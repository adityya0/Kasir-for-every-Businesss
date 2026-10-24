import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../controllers/admin_controller.dart';
import '../../../services/activation_service.dart';
import '../../../services/app_database.dart';
import '../../../services/super_admin_service.dart';
import '../../../widgets/kasir_dialog.dart';

class SuperAdminPage extends StatefulWidget {
  final bool isStandalone;
  final VoidCallback? onBack;

  const SuperAdminPage({
    super.key,
    this.isStandalone = true,
    this.onBack,
  });

  @override
  State<SuperAdminPage> createState() => _SuperAdminPageState();
}

class _SuperAdminPageState extends State<SuperAdminPage> {
  late SuperAdminService _superAdminService;
  bool _isLoading = true;
  List<Map<String, dynamic>> _accounts = [];
  Map<String, int> _stats = {};
  String _searchQuery = '';
  String _selectedRoleFilter = 'all'; // 'all', 'super_admin', 'admin', 'staff'
  final Map<String, bool> _visiblePasswords = {};

  final currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final db = Provider.of<AppDatabase>(context);
    _superAdminService = SuperAdminService(db);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      await _superAdminService.ensureSuperAdminExists();
      final accounts = await _superAdminService.getAllAccountsWithStats();
      final stats = await _superAdminService.getSystemSummary();
      if (mounted) {
        setState(() {
          _accounts = accounts;
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading SuperAdmin data: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal memuat data akun: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredAccounts {
    return _accounts.where((acc) {
      final Profile p = acc['profile'] as Profile;
      final String storeName = (acc['storeName'] as String?)?.toLowerCase() ?? '';
      final String fullName = (p.fullName ?? '').toLowerCase();
      final String email = (p.email ?? '').toLowerCase();
      final String query = _searchQuery.toLowerCase();

      final matchesSearch = fullName.contains(query) || email.contains(query) || storeName.contains(query);

      if (!matchesSearch) return false;

      if (_selectedRoleFilter == 'super_admin') {
        return p.role == SuperAdminService.roleSuperAdmin || p.id == SuperAdminService.superAdminId;
      } else if (_selectedRoleFilter == 'admin') {
        return p.role == 'admin' || p.role == 'owner';
      } else if (_selectedRoleFilter == 'staff') {
        return p.role != SuperAdminService.roleSuperAdmin &&
            p.id != SuperAdminService.superAdminId &&
            p.role != 'admin' &&
            p.role != 'owner';
      }
      return true;
    }).toList();
  }

  // --- LOGOUT SUPER ADMIN ---
  Future<void> _handleLogout() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => KasirDialog(
        title: "Keluar dari Super Admin?",
        message: "Anda akan keluar dari sesi Super Admin dan kembali ke layar login.",
        icon: Icons.logout_rounded,
        iconColor: const Color(0xFFC0392B),
        primaryActionLabel: "Keluar",
        onPrimaryAction: () => Navigator.pop(ctx, true),
        secondaryActionLabel: "Batal",
        onSecondaryAction: () => Navigator.pop(ctx, false),
      ),
    );

    if (confirm != true) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_route');
    await prefs.remove('current_user_id');

    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  // --- DIALOG TAMBAH AKUN BARU ---
  // --- DIALOG TAMBAH AKUN BARU ---
  void _showCreateAccountDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    bool obscure = true;

    // Deteksi Admin Toko Utama aktif di sistem offline
    Map<String, dynamic>? activeAdminItem;
    for (final acc in _accounts) {
      final p = acc['profile'] as Profile;
      if ((p.role == 'admin' || p.role == 'owner') && p.role != SuperAdminService.roleSuperAdmin) {
        activeAdminItem = acc;
        break;
      }
    }
    final bool hasAdmin = activeAdminItem != null;
    final Profile? activeAdminProfile = activeAdminItem != null ? activeAdminItem['profile'] as Profile : null;
    final String activeStoreName = activeAdminItem != null ? (activeAdminItem['storeName'] as String? ?? 'Toko POS') : 'Toko POS';
    String selectedRole = hasAdmin ? 'cashier' : 'admin';

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogContentCtx, setDialogState) {
          return KasirDialog(
            title: "Tambah Akun Pengguna Baru",
            message: hasAdmin
                ? "Tambah Akun Kasir / Karyawan (Terafiliasi Otomatis ke Toko)"
                : "Daftarkan Akun Admin Utama Toko",
            icon: Icons.person_add_outlined,
            iconColor: const Color(0xFF4F46E5),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Info Banner Afiliasi Offline
                  if (hasAdmin)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.storefront_rounded, color: Color(0xFF16A34A), size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Admin Toko sudah aktif (${activeAdminProfile?.fullName ?? activeAdminProfile?.email}).\nAkun baru otomatis terafiliasi ke toko: $activeStoreName",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: const Color(0xFF15803D),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFED7AA)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFFEA580C), size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Belum ada Admin Toko terdaftar. Buat akun Admin Utama terlebih dahulu.",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: const Color(0xFF9A3412),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  Text("Nama Lengkap", style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 5),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      hintText: hasAdmin ? "Contoh: Kasir Pagi / Budi" : "Contoh: Pemilik Toko",
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Text("Username / Email Login", style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 5),
                  TextField(
                    controller: emailCtrl,
                    decoration: InputDecoration(
                      hintText: "Contoh: budi atau kasir1",
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Text("Peran Akun", style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedRole,
                        isExpanded: true,
                        items: hasAdmin
                            ? const [
                                DropdownMenuItem(
                                  value: 'cashier',
                                  child: Text("Kasir / Akun Karyawan Toko (Terafiliasi)"),
                                ),
                              ]
                            : const [
                                DropdownMenuItem(
                                  value: 'admin',
                                  child: Text("Admin Toko (Akses Kelola Toko Utama)"),
                                ),
                              ],
                        onChanged: (val) {
                          if (val != null) setDialogState(() => selectedRole = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Text("Kata Sandi", style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 5),
                  TextField(
                    controller: passCtrl,
                    obscureText: obscure,
                    decoration: InputDecoration(
                      hintText: "Minimal 4 karakter",
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      suffixIcon: IconButton(
                        icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                        onPressed: () => setDialogState(() => obscure = !obscure),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
            primaryActionLabel: "Buat Akun",
            onPrimaryAction: () async {
              final name = nameCtrl.text.trim();
              final email = emailCtrl.text.trim();
              final pass = passCtrl.text.trim();

              if (name.isEmpty || email.isEmpty || pass.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Harap isi semua kolom pendaftaran.")),
                );
                return;
              }
              if (pass.length < 4) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Kata sandi minimal 4 karakter.")),
                );
                return;
              }

              Navigator.pop(dialogCtx);
              try {
                await _superAdminService.createAccount(
                  fullName: name,
                  email: email,
                  password: pass,
                  role: selectedRole,
                  storeId: activeAdminProfile?.storeId,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Akun $name berhasil dibuat!"),
                      backgroundColor: const Color(0xFF16A34A),
                    ),
                  );
                  _loadData();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Gagal membuat akun: $e"), backgroundColor: Colors.red),
                  );
                }
              }
            },
            secondaryActionLabel: "Batal",
            onSecondaryAction: () => Navigator.pop(dialogCtx),
          );
        },
      ),
    );
  }

  // --- DIALOG EDIT AKUN ---
  void _showEditAccountDialog(Profile profile) {
    final nameCtrl = TextEditingController(text: profile.fullName ?? '');
    final emailCtrl = TextEditingController(text: profile.email ?? '');
    String selectedRole = profile.role;
    if (selectedRole != 'admin' && selectedRole != 'owner' && selectedRole != 'cashier' && selectedRole != 'staff' && selectedRole != SuperAdminService.roleSuperAdmin) {
      selectedRole = 'cashier';
    }
    final bool isSuper = _superAdminService.isProtectedAccount(profile);

    // Cek apakah ada Admin Toko lain selain akun ini
    final bool otherAdminExists = _accounts.any((a) {
      final p = a['profile'] as Profile;
      return (p.role == 'admin' || p.role == 'owner') && p.id != profile.id && p.role != SuperAdminService.roleSuperAdmin;
    });

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogContentCtx, setDialogState) {
          return KasirDialog(
            title: "Ubah Data Akun",
            message: "Perbarui identitas dan peran akun pengguna.",
            icon: Icons.edit_outlined,
            iconColor: const Color(0xFF4F46E5),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10),
                  Text("Nama Lengkap", style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 5),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text("Username / Email", style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 5),
                  TextField(
                    controller: emailCtrl,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text("Peran Akun", style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: isSuper
                            ? SuperAdminService.roleSuperAdmin
                            : (selectedRole == 'admin' || selectedRole == 'owner' ? 'admin' : 'cashier'),
                        isExpanded: true,
                        items: isSuper
                            ? const [
                                DropdownMenuItem(
                                  value: SuperAdminService.roleSuperAdmin,
                                  child: Text("Super Administrator (Master)"),
                                )
                              ]
                            : [
                                if (!otherAdminExists || (profile.role == 'admin' || profile.role == 'owner'))
                                  const DropdownMenuItem(
                                    value: 'admin',
                                    child: Text("Admin Toko"),
                                  ),
                                const DropdownMenuItem(
                                  value: 'cashier',
                                  child: Text("Kasir / Karyawan"),
                                ),
                              ],
                        onChanged: isSuper || (otherAdminExists && profile.role != 'admin' && profile.role != 'owner')
                            ? null
                            : (val) {
                                if (val != null) setDialogState(() => selectedRole = val);
                              },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            primaryActionLabel: "Simpan Perubahan",
            onPrimaryAction: () async {
              final name = nameCtrl.text.trim();
              final email = emailCtrl.text.trim();

              if (name.isEmpty || email.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Nama dan Email tidak boleh kosong.")),
                );
                return;
              }

              Navigator.pop(dialogCtx);
              try {
                await _superAdminService.updateAccount(
                  userId: profile.id,
                  fullName: name,
                  email: email,
                  role: isSuper ? SuperAdminService.roleSuperAdmin : selectedRole,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Data akun berhasil diperbarui!"),
                      backgroundColor: Color(0xFF16A34A),
                    ),
                  );
                  _loadData();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Gagal memperbarui: $e"), backgroundColor: Colors.red),
                  );
                }
              }
            },
            secondaryActionLabel: "Batal",
            onSecondaryAction: () => Navigator.pop(dialogCtx),
          );
        },
      ),
    );
  }

  // --- DIALOG HAPUS AKUN ---
  void _confirmDeleteAccount(Profile profile) {
    if (_superAdminService.isProtectedAccount(profile)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Akun Super Admin permanen dilindungi dan tidak dapat dihapus!"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogCtx) => KasirDialog(
        title: "Hapus Akun Pengguna?",
        message: "Apakah Anda yakin ingin menghapus akun ${profile.fullName ?? profile.email}?\n\nRiwayat transaksi toko yang pernah diproses akun ini tetap aman tersimpan.",
        icon: Icons.delete_outline_rounded,
        iconColor: const Color(0xFFDC2626),
        isDestructive: true,
        primaryActionLabel: "Ya, Hapus Akun",
        onPrimaryAction: () async {
          Navigator.pop(dialogCtx);
          try {
            await _superAdminService.deleteAccount(profile.id);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Akun ${profile.fullName ?? profile.email} berhasil dihapus."),
                  backgroundColor: const Color(0xFF16A34A),
                ),
              );
              _loadData();
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Gagal menghapus akun: $e"), backgroundColor: Colors.red),
              );
            }
          }
        },
        secondaryActionLabel: "Batal",
        onSecondaryAction: () => Navigator.pop(dialogCtx),
      ),
    );
  }

  // --- DIALOG RESET PASSWORD ---
  void _showResetPasswordDialog(Profile profile) {
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    bool obscureNew = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogContentCtx, setDialogState) {
          return KasirDialog(
            title: "Reset Kata Sandi Akun",
            message: "Atur ulang password untuk akun ${profile.fullName ?? profile.email ?? 'Pengguna'}.",
            icon: Icons.lock_reset_rounded,
            iconColor: const Color(0xFFDC2626),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Text(
                  "Password Baru",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: newPassCtrl,
                  obscureText: obscureNew,
                  decoration: InputDecoration(
                    hintText: "Masukkan kata sandi baru (min. 4 karakter)",
                    hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.grey[400]),
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 20,
                        color: Colors.grey[600],
                      ),
                      onPressed: () => setDialogState(() => obscureNew = !obscureNew),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  "Ulangi Password Baru",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: confirmPassCtrl,
                  obscureText: obscureConfirm,
                  decoration: InputDecoration(
                    hintText: "Ulangi kata sandi baru",
                    hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.grey[400]),
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 20,
                        color: Colors.grey[600],
                      ),
                      onPressed: () => setDialogState(() => obscureConfirm = !obscureConfirm),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ],
            ),
            primaryActionLabel: "Simpan & Reset",
            onPrimaryAction: () async {
              final newPass = newPassCtrl.text.trim();
              final confirmPass = confirmPassCtrl.text.trim();

              if (newPass.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Kata sandi baru tidak boleh kosong.")),
                );
                return;
              }
              if (newPass.length < 4) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Kata sandi minimal 4 karakter.")),
                );
                return;
              }
              if (newPass != confirmPass) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Konfirmasi kata sandi tidak cocok.")),
                );
                return;
              }

              Navigator.pop(dialogCtx);
              try {
                await _superAdminService.resetPassword(
                  userId: profile.id,
                  newPassword: newPass,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Password untuk ${profile.fullName ?? profile.email} berhasil direset!",
                              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: const Color(0xFF16A34A),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  _loadData();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Gagal mereset kata sandi: $e"), backgroundColor: Colors.red),
                  );
                }
              }
            },
            secondaryActionLabel: "Batal",
            onSecondaryAction: () => Navigator.pop(dialogCtx),
          );
        },
      ),
    );
  }

  // --- DIALOG GANTI PASSWORD MASTER SUPER ADMIN ---
  void _showChangeMasterPasswordDialog() {
    final newPassCtrl = TextEditingController();
    bool obscure = true;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogContentCtx, setDialogState) {
          return KasirDialog(
            title: "Ubah Password Master",
            message: "Ganti password master Super Admin. Catat dan simpan password baru ini dengan baik.",
            icon: Icons.key_outlined,
            iconColor: const Color(0xFF4F46E5),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Text(
                  "Password Master Baru",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: newPassCtrl,
                  obscureText: obscure,
                  decoration: InputDecoration(
                    hintText: "Masukkan password master baru",
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 20,
                        color: Colors.grey[600],
                      ),
                      onPressed: () => setDialogState(() => obscure = !obscure),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ],
            ),
            primaryActionLabel: "Perbarui Master Password",
            onPrimaryAction: () async {
              final pass = newPassCtrl.text.trim();
              if (pass.length < 4) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Password minimal 4 karakter.")),
                );
                return;
              }
              Navigator.pop(dialogCtx);
              try {
                await _superAdminService.updateSuperAdminPassword(pass);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Password Master Super Admin berhasil diperbarui!"),
                      backgroundColor: Color(0xFF16A34A),
                    ),
                  );
                  _loadData();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Gagal memperbarui: $e"), backgroundColor: Colors.red),
                  );
                }
              }
            },
            secondaryActionLabel: "Batal",
            onSecondaryAction: () => Navigator.pop(dialogCtx),
          );
        },
      ),
    );
  }

  // --- MASUK LANGSUNG SEBAGAI AKUN INI (IMPERSONATE) ---
  Future<void> _loginAsAccount(Profile profile) async {
    final bool isCurrentUser = Provider.of<AdminController>(context, listen: false).userId == profile.id;
    if (isCurrentUser) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Anda sudah berada di sesi akun ini.")),
      );
      return;
    }

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => KasirDialog(
        title: "Beralih ke Akun Ini?",
        message: "Anda akan masuk langsung sebagai ${profile.fullName ?? profile.email} (${profile.role}).",
        icon: Icons.login_rounded,
        iconColor: const Color(0xFF4F46E5),
        primaryActionLabel: "Ya, Masuk Sekarang",
        onPrimaryAction: () => Navigator.pop(ctx, true),
        secondaryActionLabel: "Batal",
        onSecondaryAction: () => Navigator.pop(ctx, false),
      ),
    );

    if (confirm != true) return;

    try {
      final actService = ActivationService();
      await actService.activateLocally(
        profile.email ?? profile.fullName ?? 'User',
        displayName: profile.fullName,
      );

      if (!mounted) return;
      final adminCtrl = Provider.of<AdminController>(context, listen: false);
      await adminCtrl.loadInitialData(userId: profile.id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Berhasil beralih ke akun ${profile.fullName ?? profile.email}!"),
          backgroundColor: const Color(0xFF16A34A),
        ),
      );

      if (profile.role == 'admin' || profile.role == 'owner') {
        Navigator.pushNamedAndRemoveUntil(context, '/admin', (route) => false);
      } else {
        Navigator.pushNamedAndRemoveUntil(context, '/kasir', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal beralih akun: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            _buildTopBar(isDark, cardBg, borderColor),

            // Body
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      color: const Color(0xFF4F46E5),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // KPI Cards Row
                            _buildKpiSummary(isDark, cardBg, borderColor),
                            const SizedBox(height: 16),

                            // Search & Filter Row Sejajar
                            _buildFilterBar(isDark, cardBg, borderColor),
                            const SizedBox(height: 16),

                            // List of Accounts
                            _buildAccountList(isDark, cardBg, borderColor),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // --- TOP BAR ---
  Widget _buildTopBar(bool isDark, Color cardBg, Color borderColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          if (!widget.isStandalone && (widget.onBack != null || Navigator.canPop(context)))
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded, size: 20),
              onPressed: () {
                if (widget.onBack != null) {
                  widget.onBack!();
                } else {
                  Navigator.pop(context);
                }
              },
              tooltip: "Kembali",
            ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFC7D2FE)),
            ),
            child: const Icon(Icons.shield_outlined, color: Color(0xFF4F46E5), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      "Super Admin Console",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: Text(
                        "PERMANEN",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF059669),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  "Manajemen kredensial, hak akses, dan pemulihan seluruh akun",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),

          // Action: Tambah Akun Baru
          ElevatedButton.icon(
            onPressed: _showCreateAccountDialog,
            icon: const Icon(Icons.person_add_outlined, size: 16),
            label: Text(
              "Tambah Akun",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
          const SizedBox(width: 8),

          // Action: Ganti Password Master
          OutlinedButton.icon(
            onPressed: _showChangeMasterPasswordDialog,
            icon: const Icon(Icons.key_outlined, size: 16, color: Color(0xFF4F46E5)),
            label: Text(
              "Sandi Master",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF4F46E5),
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(width: 8),

          // Action: Refresh
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20, color: Color(0xFF64748B)),
            onPressed: _loadData,
            tooltip: "Muat Ulang Data",
          ),
          const SizedBox(width: 2),

          // Action: Logout
          IconButton(
            icon: const Icon(Icons.logout_rounded, size: 20, color: Color(0xFFDC2626)),
            onPressed: _handleLogout,
            tooltip: "Keluar dari Super Admin",
          ),
        ],
      ),
    );
  }

  // --- KPI SUMMARY ---
  Widget _buildKpiSummary(bool isDark, Color cardBg, Color borderColor) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 650;
        final count = _stats['totalProfiles'] ?? 0;
        final admins = _stats['admins'] ?? 0;
        final staff = _stats['staff'] ?? 0;
        final stores = _stats['totalStores'] ?? 0;

        final items = [
          _buildKpiCard("Total Akun", "$count Akun", Icons.groups_outlined, const Color(0xFF4F46E5), isDark, cardBg, borderColor),
          _buildKpiCard("Admin Toko", "$admins Akun", Icons.store_outlined, const Color(0xFFEA580C), isDark, cardBg, borderColor),
          _buildKpiCard("Karyawan / Kasir", "$staff Staf", Icons.badge_outlined, const Color(0xFF0D9488), isDark, cardBg, borderColor),
          _buildKpiCard("Toko Terdaftar", "$stores Toko", Icons.apartment_outlined, const Color(0xFF2563EB), isDark, cardBg, borderColor),
        ];

        if (isSmall) {
          return GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.3,
            children: items,
          );
        }

        return Row(
          children: items.map((w) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 5), child: w))).toList(),
        );
      },
    );
  }

  Widget _buildKpiCard(
    String title,
    String value,
    IconData icon,
    Color color,
    bool isDark,
    Color cardBg,
    Color borderColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
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
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- FILTER & SEARCH BAR SEJAJAR ---
  Widget _buildFilterBar(bool isDark, Color cardBg, Color borderColor) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 800;

        final searchInput = SizedBox(
          height: 42,
          child: TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            style: GoogleFonts.plusJakartaSans(fontSize: 13),
            decoration: InputDecoration(
              hintText: "Cari nama, email, username, atau toko...",
              hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF94A3B8)),
              prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF64748B)),
              filled: true,
              fillColor: isDark ? const Color(0xFF0F172A) : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
            ),
          ),
        );

        final filterChips = SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildRoleFilterChip("Semua (${_accounts.length})", 'all'),
              const SizedBox(width: 6),
              _buildRoleFilterChip("Super Admin", 'super_admin'),
              const SizedBox(width: 6),
              _buildRoleFilterChip("Admin Toko", 'admin'),
              const SizedBox(width: 6),
              _buildRoleFilterChip("Karyawan", 'staff'),
            ],
          ),
        );

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              searchInput,
              const SizedBox(height: 10),
              filterChips,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: searchInput),
            const SizedBox(width: 14),
            filterChips,
          ],
        );
      },
    );
  }

  Widget _buildRoleFilterChip(String label, String value) {
    final isSelected = _selectedRoleFilter == value;
    return InkWell(
      onTap: () => setState(() => _selectedRoleFilter = value),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4F46E5) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFCBD5E1),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  // --- ACCOUNT LIST ---
  Widget _buildAccountList(bool isDark, Color cardBg, Color borderColor) {
    final list = _filteredAccounts;

    if (list.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          children: [
            Icon(Icons.person_search_outlined, size: 40, color: Colors.grey[400]),
            const SizedBox(height: 10),
            Text(
              "Tidak ada akun yang sesuai kriteria pencarian",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = list[index];
        final Profile p = item['profile'] as Profile;
        final String storeName = item['storeName'] as String;
        final int txCount = item['transactionCount'] as int;
        final double totalSales = item['totalSales'] as double;
        final bool isSuperAdmin = item['isSuperAdmin'] as bool;
        final String? adminName = item['adminName'] as String?;
        final bool isPassVisible = _visiblePasswords[p.id] ?? false;

        return _buildAccountCard(
          p: p,
          storeName: storeName,
          adminName: adminName,
          txCount: txCount,
          totalSales: totalSales,
          isSuperAdmin: isSuperAdmin,
          isPassVisible: isPassVisible,
          isDark: isDark,
          cardBg: cardBg,
          borderColor: borderColor,
        );
      },
    );
  }

  // --- SINGLE ACCOUNT CARD ---
  Widget _buildAccountCard({
    required Profile p,
    required String storeName,
    String? adminName,
    required int txCount,
    required double totalSales,
    required bool isSuperAdmin,
    required bool isPassVisible,
    required bool isDark,
    required Color cardBg,
    required Color borderColor,
  }) {
    Color badgeColor;
    String roleLabel;
    IconData roleIcon;

    if (isSuperAdmin) {
      badgeColor = const Color(0xFF4F46E5);
      roleLabel = "SUPER ADMIN";
      roleIcon = Icons.shield_outlined;
    } else if (p.role == 'admin' || p.role == 'owner') {
      badgeColor = const Color(0xFFEA580C);
      roleLabel = "ADMIN TOKO";
      roleIcon = Icons.store_outlined;
    } else {
      badgeColor = const Color(0xFF0D9488);
      roleLabel = p.role == 'cashier' ? "KASIR" : "STAF";
      roleIcon = Icons.badge_outlined;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSuperAdmin ? const Color(0xFFC7D2FE) : borderColor,
          width: isSuperAdmin ? 1.4 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Avatar, Name, Role Badge, Meta
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(roleIcon, color: badgeColor, size: 20),
              ),
              const SizedBox(width: 12),

              // Name & Credential Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            p.fullName ?? p.email ?? "Pengguna",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: badgeColor.withValues(alpha: 0.25)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(roleIcon, size: 11, color: badgeColor),
                              const SizedBox(width: 4),
                              Text(
                                roleLabel,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: badgeColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),

                    // Username / Email & Store
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.alternate_email_rounded, size: 13, color: Color(0xFF64748B)),
                            const SizedBox(width: 4),
                            Text(
                              p.email ?? 'Tidak ada email',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.storefront_outlined, size: 13, color: Color(0xFF64748B)),
                            const SizedBox(width: 4),
                            Text(
                              storeName,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                        if (txCount > 0)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.receipt_outlined, size: 13, color: Color(0xFF059669)),
                              const SizedBox(width: 4),
                              Text(
                                "$txCount Transaksi (${currencyFormat.format(totalSales)})",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF059669),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),

                    // Badge Afiliasi Toko untuk Kasir / Karyawan
                    if (!isSuperAdmin && p.role != 'admin' && p.role != 'owner') ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.link_rounded, size: 12, color: Color(0xFF16A34A)),
                            const SizedBox(width: 4),
                            Text(
                              "Terafiliasi: $storeName${adminName != null ? ' (Admin: $adminName)' : ''}",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF15803D),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else if (p.role == 'admin' || p.role == 'owner') ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFFED7AA)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.stars_rounded, size: 12, color: Color(0xFFEA580C)),
                            const SizedBox(width: 4),
                            Text(
                              "Admin Tunggal Toko (Menaungi Seluruh Karyawan & Kasir)",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFC2410C),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 10),

          // Bottom Section: Password Viewer & Action Buttons
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Password Display with Eye Toggle
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_outline_rounded, size: 13, color: Color(0xFF64748B)),
                    const SizedBox(width: 6),
                    Text(
                      "Sandi: ",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    Text(
                      isPassVisible ? (p.password ?? "(Kosong)") : "••••••••",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                        letterSpacing: isPassVisible ? 0 : 2,
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () {
                        setState(() {
                          _visiblePasswords[p.id] = !isPassVisible;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: Icon(
                          isPassVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          size: 15,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () {
                        if (p.password != null) {
                          Clipboard.setData(ClipboardData(text: p.password!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Kata sandi disalin ke clipboard!"),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        }
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(2),
                        child: Icon(Icons.copy_rounded, size: 13, color: Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ),
              ),

              // Button: Reset Password
              OutlinedButton.icon(
                onPressed: () => _showResetPasswordDialog(p),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFDC2626),
                  side: const BorderSide(color: Color(0xFFDC2626)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
                icon: const Icon(Icons.lock_reset_rounded, size: 14),
                label: Text(
                  "Reset Sandi",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              // Button: Edit Akun
              OutlinedButton.icon(
                onPressed: () => _showEditAccountDialog(p),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF4F46E5),
                  side: const BorderSide(color: Color(0xFF4F46E5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
                icon: const Icon(Icons.edit_outlined, size: 14),
                label: Text(
                  "Edit",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              // Button: Hapus Akun (Hanya jika bukan super admin)
              if (!isSuperAdmin)
                IconButton(
                  onPressed: () => _confirmDeleteAccount(p),
                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFDC2626)),
                  tooltip: "Hapus Akun",
                ),

              // Button: Impersonate / Masuk Sebagai Akun Ini
              if (!isSuperAdmin)
                ElevatedButton.icon(
                  onPressed: () => _loginAsAccount(p),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                  icon: const Icon(Icons.login_rounded, size: 14),
                  label: Text(
                    "Masuk Cepat",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
