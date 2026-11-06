import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import '../../services/platform/file_manager.dart';

import 'package:provider/provider.dart';
import '../../controllers/admin_controller.dart';
import '../../controllers/analytics_controller.dart';
import '../../controllers/cart_controller.dart';
import '../../services/app_database.dart';
import '../../services/activation_service.dart';
import '../../services/supabase_auth_service.dart';
import '../../widgets/kasir_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  final String storeId;
  final VoidCallback? onMenuPressed;
  const ProfilePage({super.key, required this.storeId, this.onMenuPressed});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isLoading = false;
  String? _storeName;
  String? _storeLogo;
  bool _isPinActive = false;

  final Color _primaryColor = const Color(0xFF00BF63);

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final adminCtrl = context.read<AdminController>();
    final db = context.read<AppDatabase>();

    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final pin = prefs.getString('pin_code') ?? '';
      final pinEnabled = prefs.getBool('offline_pin_enabled') ?? pin.isNotEmpty;

      if (mounted) {
        setState(() {
          _isPinActive = pinEnabled && pin.isNotEmpty;
          _storeName = adminCtrl.storeName;
          _storeLogo = adminCtrl.storeLogo;
        });

        // Load Store Info (already in controller, but if we need a fresh DB hit)
        final storeData =
            await (db.select(db.stores)
                  ..where((t) => t.id.equals(widget.storeId))
                  ..limit(1))
                .getSingleOrNull();

        if (mounted && storeData != null) {
          setState(() {
            _storeName = storeData.name;
            _storeLogo = storeData.logoUrl;
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading profile: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showLogoSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Ganti Logo Toko",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSourceOption(
                  icon: Icons.camera_alt_rounded,
                  label: "Kamera",
                  onTap: () {
                    Navigator.pop(context);
                    _pickStoreLogo(ImageSource.camera);
                  },
                ),
                _buildSourceOption(
                  icon: Icons.photo_library_rounded,
                  label: "Galeri",
                  onTap: () {
                    Navigator.pop(context);
                    _pickStoreLogo(ImageSource.gallery);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: _primaryColor, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.openSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickStoreLogo(ImageSource source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: source,
      imageQuality: 70,
    );
    if (image == null) return;
    if (!mounted) return;

    setState(() => _isLoading = true);
    try {
      final fileName =
          'store_${widget.storeId}_${DateTime.now().millisecondsSinceEpoch}${p.extension(image.path)}';
      final savedPath = await FileManager().saveFile(image, fileName);

      if (!mounted) return;
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

      final adminCtrl = context.read<AdminController>();
      await adminCtrl.updateStoreBranding(logoUrl: savedPath);

      if (mounted) {
        setState(() => _storeLogo = savedPath);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Logo toko diperbarui!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint("Update Store Logo Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _editStoreName() async {
    final controller = TextEditingController(text: _storeName);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Ubah Nama Toko",
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: GoogleFonts.openSans(
            color: isDark ? Colors.white : Colors.black87,
          ),
          decoration: InputDecoration(
            hintText: "Nama Toko (Contoh: Kakilima Pos)",
            fillColor: Colors.grey.withValues(alpha: 0.1),
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Batal", style: GoogleFonts.openSans(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text("Simpan", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty) {
      if (!mounted) return;
      setState(() => _isLoading = true);
      try {
        final adminCtrl = context.read<AdminController>();
        await adminCtrl.updateStoreBranding(name: newName);
        try {
          await SupabaseAuthService().updateProfileOnline(storeName: newName);
        } catch (e) {
          debugPrint("Sync online store_name error: $e");
        }
        setState(() => _storeName = newName);
      } catch (e) {
        debugPrint("Update Store Name Error: $e");
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  // ── Fitur Pengaturan PIN Offline & Keamanan ──────────────────────
  Future<void> _showManagePinModal() async {
    final db = context.read<AppDatabase>();
    final prefs = await SharedPreferences.getInstance();
    bool enablePin = prefs.getBool('offline_pin_enabled') ?? false;
    final existingPin = prefs.getString('pin_code') ?? '';
    final pinCtrl = TextEditingController(text: existingPin);
    final confirmPinCtrl = TextEditingController(text: existingPin);

    if (!mounted) return;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        bool isSaving = false;
        String? errText;
        bool obscurePin = true;

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
                            color: _primaryColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.pin_outlined, color: _primaryColor, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Atur PIN Keamanan (Offline)",
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                "Kunci bersifat opsional / dapat dinonaktifkan",
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
                    const SizedBox(height: 16),
                    // Toggle Switch PIN Aktif / Opsional
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            enablePin ? Icons.lock_rounded : Icons.lock_open_rounded,
                            color: enablePin ? _primaryColor : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              enablePin ? "Kunci PIN Aktif" : "Kunci PIN Dinonaktifkan (Bebas Masuk)",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          Switch(
                            value: enablePin,
                            activeThumbColor: _primaryColor,
                            onChanged: (val) {
                              setModalState(() {
                                enablePin = val;
                                errText = null;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (enablePin) ...[
                      Text(
                        "Masukkan 4-6 digit angka untuk mengunci aplikasi dan menu sensitif (Arus Kas, Pembelian, dll).",
                        style: GoogleFonts.openSans(
                          fontSize: 12.5,
                          color: isDark ? Colors.white70 : const Color(0xFF475569),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: pinCtrl,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        obscureText: obscurePin,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 8,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                        decoration: InputDecoration(
                          hintText: "PIN Baru",
                          hintStyle: GoogleFonts.plusJakartaSans(letterSpacing: 2, color: Colors.grey.shade400, fontSize: 14),
                          counterText: "",
                          filled: true,
                          fillColor: isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: confirmPinCtrl,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        obscureText: obscurePin,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 8,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                        decoration: InputDecoration(
                          hintText: "Konfirmasi PIN",
                          hintStyle: GoogleFonts.plusJakartaSans(letterSpacing: 2, color: Colors.grey.shade400, fontSize: 14),
                          counterText: "",
                          suffixIcon: IconButton(
                            icon: Icon(obscurePin ? Icons.visibility_off : Icons.visibility, color: Colors.grey, size: 20),
                            onPressed: () => setModalState(() => obscurePin = !obscurePin),
                          ),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                          ),
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                        ),
                        child: Text(
                          "Aplikasi tidak akan meminta PIN saat dibuka atau saat membuka menu sensitif. Anda dapat mengaktifkannya kembali kapan saja.",
                          style: GoogleFonts.openSans(
                            fontSize: 12.5,
                            color: isDark ? Colors.white60 : const Color(0xFF64748B),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                    if (errText != null) ...[
                      const SizedBox(height: 10),
                      Text(errText!, style: GoogleFonts.plusJakartaSans(color: Colors.red, fontSize: 12)),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: isSaving
                            ? null
                            : () async {
                                final pin = pinCtrl.text.trim();
                                final conf = confirmPinCtrl.text.trim();

                                if (enablePin) {
                                  if (pin.length < 4 || pin.length > 6) {
                                    setModalState(() => errText = "PIN harus terdiri dari 4 sampai 6 digit angka.");
                                    return;
                                  }
                                  if (pin != conf) {
                                    setModalState(() => errText = "Konfirmasi PIN tidak cocok.");
                                    return;
                                  }
                                }

                                setModalState(() {
                                  isSaving = true;
                                  errText = null;
                                });

                                final scaffoldMessenger = ScaffoldMessenger.of(context);
                                try {
                                  await SupabaseAuthService().updateOfflinePin(
                                    pinCode: enablePin ? pin : null,
                                    localDb: db,
                                  );

                                  if (mounted) {
                                    setState(() {
                                      _isPinActive = enablePin;
                                    });
                                    if (modalCtx.mounted) Navigator.pop(modalCtx);
                                    scaffoldMessenger.showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          enablePin
                                              ? "PIN Keamanan Offline berhasil disimpan & aktif!"
                                              : "PIN Keamanan dinonaktifkan (bebas tanpa PIN).",
                                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                                        ),
                                        backgroundColor: _primaryColor,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  setModalState(() {
                                    isSaving = false;
                                    errText = "Gagal menyimpan PIN: $e";
                                  });
                                }
                              },
                        child: isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                "Simpan Pengaturan PIN",
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

  Future<void> _confirmSignOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => KasirDialog(
        title: "Keluar dari Akun?",
        message: "Anda akan keluar dari sesi ini dan harus memasukkan kredensial login kembali untuk membuka POS.",
        icon: Icons.logout_rounded,
        iconColor: Colors.orange.shade800,
        primaryActionLabel: "Keluar",
        onPrimaryAction: () => Navigator.pop(ctx, true),
        secondaryActionLabel: "Batal",
        onSecondaryAction: () => Navigator.pop(ctx, false),
      ),
    );

    if (confirm == true) {
      await ActivationService().logout();
      await SupabaseAuthService().signOut();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/activation', (route) => false);
    }
  }

  Future<void> _confirmResetStore() async {
    final controller = TextEditingController();
    bool deleteProducts = true;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final result = await showDialog<String>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.delete_forever_rounded, color: Color(0xFFEF4444), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "RESET TOTAL TOKO",
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 16.5,
                        color: const Color(0xFFEF4444),
                      ),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Tindakan ini akan MENGHAPUS SEMUA DATA TOKO dan meresetnya menjadi 0 (kembali bersih total). Data yang dihapus tidak dapat dipulihkan.",
                      style: GoogleFonts.openSans(
                        fontSize: 13,
                        color: isDark ? Colors.white70 : const Color(0xFF475569),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Data yang akan di-reset ke 0:",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildResetBullet("Semua Riwayat Transaksi & Nota Kasir", isDark),
                          _buildResetBullet("Semua Pengeluaran & Catatan Arus Kas", isDark),
                          _buildResetBullet("Semua Pembelian, Hutang & Data Supplier", isDark),
                          _buildResetBullet("Semua Data Pelanggan & Piutang", isDark),
                          _buildResetBullet("Semua Promo, Diskon, & Absensi Karyawan", isDark),
                          _buildResetBullet("Semua Laporan, Grafik Tren, & Saldo Kas (Rp 0)", isDark),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: CheckboxListTile(
                        value: deleteProducts,
                        activeColor: const Color(0xFFEF4444),
                        onChanged: (val) => setDialogState(() => deleteProducts = val ?? true),
                        title: Text(
                          "Hapus seluruh katalog produk & kategori (0 produk)",
                          style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          deleteProducts
                              ? "Semua produk, kategori & satuan dikosongkan total."
                              : "Produk dipertahankan, namun stok di-reset ke 0.",
                          style: GoogleFonts.openSans(fontSize: 11, color: Colors.grey),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Ketik kata \"RESET\" untuk konfirmasi penghapusan:",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : const Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: controller,
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                      decoration: InputDecoration(
                        hintText: "RESET",
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: Text("Batal", style: GoogleFonts.plusJakartaSans(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    Navigator.pop(dialogCtx, controller.text.trim());
                  },
                  child: const Text(
                    "RESET SEMUA DATA",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == "RESET") {
      if (!mounted) return;
      setState(() => _isLoading = true);
      try {
        final adminCtrl = context.read<AdminController>();
        await adminCtrl.resetStore(deleteProducts: deleteProducts);

        if (mounted) {
          try {
            context.read<AnalyticsController>().refreshData();
            context.read<AnalyticsController>().resetTableTrendsData();
          } catch (_) {}
          try {
            context.read<CartController>().clearCart();
          } catch (_) {}
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "✓ Berhasil! Semua data toko telah di-reset total menjadi 0.",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              backgroundColor: Color(0xFF00BF63),
              duration: Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Gagal me-reset toko: $e"),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
          _loadProfile();
        }
      }
    } else if (result != null && result.isNotEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Konfirmasi salah. Ketik kata RESET dengan huruf kapital untuk menghapus."),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Widget _buildResetBullet(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("• ", style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.openSans(
                fontSize: 12,
                color: isDark ? Colors.white70 : const Color(0xFF475569),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final adminCtrl = context.watch<AdminController>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF374151) : const Color(0xFFCBD5E1);
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final currentLogo = _storeLogo ?? adminCtrl.storeLogo;
    final currentName = _storeName ?? adminCtrl.storeName ?? 'Toko Saya';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          "Profil Toko",
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                onPressed: () => Navigator.pop(context),
              )
            : (widget.onMenuPressed != null
                ? IconButton(
                    icon: Icon(
                      Icons.menu,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    onPressed: widget.onMenuPressed,
                  )
                : null),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: "Segarkan",
            onPressed: _loadProfile,
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: borderColor,
            height: 1,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00BF63)))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 820),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Profile Header Card (Outline Style) ──────────────────
                      _buildProfileHeaderCard(
                        isDark: isDark,
                        borderColor: borderColor,
                        cardBg: cardBg,
                        currentLogo: currentLogo,
                        currentName: currentName,
                      ),
                      const SizedBox(height: 24),

                      // ── Branding Section ─────────────────────────────────────
                      _buildSectionHeader("BRANDING TOKO", isDark),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: borderColor, width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildActionTile(
                              icon: Icons.edit_note_rounded,
                              title: "Ubah Nama Toko",
                              subtitle: currentName,
                              isDark: isDark,
                              onTap: _editStoreName,
                            ),
                            Divider(height: 1, indent: 56, color: borderColor),
                            _buildActionTile(
                              icon: Icons.image_rounded,
                              title: "Ubah Logo Toko",
                              subtitle: "Ketuk untuk memilih foto logo dari kamera atau galeri",
                              isDark: isDark,
                              trailing: currentLogo != null && currentLogo.isNotEmpty
                                  ? Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: borderColor, width: 1),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(7),
                                        child: Image(
                                          image: FileManager().getImageProvider(currentLogo),
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => const Icon(
                                            Icons.broken_image_rounded,
                                            size: 18,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                    )
                                  : null,
                              onTap: _showLogoSourceDialog,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ── Keamanan Akun & PIN Lokal ────────────────────────────
                      _buildSectionHeader("KEAMANAN AKUN & PIN LOKAL", isDark),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: borderColor, width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildActionTile(
                              icon: Icons.pin_outlined,
                              title: "Atur PIN Keamanan (Offline & Arus Kas)",
                              subtitle: _isPinActive
                                  ? "Status: Aktif (aplikasi & menu dilindungi PIN)"
                                  : "Status: Dinonaktifkan (bebas masuk tanpa PIN)",
                              isDark: isDark,
                              onTap: _showManagePinModal,
                            ),
                            Divider(height: 1, indent: 56, color: borderColor),
                            _buildActionTile(
                              icon: Icons.logout_rounded,
                              title: "Keluar dari Akun",
                              subtitle: "Keluar dari sesi ini dan kembali ke layar login",
                              isDark: isDark,
                              onTap: _confirmSignOut,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ── Danger Zone Section ──────────────────────────────────
                      _buildSectionHeader("ZONA BERBAHAYA", isDark, isDanger: true),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.35),
                            width: 1.2,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.delete_forever_rounded,
                              color: Color(0xFFEF4444),
                              size: 22,
                            ),
                          ),
                          title: Text(
                            "Reset Toko",
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: const Color(0xFFEF4444),
                            ),
                          ),
                          subtitle: Text(
                            "Hapus semua data toko & reset jadi nol (transaksi, produk, pengeluaran, supplier, pelanggan)",
                            style: GoogleFonts.openSans(
                              fontSize: 12,
                              color: isDark ? Colors.white60 : const Color(0xFF64748B),
                            ),
                          ),
                          trailing: const Icon(
                            Icons.chevron_right_rounded,
                            color: Color(0xFFEF4444),
                          ),
                          onTap: _confirmResetStore,
                        ),
                      ),
                      const SizedBox(height: 48),

                      // ── Footer ───────────────────────────────────────────────
                      Center(
                        child: Column(
                          children: [
                            Text(
                              "Developed by",
                              style: GoogleFonts.openSans(
                                fontSize: 11,
                                color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Aditya Maulana  &  Muhammad Parhan",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white54 : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildProfileHeaderCard({
    required bool isDark,
    required Color borderColor,
    required Color cardBg,
    required String? currentLogo,
    required String currentName,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? Colors.black26 : Colors.white,
                  border: Border.all(color: _primaryColor, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: _primaryColor.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: currentLogo != null && currentLogo.isNotEmpty
                      ? Image(
                          image: FileManager().getImageProvider(currentLogo),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.store_rounded,
                            size: 52,
                            color: Colors.grey,
                          ),
                        )
                      : const Icon(
                          Icons.store_rounded,
                          size: 52,
                          color: Colors.grey,
                        ),
                ),
              ),
              Positioned(
                bottom: 2,
                right: 2,
                child: GestureDetector(
                  onTap: _showLogoSourceDialog,
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: _primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            currentName,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              "Profil Toko",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark, {bool isDanger = false}) {
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: isDanger
              ? const Color(0xFFEF4444)
              : (isDark ? Colors.white60 : const Color(0xFF64748B)),
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: _primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: _primaryColor, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : const Color(0xFF0F172A),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.openSans(
          fontSize: 12,
          color: isDark ? Colors.white54 : const Color(0xFF64748B),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null) ...[
            trailing,
            const SizedBox(width: 8),
          ],
          Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: isDark ? Colors.white38 : Colors.grey.shade400,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

