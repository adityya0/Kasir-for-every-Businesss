import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'supabase_auth_service.dart';

class SecurityPinService {
  static final SecurityPinService _instance = SecurityPinService._internal();
  factory SecurityPinService() => _instance;
  SecurityPinService._internal();

  static const String _keyPin = 'security_pin_code';
  static const String _keyEnabled = 'security_pin_enabled';
  static const String _legacyPin = 'pin_code';
  static const String _legacyEnabled = 'offline_pin_enabled';

  /// Check whether transaction security PIN is active
  Future<bool> isPinEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool(_keyEnabled) ?? prefs.getBool(_legacyEnabled) ?? false;
      if (!enabled) return false;
      final pin = prefs.getString(_keyPin) ?? prefs.getString(_legacyPin);
      return pin != null && pin.trim().isNotEmpty;
    } catch (e) {
      debugPrint("isPinEnabled error: $e");
      return false;
    }
  }

  /// Verify entered PIN against saved PIN.
  /// Strict check: must match exactly and not empty.
  Future<bool> verifyPin(String inputPin) async {
    try {
      final cleanInput = inputPin.trim();
      if (cleanInput.isEmpty) return false;

      final prefs = await SharedPreferences.getInstance();
      final savedPin = prefs.getString(_keyPin) ?? prefs.getString(_legacyPin);
      if (savedPin == null || savedPin.trim().isEmpty) {
        return false;
      }
      return cleanInput == savedPin.trim();
    } catch (e) {
      debugPrint("verifyPin error: $e");
      return false;
    }
  }

  /// Set a new PIN and activate protection
  Future<bool> setPin(String newPin) async {
    try {
      final cleanPin = newPin.trim();
      if (cleanPin.length < 4) return false;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyPin, cleanPin);
      await prefs.setBool(_keyEnabled, true);

      // Sync legacy keys for system-wide compatibility
      await prefs.setString(_legacyPin, cleanPin);
      await prefs.setBool(_legacyEnabled, true);

      try {
        await SupabaseAuthService().updateOfflinePin(pinCode: cleanPin);
      } catch (e) {
        debugPrint("Sync Supabase offline pin error: $e");
      }

      return true;
    } catch (e) {
      debugPrint("setPin error: $e");
      return false;
    }
  }

  /// Change PIN: requires current active PIN to match first
  Future<bool> changePin({
    required String currentPin,
    required String newPin,
  }) async {
    final isValid = await verifyPin(currentPin);
    if (!isValid) return false;

    return await setPin(newPin);
  }

  /// Disable/Remove PIN: requires current active PIN to match first
  Future<bool> disablePin({
    required String currentPin,
  }) async {
    final isValid = await verifyPin(currentPin);
    if (!isValid) return false;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyEnabled, false);
      await prefs.remove(_keyPin);

      // Legacy sync
      await prefs.setBool(_legacyEnabled, false);
      await prefs.remove(_legacyPin);

      try {
        await SupabaseAuthService().updateOfflinePin(pinCode: null);
      } catch (e) {
        debugPrint("Sync Supabase offline pin clear error: $e");
      }

      return true;
    } catch (e) {
      debugPrint("disablePin error: $e");
      return false;
    }
  }
}

