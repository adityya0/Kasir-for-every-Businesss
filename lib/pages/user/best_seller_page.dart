import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' as drift;
import '../../services/app_database.dart';
import '../../controllers/admin_controller.dart';
import '../../services/platform/file_manager.dart';
import '../../widgets/reset_transactions_dialog.dart';

enum BestSellerRange { today, sevenDays, thirtyDays, month, allTime }

class BestSellerPage extends StatefulWidget {
  final VoidCallback? onBack;

  const BestSellerPage({super.key, this.onBack});

  @override
  State<BestSellerPage> createState() => _BestSellerPageState();
}

class _BestSellerPageState extends State<BestSellerPage> {
  BestSellerRange _selectedRange = BestSellerRange.sevenDays;
  String _searchQuery = "";
  bool _isLoading = true;
  List<Map<String, dynamic>> _allProducts = [];
  final _currencyFormat = NumberFormat.currency(
    locale: 'id',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchTopProducts();
    });
  }

  Future<void> _fetchTopProducts() async {
    setState(() => _isLoading = true);
    try {
      final db = context.read<AppDatabase>();
      final admin = context.read<AdminController>();
      final storeId = admin.storeId;

      if (storeId == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final now = DateTime.now();
      DateTime startDate;

      switch (_selectedRange) {
        case BestSellerRange.today:
          startDate = DateTime(now.year, now.month, now.day);
          break;
        case BestSellerRange.sevenDays:
          startDate = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
          break;
        case BestSellerRange.thirtyDays:
          startDate = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 29));
          break;
        case BestSellerRange.month:
          startDate = DateTime(now.year, now.month, 1);
          break;
        case BestSellerRange.allTime:
          startDate = DateTime(2020, 1, 1);
          break;
      }

      final query = db.selectOnly(db.transactionItems).join([
        drift.innerJoin(
          db.transactions,
          db.transactions.id.equalsExp(db.transactionItems.transactionId),
        ),
        drift.leftOuterJoin(
          db.products,
          db.products.id.equalsExp(db.transactionItems.productId),
        ),
      ]);

      query.addColumns([
        db.transactionItems.productId,
        db.transactionItems.productName,
        db.transactionItems.unitPrice,
        db.transactionItems.quantity.sum(),
        db.products.imageUrl,
        db.products.salePrice,
      ]);

      query.where(
        db.transactions.storeId.equals(storeId) &
            db.transactions.createdAt.isBiggerOrEqualValue(startDate),
      );

      query.groupBy([
        db.transactionItems.productId,
        db.transactionItems.productName,
        db.transactionItems.unitPrice,
        db.products.imageUrl,
        db.products.salePrice,
      ]);

      query.orderBy([
        drift.OrderingTerm(
          expression: db.transactionItems.quantity.sum(),
          mode: drift.OrderingMode.desc,
        ),
      ]);

      final result = await query.get();

      // Aggregate if same productId appeared with slightly different price lines
      final Map<String, Map<String, dynamic>> aggregated = {};
      for (var row in result) {
        final id = row.read(db.transactionItems.productId) ?? 'unknown';
        final name = row.read(db.transactionItems.productName) ?? 'Unnamed';
        final qty = (row.read(db.transactionItems.quantity.sum()) ?? 0).toDouble();
        final img = row.read(db.products.imageUrl);
        final price = row.read(db.products.salePrice) ?? row.read(db.transactionItems.unitPrice) ?? 0.0;

        if (aggregated.containsKey(id)) {
          aggregated[id]!['sales'] = (aggregated[id]!['sales'] as double) + qty;
        } else {
          aggregated[id] = {
            'id': id,
            'name': name,
            'sales': qty,
            'price': price,
            'imageUrl': img,
          };
        }
      }

      final list = aggregated.values.toList();
      list.sort((a, b) => (b['sales'] as double).compareTo(a['sales'] as double));

      if (mounted) {
        setState(() {
          _allProducts = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching best sellers: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const primaryColor = Color(0xFF00BF63);
    final borderColor = isDark ? const Color(0xFF374151) : const Color(0xFFCBD5E1);

    final filtered = _allProducts.where((p) {
      final name = (p['name'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();

    final maxSales = _allProducts.isNotEmpty ? (_allProducts.first['sales'] as double) : 1.0;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Produk Terlaris (Best Seller)",
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        elevation: 0,
        centerTitle: false,
        leading: widget.onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBack,
              )
            : null,
        actions: [
          Consumer<AdminController>(
            builder: (context, adminCtrl, _) {
              final isAdmin = adminCtrl.role == 'admin' || adminCtrl.role == 'owner';
              final storeId = adminCtrl.storeId;
              if (!isAdmin || storeId == null) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.delete_sweep_rounded, color: Color(0xFFEF4444)),
                tooltip: "Reset Tren & Riwayat Transaksi",
                onPressed: () => ResetTransactionsDialog.show(
                  context,
                  storeId: storeId,
                  onResetSuccess: _fetchTopProducts,
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: "Muat Ulang",
            onPressed: _fetchTopProducts,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 880),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Card & Info
                      _buildHeaderCard(isDark, borderColor, primaryColor),
                      const SizedBox(height: 18),

                      // Period Selector
                      _buildPeriodSelector(isDark, borderColor, primaryColor),
                      const SizedBox(height: 18),

                      // Search Bar
                      _buildSearchBar(isDark, borderColor),
                      const SizedBox(height: 24),

                      if (filtered.isEmpty)
                        _buildEmptyState(isDark, borderColor)
                      else ...[
                        // Top 3 Podium if no active search filter and we have items
                        if (_searchQuery.isEmpty && filtered.length >= 3) ...[
                          _buildPodiumSection(filtered.take(3).toList(), isDark, borderColor, primaryColor),
                          const SizedBox(height: 28),
                        ],

                        // Full Ranked List
                        _buildRankedList(filtered, maxSales, isDark, borderColor, primaryColor),
                      ],
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildHeaderCard(bool isDark, Color borderColor, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.local_fire_department_rounded, color: primaryColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Peringkat Menu & Produk Terlaris",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                Text(
                  "Gunakan data ini untuk rekomendasi menu ke pelanggan saat pemesanan",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector(bool isDark, Color borderColor, Color primaryColor) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip(BestSellerRange.today, "Hari Ini", isDark, borderColor, primaryColor),
          const SizedBox(width: 8),
          _buildFilterChip(BestSellerRange.sevenDays, "7 Hari", isDark, borderColor, primaryColor),
          const SizedBox(width: 8),
          _buildFilterChip(BestSellerRange.thirtyDays, "30 Hari", isDark, borderColor, primaryColor),
          const SizedBox(width: 8),
          _buildFilterChip(BestSellerRange.month, "Bulan Ini", isDark, borderColor, primaryColor),
          const SizedBox(width: 8),
          _buildFilterChip(BestSellerRange.allTime, "Semua Waktu", isDark, borderColor, primaryColor),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    BestSellerRange range,
    String label,
    bool isDark,
    Color borderColor,
    Color primaryColor,
  ) {
    final isSelected = _selectedRange == range;
    return InkWell(
      onTap: () {
        if (_selectedRange != range) {
          setState(() => _selectedRange = range);
          _fetchTopProducts();
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? primaryColor : borderColor,
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF334155)),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(bool isDark, Color borderColor) {
    return TextField(
      onChanged: (val) => setState(() => _searchQuery = val),
      decoration: InputDecoration(
        hintText: "Cari menu / produk...",
        hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.grey.shade400),
        prefixIcon: const Icon(Icons.search_rounded, size: 20),
        filled: true,
        fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: borderColor, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: borderColor, width: 1.2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  // ─── Top 3 Podium Section ─────────────────────────────────────────────
  Widget _buildPodiumSection(
    List<Map<String, dynamic>> top3,
    bool isDark,
    Color borderColor,
    Color primaryColor,
  ) {
    final first = top3[0];
    final second = top3.length > 1 ? top3[1] : null;
    final third = top3.length > 2 ? top3[2] : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // #2 Silver (Left)
        if (second != null)
          Expanded(
            child: _buildPodiumCard(
              second,
              rank: 2,
              badgeColor: const Color(0xFF94A3B8),
              height: 180,
              isDark: isDark,
              borderColor: borderColor,
            ),
          ),
        const SizedBox(width: 10),

        // #1 Gold (Center, Taller)
        Expanded(
          child: _buildPodiumCard(
            first,
            rank: 1,
            badgeColor: const Color(0xFFF59E0B),
            height: 205,
            isDark: isDark,
            borderColor: borderColor,
          ),
        ),
        const SizedBox(width: 10),

        // #3 Bronze (Right)
        if (third != null)
          Expanded(
            child: _buildPodiumCard(
              third,
              rank: 3,
              badgeColor: const Color(0xFFD97706),
              height: 165,
              isDark: isDark,
              borderColor: borderColor,
            ),
          ),
      ],
    );
  }

  Widget _buildPodiumCard(
    Map<String, dynamic> item, {
    required int rank,
    required Color badgeColor,
    required double height,
    required bool isDark,
    required Color borderColor,
  }) {
    final sales = (item['sales'] as double).toInt();
    final name = item['name'] ?? 'Menu';
    final imageUrl = item['imageUrl'] as String?;

    return Container(
      height: height,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: rank == 1 ? badgeColor : borderColor,
          width: rank == 1 ? 2 : 1.2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              "#$rank Best Seller",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: badgeColor,
              ),
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 44,
              height: 44,
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
              child: (imageUrl != null && imageUrl.isNotEmpty)
                  ? Image(
                      image: FileManager().getImageProvider(imageUrl),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.fastfood, size: 20),
                    )
                  : const Icon(Icons.fastfood, size: 20),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            "$sales Terjual",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF00BF63),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Ranked List ──────────────────────────────────────────────────────
  Widget _buildRankedList(
    List<Map<String, dynamic>> items,
    double maxSales,
    bool isDark,
    Color borderColor,
    Color primaryColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Daftar Lengkap Produk Terlaris",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 14),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => Divider(color: borderColor, height: 16),
            itemBuilder: (context, index) {
              final item = items[index];
              final rank = index + 1;
              final sales = (item['sales'] as double).toInt();
              final price = (item['price'] as num?)?.toDouble() ?? 0.0;
              final name = item['name'] ?? 'Unnamed';
              final imageUrl = item['imageUrl'] as String?;
              final ratio = maxSales > 0 ? (sales / maxSales) : 0.0;

              return Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: rank <= 3
                          ? primaryColor.withValues(alpha: 0.1)
                          : (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "$rank",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: rank <= 3 ? primaryColor : Colors.grey.shade600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      width: 40,
                      height: 40,
                      color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                      child: (imageUrl != null && imageUrl.isNotEmpty)
                          ? Image(
                              image: FileManager().getImageProvider(imageUrl),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(Icons.fastfood, size: 20),
                            )
                          : const Icon(Icons.fastfood, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _currencyFormat.format(price),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: ratio.clamp(0.05, 1.0),
                            minHeight: 4,
                            backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              rank == 1 ? primaryColor : const Color(0xFFE67E22),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "$sales",
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        "Terjual",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: Colors.grey.shade500,
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
    );
  }

  Widget _buildEmptyState(bool isDark, Color borderColor) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Column(
        children: [
          Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            "Belum ada data penjualan pada periode ini.",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
