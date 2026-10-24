import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../controllers/admin_controller.dart';
import 'kasir_page.dart';
import 'best_seller_page.dart';
import '../attendance/attendance_page.dart';
import '../admin/history/history_page.dart';
import '../../widgets/kasir_dialog.dart';
import '../../services/activation_service.dart';

class KasirMainPage extends StatefulWidget {
  const KasirMainPage({super.key});

  @override
  State<KasirMainPage> createState() => _KasirMainPageState();
}

class _KasirMainPageState extends State<KasirMainPage> {
  // Page index: 3 = Kasir, 4 = Riwayat, 6 = Best Seller, 13 = Absen
  int _selectedIndex = 3;
  final List<int> _indexHistory = [];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final adminCtrl = Provider.of<AdminController>(context, listen: false);
      if (adminCtrl.isInitializing) {
        adminCtrl.loadInitialData();
      }
    });
  }

  void _onSelectIndex(int index) {
    if (_selectedIndex == index) return;
    _indexHistory.add(_selectedIndex);
    setState(() => _selectedIndex = index);
  }

  bool _handleBackNavigation() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
      return true;
    }
    if (_indexHistory.isNotEmpty) {
      final previous = _indexHistory.removeLast();
      setState(() => _selectedIndex = previous);
      return true;
    }
    if (_selectedIndex != 3) {
      setState(() => _selectedIndex = 3);
      return true;
    }
    return false;
  }

  int _getBottomNavIndex() {
    switch (_selectedIndex) {
      case 3:
        return 0; // Kasir
      case 4:
        return 1; // Riwayat
      case 6:
        return 2; // Best Seller
      case 13:
        return 3; // Absen
      default:
        return 0;
    }
  }

  void _onBottomNavItemTapped(int index) {
    int appIndex;
    switch (index) {
      case 0:
        appIndex = 3; // Kasir
        break;
      case 1:
        appIndex = 4; // Riwayat
        break;
      case 2:
        appIndex = 6; // Best Seller
        break;
      case 3:
        appIndex = 13; // Absen
        break;
      default:
        appIndex = 3;
    }
    HapticFeedback.lightImpact();
    _onSelectIndex(appIndex);
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => KasirDialog(
        title: "Konfirmasi Logout",
        message: "Apakah Anda yakin ingin keluar dari akun kasir?",
        icon: Icons.logout_rounded,
        iconColor: Colors.orangeAccent,
        isDestructive: true,
        primaryActionLabel: "Keluar Sesi",
        onPrimaryAction: () => Navigator.pop(context, true),
        secondaryActionLabel: "Batal",
        onSecondaryAction: () => Navigator.pop(context, false),
      ),
    );

    if (shouldLogout == true && mounted) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('last_route');
      final activationService = ActivationService();
      await activationService.logout();
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminCtrl = context.watch<AdminController>();

    if (adminCtrl.isInitializing) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final handled = _handleBackNavigation();
        if (handled) return;

        final shouldExit = await _showExitConfirmation();
        if (!context.mounted) return;
        if (shouldExit == true) {
          await SystemNavigator.pop();
        }
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;
          final content = _getSelectedPage(adminCtrl);

          return Scaffold(
            key: _scaffoldKey,
            body: isWide
                ? Row(
                    children: [
                      _buildEmployeeWideRail(adminCtrl),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: content,
                        ),
                      ),
                    ],
                  )
                : AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: content,
                  ),
            bottomNavigationBar: isWide ? null : _buildBottomNavBar(),
          );
        },
      ),
    );
  }

  Future<bool> _showExitConfirmation() async {
    final res = await showDialog<bool>(
      context: context,
      builder: (context) => KasirDialog(
        title: "Keluar Aplikasi",
        message: "Apakah Anda yakin ingin menutup dan keluar dari aplikasi Warkop Alam POS?",
        icon: Icons.power_settings_new_rounded,
        iconColor: Colors.redAccent,
        isDestructive: true,
        primaryActionLabel: "Keluar",
        onPrimaryAction: () => Navigator.pop(context, true),
        secondaryActionLabel: "Batal",
        onSecondaryAction: () => Navigator.pop(context, false),
      ),
    );
    return res ?? false;
  }

  Widget _buildBottomNavBar() {
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;
    final currentIndex = _getBottomNavIndex();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 72 + safeAreaBottom,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
            width: 1.0,
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: safeAreaBottom),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              index: 0,
              icon: Icons.calculate_outlined,
              activeIcon: Icons.calculate,
              label: 'Kasir',
              currentIndex: currentIndex,
            ),
            _buildNavItem(
              index: 1,
              icon: Icons.receipt_long_outlined,
              activeIcon: Icons.receipt_long,
              label: 'Riwayat',
              currentIndex: currentIndex,
            ),
            _buildNavItem(
              index: 2,
              icon: Icons.local_fire_department_outlined,
              activeIcon: Icons.local_fire_department_rounded,
              label: 'Best Seller',
              currentIndex: currentIndex,
            ),
            _buildNavItem(
              index: 3,
              icon: Icons.how_to_reg_outlined,
              activeIcon: Icons.how_to_reg_rounded,
              label: 'Absen',
              currentIndex: currentIndex,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int currentIndex,
  }) {
    final isSelected = currentIndex == index;
    const accentColor = Color(0xFFC0392B);
    final color = isSelected ? accentColor : const Color(0xFF94A3B8);

    return GestureDetector(
      onTap: () => _onBottomNavItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 70, minHeight: 65),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Employee Wide Screen Rail (Tablet/Desktop) ─────────────────────────
  Widget _buildEmployeeWideRail(AdminController adminCtrl) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const accentColor = Color(0xFFC0392B);

    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1C1E) : Colors.white,
        border: Border(
          right: BorderSide(
            color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: accentColor.withValues(alpha: 0.15),
                  child: const Icon(Icons.storefront, color: accentColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        adminCtrl.storeName ?? "Kasir Asri",
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        adminCtrl.userName ?? "Staff",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Divider(height: 1),
          const SizedBox(height: 12),
          _buildRailItem(
            index: 3,
            icon: Icons.calculate_outlined,
            activeIcon: Icons.calculate,
            label: "Kasir (POS)",
          ),
          _buildRailItem(
            index: 4,
            icon: Icons.receipt_long_outlined,
            activeIcon: Icons.receipt_long,
            label: "Riwayat Transaksi",
          ),
          _buildRailItem(
            index: 6,
            icon: Icons.local_fire_department_outlined,
            activeIcon: Icons.local_fire_department_rounded,
            label: "Best Seller",
          ),
          _buildRailItem(
            index: 13,
            icon: Icons.how_to_reg_outlined,
            activeIcon: Icons.how_to_reg_rounded,
            label: "Absensi Tim",
          ),
          const Spacer(),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 22),
            title: Text(
              "Logout",
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Colors.redAccent,
              ),
            ),
            onTap: _handleLogout,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildRailItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isSelected = _selectedIndex == index;
    const accentColor = Color(0xFFC0392B);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? accentColor.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(
          isSelected ? activeIcon : icon,
          color: isSelected ? accentColor : Colors.grey.shade600,
          size: 22,
        ),
        title: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
            color: isSelected ? accentColor : null,
          ),
        ),
        onTap: () => _onSelectIndex(index),
      ),
    );
  }

  Widget _getSelectedPage(AdminController ctrl) {
    void onMenuPressed() {}

    switch (_selectedIndex) {
      case 4:
        return HistoryPage(
          storeId: ctrl.storeId,
          showSidebar: false,
          onBack: _handleBackNavigation,
        );
      case 6:
        return BestSellerPage(onBack: _handleBackNavigation);
      case 13:
        return AttendancePage(
          showSidebar: false,
          onMenuPressed: onMenuPressed,
          onBack: _handleBackNavigation,
        );
      case 3:
      default:
        return KasirPage(
          showSidebar: false,
          onMenuPressed: onMenuPressed,
          onNavigateToIndex: (index) => _onSelectIndex(index),
        );
    }
  }
}
