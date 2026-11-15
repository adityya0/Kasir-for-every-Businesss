import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/security_pin_service.dart';

class SecurityPinDialog extends StatefulWidget {
  final String title;
  final String message;
  final String confirmButtonLabel;
  final IconData icon;
  final Color iconColor;

  const SecurityPinDialog({
    super.key,
    this.title = "Otorisasi PIN Pemilik",
    this.message = "Masukkan PIN keamanan toko untuk memverifikasi tindakan ini.",
    this.confirmButtonLabel = "Verifikasi & Lanjutkan",
    this.icon = Icons.lock_outline_rounded,
    this.iconColor = const Color(0xFF2CAED2),
  });

  /// Static helper to check PIN if enabled, otherwise automatically authorize
  static Future<bool> authorize(
    BuildContext context, {
    String title = "Otorisasi PIN Pemilik",
    String message = "Masukkan PIN keamanan untuk menghapus transaksi ini.",
    String confirmButtonLabel = "Verifikasi & Hapus",
    IconData icon = Icons.lock_outline_rounded,
    Color iconColor = const Color(0xFFE05260),
  }) async {
    final pinService = SecurityPinService();
    final isEnabled = await pinService.isPinEnabled();
    if (!isEnabled) {
      return true; // No PIN protection set, proceed directly
    }

    if (!context.mounted) return false;

    final authorized = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => SecurityPinDialog(
        title: title,
        message: message,
        confirmButtonLabel: confirmButtonLabel,
        icon: icon,
        iconColor: iconColor,
      ),
    );

    return authorized == true;
  }

  /// Static helper to show the PIN Management modal (Create, Change, or Disable)
  static Future<void> showManagePinModal(
    BuildContext context, {
    VoidCallback? onStateChanged,
  }) async {
    final pinService = SecurityPinService();
    final isAlreadyActive = await pinService.isPinEnabled();

    if (!context.mounted) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryColor = Color(0xFF2CAED2);

    final currentPinCtrl = TextEditingController();
    final newPinCtrl = TextEditingController();
    final confirmPinCtrl = TextEditingController();

    int activeTabIndex = 0; // 0: Ganti PIN, 1: Nonaktifkan

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        bool isSaving = false;
        String? errText;
        bool obscureCurrent = true;
        bool obscureNew = true;
        bool obscureConfirm = true;

        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
            return Container(
              margin: EdgeInsets.only(bottom: bottomInset),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
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
                            color: primaryColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isAlreadyActive ? Icons.lock_rounded : Icons.shield_outlined,
                            color: primaryColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isAlreadyActive
                                    ? "Kelola PIN Hapus Transaksi"
                                    : "Buat PIN Hapus Transaksi",
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                isAlreadyActive
                                    ? "Lindungi data transaksi dari penghapusan kasir/karyawan"
                                    : "Sandi pengaman saat pesanan atau transaksi dihapus",
                                style: GoogleFonts.openSans(
                                  fontSize: 12,
                                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.grey),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    if (isAlreadyActive) ...[
                      // Toggle Segment: [Ganti PIN] vs [Nonaktifkan PIN]
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setModalState(() {
                                  activeTabIndex = 0;
                                  errText = null;
                                }),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 9),
                                  decoration: BoxDecoration(
                                    color: activeTabIndex == 0
                                        ? (isDark ? const Color(0xFF1E293B) : Colors.white)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(9),
                                    boxShadow: activeTabIndex == 0
                                        ? [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.08),
                                              blurRadius: 4,
                                            )
                                          ]
                                        : null,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    "Ganti PIN",
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: activeTabIndex == 0 ? FontWeight.w700 : FontWeight.w500,
                                      color: activeTabIndex == 0
                                          ? primaryColor
                                          : (isDark ? Colors.white70 : const Color(0xFF64748B)),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setModalState(() {
                                  activeTabIndex = 1;
                                  errText = null;
                                }),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 9),
                                  decoration: BoxDecoration(
                                    color: activeTabIndex == 1
                                        ? (isDark ? const Color(0xFF1E293B) : Colors.white)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(9),
                                    boxShadow: activeTabIndex == 1
                                        ? [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.08),
                                              blurRadius: 4,
                                            )
                                          ]
                                        : null,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    "Nonaktifkan PIN",
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: activeTabIndex == 1 ? FontWeight.w700 : FontWeight.w500,
                                      color: activeTabIndex == 1
                                          ? const Color(0xFFEF4444)
                                          : (isDark ? Colors.white70 : const Color(0xFF64748B)),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],

                    if (!isAlreadyActive) ...[
                      // FORM BUAT PIN BARU
                      Text(
                        "Buat 4-8 digit sandi keamanan pemilik. Sandi ini akan diminta setiap kali ada aksi menghapus transaksi.",
                        style: GoogleFonts.openSans(
                          fontSize: 12.5,
                          color: isDark ? Colors.white70 : const Color(0xFF475569),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildPinInputSheet(
                        controller: newPinCtrl,
                        hint: "PIN Baru (4-8 Digit)",
                        obscure: obscureNew,
                        isDark: isDark,
                        onToggle: () => setModalState(() => obscureNew = !obscureNew),
                      ),
                      const SizedBox(height: 12),
                      _buildPinInputSheet(
                        controller: confirmPinCtrl,
                        hint: "Konfirmasi PIN Baru",
                        obscure: obscureConfirm,
                        isDark: isDark,
                        onToggle: () => setModalState(() => obscureConfirm = !obscureConfirm),
                      ),
                    ] else if (activeTabIndex == 0) ...[
                      // FORM GANTI PIN (Wajib input PIN Aktif Saat Ini)
                      Text(
                        "Masukkan PIN yang sedang aktif saat ini untuk otorisasi perubahan, lalu masukkan PIN baru.",
                        style: GoogleFonts.openSans(
                          fontSize: 12.5,
                          color: isDark ? Colors.white70 : const Color(0xFF475569),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildPinInputSheet(
                        controller: currentPinCtrl,
                        hint: "PIN Aktif Saat Ini (Wajib)",
                        obscure: obscureCurrent,
                        isDark: isDark,
                        onToggle: () => setModalState(() => obscureCurrent = !obscureCurrent),
                      ),
                      const SizedBox(height: 12),
                      _buildPinInputSheet(
                        controller: newPinCtrl,
                        hint: "PIN Baru (4-8 Digit)",
                        obscure: obscureNew,
                        isDark: isDark,
                        onToggle: () => setModalState(() => obscureNew = !obscureNew),
                      ),
                      const SizedBox(height: 12),
                      _buildPinInputSheet(
                        controller: confirmPinCtrl,
                        hint: "Konfirmasi PIN Baru",
                        obscure: obscureConfirm,
                        isDark: isDark,
                        onToggle: () => setModalState(() => obscureConfirm = !obscureConfirm),
                      ),
                    ] else ...[
                      // FORM NONAKTIFKAN PIN (Wajib input PIN Aktif Saat Ini)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 22),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "Jika dinonaktifkan, transaksi dapat dihapus tanpa proteksi sandi. Masukkan PIN yang aktif untuk mematikan pengamanan.",
                                style: GoogleFonts.openSans(
                                  fontSize: 12,
                                  color: isDark ? Colors.white70 : const Color(0xFFB91C1C),
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildPinInputSheet(
                        controller: currentPinCtrl,
                        hint: "PIN Aktif Saat Ini (Wajib)",
                        obscure: obscureCurrent,
                        isDark: isDark,
                        onToggle: () => setModalState(() => obscureCurrent = !obscureCurrent),
                      ),
                    ],

                    if (errText != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                errText!,
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.redAccent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: (isAlreadyActive && activeTabIndex == 1)
                              ? const Color(0xFFEF4444)
                              : primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        onPressed: isSaving
                            ? null
                            : () async {
                                final cur = currentPinCtrl.text.trim();
                                final pin = newPinCtrl.text.trim();
                                final conf = confirmPinCtrl.text.trim();

                                if (!isAlreadyActive) {
                                  // Buat PIN Baru
                                  if (pin.length < 4 || pin.length > 8) {
                                    setModalState(() => errText = "PIN harus terdiri dari 4 sampai 8 digit angka.");
                                    return;
                                  }
                                  if (pin != conf) {
                                    setModalState(() => errText = "Konfirmasi PIN baru tidak cocok.");
                                    return;
                                  }

                                  setModalState(() {
                                    isSaving = true;
                                    errText = null;
                                  });

                                  final ok = await pinService.setPin(pin);
                                  if (ok) {
                                    if (modalCtx.mounted) Navigator.pop(modalCtx);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            "✓ PIN Pengaman Hapus Transaksi berhasil diaktifkan!",
                                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                                          ),
                                          backgroundColor: const Color(0xFF10B981),
                                        ),
                                      );
                                    }
                                    onStateChanged?.call();
                                  } else {
                                    setModalState(() {
                                      isSaving = false;
                                      errText = "Gagal mengaktifkan PIN. Coba lagi.";
                                    });
                                  }
                                } else if (activeTabIndex == 0) {
                                  // Ganti PIN: Cek PIN aktif saat ini dulu
                                  if (cur.isEmpty) {
                                    setModalState(() => errText = "Harap masukkan PIN yang sedang aktif.");
                                    return;
                                  }
                                  final isCurrentValid = await pinService.verifyPin(cur);
                                  if (!isCurrentValid) {
                                    setModalState(() => errText = "PIN aktif saat ini salah! Ganti PIN ditolak.");
                                    return;
                                  }
                                  if (pin.length < 4 || pin.length > 8) {
                                    setModalState(() => errText = "PIN baru harus 4 sampai 8 digit angka.");
                                    return;
                                  }
                                  if (pin != conf) {
                                    setModalState(() => errText = "Konfirmasi PIN baru tidak cocok.");
                                    return;
                                  }

                                  setModalState(() {
                                    isSaving = true;
                                    errText = null;
                                  });

                                  final ok = await pinService.changePin(currentPin: cur, newPin: pin);
                                  if (ok) {
                                    if (modalCtx.mounted) Navigator.pop(modalCtx);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            "✓ PIN Keamanan Transaksi berhasil diperbarui!",
                                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                                          ),
                                          backgroundColor: primaryColor,
                                        ),
                                      );
                                    }
                                    onStateChanged?.call();
                                  } else {
                                    setModalState(() {
                                      isSaving = false;
                                      errText = "Gagal mengubah PIN. Coba lagi.";
                                    });
                                  }
                                } else {
                                  // Nonaktifkan PIN: Cek PIN aktif saat ini dulu
                                  if (cur.isEmpty) {
                                    setModalState(() => errText = "Harap masukkan PIN yang sedang aktif.");
                                    return;
                                  }

                                  setModalState(() {
                                    isSaving = true;
                                    errText = null;
                                  });

                                  final ok = await pinService.disablePin(currentPin: cur);
                                  if (ok) {
                                    if (modalCtx.mounted) Navigator.pop(modalCtx);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            "PIN Keamanan dinonaktifkan. Transaksi bebas dihapus tanpa PIN.",
                                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                                          ),
                                          backgroundColor: Colors.orange.shade800,
                                        ),
                                      );
                                    }
                                    onStateChanged?.call();
                                  } else {
                                    setModalState(() {
                                      isSaving = false;
                                      errText = "PIN aktif saat ini salah! Tidak dapat menonaktifkan.";
                                    });
                                  }
                                }
                              },
                        child: isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                !isAlreadyActive
                                    ? "Aktifkan PIN Pengaman"
                                    : (activeTabIndex == 0 ? "Simpan PIN Baru" : "Hapus & Nonaktifkan PIN"),
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  static Widget _buildPinInputSheet({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required bool isDark,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      maxLength: 8,
      obscureText: obscure,
      textAlign: TextAlign.center,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: 6,
        color: isDark ? Colors.white : const Color(0xFF1E293B),
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.plusJakartaSans(letterSpacing: 1, color: Colors.grey.shade400, fontSize: 13),
        counterText: "",
        filled: true,
        fillColor: isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, color: Colors.grey, size: 20),
          onPressed: onToggle,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
        ),
      ),
    );
  }

  @override
  State<SecurityPinDialog> createState() => _SecurityPinDialogState();
}

class _SecurityPinDialogState extends State<SecurityPinDialog> {
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final SecurityPinService _pinService = SecurityPinService();

  bool _obscureText = true;
  bool _isChecking = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _verifyAndSubmit() async {
    final input = _pinController.text.trim();
    if (input.isEmpty) {
      setState(() => _errorMessage = "Masukkan PIN keamanan Anda");
      return;
    }

    setState(() {
      _isChecking = true;
      _errorMessage = null;
    });

    final isValid = await _pinService.verifyPin(input);

    if (!mounted) return;

    if (isValid) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _isChecking = false;
        _errorMessage = "PIN salah! Masukkan PIN pemilik yang benar.";
      });
      _pinController.clear();
      _focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      elevation: 12,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon Header
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: widget.iconColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(widget.icon, color: widget.iconColor, size: 28),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),

              // Message
              Text(
                widget.message,
                textAlign: TextAlign.center,
                style: GoogleFonts.openSans(
                  fontSize: 12.5,
                  color: isDark ? Colors.white70 : const Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),

              // PIN Input Field
              TextField(
                controller: _pinController,
                focusNode: _focusNode,
                obscureText: _obscureText,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 8,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 8,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                decoration: InputDecoration(
                  counterText: "",
                  hintText: "••••",
                  hintStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    letterSpacing: 4,
                    color: Colors.grey.shade400,
                  ),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                      color: Colors.grey,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscureText = !_obscureText),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: _errorMessage != null
                          ? Colors.redAccent
                          : (isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0)),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: _errorMessage != null ? Colors.redAccent : widget.iconColor,
                      width: 1.8,
                    ),
                  ),
                ),
                onSubmitted: (_) => _verifyAndSubmit(),
              ),

              // Error Message
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 14),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        _errorMessage!,
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.redAccent,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 22),

              // Action Buttons
              Row(
                children: [
                  // Batal
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isChecking ? null : () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        side: BorderSide(
                          color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        "Batal",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Verifikasi
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isChecking ? null : _verifyAndSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.iconColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _isChecking
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              widget.confirmButtonLabel,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
