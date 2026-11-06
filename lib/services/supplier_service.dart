import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_database.dart';
import 'expense_service.dart';
import 'payment_method_service.dart';

class SupplierSettlement {
  final String id;
  final String supplierId;
  final String storeId;
  final double amount;
  final DateTime settledAt;
  final String paymentMethod;
  final String? notes;

  SupplierSettlement({
    required this.id,
    required this.supplierId,
    required this.storeId,
    required this.amount,
    required this.settledAt,
    required this.paymentMethod,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'supplierId': supplierId,
    'storeId': storeId,
    'amount': amount,
    'settledAt': settledAt.toIso8601String(),
    'paymentMethod': paymentMethod,
    'notes': notes,
  };

  factory SupplierSettlement.fromJson(Map<String, dynamic> json) => SupplierSettlement(
    id: json['id'] as String? ?? '',
    supplierId: json['supplierId'] as String? ?? '',
    storeId: json['storeId'] as String? ?? '',
    amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
    settledAt: json['settledAt'] != null
        ? DateTime.tryParse(json['settledAt'].toString()) ?? DateTime.now()
        : DateTime.now(),
    paymentMethod: json['paymentMethod'] as String? ?? 'Tunai',
    notes: json['notes'] as String?,
  );
}


class SupplierTransactionItem {
  final String productId;
  final String productName;
  final double quantity;
  final double unitPrice;
  final double subtotal;

  SupplierTransactionItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
  });

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'productName': productName,
    'quantity': quantity,
    'unitPrice': unitPrice,
    'subtotal': subtotal,
  };

  factory SupplierTransactionItem.fromJson(Map<String, dynamic> json) => SupplierTransactionItem(
    productId: json['productId'] as String? ?? '',
    productName: json['productName'] as String? ?? '',
    quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
    unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
    subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
  );
}

class SupplierTransaction {
  final String id;
  final String storeId;
  final String supplierId;
  final String transactionNo; // PB-0051, BH-0023, RB-0005
  final String type; // 'purchase', 'payment', 'return'
  final double totalAmount;
  final double paidAmount;
  final String paymentStatus; // 'hutang', 'lunas'
  final String? paymentMethod; // 'Kas', 'BCA', 'QRIS', etc.
  final String? paymentMethodId;
  final List<SupplierTransactionItem> items;
  final String? notes;
  final DateTime createdAt;

  SupplierTransaction({
    required this.id,
    required this.storeId,
    required this.supplierId,
    required this.transactionNo,
    required this.type,
    required this.totalAmount,
    this.paidAmount = 0.0,
    required this.paymentStatus,
    this.paymentMethod,
    this.paymentMethodId,
    this.items = const [],
    this.notes,
    required this.createdAt,
  });

  bool get isPurchase => type == 'purchase';
  bool get isPayment => type == 'payment';
  bool get isReturn => type == 'return';

  Map<String, dynamic> toJson() => {
    'id': id,
    'storeId': storeId,
    'supplierId': supplierId,
    'transactionNo': transactionNo,
    'type': type,
    'totalAmount': totalAmount,
    'paidAmount': paidAmount,
    'paymentStatus': paymentStatus,
    'paymentMethod': paymentMethod,
    'paymentMethodId': paymentMethodId,
    'items': items.map((i) => i.toJson()).toList(),
    'notes': notes,
    'createdAt': createdAt.toIso8601String(),
  };

  factory SupplierTransaction.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    List<SupplierTransactionItem> itemsList = [];
    if (rawItems is List) {
      itemsList = rawItems.map((e) => SupplierTransactionItem.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } else if (rawItems is String) {
      try {
        final decoded = jsonDecode(rawItems) as List;
        itemsList = decoded.map((e) => SupplierTransactionItem.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      } catch (_) {}
    }

    final tot = (json['totalAmount'] as num?)?.toDouble() ?? 0.0;
    final status = json['paymentStatus'] as String? ?? 'hutang';
    final pAmount = (json['paidAmount'] as num?)?.toDouble() ?? (status.toLowerCase() == 'lunas' ? tot : 0.0);

    return SupplierTransaction(
      id: json['id'] as String? ?? '',
      storeId: json['storeId'] as String? ?? '',
      supplierId: json['supplierId'] as String? ?? '',
      transactionNo: json['transactionNo'] as String? ?? '',
      type: json['type'] as String? ?? 'purchase',
      totalAmount: tot,
      paidAmount: pAmount,
      paymentStatus: status,
      paymentMethod: json['paymentMethod'] as String?,
      paymentMethodId: json['paymentMethodId'] as String?,
      items: itemsList,
      notes: json['notes'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class Supplier {
  final String id;
  final String storeId;
  final String name;
  final String? phone;
  final String? address;
  final String? notes;
  final DateTime createdAt;
  /// Map of productId -> usual restock quantity (e.g. {'prod_1': 50, 'prod_2': 24})
  final Map<String, int> productUsualStock;
  /// Map of productId -> supplier purchase/buy price (e.g. {'prod_1': 15000.0, 'prod_2': 25000.0})
  final Map<String, double> productPrices;
  /// Timestamp of the last time this supplier was settled / paid off
  final DateTime? lastSettledAt;
  /// Any manual unpaid debt balance
  final double unpaidBalance;

  Supplier({
    required this.id,
    required this.storeId,
    required this.name,
    this.phone,
    this.address,
    this.notes,
    required this.createdAt,
    this.productUsualStock = const {},
    this.productPrices = const {},
    this.lastSettledAt,
    this.unpaidBalance = 0.0,
  });

  /// Total estimated cost for all usual stock: sum(stock * price)
  double get totalEstimatedRestockCost {
    double total = 0.0;
    productUsualStock.forEach((prodId, qty) {
      final price = productPrices[prodId] ?? 0.0;
      total += qty * price;
    });
    return total;
  }

  /// Total unique products associated with this supplier
  int get totalProductCount {
    final set = <String>{...productUsualStock.keys, ...productPrices.keys};
    return set.length;
  }

  Supplier copyWith({
    String? name,
    String? phone,
    String? address,
    String? notes,
    Map<String, int>? productUsualStock,
    Map<String, double>? productPrices,
    DateTime? lastSettledAt,
    double? unpaidBalance,
  }) {
    return Supplier(
      id: id,
      storeId: storeId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      productUsualStock: productUsualStock ?? this.productUsualStock,
      productPrices: productPrices ?? this.productPrices,
      lastSettledAt: lastSettledAt ?? this.lastSettledAt,
      unpaidBalance: unpaidBalance ?? this.unpaidBalance,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'storeId': storeId,
      'name': name,
      'phone': phone,
      'address': address,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'productUsualStock': productUsualStock,
      'productPrices': productPrices,
      'lastSettledAt': lastSettledAt?.toIso8601String(),
      'unpaidBalance': unpaidBalance,
    };
  }

  factory Supplier.fromJson(Map<String, dynamic> json) {
    final Map<String, int> stocks = {};
    if (json['productUsualStock'] != null && json['productUsualStock'] is Map) {
      (json['productUsualStock'] as Map).forEach((k, v) {
        if (v != null) {
          stocks[k.toString()] = (v as num).toInt();
        }
      });
    }

    final Map<String, double> prices = {};
    if (json['productPrices'] != null && json['productPrices'] is Map) {
      (json['productPrices'] as Map).forEach((k, v) {
        if (v != null) {
          prices[k.toString()] = (v as num).toDouble();
        }
      });
    }

    return Supplier(
      id: json['id'] as String? ?? '',
      storeId: json['storeId'] as String? ?? '',
      name: json['name'] as String? ?? 'Supplier',
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      productUsualStock: stocks,
      productPrices: prices,
      lastSettledAt: json['lastSettledAt'] != null
          ? DateTime.tryParse(json['lastSettledAt'].toString())
          : null,
      unpaidBalance: (json['unpaidBalance'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Itemized breakdown for a single product associated with a supplier
class SupplierBillItem {
  final String productId;
  final String productName;
  final int quantitySold;
  final int usualStock;
  final int currentStock;
  final double unitPrice;

  SupplierBillItem({
    required this.productId,
    required this.productName,
    required this.quantitySold,
    required this.usualStock,
    required this.currentStock,
    required this.unitPrice,
  });

  double get subtotalSold => quantitySold * unitPrice;
  double get subtotalUsual => usualStock * unitPrice;

  SupplierBillItem copyWith({
    int? quantitySold,
    int? usualStock,
    double? unitPrice,
  }) {
    return SupplierBillItem(
      productId: productId,
      productName: productName,
      quantitySold: quantitySold ?? this.quantitySold,
      usualStock: usualStock ?? this.usualStock,
      currentStock: currentStock,
      unitPrice: unitPrice ?? this.unitPrice,
    );
  }
}

/// Comprehensive bill breakdown for supplier settlement
class SupplierBillBreakdown {
  final double unpaidBalance;
  final List<SupplierBillItem> items;
  final double totalSoldCost;
  final double totalUsualCost;
  final DateTime? lastSettledAt;

  SupplierBillBreakdown({
    required this.unpaidBalance,
    required this.items,
    required this.totalSoldCost,
    required this.totalUsualCost,
    this.lastSettledAt,
  });

  double get grandTotalSold => unpaidBalance + totalSoldCost;
  double get grandTotalUsual => unpaidBalance + totalUsualCost;
}

class SupplierService {
  final AppDatabase db;
  final _uuid = const Uuid();
  bool _tableInitialized = false;

  SupplierService(this.db);

  Future<void> _ensureTable() async {
    if (_tableInitialized) return;
    try {
      await db.customStatement('''
        CREATE TABLE IF NOT EXISTS suppliers (
          id TEXT PRIMARY KEY NOT NULL,
          store_id TEXT NOT NULL,
          name TEXT NOT NULL,
          phone TEXT,
          address TEXT,
          notes TEXT,
          product_stocks TEXT,
          product_prices TEXT,
          created_at TEXT NOT NULL,
          last_settled_at TEXT,
          unpaid_balance REAL DEFAULT 0.0
        );
      ''');
      // If table already existed from before, add columns safely
      try {
        await db.customStatement('ALTER TABLE suppliers ADD COLUMN product_prices TEXT;');
      } catch (_) {}
      try {
        await db.customStatement('ALTER TABLE suppliers ADD COLUMN last_settled_at TEXT;');
      } catch (_) {}
      try {
        await db.customStatement('ALTER TABLE suppliers ADD COLUMN unpaid_balance REAL DEFAULT 0.0;');
      } catch (_) {}

      
      await db.customStatement('''
        CREATE TABLE IF NOT EXISTS supplier_transactions (
          id TEXT PRIMARY KEY NOT NULL,
          store_id TEXT NOT NULL,
          supplier_id TEXT NOT NULL,
          transaction_no TEXT NOT NULL,
          type TEXT NOT NULL,
          total_amount REAL NOT NULL,
          paid_amount REAL DEFAULT 0.0,
          payment_status TEXT NOT NULL,
          payment_method TEXT,
          payment_method_id TEXT,
          items_json TEXT,
          notes TEXT,
          created_at TEXT NOT NULL
        );
      ''');
      try {
        await db.customStatement('ALTER TABLE supplier_transactions ADD COLUMN paid_amount REAL DEFAULT 0.0;');
      } catch (_) {}

      await db.customStatement('''
        CREATE TABLE IF NOT EXISTS supplier_settlements (
          id TEXT PRIMARY KEY NOT NULL,
          supplier_id TEXT NOT NULL,
          store_id TEXT NOT NULL,
          amount REAL NOT NULL,
          settled_at TEXT NOT NULL,
          payment_method TEXT NOT NULL,
          notes TEXT
        );
      ''');

      _tableInitialized = true;
    } catch (e) {
      debugPrint("SupplierService: init table error: $e");
    }
  }

  Future<List<Supplier>> getSuppliers(String storeId) async {
    await _ensureTable();
    try {
      final rows = await db.customSelect(
        'SELECT * FROM suppliers WHERE store_id = ? ORDER BY name ASC',
        variables: [Variable.withString(storeId)],
      ).get();

      if (rows.isNotEmpty) {
        final list = rows.map((row) {
          final data = row.data;
          final Map<String, int> stocks = {};
          if (data['product_stocks'] != null && data['product_stocks'] is String) {
            try {
              final decoded = jsonDecode(data['product_stocks'] as String);
              if (decoded is Map) {
                decoded.forEach((k, v) {
                  if (v != null) stocks[k.toString()] = (v as num).toInt();
                });
              }
            } catch (_) {}
          }

          final Map<String, double> prices = {};
          if (data['product_prices'] != null && data['product_prices'] is String) {
            try {
              final decoded = jsonDecode(data['product_prices'] as String);
              if (decoded is Map) {
                decoded.forEach((k, v) {
                  if (v != null) prices[k.toString()] = (v as num).toDouble();
                });
              }
            } catch (_) {}
          }

          return Supplier(
            id: data['id'] as String,
            storeId: data['store_id'] as String,
            name: data['name'] as String,
            phone: data['phone'] as String?,
            address: data['address'] as String?,
            notes: data['notes'] as String?,
            createdAt: DateTime.tryParse(data['created_at']?.toString() ?? '') ?? DateTime.now(),
            productUsualStock: stocks,
            productPrices: prices,
            lastSettledAt: data['last_settled_at'] != null && data['last_settled_at'].toString().isNotEmpty
                ? DateTime.tryParse(data['last_settled_at'].toString())
                : null,
            unpaidBalance: (data['unpaid_balance'] as num?)?.toDouble() ?? 0.0,
          );
        }).toList();

        // Reconcile supplier unpaid balances with supplier_transactions if needed
        final reconciledList = await _reconcileSupplierDebts(storeId, list);

        // Also update local cache
        await _saveListToPrefs(storeId, reconciledList);
        return reconciledList;
      }
    } catch (e) {
      debugPrint("SupplierService: getSuppliers error: $e");
    }

    // Prefs fallback
    final fallbackList = await _loadFromPrefs(storeId);
    return await _reconcileSupplierDebts(storeId, fallbackList);
  }

  Future<List<Supplier>> _reconcileSupplierDebts(String storeId, List<Supplier> suppliers) async {
    if (suppliers.isEmpty) return suppliers;
    try {
      final prefs = await SharedPreferences.getInstance();
      final migKey = 'reconciled_pb_hutang_v2_$storeId';
      final alreadyMigrated = prefs.getBool(migKey) ?? false;

      final allTxs = await getAllStoreTransactions(storeId);
      if (allTxs.isEmpty) {
        if (!alreadyMigrated) await prefs.setBool(migKey, true);
        return suppliers;
      }

      bool anyTxUpdated = false;
      final List<SupplierTransaction> updatedTxs = List.from(allTxs);

      // One-time fix for earlier PB-xxxx purchases that were inadvertently saved as 'lunas'
      // when the user tested Pembelian expecting it to become supplier hutang.
      if (!alreadyMigrated) {
        final hasAnyPayment = updatedTxs.any((t) => t.type == 'payment');
        final totalCurrentDebt = suppliers.fold<double>(0.0, (s, sup) => s + sup.unpaidBalance);
        if (!hasAnyPayment && totalCurrentDebt <= 0) {
          for (int i = 0; i < updatedTxs.length; i++) {
            final t = updatedTxs[i];
            if (t.type == 'purchase' && t.paymentStatus.toLowerCase() == 'lunas') {
              final fixedTx = SupplierTransaction(
                id: t.id,
                storeId: t.storeId,
                supplierId: t.supplierId,
                transactionNo: t.transactionNo,
                type: t.type,
                totalAmount: t.totalAmount,
                paymentStatus: 'hutang',
                paymentMethod: t.paymentMethod,
                paymentMethodId: t.paymentMethodId,
                items: t.items,
                notes: t.notes,
                createdAt: t.createdAt,
              );
              updatedTxs[i] = fixedTx;
              anyTxUpdated = true;
              try {
                await db.customUpdate(
                  "UPDATE supplier_transactions SET payment_status = 'hutang' WHERE id = ?",
                  variables: [Variable.withString(t.id)],
                );
                // Remove auto-created cash expense for this PB-xxxx since it is hutang (unpaid)
                await db.customStatement(
                  "DELETE FROM expenses WHERE store_id = ? AND notes LIKE ?",
                  [storeId, '%(${t.transactionNo})%'],
                );
              } catch (_) {}
            }
          }
          if (anyTxUpdated) {
            await _saveTransactionsListToPrefs(storeId, updatedTxs);
          }
        }
        await prefs.setBool(migKey, true);
      }

      final List<Supplier> result = [];
      for (final sup in suppliers) {
        final supTxs = updatedTxs.where((t) => t.supplierId == sup.id).toList();
        if (supTxs.isEmpty) {
          result.add(sup);
          continue;
        }
        double hutangPurchases = 0.0;
        double payments = 0.0;
        double returns = 0.0;
        for (final stx in supTxs) {
          if (stx.type == 'purchase' && stx.paymentStatus.toLowerCase() == 'hutang') {
            hutangPurchases += stx.totalAmount;
          } else if (stx.type == 'payment') {
            payments += stx.totalAmount;
          } else if (stx.type == 'return') {
            returns += stx.totalAmount;
          }
        }
        final computedNetDebt = (hutangPurchases - payments - returns).clamp(0.0, double.infinity);

        if ((sup.unpaidBalance <= 0 && computedNetDebt > 0) || anyTxUpdated) {
          final updatedSup = sup.copyWith(unpaidBalance: computedNetDebt);
          result.add(updatedSup);
          try {
            await db.customUpdate(
              'UPDATE suppliers SET unpaid_balance = ? WHERE id = ?',
              variables: [
                Variable.withReal(computedNetDebt),
                Variable.withString(sup.id),
              ],
            );
          } catch (_) {}
        } else {
          result.add(sup);
        }
      }
      return result;
    } catch (e) {
      debugPrint("SupplierService: _reconcileSupplierDebts error: $e");
      return suppliers;
    }
  }

  Future<Supplier> addSupplier({
    required String storeId,
    required String name,
    String? phone,
    String? address,
    String? notes,
    Map<String, int> productUsualStock = const {},
    Map<String, double> productPrices = const {},
    DateTime? lastSettledAt,
    double unpaidBalance = 0.0,
  }) async {
    await _ensureTable();
    final newId = 'sup_${_uuid.v4().substring(0, 8)}';
    final now = DateTime.now();
    final supplier = Supplier(
      id: newId,
      storeId: storeId,
      name: name,
      phone: phone,
      address: address,
      notes: notes,
      createdAt: now,
      productUsualStock: productUsualStock,
      productPrices: productPrices,
      lastSettledAt: lastSettledAt,
      unpaidBalance: unpaidBalance,
    );

    try {
      await db.customInsert(
        'INSERT INTO suppliers (id, store_id, name, phone, address, notes, product_stocks, product_prices, created_at, last_settled_at, unpaid_balance) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        variables: [
          Variable.withString(supplier.id),
          Variable.withString(supplier.storeId),
          Variable.withString(supplier.name),
          Variable.withString(supplier.phone ?? ''),
          Variable.withString(supplier.address ?? ''),
          Variable.withString(supplier.notes ?? ''),
          Variable.withString(jsonEncode(supplier.productUsualStock)),
          Variable.withString(jsonEncode(supplier.productPrices)),
          Variable.withString(supplier.createdAt.toIso8601String()),
          Variable.withString(supplier.lastSettledAt?.toIso8601String() ?? ''),
          Variable.withReal(supplier.unpaidBalance),
        ],
      );
    } catch (e) {
      debugPrint("SupplierService: addSupplier db insert error: $e");
    }

    // Sync to prefs
    final currentList = await _loadFromPrefs(storeId);
    currentList.add(supplier);
    await _saveListToPrefs(storeId, currentList);

    return supplier;
  }

  Future<void> updateSupplier(Supplier supplier) async {
    await _ensureTable();
    try {
      await db.customUpdate(
        'UPDATE suppliers SET name = ?, phone = ?, address = ?, notes = ?, product_stocks = ?, product_prices = ?, last_settled_at = ?, unpaid_balance = ? WHERE id = ?',
        variables: [
          Variable.withString(supplier.name),
          Variable.withString(supplier.phone ?? ''),
          Variable.withString(supplier.address ?? ''),
          Variable.withString(supplier.notes ?? ''),
          Variable.withString(jsonEncode(supplier.productUsualStock)),
          Variable.withString(jsonEncode(supplier.productPrices)),
          Variable.withString(supplier.lastSettledAt?.toIso8601String() ?? ''),
          Variable.withReal(supplier.unpaidBalance),
          Variable.withString(supplier.id),
        ],
      );
    } catch (e) {
      debugPrint("SupplierService: updateSupplier error: $e");
    }

    // Sync to prefs
    final currentList = await _loadFromPrefs(supplier.storeId);
    final idx = currentList.indexWhere((s) => s.id == supplier.id);
    if (idx != -1) {
      currentList[idx] = supplier;
    } else {
      currentList.add(supplier);
    }
    await _saveListToPrefs(supplier.storeId, currentList);
  }

  Future<void> deleteSupplier(String id, String storeId) async {
    await _ensureTable();
    try {
      await db.customStatement(
        'DELETE FROM suppliers WHERE id = ?',
        [id],
      );
    } catch (e) {
      debugPrint("SupplierService: deleteSupplier error: $e");
    }

    final currentList = await _loadFromPrefs(storeId);
    currentList.removeWhere((s) => s.id == id);
    await _saveListToPrefs(storeId, currentList);
  }

  /// Find which supplier supplies this product
  Future<Supplier?> getSupplierByProductId(String storeId, String productId) async {
    final suppliers = await getSuppliers(storeId);
    for (final s in suppliers) {
      if (s.productUsualStock.containsKey(productId) || s.productPrices.containsKey(productId)) {
        return s;
      }
    }
    return null;
  }

  /// Associate product to a supplier with buy price and usual stock
  Future<void> linkProductToSupplier({
    required String storeId,
    required String supplierId,
    required String productId,
    double? buyPrice,
    int? usualStock,
  }) async {
    final suppliers = await getSuppliers(storeId);
    for (final s in suppliers) {
      if (s.id == supplierId) {
        final newStocks = Map<String, int>.from(s.productUsualStock);
        final newPrices = Map<String, double>.from(s.productPrices);
        if (usualStock != null) {
          newStocks[productId] = usualStock;
        } else if (!newStocks.containsKey(productId)) {
          newStocks[productId] = 10;
        }
        if (buyPrice != null) {
          newPrices[productId] = buyPrice;
        }
        await updateSupplier(s.copyWith(
          productUsualStock: newStocks,
          productPrices: newPrices,
        ));
      } else {
        // Remove from other suppliers if present
        if (s.productUsualStock.containsKey(productId) || s.productPrices.containsKey(productId)) {
          final newStocks = Map<String, int>.from(s.productUsualStock)..remove(productId);
          final newPrices = Map<String, double>.from(s.productPrices)..remove(productId);
          await updateSupplier(s.copyWith(
            productUsualStock: newStocks,
            productPrices: newPrices,
          ));
        }
      }
    }
  }

  /// Unlink product from all suppliers
  Future<void> unlinkProductFromSuppliers({
    required String storeId,
    required String productId,
  }) async {
    final suppliers = await getSuppliers(storeId);
    for (final s in suppliers) {
      if (s.productUsualStock.containsKey(productId) || s.productPrices.containsKey(productId)) {
        final newStocks = Map<String, int>.from(s.productUsualStock)..remove(productId);
        final newPrices = Map<String, double>.from(s.productPrices)..remove(productId);
        await updateSupplier(s.copyWith(
          productUsualStock: newStocks,
          productPrices: newPrices,
        ));
      }
    }
  }

  /// Get full detailed breakdown of a supplier's bill
  Future<SupplierBillBreakdown> getSupplierBillBreakdown(String storeId, Supplier supplier) async {
    await _ensureTable();
    final supProdIds = {...supplier.productUsualStock.keys, ...supplier.productPrices.keys};

    final Map<String, Product> prodMap = {};
    if (supProdIds.isNotEmpty) {
      try {
        final query = db.select(db.products)
          ..where((p) => p.id.isIn(supProdIds));
        final products = await query.get();
        for (final p in products) {
          prodMap[p.id] = p;
        }
      } catch (e) {
        debugPrint("SupplierService: getSupplierBillBreakdown products error: $e");
      }
    }

    final Map<String, int> soldQtys = {};
    if (supProdIds.isNotEmpty) {
      try {
        final cutoff = supplier.lastSettledAt;
        var query = db.select(db.transactions);
        if (storeId.isNotEmpty) {
          query = query..where((t) => t.storeId.equals(storeId));
        }
        if (cutoff != null) {
          query = query..where((t) => t.createdAt.isBiggerThanValue(cutoff));
        }
        final txs = await query.get();
        if (txs.isNotEmpty) {
          final txIds = txs.map((t) => t.id).toList();
          final txItems = await (db.select(db.transactionItems)
            ..where((ti) => ti.transactionId.isIn(txIds) & ti.productId.isIn(supProdIds))
          ).get();

          for (final item in txItems) {
            final pid = item.productId;
            if (pid != null) {
              soldQtys[pid] = (soldQtys[pid] ?? 0) + (item.quantity ?? 1);
            }
          }
        }
      } catch (e) {
        debugPrint("SupplierService: getSupplierBillBreakdown txItems error: $e");
      }
    }

    final List<SupplierBillItem> items = [];
    double totalSoldCost = 0.0;
    double totalUsualCost = 0.0;

    for (final pid in supProdIds) {
      final prod = prodMap[pid];
      final name = prod?.name ?? 'Produk #$pid';
      final currentStock = (prod?.stockQuantity ?? 0).toInt();
      final usualQty = supplier.productUsualStock[pid] ?? 0;
      final unitPrice = supplier.productPrices[pid] ?? (prod?.buyPrice ?? prod?.basePrice ?? 0.0);
      final qtySold = soldQtys[pid] ?? 0;

      final item = SupplierBillItem(
        productId: pid,
        productName: name,
        quantitySold: qtySold,
        usualStock: usualQty,
        currentStock: currentStock,
        unitPrice: unitPrice,
      );
      items.add(item);
      totalSoldCost += item.subtotalSold;
      totalUsualCost += item.subtotalUsual;
    }

    return SupplierBillBreakdown(
      unpaidBalance: supplier.unpaidBalance,
      items: items,
      totalSoldCost: totalSoldCost,
      totalUsualCost: totalUsualCost,
      lastSettledAt: supplier.lastSettledAt,
    );
  }

  /// Calculate current unpaid / outstanding bill for a supplier
  /// Returns sold items bill if any sales exist, or unpaid balance, or usual stock supply cost
  Future<double> getOutstandingBill(String storeId, Supplier supplier) async {
    final breakdown = await getSupplierBillBreakdown(storeId, supplier);
    if (breakdown.grandTotalSold > 0) {
      return breakdown.grandTotalSold;
    }
    if (supplier.unpaidBalance > 0) {
      return supplier.unpaidBalance;
    }
    return breakdown.grandTotalUsual;
  }

  /// Process supplier settlement / payment:
  /// - Records to supplier_settlements
  /// - Inserts into expenses for cash flow deduction
  /// - If amount >= current outstanding bill: resets unpaid balance to 0 (Lunas Penuh)
  /// - If amount < current outstanding bill: saves remaining balance as unpaidBalance (Cicil / Bayar Sebagian)
  /// - Supplier data is PRESERVED and NOT deleted!
  Future<double> settleSupplierPayment({
    required String storeId,
    required Supplier supplier,
    required double amount,
    required String paymentMethod,
    double? totalBillBeforePayment,
    String? notes,
  }) async {
    await _ensureTable();
    final settlementId = 'stl_${_uuid.v4().substring(0, 8)}';
    final now = DateTime.now();

    final totalOutstanding = totalBillBeforePayment ?? await getOutstandingBill(storeId, supplier);
    final remainingBalance = (totalOutstanding - amount) > 0 ? (totalOutstanding - amount) : 0.0;

    // 1. Record in supplier_settlements table
    try {
      await db.customInsert(
        'INSERT INTO supplier_settlements (id, supplier_id, store_id, amount, settled_at, payment_method, notes) VALUES (?, ?, ?, ?, ?, ?, ?)',
        variables: [
          Variable.withString(settlementId),
          Variable.withString(supplier.id),
          Variable.withString(storeId),
          Variable.withReal(amount),
          Variable.withString(now.toIso8601String()),
          Variable.withString(paymentMethod),
          Variable.withString(notes ?? ''),
        ],
      );
    } catch (e) {
      debugPrint("SupplierService: insert settlement db error: $e");
    }

    // 2. Record to Expenses for accurate cash flow & P&L tracking
    try {
      final expService = ExpenseService(db);
      final statusTag = remainingBalance > 0
          ? ' [Cicil: Sisa Rp ${remainingBalance.toStringAsFixed(0)}]'
          : ' [Lunas]';
      await expService.createExpense(
        storeId: storeId,
        category: 'Pelunasan Supplier',
        amount: amount,
        date: now,
        notes: 'Pelunasan tagihan ke ${supplier.name} via $paymentMethod$statusTag${(notes != null && notes.trim().isNotEmpty) ? " ($notes)" : ""} [stl:$settlementId]',
      );
    } catch (e) {
      debugPrint("SupplierService: insert expense error: $e");
    }

    // 3. Update supplier's lastSettledAt and unpaidBalance (remaining balance carried forward)
    final updatedSupplier = supplier.copyWith(
      lastSettledAt: now,
      unpaidBalance: remainingBalance,
    );
    await updateSupplier(updatedSupplier);

    // 4. Save settlement to SharedPreferences cache
    await _saveSettlementToPrefs(storeId, SupplierSettlement(
      id: settlementId,
      supplierId: supplier.id,
      storeId: storeId,
      amount: amount,
      settledAt: now,
      paymentMethod: paymentMethod,
      notes: notes,
    ));

    return remainingBalance;
  }

  /// Helper to share settlement receipt to WhatsApp
  static Future<bool> shareSettlementToWhatsApp({
    required String? phone,
    required String supplierName,
    required String storeName,
    required double amountPaid,
    required double remainingBalance,
    required String paymentMethod,
    required DateTime settledAt,
    String? notes,
  }) async {
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final dateStr = DateFormat('dd MMM yyyy, HH:mm').format(settledAt);

    final statusStr = remainingBalance > 0
        ? "⚠️ Pembayaran Sebagian / Cicil (Sisa: ${currency.format(remainingBalance)})"
        : "✅ LUNAS (Tidak ada sisa tagihan)";

    final buffer = StringBuffer();
    buffer.writeln("🧾 *BUKTI SETORAN / PELUNASAN PASOKAN*");
    buffer.writeln("─────────────────────────");
    buffer.writeln("🏪 *Toko:* $storeName");
    buffer.writeln("🚚 *Supplier:* $supplierName");
    buffer.writeln("📅 *Tanggal:* $dateStr");
    buffer.writeln("💵 *Jumlah Disetor:* ${currency.format(amountPaid)}");
    buffer.writeln("💳 *Metode:* $paymentMethod");
    buffer.writeln("📌 *Status:* $statusStr");
    if (notes != null && notes.trim().isNotEmpty) {
      buffer.writeln("📝 *Catatan:* $notes");
    }
    buffer.writeln("─────────────────────────");
    buffer.writeln("Terima kasih atas pasokan & kerjasamanya! 🙏");

    String targetPhone = (phone ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    if (targetPhone.startsWith('0')) {
      targetPhone = '62${targetPhone.substring(1)}';
    }

    Uri uri;
    if (targetPhone.isNotEmpty) {
      uri = Uri.parse("https://wa.me/$targetPhone?text=${Uri.encodeComponent(buffer.toString())}");
    } else {
      uri = Uri.parse("https://wa.me/?text=${Uri.encodeComponent(buffer.toString())}");
    }

    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint("Error launching WhatsApp: $e");
    }
    return false;
  }

  /// Helper to share product return (retur barang sisa/rusak) to WhatsApp
  static Future<bool> shareReturnToWhatsApp({
    required String? phone,
    required String supplierName,
    required String storeName,
    required String productName,
    required int returnQty,
    String? reason,
  }) async {
    final dateStr = DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now());

    final buffer = StringBuffer();
    buffer.writeln("📦 *CATATAN RETUR TITIPAN / PASOKAN*");
    buffer.writeln("─────────────────────────");
    buffer.writeln("🏪 *Toko:* $storeName");
    buffer.writeln("🚚 *Supplier:* $supplierName");
    buffer.writeln("📅 *Tanggal:* $dateStr");
    buffer.writeln("🍱 *Produk:* $productName");
    buffer.writeln("🔢 *Jumlah Retur:* $returnQty pcs");
    if (reason != null && reason.trim().isNotEmpty) {
      buffer.writeln("📝 *Alasan / Ket:* $reason");
    }
    buffer.writeln("─────────────────────────");
    buffer.writeln("Barang telah diserahkan kembali ke pihak supplier.");

    String targetPhone = (phone ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    if (targetPhone.startsWith('0')) {
      targetPhone = '62${targetPhone.substring(1)}';
    }

    Uri uri;
    if (targetPhone.isNotEmpty) {
      uri = Uri.parse("https://wa.me/$targetPhone?text=${Uri.encodeComponent(buffer.toString())}");
    } else {
      uri = Uri.parse("https://wa.me/?text=${Uri.encodeComponent(buffer.toString())}");
    }

    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint("Error launching WhatsApp: $e");
    }
    return false;
  }

  /// Helper to send restock purchase order to supplier via WhatsApp
  static Future<bool> shareOrderRestockToWhatsApp({
    required String? phone,
    required String supplierName,
    required String storeName,
    required String productName,
    required int orderQty,
    double? unitPrice,
    String? notes,
  }) async {
    final dateStr = DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now());
    final currency = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

    final buffer = StringBuffer();
    buffer.writeln("📋 *PESANAN RESTOCK BARANG*");
    buffer.writeln("─────────────────────────");
    buffer.writeln("🏪 *Pemesan (Toko):* $storeName");
    buffer.writeln("🚚 *Kepada Supplier:* $supplierName");
    buffer.writeln("📅 *Tanggal Order:* $dateStr");
    buffer.writeln("─────────────────────────");
    buffer.writeln("📦 *Nama Barang:* $productName");
    buffer.writeln("🔢 *Jumlah Pesanan:* $orderQty pcs");
    if (unitPrice != null && unitPrice > 0) {
      buffer.writeln("💵 *Estimasi Harga Beli:* ${currency.format(unitPrice)} / pcs");
      buffer.writeln("💰 *Total Estimasi:* ${currency.format(unitPrice * orderQty)}");
    }
    if (notes != null && notes.trim().isNotEmpty) {
      buffer.writeln("📝 *Catatan:* $notes");
    }
    buffer.writeln("─────────────────────────");
    buffer.writeln("Mohon konfirmasi ketersediaan stok & estimasi pengirimannya. Terima kasih! 🙏");

    String targetPhone = (phone ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    if (targetPhone.startsWith('0')) {
      targetPhone = '62${targetPhone.substring(1)}';
    }

    Uri uri;
    if (targetPhone.isNotEmpty) {
      uri = Uri.parse("https://wa.me/$targetPhone?text=${Uri.encodeComponent(buffer.toString())}");
    } else {
      uri = Uri.parse("https://wa.me/?text=${Uri.encodeComponent(buffer.toString())}");
    }

    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint("Error launching WhatsApp for order: $e");
    }
    return false;
  }

  /// Get settlement history for a store (optionally filtered by supplierId)
  Future<List<SupplierSettlement>> getSettlements(String storeId, {String? supplierId}) async {
    await _ensureTable();
    try {
      String query = 'SELECT * FROM supplier_settlements WHERE store_id = ?';
      final List<Variable> vars = [Variable.withString(storeId)];
      if (supplierId != null && supplierId.isNotEmpty) {
        query += ' AND supplier_id = ?';
        vars.add(Variable.withString(supplierId));
      }
      query += ' ORDER BY settled_at DESC';

      final rows = await db.customSelect(query, variables: vars).get();
      if (rows.isNotEmpty) {
        return rows.map((r) => SupplierSettlement(
          id: r.data['id'] as String,
          supplierId: r.data['supplier_id'] as String,
          storeId: r.data['store_id'] as String,
          amount: (r.data['amount'] as num?)?.toDouble() ?? 0.0,
          settledAt: DateTime.tryParse(r.data['settled_at']?.toString() ?? '') ?? DateTime.now(),
          paymentMethod: r.data['payment_method'] as String? ?? 'Tunai',
          notes: r.data['notes'] as String?,
        )).toList();
      }
    } catch (e) {
      debugPrint("SupplierService: getSettlements db error: $e");
    }

    return await _loadSettlementsFromPrefs(storeId, supplierId: supplierId);
  }

  /// Delete a settlement record and remove its corresponding expense from the book
  Future<void> deleteSettlement(String storeId, String settlementId) async {
    await _ensureTable();
    try {
      // 1. Delete from supplier_settlements
      await db.customStatement(
        'DELETE FROM supplier_settlements WHERE id = ?',
        [settlementId],
      );
    } catch (e) {
      debugPrint("SupplierService: delete settlement db error: $e");
    }

    // 2. Delete related expense
    try {
      await db.customStatement(
        "DELETE FROM expenses WHERE store_id = ? AND category = 'Pelunasan Supplier' AND (notes LIKE ? OR notes LIKE ?)",
        [storeId, '%[stl:$settlementId]%', '%$settlementId%'],
      );
    } catch (e) {
      debugPrint("SupplierService: delete expense for settlement error: $e");
    }

    // 3. Remove from prefs
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'supplier_settlements_$storeId';
      final raw = prefs.getString(key);
      if (raw != null && raw.isNotEmpty) {
        final list = jsonDecode(raw) as List;
        list.removeWhere((item) => item is Map && item['id'] == settlementId);
        await prefs.setString(key, jsonEncode(list));
      }
    } catch (e) {
      debugPrint("SupplierService: delete settlement prefs error: $e");
    }
  }

  Future<void> _saveSettlementToPrefs(String storeId, SupplierSettlement settlement) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'supplier_settlements_$storeId';
      final raw = prefs.getString(key);
      List<dynamic> list = [];
      if (raw != null && raw.isNotEmpty) {
        try {
          list = jsonDecode(raw) as List;
        } catch (_) {}
      }
      list.insert(0, settlement.toJson());
      await prefs.setString(key, jsonEncode(list));
    } catch (e) {
      debugPrint("SupplierService: save settlement to prefs error: $e");
    }
  }

  Future<List<SupplierSettlement>> _loadSettlementsFromPrefs(String storeId, {String? supplierId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'supplier_settlements_$storeId';
      final raw = prefs.getString(key);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List;
        final all = decoded.map((e) => SupplierSettlement.fromJson(Map<String, dynamic>.from(e as Map))).toList();
        if (supplierId != null && supplierId.isNotEmpty) {
          return all.where((s) => s.supplierId == supplierId).toList();
        }
        return all;
      }
    } catch (e) {
      debugPrint("SupplierService: load settlements prefs error: $e");
    }
    return [];
  }

  Future<void> _saveListToPrefs(String storeId, List<Supplier> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(list.map((e) => e.toJson()).toList());
      await prefs.setString('suppliers_$storeId', encoded);
    } catch (e) {
      debugPrint("SupplierService: save to prefs error: $e");
    }
  }

  Future<List<Supplier>> _loadFromPrefs(String storeId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('suppliers_$storeId');
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List;
        return decoded
            .map((e) => Supplier.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
    } catch (e) {
      debugPrint("SupplierService: load from prefs error: $e");
    }
    return [];
  }

  Future<String> generateNextTransactionNo(String storeId, String prefix) async {
    await _ensureTable();
    try {
      final rows = await db.customSelect(
        "SELECT transaction_no FROM supplier_transactions WHERE store_id = ? AND transaction_no LIKE ? ORDER BY created_at DESC, transaction_no DESC LIMIT 1",
        variables: [Variable.withString(storeId), Variable.withString('$prefix-%')],
      ).get();

      if (rows.isNotEmpty) {
        final lastNo = rows.first.data['transaction_no'] as String;
        final parts = lastNo.split('-');
        if (parts.length >= 2) {
          final numPart = int.tryParse(parts.last) ?? 0;
          return '$prefix-${(numPart + 1).toString().padLeft(4, '0')}';
        }
      }
    } catch (e) {
      debugPrint("Error generating transaction no: $e");
    }

    // Prefs fallback check
    try {
      final txs = await _loadTransactionsFromPrefs(storeId);
      final matching = txs.where((t) => t.transactionNo.startsWith('$prefix-')).toList();
      if (matching.isNotEmpty) {
        matching.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final lastNo = matching.first.transactionNo;
        final numPart = int.tryParse(lastNo.split('-').last) ?? 0;
        return '$prefix-${(numPart + 1).toString().padLeft(4, '0')}';
      }
    } catch (_) {}

    return '$prefix-0001';
  }

  /// Catat Pembelian / Drop Pasokan dari Supplier (PB-xxxx)
  /// - Stok produk otomatis bertambah
  /// - Mendukung pembayaran penuh, hutang penuh, maupun bayar sebagian (sisanya otomatis jadi hutang ke supplier)
  /// - Jika ada nominal dibayar: memotong kas/bank (bisa minus)
  /// - Jika updateBuyPrice == true: memperbarui harga beli produk di database & daftar harga supplier
  Future<SupplierTransaction> recordPurchase({
    required String storeId,
    required String supplierId,
    required List<SupplierTransactionItem> items,
    required String paymentStatus, // 'hutang' or 'lunas'
    String? paymentMethod,
    String? paymentMethodId,
    String? notes,
    double? amountPaid,
    bool updateBuyPrice = false,
    DateTime? customDate,
  }) async {
    await _ensureTable();
    final suppliers = await getSuppliers(storeId);
    Supplier sup = suppliers.firstWhere((s) => s.id == supplierId);

    final txId = 'tx_${_uuid.v4().substring(0, 8)}';
    final txNo = await generateNextTransactionNo(storeId, 'PB');
    final now = customDate ?? DateTime.now();

    final totalAmount = items.fold<double>(0.0, (sum, i) => sum + i.subtotal);

    double actualPaid = 0.0;
    if (amountPaid != null && amountPaid > 0) {
      actualPaid = amountPaid.clamp(0.0, totalAmount);
    } else if (paymentStatus.toLowerCase() == 'lunas') {
      actualPaid = totalAmount;
    }
    final remainingDebt = (totalAmount - actualPaid).clamp(0.0, double.infinity);
    final effectiveStatus = remainingDebt > 0 ? 'hutang' : 'lunas';

    final tx = SupplierTransaction(
      id: txId,
      storeId: storeId,
      supplierId: supplierId,
      transactionNo: txNo,
      type: 'purchase',
      totalAmount: totalAmount,
      paidAmount: actualPaid,
      paymentStatus: effectiveStatus,
      paymentMethod: actualPaid > 0 ? (paymentMethod ?? 'Kas') : (paymentMethod ?? 'Hutang'),
      paymentMethodId: actualPaid > 0 ? paymentMethodId : null,
      items: items,
      notes: notes,
      createdAt: now,
    );

    // 1. Insert to DB
    try {
      await db.customInsert(
        'INSERT INTO supplier_transactions (id, store_id, supplier_id, transaction_no, type, total_amount, paid_amount, payment_status, payment_method, payment_method_id, items_json, notes, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        variables: [
          Variable.withString(tx.id),
          Variable.withString(tx.storeId),
          Variable.withString(tx.supplierId),
          Variable.withString(tx.transactionNo),
          Variable.withString(tx.type),
          Variable.withReal(tx.totalAmount),
          Variable.withReal(tx.paidAmount),
          Variable.withString(tx.paymentStatus),
          Variable.withString(tx.paymentMethod ?? ''),
          Variable.withString(tx.paymentMethodId ?? ''),
          Variable.withString(jsonEncode(items.map((e) => e.toJson()).toList())),
          Variable.withString(tx.notes ?? ''),
          Variable.withString(tx.createdAt.toIso8601String()),
        ],
      );
    } catch (e) {
      debugPrint("SupplierService: insert purchase tx error: $e");
    }

    // 2. Update stock quantity (and buyPrice if requested) for each product
    final updatedSupPrices = Map<String, double>.from(sup.productPrices);
    final updatedSupStocks = Map<String, int>.from(sup.productUsualStock);
    try {
      for (final item in items) {
        if (item.productId.isEmpty || item.quantity <= 0) continue;
        final p = await (db.select(db.products)..where((t) => t.id.equals(item.productId))).getSingleOrNull();
        if (p != null) {
          final curStock = p.stockQuantity ?? 0.0;
          await (db.update(db.products)..where((t) => t.id.equals(p.id))).write(
            ProductsCompanion(
              stockQuantity: Value(curStock + item.quantity),
              buyPrice: updateBuyPrice && item.unitPrice > 0 ? Value(item.unitPrice) : const Value.absent(),
              lastUpdated: Value(DateTime.now()),
            ),
          );
        }
        if (updateBuyPrice && item.unitPrice > 0) {
          updatedSupPrices[item.productId] = item.unitPrice;
        }
        if (!updatedSupStocks.containsKey(item.productId)) {
          updatedSupStocks[item.productId] = item.quantity.toInt();
        }
      }
    } catch (e) {
      debugPrint("SupplierService: update stock for purchase error: $e");
    }

    // 3. Update supplier debt with remaining unpaid debt
    final newUnpaid = sup.unpaidBalance + remainingDebt;
    sup = sup.copyWith(
      unpaidBalance: newUnpaid,
      productPrices: updatedSupPrices,
      productUsualStock: updatedSupStocks,
    );
    await updateSupplier(sup);

    // 4. Jika ada pembayaran langsung saat pembelian (actualPaid > 0), potong saldo kas/bank terkait
    if (actualPaid > 0) {
      try {
        final pmService = PaymentMethodService(db);
        final pms = await pmService.getPaymentMethods(storeId);
        PaymentMethod? selectedPm;
        if (paymentMethodId != null && paymentMethodId.isNotEmpty) {
          selectedPm = pms.cast<PaymentMethod?>().firstWhere((m) => m?.id == paymentMethodId, orElse: () => null);
        }
        selectedPm ??= pms.cast<PaymentMethod?>().firstWhere(
          (m) => m?.name.toLowerCase() == (paymentMethod ?? '').toLowerCase() ||
                 m?.type.toLowerCase() == (paymentMethod ?? '').toLowerCase() ||
                 ((paymentMethod ?? '').toLowerCase().contains('kas') && m?.type.toLowerCase() == 'cash'),
          orElse: () => pms.isNotEmpty ? pms.first : null,
        );

        if (selectedPm != null) {
          await pmService.addOutflow(
            storeId,
            selectedPm,
            actualPaid,
            notes: 'Pembelian Stok Supplier: ${sup.name} ($txNo)${effectiveStatus == 'hutang' ? ' [Bayar Sebagian]' : ' [Lunas]'}',
          );
        }
      } catch (e) {
        debugPrint("SupplierService: deduct cash for purchase error: $e");
      }
    }

    // 5. Save to prefs cache
    await _saveTransactionToPrefs(storeId, tx);

    return tx;
  }

  /// Catat Pembayaran Hutang ke Supplier (BH-xxxx)
  /// - Mengurangi hutang berjalan supplier
  /// - Memotong saldo Kas / Bank (bisa minus)
  Future<SupplierTransaction> recordPayment({
    required String storeId,
    required String supplierId,
    required double amount,
    required String paymentMethod,
    String? paymentMethodId,
    String? notes,
    DateTime? customDate,
  }) async {
    await _ensureTable();
    final suppliers = await getSuppliers(storeId);
    final sup = suppliers.firstWhere((s) => s.id == supplierId);

    final txId = 'tx_${_uuid.v4().substring(0, 8)}';
    final txNo = await generateNextTransactionNo(storeId, 'BH');
    final now = customDate ?? DateTime.now();

    final tx = SupplierTransaction(
      id: txId,
      storeId: storeId,
      supplierId: supplierId,
      transactionNo: txNo,
      type: 'payment',
      totalAmount: amount,
      paymentStatus: 'lunas',
      paymentMethod: paymentMethod,
      paymentMethodId: paymentMethodId,
      items: const [],
      notes: notes,
      createdAt: now,
    );

    // 1. Insert to DB
    try {
      await db.customInsert(
        'INSERT INTO supplier_transactions (id, store_id, supplier_id, transaction_no, type, total_amount, payment_status, payment_method, payment_method_id, items_json, notes, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        variables: [
          Variable.withString(tx.id),
          Variable.withString(tx.storeId),
          Variable.withString(tx.supplierId),
          Variable.withString(tx.transactionNo),
          Variable.withString(tx.type),
          Variable.withReal(tx.totalAmount),
          Variable.withString(tx.paymentStatus),
          Variable.withString(tx.paymentMethod ?? ''),
          Variable.withString(tx.paymentMethodId ?? ''),
          Variable.withString('[]'),
          Variable.withString(tx.notes ?? ''),
          Variable.withString(tx.createdAt.toIso8601String()),
        ],
      );
    } catch (e) {
      debugPrint("SupplierService: insert payment tx error: $e");
    }

    // 2. Reduce supplier debt
    final newUnpaid = (sup.unpaidBalance - amount) > 0 ? (sup.unpaidBalance - amount) : 0.0;
    await updateSupplier(sup.copyWith(
      unpaidBalance: newUnpaid,
      lastSettledAt: now,
    ));

    // 3. Deduct cash/bank balance (bisa minus!)
    try {
      final pmService = PaymentMethodService(db);
      final pms = await pmService.getPaymentMethods(storeId);
      PaymentMethod? selectedPm;
      if (paymentMethodId != null && paymentMethodId.isNotEmpty) {
        selectedPm = pms.cast<PaymentMethod?>().firstWhere((m) => m?.id == paymentMethodId, orElse: () => null);
      }
      selectedPm ??= pms.cast<PaymentMethod?>().firstWhere(
        (m) => m?.name.toLowerCase() == paymentMethod.toLowerCase() ||
               m?.type.toLowerCase() == paymentMethod.toLowerCase() ||
               (paymentMethod.toLowerCase().contains('kas') && m?.type.toLowerCase() == 'cash'),
        orElse: () => pms.isNotEmpty ? pms.first : null,
      );

      if (selectedPm != null) {
        await pmService.addOutflow(
          storeId,
          selectedPm,
          amount,
          notes: 'Bayar Hutang Supplier: ${sup.name} ($txNo)',
        );
      } else {
        // Fallback expense
        final expService = ExpenseService(db);
        await expService.createExpense(
          storeId: storeId,
          category: 'Pelunasan Supplier',
          amount: amount,
          date: now,
          notes: 'Bayar Hutang Supplier: ${sup.name} ($txNo via $paymentMethod)',
        );
      }
    } catch (e) {
      debugPrint("SupplierService: payment outflow error: $e");
    }

    // 4. Also record settlement record for backward-compatibility
    try {
      await db.customInsert(
        'INSERT INTO supplier_settlements (id, supplier_id, store_id, amount, settled_at, payment_method, notes) VALUES (?, ?, ?, ?, ?, ?, ?)',
        variables: [
          Variable.withString(txId),
          Variable.withString(supplierId),
          Variable.withString(storeId),
          Variable.withReal(amount),
          Variable.withString(now.toIso8601String()),
          Variable.withString(paymentMethod),
          Variable.withString(notes ?? ''),
        ],
      );
    } catch (_) {}

    // 5. Save to prefs cache
    await _saveTransactionToPrefs(storeId, tx);

    return tx;
  }

  /// Catat Retur Barang ke Supplier (RB-xxxx)
  /// - Stok produk otomatis dikurangi
  /// - Jika pembelian sebelumnya LUNAS: dana dikembalikan ke saldo/metode pembayaran (inflow), hutang supplier tidak berubah.
  /// - Jika pembelian sebelumnya MASIH HUTANG: tidak ada uang kembali ke kas, melainkan memotong saldo hutang ke supplier.
  Future<SupplierTransaction> recordReturn({
    required String storeId,
    required String supplierId,
    required List<SupplierTransactionItem> items,
    String? notes,
    bool isPurchaseLunas = false,
    String? paymentMethod,
    String? paymentMethodId,
  }) async {
    await _ensureTable();
    final suppliers = await getSuppliers(storeId);
    final sup = suppliers.firstWhere((s) => s.id == supplierId);

    final txId = 'tx_${_uuid.v4().substring(0, 8)}';
    final txNo = await generateNextTransactionNo(storeId, 'RB');
    final now = DateTime.now();

    final totalAmount = items.fold<double>(0.0, (sum, i) => sum + i.subtotal);
    final double paidAmt = isPurchaseLunas ? totalAmount : 0.0;
    final String effectiveStatus = isPurchaseLunas ? 'lunas' : 'hutang';

    final tx = SupplierTransaction(
      id: txId,
      storeId: storeId,
      supplierId: supplierId,
      transactionNo: txNo,
      type: 'return',
      totalAmount: totalAmount,
      paidAmount: paidAmt,
      paymentStatus: effectiveStatus,
      paymentMethod: paymentMethod,
      paymentMethodId: paymentMethodId,
      items: items,
      notes: notes,
      createdAt: now,
    );

    // 1. Insert to DB
    try {
      await db.customInsert(
        'INSERT INTO supplier_transactions (id, store_id, supplier_id, transaction_no, type, total_amount, paid_amount, payment_status, payment_method, payment_method_id, items_json, notes, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        variables: [
          Variable.withString(tx.id),
          Variable.withString(tx.storeId),
          Variable.withString(tx.supplierId),
          Variable.withString(tx.transactionNo),
          Variable.withString(tx.type),
          Variable.withReal(tx.totalAmount),
          Variable.withReal(tx.paidAmount),
          Variable.withString(tx.paymentStatus),
          Variable.withString(tx.paymentMethod ?? ''),
          Variable.withString(tx.paymentMethodId ?? ''),
          Variable.withString(jsonEncode(items.map((e) => e.toJson()).toList())),
          Variable.withString(tx.notes ?? ''),
          Variable.withString(tx.createdAt.toIso8601String()),
        ],
      );
    } catch (e) {
      debugPrint("SupplierService: insert return tx error: $e");
    }

    // 2. Decrease stock quantity for each returned product
    try {
      for (final item in items) {
        if (item.productId.isEmpty || item.quantity <= 0) continue;
        final p = await (db.select(db.products)..where((t) => t.id.equals(item.productId))).getSingleOrNull();
        if (p != null) {
          final curStock = p.stockQuantity ?? 0.0;
          final updatedStock = (curStock - item.quantity) > 0 ? (curStock - item.quantity) : 0.0;
          await (db.update(db.products)..where((t) => t.id.equals(p.id))).write(
            ProductsCompanion(
              stockQuantity: Value(updatedStock),
              lastUpdated: Value(DateTime.now()),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("SupplierService: decrease stock for return error: $e");
    }

    // 3. Financial handling:
    // Jika Lunas -> Kembalikan dana ke saldo akun pembayaran (Inflow)
    // Jika Hutang -> Potong hutang ke supplier tanpa ada uang masuk ke kas
    if (isPurchaseLunas && totalAmount > 0) {
      try {
        final pmService = PaymentMethodService(db);
        final pms = await pmService.getPaymentMethods(storeId);
        PaymentMethod? selectedPm;
        if (paymentMethodId != null && paymentMethodId.isNotEmpty) {
          selectedPm = pms.cast<PaymentMethod?>().firstWhere((m) => m?.id == paymentMethodId, orElse: () => null);
        }
        selectedPm ??= pms.cast<PaymentMethod?>().firstWhere(
          (m) => m?.name.toLowerCase() == (paymentMethod ?? '').toLowerCase() ||
                 m?.type.toLowerCase() == (paymentMethod ?? '').toLowerCase() ||
                 ((paymentMethod ?? '').toLowerCase().contains('kas') && m?.type.toLowerCase() == 'cash'),
          orElse: () => pms.isNotEmpty ? pms.first : null,
        );

        if (selectedPm != null) {
          await pmService.addInflow(
            storeId,
            selectedPm,
            totalAmount,
            notes: 'Pengembalian Dana Retur Barang ke ${sup.name} ($txNo) [${selectedPm.name}]',
          );
        }
      } catch (e) {
        debugPrint("SupplierService: refund cash for return error: $e");
      }
    } else {
      // Potong saldo hutang berjalan ke supplier
      final newUnpaid = (sup.unpaidBalance - totalAmount) > 0 ? (sup.unpaidBalance - totalAmount) : 0.0;
      await updateSupplier(sup.copyWith(unpaidBalance: newUnpaid));
    }

    // 4. Save to prefs cache
    await _saveTransactionToPrefs(storeId, tx);

    return tx;
  }

  /// Get list of transactions for a specific supplier
  Future<List<SupplierTransaction>> getSupplierTransactions(String storeId, String supplierId) async {
    await _ensureTable();
    try {
      final rows = await db.customSelect(
        'SELECT * FROM supplier_transactions WHERE store_id = ? AND supplier_id = ? ORDER BY created_at DESC',
        variables: [Variable.withString(storeId), Variable.withString(supplierId)],
      ).get();

      if (rows.isNotEmpty) {
        return rows.map((row) {
          final data = row.data;
          final itemsRaw = data['items_json'];
          List<SupplierTransactionItem> items = [];
          if (itemsRaw != null && itemsRaw is String && itemsRaw.isNotEmpty) {
            try {
              final decoded = jsonDecode(itemsRaw) as List;
              items = decoded.map((e) => SupplierTransactionItem.fromJson(Map<String, dynamic>.from(e as Map))).toList();
            } catch (_) {}
          }

          final tot = (data['total_amount'] as num?)?.toDouble() ?? 0.0;
          final status = data['payment_status'] as String? ?? 'hutang';
          final pAmount = (data['paid_amount'] as num?)?.toDouble() ??
              (status.toLowerCase() == 'lunas' ? tot : 0.0);

          return SupplierTransaction(
            id: data['id'] as String,
            storeId: data['store_id'] as String,
            supplierId: data['supplier_id'] as String,
            transactionNo: data['transaction_no'] as String,
            type: data['type'] as String,
            totalAmount: tot,
            paidAmount: pAmount,
            paymentStatus: status,
            paymentMethod: data['payment_method'] as String?,
            paymentMethodId: data['payment_method_id'] as String?,
            items: items,
            notes: data['notes'] as String?,
            createdAt: DateTime.tryParse(data['created_at']?.toString() ?? '') ?? DateTime.now(),
          );
        }).toList();
      }
    } catch (e) {
      debugPrint("SupplierService: getSupplierTransactions error: $e");
    }

    // Fallback to prefs
    final all = await _loadTransactionsFromPrefs(storeId);
    return all.where((t) => t.supplierId == supplierId).toList();
  }

  /// Get list of all supplier transactions for a store across all suppliers
  Future<List<SupplierTransaction>> getAllStoreTransactions(String storeId) async {
    await _ensureTable();
    try {
      final rows = await db.customSelect(
        'SELECT * FROM supplier_transactions WHERE store_id = ? ORDER BY created_at DESC',
        variables: [Variable.withString(storeId)],
      ).get();

      if (rows.isNotEmpty) {
        return rows.map((row) {
          final data = row.data;
          final itemsRaw = data['items_json'];
          List<SupplierTransactionItem> items = [];
          if (itemsRaw != null && itemsRaw is String && itemsRaw.isNotEmpty) {
            try {
              final decoded = jsonDecode(itemsRaw) as List;
              items = decoded.map((e) => SupplierTransactionItem.fromJson(Map<String, dynamic>.from(e as Map))).toList();
            } catch (_) {}
          }

          final tot = (data['total_amount'] as num?)?.toDouble() ?? 0.0;
          final status = data['payment_status'] as String? ?? 'hutang';
          final pAmount = (data['paid_amount'] as num?)?.toDouble() ??
              (status.toLowerCase() == 'lunas' ? tot : 0.0);

          return SupplierTransaction(
            id: data['id'] as String,
            storeId: data['store_id'] as String,
            supplierId: data['supplier_id'] as String,
            transactionNo: data['transaction_no'] as String,
            type: data['type'] as String,
            totalAmount: tot,
            paidAmount: pAmount,
            paymentStatus: status,
            paymentMethod: data['payment_method'] as String?,
            paymentMethodId: data['payment_method_id'] as String?,
            items: items,
            notes: data['notes'] as String?,
            createdAt: DateTime.tryParse(data['created_at']?.toString() ?? '') ?? DateTime.now(),
          );
        }).toList();
      }
    } catch (e) {
      debugPrint("SupplierService: getAllStoreTransactions error: $e");
    }

    return await _loadTransactionsFromPrefs(storeId);
  }

  Future<void> deleteSupplierTransaction(String transactionId, String storeId) async {
    await _ensureTable();
    try {
      await db.customStatement(
        'DELETE FROM supplier_transactions WHERE id = ?',
        [transactionId],
      );
    } catch (e) {
      debugPrint("SupplierService: delete tx error: $e");
    }

    final all = await _loadTransactionsFromPrefs(storeId);
    all.removeWhere((t) => t.id == transactionId);
    await _saveTransactionsListToPrefs(storeId, all);
  }

  Future<void> _saveTransactionToPrefs(String storeId, SupplierTransaction tx) async {
    try {
      final all = await _loadTransactionsFromPrefs(storeId);
      all.insert(0, tx);
      await _saveTransactionsListToPrefs(storeId, all);
    } catch (e) {
      debugPrint("SupplierService: save tx to prefs error: $e");
    }
  }

  Future<void> _saveTransactionsListToPrefs(String storeId, List<SupplierTransaction> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'supplier_transactions_$storeId';
      final encoded = jsonEncode(list.map((e) => e.toJson()).toList());
      await prefs.setString(key, encoded);
    } catch (_) {}
  }

  Future<List<SupplierTransaction>> _loadTransactionsFromPrefs(String storeId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'supplier_transactions_$storeId';
      final raw = prefs.getString(key);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List;
        return decoded.map((e) => SupplierTransaction.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      }
    } catch (_) {}
    return [];
  }

}
