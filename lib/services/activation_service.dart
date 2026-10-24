import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

class ActivationService {
  static const String _activationKeyName = 'activation_key';
  static const String _userEmailKey = 'user_email';
  static const _storage = FlutterSecureStorage();

  /// Always true in offline standalone mode - no Supabase subscription needed
  Future<String?> getActivatedEmail() async {
    try {
      final email = await _storage.read(key: _userEmailKey);
      if (email != null && email.isNotEmpty) return email;
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('user_email');
    } catch (_) {
      return null;
    }
  }

  Future<bool> isActivated() async {
    return true; // Aplikasi sepenuhnya offline & bebas lisensi Supabase
  }

  /// Performs manual local activation (offline / direct registration)
  Future<void> activateLocally(String email, {String? displayName}) async {
    try {
      final deviceId = await _getDeviceId();
      final localKey = _generateLocalKey(email, deviceId, "LICENSED");
      await _storage.write(key: _activationKeyName, value: localKey);
      await _storage.write(key: _userEmailKey, value: email);
      if (displayName != null) {
        await _storage.write(key: 'user_display_name', value: displayName);
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_email', email);
      if (displayName != null) {
        await prefs.setString('user_display_name', displayName);
      }
    } catch (e) {
      debugPrint("activateLocally error: $e");
    }
  }

  /// Legacy stub: Google & Supabase online login is removed to keep app lightweight & offline
  Future<ActivationResult> activateWithGoogle({bool forceSelectAccount = false}) async {
    return ActivationResult.error("Fitur Supabase & Google Login telah dinonaktifkan.");
  }

  String _generateLocalKey(String email, String deviceId, String code) {
    final bytes = utf8.encode("$email:$deviceId:$code:SECRET_POS_ASRI_2024");
    return sha256.convert(bytes).toString();
  }

  Future<String> _getDeviceId() async {
    if (kIsWeb) return 'web_device';
    final deviceInfo = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? 'unknown_ios';
      } else if (Platform.isWindows) {
        final windowsInfo = await deviceInfo.windowsInfo;
        return windowsInfo.deviceId;
      }
    } catch (e) {
      return 'device_${DateTime.now().millisecondsSinceEpoch}';
    }
    return 'unknown_device';
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('current_user_id');
      await prefs.remove('last_route');
    } catch (e) {
      debugPrint("Prefs clear error: $e");
    }
  }
}

class ActivationResult {
  final bool isSuccess;
  final String? message;
  final String? email;
  final bool isCancelled;

  ActivationResult({
    required this.isSuccess,
    this.message,
    this.email,
    this.isCancelled = false,
  });

  factory ActivationResult.success({required String email}) =>
      ActivationResult(isSuccess: true, email: email);
  factory ActivationResult.error(String message) =>
      ActivationResult(isSuccess: false, message: message);
  factory ActivationResult.cancelled() =>
      ActivationResult(isSuccess: false, isCancelled: true);
}
