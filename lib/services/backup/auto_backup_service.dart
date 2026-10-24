import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../app_database.dart';
import '../backup_service.dart';
import 'google_drive_service.dart';

class AutoBackupResult {
  final bool success;
  final String message;

  AutoBackupResult({required this.success, required this.message});
}

class AutoBackupService extends ChangeNotifier with WidgetsBindingObserver {
  AutoBackupService._internal();
  static final AutoBackupService instance = AutoBackupService._internal();

  AppDatabase? _db;
  Timer? _schedulerTimer;

  bool _isEnabled = false;
  TimeOfDay _backupTime = const TimeOfDay(hour: 23, minute: 59);
  bool _wifiOnly = true;
  String? _lastBackupDate;
  String? _lastBackupStatus;
  bool _isBackingUp = false;

  // Getters
  bool get isEnabled => _isEnabled;
  TimeOfDay get backupTime => _backupTime;
  bool get wifiOnly => _wifiOnly;
  String? get lastBackupDate => _lastBackupDate;
  String? get lastBackupStatus => _lastBackupStatus;
  bool get isBackingUp => _isBackingUp;

  static const String keyEnabled = 'auto_backup_enabled';
  static const String keyHour = 'auto_backup_hour';
  static const String keyMinute = 'auto_backup_minute';
  static const String keyWifiOnly = 'auto_backup_wifi_only';
  static const String keyLastDate = 'auto_backup_last_date';
  static const String keyLastStatus = 'auto_backup_last_status';

  /// Inisialisasi service dengan database aktif dan memuat konfigurasi
  Future<void> init(AppDatabase db) async {
    _db = db;
    await _loadSettings();

    // Dengarkan perubahan lifecycle (ketika aplikasi dibuka kembali dari background)
    try {
      WidgetsBinding.instance.removeObserver(this);
      WidgetsBinding.instance.addObserver(this);
    } catch (_) {}

    _startScheduler();
    
    // Cek sesaat setelah boot apakah ada jadwal backup hari ini yang terlewat
    Future.delayed(const Duration(seconds: 5), () {
      checkAndRunBackup();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      checkAndRunBackup();
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isEnabled = prefs.getBool(keyEnabled) ?? false;
    final hour = prefs.getInt(keyHour) ?? 23;
    final minute = prefs.getInt(keyMinute) ?? 59;
    _backupTime = TimeOfDay(hour: hour, minute: minute);
    _wifiOnly = prefs.getBool(keyWifiOnly) ?? true;
    _lastBackupDate = prefs.getString(keyLastDate);
    _lastBackupStatus = prefs.getString(keyLastStatus);
    notifyListeners();
  }

  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyEnabled, enabled);
    _isEnabled = enabled;
    notifyListeners();

    if (enabled) {
      checkAndRunBackup();
    }
  }

  Future<void> setBackupTime(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(keyHour, time.hour);
    await prefs.setInt(keyMinute, time.minute);
    _backupTime = time;
    notifyListeners();
  }

  Future<void> setWifiOnly(bool wifiOnly) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyWifiOnly, wifiOnly);
    _wifiOnly = wifiOnly;
    notifyListeners();
  }

  void _startScheduler() {
    _schedulerTimer?.cancel();
    // Memeriksa setiap 30 detik untuk akurasi ketepatan menit
    _schedulerTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      checkAndRunBackup();
    });
  }

  void stopScheduler() {
    _schedulerTimer?.cancel();
    _schedulerTimer = null;
  }

  /// Cek koneksi Wi-Fi atau koneksi jaringan stabil
  Future<bool> checkWifiConnection() async {
    try {
      final results = await Connectivity().checkConnectivity();
      if (results.contains(ConnectivityResult.wifi)) {
        return true;
      }
      // Untuk platform Desktop (Windows / macOS / Linux), Ethernet juga valid
      if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
        if (results.contains(ConnectivityResult.ethernet)) {
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint("Gagal memeriksa koneksi Wi-Fi: $e");
      return false;
    }
  }

  Future<bool> _hasAnyConnection() async {
    try {
      final results = await Connectivity().checkConnectivity();
      return !results.contains(ConnectivityResult.none) && results.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  void _updateStatus(String status) {
    _lastBackupStatus = status;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString(keyLastStatus, status);
    });
    notifyListeners();
  }

  /// Memeriksa kondisi jadwal & mengeksekusi pencadangan otomatis
  Future<AutoBackupResult> checkAndRunBackup({bool force = false}) async {
    if (_isBackingUp) {
      return AutoBackupResult(
        success: false,
        message: "Proses pencadangan sedang berjalan...",
      );
    }

    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(keyEnabled) ?? false;
    if (!enabled && !force) {
      return AutoBackupResult(
        success: false,
        message: "Pencadangan otomatis tidak aktif",
      );
    }

    // Pastikan akun Google Drive sudah terhubung
    final savedEmail = prefs.getString('gdrive_user_email');
    if (savedEmail == null || savedEmail.isEmpty) {
      if (force) {
        return AutoBackupResult(
          success: false,
          message: "Akun Google Drive belum terhubung. Silakan hubungkan akun terlebih dahulu.",
        );
      }
      _updateStatus("Tertunda: Akun Google Drive belum terhubung");
      return AutoBackupResult(
        success: false,
        message: "Akun Google Drive belum terhubung",
      );
    }

    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final lastDate = prefs.getString(keyLastDate);

    if (!force) {
      // 1. Cek apakah hari ini sudah dicadangkan
      if (lastDate == todayStr) {
        return AutoBackupResult(
          success: false,
          message: "Pencadangan untuk hari ini sudah selesai",
        );
      }

      // 2. Cek waktu target (jam & menit)
      final targetHour = prefs.getInt(keyHour) ?? 23;
      final targetMinute = prefs.getInt(keyMinute) ?? 59;

      // Terpicu jika jam dan menit telah mencapai target waktu hari ini
      final isTimeReached = (now.hour > targetHour) || (now.hour == targetHour && now.minute >= targetMinute);
      if (!isTimeReached) {
        return AutoBackupResult(
          success: false,
          message: "Belum mencapai waktu pencadangan (${targetHour.toString().padLeft(2, '0')}:${targetMinute.toString().padLeft(2, '0')})",
        );
      }
    }

    // 3. Cek Koneksi Wi-Fi
    final wifiOnly = prefs.getBool(keyWifiOnly) ?? true;
    if (wifiOnly) {
      final isWifi = await checkWifiConnection();
      if (!isWifi) {
        const pendingMsg = "Tertunda: Menunggu tersambung ke Wi-Fi";
        _updateStatus(pendingMsg);
        return AutoBackupResult(
          success: false,
          message: pendingMsg,
        );
      }
    } else {
      final isOnline = await _hasAnyConnection();
      if (!isOnline) {
        const pendingMsg = "Tertunda: Menunggu koneksi internet";
        _updateStatus(pendingMsg);
        return AutoBackupResult(
          success: false,
          message: pendingMsg,
        );
      }
    }

    // Eksekusi Pencadangan
    _isBackingUp = true;
    _updateStatus("Sedang mencadangkan database & mengunggah ke Google Drive...");
    notifyListeners();

    try {
      if (_db == null) {
        throw "Koneksi database lokal tidak tersedia";
      }

      final backupService = BackupService(_db!);
      final zipPath = await backupService.createFullBackup(share: false);
      if (zipPath == null) {
        throw "Gagal membuat file arsip cadangan lokal (.zip)";
      }

      final fileName = p.basename(zipPath);
      final driveService = GoogleDriveService();
      
      // Upload ke Google Drive (silent jika otomatis, non-silent jika trigger manual via tombol uji coba)
      await driveService.uploadBackup(
        zipPath,
        fileName,
        singleBackup: true,
        silent: !force,
      );

      final finishTimeStr = DateFormat('dd MMM yyyy HH:mm', 'id_ID').format(DateTime.now());
      final successMsg = "Berhasil ($finishTimeStr)";

      await prefs.setString(keyLastDate, todayStr);
      await prefs.setString(keyLastStatus, successMsg);
      _lastBackupDate = todayStr;
      _lastBackupStatus = successMsg;
      notifyListeners();

      debugPrint("AutoBackupService: Pencadangan otomatis sukses pada $finishTimeStr");
      return AutoBackupResult(
        success: true,
        message: "Pencadangan berhasil diunggah ke Google Drive ($finishTimeStr)",
      );
    } catch (e) {
      final errMsg = "Gagal: $e";
      _updateStatus(errMsg);
      debugPrint("AutoBackupService Error: $e");
      return AutoBackupResult(
        success: false,
        message: errMsg,
      );
    } finally {
      _isBackingUp = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    try {
      WidgetsBinding.instance.removeObserver(this);
    } catch (_) {}
    _schedulerTimer?.cancel();
    super.dispose();
  }
}
