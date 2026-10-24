import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../../services/platform/file_manager.dart';
import '../../../controllers/admin_controller.dart';
import '../../../controllers/settings_controller.dart';

class KasirSideNavigation extends StatelessWidget {
  final int selectedIndex;
  final Function(int)? onIndexSelected;
  final String? currentRoute;

  const KasirSideNavigation({
    super.key,
    this.selectedIndex = 3,
    this.onIndexSelected,
    this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1C1E) : Colors.white;
    const accentColor = Color(0xFFC0392B);
    final adminCtrl = context.watch<AdminController>();
    final settings = SettingsController.instance;

    int effectiveIndex = selectedIndex;
    if (currentRoute != null) {
      switch (currentRoute) {
        case '/inventory':
          effectiveIndex = 1;
          break;
        case '/categories':
          effectiveIndex = 2;
          break;
        case '/kasir':
          effectiveIndex = 3;
          break;
        case '/order-history':
          effectiveIndex = 4;
          break;
        case '/printer-settings':
          effectiveIndex = 7;
          break;
        case '/profile':
          effectiveIndex = 8;
          break;
        case '/promotions':
          effectiveIndex = 9;
          break;
        case '/profit-loss':
          effectiveIndex = 11;
          break;
        case '/customers':
          effectiveIndex = 12;
          break;
        case '/attendance':
          effectiveIndex = 13;
          break;
      }
    }

    return ValueListenableBuilder<bool>(
      valueListenable: settings.isSidebarExpanded,
      builder: (context, isExpanded, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          width: isExpanded ? 210 : 72,
          height: double.infinity,
          decoration: BoxDecoration(
            color: bgColor,
            border: Border(
              right: BorderSide(
                color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06),
                width: 1,
              ),
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: Column(
              children: [
                const SizedBox(height: 16),
                // Header: User Profile & Toggle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: isExpanded
                      ? SizedBox(
                        width: 210 - 24, // Width minus padding
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildProfileAvatar(adminCtrl, effectiveIndex),
                            const SizedBox(width: 8),
                            Expanded(child: _buildNameRole(context, isDark, accentColor, adminCtrl)),
                            _buildToggleButton(settings, isExpanded, accentColor),
                          ],
                        ),
                      )
                      : Column(
                        children: [
                          _buildProfileAvatar(adminCtrl, effectiveIndex),
                          const SizedBox(height: 12),
                          _buildToggleButton(settings, isExpanded, accentColor),
                        ],
                      ),
                ),
                const SizedBox(height: 24),

                // Navigation Items
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      _buildRailItem(
                        context: context,
                        index: 3,
                        icon: effectiveIndex == 3 ? Icons.calculate : Icons.calculate_outlined,
                        label: "Kasir",
                        isActive: effectiveIndex == 3,
                        activeColor: accentColor,
                        isExpanded: isExpanded,
                      ),
                      _buildRailItem(
                        context: context,
                        index: 11,
                        icon: effectiveIndex == 11 ? Icons.account_balance_wallet : Icons.account_balance_wallet_outlined,
                        label: "Uang",
                        isActive: effectiveIndex == 11,
                        activeColor: accentColor,
                        isExpanded: isExpanded,
                      ),
                      _buildRailItem(
                        context: context,
                        index: 4,
                        icon: Icons.trending_up,
                        label: "Tren",
                        isActive: effectiveIndex == 4,
                        activeColor: accentColor,
                        isExpanded: isExpanded,
                      ),
                      _buildRailItem(
                        context: context,
                        index: 9,
                        icon: effectiveIndex == 9 ? Icons.bolt : Icons.bolt_outlined,
                        label: "Aksi",
                        isActive: effectiveIndex == 9,
                        activeColor: accentColor,
                        isExpanded: isExpanded,
                      ),
                      _buildRailItem(
                        context: context,
                        index: 15,
                        icon: effectiveIndex == 15 ? Icons.settings : Icons.settings_outlined,
                        label: "Pengaturan",
                        isActive: effectiveIndex == 15,
                        activeColor: accentColor,
                        isExpanded: isExpanded,
                      ),
                    ],
                  ),
                ),

                // Bottom Actions
                const Divider(indent: 12, endIndent: 12, height: 1),
                _buildRailItem(
                  context: context,
                  index: null, // Logout handled differently
                  icon: Icons.logout_rounded,
                  label: "Logout",
                  isActive: false,
                  activeColor: Colors.red,
                  isExpanded: isExpanded,
                  onTap: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.remove('last_route');
                    if (context.mounted) {
                      Navigator.pushReplacementNamed(context, '/login');
                    }
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRailItem({
    required BuildContext context,
    required int? index,
    required IconData icon,
    required String label,
    required bool isActive,
    required Color activeColor,
    required bool isExpanded,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Tooltip(
        message: !isExpanded ? label : "",
        child: InkWell(
          onTap: onTap ?? () => onIndexSelected?.call(index!),
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              horizontal: isExpanded ? 12 : 0,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color:
                  isActive
                      ? activeColor.withValues(alpha: 0.12)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment:
                  isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color:
                      isActive
                          ? activeColor
                          : (isDark ? Colors.white54 : Colors.black38),
                  size: 20,
                ),
                if (isExpanded) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                        color:
                            isActive
                                ? activeColor
                                : (isDark ? Colors.white70 : Colors.black87),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(AdminController adminCtrl, int effectiveIndex) {
    const accentColor = Color(0xFFC0392B);
    return GestureDetector(
      onTap: () => onIndexSelected?.call(8),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(
            color: effectiveIndex == 8
                ? accentColor
                : accentColor.withValues(alpha: 0.1),
            width: 1.5,
          ),
          image: adminCtrl.profileUrl != null
              ? DecorationImage(
                  image: FileManager().getImageProvider(adminCtrl.profileUrl!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: adminCtrl.profileUrl == null
            ? Icon(
                Icons.person,
                color: effectiveIndex == 8 ? accentColor : Colors.grey[400],
                size: 18,
              )
            : null,
      ),
    );
  }

  Widget _buildNameRole(BuildContext context, bool isDark, Color accentColor,
      AdminController adminCtrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          adminCtrl.userName ?? 'User',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: isDark ? Colors.white : Colors.black87,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          adminCtrl.role?.toUpperCase() ?? 'STAFF',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w500,
            fontSize: 10,
            color: accentColor,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildToggleButton(
      SettingsController settings, bool isExpanded, Color accentColor) {
    return IconButton(
      constraints: const BoxConstraints(),
      padding: EdgeInsets.zero,
      icon: Icon(
        isExpanded ? Icons.menu_open : Icons.menu,
        color: accentColor.withValues(alpha: 0.6),
        size: 20,
      ),
      onPressed: () => settings.toggleSidebar(),
    );
  }

}

