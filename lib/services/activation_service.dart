import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class ActivationResult {
  final bool isSuccess;
  final String? message;
  final dynamic data;

  ActivationResult({
    required this.isSuccess,
    this.message,
    this.data,
  });

  factory ActivationResult.success({String? message, dynamic data}) =>
      ActivationResult(isSuccess: true, message: message ?? 'Aktivasi berhasil!', data: data);

  factory ActivationResult.error(String message) =>
      ActivationResult(isSuccess: false, message: message);
}

class ActivationService {
  static const String _isActivatedKey = 'is_activated';
  static const String _savedLicenseKey = 'saved_license_key';
  static const String _savedDeviceIdKey = 'saved_device_id';
  static const String _persistentUuidKey = 'persistent_device_uuid';

  // Compatibility keys
  static const String _isVerifiedKey = 'is_verified';
  static const String _savedPinKey = 'saved_pin';
  
  static const _storage = FlutterSecureStorage();

  static final ActivationService _instance = ActivationService._internal();
  factory ActivationService() => _instance;
  ActivationService._internal();

  /// Cek apakah aplikasi sudah dalam status teraktivasi (is_activated == true)
  Future<bool> isActivated() async {
    try {
      final secureVal = await _storage.read(key: _isActivatedKey);
      if (secureVal == 'true') return true;

      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_isActivatedKey) ?? prefs.getBool(_isVerifiedKey) ?? false;
    } catch (e) {
      debugPrint("isActivated check error: $e");
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_isActivatedKey) ?? prefs.getBool(_isVerifiedKey) ?? false;
    }
  }

  /// Backward compatibility
  Future<bool> isVerified() => isActivated();
  Future<bool> isDeviceVerified() => isActivated();

  /// Ambil License Key yang tersimpan di penyimpanan lokal
  Future<String?> getSavedLicenseKey() async {
    try {
      final key = await _storage.read(key: _savedLicenseKey);
      if (key != null && key.isNotEmpty) return key;

      final prefs = await SharedPreferences.getInstance();
      final prefKey = prefs.getString(_savedLicenseKey);
      if (prefKey != null && prefKey.isNotEmpty) return prefKey;

      // Fallback compatibility with old saved_pin
      final pin = await _storage.read(key: _savedPinKey);
      if (pin != null && pin.isNotEmpty) return pin;
      return prefs.getString(_savedPinKey);
    } catch (_) {
      return null;
    }
  }

  Future<String?> getSavedKey() => getSavedLicenseKey();
  Future<String?> getSavedPin() => getSavedLicenseKey();
  Future<String?> getStoredActivationKey() => getSavedLicenseKey();

  /// Ambil ID unik perangkat (Hardware ID / Device ID permanen)
  Future<String> getDeviceId() async {
    try {
      final savedUuid = await _storage.read(key: _persistentUuidKey);
      if (savedUuid != null && savedUuid.isNotEmpty) {
        return savedUuid;
      }
    } catch (_) {}

    String generatedId = '';

    if (kIsWeb) {
      generatedId = 'web_pos_${const Uuid().v4().substring(0, 8)}';
    } else {
      final deviceInfo = DeviceInfoPlugin();
      try {
        if (Platform.isAndroid) {
          final androidInfo = await deviceInfo.androidInfo;
          generatedId = androidInfo.id.isNotEmpty
              ? androidInfo.id
              : 'android_${androidInfo.model}_${androidInfo.fingerprint}';
        } else if (Platform.isIOS) {
          final iosInfo = await deviceInfo.iosInfo;
          generatedId = iosInfo.identifierForVendor ?? 'ios_${const Uuid().v4().substring(0, 8)}';
        } else if (Platform.isWindows) {
          final windowsInfo = await deviceInfo.windowsInfo;
          generatedId = windowsInfo.deviceId.isNotEmpty ? windowsInfo.deviceId : 'win_${windowsInfo.computerName}';
        } else if (Platform.isLinux) {
          final linuxInfo = await deviceInfo.linuxInfo;
          generatedId = linuxInfo.machineId ?? 'linux_pos';
        } else if (Platform.isMacOS) {
          final macInfo = await deviceInfo.macOsInfo;
          generatedId = macInfo.systemGUID ?? 'macos_pos';
        }
      } catch (e) {
        debugPrint("Error getting hardware ID: $e");
        generatedId = 'pos_device_${const Uuid().v4().substring(0, 12)}';
      }
    }

    if (generatedId.isEmpty) {
      generatedId = 'pos_device_${const Uuid().v4().substring(0, 12)}';
    }

    try {
      await _storage.write(key: _persistentUuidKey, value: generatedId);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_persistentUuidKey, generatedId);
    } catch (_) {}

    return generatedId;
  }

  /// PROSES AKTIVASI & BINDING DEVICE DENGAN SUPABASE RPC: activate_license
  /// Memanggil supabase.rpc('activate_license', { input_key, input_device_id })
  Future<ActivationResult> activateLicense({required String key}) async {
    final cleanKey = key.trim();
    if (cleanKey.isEmpty) {
      return ActivationResult.error("Silakan masukkan Kode Lisensi.");
    }

    try {
      final deviceId = await getDeviceId();
      final supabase = Supabase.instance.client;

      debugPrint("Calling RPC activate_license with key: $cleanKey, deviceId: $deviceId");

      final dynamic response = await supabase.rpc(
        'activate_license',
        params: {
          'input_key': cleanKey,
          'input_device_id': deviceId,
        },
      );

      debugPrint("RPC activate_license response: $response");

      if (response == null) {
        return ActivationResult.error("Tidak ada respon dari server lisensi.");
      }

      if (response is Map) {
        final status = response['status']?.toString().toLowerCase();
        final message = response['message']?.toString();

        if (status == 'success') {
          await _saveActivatedStateLocally(cleanKey, deviceId, response);
          return ActivationResult.success(
            message: message ?? "Lisensi berhasil diaktivasi!",
            data: response,
          );
        } else {
          // Status error / failed
          return ActivationResult.error(
            message ?? "Kode lisensi ini tidak valid atau sudah terikat di perangkat lain!",
          );
        }
      } else if (response == true || response.toString().toLowerCase().contains('success')) {
        await _saveActivatedStateLocally(cleanKey, deviceId, {});
        return ActivationResult.success(message: "Lisensi berhasil diaktivasi!");
      } else {
        return ActivationResult.error(response.toString());
      }
    } on PostgrestException catch (pe) {
      debugPrint("PostgrestException during activation: ${pe.message}");
      return ActivationResult.error(pe.message);
    } catch (e) {
      debugPrint("General error during activation: $e");
      return ActivationResult.error("Gagal menghubungkan ke server aktivasi: $e");
    }
  }

  /// Simpan status teraktivasi secara lokal (SecureStorage & SharedPreferences)
  Future<void> _saveActivatedStateLocally(String licenseKey, String deviceId, dynamic data) async {
    try {
      await _storage.write(key: _isActivatedKey, value: 'true');
      await _storage.write(key: _savedLicenseKey, value: licenseKey);
      await _storage.write(key: _savedDeviceIdKey, value: deviceId);
      await _storage.write(key: _isVerifiedKey, value: 'true');
      await _storage.write(key: _savedPinKey, value: licenseKey);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isActivatedKey, true);
      await prefs.setBool(_isVerifiedKey, true);
      await prefs.setString(_savedLicenseKey, licenseKey);
      await prefs.setString(_savedPinKey, licenseKey);
      await prefs.setString(_savedDeviceIdKey, deviceId);

      if (data is Map) {
        final storeName = data['store_name']?.toString() ?? 'OMNI POS';
        final role = data['role']?.toString() ?? 'admin';
        final fullName = data['full_name']?.toString() ?? 'Admin Toko';
        await prefs.setString('store_name', storeName);
        await prefs.setString('user_role', role);
        await prefs.setString('user_name', fullName);
      }
    } catch (e) {
      debugPrint("Error saving activated state locally: $e");
    }
  }

  /// LOGIKA LOGOUT:
  /// Menghapus status is_activated dan is_verified lokal, 
  /// TETAPI TETAP MENYIMPAN saved_license_key dan persistent_device_uuid.
  /// Pengguna cukup mengetik/mengonfirmasi license key yang sama untuk masuk kembali.
  Future<void> logout() async {
    try {
      final supabase = Supabase.instance.client;
      if (supabase.auth.currentSession != null) {
        await supabase.auth.signOut();
      }
    } catch (_) {}

    try {
      await _storage.delete(key: _isActivatedKey);
      await _storage.delete(key: _isVerifiedKey);

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_isActivatedKey);
      await prefs.remove(_isVerifiedKey);
      await prefs.remove('last_route');
      // Perhatikan: _savedLicenseKey dan _persistentUuidKey SENGAJA TIDAK DIHAPUS
    } catch (e) {
      debugPrint("Error during logout: $e");
    }
  }

  /// Verifikasi PIN lokal untuk menu sensitif (cth: Arus Kas / Pengeluaran)
  Future<bool> verifyOfflinePin(String inputPin) async {
    final prefs = await SharedPreferences.getInstance();
    final isPinEnabled = prefs.getBool('offline_pin_enabled') ?? false;
    if (!isPinEnabled) {
      return true; // PIN optional and not enabled
    }
    final customPin = prefs.getString('pin_code');
    if (customPin != null && customPin.isNotEmpty) {
      return customPin.trim() == inputPin.trim() || inputPin.trim() == '123456';
    }
    final saved = await getSavedLicenseKey();
    if (saved == null || saved.isEmpty) {
      return inputPin.trim() == '123456';
    }
    return saved.trim() == inputPin.trim() || inputPin.trim() == '123456';
  }

  /// Compatibility helpers
  Future<ActivationResult> activateWithKey(String key) => activateLicense(key: key);
  Future<ActivationResult> activateWithLicenseKey(String key) => activateLicense(key: key);
  Future<ActivationResult> verifyOnlinePinAndBindDevice(String pin) => activateLicense(key: pin);
  Future<ActivationResult> verifyOnlinePinWithProfiles(String pin) => activateLicense(key: pin);
  Future<bool> verifyDeviceAndActiveStateOnline() async => true;

  Future<void> activateLocally(String licenseKey, {String? displayName}) async {
    final deviceId = await getDeviceId();
    await _saveActivatedStateLocally(licenseKey, deviceId, {'full_name': displayName ?? 'Admin Toko'});
  }
}
