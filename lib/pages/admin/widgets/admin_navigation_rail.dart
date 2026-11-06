import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../controllers/settings_controller.dart';
import '../../../services/platform/file_manager.dart';

class AdminNavigationRail extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onDestinationSelected;
  final String? storeLogo;
  final VoidCallback onLogout;
  final VoidCallback? onProfileTap;
  final VoidCallback? onCustomerTap;
  final String? userName;
  final String? storeName;
  final String? role;
  final Map<String, dynamic>? permissions;

  const AdminNavigationRail({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.storeLogo,
    required this.onLogout,
    this.onProfileTap,
    this.onCustomerTap,
    this.userName,
    this.storeName,
    this.role,
    this.permissions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1C1E) : Colors.white;
    const accentColor = Color(0xFF00BF63); // Brand sage green
    final settings = SettingsController.instance;

    return ValueListenableBuilder<bool>(
      valueListenable: settings.isSidebarExpanded,
      builder: (context, isExpanded, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          width: isExpanded ? 210 : 72,
          height: double.infinity,
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.zero,
            border: Border(
              right: BorderSide(
                color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E7EB),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(2, 0),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: Column(
              children: [
                const SizedBox(height: 16),
                // Header: Logo and Toggle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: isExpanded
                      ? SizedBox(
                          width: 210 - 32, // Width minus padding
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildLogo(context, accentColor, storeLogo),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildNameRole(
                                  context, 
                                  isDark, 
                                  accentColor, 
                                  storeName, 
                                  role
                                ),
                              ),
                              _buildToggleButton(settings, isExpanded, accentColor),
                            ],
                          ),
                        )
                      : Column(
                        children: [
                          _buildLogo(context, accentColor, storeLogo),
                          const SizedBox(height: 12),
                          _buildToggleButton(settings, isExpanded, accentColor),
                        ],
                      ),
                ),
                const SizedBox(height: 24),

                // Navigation Items
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      _buildRailItem(
                        context: context,
                        index: 3,
                        icon: (selectedIndex == 3 || selectedIndex == 0) ? Icons.calculate : Icons.calculate_outlined,
                        label: "Kasir",
                        isActive: selectedIndex == 3 || selectedIndex == 0,
                        activeColor: accentColor,
                        isExpanded: isExpanded,
                      ),
                      _buildRailItem(
                        context: context,
                        index: 11,
                        icon: selectedIndex == 11 ? Icons.account_balance_wallet : Icons.account_balance_wallet_outlined,
                        label: "Uang",
                        isActive: selectedIndex == 11,
                        activeColor: accentColor,
                        isExpanded: isExpanded,
                      ),
                      _buildRailItem(
                        context: context,
                        index: 26,
                        icon: selectedIndex == 26 ? Icons.payments : Icons.payments_outlined,
                        label: "Keuangan",
                        isActive: selectedIndex == 26,
                        activeColor: accentColor,
                        isExpanded: isExpanded,
                      ),
                      _buildRailItem(
                        context: context,
                        index: 12,
                        icon: (selectedIndex == 12 || selectedIndex == 13) ? Icons.people_rounded : Icons.people_outline_rounded,
                        label: "Kontak",
                        isActive: selectedIndex == 12 || selectedIndex == 13,
                        activeColor: accentColor,
                        isExpanded: isExpanded,
                      ),
                      _buildRailItem(
                        context: context,
                        index: 1,
                        icon: (selectedIndex == 1 || selectedIndex == 2 || selectedIndex == 6) ? Icons.inventory_2 : Icons.inventory_2_outlined,
                        label: "Produk",
                        isActive: selectedIndex == 1 || selectedIndex == 2 || selectedIndex == 6,
                        activeColor: accentColor,
                        isExpanded: isExpanded,
                      ),
                      _buildRailItem(
                        context: context,
                        index: 15,
                        icon: selectedIndex == 15 ? Icons.settings : Icons.settings_outlined,
                        label: "Pengaturan",
                        isActive: selectedIndex == 15,
                        activeColor: accentColor,
                        isExpanded: isExpanded,
                      ),
                    ],
                  ),
                ),

                // Logout Button
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: _buildRailItem(
                    context: context,
                    index: -1, // Special index for logout
                    icon: Icons.logout_rounded,
                    label: "Keluar",
                    isActive: false,
                    activeColor: Colors.red,
                    isExpanded: isExpanded,
                    onTap: onLogout,
                  ),
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
    required int index,
    required IconData icon,
    required String label,
    required bool isActive,
    required Color activeColor,
    required bool isExpanded,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Tooltip(
        message: !isExpanded ? label : "",
        child: InkWell(
          onTap: onTap ?? () => onDestinationSelected(index),
          borderRadius: BorderRadius.zero,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              horizontal: isExpanded ? 20 : 0,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color:
                  isActive
                      ? activeColor.withValues(alpha: 0.12)
                      : Colors.transparent,
              borderRadius: BorderRadius.zero,
              border: isActive
                  ? Border(
                      left: BorderSide(
                        color: activeColor,
                        width: 4,
                      ),
                    )
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
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
                  Flexible(
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

  Widget _buildLogo(BuildContext context, Color accentColor, String? storeLogo) {
    Widget imageWidget;
    if (storeLogo != null && storeLogo.isNotEmpty) {
      if (storeLogo.startsWith('http://') || storeLogo.startsWith('https://')) {
        imageWidget = Image.network(
          storeLogo,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Image.asset('assets/logo/logo_icon.png', fit: BoxFit.cover),
        );
      } else if (storeLogo.startsWith('assets/')) {
        imageWidget = Image.asset(
          storeLogo,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Image.asset('assets/logo/logo_icon.png', fit: BoxFit.cover),
        );
      } else {
        imageWidget = Image(
          image: FileManager().getImageProvider(storeLogo),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Image.asset('assets/logo/logo_icon.png', fit: BoxFit.cover),
        );
      }
    } else {
      imageWidget = Image.asset(
        'assets/logo/logo_icon.png',
        fit: BoxFit.cover,
      );
    }

    return GestureDetector(
      onTap: onProfileTap ?? () => onDestinationSelected(8),
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
            color: accentColor.withValues(alpha: 0.1),
            width: 1.5,
          ),
        ),
        child: ClipOval(child: imageWidget),
      ),
    );
  }

  Widget _buildNameRole(BuildContext context, bool isDark, Color accentColor,
      String? storeName, String? role) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          storeName ?? 'Tokoku',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: isDark ? Colors.white : Colors.black87,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          role ?? '-',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            color: isDark ? Colors.white54 : Colors.black54,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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