import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import '../app_database.dart'; // Adjusted path


class BackupService {
  final AppDatabase _db;

  BackupService(this._db);

  /// Creates a full backup (DB + Images) as a ZIP file.
  Future<String?> createFullBackup({bool share = true}) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final dbPath = p.join(appDir.path, 'db.sqlite');
      final dbFile = File(dbPath);

      if (!await dbFile.exists()) {
        throw "Database file not found at $dbPath";
      }

      // 1. Create Staging Directory
      final tempDir = await getTemporaryDirectory();
      final stagingDirName =
          'backup_staging_${DateTime.now().millisecondsSinceEpoch}';
      final stagingDir = Directory(p.join(tempDir.path, stagingDirName));
      if (await stagingDir.exists()) {
        await stagingDir.delete(recursive: true);
      }
      await stagingDir.create();

      // 2. Copy Database to Staging
      await dbFile.copy(p.join(stagingDir.path, 'db.sqlite'));

      // 3. Copy Images to Staging/images
      final imagesDir = Directory(p.join(stagingDir.path, 'images'));
      await imagesDir.create();

      final Set<String> uniqueImagePaths = {};

      // Helper to collect paths
      void collect(String? path) {
        if (path != null && path.isNotEmpty && !path.startsWith('http')) {
          uniqueImagePaths.add(path);
        }
      }

      // Query DB for image paths efficiently in parallel
      final results = await Future.wait([
        (_db.selectOnly(
          _db.products,
        )..addColumns([_db.products.imageUrl])).get(),
        (_db.selectOnly(
          _db.stores,
        )..addColumns([_db.stores.logoUrl, _db.stores.adminAvatar])).get(),
        (_db.selectOnly(
          _db.profiles,
        )..addColumns([_db.profiles.avatarUrl])).get(),
        (_db.selectOnly(
          _db.attendanceLogs,
        )..addColumns([_db.attendanceLogs.photoUrl])).get(),
        (_db.selectOnly(
          _db.categories,
        )..addColumns([_db.categories.iconUrl])).get(),
      ]);

      for (var row in results[0]) {
        collect(row.read(_db.products.imageUrl));
      }
      for (var row in results[1]) {
        collect(row.read(_db.stores.logoUrl));
        collect(row.read(_db.stores.adminAvatar));
      }
      for (var row in results[2]) {
        collect(row.read(_db.profiles.avatarUrl));
      }
      for (var row in results[3]) {
        collect(row.read(_db.attendanceLogs.photoUrl));
      }
      for (var row in results[4]) {
        collect(row.read(_db.categories.iconUrl));
      }

      int copiedCount = 0;
      for (var path in uniqueImagePaths) {
        final file = File(path);
        if (await file.exists()) {
          // We copy the file into images/filename.ext
          // On restore, we'll strip the old absolute path prefix and replace with new one.
          final filename = path.split(RegExp(r'[/\\]')).last;
          await file.copy(p.join(imagesDir.path, filename));
          copiedCount++;
        }
      }
      debugPrint("Backup: Copied $copiedCount images.");

      // 4. Create ZIP
      final dateStr = DateFormat('ddMMyyyy_HHmm').format(DateTime.now());
      final zipPath = p.join(
        tempDir.path,
        'pos_backup_$dateStr.zip',
      );
      final encoder = ZipFileEncoder();
      encoder.create(zipPath);
      encoder.addDirectory(
        stagingDir,
        includeDirName: false,
      ); // Add contents of staging to root of zip
      encoder.close();

      // Cleanup Staging
      await stagingDir.delete(recursive: true);

      // Share
      if (share) {
        final xFile = XFile(zipPath);
        // ignore: deprecated_member_use
        await Share.shareXFiles(
          [xFile],
          subject: 'OMNI POS Full Backup',
        );
      }

      return zipPath;
    } catch (e) {
      debugPrint("Create Backup Error: $e");
      rethrow;
    }
  }

  /// Restores a full backup from a ZIP file by importing data directly into the active database
  /// without closing the database connection or triggering Windows file locks.
  Future<String?> restoreFullBackup(String zipPath) async {
    try {
      final zipFile = File(zipPath);
      final appDir = await getApplicationDocumentsDirectory();
      final tempDir = await getTemporaryDirectory();

      // 1. Unzip to Staging
      final stagingDir = Directory(
        p.join(
          tempDir.path,
          'restore_staging_${DateTime.now().millisecondsSinceEpoch}',
        ),
      );
      if (await stagingDir.exists()) await stagingDir.delete(recursive: true);
      await stagingDir.create();

      final bytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      for (final file in archive) {
        final filename = file.name;
        if (file.isFile) {
          final data = file.content as List<int>;
          File(p.join(stagingDir.path, filename))
            ..createSync(recursive: true)
            ..writeAsBytesSync(data);
        } else {
          Directory(p.join(stagingDir.path, filename)).create(recursive: true);
        }
      }

      // 2. Locate db.sqlite in Staging
      File? newDbFile;
      Directory? newImagesDir;

      final rootDb = File(p.join(stagingDir.path, 'db.sqlite'));
      if (await rootDb.exists()) {
        newDbFile = rootDb;
        newImagesDir = Directory(p.join(stagingDir.path, 'images'));
      } else {
        await for (var entity in stagingDir.list()) {
          if (entity is Directory) {
            final subDb = File(p.join(entity.path, 'db.sqlite'));
            if (await subDb.exists()) {
              newDbFile = subDb;
              newImagesDir = Directory(p.join(entity.path, 'images'));
              break;
            }
          }
        }
      }

      if (newDbFile == null) {
        throw "File cadangan tidak valid: db.sqlite tidak ditemukan di dalam file ZIP.";
      }

      // 3. RESTORE IMAGES to App Documents Root
      if (newImagesDir != null && await newImagesDir.exists()) {
        await for (var img in newImagesDir.list()) {
          if (img is File) {
            final filename = p.basename(img.path);
            await img.copy(p.join(appDir.path, filename));
          }
        }
      }

      // 4. SMART IMPORT DATA directly into active database (NO _db.close(), NO connection loss!)
      final backupDb = NativeDatabase(newDbFile);
      final executor = backupDb;
      await executor.ensureOpen(_QueryExecutorUser());

      // Ambil Admin aktif lokal saat ini sebelum ditimpa agar kredensial tidak hilang
      final localAdmins = await (_db.select(_db.profiles)
            ..where((t) => t.role.equals('admin') | t.role.equals('owner')))
          .get();
      final Profile? currentAdmin = localAdmins.isNotEmpty ? localAdmins.first : null;

      final tables = [
        'stores',
        'categories',
        'units',
        'products',
        'product_options',
        'product_option_values',
        'transactions',
        'transaction_items',
        'attendance_logs',
        'promotions',
        'promotion_items',
        'expenses',
        'customers',
        'payment_methods',
        'store_tables',
        'profiles',
      ];

      try {
        await _db.transaction(() async {
          await _db.customStatement('PRAGMA foreign_keys = OFF;');

          for (final table in tables) {
            try {
              // Cek apakah tabel ada di database backup
              final check = await executor.runSelect(
                "SELECT name FROM sqlite_master WHERE type='table' AND name = ?",
                [table],
              );
              if (check.isEmpty) continue;

              final rows = await executor.runSelect('SELECT * FROM "$table"', []);
              if (rows.isEmpty) {
                await _db.customStatement('DELETE FROM "$table";');
                continue;
              }

              // Hapus data lokal pada tabel ini
              await _db.customStatement('DELETE FROM "$table";');

              // Ambil daftar kolom
              final firstRow = rows.first;
              final colNames = firstRow.keys.toList();
              final placeholders = List.filled(colNames.length, '?').join(', ');
              final quotedCols = colNames.map((c) => '"$c"').join(', ');
              final insertSql = 'INSERT OR REPLACE INTO "$table" ($quotedCols) VALUES ($placeholders);';

              for (final row in rows) {
                final values = colNames.map((c) => row[c]).toList();
                await _db.customStatement(insertSql, values);
              }
            } catch (err) {
              debugPrint("Smart Restore: warning importing table $table: $err");
            }
          }

          await _db.customStatement('PRAGMA foreign_keys = ON;');
        });
      } finally {
        await executor.close();
      }

      // 5. SINKRONISASI TOKO UTAMA & AFILIASI ADMIN
      // Temukan Toko Utama dari data hasil restore (toko yang memiliki data)
      final allStores = await _db.select(_db.stores).get();
      String? primaryStoreId;
      String? primaryStoreName;

      if (allStores.isNotEmpty) {
        primaryStoreId = allStores.first.id;
        primaryStoreName = allStores.first.name;
      }

      if (primaryStoreId != null) {
        // Jika ada admin lokal aktif (misal Streak Asri), pastikan tetap ada dan terikat ke toko hasil restore
        if (currentAdmin != null) {
          await _db.into(_db.profiles).insertOnConflictUpdate(
                ProfilesCompanion(
                  id: Value(currentAdmin.id),
                  fullName: Value(currentAdmin.fullName),
                  email: Value(currentAdmin.email),
                  password: Value(currentAdmin.password),
                  role: const Value('admin'),
                  storeId: Value(primaryStoreId),
                  lastUpdated: Value(DateTime.now()),
                ),
              );

          // Update nama toko menjadi nama toko yang sedang dikelola jika relevan
          if (currentAdmin.fullName != null && currentAdmin.fullName!.isNotEmpty) {
            await (_db.update(_db.stores)..where((t) => t.id.equals(primaryStoreId!))).write(
                  StoresCompanion(
                    name: Value(currentAdmin.fullName!.toLowerCase().contains('toko')
                        ? currentAdmin.fullName
                        : 'Toko ${currentAdmin.fullName}'),
                    adminName: Value(currentAdmin.fullName),
                  ),
                );
          }
        }

        // Pastikan seluruh staf & kasir & admin terafiliasi ke Toko Utama hasil restore
        await (_db.update(_db.profiles)..where((t) => t.role.isIn(['cashier', 'staff', 'admin', 'owner']))).write(
              ProfilesCompanion(storeId: Value(primaryStoreId)),
            );


      }

      // 6. FIX IMAGE PATHS untuk platform saat ini
      Future<void> fixImageTable(String tableName, String colName, String idCol) async {
        try {
          final rows = await _db.customSelect(
            'SELECT $idCol, $colName FROM "$tableName" WHERE $colName IS NOT NULL',
          ).get();

          for (final row in rows) {
            final id = row.read<String>(idCol);
            final oldPath = row.read<String?>(colName);
            if (oldPath == null || oldPath.toLowerCase().startsWith('http')) continue;

            final filename = oldPath.split(RegExp(r'[/\\]')).last;
            final newPath = p.join(appDir.path, filename);

            if (oldPath != newPath) {
              await _db.customStatement(
                'UPDATE "$tableName" SET "$colName" = ? WHERE "$idCol" = ?',
                [newPath, id],
              );
            }
          }
        } catch (e) {
          debugPrint("Smart Restore: skip fixImageTable $tableName: $e");
        }
      }

      await fixImageTable('products', 'image_url', 'id');
      await fixImageTable('stores', 'logo_url', 'id');
      await fixImageTable('stores', 'admin_avatar', 'id');
      await fixImageTable('profiles', 'avatar_url', 'id');
      await fixImageTable('attendance_logs', 'photo_url', 'id');
      await fixImageTable('categories', 'icon_url', 'id');

      // 7. Bersihkan Staging Directory
      try {
        if (await stagingDir.exists()) await stagingDir.delete(recursive: true);
      } catch (_) {}

      debugPrint("Smart Restore selesai: Toko Utama $primaryStoreId ($primaryStoreName)");
      return primaryStoreId;
    } catch (e) {
      debugPrint("Restore Error: $e");
      rethrow;
    }
  }
}

class _QueryExecutorUser extends QueryExecutorUser {
  @override
  Future<void> beforeOpen(
    QueryExecutor executor,
    OpeningDetails details,
  ) async {}
  @override
  int get schemaVersion => 10;
}
