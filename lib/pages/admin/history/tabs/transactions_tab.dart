import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../services/app_database.dart' hide TransactionItem;
import '../../../../services/report_service.dart';
import '../../../../controllers/admin_controller.dart';
import '../widgets/transaction_item.dart';
import '../transaction_detail_page.dart';
import '../../../../widgets/reset_transactions_dialog.dart';
import '../../../../services/order_service.dart';
import '../../../../widgets/kasir_dialog.dart';
import '../../../../controllers/analytics_controller.dart';

class TransactionsTab extends StatefulWidget {
  final String storeId;
  const TransactionsTab({super.key, required this.storeId});

  @override
  State<TransactionsTab> createState() => _TransactionsTabState();
}

class _TransactionsTabState extends State<TransactionsTab> {
  late ReportService _reportService;
  bool _isLoading = true;
  List<Map<String, dynamic>> _allTransactions = [];
  List<Map<String, dynamic>> _filteredTransactions = [];
  final _searchController = TextEditingController();
  String _searchQuery = "";

  String _selectedFilter = "Semua";
  final List<String> _filters = [
    "Semua",
    "Hari Ini",
    "Kemarin",
    "Minggu Ini",
    "Bulan Ini",
  ];

  List<Map<String, dynamic>> _cashiers = [];
  String? _selectedCashierId; // null = Semua Staf (Admin only)

  double get _totalSalesFiltered {
    double total = 0;
    for (var tx in _filteredTransactions) {
      total += (tx['totalAmount'] ?? 0 as num).toDouble();
    }
    return total;
  }

  @override
  void initState() {
    super.initState();
    final db = context.read<AppDatabase>();
    _reportService = ReportService(db);
    _loadCashiers();
    _loadTransactions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCashiers() async {
    try {
      final db = context.read<AppDatabase>();
      final profiles = await (db.select(db.profiles)
            ..where((t) => t.storeId.equals(widget.storeId)))
          .get();

      if (mounted) {
        setState(() {
          _cashiers = profiles.map((p) => {
            'id': p.id,
            'name': p.fullName ?? p.email ?? 'Staff',
            'role': p.role,
          }).toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    try {
      DateTime? startDate;
      DateTime? endDate;
      final now = DateTime.now();

      if (_selectedFilter == "Hari Ini") {
        startDate = DateTime(now.year, now.month, now.day);
      } else if (_selectedFilter == "Kemarin") {
        final yesterday = now.subtract(const Duration(days: 1));
        startDate = DateTime(yesterday.year, yesterday.month, yesterday.day);
        endDate = DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59);
      } else if (_selectedFilter == "Minggu Ini") {
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        startDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
      } else if (_selectedFilter == "Bulan Ini") {
        startDate = DateTime(now.year, now.month, 1);
      }

      final adminCtrl = context.read<AdminController>();
      final bool isAdmin = adminCtrl.role == 'admin' || adminCtrl.role == 'owner';
      // If employee, strictly lock to their own user id
      final String? targetCashierId = isAdmin ? _selectedCashierId : adminCtrl.userId;

      debugPrint("TransactionsTab: storeId: ${widget.storeId}, isAdmin: $isAdmin, cashierId: $targetCashierId");

      final data = await _reportService.getAllTransactions(
        widget.storeId,
        startDate: startDate,
        endDate: endDate,
        cashierId: targetCashierId,
      );

      if (mounted) {
        setState(() {
          _allTransactions = data;
          _filterTransactions(_searchQuery);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("TransactionsTab: ERROR loading: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterTransactions(String query) {
    setState(() {
      _searchQuery = query;
      _filteredTransactions = _allTransactions.where((tx) {
        final id = tx['id'].toString().toLowerCase();
        final name = (tx['profiles']?['fullName'] ?? tx['profiles']?['name'] ?? '')
            .toString()
            .toLowerCase();
        return id.contains(query.toLowerCase()) || name.contains(query.toLowerCase());
      }).toList();
    });
  }

  void _openDetail(Map<String, dynamic> transaction) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TransactionDetailPage(transaction: transaction),
      ),
    );
    if (result == true) {
      _loadTransactions();
    }
  }

  Future<void> _deleteTransactionDirectly(Map<String, dynamic> tx) async {
    final total = (tx['totalAmount'] ?? 0 as num).toDouble();
    final txIdRaw = tx['id']?.toString() ?? '';
    final shortId = txIdRaw.length >= 8 ? txIdRaw.substring(0, 8).toUpperCase() : txIdRaw.toUpperCase();

    final currencyFormat = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => KasirDialog(
        title: "Hapus Transaksi?",
        message: "Transaksi #$shortId sebesar ${currencyFormat.format(total)} akan dihapus permanen.\n\nStok produk yang terjual akan otomatis dikembalikan ke inventaris, dan kalkulasi laporan omset/keuangan akan diperbarui.",
        icon: Icons.delete_forever_rounded,
        iconColor: Colors.red,
        isDestructive: true,
        primaryActionLabel: "Hapus Transaksi",
        onPrimaryAction: () => Navigator.pop(ctx, true),
        secondaryActionLabel: "Batal",
        onSecondaryAction: () => Navigator.pop(ctx, false),
      ),
    );

    if (shouldDelete == true && mounted) {
      try {
        final db = context.read<AppDatabase>();
        final orderService = OrderService(db);
        await orderService.deleteTransaction(txIdRaw, restoreStock: true);

        if (mounted) {
          try {
            context.read<AnalyticsController>().refreshData();
            context.read<AdminController>().loadInitialData();
          } catch (_) {}

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("✓ Transaksi berhasil dihapus dan stok telah dikembalikan"),
              backgroundColor: Color(0xFF10B981),
              duration: Duration(seconds: 2),
            ),
          );

          _loadTransactions();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Gagal menghapus transaksi: $e"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final adminCtrl = context.watch<AdminController>();
    final bool isAdmin = adminCtrl.role == 'admin' || adminCtrl.role == 'owner';

    return Column(
      children: [
        // Header Controls
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notice for Employee
              if (!isAdmin) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC0392B).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFC0392B).withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person_outline, size: 16, color: Color(0xFFC0392B)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Riwayat Transaksi Pribadi (${adminCtrl.userName ?? 'Kasir'})",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFC0392B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Search Input Bar with Reset Button
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark ? const Color(0xFF374151) : const Color(0xFFCBD5E1),
                          width: 1.2,
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: _filterTransactions,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        decoration: InputDecoration(
                          hintText: "Cari ID transaksi / nama...",
                          hintStyle: GoogleFonts.openSans(
                            fontSize: 13,
                            color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            size: 18,
                            color: isDark ? Colors.white54 : const Color(0xFF64748B),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 11),
                        ),
                      ),
                    ),
                  ),
                  if (isAdmin) ...[
                    const SizedBox(width: 8),
                    Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                          width: 1.2,
                        ),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.delete_sweep_rounded, color: Color(0xFFEF4444), size: 20),
                        tooltip: "Reset Riwayat Transaksi",
                        onPressed: () => ResetTransactionsDialog.show(
                          context,
                          storeId: widget.storeId,
                          onResetSuccess: _loadTransactions,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),

              // Date Period Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _filters.map((filter) {
                    final isSelected = _selectedFilter == filter;
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            if (_selectedFilter != filter) {
                              setState(() => _selectedFilter = filter);
                              _loadTransactions();
                            }
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFC0392B)
                                  : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFFC0392B)
                                    : (isDark ? const Color(0xFF374151) : const Color(0xFFCBD5E1)),
                                width: 1.2,
                              ),
                            ),
                            child: Text(
                              filter,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : (isDark ? Colors.white70 : const Color(0xFF475569)),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // Admin-Only Staff Filter Chips
              if (isAdmin && _cashiers.isNotEmpty) ...[
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildStaffFilterChip(
                        label: "Semua Staf",
                        isSelected: _selectedCashierId == null,
                        isDark: isDark,
                        onTap: () {
                          if (_selectedCashierId != null) {
                            setState(() => _selectedCashierId = null);
                            _loadTransactions();
                          }
                        },
                      ),
                      const SizedBox(width: 6),
                      ..._cashiers.map((c) {
                        final isSelected = _selectedCashierId == c['id'];
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: _buildStaffFilterChip(
                            label: c['name'] ?? 'Staff',
                            isSelected: isSelected,
                            isDark: isDark,
                            onTap: () {
                              if (_selectedCashierId != c['id']) {
                                setState(() => _selectedCashierId = c['id'] as String?);
                                _loadTransactions();
                              }
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        // Transactions List
        Expanded(
          child: _isLoading
              ? const Center(child: CupertinoActivityIndicator())
              : RefreshIndicator(
                  onRefresh: _loadTransactions,
                  color: const Color(0xFFC0392B),
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      // Dynamic Omset Summary Card
                      _buildOmsetSummaryCard(isDark),
                      const SizedBox(height: 8),

                      if (_filteredTransactions.isEmpty)
                        _buildEmptyState()
                      else
                        Container(
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark ? const Color(0xFF374151) : const Color(0xFFCBD5E1),
                              width: 1.2,
                            ),
                          ),
                          child: Column(
                            children: [
                              // Card Header Row
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    const SizedBox(width: 40),
                                    Expanded(
                                      flex: 3,
                                      child: Text("TRANSAKSI", style: _headerStyle(isDark)),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text("KASIR", style: _headerStyle(isDark)),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        "TOTAL",
                                        style: _headerStyle(isDark),
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                    const SizedBox(width: 24),
                                  ],
                                ),
                              ),
                              Divider(
                                height: 1,
                                color: isDark ? const Color(0xFF374151) : const Color(0xFFE2E8F0),
                              ),

                              // List items
                              ...List.generate(_filteredTransactions.length, (index) {
                                final tx = _filteredTransactions[index];
                                return TransactionItem(
                                  transaction: tx,
                                  index: index + 1,
                                  isLast: index == _filteredTransactions.length - 1,
                                  onTap: () => _openDetail(tx),
                                  onDelete: () => _deleteTransactionDirectly(tx),
                                );
                              }),
                            ],
                          ),
                        ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildStaffFilterChip({
    required String label,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF0D9488)
              : (isDark ? Colors.grey.shade900 : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF0D9488)
                : (isDark ? const Color(0xFF374151) : const Color(0xFFCBD5E1)),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : const Color(0xFF475569)),
          ),
        ),
      ),
    );
  }

  TextStyle _headerStyle(bool isDark) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.8,
      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
    );
  }

  Widget _buildOmsetSummaryCard(bool isDark) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF374151) : const Color(0xFFCBD5E1),
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFC0392B).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: Color(0xFFC0392B),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Total Terfilter ($_selectedFilter)",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "${_filteredTransactions.length} Transaksi",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Text(
            currencyFormat.format(_totalSalesFiltered),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: const Color(0xFFC0392B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.receipt_outlined, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            "Tidak ada transaksi ditemukan",
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
