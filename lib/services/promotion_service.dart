import 'package:uuid/uuid.dart';
import 'app_database.dart';
import 'package:drift/drift.dart';

class PromotionService {
  final AppDatabase _db;

  PromotionService(this._db);

  // --- CRUD ---

  Future<List<Promotion>> getActivePromotions(String storeId) async {
    final now = DateTime.now();
    return await (_db.select(_db.promotions)
          ..where((t) => t.storeId.equals(storeId))
          ..where((t) => t.isActive.equals(true))
          ..where(
            (t) =>
                t.startDate.isNull() | t.startDate.isSmallerOrEqualValue(now),
          )
          ..where(
            (t) => t.endDate.isNull() | t.endDate.isBiggerOrEqualValue(now),
          ))
        .get();
  }

  Future<List<Promotion>> getAllPromotions(String storeId) async {
    return await (_db.select(_db.promotions)
          ..where((t) => t.storeId.equals(storeId))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
          ]))
        .get();
  }

  Future<void> createPromotion({
    required String name,
    required String type,
    String discountType = 'percentage',
    String? description,
    double? value,
    required String storeId,
    DateTime? startDate,
    DateTime? endDate,
    List<Map<String, dynamic>> items =
        const [], // {productId, categoryId, role, quantity}
  }) async {
    final promoId = const Uuid().v4();
    final now = DateTime.now();

    await _db.transaction(() async {
      await _db
          .into(_db.promotions)
          .insert(
            PromotionsCompanion.insert(
              id: promoId,
              name: Value(name),
              type: type,
              discountType: Value(discountType),
              description: Value(description),
              value: Value(value),
              storeId: Value(storeId),
              startDate: Value(startDate),
              endDate: Value(endDate),
              createdAt: Value(now),
            ),
          );

      for (var item in items) {
        await _db
            .into(_db.promotionItems)
            .insert(
              PromotionItemsCompanion.insert(
                id: const Uuid().v4(),
                promotionId: Value(promoId),
                productId: Value(item['productId']),
                categoryId: Value(item['categoryId']),
                role: item['role'], // BUY, GET, TARGET
                quantity: Value(item['quantity'] ?? 1),
              ),
            );
      }
    });
  }

  Future<void> updatePromotionStatus(String id, bool isActive) async {
    await (_db.update(_db.promotions)..where((t) => t.id.equals(id))).write(
      PromotionsCompanion(isActive: Value(isActive)),
    );
  }

  Future<void> deletePromotion(String id) async {
    await _db.transaction(() async {
      await (_db.delete(
        _db.promotionItems,
      )..where((t) => t.promotionId.equals(id))).go();
      await (_db.delete(_db.promotions)..where((t) => t.id.equals(id))).go();
    });
  }

  Future<List<PromotionItem>> getPromotionItems(String promotionId) async {
    return await (_db.select(
      _db.promotionItems,
    )..where((t) => t.promotionId.equals(promotionId))).get();
  }

  /// Scans the cart and return a list of applied promotions and their total discount.
  /// Pass [selectedCustomerId] when a customer is attached to the transaction.
  Future<Map<String, dynamic>> calculateDiscounts({
    required String storeId,
    required List<Map<String, dynamic>> cartItems,
    String? selectedCustomerId,
  }) async {
    // 1. Fetch active promotions
    final rawPromos = await getActivePromotions(storeId);
    double totalDiscount = 0;
    List<String> appliedPromoNames = [];
    bool isMemberDiscount = false;

    // 2. Pair promos with their items
    List<Map<String, dynamic>> promoWithItems = [];
    for (var promo in rawPromos) {
      final items = await (_db.select(
        _db.promotionItems,
      )..where((t) => t.promotionId.equals(promo.id))).get();
      promoWithItems.add({'promo': promo, 'items': items});
    }

    // 3. Sort: Specific (Category / Customer) first, then General (All Products)
    promoWithItems.sort((a, b) {
      final aItems = a['items'] as List<PromotionItem>;
      final bItems = b['items'] as List<PromotionItem>;

      if (aItems.isEmpty && bItems.isNotEmpty) return 1;
      if (aItems.isNotEmpty && bItems.isEmpty) return -1;
      return 0;
    });

    // To prevent stacking (one discount per item)
    final Set<String> globalAppliedCartIds = {};
    final Map<String, double> itemDiscounts = {};

    for (var entry in promoWithItems) {
      final promo = entry['promo'] as Promotion;
      final promoItems = entry['items'] as List<PromotionItem>;

      if (promo.type == 'discount' && promo.value != null) {
        final isPercentage = promo.discountType == 'percentage';
        final promoValue = promo.value!;

        // Classify the promo target
        final customerItems = promoItems
            .where((i) => i.role == 'CUSTOMER' || i.role == 'CUSTOMER_ALL')
            .toList();
        final categoryItems = promoItems
            .where((i) => i.role == 'TARGET')
            .toList();

        final isCustomerPromo = customerItems.isNotEmpty;
        final isCategoryPromo = !isCustomerPromo && categoryItems.isNotEmpty;
        final isApplyToAll = promoItems.isEmpty;

        // ── Customer-scoped promo ──────────────────────────────────────────
        if (isCustomerPromo) {
          // Only activate if the buying customer is in the list
          if (selectedCustomerId == null) continue; // no customer → skip
          
          final bool isForAllMembers = customerItems.any(
            (i) => i.productId == 'ALL_MEMBERS' || i.productId == null || i.role == 'CUSTOMER_ALL',
          );
          final allowedIds = customerItems.map((i) => i.productId).toSet();
          if (!isForAllMembers && !allowedIds.contains(selectedCustomerId)) {
            continue; // wrong customer
          }

          isMemberDiscount = true;

          // Apply discount to ALL cart items for this customer
          for (var cartItem in cartItems) {
            final String cartId = cartItem['cart_id'];
            if (globalAppliedCartIds.contains(cartId)) continue;

            _applyDiscount(
              cartItem,
              promoValue,
              isPercentage,
              promo.name ?? 'Diskon Member',
              (disc) {
                if (disc > 0) {
                  globalAppliedCartIds.add(cartId);
                  itemDiscounts[cartId] = disc;
                  totalDiscount += disc;
                }
              },
              (name) {
                if (!appliedPromoNames.contains(name)) {
                  appliedPromoNames.add(name);
                }
              },
            );
          }
          continue; // done with this promo
        }

        // ── Category-scoped promo ─────────────────────────────────────────
        if (isCategoryPromo) {
          for (var pi in categoryItems) {
            for (var cartItem in cartItems) {
              final String cartId = cartItem['cart_id'];
              if (globalAppliedCartIds.contains(cartId)) continue;

              final Product p = cartItem['product'];
              bool match = false;

              if (pi.productId != null && pi.productId == p.id) {
                match = true;
              } else if (pi.categoryId != null &&
                  pi.categoryId == p.categoryId) {
                match = true;
              }

              if (match) {
                _applyDiscount(
                  cartItem,
                  promoValue,
                  isPercentage,
                  promo.name ?? 'Promo',
                  (disc) {
                    if (disc > 0) {
                      globalAppliedCartIds.add(cartId);
                      itemDiscounts[cartId] = disc;
                      totalDiscount += disc;
                    }
                  },
                  (name) {
                    if (!appliedPromoNames.contains(name)) {
                      appliedPromoNames.add(name);
                    }
                  },
                );
              }
            }
          }
          continue;
        }

        // ── Apply-to-all promo ────────────────────────────────────────────
        if (isApplyToAll) {
          for (var cartItem in cartItems) {
            final String cartId = cartItem['cart_id'];
            if (globalAppliedCartIds.contains(cartId)) continue;

            _applyDiscount(
              cartItem,
              promoValue,
              isPercentage,
              promo.name ?? 'Promo',
              (disc) {
                if (disc > 0) {
                  globalAppliedCartIds.add(cartId);
                  itemDiscounts[cartId] = disc;
                  totalDiscount += disc;
                }
              },
              (name) {
                if (!appliedPromoNames.contains(name)) {
                  appliedPromoNames.add(name);
                }
              },
            );
          }
        }
      }
    }

    return {
      'total_discount': totalDiscount,
      'promo_count': appliedPromoNames.length,
      'promo_names': appliedPromoNames,
      'applied_cart_ids': globalAppliedCartIds.toList(),
      'item_discounts': itemDiscounts,
      'is_member_discount': isMemberDiscount,
    };
  }

  void _applyDiscount(
    Map<String, dynamic> cartItem,
    double promoValue,
    bool isPercentage,
    String promoName,
    Function(double) onDiscountAdded,
    Function(String) onPromoApplied,
  ) {
    final qty = cartItem['quantity'] as int;
    final price = cartItem['price'] as double;

    double itemDiscount = 0;
    if (isPercentage) {
      itemDiscount = (price * (promoValue / 100)) * qty;
    } else {
      itemDiscount = (promoValue * qty).clamp(0.0, price * qty);
    }

    onDiscountAdded(itemDiscount);
    onPromoApplied(promoName);
  }

  /// Get active and all promotions that target members (CUSTOMER role)
  Future<List<Map<String, dynamic>>> getMemberPromotions(String storeId) async {
    final allPromos = await getAllPromotions(storeId);
    final List<Map<String, dynamic>> memberPromos = [];

    for (var promo in allPromos) {
      final items = await getPromotionItems(promo.id);
      final customerItems = items.where((i) => i.role == 'CUSTOMER' || i.role == 'CUSTOMER_ALL').toList();
      if (customerItems.isNotEmpty) {
        final bool isAllMembers = customerItems.any(
          (i) => i.productId == 'ALL_MEMBERS' || i.productId == null || i.role == 'CUSTOMER_ALL',
        );
        final customerIds = customerItems
            .where((i) => i.productId != null && i.productId != 'ALL_MEMBERS')
            .map((i) => i.productId!)
            .toList();

        memberPromos.add({
          'promo': promo,
          'isAllMembers': isAllMembers,
          'customerIds': customerIds,
        });
      }
    }
    return memberPromos;
  }

  /// Save or update a member discount promotion
  Future<void> saveMemberDiscountPromotion({
    required String storeId,
    required String name,
    required String discountType, // 'percentage' | 'fixed'
    required double value,
    required bool applyToAllMembers,
    List<String> selectedCustomerIds = const [],
    String? existingPromoId,
    bool isActive = true,
  }) async {
    if (existingPromoId != null) {
      // Delete old promo items and update promo
      await _db.transaction(() async {
        await (_db.delete(_db.promotionItems)
              ..where((t) => t.promotionId.equals(existingPromoId)))
            .go();

        await (_db.update(_db.promotions)
              ..where((t) => t.id.equals(existingPromoId)))
            .write(
          PromotionsCompanion(
            name: Value(name),
            discountType: Value(discountType),
            value: Value(value),
            isActive: Value(isActive),
          ),
        );

        if (applyToAllMembers) {
          await _db.into(_db.promotionItems).insert(
                PromotionItemsCompanion.insert(
                  id: const Uuid().v4(),
                  promotionId: Value(existingPromoId),
                  productId: const Value('ALL_MEMBERS'),
                  role: 'CUSTOMER_ALL',
                  quantity: const Value(1),
                ),
              );
        } else {
          for (var cId in selectedCustomerIds) {
            await _db.into(_db.promotionItems).insert(
                  PromotionItemsCompanion.insert(
                    id: const Uuid().v4(),
                    promotionId: Value(existingPromoId),
                    productId: Value(cId),
                    role: 'CUSTOMER',
                    quantity: const Value(1),
                  ),
                );
          }
        }
      });
    } else {
      List<Map<String, dynamic>> items = [];
      if (applyToAllMembers) {
        items.add({
          'productId': 'ALL_MEMBERS',
          'role': 'CUSTOMER_ALL',
          'quantity': 1,
        });
      } else {
        for (var cId in selectedCustomerIds) {
          items.add({
            'productId': cId,
            'role': 'CUSTOMER',
            'quantity': 1,
          });
        }
      }

      await createPromotion(
        name: name,
        type: 'discount',
        discountType: discountType,
        description: 'Diskon khusus pelanggan / member terdaftar',
        value: value,
        storeId: storeId,
        items: items,
      );
    }
  }
}
