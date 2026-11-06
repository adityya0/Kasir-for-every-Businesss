import '../../controllers/settings_controller.dart';
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
import 'payment_settings_page.dart';
import 'transaction_settings_page.dart';
import 'laporan_page.dart';
import 'unit_page.dart';
import 'report/expense_management_page.dart';
import 'feature_settings_page.dart';
import 'table_management_page.dart';
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

  // Maksimal kedalaman riwayat 2 halaman sebelumnya sebelum langsung kembali ke halaman utama Kasir
  static const int _maxHistoryLimit = 2;

  void _onSelectIndex(int index) {
    if (_selectedIndex == index) return;
    if (index == 3) {
      // Jika kembali ke halaman utama Kasir, bersihkan riwayat
      _indexHistory.clear();
    } else {
      if (_indexHistory.isEmpty || _indexHistory.last != _selectedIndex) {
        _indexHistory.add(_selectedIndex);
        // Batasi riwayat maksimal 2 halaman sebelumnya
        while (_indexHistory.length > _maxHistoryLimit) {
          _indexHistory.removeAt(0);
        }
      }
    }
    setState(() => _selectedIndex = index);
  }

  bool _handleBackNavigation() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
      return true;
    }
    // Jika masih ada riwayat 2-3 halaman sebelumnya
    if (_indexHistory.isNotEmpty) {
      final previous = _indexHistory.removeLast();
      if (previous == 3) {
        _indexHistory.clear();
      }
      setState(() => _selectedIndex = previous);
      return true;
    }
    // Jika riwayat habis dan belum di halaman utama Kasir, langsung kembali ke Kasir
    if (_selectedIndex != 3) {
      _indexHistory.clear();
      setState(() => _selectedIndex = 3);
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
      case 21:
      case 23:
        return 1; // Uang (Laporan)
      case 26:
        return 2; // Keuangan
      case 12:
      case 13:
        return 3; // Kontak (Pelanggan & Supplier)
      case 1:
      case 2:
      case 22:
      case 6:
        return 4; // Produk (termasuk Tren & Kategori & Satuan)
      case 15:
      case 4:
      case 5:
      case 16:
      case 7:
      case 8:
      case 9:
      case 10:
      case 17:
      case 18:
      case 19:
      case 20:
      case 24:
      case 25:
        return 5; // Pengaturan
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
        appIndex = 26; // Keuangan
        break;
      case 3:
        appIndex = 12; // Kontak
        break;
      case 4:
        appIndex = 1; // Produk (termasuk Tren)
        break;
      case 5:
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
                        onDestinationSelected: (index) => _onSelectIndex(index),
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
    final activeGreen = primaryColor;
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
            indicatorColor: Colors.transparent,
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            surfaceTintColor: Colors.transparent,
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return GoogleFonts.plusJakartaSans(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: activeGreen,
                );
              }
              return GoogleFonts.plusJakartaSans(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white60 : const Color(0xFF64748B),
              );
            }),
            iconTheme: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return IconThemeData(color: activeGreen, size: 22);
              }
              return IconThemeData(
                color: isDark ? Colors.white60 : const Color(0xFF64748B),
                size: 22,
              );
            }),
          ),
        ),
        child: NavigationBar(
          height: 60,
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
              icon: Icon(Icons.payments_outlined),
              selectedIcon: Icon(Icons.payments),
              label: 'Keuangan',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline_rounded),
              selectedIcon: Icon(Icons.people_rounded),
              label: 'Kontak',
            ),
            NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2),
              label: 'Produk',
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
          onNavigateToIndex: (index) => _onSelectIndex(index),
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
        return InventoryPage(
          onMenuPressed: onMenuPressed,
          onBack: _handleBackNavigation,
          onNavigateToCategories: () => _onSelectIndex(2),
          onNavigateToIndex: (index) => _onSelectIndex(index),
          initialTabIndex: 1,
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
      case 21:
        return LaporanPage(
          storeId: sId!,
        );
      case 22:
        return const UnitManagementPage();
      case 23:
        return ExpenseManagementPage(
          storeId: sId!,
        );
      case 24:
        return const FeatureSettingsPage();
      case 25:
        return TableManagementPage(
          storeId: sId!,
        );
      case 26:
        return PaymentSettingsPage(
          storeId: sId!,
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
        message: "Apakah Anda yakin ingin menutup dan keluar dari aplikasi OMNI POS?",
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
        title: Text(
          "Pengaturan",
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 18,
          ),
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
            // ── Manajemen Produk & Inventaris ────────────────
            _buildSectionTitle("Manajemen Produk & Inventaris", isDark),
            _buildGroupedSection(isDark: isDark, items: [
              _buildMenuTile(
                index: 1,
                label: "Daftar Produk",
                icon: Icons.inventory_2_outlined,
                isDark: isDark,
              ),
              _buildMenuTile(
                index: 2,
                label: "Kategori Produk",
                icon: Icons.grid_view_rounded,
                isDark: isDark,
              ),
              _buildMenuTile(
                index: 22,
                label: "Kelola Satuan",
                icon: Icons.straighten_rounded,
                isDark: isDark,
              ),
              _buildMenuTile(
                index: 7,
                label: "Pengaturan Printer",
                icon: Icons.print_outlined,
                isDark: isDark,
              ),
              _buildMenuTile(
                index: 19,
                label: "Pengaturan Transaksi",
                icon: Icons.receipt_long_rounded,
                isDark: isDark,
              ),
            ]),
            const SizedBox(height: 24),

            // ── Penjualan & Promosi ──────────────────────────
            _buildSectionTitle("Penjualan & Promosi", isDark),
            ValueListenableBuilder<bool>(
              valueListenable: SettingsController.instance.featureMejaEnabled,
              builder: (context, mejaEnabled, _) {
                final promoItems = [
                  _buildMenuTile(
                    index: 17,
                    label: "Promosi & Diskon",
                    icon: Icons.discount_outlined,
                    isDark: isDark,
                  ),
                  if (mejaEnabled)
                    _buildMenuTile(
                      index: 25,
                      label: "Manajemen Meja",
                      icon: Icons.table_restaurant_outlined,
                      isDark: isDark,
                    ),
                ];
                return _buildGroupedSection(isDark: isDark, items: promoItems);
              },
            ),
            const SizedBox(height: 24),

            // ── Keuangan & Pengeluaran ───────────────────────────
            _buildSectionTitle("Keuangan & Pengeluaran", isDark),
            _buildGroupedSection(isDark: isDark, items: [
              _buildMenuTile(
                index: 23,
                label: "Kelola Pengeluaran",
                icon: Icons.payments_outlined,
                isDark: isDark,
              ),
            ]),
            const SizedBox(height: 24),

            // ── Karyawan & Absensi ───────────────────────────
            ValueListenableBuilder<bool>(
              valueListenable: SettingsController.instance.featureKaryawanEnabled,
              builder: (context, karyawanEnabled, _) {
                if (!karyawanEnabled) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                  ],
                );
              },
            ),

            // ── Sistem & Pengaturan ──────────────────────────
            _buildSectionTitle("Sistem & Pengaturan", isDark),
            _buildGroupedSection(isDark: isDark, items: [
              _buildMenuTile(
                index: 24,
                label: "Pusat Fitur Aplikasi",
                icon: Icons.rocket_launch_rounded,
                isDark: isDark,
              ),
              _buildMenuTile(
                index: 10,
                label: "Manajemen Data (CSV/Excel)",
                icon: Icons.upload_file_rounded,
                isDark: isDark,
              ),
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
}

