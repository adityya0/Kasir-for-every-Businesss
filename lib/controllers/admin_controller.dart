import 'dart:async';
import 'package:flutter/material.dart';
import '../services/app_database.dart';
import 'package:drift/drift.dart';
import '../services/promotion_service.dart';
import '../services/payment_method_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AdminController extends ChangeNotifier {
  final AppDatabase _db;
  late final PromotionService _promotionService;
  late final PaymentMethodService _paymentMethodService;

  AdminController(this._db) {
    _promotionService = PromotionService(_db);
    _paymentMethodService = PaymentMethodService(_db);
    loadInitialData();
  }

  String? _userId;
  String? _userEmail;
  String? _storeId;
  String? _userName;
  String? _profileUrl;
  String? _storeName;
  String? _storeLogo;
  String? _storeAddress;
  String? _storeEmail;
  String? _role;
  Map<String, dynamic>? _permissions;
  bool _isInitializing = true;
  double _todaySales = 0;
  int _lowStockCount = 0;
  List<Map<String, dynamic>> _lowStockItems = [];
  int _transactionCount = 0;
  Map<String, dynamic>? _userProfile;

  // Stream subscriptions for reactivity
  StreamSubscription? _salesSubscription;
  StreamSubscription? _lowStockSubscription;

  List<Category> _categories = [];
  List<Product> _products = [];

  // Getters
  String? get userId => _userId;
  String? get userEmail => _userEmail;
  String? get storeId => _storeId;
  String? get userName => _userName;
  String? get profileUrl => _profileUrl;
  String? get storeName => _storeName;
  String? get storeLogo => _storeLogo;
  String? get storeAddress => _storeAddress;
  String? get storeEmail => _storeEmail;
  String? get role => _role;
  bool get isSuperAdmin => false;
  bool get isAdmin => true; // Semua pengguna memiliki akses penuh Admin (Aksi, Pengaturan, Kasir, Uang, Tren)
  Map<String, dynamic>? get permissions => _permissions;
  Map<String, dynamic>? get userProfile => _userProfile;
  bool get isInitializing => _isInitializing;
  double get todaySales => _todaySales;
  int get lowStockCount => _lowStockCount;
  List<Map<String, dynamic>> get lowStockItems => _lowStockItems;
  int get transactionCount => _transactionCount;
  AppDatabase? get database => _db;
  PromotionService get promotionService => _promotionService;
  PaymentMethodService get paymentMethodService => _paymentMethodService;
  List<Category> get categories => _categories;
  List<Product> get products => _products;

  @override
  void dispose() {
    _salesSubscription?.cancel();
    _lowStockSubscription?.cancel();
    super.dispose();
  }

  Future<void> loadInitialData({String? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final effectiveUserId = userId ?? prefs.getString('current_user_id');

      // Clear previous in-memory lists & stream subscriptions
      _categories = [];
      _products = [];
      _salesSubscription?.cancel();
      _lowStockSubscription?.cancel();

      // 1. Load active Profile
      Profile? profile;
      if (effectiveUserId != null) {
        profile = await (_db.select(_db.profiles)..where((t) => t.id.equals(effectiveUserId))).getSingleOrNull();
      }

      if (profile == null) {
        final profilesItems = await (_db.select(_db.profiles)..limit(1)).get();
        if (profilesItems.isNotEmpty) {
          profile = profilesItems.first;
        }
      }

      if (profile != null) {
        _userId = profile.id;
        _userEmail = profile.email;
        _userName = profile.fullName;
        _profileUrl = profile.avatarUrl;
        _role = profile.role;
        _storeId = profile.storeId;

        await prefs.setString('current_user_id', _userId!);

        if (_storeId == null) {
          final newStoreId = 'store_${DateTime.now().millisecondsSinceEpoch}';
          await _db.into(_db.stores).insert(
            StoresCompanion.insert(
              id: newStoreId,
              name: Value('Toko ${_userName ?? "Kasir"}'),
              adminName: Value(_userName ?? 'Owner'),
              createdAt: Value(DateTime.now()),
            ),
          );
          _storeId = newStoreId;
          await (_db.update(_db.profiles)..where((t) => t.id.equals(_userId!)))
              .write(ProfilesCompanion(storeId: Value(_storeId)));
        }

        if (profile.permissions != null) {
          try {
            _permissions = Map<String, dynamic>.from(jsonDecode(profile.permissions!));
          } catch (e) {
            _permissions = {};
          }
        } else {
          _permissions = {};
        }

        if (_storeId != null) {
          final store = await (_db.select(_db.stores)..where((t) => t.id.equals(_storeId!))..limit(1)).getSingleOrNull();
          if (store != null) {
            _storeName = store.name;
            _storeLogo = store.logoUrl;
            _storeAddress = store.address;
            _storeEmail = store.email;
            _profileUrl ??= store.adminAvatar;
          }
        }

        _userProfile = {
          'id': _userId,
          'email': _userEmail,
          'full_name': _userName,
          'role': _role,
          'avatar_url': _profileUrl,
          'store_id': _storeId,
          'store_name': _storeName,
          'store_logo': _storeLogo,
          'permissions': _permissions,
        };
      } else {
        var stores = await (_db.select(_db.stores)..limit(1)).get();
        if (stores.isEmpty) {
          final initialStoreId = 'store_${DateTime.now().millisecondsSinceEpoch}';
          await _db.into(_db.stores).insert(
            StoresCompanion.insert(
              id: initialStoreId,
              name: const Value('Warkop Alam POS'),
              adminName: const Value('Owner'),
              createdAt: Value(DateTime.now()),
            ),
          );
          stores = await (_db.select(_db.stores)..limit(1)).get();
        }
        final store = stores.first;
        _storeId = store.id;
        _storeName = store.name;
        _storeLogo = store.logoUrl;
        _storeAddress = store.address;
        _storeEmail = store.email;
        _userName = store.adminName;
        _profileUrl = store.adminAvatar;
        _role = 'admin';
        _userId = 'local_admin';

        _userProfile = {
          'id': _userId,
          'full_name': _userName,
          'role': _role,
          'avatar_url': _profileUrl,
          'store_id': _storeId,
          'store_name': _storeName,
          'store_logo': _storeLogo,
        };
      }

      if (_storeId != null) {
        _initStatsStreams();
        _categories = await (_db.select(_db.categories)..where((t) => t.storeId.equals(_storeId!))).get();
        _products = await (_db.select(_db.products)
                  ..where((t) => t.storeId.equals(_storeId!))
                  ..where((t) => t.isDeleted.equals(false)))
                .get();
      }

      _isInitializing = false;
      notifyListeners();
    } catch (e) {
      debugPrint("AdminController: Error loading data: $e");
      _isInitializing = false;
      notifyListeners();
    }
  }

  void _initStatsStreams() {
    if (_storeId == null) return;

    _salesSubscription?.cancel();
    _lowStockSubscription?.cancel();

    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);

    _salesSubscription = (_db.select(_db.transactions)
          ..where((t) => t.storeId.equals(_storeId!) & t.createdAt.isBiggerOrEqualValue(startOfToday)))
        .watch()
        .listen((txs) {
          double total = 0;
          for (var tx in txs) {
            total += tx.totalAmount ?? 0;
          }
          _todaySales = total;
          _transactionCount = txs.length;
          notifyListeners();
        });

    _lowStockSubscription = (_db.select(_db.products)
          ..where((t) => t.storeId.equals(_storeId!) & t.stockQuantity.isSmallerThanValue(5) & t.isStockManaged.equals(true) & t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm(expression: t.stockQuantity, mode: OrderingMode.asc)]))
        .watch()
        .listen((productsRaw) {
          _lowStockCount = productsRaw.length;
          _lowStockItems = productsRaw.map((p) => {
                'id': p.id,
                'name': p.name,
                'stock_quantity': p.stockQuantity,
                'image_url': p.imageUrl,
              }).toList();
          notifyListeners();
        });
  }

  Future<void> fetchDashboardStats() async {
    _initStatsStreams();
  }

  Future<void> updateProfile({String? name, String? avatarUrl}) async {
    if (_storeId == null) return;
    final updates = StoresCompanion(
      adminName: name != null ? Value(name) : const Value.absent(),
      adminAvatar: avatarUrl != null ? Value(avatarUrl) : const Value.absent(),
    );
    await (_db.update(_db.stores)..where((t) => t.id.equals(_storeId!))).write(updates);
    await loadInitialData();
  }

  Future<void> updateStoreBranding({String? name, String? logoUrl}) async {
    if (_storeId == null) return;
    final updates = StoresCompanion(
      name: name != null ? Value(name) : const Value.absent(),
      logoUrl: logoUrl != null ? Value(logoUrl) : const Value.absent(),
    );
    await (_db.update(_db.stores)..where((t) => t.id.equals(_storeId!))).write(updates);
    await loadInitialData();
  }

  Future<void> updateStoreAddress(String address) async {
    if (_storeId == null) return;
    await (_db.update(_db.stores)..where((t) => t.id.equals(_storeId!)))
        .write(StoresCompanion(address: Value(address)));
    await loadInitialData();
  }

  Future<void> updateStoreEmail(String email) async {
    if (_storeId == null) return;
    await (_db.update(_db.stores)..where((t) => t.id.equals(_storeId!)))
        .write(StoresCompanion(email: Value(email)));
    await loadInitialData();
  }

  Future<void> resetStore({bool deleteProducts = false}) async {
    if (_storeId == null) return;
    try {
      await _db.transaction(() async {
        final txs = await (_db.select(_db.transactions)..where((t) => t.storeId.equals(_storeId!))).get();
        final txIds = txs.map((t) => t.id).toList();
        if (txIds.isNotEmpty) {
          await (_db.delete(_db.transactionItems)..where((t) => t.transactionId.isIn(txIds))).go();
        }
        await (_db.delete(_db.transactions)..where((t) => t.storeId.equals(_storeId!))).go();
        if (deleteProducts) {
          await (_db.delete(_db.products)..where((t) => t.storeId.equals(_storeId!))).go();
          await (_db.delete(_db.categories)..where((t) => t.storeId.equals(_storeId!))).go();
        } else {
          await (_db.update(_db.products)..where((t) => t.storeId.equals(_storeId!)))
              .write(const ProductsCompanion(stockQuantity: Value(0)));
        }
      });
      await loadInitialData();
    } catch (e) {
      debugPrint("AdminController: Error resetting store: $e");
      rethrow;
    }
  }

  Future<void> refreshProfile() async {
    await loadInitialData();
  }
}
