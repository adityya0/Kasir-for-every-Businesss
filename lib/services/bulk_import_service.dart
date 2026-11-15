import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'platform/file_manager.dart';
import 'sample_product_service.dart';

import 'package:uuid/uuid.dart';
import 'app_database.dart';
import 'package:drift/drift.dart';

class BulkImportService {
  final AppDatabase _db;

  BulkImportService(this._db);

  Future<Map<String, dynamic>> importProducts(String storeId) async {
    try {
      // 1. Pick File with robust cross-platform options
      FilePickerResult? result;
      try {
        result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['xlsx', 'xls', 'csv'],
          withData: true,
        );
      } catch (e) {
        debugPrint("Custom file pick fallback: $e");
        result = await FilePicker.platform.pickFiles(withData: true);
      }

      if (result == null || result.files.isEmpty) {
        return {'status': 'cancelled'};
      }

      final platformFile = result.files.single;
      final extension = (platformFile.extension?.toLowerCase() ??
              platformFile.name.split('.').last.toLowerCase())
          .trim();

      List<List<dynamic>> fields = [];
      Uint8List? fileBytes = platformFile.bytes;

      if (fileBytes == null && platformFile.path != null) {
        try {
          fileBytes = await FileManager().readBytes(platformFile.path!);
        } catch (_) {}
        if (fileBytes == null) {
          try {
            final f = File(platformFile.path!);
            if (await f.exists()) {
              fileBytes = await f.readAsBytes();
            }
          } catch (_) {}
        }
      }

      if (fileBytes == null || fileBytes.isEmpty) {
        return {
          'status': 'error',
          'message': 'Gagal membaca file di perangkat (File kosong atau tidak dapat diakses)',
        };
      }

      if (extension == 'csv') {
        // Handle CSV with BOM, UTF-8, and dynamic delimiter (; or , or \t)
        String csvString = utf8.decode(fileBytes, allowMalformed: true);
        // Strip BOM and zero-width characters
        csvString = csvString.replaceAll(RegExp(r'^[\uFEFF\u200B\uFEFE]'), '');

        // Detect delimiter
        final firstLine = csvString.split(RegExp(r'[\r\n]+')).firstWhere(
              (l) => l.trim().isNotEmpty,
              orElse: () => '',
            );
        final countSemicolon = ';'.allMatches(firstLine).length;
        final countComma = ','.allMatches(firstLine).length;
        final countTab = '\t'.allMatches(firstLine).length;

        String delimiter = ',';
        if (countSemicolon > countComma && countSemicolon > countTab) {
          delimiter = ';';
        } else if (countTab > countComma && countTab > countSemicolon) {
          delimiter = '\t';
        }

        fields = CsvToListConverter(
          fieldDelimiter: delimiter,
          shouldParseNumbers: false,
          allowInvalid: true,
        ).convert(csvString);
      } else if (extension == 'xlsx' || extension == 'xls') {
        var excel = Excel.decodeBytes(fileBytes);
        Sheet? table;

        // Find sheet that contains data / headers
        for (final sheetName in excel.tables.keys) {
          final s = excel.tables[sheetName];
          if (s != null && s.rows.isNotEmpty) {
            // Check if any row has headers
            for (int r = 0; r < s.rows.length && r < 5; r++) {
              final rowStrings = s.rows[r]
                  .map((c) => _extractCellText(c?.value).toLowerCase())
                  .toList();
              if (rowStrings.any((str) =>
                  str.contains('name') ||
                  str.contains('nama') ||
                  str.contains('sku') ||
                  str.contains('produk') ||
                  str.contains('harga'))) {
                table = s;
                break;
              }
            }
            if (table != null) break;
          }
        }

        // Fallback to default or first sheet
        table ??= (excel.getDefaultSheet() != null
                ? excel.tables[excel.getDefaultSheet()]
                : null) ??
            (excel.tables.isNotEmpty ? excel.tables.values.first : null);

        if (table == null || table.rows.isEmpty) {
          return {
            'status': 'error',
            'message': 'File Excel kosong atau tidak berisi data',
          };
        }

        for (var row in table.rows) {
          fields.add(row.map((e) => _extractCellValue(e?.value)).toList());
        }
      } else {
        return {
          'status': 'error',
          'message': 'Format file tidak didukung: $extension (Gunakan .xlsx atau .csv)',
        };
      }

      if (fields.isEmpty) {
        return {'status': 'error', 'message': 'File kosong atau tidak memiliki baris data'};
      }

      // 2. Identify the Header Row (search first 5 rows)
      int headerRowIndex = 0;
      int nameIdx = -1;
      int skuIdx = -1;
      int categoryIdx = -1;
      int buyPriceIdx = -1;
      int salePriceIdx = -1;
      int stockIdx = -1;
      int descIdx = -1;
      int imageIdx = -1;

      for (int r = 0; r < fields.length && r < 5; r++) {
        final rowHeaders = fields[r]
            .map((e) => _normalizeHeader(e?.toString() ?? ''))
            .toList();

        final nIdx = _findColumnIndex(rowHeaders, [
          'name',
          'nama',
          'nama produk',
          'product name',
          'produk',
          'menu',
          'item',
          'nama barang',
        ]);

        if (nIdx != -1) {
          headerRowIndex = r;
          nameIdx = nIdx;
          skuIdx = _findColumnIndex(rowHeaders, [
            'sku',
            'kode',
            'kode barang',
            'kode produk',
            'barcode',
          ]);
          categoryIdx = _findColumnIndex(rowHeaders, [
            'category',
            'kategori',
            'kategori produk',
            'kelompok',
            'jenis',
          ]);
          buyPriceIdx = _findColumnIndex(rowHeaders, [
            'buy_price',
            'buy price',
            'harga beli',
            'harga modal',
            'modal',
            'beli',
            'hpp',
          ]);
          salePriceIdx = _findColumnIndex(rowHeaders, [
            'sale_price',
            'sale price',
            'harga jual',
            'harga',
            'jual',
            'price',
          ]);
          stockIdx = _findColumnIndex(rowHeaders, [
            'stock_quantity',
            'stock',
            'stok',
            'jumlah stok',
            'qty',
            'kuantitas',
            'jumlah',
          ]);
          descIdx = _findColumnIndex(rowHeaders, [
            'description',
            'deskripsi',
            'keterangan',
            'detail',
            'catatan',
          ]);
          imageIdx = _findColumnIndex(rowHeaders, [
            'image',
            'image_url',
            'imageurl',
            'gambar',
            'foto',
            'foto produk',
            'gambar produk',
            'url gambar',
            'link gambar',
          ]);
          break;
        }
      }

      if (nameIdx == -1) {
        return {
          'status': 'error',
          'message': 'Kolom "Name" atau "Nama Produk" tidak ditemukan pada file.',
        };
      }

      // 3. Fetch Existing Categories for Matching
      final catData = await (_db.select(_db.categories)
            ..where((t) => t.storeId.equals(storeId)))
          .get();

      Map<String, String> categoryMap = {
        for (var cat in catData)
          if ((cat.name ?? '').trim().isNotEmpty)
            cat.name!.trim().toLowerCase(): cat.id,
      };

      // 4. Fetch Existing Products for Upsert
      final existingProducts = await (_db.select(_db.products)
            ..where((t) => t.storeId.equals(storeId)))
          .get();

      final existingBySku = <String, Product>{};
      final existingByName = <String, Product>{};
      for (final p in existingProducts) {
        final s = (p.sku ?? '').trim().toUpperCase();
        if (s.isNotEmpty) existingBySku[s] = p;
        final n = (p.name ?? '').trim().toLowerCase();
        if (n.isNotEmpty) existingByName[n] = p;
      }

      // 5. Parse Rows & Bulk Insert / Update
      int successCount = 0;
      int failCount = 0;
      List<String> errors = [];
      const uuid = Uuid();
      final now = DateTime.now();

      await _db.transaction(() async {
        for (int i = headerRowIndex + 1; i < fields.length; i++) {
          final row = fields[i];
          if (row.isEmpty) continue;

          // Skip completely empty rows
          if (row.every((c) => c == null || c.toString().trim().isEmpty)) {
            continue;
          }

          try {
            String name = (nameIdx != -1 && nameIdx < row.length && row[nameIdx] != null)
                ? row[nameIdx].toString().trim()
                : '';

            if (name.isEmpty) {
              failCount++;
              errors.add('Baris ${i + 1}: Nama kosong');
              continue;
            }

            String? sku;
            if (skuIdx != -1 && skuIdx < row.length && row[skuIdx] != null) {
              final rawSku = row[skuIdx].toString().trim();
              if (rawSku.isNotEmpty && rawSku.toLowerCase() != 'null') {
                sku = rawSku.toUpperCase();
              }
            }

            String? categoryNameRaw;
            if (categoryIdx != -1 && categoryIdx < row.length && row[categoryIdx] != null) {
              final rawCat = row[categoryIdx].toString().trim();
              if (rawCat.isNotEmpty && rawCat.toLowerCase() != 'null') {
                categoryNameRaw = rawCat;
              }
            }

            String? categoryId;
            if (categoryNameRaw != null && categoryNameRaw.isNotEmpty) {
              String categoryNameLower = categoryNameRaw.toLowerCase();
              if (categoryMap.containsKey(categoryNameLower)) {
                categoryId = categoryMap[categoryNameLower];
              } else {
                // Auto-create category
                categoryId = uuid.v4();
                await _db.into(_db.categories).insert(
                      CategoriesCompanion.insert(
                        id: categoryId,
                        name: Value(categoryNameRaw),
                        storeId: Value(storeId),
                        createdAt: Value(now),
                        lastUpdated: Value(now),
                      ),
                    );
                categoryMap[categoryNameLower] = categoryId;
              }
            }

            String? imageUrl;
            if (imageIdx != -1 && imageIdx < row.length && row[imageIdx] != null) {
              final rawImg = row[imageIdx].toString().trim();
              if (rawImg.isNotEmpty && rawImg.toLowerCase() != 'null') {
                imageUrl = rawImg;
              }
            }

            String? description;
            if (descIdx != -1 && descIdx < row.length && row[descIdx] != null) {
              final rawDesc = row[descIdx].toString().trim();
              if (rawDesc.isNotEmpty && rawDesc.toLowerCase() != 'null') {
                description = rawDesc;
              }
            }

            final buyPrice = _parsePrice(
              (buyPriceIdx != -1 && buyPriceIdx < row.length)
                  ? row[buyPriceIdx]
                  : 0,
            ).toDouble();

            final salePrice = _parsePrice(
              (salePriceIdx != -1 && salePriceIdx < row.length)
                  ? row[salePriceIdx]
                  : 0,
            ).toDouble();

            final stockQuantity = _parseDouble(
              (stockIdx != -1 && stockIdx < row.length) ? row[stockIdx] : 0.0,
            );

            // Check if product exists by SKU or Name
            Product? existing;
            if (sku != null && sku.isNotEmpty) {
              existing = existingBySku[sku];
            }
            existing ??= existingByName[name.toLowerCase()];

            if (existing != null) {
              // UPDATE EXISTING
              await (_db.update(_db.products)..where((t) => t.id.equals(existing!.id))).write(
                ProductsCompanion(
                  name: Value(name),
                  sku: Value(sku ?? existing.sku),
                  categoryId: Value(categoryId ?? existing.categoryId),
                  buyPrice: Value(buyPrice),
                  basePrice: Value(buyPrice),
                  salePrice: Value(salePrice),
                  stockQuantity: Value(stockQuantity),
                  description: Value(description ?? existing.description),
                  imageUrl: Value(imageUrl ?? existing.imageUrl),
                  isStockManaged: const Value(true),
                  isAvailable: const Value(true),
                  isDeleted: const Value(false),
                  lastUpdated: Value(now),
                ),
              );
            } else {
              // INSERT NEW
              final newId = uuid.v4();
              await _db.into(_db.products).insert(
                    ProductsCompanion.insert(
                      id: newId,
                      storeId: Value(storeId),
                      name: Value(name),
                      sku: Value(sku),
                      categoryId: Value(categoryId),
                      buyPrice: Value(buyPrice),
                      basePrice: Value(buyPrice),
                      salePrice: Value(salePrice),
                      stockQuantity: Value(stockQuantity),
                      description: Value(description),
                      imageUrl: Value(imageUrl ?? ''),
                      isStockManaged: const Value(true),
                      isAvailable: const Value(true),
                      isDeleted: const Value(false),
                      createdAt: Value(now),
                      lastUpdated: Value(now),
                    ),
                  );

              // Update lookup maps
              final createdProduct = Product(
                id: newId,
                name: name,
                sku: sku,
                categoryId: categoryId,
                buyPrice: buyPrice,
                basePrice: buyPrice,
                salePrice: salePrice,
                stockQuantity: stockQuantity,
                description: description,
                imageUrl: imageUrl,
                isStockManaged: true,
                isAvailable: true,
                isDeleted: false,
                storeId: storeId,
                createdAt: now,
                lastUpdated: now,
              );
              if (sku != null && sku.isNotEmpty) existingBySku[sku] = createdProduct;
              existingByName[name.toLowerCase()] = createdProduct;
            }

            successCount++;
          } catch (e) {
            failCount++;
            errors.add('Baris ${i + 1}: $e');
          }
        }
      });

      return {
        'status': 'success',
        'successCount': successCount,
        'failCount': failCount,
        'errors': errors,
      };
    } catch (e) {
      debugPrint("Import Error: $e");
      return {'status': 'error', 'message': e.toString()};
    }
  }

  Future<String?> exportProductsToExcel(String storeId) async {
    try {
      debugPrint('Export: Starting export for store $storeId');
      final query = _db.select(_db.products).join([
        leftOuterJoin(
          _db.categories,
          _db.categories.id.equalsExp(_db.products.categoryId),
        ),
      ])
        ..where(
          _db.products.storeId.equals(storeId) &
              _db.products.isDeleted.equals(false),
        )
        ..orderBy([
          OrderingTerm(
            expression: _db.products.name,
            mode: OrderingMode.asc,
          ),
        ]);

      final rows = await query.get();
      debugPrint('Export: Fetched ${rows.length} products');

      var excel = Excel.createExcel();
      String sheetName = excel.getDefaultSheet() ?? 'Sheet1';

      if (sheetName != 'Products') {
        excel.rename(sheetName, 'Products');
        sheetName = 'Products';
      }

      Sheet sheet = excel[sheetName];

      // Headers matching user requirements exactly
      List<CellValue> headers = [
        TextCellValue('Name'),
        TextCellValue('SKU'),
        TextCellValue('kategori'),
        TextCellValue('harga beli'),
        TextCellValue('harga jual'),
        TextCellValue('stok'),
        TextCellValue('Description'),
        TextCellValue('Gambar'),
      ];
      sheet.appendRow(headers);

      for (var row in rows) {
        final p = row.readTable(_db.products);
        final c = row.readTableOrNull(_db.categories);

        final double buyPrice = (p.buyPrice ?? p.basePrice ?? 0.0);

        sheet.appendRow([
          TextCellValue(p.name ?? ''),
          TextCellValue(p.sku ?? ''),
          TextCellValue(c?.name ?? ''),
          DoubleCellValue(buyPrice),
          DoubleCellValue(p.salePrice ?? 0.0),
          DoubleCellValue(p.stockQuantity ?? 0.0),
          TextCellValue(p.description ?? ''),
          TextCellValue(p.imageUrl ?? ''),
        ]);
      }

      final String fileName =
          'FLASH_COIN_LAUNDRY_Products_${DateTime.now().millisecondsSinceEpoch}.xlsx';

      var fileBytes = excel.encode() ?? excel.save();
      if (fileBytes == null) {
        throw "Gagal generate file excel (Bytes null)";
      }

      return await FileManager().saveAndShareBytes(
        fileName,
        Uint8List.fromList(fileBytes),
      );
    } catch (e, stack) {
      debugPrint('Export Error: $e\n$stack');
      rethrow;
    }
  }

  Future<String?> generateTemplate() async {
    try {
      var excel = Excel.createExcel();
      String sheetName = excel.getDefaultSheet() ?? 'Sheet1';
      if (sheetName != 'Products') {
        excel.rename(sheetName, 'Products');
        sheetName = 'Products';
      }
      Sheet sheet = excel[sheetName];

      List<CellValue> headers = [
        TextCellValue('Name'),
        TextCellValue('SKU'),
        TextCellValue('kategori'),
        TextCellValue('harga beli'),
        TextCellValue('harga jual'),
        TextCellValue('stok'),
        TextCellValue('Description'),
        TextCellValue('Gambar'),
      ];
      sheet.appendRow(headers);

      // Pre-fill with the official FLASH COIN LAUNDRY menu items
      for (final item in SampleProductService.flashCoinLaundryMenu) {
        sheet.appendRow([
          TextCellValue(item['name'] as String),
          TextCellValue(item['sku'] as String),
          TextCellValue(item['category'] as String),
          DoubleCellValue((item['buyPrice'] as num).toDouble()),
          DoubleCellValue((item['salePrice'] as num).toDouble()),
          DoubleCellValue((item['stock'] as num).toDouble()),
          TextCellValue(item['description'] as String),
          TextCellValue(''),
        ]);
      }

      const String fileName = 'template_produk_flash_coin_laundry.xlsx';
      var fileBytes = excel.encode() ?? excel.save();
      if (fileBytes == null) {
        throw "Gagal generate file excel template (Bytes null)";
      }

      return await FileManager().saveAndShareBytes(
        fileName,
        Uint8List.fromList(fileBytes),
      );
    } catch (e) {
      debugPrint('Template Error: $e');
      return null;
    }
  }

  String _normalizeHeader(String h) {
    return h
        .replaceAll(RegExp(r'[\uFEFF\u200B\uFEFE\r\n\t_]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .toLowerCase();
  }

  dynamic _extractCellValue(CellValue? val) {
    if (val == null) return null;
    if (val is TextCellValue) return val.value.text ?? val.toString();
    if (val is IntCellValue) return val.value;
    if (val is DoubleCellValue) return val.value;
    if (val is BoolCellValue) return val.value;
    if (val is DateCellValue) return val.asDateTimeLocal().toIso8601String();
    if (val is DateTimeCellValue) return val.asDateTimeLocal().toIso8601String();
    if (val is FormulaCellValue) return val.formula;
    return val.toString();
  }

  String _extractCellText(CellValue? val) {
    final v = _extractCellValue(val);
    return v?.toString().trim() ?? '';
  }

  int _parsePrice(dynamic val) {
    if (val == null) return 0;
    if (val is num) return val.toInt();
    if (val is IntCellValue) return val.value;
    if (val is DoubleCellValue) return val.value.round();
    if (val is TextCellValue) {
      val = val.value.text ?? val.toString();
    }

    String s = val.toString().trim();
    if (s.isEmpty) return 0;

    // Remove currency indicators
    s = s.replaceAll(RegExp(r'^(rp|idr)\s*', caseSensitive: false), '').trim();

    // Check if it's formatted like "10.000,00" or "10.000" or "10000.00"
    if (s.contains(',') && s.contains('.')) {
      // e.g. 10.000,00 -> Indonesian formatted
      s = s.split(',')[0].replaceAll('.', '');
    } else if (s.contains(',')) {
      // Could be decimal comma (e.g. 10000,50) or thousand comma (e.g. 10,000)
      final parts = s.split(',');
      if (parts.length == 2 && parts[1].length <= 2) {
        s = parts[0].replaceAll('.', '');
      } else {
        s = s.replaceAll(',', '');
      }
    } else if (s.contains('.')) {
      final parts = s.split('.');
      if (parts.length == 2 && parts[1].length <= 2) {
        // Decimal point like 10000.0 or 10000.00
        return (double.tryParse(s) ?? 0.0).round();
      } else {
        // Thousand separator like 10.000
        s = s.replaceAll('.', '');
      }
    }

    final digitsOnly = s.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digitsOnly) ?? 0;
  }

  double _parseDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is DoubleCellValue) return val.value;
    if (val is IntCellValue) return val.value.toDouble();
    if (val is TextCellValue) {
      val = val.value.text ?? val.toString();
    }

    String s = val.toString().trim();
    if (s.isEmpty) return 0.0;

    // Handle comma as decimal
    if (s.contains(',') && !s.contains('.')) {
      s = s.replaceAll(',', '.');
    }

    return double.tryParse(s) ?? 0.0;
  }

  int _findColumnIndex(List<String> headers, List<String> possibleNames) {
    // 1. Exact match
    for (var name in possibleNames) {
      final target = _normalizeHeader(name);
      int idx = headers.indexOf(target);
      if (idx != -1) return idx;
    }

    // 2. Contains match
    for (int i = 0; i < headers.length; i++) {
      final h = headers[i];
      if (h.isEmpty) continue;
      for (var name in possibleNames) {
        final target = _normalizeHeader(name);
        if (h == target || h.contains(target) || target.contains(h)) {
          return i;
        }
      }
    }

    return -1;
  }
}
