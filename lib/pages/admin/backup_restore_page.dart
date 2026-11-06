import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
// import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import '../../services/app_database.dart';
import '../../services/backup_service.dart';
import '../../services/backup/google_drive_service.dart';
import '../../services/backup/auto_backup_service.dart';
import '../../widgets/kasir_dialog.dart';
import '../../widgets/backup_time_picker_dialog.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../controllers/admin_controller.dart';

class BackupRestorePage extends StatefulWidget {
  final VoidCallback onBack;

  const BackupRestorePage({super.key, required this.onBack});

  @override
  State<BackupRestorePage> createState() => _BackupRestorePageState();
}

class _BackupRestorePageState extends State<BackupRestorePage> {
  final GoogleDriveService _driveService = GoogleDriveService();
  final AutoBackupService _autoBackup = AutoBackupService.instance;
  bool _isGdriveLoading = false;
  bool _isHistoryLoading = false;
  GoogleUserInfo? _currentUser;
  List<drive.File> _backupHistory = [];
  int _selectedTab = 0; // 0: Pencadangan, 1: Pemulihan

  @override
  void initState() {
    super.initState();
    _checkGdriveStatus();
    _autoBackup.addListener(_onAutoBackupStateChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowGdriveActivationDialog();
    });
  }

  @override
  void dispose() {
    _autoBackup.removeListener(_onAutoBackupStateChanged);
    super.dispose();
  }

  void _onAutoBackupStateChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _handleRestoreSuccess() async {
    if (!mounted) return;
    try {
      final adminCtrl = context.read<AdminController>();
      await adminCtrl.loadInitialData();
    } catch (e) {
      debugPrint("Error reloading AdminController: $e");
    }

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
            SizedBox(width: 10),
            Text("Pemulihan Berhasil"),
          ],
        ),
        content: const Text(
          "Seluruh data produk, riwayat transaksi, dan profil toko telah berhasil dipulihkan dan langsung siap digunakan tanpa harus menutup aplikasi.",
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC0392B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              widget.onBack();
            },
            child: const Text("Buka Kasir"),
          ),
        ],
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = (log(bytes) / log(1024)).floor();
    return "${(bytes / pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}";
  }

  Future<void> _checkGdriveStatus() async {
    setState(() => _isGdriveLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedEmail = prefs.getString('gdrive_user_email');
      // If we have saved user info, PULIHKAN it directly without any Google SDK call
      if (savedEmail != null && savedEmail.isNotEmpty && mounted) {
        setState(() {
          _currentUser = GoogleUserInfo(
            email: savedEmail,
            displayName: prefs.getString('gdrive_user_name'),
          );
        });
        _fetchHistory();
      }
    } catch (e) {
      debugPrint("Gdrive Status Check Error: $e");
    } finally {
      if (mounted) setState(() => _isGdriveLoading = false);
    }
  }

  Future<void> _handleGdriveSync() async {
    setState(() => _isGdriveLoading = true);
    try {
      final result = await _driveService.signIn();
      
      if (result != null) {
        // Persist user info in prefs so we never need to re-auth on page open
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_gdrive_synced', true);
        await prefs.setString('gdrive_user_email', result.email);
        if (result.displayName != null) {
          await prefs.setString('gdrive_user_name', result.displayName!);
        }
        
        if (mounted) {
          setState(() {
            _currentUser = result;
          });
          _fetchHistory();
        }
      } else {
        final err = _driveService.lastError ?? "";
        if (mounted) {
          _showGdriveActivationDialog(context, errorDetail: err);
        }
      }
    } catch (e) {
      if (mounted) {
        _showGdriveActivationDialog(context, errorDetail: e.toString());
      }
    } finally {
      if (mounted) setState(() => _isGdriveLoading = false);
    }
  }

  Future<void> _contactAdminWhatsApp() async {
    final prefs = await SharedPreferences.getInstance();
    final storeName = prefs.getString('store_name') ?? 'Toko Saya';

    final text = '''
Halo Admin Kakilima POS,

Saya ingin melakukan aktivasi fitur Pencadangan Google Drive untuk toko saya.

Data Pendaftaran:
• Nama Toko: $storeName
• Akun Gmail Saya: [MOHON TULIS GMAIL ANDA DI SINI]

Mohon bantuannya untuk mendaftarkan dan mengaktifkan akun Google Drive saya agar bisa melakukan pencadangan otomatis. Terima kasih!
'''.trim();

    final url = Uri.parse("https://wa.me/6283121782648?text=${Uri.encodeComponent(text)}");
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(url);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal membuka WhatsApp: $e. Hubungi nomor: 083121782648"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _checkAndShowGdriveActivationDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final alreadyShown = prefs.getBool('gdrive_activation_info_shown') ?? false;
    if (!alreadyShown && mounted) {
      await prefs.setBool('gdrive_activation_info_shown', true);
      if (!mounted) return;
      _showGdriveActivationDialog(context);
    }
  }

  void _showGdriveActivationDialog(BuildContext context, {String? errorDetail}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(22, 20, 22, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF25D366).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.chat_bubble_rounded, color: Color(0xFF25D366), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Aktivasi Google Drive",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        "Pencadangan Cloud Otomatis",
                        style: GoogleFonts.openSans(
                          fontSize: 11.5,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Untuk mengaktifkan fitur pencadangan otomatis Google Drive, Anda perlu menghubungi Admin WhatsApp agar akun Gmail Anda didaftarkan & diizinkan ke sistem cloud.",
                    style: GoogleFonts.openSans(
                      fontSize: 12.5,
                      height: 1.45,
                      color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline_rounded, size: 16, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Jangan lupa mengisi alamat Gmail Anda pada template pesan WhatsApp yang telah disediakan.",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _contactAdminWhatsApp();
                },
                icon: const Icon(Icons.chat_bubble_rounded, size: 18, color: Colors.white),
                label: Text(
                  "Hubungi WhatsApp (083121782648)",
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 38,
              child: TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  "Nanti Saja",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleGdriveLogout() async {
    setState(() => _isGdriveLoading = true);
    try {
      await _driveService.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('is_gdrive_synced');
      await prefs.remove('gdrive_user_email');
      await prefs.remove('gdrive_user_name');
      if (mounted) setState(() => _currentUser = null);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal Keluar: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isGdriveLoading = false);
    }
  }

  Future<void> _fetchHistory() async {
    if (_currentUser == null) return;
    setState(() => _isHistoryLoading = true);
    try {
      final history = await _driveService.listBackups();
      if (mounted) {
        setState(() => _backupHistory = history);
      }
    } catch (e) {
      debugPrint("Fetch History Error: $e");
    } finally {
      if (mounted) {
        setState(() => _isHistoryLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryColor = Color(0xFF00BF63);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final secondaryTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          "Pencadangan & Pemulihan",
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: widget.onBack,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, size: 21),
            tooltip: "Info Aktivasi Google Drive",
            onPressed: () => _showGdriveActivationDialog(context),
          ),
          const SizedBox(width: 8),
        ],
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          // ── SEGMENTED TAB SELECTOR (Efisien & Mudah Beralih) ─────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSegmentButton(
                      index: 0,
                      label: "Pencadangan (Backup)",
                      icon: Icons.cloud_upload_outlined,
                      isSelected: _selectedTab == 0,
                      primaryColor: primaryColor,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _buildSegmentButton(
                      index: 1,
                      label: "Pemulihan (Restore)",
                      icon: Icons.settings_backup_restore_rounded,
                      isSelected: _selectedTab == 1,
                      primaryColor: primaryColor,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── TAB CONTENT ──────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
              child: _selectedTab == 0
                  ? _buildBackupTab(isDark, primaryColor, cardBg, borderColor, secondaryTextColor)
                  : _buildRestoreTab(isDark, primaryColor, cardBg, borderColor, secondaryTextColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentButton({
    required int index,
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color primaryColor,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() => _selectedTab = index);
        if (index == 1 && _currentUser != null && _backupHistory.isEmpty) {
          _fetchHistory();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF334155) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 17,
              color: isSelected ? primaryColor : (isDark ? Colors.white60 : const Color(0xFF64748B)),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected
                    ? (isDark ? Colors.white : const Color(0xFF0F172A))
                    : (isDark ? Colors.white60 : const Color(0xFF64748B)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // TAB 1: PENCADANGAN (BACKUP)
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildBackupTab(
    bool isDark,
    Color primaryColor,
    Color cardBg,
    Color borderColor,
    Color secondaryTextColor,
  ) {
    final bool isSynced = _currentUser != null;
    final autoBackup = _autoBackup;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Info & Tombol Aktivasi WhatsApp ─────────────────────────────
        Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF25D366).withValues(alpha: isDark ? 0.12 : 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFF25D366).withValues(alpha: isDark ? 0.35 : 0.25),
              width: 1.1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF25D366).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.chat_bubble_rounded, color: Color(0xFF25D366), size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Aktivasi Google Drive via WhatsApp",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          "Hubungi admin untuk mendaftarkan akun Gmail Anda",
                          style: GoogleFonts.openSans(
                            fontSize: 11,
                            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                "Untuk mengaktifkan fitur pencadangan Google Drive, silakan hubungi nomor WhatsApp 083121782648 dan cantumkan alamat Gmail Anda.",
                style: GoogleFonts.openSans(
                  fontSize: 11.5,
                  height: 1.45,
                  color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 38,
                child: ElevatedButton.icon(
                  onPressed: _contactAdminWhatsApp,
                  icon: const Icon(Icons.chat_bubble_rounded, size: 16, color: Colors.white),
                  label: Text(
                    "Hubungi WhatsApp (083121782648)",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── 1. Unified Cloud & Auto-Backup Card ──────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1.1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Cloud
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (isSynced ? Colors.green : Colors.blue).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isSynced ? Icons.cloud_done_rounded : Icons.cloud_sync_rounded,
                      color: isSynced ? Colors.green : Colors.blue,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Google Drive Cloud",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          isSynced ? _currentUser!.email : "Belum terhubung ke cloud",
                          style: GoogleFonts.openSans(
                            fontSize: 12,
                            color: isSynced ? (isDark ? Colors.white70 : const Color(0xFF475569)) : secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isSynced ? Colors.green : Colors.grey).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSynced ? Colors.green : Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isSynced ? "Terhubung" : "Offline",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isSynced ? Colors.green : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              if (!isSynced) ...[
                Text(
                  "Hubungkan akun Google Drive untuk menyimpan database secara otomatis & aman di cloud tanpa takut data hilang.",
                  style: GoogleFonts.openSans(fontSize: 12, color: secondaryTextColor, height: 1.4),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: _isGdriveLoading ? null : _handleGdriveSync,
                    icon: _isGdriveLoading
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.link_rounded, size: 18),
                    label: Text(
                      _isGdriveLoading ? "Menghubungkan..." : "Hubungkan ke Google Drive",
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13.5),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 38,
                  child: OutlinedButton.icon(
                    onPressed: _contactAdminWhatsApp,
                    icon: const Icon(Icons.chat_bubble_rounded, size: 15, color: Color(0xFF25D366)),
                    label: Text(
                      "Aktivasi via WhatsApp (083121782648)",
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: const Color(0xFF25D366),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF25D366), width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ] else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Akun pencadangan aktif",
                      style: GoogleFonts.openSans(fontSize: 11.5, color: secondaryTextColor),
                    ),
                    InkWell(
                      onTap: _handleGdriveLogout,
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.logout_rounded, size: 14, color: Colors.red),
                            const SizedBox(width: 4),
                            Text(
                              "Putuskan",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 14),
              Divider(height: 1, color: borderColor),
              const SizedBox(height: 14),

              // Sub-section: Jadwal Pencadangan Otomatis
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.schedule_rounded, size: 18, color: Colors.teal),
                      const SizedBox(width: 8),
                      Text(
                        "Pencadangan Otomatis Harian",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  Switch(
                    value: autoBackup.isEnabled && isSynced,
                    activeThumbColor: Colors.teal,
                    onChanged: !isSynced
                        ? null
                        : (val) async {
                            await autoBackup.setEnabled(val);
                          },
                  ),
                ],
              ),

              if (autoBackup.isEnabled && isSynced) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    // Chip Ganti Jam
                    InkWell(
                      onTap: () async {
                        final picked = await BackupTimePickerDialog.show(
                          context,
                          initialTime: autoBackup.backupTime,
                        );
                        if (picked != null) {
                          await autoBackup.setBackupTime(picked);
                        }
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.teal.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.teal.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.alarm_rounded, size: 15, color: Colors.teal),
                            const SizedBox(width: 6),
                            Text(
                              "${autoBackup.backupTime.hour.toString().padLeft(2, '0')}:${autoBackup.backupTime.minute.toString().padLeft(2, '0')} WIB",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.teal,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.edit_rounded, size: 12, color: Colors.teal),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Hanya Wi-Fi
                    Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.wifi_rounded, size: 16, color: secondaryTextColor),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              "Hanya Wi-Fi",
                              style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                          Switch(
                            value: autoBackup.wifiOnly,
                            activeThumbColor: Colors.teal,
                            onChanged: (val) async {
                              await autoBackup.setWifiOnly(val);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        autoBackup.lastBackupStatus != null
                            ? "Status: ${autoBackup.lastBackupStatus}"
                            : "Status: Menunggu jadwal pkl ${autoBackup.backupTime.hour.toString().padLeft(2, '0')}:${autoBackup.backupTime.minute.toString().padLeft(2, '0')}",
                        style: GoogleFonts.openSans(fontSize: 11, color: secondaryTextColor),
                      ),
                    ),
                    InkWell(
                      onTap: autoBackup.isBackingUp
                          ? null
                          : () async {
                              final messenger = ScaffoldMessenger.of(context);
                              messenger.showSnackBar(const SnackBar(content: Text("Memulai uji coba pencadangan...")));
                              final res = await autoBackup.checkAndRunBackup(force: true);
                              if (!mounted) return;
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(res.message),
                                  backgroundColor: res.success ? Colors.green : Colors.red,
                                ),
                              );
                              if (res.success) _fetchHistory();
                            },
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        child: Text(
                          "Uji Coba Sekarang",
                          style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.teal),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ── 2. Aksi Cadangkan Cepat (Side-by-Side 2 Cards) ────────────────────
        Text(
          "AKSI PENCADANGAN CEPAT",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            color: isDark ? Colors.white60 : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // Card A: Ke Google Drive
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.cloud_upload_rounded,
                iconColor: Colors.green,
                title: "Ke Google Drive",
                subtitle: isSynced ? "Unggah cadangan ke cloud" : "Hubungkan Drive dahulu",
                isDark: isDark,
                cardBg: cardBg,
                borderColor: borderColor,
                secondaryTextColor: secondaryTextColor,
                isDisabled: !isSynced,
                onTap: isSynced ? () => _backupToGdrive(context) : null,
              ),
            ),
            const SizedBox(width: 10),
            // Card B: Ekspor & Bagikan
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.share_rounded,
                iconColor: primaryColor,
                title: "Ekspor & Bagikan",
                subtitle: "Simpan ZIP / WhatsApp",
                isDark: isDark,
                cardBg: cardBg,
                borderColor: borderColor,
                secondaryTextColor: secondaryTextColor,
                isDisabled: false,
                onTap: () => _backupLocal(context),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // ── 3. Riwayat Cadangan di Cloud ─────────────────────────────────────
        if (isSynced) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "RIWAYAT CADANGAN DI DRIVE (${_backupHistory.length})",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                ),
              ),
              InkWell(
                onTap: _fetchHistory,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(
                    children: [
                      if (_isHistoryLoading)
                        const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2))
                      else
                        const Icon(Icons.refresh_rounded, size: 15, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text("Segarkan", style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_backupHistory.isEmpty && !_isHistoryLoading)
            _buildEmptyHistory(isDark)
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _backupHistory.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final file = _backupHistory[index];
                final dateStr = file.createdTime != null
                    ? DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(file.createdTime!.toLocal())
                    : '-';
                final sizeStr = file.size != null ? _formatFileSize(int.parse(file.size!)) : '-';

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.archive_outlined, color: Colors.blue, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              file.name ?? 'Cadangan',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "$dateStr • $sizeStr",
                              style: GoogleFonts.openSans(
                                fontSize: 11.5,
                                color: secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_vert_rounded, size: 18),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        onPressed: () => _showBackupOptions(context, file),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // TAB 2: PEMULIHAN (RESTORE)
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildRestoreTab(
    bool isDark,
    Color primaryColor,
    Color cardBg,
    Color borderColor,
    Color secondaryTextColor,
  ) {
    final bool isSynced = _currentUser != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Notice Alert Card ──────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: isDark ? 0.12 : 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Penting: Proses pemulihan akan menimpa database saat ini dengan data dari file cadangan. Pastikan file backup yang dipilih adalah yang benar.",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: isDark ? Colors.amber.shade200 : Colors.amber.shade900,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        Text(
          "PILIH SUMBER PEMULIHAN",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            color: isDark ? Colors.white60 : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 8),

        // ── Metode 1: Dari File Perangkat (.ZIP) ───────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 1.1),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.folder_open_rounded, color: Colors.orange, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "File .ZIP dari Perangkat",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      "Dari memori HP, WhatsApp, atau folder Downloads",
                      style: GoogleFonts.openSans(fontSize: 11.5, color: secondaryTextColor),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => _restoreLocal(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: Text(
                  "Pilih File",
                  style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // ── Metode 2: Dari Google Drive Cloud ──────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 1.1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.cloud_download_outlined, color: Colors.blue, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Dari Google Drive Cloud",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          isSynced
                              ? "Pilih cadangan langsung dari riwayat cloud"
                              : "Hubungkan Google Drive untuk memulihkan",
                          style: GoogleFonts.openSans(fontSize: 11.5, color: secondaryTextColor),
                        ),
                      ],
                    ),
                  ),
                  if (!isSynced)
                    ElevatedButton(
                      onPressed: _handleGdriveSync,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      child: Text(
                        "Hubungkan",
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ),
                ],
              ),

              if (!isSynced) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 36,
                  child: OutlinedButton.icon(
                    onPressed: _contactAdminWhatsApp,
                    icon: const Icon(Icons.chat_bubble_rounded, size: 14, color: Color(0xFF25D366)),
                    label: Text(
                      "Aktivasi via WhatsApp (083121782648)",
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 11.5,
                        color: const Color(0xFF25D366),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF25D366), width: 1.1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],

              if (isSynced) ...[
                const SizedBox(height: 14),
                Divider(height: 1, color: borderColor),
                const SizedBox(height: 12),

                if (_isHistoryLoading) ...[
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ] else if (_backupHistory.isEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: Text(
                        "Tidak ada file cadangan ditemukan di Google Drive.",
                        style: GoogleFonts.openSans(fontSize: 12, color: secondaryTextColor),
                      ),
                    ),
                  ),
                ] else ...[
                  Text(
                    "Pilih Cadangan Cloud untuk Dipulihkan:",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white70 : const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(
                    _backupHistory.length > 5 ? 5 : _backupHistory.length,
                    (index) {
                      final file = _backupHistory[index];
                      final dateStr = file.createdTime != null
                          ? DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(file.createdTime!.toLocal())
                          : '-';
                      final sizeStr = file.size != null ? _formatFileSize(int.parse(file.size!)) : '-';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.cloud_done_outlined, size: 18, color: Colors.blue),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    file.name ?? 'Cadangan',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700),
                                  ),
                                  Text(
                                    "$dateStr • $sizeStr",
                                    style: GoogleFonts.openSans(fontSize: 11, color: secondaryTextColor),
                                  ),
                                ],
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => _restoreSpecificBackup(context, file),
                              icon: const Icon(Icons.download_rounded, size: 14),
                              label: const Text("Pulihkan", style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.blue,
                                side: const BorderSide(color: Colors.blue),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isDark,
    required Color cardBg,
    required Color borderColor,
    required Color secondaryTextColor,
    required bool isDisabled,
    required VoidCallback? onTap,
  }) {
    return Opacity(
      opacity: isDisabled ? 0.45 : 1.0,
      child: Material(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: isDisabled ? null : onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor, width: 1.1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.openSans(
                    fontSize: 11,
                    color: secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyHistory(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.history_toggle_off_rounded,
            size: 36,
            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
          ),
          const SizedBox(height: 8),
          Text(
            "Belum ada riwayat cadangan di Google Drive",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  void _showBackupOptions(BuildContext context, drive.File file) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.download_rounded, color: Colors.blue),
                  title: Text(
                    "Pulihkan dari Cadangan Ini",
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13.5),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _restoreSpecificBackup(context, file);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                  title: Text(
                    "Hapus Cadangan dari Drive",
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13.5, color: Colors.red),
                  ),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (c) => KasirDialog(
                        title: "Hapus File Cadangan?",
                        message: "File cadangan '${file.name ?? 'ini'}' akan dihapus secara permanen dari Google Drive.",
                        primaryActionLabel: "HAPUS",
                        isDestructive: true,
                        onPrimaryAction: () => Navigator.pop(c, true),
                        secondaryActionLabel: "Batal",
                        onSecondaryAction: () => Navigator.pop(c, false),
                      ),
                    );
                    if (confirm == true && file.id != null) {
                      try {
                        await _driveService.deleteBackup(file.id!);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Cadangan berhasil dihapus"), backgroundColor: Colors.green),
                          );
                        }
                        _fetchHistory();
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Gagal menghapus: $e"), backgroundColor: Colors.red),
                          );
                        }
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _restoreSpecificBackup(BuildContext context, drive.File file) async {
    if (file.id == null) return;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => KasirDialog(
        title: "Konfirmasi Pemulihan",
        message: "Tindakan ini akan MENGGANTI SEMUA DATA yang ada dengan data dari '${file.name ?? 'cadangan'}'. Aplikasi akan otomatis dimuat ulang.",
        primaryActionLabel: "PULIHKAN",
        isDestructive: true,
        onPrimaryAction: () => Navigator.pop(c, true),
        secondaryActionLabel: "Batal",
        onSecondaryAction: () => Navigator.pop(c, false),
      ),
    );

    if (confirm != true) return;
    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final downloadedPath = await _driveService.downloadBackup(file.id!, file.name ?? 'pos_backup.zip');
      if (downloadedPath == null) throw "Gagal mengunduh file cadangan dari Google Drive";

      if (!context.mounted) return;
      final db = context.read<AppDatabase>();
      await BackupService(db).restoreFullBackup(downloadedPath);

      if (!context.mounted) return;
      if (Navigator.of(context).canPop()) Navigator.pop(context); // dismiss loading

      await _handleRestoreSuccess();
    } catch (e) {
      if (context.mounted) {
        if (Navigator.of(context).canPop()) Navigator.pop(context); // dismiss loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal pemulihan: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Implementation logic (copied from QuickMenuPage mostly)
  Future<void> _backupLocal(BuildContext context) async {
    final db = context.read<AppDatabase>();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sedang mencadangkan...")));
    try {
      await BackupService(db).createFullBackup(share: true);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal mencadangkan: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _backupToGdrive(BuildContext context) async {
    final db = context.read<AppDatabase>();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sedang mencadangkan...")));
    try {
      final zipPath = await BackupService(db).createFullBackup(share: false);
      if (zipPath == null) throw "Gagal membuat file cadangan lokal";
      
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mengunggah ke Google Drive...")));
      
      final filename = zipPath.split(RegExp(r'[/\\]')).last;
      await _driveService.uploadBackup(zipPath, filename);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Berhasil mencadangkan ke Google Drive!"), backgroundColor: Colors.green),
        );
        _fetchHistory();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal upload: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _restoreLocal(BuildContext context) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );
    if (result == null || result.files.single.path == null) return;
    final path = result.files.single.path!;

    if (!context.mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => KasirDialog(
        title: "Konfirmasi Pemulihan",
        message: "Tindakan ini akan MENGGANTI SEMUA DATA yang ada. Aplikasi akan otomatis MULAI ULANG setelah selesai.",
        primaryActionLabel: "PULIHKAN",
        isDestructive: true,
        onPrimaryAction: () => Navigator.pop(c, true),
        secondaryActionLabel: "Batal",
        onSecondaryAction: () => Navigator.pop(c, false),
      ),
    );

    if (confirm != true) return;
    if (!context.mounted) return;

    try {
      final db = context.read<AppDatabase>();
      await BackupService(db).restoreFullBackup(path);
      if (!context.mounted) return;
      await _handleRestoreSuccess();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal pemulihan: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }
}

