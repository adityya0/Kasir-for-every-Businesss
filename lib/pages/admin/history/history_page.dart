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
import '../../../controllers/settings_controller.dart';
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
  Key _tabKey = UniqueKey();

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
                    "Riwayat Transaksi",
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF2D3436),
                      fontSize: 18,
                    ),
                  ),
                ],
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
                    if (!isAdmin || _storeId == null) return const SizedBox.shrink();
                    return IconButton(
                      onPressed: () => ResetTransactionsDialog.show(
                        context,
                        storeId: _storeId!,
                        onResetSuccess: () {
                          setState(() {
                            _tabKey = UniqueKey();
                          });
                        },
                      ),
                      icon: const Icon(Icons.delete_sweep_rounded, color: Color(0xFFEF4444)),
                      tooltip: "Reset Riwayat Transaksi",
                    );
                  },
                ),
                IconButton(
                  onPressed: () => _showExportMenu(context),
                  icon: const Icon(Icons.ios_share_rounded),
                  tooltip: SettingsController.instance.getString(
                    'export_report',
                  ),
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

  void _showExportMenu(BuildContext context) {
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
                SettingsController.instance.getString('export_history_title'),
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: Text(SettingsController.instance.getString('export_pdf')),
              onTap: () {
                Navigator.pop(context);
                _handleExport('pdf');
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart, color: Colors.green),
              title: Text(
                SettingsController.instance.getString('export_excel'),
              ),
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

  Future<void> _handleExport(String type) async {
    if (_storeId == null) return;

    final db = context.read<AppDatabase>();
    final exportService = ExportService();

    try {
      final transactions =
          await (db.select(db.transactions)
                ..where((t) => t.storeId.equals(_storeId!))
                ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
              .get();

      if (transactions.isEmpty) {
        if (mounted) {
          CustomToast.show(context, "Tidak ada transaksi untuk diekspor", isError: true);
        }
        return;
      }

      Uint8List bytes;
      String filename;
      String mimeType;

      if (type == 'pdf') {
        bytes = await exportService.generateTransactionsPdf(
          "Warkop Alam POS",
          transactions,
        );
        filename =
            "Laporan_Transaksi_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf";
        mimeType = "application/pdf";
      } else {
        bytes = await exportService.generateTransactionsExcel(
          "Warkop Alam POS",
          transactions,
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
      if (mounted) {
        CustomToast.show(context, "Gagal ekspor: $e", isError: true);
      }
    }
  }
}
