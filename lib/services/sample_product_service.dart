import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'app_database.dart';

class SampleProductService {
  /// The 20 items requested by FLASH COIN LAUNDRY
  static final List<Map<String, dynamic>> flashCoinLaundryMenu = [
    {
      'name': 'Cuci',
      'sku': 'LUN-001',
      'category': 'Laundry',
      'buyPrice': 0.0,
      'salePrice': 10000.0,
      'stock': 0.0,
      'description': 'Layanan cuci',
      'image': '',
    },
    {
      'name': 'Kering',
      'sku': 'LUN-002',
      'category': 'Laundry',
      'buyPrice': 0.0,
      'salePrice': 10000.0,
      'stock': 0.0,
      'description': 'Layanan kering',
      'image': '',
    },
    {
      'name': 'Drop Off',
      'sku': 'LUN-003',
      'category': 'Laundry',
      'buyPrice': 0.0,
      'salePrice': 10000.0,
      'stock': 0.0,
      'description': 'Layanan drop off',
      'image': '',
    },
    {
      'name': 'Detergen',
      'sku': 'LUN-004',
      'category': 'Laundry',
      'buyPrice': 0.0,
      'salePrice': 3000.0,
      'stock': 0.0,
      'description': 'Tambahan detergen',
      'image': '',
    },
    {
      'name': 'Pewangi',
      'sku': 'LUN-005',
      'category': 'Laundry',
      'buyPrice': 0.0,
      'salePrice': 3000.0,
      'stock': 0.0,
      'description': 'Tambahan pewangi',
      'image': '',
    },
    {
      'name': 'Plastik',
      'sku': 'LUN-006',
      'category': 'Laundry',
      'buyPrice': 0.0,
      'salePrice': 3000.0,
      'stock': 0.0,
      'description': 'Plastik laundry',
      'image': '',
    },
    {
      'name': 'Cuci Kering Promo',
      'sku': 'LUN-007',
      'category': 'Laundry',
      'buyPrice': 0.0,
      'salePrice': 15000.0,
      'stock': 0.0,
      'description': 'Paket cuci kering promo',
      'image': '',
    },
    {
      'name': 'Baso Halus',
      'sku': 'BAS-001',
      'category': 'Makanan',
      'buyPrice': 0.0,
      'salePrice': 10000.0,
      'stock': 0.0,
      'description': 'Baso halus',
      'image': '',
    },
    {
      'name': 'Baso Cincang',
      'sku': 'BAS-002',
      'category': 'Makanan',
      'buyPrice': 0.0,
      'salePrice': 12000.0,
      'stock': 0.0,
      'description': 'Baso cincang',
      'image': '',
    },
    {
      'name': 'Baso Cincang Tetelan',
      'sku': 'BAS-003',
      'category': 'Makanan',
      'buyPrice': 0.0,
      'salePrice': 15000.0,
      'stock': 0.0,
      'description': 'Baso cincang dengan tetelan',
      'image': '',
    },
    {
      'name': 'Baso Cincang Kikil',
      'sku': 'BAS-004',
      'category': 'Makanan',
      'buyPrice': 0.0,
      'salePrice': 15000.0,
      'stock': 0.0,
      'description': 'Baso cincang dengan kikil',
      'image': '',
    },
    {
      'name': 'Air Mineral',
      'sku': 'MNM-001',
      'category': 'Minuman',
      'buyPrice': 0.0,
      'salePrice': 4000.0,
      'stock': 0.0,
      'description': 'Air mineral botol',
      'image': '',
    },
    {
      'name': 'Teh Kotak',
      'sku': 'MNM-002',
      'category': 'Minuman',
      'buyPrice': 0.0,
      'salePrice': 5000.0,
      'stock': 0.0,
      'description': 'Teh kotak',
      'image': '',
    },
    {
      'name': 'Fresh Tea',
      'sku': 'MNM-003',
      'category': 'Minuman',
      'buyPrice': 0.0,
      'salePrice': 5000.0,
      'stock': 0.0,
      'description': 'Fresh tea',
      'image': '',
    },
    {
      'name': 'Fanta',
      'sku': 'MNM-004',
      'category': 'Minuman',
      'buyPrice': 0.0,
      'salePrice': 6000.0,
      'stock': 0.0,
      'description': 'Minuman Fanta',
      'image': '',
    },
    {
      'name': 'Coca Cola',
      'sku': 'MNM-005',
      'category': 'Minuman',
      'buyPrice': 0.0,
      'salePrice': 6000.0,
      'stock': 0.0,
      'description': 'Minuman Coca Cola',
      'image': '',
    },
    {
      'name': 'Nipis Madu',
      'sku': 'MNM-006',
      'category': 'Minuman',
      'buyPrice': 0.0,
      'salePrice': 5000.0,
      'stock': 0.0,
      'description': 'Minuman Nipis Madu',
      'image': '',
    },
    {
      'name': 'Minute Maid',
      'sku': 'MNM-007',
      'category': 'Minuman',
      'buyPrice': 0.0,
      'salePrice': 6000.0,
      'stock': 0.0,
      'description': 'Minuman Minute Maid',
      'image': '',
    },
    {
      'name': 'Nutri Boost',
      'sku': 'MNM-008',
      'category': 'Minuman',
      'buyPrice': 0.0,
      'salePrice': 7000.0,
      'stock': 0.0,
      'description': 'Minuman Nutri Boost',
      'image': '',
    },
    {
      'name': 'All Kopi & Susu',
      'sku': 'MNM-009',
      'category': 'Minuman',
      'buyPrice': 0.0,
      'salePrice': 5000.0,
      'stock': 0.0,
      'description': 'Aneka kopi & susu',
      'image': '',
    },
  ];

  static Future<void> seedSampleProducts(
    AppDatabase db,
    String storeId, {
    bool force = false,
  }) async {
    await seedFlashCoinLaundryProducts(db, storeId, force: force);
  }

  /// Seeds or updates the 20 official FLASH COIN LAUNDRY products into the store.
  static Future<int> seedFlashCoinLaundryProducts(
    AppDatabase db,
    String storeId, {
    bool force = false,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'flash_coin_menu_seeded_$storeId';

      if (!force) {
        final alreadySeeded = prefs.getBool(key) ?? false;
        if (alreadySeeded) {
          // If already marked as seeded, verify if at least one product exists
          final count = await (db.select(db.products)
                ..where((t) => t.storeId.equals(storeId))
                ..where((t) => t.isDeleted.equals(false)))
              .get();
          if (count.isNotEmpty) {
            return 0;
          }
        }
      }

      final now = DateTime.now();
      const uuid = Uuid();

      // 1. Ensure Categories exist: Laundry, Makanan, Minuman
      final existingCategories = await (db.select(db.categories)
            ..where((t) => t.storeId.equals(storeId)))
          .get();

      final categoryMap = <String, String>{};
      for (final cat in existingCategories) {
        final name = (cat.name ?? '').trim().toLowerCase();
        if (name.isNotEmpty) {
          categoryMap[name] = cat.id;
        }
      }

      final requiredCategories = ['Laundry', 'Makanan', 'Minuman'];
      for (final catName in requiredCategories) {
        final lower = catName.toLowerCase();
        if (!categoryMap.containsKey(lower)) {
          final catId = 'cat_${lower}_$storeId';
          await db.into(db.categories).insertOnConflictUpdate(
            CategoriesCompanion.insert(
              id: catId,
              name: Value(catName),
              storeId: Value(storeId),
              createdAt: Value(now),
              lastUpdated: Value(now),
            ),
          );
          categoryMap[lower] = catId;
        }
      }

      // 2. Fetch existing products for this store to prevent duplicate SKUs or names
      final existingProducts = await (db.select(db.products)
            ..where((t) => t.storeId.equals(storeId)))
          .get();

      final productBySku = <String, Product>{};
      final productByName = <String, Product>{};
      for (final p in existingProducts) {
        final sku = (p.sku ?? '').trim().toUpperCase();
        if (sku.isNotEmpty) productBySku[sku] = p;
        final name = (p.name ?? '').trim().toLowerCase();
        if (name.isNotEmpty) productByName[name] = p;
      }

      int seededCount = 0;

      for (final item in flashCoinLaundryMenu) {
        final name = item['name'] as String;
        final sku = (item['sku'] as String).trim().toUpperCase();
        final catName = (item['category'] as String).trim().toLowerCase();
        final catId = categoryMap[catName];
        final buyPrice = (item['buyPrice'] as num).toDouble();
        final salePrice = (item['salePrice'] as num).toDouble();
        final stock = (item['stock'] as num).toDouble();
        final desc = item['description'] as String;

        Product? existing = productBySku[sku] ?? productByName[name.toLowerCase()];

        if (existing != null) {
          // Update existing product to make sure prices & category are accurate
          await (db.update(db.products)..where((t) => t.id.equals(existing.id))).write(
            ProductsCompanion(
              name: Value(name),
              sku: Value(sku),
              categoryId: Value(catId ?? existing.categoryId),
              buyPrice: Value(buyPrice),
              basePrice: Value(buyPrice),
              salePrice: Value(salePrice),
              description: Value(desc),
              isAvailable: const Value(true),
              isDeleted: const Value(false),
              lastUpdated: Value(now),
            ),
          );
        } else {
          // Insert new product
          final newId = uuid.v4();
          await db.into(db.products).insert(
            ProductsCompanion.insert(
              id: newId,
              storeId: Value(storeId),
              name: Value(name),
              sku: Value(sku),
              categoryId: Value(catId),
              buyPrice: Value(buyPrice),
              basePrice: Value(buyPrice),
              salePrice: Value(salePrice),
              stockQuantity: Value(stock),
              description: Value(desc),
              imageUrl: const Value(''),
              isStockManaged: const Value(true),
              isAvailable: const Value(true),
              isDeleted: const Value(false),
              createdAt: Value(now),
              lastUpdated: Value(now),
            ),
          );
        }
        seededCount++;
      }

      await prefs.setBool(key, true);
      debugPrint("✓ Successfully seeded $seededCount FLASH COIN LAUNDRY products into store $storeId");
      return seededCount;
    } catch (e, stack) {
      debugPrint("Error seeding Flash Coin Laundry products: $e\n$stack");
      return 0;
    }
  }
}
