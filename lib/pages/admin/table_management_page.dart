import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' as drift;
import '../../services/app_database.dart';
import '../../controllers/analytics_controller.dart';
import 'widgets/pinterest_card.dart';
import '../../widgets/kasir_dialog.dart';

class TableManagementPage extends StatefulWidget {
  final String storeId;
  const TableManagementPage({super.key, required this.storeId});

  @override
  State<TableManagementPage> createState() => _TableManagementPageState();
}

class _TableManagementPageState extends State<TableManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<StoreTable> _tables = [];
  bool _isLoading = true;
  String _searchQuery = "";
  String _statusFilter = "Semua"; // "Semua", "available", "occupied"

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchTables();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        context.read<AnalyticsController>().refreshData();
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchTables() async {
    setState(() => _isLoading = true);
    try {
      final db = Provider.of<AppDatabase>(context, listen: false);
      final data = await (db.select(db.storeTables)
            ..where((t) => t.storeId.equals(widget.storeId))
            ..orderBy([(t) => drift.OrderingTerm.asc(t.name)]))
          .get();
      setState(() {
        _tables = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching tables: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addTable() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Tambah Meja Baru",
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: "Contoh: Meja 01, VIP 1",
            hintStyle: GoogleFonts.openSans(color: Colors.grey),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Batal", style: GoogleFonts.openSans(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text("Simpan", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty) {
      if (!mounted) return;
      final db = Provider.of<AppDatabase>(context, listen: false);
      await db.into(db.storeTables).insert(
            StoreTablesCompanion.insert(
              id: const Uuid().v4(),
              storeId: drift.Value(widget.storeId),
              name: name,
              status: const drift.Value('available'),
              createdAt: drift.Value(DateTime.now()),
            ),
          );
      _fetchTables();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Meja $name berhasil ditambahkan"),
            backgroundColor: const Color(0xFF059669),
          ),
        );
      }
    }
  }

  Future<void> _editTable(StoreTable table) async {
    final controller = TextEditingController(text: table.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Edit Nama Meja",
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: "Contoh: Meja 01, VIP 1",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Batal", style: GoogleFonts.openSans(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text("Simpan", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty && name != table.name) {
      if (!mounted) return;
      final db = Provider.of<AppDatabase>(context, listen: false);
      await (db.update(db.storeTables)..where((t) => t.id.equals(table.id))).write(
        StoreTablesCompanion(name: drift.Value(name)),
      );
      _fetchTables();
    }
  }

  Future<void> _updateTableStatus(StoreTable table, String newStatus) async {
    final db = Provider.of<AppDatabase>(context, listen: false);
    await (db.update(db.storeTables)..where((t) => t.id.equals(table.id))).write(
      StoreTablesCompanion(status: drift.Value(newStatus)),
    );
    _fetchTables();
    if (mounted) {
      final isFree = newStatus == 'available';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isFree
                ? "${table.name} berhasil dikosongkan (Tersedia)."
                : "${table.name} ditandai sebagai Terisi / Menunggu.",
          ),
          backgroundColor: isFree ? const Color(0xFF059669) : Colors.amber.shade800,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _deleteTable(StoreTable table) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => KasirDialog(
        title: "Hapus ${table.name}?",
        message: "Data konfigurasi meja ini akan dihapus permanen dari sistem.",
        icon: Icons.delete_outline_rounded,
        iconColor: Colors.redAccent,
        isDestructive: true,
        primaryActionLabel: "Hapus Meja",
        onPrimaryAction: () => Navigator.pop(ctx, true),
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      final db = Provider.of<AppDatabase>(context, listen: false);
      await (db.delete(db.storeTables)..where((t) => t.id.equals(table.id))).go();
      _fetchTables();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${table.name} berhasil dihapus"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showResetTableTrendsDialog(
      BuildContext context, AnalyticsController controller) {
    showDialog(
      context: context,
      builder: (ctx) => KasirDialog(
        title: "Reset Data Tren Meja?",
        message:
            "Data pemakaian meja pada riwayat transaksi akan dihapus dari statistik tren sehingga angka okupansi kembali ke 0.\n\nTindakan ini tidak menghapus daftar meja Anda.",
        icon: Icons.restart_alt_rounded,
        iconColor: const Color(0xFFEF4444),
        isDestructive: true,
        primaryActionLabel: "Reset Data Meja",
        onPrimaryAction: () async {
          Navigator.pop(ctx);
          await controller.resetTableTrendsData();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("✓ Data tren okupansi meja berhasil direset!"),
                backgroundColor: Color(0xFF059669),
              ),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final analyticsCtrl = context.watch<AnalyticsController>();
    final topTables = analyticsCtrl.topTables;

    final availableCount = _tables.where((t) => t.status == 'available').length;
    final occupiedCount = _tables.where((t) => t.status != 'available').length;
    final favoriteTable = topTables.isNotEmpty ? topTables.first['name'] as String : "-";
    final favoriteOccupancy = topTables.isNotEmpty ? topTables.first['occupancy'] as int : 0;

    // Filter tables for Tab 1
    final filteredTables = _tables.where((t) {
      final matchSearch = t.name.toLowerCase().contains(_searchQuery.toLowerCase());
      if (!matchSearch) return false;
      if (_statusFilter == "available") return t.status == 'available';
      if (_statusFilter == "occupied") return t.status != 'available';
      return true;
    }).toList();

    // Map trends to table name for quick lookup
    final Map<String, Map<String, dynamic>> tableTrendsMap = {
      for (var item in topTables)
        (item['name'] as String).trim().toLowerCase(): item,
    };

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Manajemen & Tren Meja",
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            Text(
              "Kontrol operasional dan analisa okupansi meja",
              style: GoogleFonts.openSans(
                fontSize: 11,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ],
        ),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: Color(0xFF059669)),
            tooltip: "Tambah Meja",
            onPressed: _addTable,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF059669),
          unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
          indicatorColor: const Color(0xFF059669),
          indicatorWeight: 3,
          labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
          unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500, fontSize: 13),
          tabs: [
            Tab(
              icon: const Icon(Icons.table_restaurant_outlined, size: 20),
              text: "Kontrol Status Meja (${_tables.length})",
            ),
            const Tab(
              icon: Icon(Icons.insights_rounded, size: 20),
              text: "Tren Okupansi Meja",
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            _fetchTables(),
            analyticsCtrl.refreshData(),
          ]);
        },
        color: const Color(0xFF059669),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF059669)))
            : TabBarView(
                controller: _tabController,
                children: [
                  // ── TAB 1: KONTROL STATUS MEJA ───────────────────────────
                  _buildControlTab(
                    isDark: isDark,
                    tables: filteredTables,
                    availableCount: availableCount,
                    occupiedCount: occupiedCount,
                    favoriteTable: favoriteTable,
                    favoriteOccupancy: favoriteOccupancy,
                    trendsMap: tableTrendsMap,
                  ),

                  // ── TAB 2: TREN OKUPANSI MEJA ────────────────────────────
                  _buildTrendsTab(
                    isDark: isDark,
                    controller: analyticsCtrl,
                    topTables: topTables,
                    totalConfiguredTables: _tables.length,
                  ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addTable,
        backgroundColor: const Color(0xFF059669),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(
          "Tambah Meja",
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  // ─── TAB 1: KONTROL OPERASIONAL MEJA ──────────────────────────────────────
  Widget _buildControlTab({
    required bool isDark,
    required List<StoreTable> tables,
    required int availableCount,
    required int occupiedCount,
    required String favoriteTable,
    required int favoriteOccupancy,
    required Map<String, Map<String, dynamic>> trendsMap,
  }) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: [
        // Summary KPI Cards
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                label: "Total Meja",
                value: "${_tables.length}",
                subtext: "Dikonfigurasi",
                icon: Icons.table_restaurant_outlined,
                color: const Color(0xFF3B82F6),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricCard(
                label: "Tersedia",
                value: "$availableCount",
                subtext: "Siap ditempati",
                icon: Icons.check_circle_outline_rounded,
                color: const Color(0xFF10B981),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricCard(
                label: "Terisi",
                value: "$occupiedCount",
                subtext: "Sedang dipakai",
                icon: Icons.hourglass_top_rounded,
                color: const Color(0xFFF59E0B),
                isDark: isDark,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Best Table Highlight banner
        if (favoriteOccupancy > 0)
          PinterestCard(
            borderRadius: 12,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFECFDF5),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.emoji_events_rounded, color: Color(0xFF059669), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Meja Terfavorit Pelanggan: $favoriteTable",
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: isDark ? Colors.white : const Color(0xFF065F46),
                        ),
                      ),
                      Text(
                        "Sudah dikunjungi $favoriteOccupancy kali berdasarkan data transaksi.",
                        style: GoogleFonts.openSans(
                          fontSize: 11,
                          color: isDark ? Colors.white70 : const Color(0xFF047857),
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => _tabController.animateTo(1),
                  child: Text(
                    "Lihat Tren",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF059669),
                    ),
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 16),

        // Search Bar & Filter Chips
        TextField(
          onChanged: (val) => setState(() => _searchQuery = val),
          style: GoogleFonts.plusJakartaSans(fontSize: 13),
          decoration: InputDecoration(
            hintText: "Cari nama meja...",
            hintStyle: GoogleFonts.openSans(color: Colors.grey, fontSize: 13),
            prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF059669)),
            filled: true,
            fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip("Semua (${_tables.length})", "Semua", isDark),
              const SizedBox(width: 8),
              _buildFilterChip("🟢 Tersedia ($availableCount)", "available", isDark),
              const SizedBox(width: 8),
              _buildFilterChip("🟠 Terisi ($occupiedCount)", "occupied", isDark),
            ],
          ),
        ),

        const SizedBox(height: 14),

        if (tables.isEmpty)
          PinterestCard(
            borderRadius: 14,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.table_restaurant_outlined,
                    size: 54,
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _tables.isEmpty
                        ? "Belum ada meja dikonfigurasi"
                        : "Tidak ada meja yang cocok dengan filter",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  if (_tables.isEmpty) ...[
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _addTable,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text("Tambah Meja Pertama"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          )
        else
          ...tables.map((table) {
            final isFree = table.status == 'available';
            final trend = trendsMap[table.name.trim().toLowerCase()];
            final occupancy = trend != null ? (trend['occupancy'] as int) : 0;
            final revenue = trend != null ? (trend['revenue'] as num).toDouble() : 0.0;

            return PinterestCard(
              borderRadius: 14,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Table icon with status color
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isFree
                              ? const Color(0xFF10B981).withValues(alpha: 0.12)
                              : Colors.amber.shade700.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isFree
                                ? const Color(0xFF10B981).withValues(alpha: 0.3)
                                : Colors.amber.shade700.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Icon(
                          Icons.table_restaurant_rounded,
                          color: isFree ? const Color(0xFF10B981) : Colors.amber.shade800,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  table.name,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                InkWell(
                                  onTap: () => _editTable(table),
                                  child: Icon(
                                    Icons.edit_outlined,
                                    size: 15,
                                    color: isDark ? Colors.white54 : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            // Real-time status badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isFree
                                    ? const Color(0xFF10B981).withValues(alpha: 0.1)
                                    : Colors.amber.shade700.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isFree ? "🟢 Tersedia (Kosong)" : "🟠 Terisi / Menunggu Pesanan",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isFree ? const Color(0xFF059669) : Colors.amber.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Delete button
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                        tooltip: "Hapus Meja",
                        onPressed: () => _deleteTable(table),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  Divider(height: 1, color: isDark ? Colors.white10 : Colors.grey.shade200),
                  const SizedBox(height: 10),

                  // Occupancy Trend Stats for this table
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.insights_rounded,
                            size: 15,
                            color: occupancy > 0 ? const Color(0xFF059669) : Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            occupancy > 0
                                ? "Dipakai $occupancy kali  •  Total ${_currencyFormat.format(revenue)}"
                                : "Belum ada riwayat transaksi",
                            style: GoogleFonts.openSans(
                              fontSize: 11.5,
                              fontWeight: occupancy > 0 ? FontWeight.w600 : FontWeight.normal,
                              color: isDark
                                  ? (occupancy > 0 ? Colors.white70 : Colors.white38)
                                  : (occupancy > 0 ? const Color(0xFF334155) : Colors.grey),
                            ),
                          ),
                        ],
                      ),
                      // Quick Toggle Status button
                      InkWell(
                        onTap: () => _updateTableStatus(table, isFree ? 'waiting' : 'available'),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isFree
                                ? Colors.amber.shade600.withValues(alpha: 0.12)
                                : const Color(0xFF10B981).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isFree
                                  ? Colors.amber.shade700.withValues(alpha: 0.3)
                                  : const Color(0xFF10B981).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isFree ? Icons.person_add_alt_1_rounded : Icons.check_circle_outline_rounded,
                                size: 14,
                                color: isFree ? Colors.amber.shade800 : const Color(0xFF059669),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isFree ? "Tandai Terisi" : "Kosongkan Meja",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: isFree ? Colors.amber.shade900 : const Color(0xFF059669),
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
            );
          }),
      ],
    );
  }

  // ─── TAB 2: TREN OKUPANSI MEJA ───────────────────────────────────────────
  Widget _buildTrendsTab({
    required bool isDark,
    required AnalyticsController controller,
    required List<Map<String, dynamic>> topTables,
    required int totalConfiguredTables,
  }) {
    final maxOccupancy = topTables.isNotEmpty ? (topTables.first['occupancy'] as int) : 1;
    final totalVisits = topTables.fold<int>(0, (sum, t) => sum + (t['occupancy'] as int));
    final totalRevenue = topTables.fold<double>(0.0, (sum, t) => sum + ((t['revenue'] as num).toDouble()));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: [
        // Range Filters
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildRangeChip(controller, ChartRange.today, "Hari Ini", isDark),
              const SizedBox(width: 8),
              _buildRangeChip(controller, ChartRange.sevenDays, "7 Hari", isDark),
              const SizedBox(width: 8),
              _buildRangeChip(controller, ChartRange.thirtyDays, "30 Hari", isDark),
              const SizedBox(width: 8),
              _buildRangeChip(controller, ChartRange.month, "Bulan Ini", isDark),
              const SizedBox(width: 8),
              _buildRangeChip(controller, ChartRange.allTime, "Semua", isDark),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Header Section with Reset Button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Peringkat Okupansi Meja",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  "Meja paling banyak ditempati oleh pelanggan",
                  style: GoogleFonts.openSans(
                    fontSize: 11.5,
                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
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
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.restart_alt_rounded, size: 14, color: Color(0xFFEF4444)),
                    const SizedBox(width: 4),
                    Text(
                      "Reset Tren",
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

        const SizedBox(height: 12),

        // Total Occupancy Highlight Banner
        PinterestCard(
          borderRadius: 14,
          padding: const EdgeInsets.all(16),
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Total Kunjungan Meja",
                      style: GoogleFonts.openSans(
                        fontSize: 11.5,
                        color: isDark ? Colors.white60 : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "$totalVisits kali",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF059669),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: isDark ? Colors.white10 : Colors.grey.shade200,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Total Omset Meja",
                      style: GoogleFonts.openSans(
                        fontSize: 11.5,
                        color: isDark ? Colors.white60 : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _currencyFormat.format(totalRevenue),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        if (topTables.isEmpty)
          PinterestCard(
            borderRadius: 14,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669).withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.table_restaurant_outlined,
                    size: 38,
                    color: Color(0xFF059669),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  "Belum ada data okupansi meja pada periode ini",
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: isDark ? Colors.white70 : const Color(0xFF334155),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  "Data otomatis terkumpul saat kasir memilih nomor meja ketika memproses transaksi pesanan.",
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
          ...List.generate(topTables.length, (index) {
            final t = topTables[index];
            final name = t['name'] as String;
            final occupancy = t['occupancy'] as int;
            final revenue = (t['revenue'] as num).toDouble();
            final ratio = maxOccupancy > 0 ? (occupancy / maxOccupancy) : 0.0;
            final sharePercent = totalVisits > 0 ? ((occupancy / totalVisits) * 100).toStringAsFixed(1) : "0";

            Color rankColor = Colors.grey.shade600;
            Color rankBg = isDark ? Colors.white10 : Colors.grey.shade100;
            String medal = "";
            if (index == 0) {
              medal = "🥇 ";
              rankColor = const Color(0xFFCA8A04);
              rankBg = const Color(0xFFFACC15).withValues(alpha: 0.15);
            } else if (index == 1) {
              medal = "🥈 ";
              rankColor = const Color(0xFF64748B);
              rankBg = const Color(0xFF94A3B8).withValues(alpha: 0.15);
            } else if (index == 2) {
              medal = "🥉 ";
              rankColor = const Color(0xFFB45309);
              rankBg = const Color(0xFFD97706).withValues(alpha: 0.15);
            }

            return PinterestCard(
              borderRadius: 14,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Rank pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: rankBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "$medal#${index + 1}",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: rankColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
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
                                fontSize: 15,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              "$sharePercent% dari total pemakaian meja",
                              style: GoogleFonts.openSans(
                                fontSize: 11,
                                color: isDark ? Colors.white54 : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "$occupancy kali",
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: const Color(0xFF059669),
                            ),
                          ),
                          Text(
                            _currencyFormat.format(revenue),
                            style: GoogleFonts.openSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
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
                          minHeight: 7,
                          backgroundColor: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF059669)),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  // ─── HELPERS ─────────────────────────────────────────────────────────────
  Widget _buildMetricCard({
    required String label,
    required String value,
    required String subtext,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return PinterestCard(
      borderRadius: 14,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
              Icon(icon, size: 16, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtext,
            style: GoogleFonts.openSans(
              fontSize: 9.5,
              color: isDark ? Colors.white38 : Colors.grey,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, bool isDark) {
    final isSelected = _statusFilter == value;
    return InkWell(
      onTap: () => setState(() => _statusFilter = value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF059669)
              : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF059669) : (isDark ? Colors.white10 : Colors.grey.shade300),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF334155)),
          ),
        ),
      ),
    );
  }

  Widget _buildRangeChip(
    AnalyticsController controller,
    ChartRange range,
    String label,
    bool isDark,
  ) {
    final isSelected = controller.selectedRange == range;
    return InkWell(
      onTap: () => controller.setRange(range),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF059669)
              : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF059669) : (isDark ? Colors.white10 : Colors.grey.shade300),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF334155)),
          ),
        ),
      ),
    );
  }
}
