import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:uuid/uuid.dart';
import '../../services/app_database.dart';

import 'package:provider/provider.dart';
import '../../controllers/admin_controller.dart';
import '../../services/activation_service.dart';
import '../../widgets/kasir_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

const colorbase = Color(0xFFC0392B);

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  late AppDatabase _db;
  bool _isLoading = false;
  bool _isRegisterMode = false; // false = Login, true = Register

  // Form Controllers
  final _loginUsernameController = TextEditingController();
  final _loginPasswordController = TextEditingController();

  final _regFullNameController = TextEditingController();
  final _regUsernameController = TextEditingController();
  final _regPasswordController = TextEditingController();
  final _regConfirmPasswordController = TextEditingController();
  String _selectedRole = 'admin';

  // Obscure password toggles
  bool _obscureLoginPass = true;
  bool _obscureRegPass = true;
  bool _obscureRegConfirmPass = true;

  // Status Admin Offline & Afiliasi Toko
  Profile? _existingAdmin;
  Store? _existingStore;

  final ActivationService _activationService = ActivationService();
  
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.65, curve: Curves.easeOutQuint),
    ));

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _loginUsernameController.dispose();
    _loginPasswordController.dispose();
    _regFullNameController.dispose();
    _regUsernameController.dispose();
    _regPasswordController.dispose();
    _regConfirmPasswordController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _db = Provider.of<AppDatabase>(context);
    _checkOfflineAdminStatus();
  }

  /// Memeriksa apakah Admin Toko sudah terdaftar di sistem offline ini
  Future<void> _checkOfflineAdminStatus() async {
    try {
      final admin = await (_db.select(_db.profiles)
            ..where((t) => t.role.equals('admin') | t.role.equals('owner'))
            ..limit(1))
          .getSingleOrNull();
      Store? store;
      if (admin != null && admin.storeId != null) {
        store = await (_db.select(_db.stores)..where((t) => t.id.equals(admin.storeId!))).getSingleOrNull();
      }
      if (mounted) {
        setState(() {
          _existingAdmin = admin;
          _existingStore = store;
          _selectedRole = 'admin';
        });
      }
    } catch (e) {
      debugPrint("Error checking offline admin status: $e");
    }
  }

  // --- MANUAL LOGIN ---
  Future<void> _handleManualLogin() async {
    final usernameOrEmail = _loginUsernameController.text.trim();
    final password = _loginPasswordController.text;

    if (usernameOrEmail.isEmpty || password.isEmpty) {
      _showSnackbar("Harap isi Username/Email dan Password.");
      return;
    }

    setState(() => _isLoading = true);
    try {
      final profiles = await (_db.select(_db.profiles)
            ..where((t) {
              final List<Expression<bool>> matchExprs = [
                t.email.equals(usernameOrEmail),
                t.fullName.equals(usernameOrEmail),
              ];
              return Expression.or(matchExprs);
            }))
          .get();

      if (profiles.isEmpty) {
        _showError("Akun tidak ditemukan. Silakan periksa kembali atau gunakan bantuan Pemulihan Akun.");
        return;
      }

      final profile = profiles.first;
      if (profile.password != password) {
        _showError("Password yang Anda masukkan salah.");
        return;
      }

      // Successful manual login
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_user_id', profile.id);
      await _activationService.activateLocally(
        profile.email ?? profile.fullName ?? usernameOrEmail,
        displayName: profile.fullName,
      );

      if (!mounted) return;
      final adminCtrl = Provider.of<AdminController>(context, listen: false);
      await adminCtrl.loadInitialData(userId: profile.id);

      if (!mounted) return;
      _showSuccessDialog("Berhasil Masuk!", "Selamat datang kembali,\n${profile.fullName ?? usernameOrEmail}");

      await Future.delayed(const Duration(milliseconds: 1300));
      if (!mounted) return;
      Navigator.pop(context); // Close dialog

      Navigator.pushReplacementNamed(context, '/admin');
    } catch (e) {
      debugPrint("Manual Login Error: $e");
      _showError("Terjadi kesalahan sistem: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- MANUAL REGISTER ---
  Future<void> _handleManualRegister() async {
    final fullName = _regFullNameController.text.trim();
    final emailOrUsername = _regUsernameController.text.trim();
    final password = _regPasswordController.text;
    final confirmPassword = _regConfirmPasswordController.text;

    if (fullName.isEmpty || emailOrUsername.isEmpty || password.isEmpty) {
      _showSnackbar("Harap isi semua kolom pendaftaran.");
      return;
    }

    if (password.length < 4) {
      _showSnackbar("Password minimal 4 karakter.");
      return;
    }

    if (password != confirmPassword) {
      _showSnackbar("Konfirmasi password tidak cocok.");
      return;
    }

    setState(() => _isLoading = true);
    try {
      final existing = await (_db.select(_db.profiles)
            ..where((t) => Expression.or([t.email.equals(emailOrUsername), t.fullName.equals(fullName)])))
          .get();

      if (existing.isNotEmpty) {
        _showError("Email / Username sudah terdaftar. Silakan pindah ke tab Masuk.");
        return;
      }

      final userId = const Uuid().v4();
      String effectiveStoreId;

      final existingStores = await (_db.select(_db.stores)..limit(1)).get();
      if (existingStores.isNotEmpty) {
        effectiveStoreId = existingStores.first.id;
      } else {
        // Ini adalah Admin Toko Pertama, buat Toko Baru
        effectiveStoreId = 'store_${DateTime.now().millisecondsSinceEpoch}';
        await _db.into(_db.stores).insert(
          StoresCompanion.insert(
            id: effectiveStoreId,
            name: Value('Toko $fullName'),
            adminName: Value(fullName),
            createdAt: Value(DateTime.now()),
          ),
        );
      }

      await _db.into(_db.profiles).insert(
        ProfilesCompanion.insert(
          id: userId,
          fullName: Value(fullName),
          email: Value(emailOrUsername),
          password: Value(password),
          role: const Value('admin'),
          storeId: Value(effectiveStoreId),
          createdAt: Value(DateTime.now()),
        ),
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_user_id', userId);
      await _activationService.activateLocally(
        emailOrUsername,
        displayName: fullName,
      );

      if (!mounted) return;
      final adminCtrl = Provider.of<AdminController>(context, listen: false);
      await adminCtrl.loadInitialData(userId: userId);

      // Refresh status admin offline
      await _checkOfflineAdminStatus();

      if (!mounted) return;
      _showSuccessDialog("Pendaftaran Berhasil!", "Akun berhasil dibuat.\nSelamat datang, $fullName!");

      await Future.delayed(const Duration(milliseconds: 1300));
      if (!mounted) return;
      Navigator.pop(context); // Close dialog

      Navigator.pushReplacementNamed(context, '/admin');
    } catch (e) {
      debugPrint("Manual Register Error: $e");
      _showError("Gagal mendaftar: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }



  void _showSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: colorbase,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => KasirDialog(
        title: "Perhatian",
        message: message,
        icon: Icons.error_outline_rounded,
        iconColor: Colors.redAccent,
        primaryActionLabel: "Mengerti",
        onPrimaryAction: () => Navigator.pop(context),
      ),
    );
  }

  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (context) => KasirDialog(
        title: title,
        message: message,
        icon: Icons.check_circle_rounded,
        iconColor: Colors.green,
      ),
    );
  }

  // --- ACCOUNT RECOVERY & QUICK LOGIN ---
  Future<void> _quickLoginAsProfile(Profile profile) async {
    Navigator.of(context, rootNavigator: true).pop(); // Close bottom sheet
    setState(() => _isLoading = true);
    try {
      await _activationService.activateLocally(
        profile.email ?? profile.fullName ?? 'User',
        displayName: profile.fullName,
      );

      if (!mounted) return;
      final adminCtrl = Provider.of<AdminController>(context, listen: false);
      await adminCtrl.loadInitialData(userId: profile.id);

      if (!mounted) return;
      _showSuccessDialog("Berhasil Masuk!", "Selamat datang kembali,\n${profile.fullName ?? profile.email}");

      await Future.delayed(const Duration(milliseconds: 1000));
      if (!mounted) return;
      Navigator.pop(context); // Close success dialog

      if (profile.role == 'admin' || profile.role == 'owner') {
        Navigator.pushReplacementNamed(context, '/admin');
      } else {
        Navigator.pushReplacementNamed(context, '/kasir');
      }
    } catch (e) {
      _showError("Gagal masuk cepat: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPasswordForProfile(Profile profile, String newPassword) async {
    try {
      await (_db.update(_db.profiles)..where((t) => t.id.equals(profile.id))).write(
        ProfilesCompanion(password: Value(newPassword)),
      );
      _showSnackbar("Password untuk ${profile.fullName ?? profile.email} berhasil diperbarui!");
    } catch (e) {
      _showError("Gagal mereset password: $e");
    }
  }

  void _showResetPasswordDialog(Profile profile) {
    final newPassCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => KasirDialog(
        title: "Setel Password Baru",
        message: "Masukkan kata sandi baru untuk akun ${profile.fullName ?? profile.email}:",
        icon: Icons.key_rounded,
        iconColor: colorbase,
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: TextField(
            controller: newPassCtrl,
            obscureText: false,
            decoration: InputDecoration(
              hintText: "Kata sandi baru...",
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ),
        primaryActionLabel: "Simpan Password",
        onPrimaryAction: () async {
          Navigator.pop(ctx);
          final pass = newPassCtrl.text.trim();
          if (pass.isEmpty) {
            _showSnackbar("Password tidak boleh kosong.");
            return;
          }
          await _resetPasswordForProfile(profile, pass);
        },
        secondaryActionLabel: "Batal",
        onSecondaryAction: () => Navigator.pop(ctx),
      ),
    );
  }

  Future<void> _showAccountRecoveryModal() async {
    final profiles = await (_db.select(_db.profiles)
          ..orderBy([
            (t) => OrderingTerm(
                  expression: const CustomExpression<int>(
                    "CASE WHEN role IN ('admin', 'owner') THEN 0 ELSE 1 END",
                  ),
                  mode: OrderingMode.asc,
                ),
            (t) => OrderingTerm.asc(t.fullName),
          ]))
        .get();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final Map<String, bool> showPassMap = {};

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(sheetCtx).size.height * 0.88,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.shield_outlined, color: colorbase, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            "Pemulihan Akun Tersimpan",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(sheetCtx),
                      ),
                    ],
                  ),
                  Text(
                    "Pilih akun terdaftar di perangkat ini untuk melihat kredensial, reset password, atau langsung masuk:",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Emergency Master Super Admin Card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFC7D2FE), width: 1.2),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.shield_rounded, color: Color(0xFF6366F1), size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    "Akun Super Admin (Permanen)",
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: const Color(0xFF312E81),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF6366F1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      "MASTER",
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Email: superadmin@pos.com | Sandi: superadmin123\nDapat melihat semua akun & reset sandi tanpa hapus data toko.",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: const Color(0xFF4338CA),
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (profiles.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          Icon(Icons.person_off_outlined, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            "Belum ada akun tersimpan di database perangkat ini.\nSilakan gunakan tab Daftar Baru.",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        itemCount: profiles.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final p = profiles[index];
                          final bool isAdmin = p.role == 'admin' || p.role == 'owner';
                          final roleLabel = isAdmin ? 'Admin Toko' : 'Karyawan / Kasir';
                          final roleColor = isAdmin ? const Color(0xFFC0392B) : const Color(0xFF0D9488);
                          final passVisible = showPassMap[p.id] ?? false;

                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFCBD5E1),
                                width: 1.2,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: roleColor.withValues(alpha: 0.12),
                                      child: Text(
                                        (p.fullName != null && p.fullName!.isNotEmpty)
                                            ? p.fullName![0].toUpperCase()
                                            : '?',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontWeight: FontWeight.w700,
                                          color: roleColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  p.fullName ?? 'Nama Akun',
                                                  style: GoogleFonts.plusJakartaSans(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 14,
                                                    color: const Color(0xFF1E293B),
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: roleColor.withValues(alpha: 0.12),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  roleLabel,
                                                  style: GoogleFonts.plusJakartaSans(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w700,
                                                    color: roleColor,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            "Username/Email: ${p.email ?? p.fullName ?? '-'}",
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.key, size: 14, color: Colors.grey),
                                      const SizedBox(width: 6),
                                      Text(
                                        "Kata Sandi: ",
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          color: Colors.grey.shade700,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          passVisible ? (p.password ?? '(kosong)') : "••••••••",
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF1E293B),
                                          ),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          setModalState(() {
                                            showPassMap[p.id] = !passVisible;
                                          });
                                        },
                                        child: Icon(
                                          passVisible ? Icons.visibility_off : Icons.visibility,
                                          size: 16,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: SizedBox(
                                        height: 38,
                                        child: ElevatedButton.icon(
                                          onPressed: () => _quickLoginAsProfile(p),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: colorbase,
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                          icon: const Icon(Icons.login_rounded, size: 16),
                                          label: Text(
                                            "Masuk Cepat",
                                            style: GoogleFonts.plusJakartaSans(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    SizedBox(
                                      height: 38,
                                      child: OutlinedButton.icon(
                                        onPressed: () => _showResetPasswordDialog(p),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: const Color(0xFF1E293B),
                                          side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        icon: const Icon(Icons.edit_outlined, size: 16),
                                        label: Text(
                                          "Ganti Password",
                                          style: GoogleFonts.plusJakartaSans(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 900) {
            return _buildWideLayout();
          }
          return _buildMobileLayout();
        },
      ),
    );
  }

  Widget _buildWideLayout() {
    return Row(
      children: [
        // Left Side: Branding
        Expanded(
          flex: 5,
          child: Container(
            color: colorbase,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.asset(
                        'assets/logo/logo.png',
                        width: 200,
                        height: 200,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Sistem Manajemen Kasir & Restoran Modern",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.openSans(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Right Side: Form Container
        Expanded(
          flex: 6,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: _buildFormCard(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/logo/logo.png',
                        width: 130,
                        height: 130,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildFormCard(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Tab Segment Switcher
        Container(
          height: 52,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (_isRegisterMode) {
                      setState(() => _isRegisterMode = false);
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    decoration: BoxDecoration(
                      color: !_isRegisterMode ? colorbase : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: !_isRegisterMode
                          ? [
                              BoxShadow(
                                color: colorbase.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : [],
                    ),
                    child: Center(
                      child: Text(
                        "Masuk",
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: !_isRegisterMode ? Colors.white : Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (!_isRegisterMode) {
                      setState(() => _isRegisterMode = true);
                      _checkOfflineAdminStatus();
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    decoration: BoxDecoration(
                      color: _isRegisterMode ? colorbase : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: _isRegisterMode
                          ? [
                              BoxShadow(
                                color: colorbase.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : [],
                    ),
                    child: Center(
                      child: Text(
                        "Daftar Baru",
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: _isRegisterMode ? Colors.white : Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        // Animated Form View
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 300),
          crossFadeState: !_isRegisterMode
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          firstChild: _buildLoginForm(),
          secondChild: _buildRegisterForm(),
        ),
      ],
    );
  }

  // --- LOGIN FORM WIDGET ---
  Widget _buildLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Selamat Datang Kembali!",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF2D3436),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "Masukkan username/email dan password Anda",
          style: GoogleFonts.openSans(fontSize: 14, color: Colors.grey[600]),
        ),
        const SizedBox(height: 24),

        // Input Username / Email
        _buildTextField(
          controller: _loginUsernameController,
          label: "Username / Email",
          hint: "Masukkan username atau email",
          icon: Icons.person_outline_rounded,
        ),
        const SizedBox(height: 16),

        // Input Password
        _buildTextField(
          controller: _loginPasswordController,
          label: "Password",
          hint: "Masukkan password",
          icon: Icons.lock_outline_rounded,
          isPassword: true,
          obscureText: _obscureLoginPass,
          onTogglePassword: () {
            setState(() => _obscureLoginPass = !_obscureLoginPass);
          },
        ),
        // Forgot Password / Account Recovery Link
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: _showAccountRecoveryModal,
            icon: const Icon(Icons.help_outline_rounded, size: 16, color: colorbase),
            label: Text(
              "Lupa Password / Pemulihan Akun",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colorbase,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Submit Button
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleManualLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: colorbase,
              foregroundColor: Colors.white,
              elevation: 3,
              shadowColor: colorbase.withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                    "MASUK",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 12),

        // Quick Account Switcher Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: _showAccountRecoveryModal,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1E293B),
              side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.switch_account_outlined, size: 20, color: colorbase),
            label: Text(
              "Pilih Akun Tersimpan di Perangkat Ini",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- REGISTER FORM WIDGET ---
  Widget _buildRegisterForm() {
    final bool hasAdmin = _existingAdmin != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          hasAdmin ? "Buat Akun Kasir / Karyawan" : "Pendaftaran Admin Toko",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF2D3436),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          hasAdmin
              ? "Akun baru akan otomatis terafiliasi dengan Admin Toko aktif"
              : "Daftarkan akun Admin Utama untuk mengelola toko di perangkat ini",
          style: GoogleFonts.openSans(fontSize: 14, color: Colors.grey[600]),
        ),
        const SizedBox(height: 16),

        // Banner Afiliasi Toko (Offline Single Admin)
        if (hasAdmin)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBBF7D0), width: 1.2),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.storefront_rounded, color: Color(0xFF16A34A), size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            "Terafiliasi dengan Admin Toko",
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: const Color(0xFF14532D),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF16A34A),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              "TERHUBUNG",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Toko: ${_existingStore?.name ?? 'Toko POS'} • Admin: ${_existingAdmin?.fullName ?? _existingAdmin?.email ?? 'Admin'}",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF15803D),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Karena sistem offline, 1 Admin Utama menaungi banyak akun kasir dan seluruh karyawan toko.",
                        style: GoogleFonts.openSans(
                          fontSize: 11,
                          color: const Color(0xFF166534),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFED7AA), width: 1.2),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEA580C).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFFEA580C), size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Admin Toko Belum Ada",
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: const Color(0xFF7C2D12),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Anda harus mendaftar sebagai Admin Utama terlebih dahulu. Karyawan hanya dapat dibuat setelah Admin Toko terdaftar.",
                        style: GoogleFonts.openSans(
                          fontSize: 11,
                          color: const Color(0xFF9A3412),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),

        // Full Name
        _buildTextField(
          controller: _regFullNameController,
          label: "Nama Lengkap",
          hint: hasAdmin ? "Contoh: Kasir Pagi / Budi" : "Contoh: Pemilik Toko",
          icon: Icons.badge_outlined,
        ),
        const SizedBox(height: 14),

        // Username / Email
        _buildTextField(
          controller: _regUsernameController,
          label: "Username / Email",
          hint: "Masukkan username atau email unik",
          icon: Icons.email_outlined,
        ),
        const SizedBox(height: 14),

        // Password
        _buildTextField(
          controller: _regPasswordController,
          label: "Password",
          hint: "Minimal 4 karakter",
          icon: Icons.lock_outline_rounded,
          isPassword: true,
          obscureText: _obscureRegPass,
          onTogglePassword: () {
            setState(() => _obscureRegPass = !_obscureRegPass);
          },
        ),
        const SizedBox(height: 14),

        // Confirm Password
        _buildTextField(
          controller: _regConfirmPasswordController,
          label: "Konfirmasi Password",
          hint: "Ulangi password di atas",
          icon: Icons.lock_clock_outlined,
          isPassword: true,
          obscureText: _obscureRegConfirmPass,
          onTogglePassword: () {
            setState(() => _obscureRegConfirmPass = !_obscureRegConfirmPass);
          },
        ),
        const SizedBox(height: 14),

        // Role Indicator (Terkunci otomatis sesuai ketersediaan Admin)
        Text(
          "Peran Akun",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2D3436),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              Icon(
                hasAdmin ? Icons.point_of_sale_outlined : Icons.admin_panel_settings_outlined,
                size: 20,
                color: hasAdmin ? Colors.blueAccent : colorbase,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasAdmin ? "Kasir / Akun Karyawan Toko" : "Admin / Pemilik Toko Utama",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      hasAdmin
                          ? "Terafiliasi langsung dengan ${_existingStore?.name ?? 'Toko POS'}"
                          : "Membuat toko baru dan mengelola seluruh sistem",
                      style: GoogleFonts.openSans(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: (hasAdmin ? Colors.blueAccent : colorbase).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  hasAdmin ? "KASIR" : "ADMIN",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: hasAdmin ? Colors.blueAccent : colorbase,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Submit Register Button
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleManualRegister,
            style: ElevatedButton.styleFrom(
              backgroundColor: colorbase,
              foregroundColor: Colors.white,
              elevation: 3,
              shadowColor: colorbase.withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                    hasAdmin ? "DAFTAR SEBAGAI KASIR" : "DAFTAR SEBAGAI ADMIN UTAMA",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  // --- REUSABLE TEXT FIELD WIDGET ---
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onTogglePassword,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2D3436),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: isPassword ? obscureText : false,
          style: GoogleFonts.openSans(fontSize: 15, color: const Color(0xFF2D3436)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.openSans(fontSize: 14, color: Colors.grey[400]),
            prefixIcon: Icon(icon, color: Colors.grey[500], size: 20),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: Colors.grey[500],
                      size: 20,
                    ),
                    onPressed: onTogglePassword,
                  )
                : null,
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: colorbase, width: 2),
            ),
          ),
        ),
      ],
    );
  }


}
