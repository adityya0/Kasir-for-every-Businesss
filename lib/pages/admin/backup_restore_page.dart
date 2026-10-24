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
  bool _showTutorial = false;

  @override
  void initState() {
    super.initState();
    _checkGdriveStatus();
    _autoBackup.addListener(_onAutoBackupStateChanged);
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
          _showTutorial = false;
        });
        _fetchHistory();
      } else {
        if (mounted) setState(() => _showTutorial = true);
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
        throw "Sinkronisasi dibatalkan atau gagal";
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal Sinkronisasi: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isGdriveLoading = false);
    }
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
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          "Pencadangan & Pemulihan",
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: widget.onBack,
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: _showTutorial && _currentUser == null
          ? _buildTutorialView(isDark, primaryColor)
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGdriveStatusCard(isDark, primaryColor),
                  const SizedBox(height: 24),
                  _buildAutoBackupCard(isDark, primaryColor),
                  const SizedBox(height: 24),
                  _buildSectionTitle("Pencadangan Manual", isDark),
                  _buildActionCard(
                    title: "Cadangkan ke Perangkat",
                    icon: Icons.share_rounded,
                    color: Colors.blue,
                    isDark: isDark,
                    onTap: () => _backupLocal(context),
                  ),
                  const SizedBox(height: 12),
                  _buildActionCard(
                    title: "Cadangkan ke Google Drive",
                    icon: Icons.cloud_upload_outlined,
                    color: Colors.green,
                    isDark: isDark,
                    onTap: _currentUser == null ? null : () => _backupToGdrive(context),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle("Pemulihan Data", isDark),
                  _buildActionCard(
                    title: "Pulihkan dari Perangkat",
                    icon: Icons.folder_open_rounded,
                    color: Colors.orange,
                    isDark: isDark,
                    onTap: () => _restoreLocal(context),
                  ),
                  const SizedBox(height: 12),
                  _buildActionCard(
                    title: "Pulihkan dari Google Drive",
                    icon: Icons.cloud_download_outlined,
                    color: Colors.purple,
                    isDark: isDark,
                    onTap: _currentUser == null ? null : () => _restoreFromGdrive(context),
                  ),
                  const SizedBox(height: 32),
                  _buildHistorySection(isDark),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildTutorialView(bool isDark, Color primaryColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.cloud_sync_rounded, size: 80, color: primaryColor),
          ),
          const SizedBox(height: 40),
          Text(
            "Amankan Data Anda ke Cloud",
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Hubungkan Google Drive untuk mencadangkan data penjualan, stok, dan laporan Anda secara otomatis dan aman.",
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              color: isDark ? Colors.white60 : Colors.black54,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 48),
          _buildTutorialItem(
            Icons.security_rounded,
            "Keamanan Data",
            "Data Anda tersimpan aman di akun Google pribadi Anda.",
            isDark,
          ),
          const SizedBox(height: 24),
          _buildTutorialItem(
            Icons.devices_rounded,
            "Sinkronisasi Perangkat",
            "Pulihkan data di perangkat baru kapan saja dengan mudah.",
            isDark,
          ),
          const SizedBox(height: 24),
          _buildTutorialItem(
            Icons.auto_awesome_rounded,
            "Gratis & Mudah",
            "Gunakan penyimpanan gratis Google Drive tanpa biaya tambahan.",
            isDark,
          ),
          const SizedBox(height: 60),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => setState(() => _showTutorial = false),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 0,
              ),
              child: Text(
                "Lanjutkan",
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTutorialItem(IconData icon, String title, String desc, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: Colors.blue, size: 24),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                desc,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHistorySection(bool isDark) {
    if (_currentUser == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle("Riwayat Pencadangan (Drive)", isDark),
            if (_isHistoryLoading)
              const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
            else
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 20),
                onPressed: _fetchHistory,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_backupHistory.isEmpty && !_isHistoryLoading)
          _buildEmptyHistory(isDark)
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _backupHistory.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final file = _backupHistory[index];
              final dateStr = file.createdTime != null 
                  ? DateFormat('dd MMM yyyy HH:mm', 'id_ID').format(file.createdTime!.toLocal())
                  : '-';
              
              // Size is in bytes, convert to human readable
              final sizeStr = file.size != null ? _formatFileSize(int.parse(file.size!)) : '-';

              return Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.indigo.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.description_outlined, color: Colors.indigo),
                  ),
                  title: Text(
                    file.name ?? 'Cadangan',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    "Tgl: $dateStr • Ukuran: $sizeStr",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.more_vert_rounded),
                    onPressed: () => _showBackupOptions(context, file),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildEmptyHistory(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200, style: BorderStyle.none),
      ),
      child: Column(
        children: [
          Icon(Icons.history_rounded, size: 48, color: isDark ? Colors.white10 : Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            "Belum ada riwayat cadangan",
            style: GoogleFonts.plusJakartaSans(
              color: isDark ? Colors.white30 : Colors.grey.shade400,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _showBackupOptions(BuildContext context, drive.File file) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Opsi Pencadangan",
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.cloud_download_outlined, color: Colors.blue),
              title: const Text("Pulihkan data ini"),
              onTap: () {
                Navigator.pop(context);
                _restoreSpecificBackup(context, file);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
              title: const Text("Hapus dari Drive"),
              onTap: () async {
                Navigator.pop(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => KasirDialog(
                    title: "Hapus Cadangan",
                    message: "Yakin ingin menghapus cadangan '${file.name}' dari Google Drive?",
                    primaryActionLabel: "Hapus",
                    isDestructive: true,
                    onPrimaryAction: () => Navigator.pop(ctx, true),
                    secondaryActionLabel: "Batal",
                    onSecondaryAction: () => Navigator.pop(ctx, false),
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
  }

  Future<void> _restoreSpecificBackup(BuildContext context, drive.File file) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => KasirDialog(
        title: "Konfirmasi Pemulihan",
        message: "Tindakan ini akan MENGGANTI SEMUA DATA yang ada. Ingin melanjutkan?",
        primaryActionLabel: "PULIHKAN",
        isDestructive: true,
        onPrimaryAction: () => Navigator.pop(context, true),
        secondaryActionLabel: "Batal",
        onSecondaryAction: () => Navigator.pop(context, false),
      ),
    );

    if (confirm != true) return;
    
    showDialog(
      context: context, 
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator())
    );
    
    try {
      final downloadedPath = await _driveService.downloadBackup(file.id!, file.name!);
      if (downloadedPath == null) {
        if (context.mounted) Navigator.pop(context);
        throw "Gagal mengunduh file cadangan";
      }
      
      if (!context.mounted) return;
      final db = context.read<AppDatabase>();
      await BackupService(db).restoreFullBackup(downloadedPath);
      
      if (!context.mounted) return;
      Navigator.pop(context); // close loading
      
      await _handleRestoreSuccess();
    } catch (e) {
      if (context.mounted) {
        if (Navigator.of(context).canPop()) Navigator.pop(context); 
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal pemulihan: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildGdriveStatusCard(bool isDark, Color primaryColor) {
    final bool isSynced = _currentUser != null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (isSynced ? Colors.green : Colors.grey).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSynced ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                  color: isSynced ? Colors.green : Colors.grey,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSynced ? "Terhubung ke Google Drive" : "Belum Terhubung",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isSynced 
                          ? _currentUser!.email 
                          : "Hubungkan untuk akses pencadangan cloud",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: _isGdriveLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
                    onPressed: isSynced 
                      ? null // Locked if already synced as requested
                      : _handleGdriveSync,
                    icon: Icon(isSynced ? Icons.lock_outline : Icons.link_rounded),
                    label: Text(isSynced ? "Akun Terhubung (Terkunci)" : "Hubungkan Akun"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: isSynced ? Colors.grey.shade400 : primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                  ),
          ),
          if (isSynced) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _handleGdriveLogout,
              icon: const Icon(Icons.logout_rounded, size: 18, color: Colors.red),
              label: const Text("Putuskan Koneksi", style: TextStyle(color: Colors.red)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAutoBackupCard(bool isDark, Color primaryColor) {
    final bool isSynced = _currentUser != null;
    final autoBackup = _autoBackup;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (autoBackup.isEnabled && isSynced ? Colors.teal : Colors.grey).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.alarm_on_rounded,
                  color: autoBackup.isEnabled && isSynced ? Colors.teal : Colors.grey,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Pencadangan Otomatis",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      autoBackup.isEnabled && isSynced
                          ? "Aktif setiap hari pkl ${autoBackup.backupTime.hour.toString().padLeft(2, '0')}:${autoBackup.backupTime.minute.toString().padLeft(2, '0')} WIB"
                          : "Cadangkan database otomatis terjadwal",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: autoBackup.isEnabled && isSynced,
                activeTrackColor: Colors.teal,
                onChanged: !isSynced
                    ? null
                    : (val) async {
                        await autoBackup.setEnabled(val);
                      },
              ),
            ],
          ),

          if (!isSynced) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Colors.amber, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Hubungkan Google Drive di atas untuk mengaktifkan pencadangan otomatis.",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: isDark ? Colors.amber.shade200 : Colors.amber.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (autoBackup.isEnabled) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Pilihan Jam Pencadangan
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
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Row(
                  children: [
                    Icon(Icons.schedule_rounded, size: 20, color: isDark ? Colors.white70 : Colors.black54),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Waktu Pencadangan Harian",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          Text(
                            "Ketuk untuk mengganti jam",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: isDark ? Colors.white54 : Colors.black45,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.teal.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "${autoBackup.backupTime.hour.toString().padLeft(2, '0')}:${autoBackup.backupTime.minute.toString().padLeft(2, '0')} WIB",
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.arrow_forward_ios_rounded, size: 14, color: isDark ? Colors.white30 : Colors.black26),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 6),

            // Opsi Hanya Wi-Fi
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              child: Row(
                children: [
                  Icon(Icons.wifi_rounded, size: 20, color: isDark ? Colors.white70 : Colors.black54),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Hanya Lewat Wi-Fi",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        Text(
                          "Mencegah penggunaan kuota seluler kasir",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: autoBackup.wifiOnly,
                    activeTrackColor: Colors.teal,
                    onChanged: (val) async {
                      await autoBackup.setWifiOnly(val);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Status Card / Last Run
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  if (autoBackup.isBackingUp) ...[
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Sedang memproses pencadangan...",
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ] else ...[
                    Icon(
                      autoBackup.lastBackupStatus != null && autoBackup.lastBackupStatus!.contains("Berhasil")
                          ? Icons.check_circle_rounded
                          : Icons.info_outline_rounded,
                      size: 16,
                      color: autoBackup.lastBackupStatus != null && autoBackup.lastBackupStatus!.contains("Berhasil")
                          ? Colors.green
                          : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        autoBackup.lastBackupStatus != null
                            ? "Status: ${autoBackup.lastBackupStatus}"
                            : "Status: Menunggu jadwal pkl ${autoBackup.backupTime.hour.toString().padLeft(2, '0')}:${autoBackup.backupTime.minute.toString().padLeft(2, '0')}",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Tombol Uji Coba Sekarang
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: autoBackup.isBackingUp
                    ? null
                    : () async {
                        final messenger = ScaffoldMessenger.of(context);
                        messenger.showSnackBar(
                          const SnackBar(content: Text("Memulai uji coba pencadangan...")),
                        );
                        final res = await autoBackup.checkAndRunBackup(force: true);
                        if (!mounted) return;
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(res.message),
                            backgroundColor: res.success ? Colors.green : Colors.red,
                          ),
                        );
                        if (res.success) {
                          _fetchHistory();
                        }
                      },
                icon: const Icon(Icons.play_circle_outline_rounded, size: 18),
                label: const Text("Uji Coba Pencadangan Sekarang"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.teal,
                  side: const BorderSide(color: Colors.teal),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white70 : Colors.black54,
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required bool isDark,
    required VoidCallback? onTap,
  }) {
    final bool isDisabled = onTap == null;
    return Opacity(
      opacity: isDisabled ? 0.5 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
        ),
        child: ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          title: Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),

          trailing: const Icon(Icons.chevron_right_rounded),
        ),
      ),
    );
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

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => KasirDialog(
        title: "Konfirmasi Pemulihan",
        message: "Tindakan ini akan MENGGANTI SEMUA DATA yang ada. Aplikasi akan otomatis MULAI ULANG setelah selesai.",
        primaryActionLabel: "PULIHKAN",
        isDestructive: true,
        onPrimaryAction: () => Navigator.pop(context, true),
        secondaryActionLabel: "Batal",
        onSecondaryAction: () => Navigator.pop(context, false),
      ),
    );

    if (confirm != true) return;

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

  Future<void> _restoreFromGdrive(BuildContext context) async {
     if (!context.mounted) return;
     showDialog(
      context: context, 
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator())
    );
    
    try {
      final files = await _driveService.listBackups();
      if (!context.mounted) return;
      Navigator.pop(context); // close loading
      
      if (files.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Tidak ada file cadangan ditemukan di Google Drive"))
          );
        }
        return;
      }
      
      final selectedFile = await showDialog<drive.File>(
        context: context,
        builder: (c) => KasirDialog(
          title: "Pilih Cadangan Google Drive",
          icon: Icons.cloud_download_outlined,
          content: Container(
            constraints: const BoxConstraints(maxHeight: 400),
            width: double.maxFinite,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: files.length,
              separatorBuilder: (ctx, idx) => Divider(
                height: 1, 
                color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
              ),
              itemBuilder: (ctx, idx) {
                final file = files[idx];
                final date = file.modifiedTime ?? file.createdTime;
                final dateStr = date != null 
                    ? DateFormat('EEEE, dd MMM yyyy • HH:mm', 'id_ID').format(date.toLocal())
                    : '-';
                
                return ListTile(
                  onTap: () => Navigator.pop(c, file),
                  title: Text(
                    file.name == 'pos_backup_latest.zip' ? 'Cadangan Terbaru (pos_backup_latest.zip)' : (file.name ?? 'Cadangan'), 
                    style: GoogleFonts.openSans(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  subtitle: Text(dateStr, style: GoogleFonts.openSans(fontSize: 12, color: Colors.grey)),
                  trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                );
              },
            ),
          ),
          primaryActionLabel: "Tutup",
          onPrimaryAction: () => Navigator.pop(c),
        ),
      );
      
      if (selectedFile == null) return;
      if (!context.mounted) return;
      
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => KasirDialog(
          title: "Konfirmasi Pemulihan",
          message: "Tindakan ini akan MENGGANTI SEMUA DATA yang ada.",
          primaryActionLabel: "PULIHKAN",
          isDestructive: true,
          onPrimaryAction: () => Navigator.pop(context, true),
          secondaryActionLabel: "Batal",
          onSecondaryAction: () => Navigator.pop(context, false),
        ),
      );

      if (confirm != true) return;
      
      if (!context.mounted) return;
      showDialog(
        context: context, 
        barrierDismissible: false,
        builder: (c) => const Center(child: CircularProgressIndicator())
      );
      
      final downloadedPath = await _driveService.downloadBackup(selectedFile.id!, selectedFile.name!);
      if (downloadedPath == null && context.mounted) {
        Navigator.pop(context);
        throw "Gagal mengunduh file cadangan";
      }
      
      if (!context.mounted) return;
      final db = context.read<AppDatabase>();
      await BackupService(db).restoreFullBackup(downloadedPath!);
      
      if (!context.mounted) return;
      Navigator.pop(context); // close loading
      
      await _handleRestoreSuccess();
    } catch (e) {
      if (context.mounted) {
        if (Navigator.of(context).canPop()) Navigator.pop(context); 
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal pemulihan: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }
}

