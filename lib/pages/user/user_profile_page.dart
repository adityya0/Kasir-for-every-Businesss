import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import '../../controllers/admin_controller.dart';
import '../../services/platform/file_manager.dart';
import '../../widgets/kasir_drawer.dart';

class UserProfilePage extends StatefulWidget {
  final VoidCallback? onMenuPressed;
  final bool showSidebar;
  final VoidCallback? onBack;
  const UserProfilePage({
    super.key,
    this.onMenuPressed,
    this.showSidebar = true,
    this.onBack,
  });

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  bool _isLoading = false;

  void _showAvatarSourceDialog() {
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
              "Ganti Foto Profil",
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
                    _pickAvatar(ImageSource.camera);
                  },
                ),
                _buildSourceOption(
                  icon: Icons.photo_library_rounded,
                  label: "Galeri",
                  onTap: () {
                    Navigator.pop(context);
                    _pickAvatar(ImageSource.gallery);
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
    const primaryColor = Color(0xFF00BF63);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: primaryColor, size: 30),
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

  Future<void> _pickAvatar(ImageSource source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: source,
      imageQuality: 70,
    );
    if (image == null) return;
    if (!mounted) return;

    setState(() => _isLoading = true);
    try {
      final adminCtrl = context.read<AdminController>();
      final userId = adminCtrl.userId;

      final fileName =
          'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}${p.extension(image.path)}';
      final savedPath = await FileManager().saveFile(image, fileName);

      await adminCtrl.updateProfile(avatarUrl: savedPath);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Foto profil diperbarui!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint("Update Avatar Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal memperbarui foto: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _editName() async {
    final adminCtrl = context.read<AdminController>();
    final controller = TextEditingController(text: adminCtrl.userName);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Ubah Nama",
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: GoogleFonts.openSans(
            color: isDark ? Colors.white : Colors.black87,
          ),
          decoration: InputDecoration(
            hintText: "Nama Lengkap",
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
              backgroundColor: const Color(0xFF00BF63),
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
        await adminCtrl.updateProfile(name: newName);
      } catch (e) {
        debugPrint("Update Name Error: $e");
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminCtrl = context.watch<AdminController>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const primaryColor = Color(0xFF00BF63);

    final content = LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 720;
        final double horizontalPadding = isWide
            ? (constraints.maxWidth - 600) / 2
            : 20;

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 24,
          ),
          child: Column(
            children: [
              _buildProfileCard(isDark, adminCtrl, primaryColor),
              const SizedBox(height: 24),
              _buildPermissionsCard(isDark, adminCtrl, primaryColor),
              const SizedBox(height: 40),
              Text(
                "Ver 1.0.0 • PosKasirBersama",
                style: GoogleFonts.openSans(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
        );
      },
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: widget.showSidebar
          ? const KasirDrawer(currentRoute: '/profile')
          : null,
      appBar: AppBar(
        title: Text(
          "Profil Saya",
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF2D3436),
          ),
        ),
        centerTitle: true,
        leading: Builder(
          builder: (ctx) {
            final isWide = MediaQuery.of(ctx).size.width >= 720;
            if (isWide) return const SizedBox.shrink();
            if (widget.onBack != null) {
              return IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: isDark ? Colors.white : const Color(0xFF2D3436),
                ),
                onPressed: widget.onBack,
                tooltip: 'Kembali',
              );
            }
            if (Navigator.canPop(context)) {
              return IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: isDark ? Colors.white : const Color(0xFF2D3436),
                ),
                onPressed: () => Navigator.pop(context),
              );
            }
            return IconButton(
              icon: Icon(
                Icons.menu_rounded,
                color: isDark ? Colors.white : const Color(0xFF2D3436),
              ),
              onPressed: widget.onMenuPressed ??
                  () => Scaffold.of(ctx).openDrawer(),
            );
          },
        ),
      ),
      body: content,
    );
  }

  Widget _buildProfileCard(
    bool isDark,
    AdminController adminCtrl,
    Color primaryColor,
  ) {
    final avatarUrl = adminCtrl.profileUrl;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: _showAvatarSourceDialog,
            child: Stack(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: primaryColor, width: 3),
                    image: avatarUrl != null
                        ? DecorationImage(
                            image: FileManager().getImageProvider(avatarUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                    color: isDark ? Colors.grey[800] : Colors.grey[100],
                  ),
                  child: avatarUrl == null
                      ? Icon(
                          Icons.person,
                          size: 60,
                          color: isDark ? Colors.white24 : Colors.grey[400],
                        )
                      : null,
                ),
                if (_isLoading)
                  const Positioned.fill(
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  adminCtrl.userName ?? "Kasir",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _editName,
                icon: Icon(
                  Icons.edit,
                  color: primaryColor.withValues(alpha: 0.8),
                  size: 24,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          Text(
            adminCtrl.role?.toUpperCase() ?? "STAFF",
            style: GoogleFonts.openSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: primaryColor,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 32),
          _buildInfoRow(
            Icons.home,
            "Toko",
            adminCtrl.storeName ?? "-",
            isDark,
          ),
          const Divider(height: 32),
          _buildInfoRow(
            Icons.email_outlined,
            "Email Login",
            adminCtrl.userEmail ?? "-",
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[500]),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.openSans(fontSize: 12, color: Colors.grey[500]),
              ),
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionsCard(
    bool isDark,
    AdminController adminCtrl,
    Color primaryColor,
  ) {
    final perms = adminCtrl.permissions ?? {};
    final bool isOwner = adminCtrl.role == 'owner' || adminCtrl.role == 'admin';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Hak Akses Fitur",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          if (isOwner)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.security,
                    color: Colors.blue,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Anda memiliki akses penuh sebagai Owner/Admin.",
                      style: GoogleFonts.openSans(
                        fontSize: 13,
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildPermissionChip("POS Access", perms['pos_access'] == true),
                _buildPermissionChip(
                  "Inventory",
                  perms['manage_inventory'] == true,
                ),
                _buildPermissionChip(
                  "Categories",
                  perms['manage_categories'] == true,
                ),
                _buildPermissionChip("History", perms['view_history'] == true),
                _buildPermissionChip("Reports", perms['view_reports'] == true),
                _buildPermissionChip(
                  "Printer",
                  perms['manage_printer'] == true,
                ),
                _buildPermissionChip(
                  "Promotions",
                  perms['manage_promotions'] == true,
                ),
                _buildPermissionChip(
                  "Customers",
                  perms['manage_customers'] == true,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildPermissionChip(String label, bool granted) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: granted
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.red.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: granted
              ? Colors.green.withValues(alpha: 0.2)
              : Colors.red.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            granted
                ? Icons.check_circle
                : Icons.cancel,
            size: 14,
            color: granted ? Colors.green : Colors.red[300],
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.openSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: granted ? Colors.green[700] : Colors.red[300],
            ),
          ),
        ],
      ),
    );
  }
}

