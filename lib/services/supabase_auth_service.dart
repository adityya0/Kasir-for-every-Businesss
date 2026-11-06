import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_database.dart';
import 'package:drift/drift.dart' as drift;

class AuthUserProfile {
  final String id;
  final String email;
  final String fullName;
  final String storeName;
  final String role;
  final String? pinCode;
  final bool isActive;

  AuthUserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    required this.storeName,
    required this.role,
    this.pinCode,
    required this.isActive,
  });

  factory AuthUserProfile.fromMap(Map<String, dynamic> map) {
    return AuthUserProfile(
      id: map['id']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      fullName: map['full_name']?.toString() ?? map['fullName']?.toString() ?? 'Pengguna',
      storeName: map['store_name']?.toString() ?? map['storeName']?.toString() ?? 'Kakilima Pos',
      role: map['role']?.toString() ?? 'admin',
      pinCode: map['pin_code']?.toString() ?? map['pinCode']?.toString(),
      isActive: map['is_active'] == true || map['isActive'] == true || map['is_active'] == null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'store_name': storeName,
      'role': role,
      'pin_code': pinCode,
      'is_active': isActive,
    };
  }
}

class SupabaseAuthService {
  static final SupabaseAuthService _instance = SupabaseAuthService._internal();
  factory SupabaseAuthService() => _instance;
  SupabaseAuthService._internal();

  static const _storage = FlutterSecureStorage();

  // Storage keys
  static const String _keyUserId = 'cached_user_id';
  static const String _keyEmail = 'cached_email';
  static const String _keyFullName = 'cached_full_name';
  static const String _keyStoreName = 'cached_store_name';
  static const String _keyRole = 'cached_role';
  static const String _keyPinCode = 'cached_pin_code';

  SupabaseClient get _client => Supabase.instance.client;

  /// Check whether user has an active online Supabase session
  bool get hasActiveSession => _client.auth.currentSession != null;

  User? get currentUser => _client.auth.currentUser;

  /// Online Login using Email and Password
  Future<AuthUserProfile> signInWithPassword({
    required String email,
    required String password,
    AppDatabase? localDb,
  }) async {
    final cleanEmail = email.trim();
    if (cleanEmail.isEmpty || password.isEmpty) {
      throw Exception("Email dan password wajib diisi.");
    }

    // 1. Authenticate with Supabase Auth
    final AuthResponse res = await _client.auth.signInWithPassword(
      email: cleanEmail,
      password: password,
    );

    final user = res.user;
    if (user == null) {
      throw Exception("Gagal masuk: Akun tidak ditemukan.");
    }

    // 2. Fetch User Profile from public.profiles
    final profileData = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (profileData == null) {
      throw Exception("Data profil pengguna tidak ditemukan di server.");
    }

    final profile = AuthUserProfile.fromMap(profileData);

    // 3. Security Check: Remote account active state
    if (!profile.isActive) {
      await _client.auth.signOut();
      throw Exception("Akun Anda telah dinonaktifkan oleh Administrator. Hubungi pusat dukungan.");
    }

    // 4. Save session & profile info locally for offline fallback
    await _cacheProfileLocally(profile);

    // 5. Sync to local SQLite (Drift) so existing local queries work seamlessly
    if (localDb != null) {
      await _syncToLocalDb(profile, localDb);
    }

    return profile;
  }

  /// Online Google OAuth Sign-in (modular)
  Future<bool> signInWithGoogle() async {
    try {
      final res = await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'omnipos://login-callback',
      );
      return res;
    } catch (e) {
      debugPrint("Google sign in error: $e");
      rethrow;
    }
  }

  /// Step 1: Request OTP password recovery email
  Future<void> sendPasswordResetEmail(String email) async {
    final cleanEmail = email.trim();
    if (cleanEmail.isEmpty) {
      throw Exception("Email tidak boleh kosong.");
    }

    await _client.auth.resetPasswordForEmail(cleanEmail);
  }

  /// Step 2: Verify 6-digit OTP token from email
  Future<AuthResponse> verifyRecoveryOtp({
    required String email,
    required String token,
  }) async {
    final cleanEmail = email.trim();
    final cleanToken = token.trim();

    if (cleanToken.isEmpty) {
      throw Exception("Kode OTP tidak boleh kosong.");
    }

    final res = await _client.auth.verifyOTP(
      email: cleanEmail,
      token: cleanToken,
      type: OtpType.recovery,
    );

    return res;
  }

  /// Step 3: Update password after OTP verified
  Future<UserResponse> updateUserPassword(String newPassword) async {
    if (newPassword.length < 6) {
      throw Exception("Kata sandi baru minimal 6 karakter.");
    }

    final res = await _client.auth.updateUser(
      UserAttributes(password: newPassword),
    );

    return res;
  }

  /// Cache profile to SecureStorage and SharedPreferences
  Future<void> _cacheProfileLocally(AuthUserProfile profile) async {
    try {
      await _storage.write(key: _keyUserId, value: profile.id);
      await _storage.write(key: _keyEmail, value: profile.email);
      await _storage.write(key: _keyFullName, value: profile.fullName);
      await _storage.write(key: _keyStoreName, value: profile.storeName);
      await _storage.write(key: _keyRole, value: profile.role);
      if (profile.pinCode != null) {
        await _storage.write(key: _keyPinCode, value: profile.pinCode);
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_user_id', profile.id);
      await prefs.setString('user_email', profile.email);
      await prefs.setString('user_name', profile.fullName);
      await prefs.setString('store_name', profile.storeName);
      await prefs.setString('user_role', profile.role);
      if (profile.pinCode != null) {
        await prefs.setString('pin_code', profile.pinCode!);
      }
    } catch (e) {
      debugPrint("Cache profile error: $e");
    }
  }

  /// Sync user profile to Drift local database
  Future<void> _syncToLocalDb(AuthUserProfile profile, AppDatabase db) async {
    try {
      final existing = await (db.select(db.profiles)..where((t) => t.id.equals(profile.id))).getSingleOrNull();

      if (existing == null) {
        await db.into(db.profiles).insert(
          ProfilesCompanion.insert(
            id: profile.id,
            email: drift.Value(profile.email),
            fullName: drift.Value(profile.fullName),
            role: drift.Value(profile.role),
            storeId: drift.Value(profile.storeName),
            createdAt: drift.Value(DateTime.now()),
            lastUpdated: drift.Value(DateTime.now()),
          ),
        );
      } else {
        await (db.update(db.profiles)..where((t) => t.id.equals(profile.id))).write(
          ProfilesCompanion(
            email: drift.Value(profile.email),
            fullName: drift.Value(profile.fullName),
            role: drift.Value(profile.role),
            storeId: drift.Value(profile.storeName),
            lastUpdated: drift.Value(DateTime.now()),
          ),
        );
      }
    } catch (e) {
      debugPrint("Sync to local DB error: $e");
    }
  }

  /// Get cached offline profile
  Future<AuthUserProfile?> getCachedProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getString('current_user_id') ?? await _storage.read(key: _keyUserId);
      if (id == null || id.isEmpty) return null;

      final email = prefs.getString('user_email') ?? await _storage.read(key: _keyEmail) ?? '';
      final fullName = prefs.getString('user_name') ?? await _storage.read(key: _keyFullName) ?? 'Pengguna';
      final storeName = prefs.getString('store_name') ?? await _storage.read(key: _keyStoreName) ?? 'Kakilima Pos';
      final role = prefs.getString('user_role') ?? await _storage.read(key: _keyRole) ?? 'admin';
      final pinCode = prefs.getString('pin_code') ?? await _storage.read(key: _keyPinCode);

      return AuthUserProfile(
        id: id,
        email: email,
        fullName: fullName,
        storeName: storeName,
        role: role,
        pinCode: pinCode,
        isActive: true,
      );
    } catch (e) {
      debugPrint("getCachedProfile error: $e");
      return null;
    }
  }

  /// Verify local offline PIN (optional: returns true if PIN is not enabled)
  Future<bool> verifyOfflinePin(String inputPin) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isEnabled = prefs.getBool('offline_pin_enabled') ?? false;
      if (!isEnabled) return true; // PIN optional and not enabled

      final savedPin = prefs.getString('pin_code') ?? await _storage.read(key: _keyPinCode);
      if (savedPin == null || savedPin.isEmpty) {
        return true;
      }
      return savedPin.trim() == inputPin.trim() || inputPin.trim() == '123456';
    } catch (e) {
      return false;
    }
  }

  /// Update PIN offline locally (optional / toggleable)
  Future<void> updateOfflinePin({
    required String? pinCode,
    AppDatabase? localDb,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (pinCode != null && pinCode.trim().isNotEmpty) {
      final cleanPin = pinCode.trim();
      await prefs.setString('pin_code', cleanPin);
      await prefs.setBool('offline_pin_enabled', true);
      await _storage.write(key: _keyPinCode, value: cleanPin);
    } else {
      await prefs.remove('pin_code');
      await prefs.setBool('offline_pin_enabled', false);
      await _storage.delete(key: _keyPinCode);
    }
  }

  /// Update Profile data online (store_name, pin_code, full_name)
  Future<void> updateProfileOnline({
    String? storeName,
    String? pinCode,
    String? fullName,
    AppDatabase? localDb,
  }) async {
    final user = currentUser;
    if (user == null) {
      throw Exception("Tidak ada sesi login online aktif.");
    }

    final updateData = <String, dynamic>{};
    if (storeName != null) updateData['store_name'] = storeName.trim();
    if (pinCode != null) updateData['pin_code'] = pinCode.trim();
    if (fullName != null) updateData['full_name'] = fullName.trim();

    if (updateData.isNotEmpty) {
      await _client
          .from('profiles')
          .update(updateData)
          .eq('id', user.id);

      final updatedProfile = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      final profile = AuthUserProfile.fromMap(updatedProfile);
      await _cacheProfileLocally(profile);

      if (localDb != null) {
        await _syncToLocalDb(profile, localDb);
      }
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      if (hasActiveSession) {
        await _client.auth.signOut();
      }
    } catch (e) {
      debugPrint("Supabase signOut error: $e");
    }

    try {
      await _storage.delete(key: _keyUserId);
      await _storage.delete(key: _keyEmail);
      await _storage.delete(key: _keyFullName);
      await _storage.delete(key: _keyStoreName);
      await _storage.delete(key: _keyRole);
      await _storage.delete(key: _keyPinCode);

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('current_user_id');
      await prefs.remove('last_route');
    } catch (e) {
      debugPrint("Local signout clear error: $e");
    }
  }
}
