import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'app_database.dart';

class SampleProductService {
  static Future<void> seedSampleProducts(
    AppDatabase db,
    String storeId, {
    bool force = false,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'sample_products_seeded_$storeId';

      if (!force) {
        final alreadySeeded = prefs.getBool(key) ?? false;
        if (alreadySeeded) {
          return;
        }

        // Check if store already has any active products
        final existingCount = await (db.select(db.products)
              ..where((t) => t.storeId.equals(storeId))
              ..where((t) => t.isDeleted.equals(false)))
            .get();

        if (existingCount.isNotEmpty) {
          await prefs.setBool(key, true);
          return;
        }
      }

      // 1. Ensure Categories "Makanan" and "Minuman"
      String makananCatId = 'cat_makanan_$storeId';
      String minumanCatId = 'cat_minuman_$storeId';

      final existingCategories = await (db.select(db.categories)
            ..where((t) => t.storeId.equals(storeId)))
          .get();

      final existingMakanan = existingCategories
          .where((c) => (c.name ?? '').toLowerCase() == 'makanan')
          .firstOrNull;
      if (existingMakanan != null) {
        makananCatId = existingMakanan.id;
      } else {
        await db.into(db.categories).insertOnConflictUpdate(
          CategoriesCompanion.insert(
            id: makananCatId,
            name: const Value('Makanan'),
            storeId: Value(storeId),
            createdAt: Value(DateTime.now()),
            lastUpdated: Value(DateTime.now()),
          ),
        );
      }

      final existingMinuman = existingCategories
          .where((c) => (c.name ?? '').toLowerCase() == 'minuman')
          .firstOrNull;
      if (existingMinuman != null) {
        minumanCatId = existingMinuman.id;
      } else {
        await db.into(db.categories).insertOnConflictUpdate(
          CategoriesCompanion.insert(
            id: minumanCatId,
            name: const Value('Minuman'),
            storeId: Value(storeId),
            createdAt: Value(DateTime.now()),
            lastUpdated: Value(DateTime.now()),
          ),
        );
      }

      // 2. Ensure Units exist
      final existingUnits = await db.select(db.units).get();
      String? unitPcsId = existingUnits.where((u) => u.code.toLowerCase() == 'pcs').firstOrNull?.id ?? 'uPcs';
      String? unitPorsiId = existingUnits.where((u) => u.code.toLowerCase() == 'prs').firstOrNull?.id ?? unitPcsId;
      String? unitCupId = existingUnits.where((u) => u.code.toLowerCase() == 'cup').firstOrNull?.id ?? unitPcsId;

      final now = DateTime.now();

      // 3. Define 4 Sample Products with high quality assets
      final sampleList = [
        {
          'id': 'prod_sample_ikan_bakar_${storeId.substring(0, storeId.length > 8 ? 8 : storeId.length)}',
          'name': 'Ikan Bakar Sambal Lalapan',
          'sku': 'IKN-01',
          'description': 'Ikan nila bakar bumbu manis gurih dengan sambal terasi segar, lalapan mentimun dan selada.',
          'buyPrice': 18000.0,
          'salePrice': 28000.0,
          'stock': 20.0,
          'categoryId': makananCatId,
          'unitId': unitPcsId,
          'image': 'assets/products/ikan_bakar.jpg',
        },
        {
          'id': 'prod_sample_es_teh_${storeId.substring(0, storeId.length > 8 ? 8 : storeId.length)}',
          'name': 'Es Teh Manis Segar',
          'sku': 'MIN-01',
          'description': 'Teh melati seduh dingin segar dengan es batu kristal dan manis pas pelepas dahaga.',
          'buyPrice': 2000.0,
          'salePrice': 5000.0,
          'stock': 100.0,
          'categoryId': minumanCatId,
          'unitId': unitCupId,
          'image': 'assets/products/es_teh.jpg',
        },
        {
          'id': 'prod_sample_nasi_goreng_${storeId.substring(0, storeId.length > 8 ? 8 : storeId.length)}',
          'name': 'Nasi Goreng Spesial Telur',
          'sku': 'NAS-01',
          'description': 'Nasi goreng bumbu rempah spesial gurih dengan telur mata sapi, sayuran segar, dan timun.',
          'buyPrice': 12000.0,
          'salePrice': 22000.0,
          'stock': 45.0,
          'categoryId': makananCatId,
          'unitId': unitPorsiId,
          'image': 'assets/products/nasi_goreng.jpg',
        },
        {
          'id': 'prod_sample_sate_ayam_${storeId.substring(0, storeId.length > 8 ? 8 : storeId.length)}',
          'name': 'Sate Ayam Madura + Nasi',
          'sku': 'SAT-01',
          'description': 'Sate daging ayam panggang lembut dengan siraman bumbu kacang kental gurih, cabai, dan seporsi nasi putih.',
          'buyPrice': 15000.0,
          'salePrice': 25000.0,
          'stock': 30.0,
          'categoryId': makananCatId,
          'unitId': unitPorsiId,
          'image': 'assets/products/sate_ayam.jpg',
        },
      ];

      for (var p in sampleList) {
        final prodId = force ? const Uuid().v4() : p['id'] as String;

        await db.into(db.products).insertOnConflictUpdate(
          ProductsCompanion(
            id: Value(prodId),
            storeId: Value(storeId),
            name: Value(p['name'] as String),
            sku: Value(p['sku'] as String),
            description: Value(p['description'] as String),
            buyPrice: Value(p['buyPrice'] as double),
            basePrice: Value(p['buyPrice'] as double),
            salePrice: Value(p['salePrice'] as double),
            stockQuantity: Value(p['stock'] as double),
            isStockManaged: const Value(true),
            categoryId: Value(p['categoryId'] as String?),
            unitId: Value(p['unitId'] as String?),
            imageUrl: Value(p['image'] as String?),
            isAvailable: const Value(true),
            isDeleted: const Value(false),
            createdAt: Value(now),
            lastUpdated: Value(now),
          ),
        );
      }

      await prefs.setBool(key, true);
      debugPrint("SampleProductService: 4 sample products successfully seeded for store $storeId!");
    } catch (e) {
      debugPrint("SampleProductService Error: $e");
    }
  }
}

