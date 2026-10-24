import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import 'app_database.dart';

class SuperAdminService {
  final AppDatabase db;

  static const String superAdminId = 'super_admin_master';
  static const String defaultEmail = 'superadmin@pos.com';
  static const String defaultUsername = 'superadmin';
  static const String defaultPassword = 'superadmin123';
  static const String defaultFullName = 'Super Administrator';
  static const String roleSuperAdmin = 'super_admin';

  SuperAdminService(this.db);

  /// Memastikan Akun Super Admin Bawaan Permanen selalu ada di SQLite database.
  /// Jika belum ada, otomatis dibuat dengan kredensial default:
  /// - Email / Username: superadmin@pos.com / superadmin
  /// - Password: superadmin123
  /// - Role: super_admin
  Future<Profile> ensureSuperAdminExists() async {
    try {
      // 1. Cek apakah akun super admin sudah ada berdasarkan id, role, atau email
      final existing = await (db.select(db.profiles)
            ..where((t) => Expression.or([
                  t.id.equals(superAdminId),
                  t.role.equals(roleSuperAdmin),
                  t.email.equals(defaultEmail),
                ]))
            ..limit(1))
          .getSingleOrNull();

      if (existing != null) {
        // Pastikan role-nya adalah super_admin
        if (existing.role != roleSuperAdmin) {
          await (db.update(db.profiles)..where((t) => t.id.equals(existing.id))).write(
            const ProfilesCompanion(role: Value(roleSuperAdmin)),
          );
          return (await (db.select(db.profiles)..where((t) => t.id.equals(existing.id))).getSingle());
        }
        return existing;
      }

      // 2. Siapkan Store ID (Gunakan store yang sudah ada atau buat store master)
      final existingStores = await (db.select(db.stores)..limit(1)).get();
      String storeId = 'store_master';
      if (existingStores.isNotEmpty) {
        storeId = existingStores.first.id;
      } else {
        await db.into(db.stores).insert(
              StoresCompanion.insert(
                id: storeId,
                name: const Value('Pusat Toko Asri (Master)'),
                adminName: const Value(defaultFullName),
                createdAt: Value(DateTime.now()),
              ),
            );
      }

      // 3. Masukkan profil Super Admin permanen
      final companion = ProfilesCompanion.insert(
        id: superAdminId,
        email: const Value(defaultEmail),
        password: const Value(defaultPassword),
        fullName: const Value(defaultFullName),
        role: const Value(roleSuperAdmin),
        storeId: Value(storeId),
        createdAt: Value(DateTime.now()),
      );

      await db.into(db.profiles).insert(companion);
      debugPrint("Super Admin Permanen berhasil dibuat: $defaultEmail / $defaultPassword");

      return (await (db.select(db.profiles)..where((t) => t.id.equals(superAdminId))).getSingle());
    } catch (e) {
      debugPrint("Error ensuring super admin: $e");
      // Jika terjadi race condition atau sudah ada, ambil kembali
      final fallback = await (db.select(db.profiles)
            ..where((t) => t.id.equals(superAdminId))
            ..limit(1))
          .getSingleOrNull();
      if (fallback != null) return fallback;
      rethrow;
    }
  }

  /// Mengambil semua akun terdaftar di sistem beserta ringkasan aktivitasnya
  Future<List<Map<String, dynamic>>> getAllAccountsWithStats() async {
    // Ambil semua profil
    final allProfiles = await (db.select(db.profiles)
          ..orderBy([
            (t) => OrderingTerm(
                  expression: const CustomExpression<int>(
                    "CASE WHEN role = '$roleSuperAdmin' THEN 0 WHEN role IN ('admin', 'owner') THEN 1 ELSE 2 END",
                  ),
                  mode: OrderingMode.asc,
                ),
            (t) => OrderingTerm.desc(t.createdAt),
          ]))
        .get();

    // Ambil semua toko untuk mapping
    final allStores = await db.select(db.stores).get();
    final storeMap = {for (var s in allStores) s.id: s};

    final List<Map<String, dynamic>> results = [];

    for (final p in allProfiles) {
      final store = p.storeId != null ? storeMap[p.storeId] : null;

      // Hitung total transaksi kasir yang diproses akun ini
      int txCount = 0;
      double totalSales = 0.0;
      try {
        final txs = await (db.select(db.transactions)..where((t) => t.cashierId.equals(p.id))).get();
        txCount = txs.length;
        for (final tx in txs) {
          totalSales += (tx.totalAmount ?? 0.0);
        }
      } catch (_) {}

      results.add({
        'profile': p,
        'store': store,
        'storeName': store?.name ?? (p.storeId != null ? 'Toko (${p.storeId})' : 'Belum Ditentukan'),
        'adminName': store?.adminName,
        'transactionCount': txCount,
        'totalSales': totalSales,
        'isSuperAdmin': p.role == roleSuperAdmin || p.id == superAdminId,
      });
    }

    return results;
  }

  /// Reset Password Akun TERTENTU TANPA MENGHAPUS ATAU MENGUBAH DATA LAINNYA.
  /// Data transaksi, produk, absensi, gaji, toko, dan inventaris TETAP AMAN 100%.
  Future<void> resetPassword({
    required String userId,
    required String newPassword,
  }) async {
    await (db.update(db.profiles)..where((t) => t.id.equals(userId))).write(
      ProfilesCompanion(
        password: Value(newPassword),
        lastUpdated: Value(DateTime.now()),
      ),
    );
    debugPrint("Password untuk userId $userId berhasil direset tanpa menyentuh data lainnya.");
  }

  /// Reset password Super Admin sendiri
  Future<void> updateSuperAdminPassword(String newPassword) async {
    final superAdmins = await (db.select(db.profiles)
          ..where((t) => Expression.or([
                t.id.equals(superAdminId),
                t.role.equals(roleSuperAdmin),
              ])))
        .get();

    for (final sa in superAdmins) {
      await (db.update(db.profiles)..where((t) => t.id.equals(sa.id))).write(
        ProfilesCompanion(
          password: Value(newPassword),
          lastUpdated: Value(DateTime.now()),
        ),
      );
    }
  }

  /// Mengambil statistik sistem global untuk ringkasan di dashboard Super Admin
  Future<Map<String, int>> getSystemSummary() async {
    final profiles = await db.select(db.profiles).get();
    final stores = await db.select(db.stores).get();
    final transactions = await db.select(db.transactions).get();

    int superAdminCount = 0;
    int adminCount = 0;
    int staffCount = 0;

    for (final p in profiles) {
      if (p.role == roleSuperAdmin || p.id == superAdminId) {
        superAdminCount++;
      } else if (p.role == 'admin' || p.role == 'owner') {
        adminCount++;
      } else {
        staffCount++;
      }
    }

    return {
      'totalProfiles': profiles.length,
      'superAdmins': superAdminCount,
      'admins': adminCount,
      'staff': staffCount,
      'totalStores': stores.length,
      'totalTransactions': transactions.length,
    };
  }

  /// Hapus Akun Pengguna (Admin atau Karyawan).
  /// Akun Super Admin permanen DILINDUNGI dan TIDAK DAPAT dihapus!
  /// Catatan: Data transaksi toko yang pernah diproses tetap aman tersimpan di database.
  Future<bool> deleteAccount(String userId) async {
    final profile = await (db.select(db.profiles)..where((t) => t.id.equals(userId))).getSingleOrNull();
    if (profile == null) return false;

    if (isProtectedAccount(profile)) {
      throw Exception("Akun Super Admin permanen dilindungi dan tidak dapat dihapus!");
    }

    await (db.delete(db.profiles)..where((t) => t.id.equals(userId))).go();
    debugPrint("Akun $userId (${profile.fullName}) berhasil dihapus oleh Super Admin.");
    return true;
  }

  /// Memperbarui informasi akun (Nama, Email/Username, Peran, Sandi opsional)
  Future<void> updateAccount({
    required String userId,
    required String fullName,
    required String email,
    required String role,
    String? password,
  }) async {
    final profile = await (db.select(db.profiles)..where((t) => t.id.equals(userId))).getSingleOrNull();
    if (profile == null) throw Exception("Akun tidak ditemukan");

    // Jangan izinkan mengubah role Super Admin master
    final effectiveRole = isProtectedAccount(profile) ? roleSuperAdmin : role;

    await (db.update(db.profiles)..where((t) => t.id.equals(userId))).write(
      ProfilesCompanion(
        fullName: Value(fullName),
        email: Value(email),
        role: Value(effectiveRole),
        password: password != null && password.isNotEmpty ? Value(password) : const Value.absent(),
        lastUpdated: Value(DateTime.now()),
      ),
    );
  }

  /// Mengambil profil Admin Toko Utama yang aktif (bukan super admin)
  Future<Profile?> getActiveStoreAdmin() async {
    return (db.select(db.profiles)
          ..where((t) => (t.role.equals('admin') | t.role.equals('owner')) & t.role.equals(roleSuperAdmin).not())
          ..limit(1))
        .getSingleOrNull();
  }

  /// Mengambil info Toko berdasarkan ID
  Future<Store?> getStoreById(String storeId) async {
    return (db.select(db.stores)..where((t) => t.id.equals(storeId))).getSingleOrNull();
  }

  /// Membuat akun baru langsung dari konsol Super Admin
  Future<Profile> createAccount({
    required String fullName,
    required String email,
    required String password,
    required String role,
    String? storeId,
  }) async {
    // Pastikan email/username belum terpakai
    final existing = await (db.select(db.profiles)..where((t) => t.email.equals(email))).getSingleOrNull();
    if (existing != null) {
      throw Exception("Email/Username $email sudah digunakan oleh akun lain.");
    }

    // Ambil Admin Toko Utama yang sudah ada
    final activeAdmin = await getActiveStoreAdmin();

    // Aturan 1 Admin Toko di Sistem Offline
    if ((role == 'admin' || role == 'owner') && activeAdmin != null) {
      throw Exception("Sistem kasir offline hanya mendukung 1 Admin Toko Utama (${activeAdmin.fullName ?? activeAdmin.email}).");
    }

    String effectiveStoreId = storeId ?? '';
    if (effectiveStoreId.isEmpty) {
      if (activeAdmin != null && activeAdmin.storeId != null && activeAdmin.storeId!.isNotEmpty) {
        // Otomatis terafiliasi dengan toko milik Admin yang ada
        effectiveStoreId = activeAdmin.storeId!;
      } else {
        final stores = await (db.select(db.stores)..limit(1)).get();
        if (stores.isNotEmpty) {
          effectiveStoreId = stores.first.id;
        } else {
          effectiveStoreId = 'store_${DateTime.now().millisecondsSinceEpoch}';
          await db.into(db.stores).insert(
                StoresCompanion.insert(
                  id: effectiveStoreId,
                  name: Value('Toko $fullName'),
                  adminName: Value(fullName),
                  createdAt: Value(DateTime.now()),
                ),
              );
        }
      }
    }

    final newId = 'user_${DateTime.now().millisecondsSinceEpoch}';
    final companion = ProfilesCompanion.insert(
      id: newId,
      fullName: Value(fullName),
      email: Value(email),
      password: Value(password),
      role: Value(role),
      storeId: Value(effectiveStoreId),
      createdAt: Value(DateTime.now()),
    );

    await db.into(db.profiles).insert(companion);
    return (await (db.select(db.profiles)..where((t) => t.id.equals(newId))).getSingle());
  }

  /// Apakah akun ini bisa dihapus? Super Admin permanen TIDAK BISA dihapus!
  bool isProtectedAccount(Profile profile) {
    return profile.id == superAdminId || profile.role == roleSuperAdmin;
  }
}
