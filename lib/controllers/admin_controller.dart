import 'dart:async';
import 'package:flutter/material.dart';
import '../services/app_database.dart';
import '../services/sample_product_service.dart';
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
              name: const Value('OMNI POS'),
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
        await SampleProductService.seedSampleProducts(_db, _storeId!);
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

  Future<void> resetStore({bool deleteProducts = true}) async {
    if (_storeId == null) return;
    final storeId = _storeId!;
    try {
      await _db.transaction(() async {
        // 1. Riwayat Transaksi & Item Penjualan
        final txs = await (_db.select(_db.transactions)..where((t) => t.storeId.equals(storeId))).get();
        final txIds = txs.map((t) => t.id).toList();
        if (txIds.isNotEmpty) {
          const chunkSize = 200;
          for (var i = 0; i < txIds.length; i += chunkSize) {
            final chunk = txIds.sublist(i, i + chunkSize > txIds.length ? txIds.length : i + chunkSize);
            await (_db.delete(_db.transactionItems)..where((t) => t.transactionId.isIn(chunk))).go();
          }
        }
        await (_db.delete(_db.transactions)..where((t) => t.storeId.equals(storeId))).go();

        // 2. Pengeluaran / Biaya Operasional / Kas Keluar
        await (_db.delete(_db.expenses)..where((t) => t.storeId.equals(storeId))).go();

        // 3. Transaksi Supplier, Pelunasan, & Data Supplier
        try {
          await _db.customStatement('DELETE FROM supplier_transactions WHERE store_id = ?;', [storeId]);
        } catch (e) {
          debugPrint("resetStore: delete supplier_transactions error: $e");
        }
        try {
          await _db.customStatement('DELETE FROM supplier_settlements WHERE store_id = ?;', [storeId]);
        } catch (e) {
          debugPrint("resetStore: delete supplier_settlements error: $e");
        }
        try {
          await _db.customStatement('DELETE FROM suppliers WHERE store_id = ?;', [storeId]);
        } catch (e) {
          debugPrint("resetStore: delete suppliers error: $e");
        }

        // 4. Data Pelanggan & Riwayat Piutang
        await (_db.delete(_db.customers)..where((t) => t.storeId.equals(storeId))).go();

        // 5. Produk, Kategori, Satuan, Opsi/Varian Produk
        if (deleteProducts) {
          final prods = await (_db.select(_db.products)..where((t) => t.storeId.equals(storeId))).get();
          final prodIds = prods.map((p) => p.id).toList();
          if (prodIds.isNotEmpty) {
            final options = await (_db.select(_db.productOptions)..where((o) => o.productId.isIn(prodIds))).get();
            final optIds = options.map((o) => o.id).toList();
            if (optIds.isNotEmpty) {
              await (_db.delete(_db.productOptionValues)..where((v) => v.optionId.isIn(optIds))).go();
            }
            await (_db.delete(_db.productOptions)..where((o) => o.productId.isIn(prodIds))).go();
          }
          await (_db.delete(_db.products)..where((t) => t.storeId.equals(storeId))).go();
          await (_db.delete(_db.categories)..where((t) => t.storeId.equals(storeId))).go();
          await (_db.delete(_db.units)..where((t) => t.storeId.equals(storeId))).go();
        } else {
          await (_db.update(_db.products)..where((t) => t.storeId.equals(storeId)))
              .write(const ProductsCompanion(stockQuantity: Value(0)));
        }

        // 6. Promo & Diskon
        final promos = await (_db.select(_db.promotions)..where((t) => t.storeId.equals(storeId))).get();
        final promoIds = promos.map((p) => p.id).toList();
        if (promoIds.isNotEmpty) {
          await (_db.delete(_db.promotionItems)..where((t) => t.promotionId.isIn(promoIds))).go();
        }
        await (_db.delete(_db.promotions)..where((t) => t.storeId.equals(storeId))).go();

        // 7. Absensi Karyawan
        await (_db.delete(_db.attendanceLogs)..where((t) => t.storeId.equals(storeId))).go();

        // 8. Meja Toko
        await (_db.delete(_db.storeTables)..where((t) => t.storeId.equals(storeId))).go();

        // 9. Metode Pembayaran (Hapus akun kustom & reset saldo ke 0)
        await (_db.delete(_db.paymentMethods)..where((t) => t.storeId.equals(storeId))).go();
      });

      // 10. Tandai sample products agar tidak otomatis mengisi produk bawaan kembali
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('sample_products_seeded_$storeId', true);

      // 11. Buat ulang akun default (Kas & QRIS saldo 0)
      await prefs.remove('default_payment_methods_initialized_$storeId');
      await _paymentMethodService.ensureDefaultPaymentMethods(storeId);

      // 12. Bersihkan cache shift kasir & preferensi finansial
      final keysToRemove = prefs.getKeys().where((k) =>
        k.startsWith('cash_drawer_') ||
        k.startsWith('shift_') ||
        k.contains('financial_') ||
        k == 'owner_wa_phone'
      ).toList();
      for (final k in keysToRemove) {
        await prefs.remove(k);
      }

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
