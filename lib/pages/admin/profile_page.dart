import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import '../../services/platform/file_manager.dart';

import 'package:provider/provider.dart';
import '../../controllers/admin_controller.dart';
import '../../services/app_database.dart';

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

  final Color _primaryColor = const Color(0xFFC0392B);

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
      if (mounted) {
        setState(() {
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
            hintText: "Nama Toko (Contoh: Warkop Alam POS)",
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
        setState(() => _storeName = newName);
      } catch (e) {
        debugPrint("Update Store Name Error: $e");
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _confirmResetStore() async {
    final controller = TextEditingController();
    bool deleteProducts = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                "RESET TOKO?",
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Tindakan ini akan MENGHAPUS SEMUA RIWAYAT PENJUALAN dan LAPORAN. Data yang dihapus tidak dapat dikembalikan.",
                    style: GoogleFonts.openSans(fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    value: deleteProducts,
                    onChanged: (val) => setState(() => deleteProducts = val!),
                    title: Text(
                      "Hapus juga semua produk?",
                      style: GoogleFonts.openSans(fontSize: 13),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      labelText: 'Ketik "RESET" untuk konfirmasi',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Batal"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () {
                    Navigator.pop(context, controller.text);
                  },
                  child: const Text(
                    "HAPUS DATA",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    ).then((result) async {
      if (result == "RESET") {
        if (!mounted) return;
        setState(() => _isLoading = true);
        try {
          final adminCtrl = context.read<AdminController>();
          await adminCtrl.resetStore(deleteProducts: deleteProducts);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Toko berhasil di-reset."),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
            );
          }
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      }
    });
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
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFC0392B)))
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
                            "Hapus semua riwayat transaksi & reset stok produk kembali ke awal",
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

