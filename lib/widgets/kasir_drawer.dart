import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/platform/file_manager.dart';
import '../controllers/theme_controller.dart';
import '../pages/other/printer_settings_page.dart';
import 'package:provider/provider.dart';
import '../controllers/admin_controller.dart';
import '../pages/admin/inventory_page.dart';
import '../pages/admin/category_page.dart';
import '../pages/admin/report/profit_loss_page.dart';
import '../pages/admin/customer_page.dart';
import '../pages/admin/promotion_page.dart';
import '../controllers/settings_controller.dart';
import 'kasir_dialog.dart';
import '../services/activation_service.dart';

class KasirDrawer extends StatefulWidget {
  final String currentRoute;
  final Function(int)? onIndexSelected;

  const KasirDrawer({
    super.key,
    required this.currentRoute,
    this.onIndexSelected,
  });

  @override
  State<KasirDrawer> createState() => _KasirDrawerState();
}

class _KasirDrawerState extends State<KasirDrawer> {
  Future<void> _updateName() async {
    final adminCtrl = context.read<AdminController>();
    final controller = TextEditingController(text: adminCtrl.userName);

    await showDialog(
      context: context,
      builder: (ctx) => KasirDialog(
        title: "Ubah Nama",
        icon: Icons.edit_rounded,
        iconColor: const Color(0xFF00BF63),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: "Nama Lengkap",
              filled: true,
              fillColor: Theme.of(ctx).brightness == Brightness.dark
                  ? const Color(0xFF2C2C2E)
                  : const Color(0xFFF2F2F7),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
        primaryActionLabel: "Simpan",
        onPrimaryAction: () async {
          Navigator.pop(ctx);
          final newName = controller.text.trim();
          if (newName.isNotEmpty) {
            await adminCtrl.updateProfile(name: newName);
          }
        },
        secondaryActionLabel: "Batal",
        onSecondaryAction: () => Navigator.pop(ctx),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeController.instance.isDarkMode;
    final bgColor = isDark ? const Color(0xFF1A1C1E) : Colors.white;
    const accentColor = Color(0xFF00BF63);

    final adminCtrl = context.watch<AdminController>();
    final role = adminCtrl.role;

    return Drawer(
      backgroundColor: bgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(0)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildModernHeader(isDark, adminCtrl),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                children: [
                  _buildSectionTitle(
                    SettingsController.instance.getString('navigation'),
                  ),
                  _buildModernItem(
                    icon: Icons.account_circle_outlined,
                    label: "Profil Saya",
                    isSelected: widget.currentRoute == '/profile',
                    accentColor: accentColor,
                    itemColor: const Color(0xFF3498DB),
                    onTap: () {
                      Navigator.pop(context);
                      if (widget.onIndexSelected != null) {
                        widget.onIndexSelected!(8);
                      } else if (widget.currentRoute != '/profile') {
                        Navigator.pushReplacementNamed(context, '/profile');
                      }
                    },
                  ),
                  if (_hasPerm(adminCtrl, 'pos_access'))
                    _buildModernItem(
                      icon: Icons.home_outlined,
                      label: SettingsController.instance.getString('beranda'),
                      isSelected: widget.currentRoute == '/kasir',
                      accentColor: accentColor,
                      itemColor: const Color(0xFF00BF63),
                      onTap: () {
                        Navigator.pop(context);
                        if (widget.onIndexSelected != null) {
                          widget.onIndexSelected!(3);
                        } else if (widget.currentRoute != '/kasir') {
                          Navigator.pushReplacementNamed(context, '/kasir');
                        }
                      },
                    ),
                  if (_hasPerm(adminCtrl, 'manage_inventory'))
                    _buildModernItem(
                      icon: Icons.inventory_2_outlined,
                      label: SettingsController.instance.getString(
                        'nav_inventory',
                      ),
                      isSelected: widget.currentRoute == '/inventory',
                      accentColor: accentColor,
                      itemColor: const Color(0xFF2ECC71),
                      onTap: () {
                        Navigator.pop(context);
                        if (widget.onIndexSelected != null) {
                          widget.onIndexSelected!(1);
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (ctx) => InventoryPage(
                                onNavigateToCategories: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (ctx) => CategoryPage(
                                        storeId: adminCtrl.storeId!,
                                        onNavigateToProducts: () {
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                              builder: (ctx) => const InventoryPage(),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  if (_hasPerm(adminCtrl, 'manage_categories'))
                    _buildModernItem(
                      icon: Icons.label_outlined,
                      label: SettingsController.instance.getString(
                        'nav_category',
                      ),
                      isSelected: widget.currentRoute == '/categories',
                      accentColor: accentColor,
                      itemColor: const Color(0xFF9B59B6),
                      onTap: () {
                        Navigator.pop(context);
                        if (widget.onIndexSelected != null) {
                          widget.onIndexSelected!(2);
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (ctx) => CategoryPage(
                                storeId: adminCtrl.storeId!,
                                onNavigateToProducts: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (ctx) => InventoryPage(
                                        onNavigateToCategories: () {
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                              builder: (ctx) => CategoryPage(
                                                storeId: adminCtrl.storeId!,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  _buildModernItem(
                    icon: Icons.schedule_outlined,
                    label: SettingsController.instance.getString('absen_staff'),
                    isSelected: widget.currentRoute == '/attendance',
                    accentColor: accentColor,
                    itemColor: const Color(0xFFE91E63),
                    onTap: () {
                      Navigator.pop(context);
                      if (widget.onIndexSelected != null) {
                        widget.onIndexSelected!(13);
                      } else if (widget.currentRoute != '/attendance') {
                        Navigator.pushReplacementNamed(context, '/attendance');
                      }
                    },
                  ),
                  if (_hasPerm(adminCtrl, 'view_history'))
                    _buildModernItem(
                      icon: Icons.description_outlined,
                      label: SettingsController.instance.getString(
                        'nav_history',
                      ),
                      isSelected: widget.currentRoute == '/order-history',
                      accentColor: accentColor,
                      itemColor: const Color(0xFF1ABC9C),
                      onTap: () {
                        Navigator.pop(context);
                        if (widget.onIndexSelected != null) {
                          widget.onIndexSelected!(4);
                        } else {
                          Navigator.pushReplacementNamed(
                            context,
                            '/order-history',
                          );
                        }
                      },
                    ),
                  if (_hasPerm(adminCtrl, 'view_reports'))
                    _buildModernItem(
                      icon: Icons.bar_chart_outlined,
                      label: SettingsController.instance.getString(
                        'nav_profit_loss',
                      ),
                      isSelected: widget.currentRoute == '/profit-loss',
                      accentColor: accentColor,
                      itemColor: const Color(0xFF6C5CE7),
                      onTap: () {
                        Navigator.pop(context);
                        if (widget.onIndexSelected != null) {
                          widget.onIndexSelected!(11);
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (ctx) =>
                                  ProfitLossPage(storeId: adminCtrl.storeId!),
                            ),
                          );
                        }
                      },
                    ),
                  ValueListenableBuilder<bool>(
                    valueListenable: SettingsController.instance.featureLoyaltyEnabled,
                    builder: (context, loyaltyEnabled, _) {
                      if (!loyaltyEnabled || !_hasPerm(adminCtrl, 'manage_customers')) {
                        return const SizedBox.shrink();
                      }
                      return _buildModernItem(
                        icon: Icons.people_outline_rounded,
                        label: "Loyalty Pelanggan",
                        isSelected: widget.currentRoute == '/customers',
                        accentColor: accentColor,
                        itemColor: const Color(0xFFF1C40F),
                        onTap: () {
                          Navigator.pop(context);
                          if (widget.onIndexSelected != null) {
                            widget.onIndexSelected!(12);
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (ctx) => const CustomerPage(),
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
                  if (_hasPerm(adminCtrl, 'manage_promotions'))
                    _buildModernItem(
                      icon: Icons.discount_outlined,
                      label: "Promosi & Diskon",
                      isSelected: widget.currentRoute == '/promotions',
                      accentColor: accentColor,
                      itemColor: const Color(0xFFD63031),
                      onTap: () {
                        Navigator.pop(context);
                        if (widget.onIndexSelected != null) {
                          widget.onIndexSelected!(9);
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (ctx) => const PromotionPage(),
                            ),
                          );
                        }
                      },
                    ),
                  if (_hasPerm(adminCtrl, 'manage_printer'))
                    _buildModernItem(
                      icon: Icons.print_outlined,
                      label: SettingsController.instance.getString(
                        'nav_printer',
                      ),
                      isSelected: widget.currentRoute == '/printer-settings',
                      accentColor: accentColor,
                      itemColor: const Color(0xFF636E72),
                      onTap: () {
                        Navigator.pop(context);
                        if (widget.onIndexSelected != null) {
                          widget.onIndexSelected!(7);
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (ctx) => const PrinterSettingsPage(),
                            ),
                          );
                        }
                      },
                    ),
                  if (role == 'admin' || role == 'owner') ...[
                    _buildSectionTitle(
                      SettingsController.instance.getString('administration'),
                    ),
                    _buildModernItem(
                      icon: Icons.security_rounded,
                      label: SettingsController.instance.getString(
                        'admin_panel',
                      ),
                      isSelected: false,
                      accentColor: Colors.blue,
                      itemColor: const Color(0xFF00BCD4),
                      isSpecial: true,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushReplacementNamed(context, '/admin');
                      },
                    ),
                  ],
                ],
              ),
            ),
            _buildThemeToggle(isDark, accentColor),
            _buildFooter(isDark),
          ],
        ),
      ),
    );
  }

  bool _hasPerm(AdminController ctrl, String key) {
    if (ctrl.role == 'admin' || ctrl.role == 'owner') return true;
    final perms = ctrl.permissions;
    if (perms == null) return false;
    return perms[key] == true;
  }

  Widget _buildModernHeader(bool isDark, AdminController adminCtrl) {
    final avatarUrl = adminCtrl.storeLogo ?? adminCtrl.profileUrl;
    final fullName = adminCtrl.userName ?? "Kasir";

    // A slightly different style for Kasir active user
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.grey[50],
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white10 : Colors.grey[200]!,
          ),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: (adminCtrl.storeLogo != null && adminCtrl.storeLogo!.isNotEmpty)
                ? Image(
                    image: FileManager().getImageProvider(adminCtrl.storeLogo!),
                    height: 44,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Image.asset(
                      'assets/logo/logo.png',
                      height: 44,
                      fit: BoxFit.contain,
                    ),
                  )
                : Image.asset(
                    'assets/logo/logo.png',
                    height: 44,
                    fit: BoxFit.contain,
                  ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              if (widget.onIndexSelected != null) {
                widget.onIndexSelected!(4);
              }
            },
            child: Stack(
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF00BF63),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                    image: avatarUrl != null
                        ? DecorationImage(
                            image: FileManager().getImageProvider(avatarUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                    color: isDark ? Colors.grey[800] : Colors.white,
                  ),
                  child: avatarUrl == null
                      ? Icon(
                          Icons.person_rounded,
                          size: 40,
                          color: isDark ? Colors.white38 : Colors.grey[400],
                        )
                      : null,
                ),

                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFF00BF63),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                fullName,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _updateName,
                child: Icon(
                  Icons.edit_outlined,
                  size: 16,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF00BF63).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "POS TERMINAL",
              style: GoogleFonts.openSans(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF00BF63),
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
      child: Text(
        title,
        style: GoogleFonts.openSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.grey[400],
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildModernItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color accentColor,
    Color? itemColor,
    bool isSpecial = false,
  }) {
    final isDark = ThemeController.instance.isDarkMode;
    final baseColor = itemColor ?? (isSpecial ? Colors.blue : accentColor);
    final activeBg = baseColor.withValues(alpha: 0.1);
    final textColor = isSelected
        ? baseColor
        : (isDark ? Colors.white70 : const Color(0xFF2D3436));
    final iconColor = isSelected
        ? baseColor
        : (isDark ? Colors.white54 : Colors.grey[500]);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? activeBg : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(icon, size: 22, color: iconColor),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.openSans(
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: baseColor,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeToggle(bool isDark, Color accentColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(
            isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
            color: isDark ? Colors.white70 : Colors.grey[700],
            size: 20,
          ),
          const SizedBox(width: 16),
          Text(
            isDark ? "Dark Mode" : "Light Mode",
            style: GoogleFonts.openSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : Colors.grey[800],
            ),
          ),
          const Spacer(),
          CupertinoSwitch(
            value: isDark,
            activeTrackColor: accentColor,
            onChanged: (val) {
              ThemeController.instance.toggleTheme();
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: InkWell(
        onTap: () async {
          final shouldLogout = await showDialog<bool>(
            context: context,
            builder: (context) => KasirDialog(
              title: "Konfirmasi Logout",
              message: "Apakah Anda yakin ingin keluar dari akun ini?",
              icon: Icons.logout_rounded,
              iconColor: Colors.redAccent,
              isDestructive: true,
              primaryActionLabel: "Keluar Sesi",
              onPrimaryAction: () => Navigator.pop(context, true),
              secondaryActionLabel: "Batal",
              onSecondaryAction: () => Navigator.pop(context, false),
            ),
          );

          if (shouldLogout == true) {
            final activationService = ActivationService();
            await activationService.logout();
            if (!mounted) return;
            Navigator.pushNamedAndRemoveUntil(context, '/activation', (route) => false);
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.withValues(alpha: 0.1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.power_settings_new_rounded, color: Colors.red, size: 20),
              const SizedBox(width: 12),
              Text(
                SettingsController.instance.getString('logout_app'),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

