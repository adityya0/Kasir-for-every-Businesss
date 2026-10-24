import 'package:flutter/material.dart';
import 'app_database.dart';
import 'package:drift/drift.dart';

class ReportService {
  final AppDatabase db;

  ReportService(this.db);

  /// Fetches all transactions for a specific store with details
  Future<List<Map<String, dynamic>>> getAllTransactions(
    String storeId, {
    DateTime? dateLimit,
    DateTime? startDate,
    DateTime? endDate,
    String? cashierId,
  }) async {
    debugPrint(
      "ReportService.getAllTransactions: id=$storeId, cashier=$cashierId, dateLimit=$dateLimit, start=$startDate, end=$endDate",
    );

    final txQuery = db.select(db.transactions)
      ..where((t) => t.storeId.equals(storeId));

    if (cashierId != null && cashierId.isNotEmpty) {
      txQuery.where((t) => t.cashierId.equals(cashierId));
    }

    if (startDate != null) {
      txQuery.where((t) => t.createdAt.isBiggerOrEqualValue(startDate));
    } else if (dateLimit != null) {
      txQuery.where((t) => t.createdAt.isBiggerOrEqualValue(dateLimit));
    }

    if (endDate != null) {
      txQuery.where((t) => t.createdAt.isSmallerOrEqualValue(endDate));
    }

    txQuery.orderBy([(t) => OrderingTerm.desc(t.createdAt)]);

    final response = await txQuery.get();
    final List<Map<String, dynamic>> results = [];

    for (var tx in response) {
      final txMap = tx.toJson();

      // Fetch profile
      if (tx.cashierId != null) {
        final profile =
            await (db.select(db.profiles)
                  ..where((t) => t.id.equals(tx.cashierId!))
                  ..limit(1))
                .getSingleOrNull();
        if (profile != null) {
          txMap['profiles'] = profile.toJson();
        }
      }

      // Fetch transaction items
      final items = await (db.select(
        db.transactionItems,
      )..where((t) => t.transactionId.equals(tx.id))).get();

      final List<Map<String, dynamic>> itemsWithProducts = [];
      for (var item in items) {
        final itemMap = item.toJson();
        // Fetch product name
        if (item.productId != null) {
          final productQuery = db.select(db.products)
            ..where((t) => t.id.equals(item.productId!))
            ..limit(1);
          final product = await productQuery.getSingleOrNull();

          if (product != null) {
            itemMap['products'] = {'name': product.name};
          }
        }
        itemsWithProducts.add(itemMap);
      }
      txMap['transaction_items'] = itemsWithProducts;
      results.add(txMap);
    }

    debugPrint(
      "ReportService.getAllTransactions: Query complete. Found ${results.length} items.",
    );
    return results;
  }

  /// Deletes transactions and their items older than 30 days
  Future<void> cleanupOldTransactions(String storeId) async {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

    try {
      // Transaction items update/delete can be handled by foreign keys or manually.
      // In Drift, we might need to delete items manually if not cascaded.
      final oldTxs =
          await (db.select(db.transactions)..where(
                (t) =>
                    t.storeId.equals(storeId) &
                    t.createdAt.isSmallerThanValue(thirtyDaysAgo),
              ))
              .get();

      await db.transaction(() async {
        for (var tx in oldTxs) {
          await (db.delete(
            db.transactionItems,
          )..where((t) => t.transactionId.equals(tx.id))).go();
          await (db.delete(
            db.transactions,
          )..where((t) => t.id.equals(tx.id))).go();
        }
      });
    } catch (e) {
      debugPrint("Error cleaning up old transactions: $e");
    }
  }

  /// Fetches cashier performance data (sales volume and count)
  Future<List<Map<String, dynamic>>> getCashierPerformance(
    String storeId, {
    DateTime? dateLimit,
  }) async {
    final txQuery = db.select(db.transactions)
      ..where((t) => t.storeId.equals(storeId));

    if (dateLimit != null) {
      txQuery.where((t) => t.createdAt.isBiggerOrEqualValue(dateLimit));
    }

    final response = await txQuery.get();

    // Group and aggregate data
    final Map<String, Map<String, dynamic>> performance = {};

    for (var tx in response) {
      final id = tx.cashierId ?? 'unknown';
      final amount = tx.totalAmount ?? 0.0;

      if (!performance.containsKey(id)) {
        // Fetch profile
        final profile =
            await (db.select(db.profiles)
                  ..where((t) => t.id.equals(id))
                  ..limit(1))
                .getSingleOrNull();
        final name = profile?.fullName ?? 'Unknown';

        performance[id] = {
          'id': id,
          'name': name,
          'avatar': profile?.avatarUrl,
          'totalSales': 0.0,
          'transactionCount': 0,
        };
      }

      performance[id]!['totalSales'] += amount;
      performance[id]!['transactionCount'] += 1;
    }

    return performance.values.toList();
  }

  /// Fetches the current status (Online/Offline/Break) and attendance for each staff
  Future<List<Map<String, dynamic>>> getStaffStatus(String storeId) async {
    // 1. Get all profiles for the store with role 'cashier'
    final staffResponse =
        await (db.select(db.profiles)..where(
              (t) => t.storeId.equals(storeId) & t.role.equals('cashier'),
            ))
            .get();

    final List<Map<String, dynamic>> staff = staffResponse
        .map((e) => e.toJson())
        .toList();

    // 2. Get today's attendance logs
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    final logsResponse =
        await (db.select(db.attendanceLogs)..where(
              (t) =>
                  t.storeId.equals(storeId) &
                  t.clockIn.isBiggerOrEqualValue(startOfDay),
            ))
            .get();

    final List<Map<String, dynamic>> logs = logsResponse
        .map((e) => e.toJson())
        .toList();

    // 3. Map status to staff
    return staff.map((s) {
      final Map<String, dynamic>? log = logs
          .cast<Map<String, dynamic>?>()
          .firstWhere((l) => l?['user_id'] == s['id'], orElse: () => null);

      String status = 'offline';
      String? clockIn;
      String? clockOut;

      if (log != null) {
        if (log['clock_out'] != null) {
          status = 'offline'; // Finished for the day
          clockIn = log['clock_in'];
          clockOut = log['clock_out'];
        } else if (log['status'] == 'break') {
          status = 'break';
          clockIn = log['clock_in'];
        } else {
          status = 'online';
          clockIn = log['clock_in'];
        }
      }

      final res = Map<String, dynamic>.from(s);
      res['status'] = status;
      res['clock_in'] = clockIn;
      res['clock_out'] = clockOut;
      return res;
    }).toList();
  }

  /// Reset / delete all transactions and their items for a store
  Future<int> resetStoreTransactions(String storeId, {bool restoreStock = false}) async {
    int deletedCount = 0;
    await db.transaction(() async {
      final txs = await (db.select(db.transactions)..where((t) => t.storeId.equals(storeId))).get();
      deletedCount = txs.length;
      if (txs.isEmpty) return;

      final txIds = txs.map((t) => t.id).toList();

      // If requested, restore product stock quantities
      if (restoreStock) {
        for (var tx in txs) {
          final items = await (db.select(db.transactionItems)..where((t) => t.transactionId.equals(tx.id))).get();
          for (var item in items) {
            if (item.productId != null && item.quantity != null && item.quantity! > 0) {
              await (db.update(db.products)..where((p) => p.id.equals(item.productId!) & p.isStockManaged.equals(true)))
                  .write(ProductsCompanion.custom(
                stockQuantity: db.products.stockQuantity + Variable(item.quantity!.toDouble()),
              ));
            }
          }
        }
      }

      // Delete transaction items in chunks
      const chunkSize = 200;
      for (var i = 0; i < txIds.length; i += chunkSize) {
        final chunk = txIds.sublist(i, i + chunkSize > txIds.length ? txIds.length : i + chunkSize);
        await (db.delete(db.transactionItems)..where((t) => t.transactionId.isIn(chunk))).go();
      }

      // Delete all transactions for this store
      await (db.delete(db.transactions)..where((t) => t.storeId.equals(storeId))).go();
    });

    return deletedCount;
  }
}
