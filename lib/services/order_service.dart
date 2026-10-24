import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'app_database.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart';

class OrderService {
  final AppDatabase db;

  OrderService(this.db);

  /// Create a new transaction.
  Future<String> createOrder({
    required String storeId,
    required String userId,
    required double totalAmount,
    required double cashReceived,
    required double change,
    required String paymentMethod,
    required List<Map<String, dynamic>> items,
    String? customerId,
    String? tableNumber,
    String? status,
    String? notes,
    double? discount,
    String? discountLabel,
    String? customerName,
    double? subtotal,
    double? pajakAmount,
  }) async {
    debugPrint(
      "OrderService.createOrder: storeId=$storeId, userId=$userId, amount=$totalAmount, customerId=$customerId, table=$tableNumber, discount=$discount, discountLabel=$discountLabel, customerName=$customerName",
    );

    final txId = const Uuid().v4();
    final now = DateTime.now();

    final Map<String, dynamic> notesMeta = {};
    if (notes != null && notes.trim().isNotEmpty) notesMeta['custom_notes'] = notes.trim();
    if (discount != null && discount > 0) {
      notesMeta['discount'] = discount;
      if (discountLabel != null && discountLabel.trim().isNotEmpty) {
        notesMeta['discount_label'] = discountLabel.trim();
      }
    }
    if (customerName != null && customerName.trim().isNotEmpty) {
      notesMeta['customer_name'] = customerName.trim();
    }
    if (subtotal != null && subtotal > 0) notesMeta['subtotal'] = subtotal;
    if (pajakAmount != null && pajakAmount > 0) notesMeta['tax'] = pajakAmount;
    final String? notesJson = notesMeta.isNotEmpty ? jsonEncode(notesMeta) : notes;

    await db.transaction(() async {
      // 1. Save Transaction
      await db
          .into(db.transactions)
          .insert(
            TransactionsCompanion.insert(
              id: txId,
              storeId: Value(storeId),
              cashierId: Value(userId),
              totalAmount: Value(totalAmount),
              cashReceived: Value(cashReceived),
              change: Value(change),
              paymentMethod: Value(paymentMethod),
              customerId: Value(customerId),
              tableNumber: Value(tableNumber),
              createdAt: Value(now),
              notes: Value(notesJson),
              status: Value(status ?? 'completed'),
            ),
          );

      // 2. Update Customer Loyalty Points if applicable
      if (customerId != null) {
        final custQuery = db.select(db.customers)
          ..where((t) => t.id.equals(customerId));
        final customer = await custQuery.getSingleOrNull();
        if (customer != null) {
          // Rule: 1 point for every 10,000 total
          final pointsToAdd = (totalAmount / 10000).floor();
          if (pointsToAdd > 0) {
            await (db.update(
              db.customers,
            )..where((t) => t.id.equals(customerId))).write(
              CustomersCompanion(points: Value(customer.points + pointsToAdd)),
            );
          }
        }
      }

      // 3. Save Transaction Items & Update Stock
      for (var item in items) {
        final itemId = const Uuid().v4();
        final productId = item['product_id'] as String;
        final quantity = item['quantity'] as int;
        final unitPrice = (item['unit_price'] as num).toDouble();

        await db
            .into(db.transactionItems)
            .insert(
              TransactionItemsCompanion.insert(
                id: itemId,
                transactionId: Value(txId),
                productId: Value(productId),
                productName: Value(item['product_name'] as String?),
                quantity: Value(quantity),
                unitPrice: Value(unitPrice),
                totalPrice: Value((item['total_price'] as num).toDouble()),
                notes: Value(item['notes'] as String?),
              ),
            );

        // Update Local Stock using Drift's update
        final productQuery = db.select(db.products)
          ..where((t) => t.id.equals(productId));
        final product = await productQuery.getSingleOrNull();

        if (product != null && product.isStockManaged) {
          double multiplier = 1.0;
          final opts = item['selected_options'] as List<dynamic>?;
          if (opts != null) {
            for (var opt in opts) {
              final sm = opt['stock_multiplier'];
              if (sm != null) {
                multiplier *= (sm as num).toDouble();
              }
            }
          }
          final double decrement = quantity.toDouble() * multiplier;
          final newStock = (product.stockQuantity ?? 0.0) - decrement;
          await (db.update(db.products)..where((t) => t.id.equals(productId)))
              .write(ProductsCompanion(stockQuantity: Value(newStock)));
        }
      }
    });

    return txId;
  }

  /// Get transactions for today for a specific store
  Future<List<Map<String, dynamic>>> getTodayOrders(String storeId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    final txResults =
        await (db.select(db.transactions)
              ..where((t) => t.storeId.equals(storeId))
              ..where((t) => t.createdAt.isBiggerOrEqualValue(startOfDay))
              ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
            .get();

    List<Map<String, dynamic>> result = [];
    for (var tx in txResults) {
      final items = await (db.select(
        db.transactionItems,
      )..where((t) => t.transactionId.equals(tx.id))).get();

      // Convert to map-like structure if needed for legacy compatibility,
      // but ideally we should return data classes.
      // For now, let's keep it as Map<String, dynamic> to avoid breaking too much UI.
      final txMap = tx.toJson();
      txMap['transaction_items'] = items.map((e) => e.toJson()).toList();
      result.add(txMap);
    }

    return result;
  }

  /// Delete a transaction by ID.
  /// Reverses stock deductions and loyalty points, then removes transaction and items.
  Future<void> deleteTransaction(String transactionId, {bool restoreStock = true}) async {
    await db.transaction(() async {
      // 1. Fetch transaction record
      final tx = await (db.select(db.transactions)
            ..where((t) => t.id.equals(transactionId)))
          .getSingleOrNull();
      if (tx == null) return;

      // 2. Fetch all transaction items
      final items = await (db.select(db.transactionItems)
            ..where((t) => t.transactionId.equals(transactionId)))
          .get();

      // 3. Restore stock if stock is managed
      if (restoreStock) {
        for (final item in items) {
          if (item.productId != null && item.quantity != null) {
            final product = await (db.select(db.products)
                  ..where((t) => t.id.equals(item.productId!)))
                .getSingleOrNull();
            if (product != null && product.isStockManaged) {
              double multiplier = 1.0;
              if (item.selectedOptionsJson != null) {
                try {
                  final opts = jsonDecode(item.selectedOptionsJson!) as List<dynamic>?;
                  if (opts != null) {
                    for (var opt in opts) {
                      final sm = opt['stock_multiplier'];
                      if (sm != null) {
                        multiplier *= (sm as num).toDouble();
                      }
                    }
                  }
                } catch (_) {}
              }
              final double increment = item.quantity!.toDouble() * multiplier;
              final double newStock = (product.stockQuantity ?? 0.0) + increment;
              await (db.update(db.products)..where((t) => t.id.equals(item.productId!)))
                  .write(ProductsCompanion(stockQuantity: Value(newStock)));
            }
          }
        }
      }

      // 4. Reverse customer loyalty points if applicable
      if (tx.customerId != null && tx.totalAmount != null) {
        final customer = await (db.select(db.customers)
              ..where((t) => t.id.equals(tx.customerId!)))
            .getSingleOrNull();
        if (customer != null) {
          final pointsToDeduct = (tx.totalAmount! / 10000).floor();
          if (pointsToDeduct > 0) {
            final newPoints = (customer.points - pointsToDeduct) > 0 ? (customer.points - pointsToDeduct) : 0;
            await (db.update(db.customers)..where((t) => t.id.equals(tx.customerId!)))
                .write(CustomersCompanion(points: Value(newPoints)));
          }
        }
      }

      // 5. Delete transaction items
      await (db.delete(db.transactionItems)..where((t) => t.transactionId.equals(transactionId))).go();

      // 6. Delete transaction record
      await (db.delete(db.transactions)..where((t) => t.id.equals(transactionId))).go();
    });
  }
}

