import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'platform/file_manager.dart';

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
        debugPrint("Custom file pick failed on device, trying fallback: $e");
        result = await FilePicker.platform.pickFiles(
          withData: true,
        );
      }

      if (result == null || result.files.isEmpty) return {'status': 'cancelled'};

      final platformFile = result.files.single;
      final extension =
          platformFile.extension?.toLowerCase() ??
          platformFile.name.split('.').last.toLowerCase();

      List<List<dynamic>> fields = [];
      Uint8List? fileBytes = platformFile.bytes;

      if (fileBytes == null && platformFile.path != null) {
        try {
          fileBytes = await FileManager().readBytes(platformFile.path!);
        } catch (e) {
          debugPrint("FileManager readBytes error: $e");
        }
      }

      if (fileBytes == null) {
        return {
          'status': 'error',
          'message': 'Gagal membaca file di perangkat (File tidak dapat diakses)',
        };
      }

      if (extension == 'csv') {
        final csvString = utf8.decode(fileBytes);
        fields = const CsvToListConverter().convert(csvString);
      } else if (extension == 'xlsx' || extension == 'xls') {
        var excel = Excel.decodeBytes(fileBytes);
        Sheet? table;
        final defaultSheet = excel.getDefaultSheet();
        if (defaultSheet != null && excel.tables.containsKey(defaultSheet)) {
          table = excel.tables[defaultSheet];
        } else if (excel.tables.isNotEmpty) {
          table = excel.tables.values.first;
        }

        if (table == null || table.rows.isEmpty) {
          return {
            'status': 'error',
            'message': 'File Excel kosong atau tidak berisi lembar kerja',
          };
        }

        for (var row in table.rows) {
          fields.add(row.map((e) => e?.value).toList());
        }
      } else {
        return {
          'status': 'error',
          'message': 'Format file tidak didukung: $extension (Gunakan .xlsx atau .csv)',
        };
      }

      if (fields.isEmpty) return {'status': 'error', 'message': 'File kosong'};

      // 2. Process Headers safely
      final headers = fields[0]
          .map((e) => (e?.toString() ?? '').toLowerCase().trim())
          .toList();

      int nameIdx = _findColumnIndex(headers, [
        'name',
        'nama',
        'nama produk',
        'product name',
      ]);
      int skuIdx = _findColumnIndex(headers, ['sku', 'kode', 'kode barang']);
      int categoryIdx = _findColumnIndex(headers, [
        'category',
        'kategori',
        'kategori produk',
      ]);
      int buyPriceIdx = _findColumnIndex(headers, [
        'buy_price',
        'buy price',
        'harga beli',
        'modal',
      ]);
      int salePriceIdx = _findColumnIndex(headers, [
        'sale_price',
        'sale price',
        'harga jual',
      ]);
      int stockIdx = _findColumnIndex(headers, [
        'stock_quantity',
        'stock',
        'stok',
        'jumlah stok',
      ]);
      int descIdx = _findColumnIndex(headers, [
        'description',
        'deskripsi',
        'keterangan',
      ]);
      int imageIdx = _findColumnIndex(headers, [
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

      if (nameIdx == -1) {
        return {'status': 'error', 'message': 'Kolom "name" wajib ada'};
      }

      // 3. Fetch Categories for Matching
      final catData = await (_db.select(
        _db.categories,
      )..where((t) => t.storeId.equals(storeId))).get();

      Map<String, String> categoryMap = {
        for (var cat in catData) cat.name.toString().toLowerCase(): cat.id,
      };

      // 4. Parse Rows & Bulk Insert
      int successCount = 0;
      int failCount = 0;
      List<String> errors = [];
      const uuid = Uuid();
      final now = DateTime.now();

      await _db.transaction(() async {
        for (int i = 1; i < fields.length; i++) {
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

            String? categoryNameRaw;
            if (categoryIdx != -1 && categoryIdx < row.length && row[categoryIdx] != null) {
              final raw = row[categoryIdx].toString().trim();
              if (raw.isNotEmpty && raw.toLowerCase() != 'null') {
                categoryNameRaw = raw;
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
                await _db
                    .into(_db.categories)
                    .insert(
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

            await _db
                .into(_db.products)
                .insert(
                  ProductsCompanion.insert(
                    id: uuid.v4(),
                    storeId: Value(storeId),
                    name: Value(name),
                    sku: Value(
                      (skuIdx != -1 && skuIdx < row.length)
                          ? row[skuIdx]?.toString()
                          : null,
                    ),
                    categoryId: Value(categoryId),
                    basePrice: Value(
                      _parsePrice(
                        (buyPriceIdx != -1 && buyPriceIdx < row.length)
                            ? row[buyPriceIdx]
                            : 0,
                      ).toDouble(),
                    ),
                    salePrice: Value(
                      _parsePrice(
                        (salePriceIdx != -1 && salePriceIdx < row.length)
                            ? row[salePriceIdx]
                            : 0,
                      ).toDouble(),
                    ),
                    stockQuantity: Value(
                      _parseDouble(
                        (stockIdx != -1 && stockIdx < row.length)
                            ? row[stockIdx]
                            : 0.0,
                      ),
                    ),
                    description: Value(
                      (descIdx != -1 && descIdx < row.length)
                          ? row[descIdx]?.toString()
                          : null,
                    ),
                    imageUrl: Value(imageUrl),
                    isStockManaged: const Value(true),
                    isAvailable: const Value(true),
                    isDeleted: const Value(false),
                    lastUpdated: Value(now),
                  ),
                );
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
      // 1. Fetch Products with Join
      final query =
          _db.select(_db.products).join([
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

      if (rows.isEmpty) {
        debugPrint('Export: No products found');
        return null;
      }

      // 2. Create Excel
      var excel = Excel.createExcel();

      // Get the default sheet name
      String sheetName = excel.getDefaultSheet() ?? 'Sheet1';

      // Rename default sheet to 'Products'
      if (sheetName != 'Products') {
        excel.rename(sheetName, 'Products');
        sheetName = 'Products';
      }

      Sheet sheet = excel[sheetName];

      // 3. Add Headers (Matching user image)
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

      // 4. Add Rows
      for (var row in rows) {
        final p = row.readTable(_db.products);
        final c = row.readTableOrNull(_db.categories);

        // Use buyPrice (SQL) or basePrice (Legacy fallback)
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

      // 5. Save File
      final String fileName =
          'products_export_${DateTime.now().millisecondsSinceEpoch}.xlsx';

      debugPrint('Export: Encoding excel bytes...');
      var fileBytes = excel.encode();

      if (fileBytes == null) {
        debugPrint('Export: excel.encode() returned null, trying excel.save()');
        fileBytes = excel.save();
      }

      if (fileBytes == null) {
        throw "Gagal generate file excel (Bytes null)";
      }

      debugPrint('Export: Saving ${fileBytes.length} bytes to $fileName');
      var result = await FileManager().saveAndShareBytes(
        fileName,
        Uint8List.fromList(fileBytes),
      );

      debugPrint('Export: Save result: $result');
      return result != null ? "Export Success: $result" : "Export Failed";
    } catch (e, stack) {
      debugPrint('Export Error: $e');
      debugPrint('Stack: $stack');
      rethrow;
    }
  }

  Future<String?> generateTemplate() async {
    try {
      var excel = Excel.createExcel();
      String sheetName = excel.getDefaultSheet() ?? 'Sheet1';
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

      // Add a sample row
      sheet.appendRow([
        TextCellValue('Susu Ultra Milk 250ml'),
        TextCellValue('UM-250'),
        TextCellValue('Minuman'),
        const DoubleCellValue(5000),
        const DoubleCellValue(7000),
        const DoubleCellValue(24.0),
        TextCellValue('Susu UHT coklat'),
        TextCellValue(''),
      ]);

      const String fileName = 'template_impor_produk.xlsx';
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

  int _parsePrice(dynamic val) {
    if (val == null) return 0;
    if (val is num) return val.toInt();
    return int.tryParse(val.toString().replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  }

  double _parseDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }



  int _findColumnIndex(List<String> headers, List<String> possibleNames) {
    for (var name in possibleNames) {
      int idx = headers.indexOf(name.toLowerCase());
      if (idx != -1) return idx;
    }
    return -1;
  }
}
