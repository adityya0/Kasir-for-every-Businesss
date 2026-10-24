import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../user/kasir_page.dart';
import 'package:flutter/cupertino.dart';
import 'category_page.dart';
import 'inventory_page.dart';
import 'profile_page.dart';
import 'employee/employee_management_page.dart';
import '../attendance/attendance_page.dart';
import 'history/history_page.dart';
import '../other/printer_settings_page.dart';
import 'promotion_page.dart';
import 'action_menu_page.dart';
import 'data_management_page.dart';
import 'report/profit_loss_page.dart';
import 'customer_page.dart';
import 'trends_page.dart';
import 'transaction_settings_page.dart';
import 'widgets/admin_navigation_rail.dart';

import 'package:google_fonts/google_fonts.dart';

import 'package:provider/provider.dart';
import '../../controllers/admin_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../controllers/analytics_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'backup_restore_page.dart';
import '../other/terms_conditions_page.dart';
import '../../widgets/kasir_dialog.dart';
import '../../services/activation_service.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  int _selectedIndex = 3; // Default to Kasir
  final List<int> _indexHistory = [];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

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
      setState(() => _selectedIndex = 9);
      return true;
    }
    return false;
  }

  int _getBottomNavIndex() {
    switch (_selectedIndex) {
      case 3:
      case 0:
        return 0; // Kasir
      case 11:
      case 14:
      case 5:
      case 16:
        return 1; // Uang (termasuk Pegawai / Absensi dari pintasan uang)
      case 4:
      case 6:
        return 2; // Tren
      case 9:
      case 17:
      case 2:
      case 10:
        return 3; // Aksi
      case 15:
      case 7:
      case 8:
      case 18:
      case 19:
      case 20:
        return 4; // Pengaturan
      default:
        return 0; // Default to Kasir
    }
  }

  void _onBottomNavItemTapped(int index) {
    int appIndex;
    switch (index) {
      case 0:
        appIndex = 3; // Kasir
        break;
      case 1:
        appIndex = 11; // Uang
        break;
      case 2:
        appIndex = 6; // Tren
        break;
      case 3:
        appIndex = 9; // Aksi
        break;
      case 4:
        appIndex = 15; // Pengaturan
        break;
      default:
        appIndex = 3;
    }
    HapticFeedback.lightImpact();
    _onSelectIndex(appIndex);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Provider.of<AdminController>(context, listen: false);
      controller.loadInitialData().then((_) {
        if (mounted && controller.storeId != null) {
          Provider.of<AnalyticsController>(
            context,
            listen: false,
          ).init(controller.storeId);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<AdminController>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    if (controller.isInitializing) {
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
          final content = _getSelectedPage(controller);

          return Scaffold(
            key: _scaffoldKey,
            backgroundColor: theme.scaffoldBackgroundColor,
            body: isWide
                ? Row(
                    children: [
                      AdminNavigationRail(
                        selectedIndex: _selectedIndex,
                        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
                        storeLogo: controller.storeLogo,
                        onLogout: () async {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.remove('last_route');
                          if (!context.mounted) return;
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                        userName: controller.userName,
                        storeName: controller.storeName,
                        role: controller.role,
                        permissions: controller.permissions,
                      ),
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
            bottomNavigationBar: isWide ? null : _buildBottomNavBar(theme, isDark, primaryColor),
          );
        },
      ),
    );
  }

  Widget _buildBottomNavBar(ThemeData theme, bool isDark, Color primaryColor) {
    const orange = Color(0xFFF25A22);
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Theme(
        data: theme.copyWith(
          navigationBarTheme: NavigationBarThemeData(
            backgroundColor: Colors.transparent,
            indicatorColor: orange.withValues(alpha: 0.12),
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: orange,
                );
              }
              return TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white60 : Colors.black54,
              );
            }),
            iconTheme: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const IconThemeData(color: orange, size: 24);
              }
              return IconThemeData(
                color: isDark ? Colors.white60 : Colors.black54,
                size: 24,
              );
            }),
          ),
        ),
        child: NavigationBar(
          height: 65,
          selectedIndex: _getBottomNavIndex(),
          onDestinationSelected: _onBottomNavItemTapped,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.calculate_outlined),
              selectedIcon: Icon(Icons.calculate),
              label: 'Kasir',
            ),
            NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: Icon(Icons.account_balance_wallet),
              label: 'Uang',
            ),
            NavigationDestination(
              icon: Icon(Icons.trending_up_rounded),
              selectedIcon: Icon(Icons.trending_up_rounded),
              label: 'Tren',
            ),
            NavigationDestination(
              icon: Icon(Icons.bolt_outlined),
              selectedIcon: Icon(Icons.bolt),
              label: 'Aksi',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Pengaturan',
            ),
          ],
        ),
      ),
    );
  }

  Widget _getSelectedPage(AdminController controller) {
    final sId = controller.storeId;
    if (sId == null && _selectedIndex != 7) {
      return const Center(child: CircularProgressIndicator());
    }

    void onMenuPressed() {}

    switch (_selectedIndex) {
      case 0:
        // Dashboard removed – redirect to Kasir
        return KasirPage(
          showSidebar: false,
          onMenuPressed: onMenuPressed,
          onNavigateToIndex: (index) => _onSelectIndex(index),
        );
      case 1:
        return InventoryPage(
          onMenuPressed: onMenuPressed,
          onBack: _handleBackNavigation,
          onNavigateToCategories: () => _onSelectIndex(2),
        );
      case 2:
        return CategoryPage(
          storeId: sId!,
          onBack: _handleBackNavigation,
          onNavigateToProducts: () => _onSelectIndex(1),
        );
      case 3:
        return KasirPage(
          showSidebar: false,
          onMenuPressed: onMenuPressed,
          onNavigateToIndex: (index) => _onSelectIndex(index),
        );
      case 4:
        return HistoryPage(
          storeId: sId!,
          onMenuPressed: onMenuPressed,
          onBack: _handleBackNavigation,
          showSidebar: false,
        );
      case 5:
        return EmployeeManagementPage(
          storeId: sId!,
          onBack: _handleBackNavigation,
        );
      case 16:
        return AttendancePage(
          showSidebar: false,
          onMenuPressed: onMenuPressed,
          onBack: _handleBackNavigation,
        );
      case 6:
        return TrendsPage(
          storeId: sId!,
          onNavigateToIndex: (index) => _onSelectIndex(index),
        );
      case 7:
        return PrinterSettingsPage(
          showSidebar: false,
          onMenuPressed: onMenuPressed,
          onBack: _handleBackNavigation,
          onNavigateToStruk: () => _onSelectIndex(19),
        );
      case 8:
        return ProfilePage(storeId: sId!, onMenuPressed: onMenuPressed);
      case 9:
        return ActionMenuPage(
          onMenuPressed: onMenuPressed,
          onIndexSelected: (index) {
            _onSelectIndex(index);
          },
        );
      case 17: // PromotionPage
        return PromotionPage(onBack: _handleBackNavigation);
      case 10:
        return DataManagementPage(
          onMenuPressed: onMenuPressed,
          onBack: _handleBackNavigation,
        );
      case 11:
        return ProfitLossPage(
          storeId: sId!,
          onMenuPressed: onMenuPressed,
          onNavigateToIndex: (index) => _onSelectIndex(index),
        );
      case 12:
        return CustomerPage(
          onMenuPressed: onMenuPressed,
          onBack: _handleBackNavigation,
          onNavigateToIndex: (index) => _onSelectIndex(index),
        );
      case 15:
        return _QuickMenuPage(
          onMenuPressed: onMenuPressed,
          onLogout: _handleLogout,
          onIndexSelected: (index) {
            _onSelectIndex(index);
          },
        );
      case 18:
        return BackupRestorePage(
          onBack: _handleBackNavigation,
        );
      case 19:
        return TransactionSettingsPage(
          onBack: _handleBackNavigation,
        );
      case 20:
        return TermsConditionsPage(
          onBack: _handleBackNavigation,
        );

      default:
        return TrendsPage(
          storeId: sId!,
          onNavigateToIndex: (index) => setState(() => _selectedIndex = index),
        );
    }
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

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => KasirDialog(
        title: "Konfirmasi Logout",
        message: "Apakah Anda yakin ingin keluar dari akun ini?",
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
      final activationService = ActivationService();
      await activationService.logout();
      if (mounted) Navigator.of(context).pushReplacementNamed('/login');
    }
  }
}

class _QuickMenuPage extends StatelessWidget {
  final VoidCallback onMenuPressed;
  final VoidCallback onLogout;
  final Function(int) onIndexSelected;

  const _QuickMenuPage({
    required this.onMenuPressed,
    required this.onLogout,
    required this.onIndexSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey.shade50,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Image.asset(
                'assets/logo/logo.png',
                height: 24,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              "Pengaturan",
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 18,
              ),
            ),
          ],
        ),
        centerTitle: false,
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: isDark ? const Color(0xFF374151) : const Color(0xFFE2E8F0),
            height: 1,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            // ── Operasional & Perangkat ────────────────
            _buildSectionTitle("Operasional & Perangkat", isDark),
            _buildGroupedSection(isDark: isDark, items: [
              _buildActionNavCard(
                title: "Pengaturan Printer",
                icon: Icons.print_outlined,
                isDark: isDark,
                onTap: () => onIndexSelected(7),
              ),
              _buildActionNavCard(
                title: "Pengaturan Transaksi",
                icon: Icons.receipt_long_rounded,
                isDark: isDark,
                onTap: () => onIndexSelected(19),
              ),
            ]),
            const SizedBox(height: 24),
            // ── Karyawan & Absensi ─────────────────────
            _buildSectionTitle("Karyawan & Absensi", isDark),
            _buildGroupedSection(isDark: isDark, items: [
              _buildMenuTile(
                index: 5,
                label: "Kelola Pegawai & Gaji",
                icon: Icons.badge_outlined,
                isDark: isDark,
              ),
              _buildMenuTile(
                index: 16,
                label: "Absensi Pegawai",
                icon: Icons.fingerprint_rounded,
                isDark: isDark,
              ),
            ]),
            const SizedBox(height: 24),
            // ── Sistem & Pengaturan ────────────────────
            _buildSectionTitle("Sistem & Pengaturan", isDark),
            _buildGroupedSection(isDark: isDark, items: [
              _buildMenuTile(
                index: 18,
                label: "Pencadangan & Pemulihan",
                icon: Icons.storage_rounded,
                isDark: isDark,
              ),
              _buildThemeTile(isDark),
              _buildMenuTile(
                index: 8,
                label: "Profil Toko",
                icon: Icons.store_outlined,
                isDark: isDark,
              ),
              _buildMenuTile(
                index: 20,
                label: "Syarat & Ketentuan",
                icon: Icons.description_outlined,
                isDark: isDark,
              ),
              _buildVersionTile(isDark),
              _buildLogoutTile(isDark),
            ]),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupedSection({
    required bool isDark,
    required List<Widget> items,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: List.generate(items.length * 2 - 1, (i) {
          if (i.isOdd) {
            return Divider(
              height: 1,
              indent: 60,
              color: isDark ? Colors.white10 : Colors.grey.shade200,
            );
          }
          return items[i ~/ 2];
        }),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white70 : Colors.black54,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildMenuTile({
    required int index,
    required String label,
    required IconData icon,
    required bool isDark,
  }) {
    return ListTile(
      onTap: () => onIndexSelected(index),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(
        icon,
        color: isDark ? Colors.white70 : Colors.black87,
        size: 22,
      ),
      title: Text(
        label,
        style: GoogleFonts.openSans(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: isDark ? Colors.white24 : Colors.grey.shade400,
        size: 20,
      ),
    );
  }

  Widget _buildLogoutTile(bool isDark) {
    return ListTile(
      onTap: onLogout,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: const Icon(Icons.logout_rounded, color: Colors.red, size: 22),
      title: Text(
        "Keluar Akun",
        style: GoogleFonts.openSans(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Colors.red,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: Colors.red.withValues(alpha: 0.3),
        size: 20,
      ),
    );
  }

  Widget _buildVersionTile(bool isDark) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(
        Icons.info_outline_rounded,
        color: isDark ? Colors.white70 : Colors.black87,
        size: 22,
      ),
      title: Text(
        "Versi Aplikasi",
        style: GoogleFonts.openSans(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      trailing: Text(
        "1.0.0",
        style: GoogleFonts.robotoMono(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white38 : Colors.grey,
        ),
      ),
    );
  }

  Widget _buildThemeTile(bool isDark) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.instance.themeMode,
      builder: (context, mode, child) {
        final isDarkMode = mode == ThemeMode.dark;
        return _buildGenericSettingTile(
          label: "Mode Gelap",
          icon: isDarkMode
              ? Icons.dark_mode
              : Icons.light_mode,
          isDark: isDark,
          trailing: CupertinoSwitch(
            value: isDarkMode,
            onChanged: (val) => ThemeController.instance.toggleTheme(),
          ),
          onTap: () => ThemeController.instance.toggleTheme(),
        );
      },
    );
  }

  Widget _buildGenericSettingTile({
    required String label,
    required IconData icon,
    required bool isDark,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(
        icon,
        color: isDark ? Colors.white70 : Colors.black87,
        size: 22,
      ),
      title: Text(
        label,
        style: GoogleFonts.openSans(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      trailing:
          trailing ??
          Icon(
            Icons.chevron_right,
            color: isDark ? Colors.white24 : Colors.grey.shade400,
            size: 20,
          ),
    );
  }

  // ── Action Nav Card (Printer / Transaksi) ────────────────────────────────
  Widget _buildActionNavCard({
    required String title,
    required IconData icon,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.blue, size: 22),
      ),
      title: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: isDark ? Colors.white24 : Colors.grey.shade400,
      ),
    );
  }
}

