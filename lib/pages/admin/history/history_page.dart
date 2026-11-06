import 'package:open_filex/open_filex.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../controllers/admin_controller.dart';
import 'tabs/transactions_tab.dart';
import '../../../services/export_service.dart';
import '../../../services/platform/file_manager.dart';
import 'package:intl/intl.dart';
import '../../../services/app_database.dart';
import 'package:drift/drift.dart' hide Column;
import '../../../widgets/custom_toast.dart';
import '../../../widgets/reset_transactions_dialog.dart';

class HistoryPage extends StatefulWidget {
  final String? storeId;
  final VoidCallback? onMenuPressed;
  final VoidCallback? onBack;
  final bool showSidebar;
  const HistoryPage({
    super.key,
    this.storeId,
    this.onMenuPressed,
    this.onBack,
    this.showSidebar = true,
  });

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String? _storeId;
  bool _isLoading = true;
  GlobalKey<TransactionsTabState> _tabKey = GlobalKey<TransactionsTabState>();

  @override
  void initState() {
    super.initState();
    _storeId = widget.storeId;
    if (_storeId == null) {
      _loadStoreId();
    } else {
      _isLoading = false;
    }
  }

  Future<void> _loadStoreId() async {
    final adminCtrl = Provider.of<AdminController>(context, listen: false);
    if (mounted) {
      setState(() {
        _storeId = adminCtrl.storeId;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final content = Scaffold(
            backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
            appBar: AppBar(
              title: Text(
                "Riwayat Transaksi",
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF2D3436),
                  fontSize: 18,
                ),
              ),
              backgroundColor: isDark ? const Color(0xFF1A1C1E) : Colors.white,
              elevation: 0,
              centerTitle: false,
              automaticallyImplyLeading: false,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(
                  color: isDark ? const Color(0xFF374151) : const Color(0xFFE2E8F0),
                  height: 1,
                ),
              ),
              actions: [
                Consumer<AdminController>(
                  builder: (context, adminCtrl, _) {
                    final isAdmin = adminCtrl.role == 'admin' || adminCtrl.role == 'owner';
                    return Theme(
                      data: Theme.of(context).copyWith(
                        hoverColor: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
                      ),
                      child: PopupMenuButton<String>(
                        offset: const Offset(0, 44),
                        elevation: 8,
                        surfaceTintColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: isDark ? const Color(0xFF475569) : const Color(0xFF1E293B),
                            width: 1.2,
                          ),
                        ),
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        icon: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark ? const Color(0xFF374151) : const Color(0xFFCBD5E1),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.settings_outlined,
                            size: 20,
                            color: isDark ? Colors.white70 : const Color(0xFF475569),
                          ),
                        ),
                        tooltip: "Pengaturan & Ekspor",
                        onSelected: (value) {
                          if (value == 'export_pdf') {
                            _handleExport('pdf');
                          } else if (value == 'export_excel') {
                            _handleExport('excel');
                          } else if (value == 'export_csv') {
                            _handleExport('csv');
                          } else if (value == 'reset_transactions') {
                            if (_storeId != null) {
                              ResetTransactionsDialog.show(
                                context,
                                storeId: _storeId!,
                                onResetSuccess: () {
                                  setState(() {
                                    _tabKey = GlobalKey<TransactionsTabState>();
                                  });
                                },
                              );
                            }
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem<String>(
                            value: 'export_pdf',
                            child: Row(
                              children: [
                                const Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent, size: 20),
                                const SizedBox(width: 10),
                                Text(
                                  "Ekspor PDF",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'export_excel',
                            child: Row(
                              children: [
                                const Icon(Icons.table_chart_rounded, color: Color(0xFF00BF63), size: 20),
                                const SizedBox(width: 10),
                                Text(
                                  "Ekspor Excel",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'export_csv',
                            child: Row(
                              children: [
                                const Icon(Icons.description_outlined, color: Color(0xFF0D9488), size: 20),
                                const SizedBox(width: 10),
                                Text(
                                  "Ekspor CSV",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isAdmin) ...[
                            const PopupMenuDivider(height: 12),
                            PopupMenuItem<String>(
                              value: 'reset_transactions',
                              child: Row(
                                children: [
                                  const Icon(Icons.delete_sweep_rounded, color: Color(0xFFEF4444), size: 20),
                                  const SizedBox(width: 10),
                                  Text(
                                    "Hapus Riwayat Transaksi",
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFFEF4444),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
              ],
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: isDark ? Colors.white : const Color(0xFF2D3436),
                ),
                onPressed: () {
                  if (widget.onBack != null) {
                    widget.onBack!();
                  } else if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                },
              ),
            ),
            body: Consumer<AdminController>(
              builder: (context, adminCtrl, child) {
                if (_isLoading || adminCtrl.isInitializing) {
                  return const Center(child: CupertinoActivityIndicator());
                }

                if (_storeId == null) {
                  return const Center(child: Text("Toko tidak ditemukan"));
                }

                return TransactionsTab(key: _tabKey, storeId: _storeId!);
              },
            ),
          );

          return content;
        },
      ),
    );
  }


  Future<void> _handleExport(String type) async {
    if (_storeId == null) return;

    final db = context.read<AppDatabase>();
    final exportService = ExportService();

    try {
      final tabState = _tabKey.currentState;
      final filterLabel = tabState?.selectedFilter ?? 'Semua';
      final startDate = tabState?.currentStartDate;
      final endDate = tabState?.currentEndDate;

      final query = db.select(db.transactions)..where((t) => t.storeId.equals(_storeId!));
      if (startDate != null && endDate != null) {
        query.where((t) => t.createdAt.isBiggerOrEqualValue(startDate) & t.createdAt.isSmallerOrEqualValue(endDate));
      }
      query.orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
      final transactions = await query.get();

      if (transactions.isEmpty) {
        if (mounted) {
          final msg = filterLabel != 'Semua'
              ? "Tidak ada transaksi untuk periode $filterLabel"
              : "Tidak ada transaksi untuk diekspor";
          CustomToast.show(context, msg, isError: true);
        }
        return;
      }

      Uint8List bytes;
      String filename;
      String mimeType;
      final activePeriod = filterLabel != 'Semua' ? filterLabel : null;

      if (type == 'pdf') {
        bytes = await exportService.generateTransactionsPdf(
          "Kakilima Pos",
          transactions,
          periodLabel: activePeriod,
          startDate: startDate,
          endDate: endDate,
        );
        filename =
            "Laporan_Transaksi_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf";
        mimeType = "application/pdf";
      } else if (type == 'excel') {
        bytes = await exportService.generateTransactionsExcel(
          "Kakilima Pos",
          transactions,
          periodLabel: activePeriod,
          startDate: startDate,
          endDate: endDate,
        );
        filename =
            "Laporan_Transaksi_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx";
        mimeType =
            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
      } else {
        final effStart = startDate ?? (transactions.isNotEmpty ? (transactions.last.createdAt ?? DateTime.now()) : DateTime.now());
        final effEnd = endDate ?? (transactions.isNotEmpty ? (transactions.first.createdAt ?? DateTime.now()) : DateTime.now());
        bytes = exportService.generateTransactionsCsv(
          storeName: "Kakilima Pos",
          startDate: effStart,
          endDate: effEnd,
          transactions: transactions,
        );
        filename =
            "Laporan_Transaksi_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv";
        mimeType = "text/csv";
      }

      final savedPath = await FileManager().saveAndShareBytes(
        filename,
        bytes,
        mimeType: mimeType,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Laporan berhasil disimpan di folder Download\n()',
              style: GoogleFonts.openSans(fontSize: 13, color: Colors.white),
            ),
            backgroundColor: const Color(0xFF00BF63),
            duration: const Duration(seconds: 6),
            action: (savedPath != null)
                ? SnackBarAction(
                    label: 'Buka',
                    textColor: Colors.white,
                    onPressed: () => OpenFilex.open(savedPath),
                  )
                : null,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(context, "Gagal ekspor: $e", isError: true);
      }
    }
  }
}
