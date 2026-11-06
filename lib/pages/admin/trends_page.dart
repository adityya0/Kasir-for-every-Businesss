import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/platform/file_manager.dart';
import 'package:intl/intl.dart';
import '../../controllers/analytics_controller.dart';
import '../../controllers/settings_controller.dart';
import 'widgets/pinterest_card.dart';
import 'widgets/green_date_picker_dialog.dart';
import 'table_management_page.dart';
import '../../controllers/admin_controller.dart';
import '../../widgets/reset_transactions_dialog.dart';
import '../../widgets/kasir_dialog.dart';

class TrendsPage extends StatefulWidget {
  final String storeId;
  final Function(int) onNavigateToIndex;
  final bool embedded;
  const TrendsPage({
    super.key,
    required this.storeId,
    required this.onNavigateToIndex,
    this.embedded = false,
  });

  @override
  State<TrendsPage> createState() => _TrendsPageState();
}

class _TrendsPageState extends State<TrendsPage>
    with TickerProviderStateMixin {
  late AnimationController _barAnimController;
  late Animation<double> _barAnimation;
  late TabController _tabController;
  String _viewMode = 'all'; // 'all', 'products', 'tables'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _barAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _barAnimation = CurvedAnimation(
      parent: _barAnimController,
      curve: Curves.easeOutCubic,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnalyticsController>().init(widget.storeId);
      _barAnimController.forward();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _barAnimController.dispose();
    super.dispose();
  }

  void _restartAnimation() {
    _barAnimController.reset();
    _barAnimController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bodyContent = Consumer<AnalyticsController>(
      builder: (context, controller, child) {
        if (controller.isLoading) {
          return const Center(child: CupertinoActivityIndicator());
        }

        final showProducts = _viewMode == 'all' || _viewMode == 'products';
        final showTables = _viewMode == 'all' || _viewMode == 'tables';

        return TabBarView(
          controller: _tabController,
          children: [
            // ── Tab 1: Tren Penjualan ─────────────────────────────────
            RefreshIndicator(
              onRefresh: () async {
                await controller.refreshData();
                _restartAnimation();
              },
              color: const Color(0xFF00BF63),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_viewMode != 'all') ...[
                      _buildFilterActiveBanner(isDark),
                    ],
                    if (controller.lowStockProducts.isNotEmpty)
                      _buildLowStockAlertCard(controller, isDark),
                    _buildPeriodSelector(controller, isDark),
                    const SizedBox(height: 24),
                    if (showProducts) ...[
                      _buildTopSellingSection(controller, isDark),
                      const SizedBox(height: 28),
                    ],
                    if (showTables) ...[
                      ValueListenableBuilder<bool>(
                        valueListenable: SettingsController.instance.featureMejaEnabled,
                        builder: (context, mejaEnabled, _) {
                          if (!mejaEnabled) return const SizedBox.shrink();
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTopTablesSection(controller, isDark),
                              const SizedBox(height: 28),
                            ],
                          );
                        },
                      ),
                    ],
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            // ── Tab 2: Produk Stok Rendah (Dedicated Page) ───────────
            RefreshIndicator(
              onRefresh: () async {
                await controller.refreshData();
                _restartAnimation();
              },
              color: const Color(0xFF00BF63),
              child: _buildDedicatedLowStockPage(controller, isDark),
            ),
          ],
        );
      },
    );

    if (widget.embedded) {
      return Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? const Color(0xFF374151) : const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
            ),
            child: Consumer<AnalyticsController>(
              builder: (context, controller, _) {
                final lowStockCount = controller.lowStockProducts.length;
                return TabBar(
                  controller: _tabController,
                  indicatorColor: const Color(0xFF00BF63),
                  indicatorWeight: 3,
                  labelColor: const Color(0xFF00BF63),
                  unselectedLabelColor: isDark ? Colors.white60 : const Color(0xFF64748B),
                  labelStyle: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                  unselectedLabelStyle: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                  tabs: [
                    const Tab(text: "Tren Penjualan"),
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text("Stok Rendah"),
                          if (lowStockCount > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                "$lowStockCount",
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Expanded(child: bodyContent),
        ],
      );
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : Colors.white,
      appBar: AppBar(
        title: Text(
          "Tren Produk",
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
        backgroundColor: isDark ? const Color(0xFF1A1C1E) : Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1C1E) : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? const Color(0xFF374151) : const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
            ),
            child: Consumer<AnalyticsController>(
              builder: (context, controller, _) {
                final lowStockCount = controller.lowStockProducts.length;
                return TabBar(
                  controller: _tabController,
                  indicatorColor: const Color(0xFF00BF63),
                  indicatorWeight: 3,
                  labelColor: const Color(0xFF00BF63),
                  unselectedLabelColor: isDark ? Colors.white60 : const Color(0xFF64748B),
                  labelStyle: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                  unselectedLabelStyle: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  tabs: [
                    const Tab(text: "Tren Penjualan"),
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text("Stok Rendah"),
                          if (lowStockCount > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                "$lowStockCount",
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12, top: 6, bottom: 6),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: isDark ? const Color(0xFF374151) : const Color(0xFFCBD5E1),
                  width: 1.2,
                ),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.bolt_rounded,
                  color: Color(0xFF00BF63),
                  size: 24,
                ),
                tooltip: "Pintasan Cepat",
                onPressed: () => _showTrendsQuickShortcutsSheet(context, isDark),
              ),
            ),
          ),
        ],
      ),
      body: bodyContent,
    );
  }

  // ─── Filter Active Banner ───────────────────────────────────────────────
  Widget _buildFilterActiveBanner(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF059669).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.filter_alt_rounded, size: 16, color: Color(0xFF059669)),
              const SizedBox(width: 8),
              Text(
                _viewMode == 'products'
                    ? "Menampilkan: Hanya Tren Produk"
                    : "Menampilkan: Hanya Tren Meja",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF059669),
                ),
              ),
            ],
          ),
          InkWell(
            onTap: () => setState(() => _viewMode = 'all'),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Row(
                children: [
                  Text(
                    "Reset Filter",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.close_rounded, size: 14),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Low Stock Alert Card in Tab 1 ──────────────────────────────────────
  Widget _buildLowStockAlertCard(AnalyticsController controller, bool isDark) {
    final count = controller.lowStockProducts.length;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _tabController.animateTo(1),
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: isDark ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFEF4444),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "$count Produk Stok Rendah / Menipis",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFEF4444),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Geser ke kanan atau ketuk untuk cek & restock",
                        style: GoogleFonts.openSans(
                          fontSize: 11.5,
                          color: isDark ? Colors.white70 : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Color(0xFFEF4444),
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Trends Quick Shortcuts Bottom Sheet ────────────────────────────────
  void _showTrendsQuickShortcutsSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 580,
              maxHeight: MediaQuery.of(ctx).size.height * 0.85,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border.all(
                  color: isDark ? const Color(0xFF374151) : const Color(0xFFCBD5E1),
                  width: 1.2,
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top drag handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00BF63).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.bolt_rounded,
                                color: Color(0xFF00BF63),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Pintasan Cepat Tren",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                                Text(
                                  "Buka menu langsung tanpa keluar dari Tren",
                                  style: GoogleFonts.openSans(
                                    fontSize: 12,
                                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Shortcut Tiles
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return Center(
                          child: Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              _buildTrendShortcutTile(
                                icon: Icons.inventory_2_outlined,
                                label: "Kelola Produk",
                                subtitle: "Katalog & stok barang",
                                color: const Color(0xFF2563EB),
                                isDark: isDark,
                                onTap: () {
                                  Navigator.pop(ctx);
                                  widget.onNavigateToIndex(1);
                                },
                              ),
                              _buildTrendShortcutTile(
                                icon: Icons.discount_outlined,
                                label: "Promosi & Diskon",
                                subtitle: "Voucher & promo toko",
                                color: const Color(0xFFEA580C),
                                isDark: isDark,
                                onTap: () {
                                  Navigator.pop(ctx);
                                  widget.onNavigateToIndex(17);
                                },
                              ),
                              _buildTrendShortcutTile(
                                icon: Icons.receipt_long_outlined,
                                label: "Riwayat Transaksi",
                                subtitle: "Daftar struk / order",
                                color: const Color(0xFF7C3AED),
                                isDark: isDark,
                                onTap: () {
                                  Navigator.pop(ctx);
                                  widget.onNavigateToIndex(4);
                                },
                              ),
                              ValueListenableBuilder<bool>(
                                valueListenable: SettingsController.instance.featureMejaEnabled,
                                builder: (context, mejaEnabled, _) {
                                  if (!mejaEnabled) return const SizedBox.shrink();
                                  return _buildTrendShortcutTile(
                                    icon: Icons.table_restaurant_outlined,
                                    label: "Manajemen Meja",
                                    subtitle: "Denah & status meja",
                                    color: const Color(0xFF059669),
                                    isDark: isDark,
                                    onTap: () {
                                      Navigator.pop(ctx);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => TableManagementPage(storeId: widget.storeId),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 20),
                    Divider(color: isDark ? Colors.white12 : Colors.grey.shade200, height: 1),
                    const SizedBox(height: 16),

                    // Filter Tampilan Tren
                    Text(
                      "FILTER TAMPILAN GRAFIK",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white38 : Colors.grey.shade500,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildFilterPill(
                          label: "Semua",
                          isSelected: _viewMode == 'all',
                          isDark: isDark,
                          onTap: () {
                            setState(() => _viewMode = 'all');
                            Navigator.pop(ctx);
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildFilterPill(
                          label: "Hanya Produk",
                          isSelected: _viewMode == 'products',
                          isDark: isDark,
                          onTap: () {
                            setState(() => _viewMode = 'products');
                            Navigator.pop(ctx);
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildFilterPill(
                          label: "Hanya Meja",
                          isSelected: _viewMode == 'tables',
                          isDark: isDark,
                          onTap: () {
                            setState(() => _viewMode = 'tables');
                            Navigator.pop(ctx);
                          },
                        ),
                      ],
                    ),

                    // Admin Actions
                    Consumer<AdminController>(
                      builder: (context, adminCtrl, _) {
                        final isAdmin = adminCtrl.role == 'admin' || adminCtrl.role == 'owner';
                        if (!isAdmin) return const SizedBox.shrink();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 20),
                            Divider(color: isDark ? Colors.white12 : Colors.grey.shade200, height: 1),
                            const SizedBox(height: 14),
                            Text(
                              "AKSI PENGATURAN DATA",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white38 : Colors.grey.shade500,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      _showResetTableTrendsDialog(context, context.read<AnalyticsController>());
                                    },
                                    icon: const Icon(Icons.restart_alt_rounded, size: 16, color: Color(0xFFF59E0B)),
                                    label: const Text(
                                      "Reset Meja",
                                      style: TextStyle(color: Color(0xFFF59E0B), fontSize: 12, fontWeight: FontWeight.w700),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: Color(0xFFF59E0B)),
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      ResetTransactionsDialog.show(
                                        context,
                                        storeId: widget.storeId,
                                        onResetSuccess: () {
                                          context.read<AnalyticsController>().refreshData();
                                          _restartAnimation();
                                        },
                                      );
                                    },
                                    icon: const Icon(Icons.delete_sweep_rounded, size: 16, color: Color(0xFFEF4444)),
                                    label: const Text(
                                      "Reset Produk",
                                      style: TextStyle(color: Color(0xFFEF4444), fontSize: 12, fontWeight: FontWeight.w700),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: Color(0xFFEF4444)),
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTrendShortcutTile({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 155,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF27272A) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark ? const Color(0xFF3F3F46) : const Color(0xFFE2E8F0),
              width: 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.openSans(
                  fontSize: 11,
                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterPill({
    required String label,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF00BF63)
              : (isDark ? const Color(0xFF27272A) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF00BF63)
                : (isDark ? const Color(0xFF3F3F46) : const Color(0xFFE2E8F0)),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : const Color(0xFF475569)),
          ),
        ),
      ),
    );
  }

  // ─── Period Selector ────────────────────────────────────────────────────
  Widget _buildPeriodSelector(AnalyticsController controller, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: 16,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
            const SizedBox(width: 8),
            Text(
              "Periode Analitik",
              style: GoogleFonts.openSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterBtn(controller, ChartRange.today, "Hari Ini"),
              const SizedBox(width: 8),
              _buildFilterBtn(controller, ChartRange.sevenDays, "7 Hari"),
              const SizedBox(width: 8),
              _buildFilterBtn(controller, ChartRange.thirtyDays, "30 Hari"),
              const SizedBox(width: 8),
              _buildFilterBtn(
                controller,
                ChartRange.custom,
                "Kustom",
                isCustom: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBtn(
    AnalyticsController controller,
    ChartRange range,
    String label, {
    bool isCustom = false,
  }) {
    final isSelected = controller.selectedRange == range;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryColor = Color(0xFF00BF63);

    return GestureDetector(
      onTap: () {
        if (isCustom) {
          _showCustomRangePicker(controller);
        } else {
          controller.setRange(range);
          _restartAnimation();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor
              : (isDark ? Colors.white10 : Colors.white),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? primaryColor
                : (isDark ? const Color(0xFF374151) : const Color(0xFFCBD5E1)),
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.openSans(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : Colors.black87),
          ),
        ),
      ),
    );
  }

  void _showCustomRangePicker(AnalyticsController controller) async {
    final now = DateTime.now();
    final initialStart = controller.customStartDate ?? now.subtract(const Duration(days: 7));
    final initialEnd = controller.customEndDate ?? now;

    final picked = await showDialog<DateTimeRange>(
      context: context,
      builder: (ctx) => GreenDateRangePickerDialog(
        initialStartDate: initialStart,
        initialEndDate: initialEnd,
        firstDate: DateTime(2020),
        lastDate: now,
      ),
    );

    if (picked != null) {
      controller.setRange(
        ChartRange.custom,
        start: picked.start,
        end: picked.end,
      );
      _restartAnimation();
    }
  }

  // ─── TOP SELLING PRODUCTS ───────────────────────────────────────────────
  Widget _buildTopSellingSection(
      AnalyticsController controller, bool isDark) {
    final products = controller.topProducts.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Produk Terlaris",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF2D3436),
                  ),
                ),
                Text(
                  "Top 5 • Penjualan Terbanyak",
                  style: GoogleFonts.openSans(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color:
                    const Color(0xFF00BF63).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.trending_up_rounded,
                    size: 14,
                    color: Color(0xFF00BF63),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "Analitik",
                    style: GoogleFonts.openSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF00BF63),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (products.isEmpty)
          PinterestCard(
            borderRadius: 8,
            padding:
                const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
            child: Column(
              children: [
                Icon(
                  Icons.bar_chart,
                  size: 48,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 12),
                Text(
                  "Belum ada data penjualan",
                  style: GoogleFonts.openSans(color: Colors.grey),
                ),
              ],
            ),
          )
        else ...[
          _buildHorizontalBarChart(products, isDark),
          const SizedBox(height: 16),
          _buildTopProductsRankList(products, isDark),
        ],
      ],
    );
  }

  // ─── Animated horizontal bar chart ─────────────────────────────────────
  Widget _buildHorizontalBarChart(
    List<Map<String, dynamic>> products,
    bool isDark,
  ) {
    final maxSales = products.fold<int>(
      0,
      (prev, p) =>
          (p['sales'] as int) > prev ? (p['sales'] as int) : prev,
    );

    final barColors = [
      const Color(0xFF00BF63),
      const Color(0xFF7C3AED),
      const Color(0xFF0D9488),
      const Color(0xFF2563EB),
      const Color(0xFFDB2777),
    ];

    return PinterestCard(
      borderRadius: 8,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.bar_chart,
                size: 16,
                color: isDark ? Colors.white54 : Colors.grey.shade500,
              ),
              const SizedBox(width: 6),
              Text(
                "Jumlah Terjual (unit)",
                style: GoogleFonts.openSans(
                  fontSize: 12,
                  color: isDark ? Colors.white54 : Colors.grey.shade500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: _barAnimation,
            builder: (context, _) {
              return Column(
                children: List.generate(products.length, (i) {
                  final p = products[i];
                  final sales = p['sales'] as int;
                  final ratio = maxSales > 0
                      ? (sales / maxSales) * _barAnimation.value
                      : 0.0;
                  final color = barColors[i % barColors.length];

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Row(
                      children: [
                        // Medal circle
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: i == 0
                                ? const Color(0xFFFACC15)
                                : i == 1
                                ? Colors.grey.shade400
                                : i == 2
                                ? const Color(0xFFCD7F32)
                                : (isDark
                                    ? Colors.white10
                                    : Colors.grey.shade100),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              "${i + 1}",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color:
                                    i < 3 ? Colors.white : Colors.grey,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Product name
                        SizedBox(
                          width: 90,
                          child: Text(
                            p['name'] as String,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.openSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? Colors.white70
                                  : Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Animated bar
                        Expanded(
                          child: Stack(
                            children: [
                              Container(
                                height: 10,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white10
                                      : Colors.grey.shade100,
                                  borderRadius:
                                      BorderRadius.circular(6),
                                ),
                              ),
                              FractionallySizedBox(
                                widthFactor: ratio.clamp(0.0, 1.0),
                                child: Container(
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius:
                                        BorderRadius.circular(6),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Count
                        SizedBox(
                          width: 36,
                          child: Text(
                            "$sales",
                            textAlign: TextAlign.right,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }

  // ─── Rank list with share percentage ───────────────────────────────────
  Widget _buildTopProductsRankList(
    List<Map<String, dynamic>> products,
    bool isDark,
  ) {
    final totalSales = products.fold<int>(
      0,
      (sum, p) => sum + (p['sales'] as int),
    );
    final medals = ['🥇', '🥈', '🥉'];

    return Column(
      children: List.generate(products.length, (index) {
        final p = products[index];
        final sales = p['sales'] as int;
        final share = totalSales > 0
            ? ((sales / totalSales) * 100).toStringAsFixed(1)
            : '0';
        final medal = index < 3 ? medals[index] : null;

        return PinterestCard(
          borderRadius: 8,
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Thumbnail
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark
                        ? Colors.white10
                        : Colors.grey.shade200,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: (p['imageUrl'] != null && (p['imageUrl'] as String).isNotEmpty)
                      ? Image(
                          image: FileManager().getImageProvider(p['imageUrl'] as String),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildRankFallback(index),
                        )
                      : _buildRankFallback(index),
                ),
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (medal != null) ...[
                          Text(
                            medal,
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Text(
                            p['name'] as String,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF2D3436),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Terjual $sales unit  •  $share% dari total",
                      style: GoogleFonts.openSans(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              // Rank pill
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: index == 0
                      ? const Color(0xFFFACC15).withValues(alpha: 0.15)
                      : (isDark
                          ? Colors.white10
                          : Colors.grey.shade100),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "#${index + 1}",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: index == 0
                        ? const Color(0xFFCA8A04)
                        : Colors.grey.shade500,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildRankFallback(int index) {
    return Center(
      child: Text(
        "${index + 1}",
        style: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w700,
          fontSize: 16,
          color: index < 3 ? const Color(0xFF00BF63) : Colors.grey,
        ),
      ),
    );
  }

  // ─── Dedicated Low Stock Page (Tab 2) ──────────────────────────────────
  Widget _buildDedicatedLowStockPage(
      AnalyticsController controller, bool isDark) {
    final lowStockList = controller.lowStockProducts;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card with Quick Link to Products
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.inventory_2_outlined,
                    color: Color(0xFFEF4444),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            "Produk Stok Rendah",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          if (lowStockList.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                "${lowStockList.length} item",
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        "Produk dengan sisa stok menipis yang perlu segera di-restock.",
                        style: GoogleFonts.openSans(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),



          if (lowStockList.isEmpty)
            PinterestCard(
              borderRadius: 14,
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00BF63).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF00BF63),
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      "Semua Stok Aman ✅",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Tidak ada produk dengan stok menipis saat ini.",
                      style: GoogleFonts.openSans(
                        fontSize: 13,
                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: lowStockList.length,
              itemBuilder: (context, index) {
                final p = lowStockList[index];
                return PinterestCard(
                  borderRadius: 12,
                  onTap: () => widget.onNavigateToIndex(1),
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark ? Colors.white10 : Colors.grey.shade200,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: (p['imageUrl'] != null && p['imageUrl'].toString().isNotEmpty)
                              ? Image(
                                  image: FileManager().getImageProvider(p['imageUrl'].toString()),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Icon(
                                    Icons.fastfood_rounded,
                                    color: isDark ? Colors.white24 : Colors.grey.shade400,
                                  ),
                                )
                              : Icon(
                                  Icons.fastfood_rounded,
                                  color: isDark ? Colors.white24 : Colors.grey.shade400,
                                ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p['name'] as String,
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 14.5,
                                color: isDark ? Colors.white : const Color(0xFF1E293B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Builder(
                                    builder: (context) {
                                      final sVal = p['stock'];
                                      final sText = (sVal is num)
                                          ? (sVal % 1 == 0 ? sVal.toInt().toString() : sVal.toString())
                                          : sVal.toString();
                                      return Text(
                                        "Sisa $sText unit",
                                        style: GoogleFonts.openSans(
                                          fontSize: 12,
                                          color: const Color(0xFFEF4444),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      );
                                    }
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => widget.onNavigateToIndex(1),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "Restock",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFEF4444),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: Color(0xFFEF4444),
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ─── TOP OCCUPIED TABLES ────────────────────────────────────────────────
  Widget _buildTopTablesSection(AnalyticsController controller, bool isDark) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final tables = controller.topTables;
    final maxOccupancy = tables.isNotEmpty ? (tables.first['occupancy'] as int) : 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Tren Okupansi Meja",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF2D3436),
                    ),
                  ),
                  Text(
                    "Meja paling banyak ditempati oleh customer",
                    style: GoogleFonts.openSans(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                // Pintasan ke kelola meja
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TableManagementPage(storeId: widget.storeId),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF059669).withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.table_restaurant_outlined,
                          size: 14,
                          color: Color(0xFF059669),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "Kelola Meja",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF059669),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Reset tren meja
                InkWell(
                  onTap: () => _showResetTableTrendsDialog(context, controller),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.restart_alt_rounded,
                          size: 14,
                          color: Color(0xFFEF4444),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "Reset",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (tables.isEmpty)
          PinterestCard(
            borderRadius: 8,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669).withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.table_restaurant_outlined,
                    size: 36,
                    color: Color(0xFF059669),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Belum ada data pemakaian meja pada periode ini",
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: isDark ? Colors.white70 : const Color(0xFF334155),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  "Data terisi otomatis saat pesanan kasir dihubungkan ke meja.",
                  style: GoogleFonts.openSans(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tables.length,
            itemBuilder: (context, index) {
              final t = tables[index];
              final name = t['name'] as String;
              final occupancy = t['occupancy'] as int;
              final revenue = (t['revenue'] as num).toDouble();
              final ratio = maxOccupancy > 0 ? (occupancy / maxOccupancy) : 0.0;

              Color rankColor = Colors.grey.shade500;
              Color rankBg = isDark ? Colors.white10 : Colors.grey.shade100;
              if (index == 0) {
                rankColor = const Color(0xFFCA8A04);
                rankBg = const Color(0xFFFACC15).withValues(alpha: 0.15);
              } else if (index == 1) {
                rankColor = const Color(0xFF64748B);
                rankBg = const Color(0xFF94A3B8).withValues(alpha: 0.15);
              } else if (index == 2) {
                rankColor = const Color(0xFFB45309);
                rankBg = const Color(0xFFD97706).withValues(alpha: 0.15);
              }

              return PinterestCard(
                borderRadius: 8,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Rank pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: rankBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            "#${index + 1}",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: rankColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF059669).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.table_restaurant_outlined,
                            size: 18,
                            color: Color(0xFF059669),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Omset: ${currencyFormat.format(revenue)}",
                                style: GoogleFonts.openSans(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF059669).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF059669).withValues(alpha: 0.25),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            "$occupancy kali",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF059669),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: ratio),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOutCubic,
                        builder: (context, val, _) {
                          return LinearProgressIndicator(
                            value: val,
                            minHeight: 6,
                            backgroundColor: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF059669)),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  void _showResetTableTrendsDialog(
      BuildContext context, AnalyticsController controller) {
    showDialog(
      context: context,
      builder: (ctx) => KasirDialog(
        title: "Reset Data Tren Meja?",
        message:
            "Data pemakaian meja pada transaksi akan dihapus dari laporan tren sehingga statistik meja kembali ke 0.\n\nTindakan ini tidak menghapus meja Anda di menu kelola meja.",
        icon: Icons.restart_alt_rounded,
        iconColor: const Color(0xFFEF4444),
        isDestructive: true,
        primaryActionLabel: "Reset Data Meja",
        onPrimaryAction: () async {
          Navigator.pop(ctx);
          await controller.resetTableTrendsData();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "✓ Data tren okupansi meja berhasil direset!",
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                backgroundColor: const Color(0xFF10B981),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          }
        },
        secondaryActionLabel: "Batal",
        onSecondaryAction: () => Navigator.pop(ctx),
      ),
    );
  }
}

