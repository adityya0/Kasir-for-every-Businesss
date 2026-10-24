import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/app_database.dart';
import '../services/report_service.dart';
import '../controllers/analytics_controller.dart';
import 'kasir_dialog.dart';

class ResetTransactionsDialog extends StatefulWidget {
  final String storeId;
  final VoidCallback? onResetSuccess;

  const ResetTransactionsDialog({
    super.key,
    required this.storeId,
    this.onResetSuccess,
  });

  static Future<void> show(
    BuildContext context, {
    required String storeId,
    VoidCallback? onResetSuccess,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ResetTransactionsDialog(
        storeId: storeId,
        onResetSuccess: onResetSuccess,
      ),
    );
  }

  @override
  State<ResetTransactionsDialog> createState() => _ResetTransactionsDialogState();
}

class _ResetTransactionsDialogState extends State<ResetTransactionsDialog> {
  bool _restoreStock = false;
  bool _isLoading = false;
  int _transactionCount = 0;
  bool _isCounting = true;

  @override
  void initState() {
    super.initState();
    _countTransactions();
  }

  Future<void> _countTransactions() async {
    try {
      final db = context.read<AppDatabase>();
      final txs = await (db.select(db.transactions)
            ..where((t) => t.storeId.equals(widget.storeId)))
          .get();
      if (mounted) {
        setState(() {
          _transactionCount = txs.length;
          _isCounting = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isCounting = false);
    }
  }

  Future<void> _executeReset() async {
    setState(() => _isLoading = true);
    try {
      final db = context.read<AppDatabase>();
      final reportService = ReportService(db);
      final deletedCount = await reportService.resetStoreTransactions(
        widget.storeId,
        restoreStock: _restoreStock,
      );

      // Refresh Analytics controller
      if (mounted) {
        try {
          context.read<AnalyticsController>().refreshData();
        } catch (_) {}
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "✓ Berhasil mereset $deletedCount riwayat transaksi & analitik tren ke 0!",
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 3),
          ),
        );
        widget.onResetSuccess?.call();
      }
    } catch (e) {
      debugPrint("Error resetting transactions: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal mereset data: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return KasirDialog(
      title: "Reset Riwayat & Tren",
      icon: Icons.delete_sweep_rounded,
      iconColor: const Color(0xFFEF4444),
      isDestructive: true,
      content: _isLoading
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: Color(0xFFEF4444)),
                  const SizedBox(height: 16),
                  Text(
                    "Sedang mereset riwayat transaksi & data tren...",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : const Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFFEF4444),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Semua riwayat transaksi dan grafik tren produk terlaris akan dihapus dan kembali ke 0. Data produk, kategori, pelanggan, dan akun tetap aman.",
                          style: GoogleFonts.openSans(
                            fontSize: 12,
                            color: isDark ? Colors.white70 : const Color(0xFF334155),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Data stats
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Transaksi yang akan dihapus:",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white70 : const Color(0xFF475569),
                        ),
                      ),
                      _isCounting
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              "$_transactionCount data",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFEF4444),
                              ),
                            ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Restore stock checkbox option
                InkWell(
                  onTap: () => setState(() => _restoreStock = !_restoreStock),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Checkbox(
                          value: _restoreStock,
                          onChanged: (val) => setState(() => _restoreStock = val ?? false),
                          activeColor: const Color(0xFFEF4444),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Pulihkan stok barang yang terjual",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                                ),
                              ),
                              Text(
                                "Tambahkan kembali kuantitas stok barang yang ada pada transaksi",
                                style: GoogleFonts.openSans(
                                  fontSize: 11,
                                  color: isDark ? Colors.white54 : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      primaryActionLabel: _isLoading ? null : "Ya, Hapus & Reset Semua",
      onPrimaryAction: _isLoading ? null : _executeReset,
      secondaryActionLabel: _isLoading ? null : "Batal",
      onSecondaryAction: _isLoading ? null : () => Navigator.pop(context),
    );
  }
}
