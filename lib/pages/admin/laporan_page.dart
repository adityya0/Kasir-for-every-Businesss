import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/app_database.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' hide Column;

import '../../services/export_service.dart';
import '../../services/platform/file_manager.dart';

class LaporanPage extends StatefulWidget {
  final String storeId;
  const LaporanPage({super.key, required this.storeId});

  @override
  State<LaporanPage> createState() => _LaporanPageState();
}

class _LaporanPageState extends State<LaporanPage> {
  bool _isLoading = true;
  List<Transaction> _transactions = [];
  final _exportService = ExportService();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final db = context.read<AppDatabase>();
      final data =
          await (db.select(db.transactions)
                ..where((t) => t.storeId.equals(widget.storeId))
                ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
              .get();

      if (mounted) {
        setState(() {
          _transactions = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("LaporanPage Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleExport(String type) async {
    if (_transactions.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      Uint8List bytes;
      String filename;
      String mimeType;

      if (type == 'pdf') {
        bytes = await _exportService.generateTransactionsPdf(
          "Warkop Alam POS",
          _transactions,
        );
        filename =
            "Laporan_Transaksi_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf";
        mimeType = "application/pdf";
      } else {
        bytes = await _exportService.generateTransactionsExcel(
          "Warkop Alam POS",
          _transactions,
        );
        filename =
            "Laporan_Transaksi_${DateFormat('yyyyMMdd').format(DateTime.now())}.xlsx";
        mimeType =
            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
      }

      await FileManager().saveAndShareBytes(
        filename,
        bytes,
        mimeType: mimeType,
      );
    } catch (e) {
      debugPrint("Export Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Gagal ekspor: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showExportMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                "Pilih Format Ekspor",
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: const Text("Ekspor PDF"),
              onTap: () {
                Navigator.pop(context);
                _handleExport('pdf');
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart, color: Colors.green),
              title: const Text("Ekspor Excel"),
              onTap: () {
                Navigator.pop(context);
                _handleExport('excel');
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(title: const Text("Laporan Penjualan")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    double totalHariIni = 0;
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);

    // Menghitung omzet hari ini
    for (var tx in _transactions) {
      final date = tx.createdAt!;
      if (!date.isBefore(startOfToday)) {
        totalHariIni += tx.totalAmount ?? 0;
      } else {
        break; // Optimized: transactions are ordered descending
      }
    }

    final todayTransactions = _transactions.where((tx) {
      final date = tx.createdAt!;
      return !date.isBefore(startOfToday);
    }).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Laporan Penjualan"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _transactions.isEmpty ? null : _showExportMenu,
            icon: const Icon(Icons.ios_share_rounded),
            tooltip: "Ekspor Laporan",
          ),
          const SizedBox(width: 8),
        ],
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : const Color(0xFF2D3436),
        ),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: isDark ? Colors.white : const Color(0xFF2D3436),
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchData,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1E1E1E), const Color(0xFF121212)]
                      : [const Color(0xFF003566), const Color(0xFF001D3D)],
                ),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    "Omzet Hari Ini",
                    style: GoogleFonts.openSans(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  Text(
                    currency.format(totalHariIni),
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    "${todayTransactions.length} Transaksi Hari Ini",
                    style: GoogleFonts.openSans(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                "Riwayat Transaksi Hari Ini",
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF2D3436),
                ),
              ),
            ),
            Expanded(
              child: todayTransactions.isEmpty
                  ? Center(
                      child: Text(
                        "Tidak ada transaksi hari ini",
                        style: GoogleFonts.openSans(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: todayTransactions.length,
                      itemBuilder: (context, index) {
                        final tx = todayTransactions[index];

                        return Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: isDark ? 0.2 : 0.03,
                                ),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue.withValues(
                                alpha: 0.1,
                              ),
                              child: const Icon(
                                Icons.receipt_long,
                                color: Colors.blue,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              "Total: ${currency.format(tx.totalAmount)}",
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF2D3436),
                              ),
                            ),
                            subtitle: Text(
                              DateFormat(
                                'dd MMM yyyy, HH:mm',
                              ).format(tx.createdAt!),
                              style: GoogleFonts.openSans(
                                color: isDark
                                    ? Colors.white60
                                    : Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                tx.paymentMethod.toString().toUpperCase(),
                                style: GoogleFonts.openSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.grey[700],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

