import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../controllers/admin_controller.dart';
import '../../core/supabase_config.dart';
import '../../services/activation_service.dart';
import '../../services/app_database.dart';
import '../../services/supabase_auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const Color primaryColor = Color(0xFFBD1B19); // OMNI POS Red
  late AppDatabase _db;

  bool _isRegisterMode = false;
  bool _isLoading = false;

  // Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _regFullNameController = TextEditingController();
  final _regEmailController = TextEditingController();
  final _regPasswordController = TextEditingController();

  bool _obscureLoginPass = true;
  bool _obscureRegPass = true;

  @override
  void initState() {
    super.initState();
    _db = context.read<AppDatabase>();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _regFullNameController.dispose();
    _regEmailController.dispose();
    _regPasswordController.dispose();
    super.dispose();
  }

  void _showSnackbar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
        backgroundColor: isError ? Colors.red.shade700 : primaryColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // --- LOGIN ONLINE (EMAIL / PASSWORD) ---
  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showSnackbar("Harap isi Email dan Password.", isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final profile = await SupabaseAuthService().signInWithPassword(
        email: email,
        password: password,
        localDb: _db,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_user_id', profile.id);

      if (!mounted) return;
      final adminCtrl = Provider.of<AdminController>(context, listen: false);
      await adminCtrl.loadInitialData(userId: profile.id);

      if (!mounted) return;

      // Cek apakah perangkat sudah pernah diverifikasi PIN sebelumnya
      final isVerified = await ActivationService().isVerified();
      if (!mounted) return;
      if (!isVerified) {
        // TAHAP 2: Arahkan ke Verifikasi PIN Keamanan Toko
        Navigator.pushReplacementNamed(context, '/pin-verification');
      } else {
        // Sudah terverifikasi -> Masuk Dashboard
        Navigator.pushReplacementNamed(context, '/admin');
      }
    } catch (e) {
      debugPrint("Login error: $e");
      final err = e.toString().replaceAll('Exception: ', '');
      _showSnackbar("Gagal Masuk: $err", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- LOGIN DENGAN GOOGLE ---
  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    try {
      final success = await SupabaseAuthService().signInWithGoogle();
      if (success) {
        final isVerified = await ActivationService().isVerified();
        if (!mounted) return;
        if (!isVerified) {
          Navigator.pushReplacementNamed(context, '/pin-verification');
        } else {
          Navigator.pushReplacementNamed(context, '/admin');
        }
      }
    } catch (e) {
      _showSnackbar("Gagal masuk dengan Google: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- DAFTAR AKUN BARU (SUPABASE) ---
  Future<void> _handleRegister() async {
    final fullName = _regFullNameController.text.trim();
    final email = _regEmailController.text.trim();
    final password = _regPasswordController.text;

    if (fullName.isEmpty || email.isEmpty || password.isEmpty) {
      _showSnackbar("Harap lengkapi semua kolom pendaftaran.", isError: true);
      return;
    }

    if (password.length < 6) {
      _showSnackbar("Password minimal 6 karakter.", isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final res = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'store_name': 'OMNI POS ($fullName)',
          'pin_code': '123456', // Default PIN sesuai aturan database
        },
      );

      final user = res.user;
      if (user != null) {
        // Pastikan baris di profiles terbuat dengan default PIN 123456
        try {
          await supabase.from('profiles').upsert({
            'id': user.id,
            'email': email,
            'full_name': fullName,
            'store_name': 'OMNI POS ($fullName)',
            'pin_code': '123456',
            'role': 'admin',
            'is_active': true,
          });
        } catch (_) {}

        _emailController.text = email;
        _passwordController.text = password;

        setState(() => _isRegisterMode = false);

        _showSnackbar("Pendaftaran Berhasil! PIN default Anda: 123456. Silakan klik Masuk.");
      } else {
        _showSnackbar("Pendaftaran dikirim. Silakan periksa verifikasi email Anda jika diaktifkan.");
      }
    } catch (e) {
      debugPrint("Register error: $e");
      _showSnackbar("Pendaftaran Gagal: ${e.toString().replaceAll('Exception: ', '')}", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- LUPA PASSWORD AMAN (OTP GMAIL 3 LANGKAH) ---
  void _showForgotPasswordModal() {
    int step = 1;
    final emailCtrl = TextEditingController(text: _emailController.text.trim());
    final otpCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    bool isSubmitting = false;
    String? stepError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final bottomInset = MediaQuery.of(sheetCtx).viewInsets.bottom;
            return Container(
              margin: EdgeInsets.only(bottom: bottomInset),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            step == 1 ? Icons.mail_outline_rounded : (step == 2 ? Icons.pin_outlined : Icons.lock_reset_rounded),
                            color: primaryColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Pemulihan Akun Aman",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                              Text(
                                "Langkah $step dari 3: ${step == 1 ? 'Minta Kode OTP' : (step == 2 ? 'Verifikasi OTP' : 'Password Baru')}",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.grey),
                          onPressed: () => Navigator.pop(sheetCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Divider(height: 1, color: Colors.grey.shade200),
                    const SizedBox(height: 16),

                    if (stepError != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Text(
                          stepError!,
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.red.shade800, fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    if (step == 1) ...[
                      Text(
                        "Masukkan email akun Supabase Anda. Kode verifikasi 6 digit akan dikirimkan ke email Anda.",
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF64748B), height: 1.4),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: emailCtrl,
                        cursorColor: primaryColor,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: "Alamat Email",
                          prefixIcon: const Icon(Icons.email_outlined, color: primaryColor),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primaryColor, width: 2)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: isSubmitting
                              ? null
                              : () async {
                                  final email = emailCtrl.text.trim();
                                  if (email.isEmpty) {
                                    setModalState(() => stepError = "Email tidak boleh kosong.");
                                    return;
                                  }
                                  setModalState(() {
                                    isSubmitting = true;
                                    stepError = null;
                                  });
                                  try {
                                    await SupabaseAuthService().sendPasswordResetEmail(email);
                                    setModalState(() {
                                      isSubmitting = false;
                                      step = 2;
                                    });
                                  } catch (e) {
                                    setModalState(() {
                                      isSubmitting = false;
                                      stepError = e.toString().replaceAll('Exception: ', '');
                                    });
                                  }
                                },
                          child: isSubmitting
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text("Kirim Kode OTP (Email)", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],

                    if (step == 2) ...[
                      Text(
                        "Masukkan 6 digit token recovery yang baru saja dikirimkan ke ${emailCtrl.text}:",
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF64748B), height: 1.4),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: otpCtrl,
                        cursorColor: primaryColor,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: 10),
                        decoration: InputDecoration(
                          hintText: "123456",
                          counterText: "",
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primaryColor, width: 2)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: isSubmitting
                              ? null
                              : () async {
                                  final token = otpCtrl.text.trim();
                                  if (token.length < 6) {
                                    setModalState(() => stepError = "Masukkan 6 digit kode OTP secara lengkap.");
                                    return;
                                  }
                                  setModalState(() {
                                    isSubmitting = true;
                                    stepError = null;
                                  });
                                  try {
                                    await SupabaseAuthService().verifyRecoveryOtp(email: emailCtrl.text.trim(), token: token);
                                    setModalState(() {
                                      isSubmitting = false;
                                      step = 3;
                                    });
                                  } catch (e) {
                                    setModalState(() {
                                      isSubmitting = false;
                                      stepError = "Kode OTP tidak valid atau kedaluwarsa.";
                                    });
                                  }
                                },
                          child: isSubmitting
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text("Verifikasi Kode OTP", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],

                    if (step == 3) ...[
                      Text(
                        "Token terverifikasi! Silakan tentukan kata sandi baru:",
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF64748B), height: 1.4),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: newPassCtrl,
                        cursorColor: primaryColor,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: "Password Baru",
                          prefixIcon: const Icon(Icons.lock_outline_rounded, color: primaryColor),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primaryColor, width: 2)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: confirmPassCtrl,
                        cursorColor: primaryColor,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: "Konfirmasi Password Baru",
                          prefixIcon: const Icon(Icons.lock_reset_rounded, color: primaryColor),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primaryColor, width: 2)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: isSubmitting
                              ? null
                              : () async {
                                  final newPass = newPassCtrl.text;
                                  if (newPass.length < 6) {
                                    setModalState(() => stepError = "Password minimal 6 karakter.");
                                    return;
                                  }
                                  if (newPass != confirmPassCtrl.text) {
                                    setModalState(() => stepError = "Konfirmasi password tidak cocok.");
                                    return;
                                  }
                                  setModalState(() {
                                    isSubmitting = true;
                                    stepError = null;
                                  });
                                  try {
                                    await SupabaseAuthService().updateUserPassword(newPass);
                                    if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                                    _emailController.text = emailCtrl.text.trim();
                                    _passwordController.clear();
                                    _showSnackbar("Password berhasil diubah! Silakan masuk.");
                                  } catch (e) {
                                    setModalState(() {
                                      isSubmitting = false;
                                      stepError = e.toString().replaceAll('Exception: ', '');
                                    });
                                  }
                                },
                          child: isSubmitting
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text("Simpan Password Baru", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                  ],
                ),
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
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                elevation: 4,
                shadowColor: Colors.black.withValues(alpha: 0.08),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo
                      Image.asset(
                        'assets/logo/logo.png',
                        width: 72,
                        height: 72,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 14),

                      // Title
                      Text(
                        "OMNI POS",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isRegisterMode ? "Pendaftaran Akun Toko Baru" : "Masuk ke Akun POS Toko",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Mode Switcher (Masuk / Daftar)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _isRegisterMode = false),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: !_isRegisterMode ? Colors.white : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: !_isRegisterMode
                                        ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))]
                                        : null,
                                  ),
                                  child: Center(
                                    child: Text(
                                      "Masuk",
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: !_isRegisterMode ? FontWeight.w700 : FontWeight.w600,
                                        color: !_isRegisterMode ? primaryColor : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _isRegisterMode = true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: _isRegisterMode ? Colors.white : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: _isRegisterMode
                                        ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))]
                                        : null,
                                  ),
                                  child: Center(
                                    child: Text(
                                      "Daftar Akun",
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: _isRegisterMode ? FontWeight.w700 : FontWeight.w600,
                                        color: _isRegisterMode ? primaryColor : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // FORM MASUK
                      if (!_isRegisterMode) ...[
                        TextField(
                          controller: _emailController,
                          cursorColor: primaryColor,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: "Email",
                            prefixIcon: const Icon(Icons.email_outlined, color: primaryColor),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: primaryColor, width: 2)),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _passwordController,
                          cursorColor: primaryColor,
                          obscureText: _obscureLoginPass,
                          decoration: InputDecoration(
                            labelText: "Password",
                            prefixIcon: const Icon(Icons.lock_outline_rounded, color: primaryColor),
                            suffixIcon: IconButton(
                              icon: Icon(_obscureLoginPass ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: Colors.grey),
                              onPressed: () => setState(() => _obscureLoginPass = !_obscureLoginPass),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: primaryColor, width: 2)),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _showForgotPasswordModal,
                            child: Text(
                              "Lupa Password?",
                              style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: primaryColor),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 2,
                            ),
                            onPressed: _isLoading ? null : _handleLogin,
                            child: _isLoading
                                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2))
                                : Text("MASUK", style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                          ),
                        ),
                        if (SupabaseConfig.enableGoogleAuth) ...[
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: OutlinedButton.icon(
                              onPressed: _isLoading ? null : _handleGoogleLogin,
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFCBD5E1)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              icon: const Icon(Icons.g_mobiledata_rounded, size: 28, color: Color(0xFFEA4335)),
                              label: Text(
                                "Masuk dengan Google",
                                style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
                              ),
                            ),
                          ),
                        ],
                      ],

                      // FORM DAFTAR AKUN BARU
                      if (_isRegisterMode) ...[
                        TextField(
                          controller: _regFullNameController,
                          cursorColor: primaryColor,
                          decoration: InputDecoration(
                            labelText: "Nama Pemilik / Toko",
                            prefixIcon: const Icon(Icons.storefront_outlined, color: primaryColor),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: primaryColor, width: 2)),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _regEmailController,
                          cursorColor: primaryColor,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: "Email Akun",
                            prefixIcon: const Icon(Icons.email_outlined, color: primaryColor),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: primaryColor, width: 2)),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _regPasswordController,
                          cursorColor: primaryColor,
                          obscureText: _obscureRegPass,
                          decoration: InputDecoration(
                            labelText: "Password (Min. 6 Karakter)",
                            prefixIcon: const Icon(Icons.lock_outline_rounded, color: primaryColor),
                            suffixIcon: IconButton(
                              icon: Icon(_obscureRegPass ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: Colors.grey),
                              onPressed: () => setState(() => _obscureRegPass = !_obscureRegPass),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: primaryColor, width: 2)),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: primaryColor.withValues(alpha: 0.25)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline_rounded, color: primaryColor, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "PIN Keamanan otomatis diatur ke '123456'.",
                                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: primaryColor, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 2,
                            ),
                            onPressed: _isLoading ? null : _handleRegister,
                            child: _isLoading
                                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2))
                                : Text("DAFTAR AKUN BARU", style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
