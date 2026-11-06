import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/app_database.dart';
import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ChartRange { today, sevenDays, thirtyDays, month, allTime, custom }

class AnalyticsController extends ChangeNotifier {
  final AppDatabase _db;

  AnalyticsController(this._db);

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  double _totalSales = 0;
  double get totalSales => _totalSales;

  double _totalDebt = 0;
  double get totalDebt => _totalDebt;

  double _todaySales = 0;
  double get todaySales => _todaySales;

  double _thisWeekSales = 0;
  double get thisWeekSales => _thisWeekSales;

  double _thisMonthSales = 0;
  double get thisMonthSales => _thisMonthSales;

  double _todaySalesCash = 0;
  double get todaySalesCash => _todaySalesCash;
  double _todaySalesDigital = 0;
  double get todaySalesDigital => _todaySalesDigital;

  double _sevenDaysSalesCash = 0;
  double get sevenDaysSalesCash => _sevenDaysSalesCash;
  double _sevenDaysSalesDigital = 0;
  double get sevenDaysSalesDigital => _sevenDaysSalesDigital;

  double _thirtyDaysSalesCash = 0;
  double get thirtyDaysSalesCash => _thirtyDaysSalesCash;
  double _thirtyDaysSalesDigital = 0;
  double get thirtyDaysSalesDigital => _thirtyDaysSalesDigital;

  double _thisMonthSalesCash = 0;
  double get thisMonthSalesCash => _thisMonthSalesCash;
  double _thisMonthSalesDigital = 0;
  double get thisMonthSalesDigital => _thisMonthSalesDigital;

  double _customSalesCash = 0;
  double get customSalesCash => _customSalesCash;
  double _customSalesDigital = 0;
  double get customSalesDigital => _customSalesDigital;

  double _allTimeSales = 0;
  double get allTimeSales => _allTimeSales;
  double _allTimeSalesCash = 0;
  double get allTimeSalesCash => _allTimeSalesCash;
  double _allTimeSalesDigital = 0;
  double get allTimeSalesDigital => _allTimeSalesDigital;

  double _inventorySellingValue = 0;
  double get inventorySellingValue => _inventorySellingValue;
  double _inventoryCostValue = 0;
  double get inventoryCostValue => _inventoryCostValue;
  double _inventoryPotentialProfit = 0;
  double get inventoryPotentialProfit => _inventoryPotentialProfit;
  double _inventoryStockCount = 0;
  double get inventoryStockCount => _inventoryStockCount;

  final double _lastWeekSales = 0;
  final double _lastMonthSales = 0;

  int _employeeCount = 0;
  int get employeeCount => _employeeCount;

  int _totalTransactionCount = 0;
  int get totalTransactionCount => _totalTransactionCount;

  int _totalProductCount = 0;
  int get totalProductCount => _totalProductCount;

  List<Map<String, dynamic>> _chartData = [];
  List<Map<String, dynamic>> get chartData => _chartData;

  ChartRange _selectedRange = ChartRange.sevenDays;
  ChartRange get selectedRange => _selectedRange;

  List<Map<String, dynamic>> _topProducts = [];
  List<Map<String, dynamic>> get topProducts => _topProducts;

  List<Map<String, dynamic>> _topTables = [];
  List<Map<String, dynamic>> get topTables => _topTables;

  List<Map<String, dynamic>> _lowStockProducts = [];
  List<Map<String, dynamic>> get lowStockProducts => _lowStockProducts;

  int _stockThreshold = 10; // Default threshold
  int get stockThreshold => _stockThreshold;

  static const String _stockThresholdKey = 'stock_threshold';

  void setStockThreshold(int value) async {
    _stockThreshold = value;
    _fetchLowStockProducts();
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_stockThresholdKey, value);
  }

  DateTime? _customStartDate;
  DateTime? _customEndDate;
  DateTime? get customStartDate => _customStartDate;
  DateTime? get customEndDate => _customEndDate;

  double _todayExpenses = 0;
  double get todayExpenses => _todayExpenses;
  double _sevenDaysExpenses = 0;
  double get sevenDaysExpenses => _sevenDaysExpenses;
  double _thirtyDaysExpenses = 0;
  double get thirtyDaysExpenses => _thirtyDaysExpenses;
  double _thisMonthExpenses = 0;
  double get thisMonthExpenses => _thisMonthExpenses;
  double _customExpenses = 0;
  double get customExpenses => _customExpenses;
  double _allTimeExpenses = 0;
  double get allTimeExpenses => _allTimeExpenses;

  double _todaySalaryExpenses = 0;
  double get todaySalaryExpenses => _todaySalaryExpenses;
  double _sevenDaysSalaryExpenses = 0;
  double get sevenDaysSalaryExpenses => _sevenDaysSalaryExpenses;
  double _thirtyDaysSalaryExpenses = 0;
  double get thirtyDaysSalaryExpenses => _thirtyDaysSalaryExpenses;
  double _thisMonthSalaryExpenses = 0;
  double get thisMonthSalaryExpenses => _thisMonthSalaryExpenses;
  double _customSalaryExpenses = 0;
  double get customSalaryExpenses => _customSalaryExpenses;
  double _allTimeSalaryExpenses = 0;
  double get allTimeSalaryExpenses => _allTimeSalaryExpenses;

  double _todayCOGS = 0;
  double get todayCOGS => _todayCOGS;
  double _sevenDaysCOGS = 0;
  double get sevenDaysCOGS => _sevenDaysCOGS;
  double _thirtyDaysCOGS = 0;
  double get thirtyDaysCOGS => _thirtyDaysCOGS;
  double _thisMonthCOGS = 0;
  double get thisMonthCOGS => _thisMonthCOGS;
  double _customCOGS = 0;
  double get customCOGS => _customCOGS;
  double _allTimeCOGS = 0;
  double get allTimeCOGS => _allTimeCOGS;

  int _todayTransactionCount = 0;
  int get todayTransactionCount => _todayTransactionCount;
  int _sevenDaysTransactionCount = 0;
  int get sevenDaysTransactionCount => _sevenDaysTransactionCount;
  int _thirtyDaysTransactionCount = 0;
  int get thirtyDaysTransactionCount => _thirtyDaysTransactionCount;
  int _customTransactionCount = 0;
  int get customTransactionCount => _customTransactionCount;
  int _allTimeTransactionCount = 0;
  int get allTimeTransactionCount => _allTimeTransactionCount;

  int _todayExpenseCount = 0;
  int get todayExpenseCount => _todayExpenseCount;
  int _sevenDaysExpenseCount = 0;
  int get sevenDaysExpenseCount => _sevenDaysExpenseCount;
  int _thirtyDaysExpenseCount = 0;
  int get thirtyDaysExpenseCount => _thirtyDaysExpenseCount;
  int _customExpenseCount = 0;
  int get customExpenseCount => _customExpenseCount;
  int _allTimeExpenseCount = 0;
  int get allTimeExpenseCount => _allTimeExpenseCount;

  double _customSales = 0;
  double get customSales => _customSales;

  String? _storeId;

  Future<void> init(String? storeId) async {
    if (storeId == null) {
      return;
    }
    _storeId = storeId;
    
    final prefs = await SharedPreferences.getInstance();
    _stockThreshold = prefs.getInt(_stockThresholdKey) ?? 10;
    
    await refreshData();
  }

  Future<void> setRange(ChartRange range, {DateTime? start, DateTime? end}) async {
    _selectedRange = range;
    if (range == ChartRange.custom) {
      _customStartDate = start;
      _customEndDate = end;
    }
    
    // Trigger a full refresh to update all stats, top products, and chart data for the new range
    await refreshData();
  }

  Future<void> refreshData() async {
    if (_storeId == null) {
      return;
    }
    _isLoading = true;
    notifyListeners();

    try {
      await Future.wait([
        _fetchTotalSales(),
        _fetchPeriodicData(),
        _fetchChartData(),
        _fetchCounts(),
        _fetchTopProducts(),
        _fetchTopTables(),
        _fetchLowStockProducts(),
        _fetchTotalDebt(),
        _fetchInventoryValuation(),
      ]);
    } catch (e) {
      debugPrint("AnalyticsController: Error refreshing data: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchTotalSales() async {
    final query = _db.selectOnly(_db.transactions)
      ..addColumns([_db.transactions.totalAmount.sum()])
      ..where(_db.transactions.storeId.equals(_storeId!));

    final result = await query.getSingle();
    _totalSales = result.read(_db.transactions.totalAmount.sum()) ?? 0;
  }

  Future<void> _fetchTotalDebt() async {
    final query = _db.select(_db.transactions)
      ..where((t) => t.storeId.equals(_storeId!) & t.status.equals('debt'));
    final results = await query.get();
    
    _totalDebt = results.fold(0.0, (sum, tx) {
      final total = tx.totalAmount ?? 0;
      final paid = tx.cashReceived ?? 0;
      return sum + (total - paid);
    });
  }

  Future<void> _fetchPeriodicData() async {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final startOfSevenDays = startOfToday.subtract(const Duration(days: 6));
    final startOfThirtyDays = startOfToday.subtract(const Duration(days: 29));
    final startOfThisMonth = DateTime(now.year, now.month, 1);

    // For custom range, use the custom dates; otherwise fetch from earliest needed period
    final customStart = _customStartDate ?? startOfThirtyDays;
    final customEnd = _customEndDate != null
        ? DateTime(_customEndDate!.year, _customEndDate!.month, _customEndDate!.day, 23, 59, 59)
        : now;

    // Fetch Transactions and Items for COGS for the current store
    final txQuery =
        _db.select(_db.transactions).join([
          leftOuterJoin(
            _db.transactionItems,
            _db.transactionItems.transactionId.equalsExp(_db.transactions.id),
          ),
          leftOuterJoin(
            _db.products,
            _db.products.id.equalsExp(_db.transactionItems.productId),
          ),
        ])..where(_db.transactions.storeId.equals(_storeId!));

    final txRows = await txQuery.get();

    _todaySales = 0;
    _todaySalesCash = 0;
    _todaySalesDigital = 0;
    _thisWeekSales = 0;
    _thisMonthSales = 0;
    _thisMonthSalesCash = 0;
    _thisMonthSalesDigital = 0;
    _sevenDaysSales = 0;
    _sevenDaysSalesCash = 0;
    _sevenDaysSalesDigital = 0;
    _thirtyDaysSales = 0;
    _thirtyDaysSalesCash = 0;
    _thirtyDaysSalesDigital = 0;
    _customSales = 0;
    _customSalesCash = 0;
    _customSalesDigital = 0;
    _allTimeSales = 0;
    _allTimeSalesCash = 0;
    _allTimeSalesDigital = 0;

    _todayCOGS = 0;
    _thisMonthCOGS = 0;
    _sevenDaysCOGS = 0;
    _thirtyDaysCOGS = 0;
    _customCOGS = 0;
    _allTimeCOGS = 0;

    _todayTransactionCount = 0;
    _sevenDaysTransactionCount = 0;
    _thirtyDaysTransactionCount = 0;
    _customTransactionCount = 0;
    _allTimeTransactionCount = 0;

    Map<String, bool> countedTxs = {};

    for (var row in txRows) {
      final tx = row.readTable(_db.transactions);
      final item = row.readTableOrNull(_db.transactionItems);
      final product = row.readTableOrNull(_db.products);

      final date = tx.createdAt!;
      final amount = tx.totalAmount ?? 0;
      final txId = tx.id;

      bool isNewTx = !countedTxs.containsKey(txId);
      if (isNewTx) {
        countedTxs[txId] = true;
        
        final paymentMethod = (tx.paymentMethod ?? '').toLowerCase();
        final isCash = paymentMethod == 'cash' || paymentMethod == 'tunai';

        _allTimeSales += amount;
        if (isCash) {
          _allTimeSalesCash += amount;
        } else {
          _allTimeSalesDigital += amount;
        }
        _allTimeTransactionCount++;

        if (!date.isBefore(startOfToday)) {
          _todaySales += amount;
          if (isCash) {
            _todaySalesCash += amount;
          } else {
            _todaySalesDigital += amount;
          }
          _todayTransactionCount++;
        }
        if (!date.isBefore(startOfSevenDays)) {
          _sevenDaysSales += amount;
          if (isCash) {
            _sevenDaysSalesCash += amount;
          } else {
            _sevenDaysSalesDigital += amount;
          }
          _sevenDaysTransactionCount++;
        }
        if (!date.isBefore(startOfThirtyDays)) {
          _thirtyDaysSales += amount;
          if (isCash) {
            _thirtyDaysSalesCash += amount;
          } else {
            _thirtyDaysSalesDigital += amount;
          }
          _thirtyDaysTransactionCount++;
        }
        if (!date.isBefore(startOfThisMonth)) {
          _thisMonthSales += amount;
          if (isCash) {
            _thisMonthSalesCash += amount;
          } else {
            _thisMonthSalesDigital += amount;
          }
        }
        // Custom range check
        if (!date.isBefore(customStart) && !date.isAfter(customEnd)) {
          _customSales += amount;
          if (isCash) {
            _customSalesCash += amount;
          } else {
            _customSalesDigital += amount;
          }
          _customTransactionCount++;
        }
      }

      // COGS
      if (item != null) {
        final qty = (item.quantity ?? 0).toDouble();
        final cost = (product?.basePrice ?? product?.buyPrice ?? 0) * qty;

        _allTimeCOGS += cost;

        if (!date.isBefore(startOfToday)) {
          _todayCOGS += cost;
        }
        if (!date.isBefore(startOfSevenDays)) {
          _sevenDaysCOGS += cost;
        }
        if (!date.isBefore(startOfThirtyDays)) {
          _thirtyDaysCOGS += cost;
        }
        if (!date.isBefore(startOfThisMonth)) {
          _thisMonthCOGS += cost;
        }
        if (!date.isBefore(customStart) && !date.isAfter(customEnd)) {
          _customCOGS += cost;
        }
      }
    }

    // Fetch Expenses for current store
    final expQuery = _db.select(_db.expenses)
      ..where((e) => e.storeId.equals(_storeId!));

    final exps = await expQuery.get();

    _todayExpenses = 0;
    _sevenDaysExpenses = 0;
    _thirtyDaysExpenses = 0;
    _thisMonthExpenses = 0;
    _customExpenses = 0;
    _allTimeExpenses = 0;

    _todaySalaryExpenses = 0;
    _sevenDaysSalaryExpenses = 0;
    _thirtyDaysSalaryExpenses = 0;
    _thisMonthSalaryExpenses = 0;
    _customSalaryExpenses = 0;
    _allTimeSalaryExpenses = 0;

    _todayExpenseCount = 0;
    _sevenDaysExpenseCount = 0;
    _thirtyDaysExpenseCount = 0;
    _customExpenseCount = 0;
    _allTimeExpenseCount = 0;

    for (var exp in exps) {
      final date = exp.date!;
      final amount = exp.amount ?? 0;
      final cat = exp.category.toLowerCase().trim();
      final notes = (exp.notes ?? '').toLowerCase().trim();

      // Penyesuaian stok, stok awal, modal, dan restock supplier adalah MODAL ASET STOK / BUKAN OPERASIONAL:
      final isNonOperational = cat.contains('supplier') ||
          cat.contains('restock') ||
          cat.contains('kulakan') ||
          cat.contains('pasokan') ||
          cat.contains('pembelian stok') ||
          cat.contains('beli stok') ||
          cat.contains('penyesuaian') ||
          cat.contains('stok awal') ||
          cat.contains('stok') ||
          cat.contains('modal') ||
          cat.contains('setor modal') ||
          cat.contains('prive') ||
          cat.contains('tarik') ||
          cat.contains('transfer') ||
          notes.contains('stok awal') ||
          notes.contains('penyesuaian stok') ||
          notes.contains('modal awal');

      if (isNonOperational) continue;

      final isSalary = cat == 'gaji' || cat == 'gaji & upah' || cat.contains('gaji');

      _allTimeExpenses += amount;
      _allTimeExpenseCount++;

      if (isSalary) {
        _allTimeSalaryExpenses += amount;
      }

      if (!date.isBefore(startOfToday)) {
        _todayExpenses += amount;
        _todayExpenseCount++;
        if (isSalary) _todaySalaryExpenses += amount;
      }
      if (!date.isBefore(startOfSevenDays)) {
        _sevenDaysExpenses += amount;
        _sevenDaysExpenseCount++;
        if (isSalary) _sevenDaysSalaryExpenses += amount;
      }
      if (!date.isBefore(startOfThirtyDays)) {
        _thirtyDaysExpenses += amount;
        _thirtyDaysExpenseCount++;
        if (isSalary) _thirtyDaysSalaryExpenses += amount;
      }
      if (!date.isBefore(startOfThisMonth)) {
        _thisMonthExpenses += amount;
        if (isSalary) _thisMonthSalaryExpenses += amount;
      }
      if (!date.isBefore(customStart) && !date.isAfter(customEnd)) {
        _customExpenses += amount;
        _customExpenseCount++;
        if (isSalary) _customSalaryExpenses += amount;
      }
    }
  }

  double _sevenDaysSales = 0;
  double get sevenDaysSales => _sevenDaysSales;
  double _thirtyDaysSales = 0;
  double get thirtyDaysSales => _thirtyDaysSales;

  Future<void> _fetchCounts() async {
    // 1. Employee Count
    final empCount =
        await (_db.selectOnly(_db.profiles)
              ..addColumns([_db.profiles.id.count()])
              ..where(
                _db.profiles.storeId.equals(_storeId!) &
                    _db.profiles.role.equals('cashier'),
              ))
            .getSingle();
    _employeeCount = empCount.read(_db.profiles.id.count()) ?? 0;

    // 2. Transaction Count (All Time)
    final txCount =
        await (_db.selectOnly(_db.transactions)
              ..addColumns([_db.transactions.id.count()])
              ..where(_db.transactions.storeId.equals(_storeId!)))
            .getSingle();
    _totalTransactionCount = txCount.read(_db.transactions.id.count()) ?? 0;

    // 3. Product Count
    final pCount =
        await (_db.selectOnly(_db.products)
              ..addColumns([_db.products.id.count()])
              ..where(
                _db.products.storeId.equals(_storeId!) &
                    _db.products.isDeleted.equals(false),
              ))
            .getSingle();
    _totalProductCount = pCount.read(_db.products.id.count()) ?? 0;
  }

  Future<void> _fetchInventoryValuation() async {
    final query = _db.select(_db.products)
      ..where((p) => p.storeId.equals(_storeId!) & p.isDeleted.equals(false));
    final products = await query.get();

    double totalSelling = 0;
    double totalCost = 0;
    double totalStock = 0;

    for (var p in products) {
      final qty = p.stockQuantity ?? 0;
      if (qty <= 0) continue;
      final price = p.salePrice ?? 0;
      final cost = p.buyPrice ?? p.basePrice ?? 0;

      totalSelling += (price * qty);
      totalCost += (cost * qty);
      totalStock += qty;
    }

    _inventorySellingValue = totalSelling;
    _inventoryCostValue = totalCost;
    _inventoryPotentialProfit = totalSelling - totalCost;
    _inventoryStockCount = totalStock;
  }

  // Adaptive chart label interval based on number of data points
  int _chartLabelInterval(int steps) {
    if (steps <= 7) return 1;
    if (steps <= 14) return 2;
    if (steps <= 31) return 5;
    if (steps <= 90) return 10;
    return (steps / 8).ceil();
  }

  int get chartLabelInterval => _chartLabelInterval(_chartData.length);

  Future<void> _fetchChartData() async {
    final now = DateTime.now();
    DateTime startDate;
    int steps;
    DateFormat format;

    switch (_selectedRange) {
      case ChartRange.today:
        startDate = DateTime(now.year, now.month, now.day);
        steps = 24;
        format = DateFormat('HH:mm');
        break;
      case ChartRange.sevenDays:
        startDate = DateTime(now.year, now.month, now.day)
            .subtract(const Duration(days: 6));
        steps = 7;
        format = DateFormat('dd/MM');
        break;
      case ChartRange.thirtyDays:
        startDate = DateTime(now.year, now.month, now.day)
            .subtract(const Duration(days: 29));
        steps = 30;
        format = DateFormat('dd/MM');
        break;
      case ChartRange.month:
        startDate = DateTime(now.year, now.month, 1);
        steps = DateTime(now.year, now.month + 1, 0).day;
        format = DateFormat('dd');
        break;
      case ChartRange.allTime:
        startDate = DateTime(2020, 1, 1);
        steps = 30;
        format = DateFormat('dd/MM');
        break;
      case ChartRange.custom:
        startDate = _customStartDate ??
            DateTime(now.year, now.month, now.day)
                .subtract(const Duration(days: 6));
        final customEnd = _customEndDate ?? now;
        steps = customEnd.difference(startDate).inDays + 1;
        // Adaptive format: use month name if range > 60 days
        format = steps > 60 ? DateFormat('MMM') : DateFormat('dd/MM');
        break;
    }

    final txs =
        await (_db.select(_db.transactions)..where(
              (t) =>
                  t.storeId.equals(_storeId!) &
                  t.createdAt.isBiggerOrEqualValue(startDate),
            ))
            .get();

    Map<String, double> dataMap = {};
    for (int i = 0; i < steps; i++) {
      DateTime stepDate;
      if (_selectedRange == ChartRange.today) {
        stepDate = startDate.add(Duration(hours: i));
      } else {
        stepDate = startDate.add(Duration(days: i));
      }
      final key = DateFormat('yyyy-MM-dd HH').format(stepDate);
      dataMap[key] = 0;
    }

    for (var tx in txs) {
      final date = tx.createdAt?.toLocal() ?? DateTime.now();

      String foundKey = '';
      if (_selectedRange == ChartRange.today) {
        final key = DateFormat('yyyy-MM-dd HH').format(date);
        if (dataMap.containsKey(key)) {
          foundKey = key;
        }
      } else {
        final dateKey = DateFormat('yyyy-MM-dd').format(date);
        // Find the first key in dataMap that starts with this date
        for (var k in dataMap.keys) {
          if (k.startsWith(dateKey)) {
            foundKey = k;
            break;
          }
        }
      }

      if (foundKey.isNotEmpty) {
        dataMap[foundKey] = dataMap[foundKey]! + (tx.totalAmount ?? 0);
      }
    }
    _chartData = dataMap.entries.map((e) {
      DateTime d = DateFormat('yyyy-MM-dd HH').parse(e.key);
      return {'date': e.key, 'amount': e.value, 'label': format.format(d)};
    }).toList();
  }

  Future<void> _fetchTopProducts() async {
    final now = DateTime.now();
    DateTime startDate = now;
    DateTime? endDate;

    switch (_selectedRange) {
      case ChartRange.today:
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case ChartRange.sevenDays:
        startDate = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(const Duration(days: 6));
        break;
      case ChartRange.thirtyDays:
        startDate = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(const Duration(days: 29));
        break;
      case ChartRange.month:
        startDate = DateTime(now.year, now.month, 1);
        break;
      case ChartRange.allTime:
        startDate = DateTime(2000, 1, 1);
        break;
      case ChartRange.custom:
        startDate =
            _customStartDate ??
            DateTime(
              now.year,
              now.month,
              now.day,
            ).subtract(const Duration(days: 6));
        endDate = _customEndDate;
        break;
    }

    final query = _db.selectOnly(_db.transactionItems).join([
      innerJoin(
        _db.transactions,
        _db.transactions.id.equalsExp(_db.transactionItems.transactionId),
      ),
      leftOuterJoin(
        _db.products,
        _db.products.id.equalsExp(_db.transactionItems.productId),
      ),
    ]);

    query.addColumns([
      _db.transactionItems.productId,
      _db.transactionItems.productName,
      _db.transactionItems.quantity.sum(),
      _db.products.imageUrl,
    ]);

    query.where(
      _db.transactions.storeId.equals(_storeId!) &
          _db.transactions.createdAt.isBiggerOrEqualValue(startDate) &
          (endDate != null
              ? _db.transactions.createdAt.isSmallerOrEqualValue(endDate)
              : const Constant(true)),
    );

    query.groupBy([
      _db.transactionItems.productId,
      _db.transactionItems.productName,
      _db.products.imageUrl,
    ]);

    query.orderBy([
      OrderingTerm(
        expression: _db.transactionItems.quantity.sum(),
        mode: OrderingMode.desc,
      ),
    ]);

    final result = await query.get();
    _topProducts = result.map((row) {
      return {
        'id': row.read(_db.transactionItems.productId),
        'name': row.read(_db.transactionItems.productName) ?? 'Unnamed',
        'sales': row.read(_db.transactionItems.quantity.sum()) ?? 0,
        'imageUrl': row.read(_db.products.imageUrl),
      };
    }).toList();
  }

  Future<void> _fetchLowStockProducts() async {
    final query = _db.select(_db.products)
      ..where(
        (p) =>
            p.storeId.equals(_storeId!) &
            p.isDeleted.equals(false) &
            p.isStockManaged.equals(true) &
            p.stockQuantity.isSmallerOrEqualValue(_stockThreshold.toDouble()),
      );

    final result = await query.get();
    _lowStockProducts = result.map((p) {
      return {
        'id': p.id,
        'name': p.name ?? 'Unnamed',
        'stock': p.stockQuantity ?? 0,
        'imageUrl': p.imageUrl,
      };
    }).toList();
  }

  double get weeklyGrowth {
    if (_lastWeekSales == 0) return _thisWeekSales > 0 ? 100 : 0;
    return ((_thisWeekSales - _lastWeekSales) / _lastWeekSales) * 100;
  }

  double get monthlyGrowth {
    if (_lastMonthSales == 0) return _thisMonthSales > 0 ? 100 : 0;
    return ((_thisMonthSales - _lastMonthSales) / _lastMonthSales) * 100;
  }

  Future<void> _fetchTopTables() async {
    final now = DateTime.now();
    DateTime startDate = now;
    DateTime? endDate;

    switch (_selectedRange) {
      case ChartRange.today:
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case ChartRange.sevenDays:
        startDate = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(const Duration(days: 6));
        break;
      case ChartRange.thirtyDays:
        startDate = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(const Duration(days: 29));
        break;
      case ChartRange.month:
        startDate = DateTime(now.year, now.month, 1);
        break;
      case ChartRange.allTime:
        startDate = DateTime(2000, 1, 1);
        break;
      case ChartRange.custom:
        startDate =
            _customStartDate ??
            DateTime(
              now.year,
              now.month,
              now.day,
            ).subtract(const Duration(days: 6));
        endDate = _customEndDate;
        break;
    }

    final query = _db.selectOnly(_db.transactions);
    query.addColumns([
      _db.transactions.tableNumber,
      _db.transactions.id.count(),
      _db.transactions.totalAmount.sum(),
    ]);

    query.where(
      _db.transactions.storeId.equals(_storeId!) &
          _db.transactions.tableNumber.isNotNull() &
          _db.transactions.tableNumber.isNotValue('') &
          _db.transactions.createdAt.isBiggerOrEqualValue(startDate) &
          (endDate != null
              ? _db.transactions.createdAt.isSmallerOrEqualValue(endDate)
              : const Constant(true)),
    );

    query.groupBy([_db.transactions.tableNumber]);

    query.orderBy([
      OrderingTerm(
        expression: _db.transactions.id.count(),
        mode: OrderingMode.desc,
      ),
    ]);

    final result = await query.get();
    _topTables = result.map((row) {
      return {
        'name': row.read(_db.transactions.tableNumber) ?? '-',
        'occupancy': row.read(_db.transactions.id.count()) ?? 0,
        'revenue': row.read(_db.transactions.totalAmount.sum()) ?? 0.0,
      };
    }).toList();
  }

  Future<void> resetTableTrendsData() async {
    if (_storeId == null) return;
    try {
      await (_db.update(_db.transactions)
            ..where((t) => t.storeId.equals(_storeId!)))
          .write(const TransactionsCompanion(tableNumber: Value(null)));

      await refreshData();
    } catch (e) {
      debugPrint("AnalyticsController: Error resetting table trends: $e");
    }
  }
}
