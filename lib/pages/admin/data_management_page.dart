import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../services/app_database.dart';
import '../../services/export_service.dart';
import '../../services/bulk_import_service.dart';
import '../../services/platform/file_manager.dart';
import '../../controllers/admin_controller.dart';
import '../../widgets/kasir_dialog.dart';
import '../../widgets/reset_transactions_dialog.dart';
import 'package:drift/drift.dart' hide Column;

class DataManagementPage extends StatefulWidget {
  final VoidCallback? onMenuPressed;
  final VoidCallback? onBack;
  const DataManagementPage({super.key, this.onMenuPressed, this.onBack});

  @override
  State<DataManagementPage> createState() => _DataManagementPageState();
}

class _DataManagementPageState extends State<DataManagementPage> {
  final _exportService = ExportService();
  late BulkImportService _importService;
  bool _isLoading = false;

  // Consistent Color Palette
  final _colors = {
    'export': const Color(0xFF2196F3), // Blue
    'import': const Color(0xFF00BFA5), // Teal
    'restock': const Color(0xFF4CAF50), // Green
    'category': const Color(0xFF5C6BC0), // Indigo
    'danger': const Color(0xFFEF5350), // Red
    'transactions': const Color(0xFFFF9800), // Orange
  };

  @override
  void initState() {
    super.initState();
    final db = context.read<AppDatabase>();
    _importService = BulkImportService(db);
  }

  Future<void> _exportProducts() async {
    final adminCtrl = context.read<AdminController>();
    final storeId = adminCtrl.storeId;
    if (storeId == null) {
      _showError("Store belum siap. Silakan coba kembali.");
      return;
    }

    setState(() => _isLoading = true);
    try {
      final db = context.read<AppDatabase>();
      final products = await (db.select(
        db.products,
      )..where((t) => t.storeId.equals(storeId))).get();

      final bytes = await _exportService.generateProductsExcel(
        adminCtrl.storeName ?? "Warkop Alam POS",
        products,
      );

      final filename =
          "Daftar_Produk_${DateFormat('yyyyMMdd').format(DateTime.now())}.xlsx";

      await FileManager().saveAndShareBytes(
        filename,
        bytes,
        mimeType:
            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
      );
    } catch (e) {
      if (!mounted) return;
      _showError("Gagal ekspor produk: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleBulkImport() async {
    final adminCtrl = context.read<AdminController>();
    final storeId = adminCtrl.storeId;
    if (storeId == null) return;

    setState(() => _isLoading = true);
    try {
      final result = await _importService.importProducts(storeId);

      if (result['status'] == 'cancelled') return;

      if (result['status'] == 'error') {
        if (!mounted) return;
        _showError("Gagal impor: ${result['message']}");
        return;
      }

      if (result['status'] == 'success') {
        if (mounted) {
          _showImportResultDialog(
            success: result['successCount'],
            fail: result['failCount'],
            errors: result['errors'],
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      _showError("Error saat impor: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showImportResultDialog({
    required int success,
    required int fail,
    required List<String> errors,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => KasirDialog(
        title: "Hasil Impor",
        icon: success > 0 ? Icons.check_circle_rounded : Icons.info_rounded,
        iconColor: success > 0 ? _colors['import'] : Colors.orange,
        content: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildImportStat("Berhasil", success.toString(), Colors.green),
                _buildImportStat("Gagal", fail.toString(), Colors.red),
              ],
            ),
            if (errors.isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Detail Kesalahan:",
                      style: GoogleFonts.openSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        itemCount: errors.length,
                        itemBuilder: (c, i) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            "• ${errors[i]}",
                            style: GoogleFonts.openSans(
                              fontSize: 11,
                              color: Colors.red[700],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        primaryActionLabel: "Tutup",
        onPrimaryAction: () => Navigator.pop(ctx),
      ),
    );
  }

  Widget _buildImportStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.openSans(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Future<void> _exportTransactions(String type) async {
    final adminCtrl = context.read<AdminController>();
    final storeId = adminCtrl.storeId;
    if (storeId == null) {
      _showError("Store belum siap. Silakan coba kembali.");
      return;
    }

    setState(() => _isLoading = true);
    try {
      final db = context.read<AppDatabase>();
      final transactions =
          await (db.select(db.transactions)
                ..where((t) => t.storeId.equals(storeId))
                ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
              .get();

      if (transactions.isEmpty) {
        _showError("Tidak ada transaksi untuk diekspor");
        return;
      }

      Uint8List bytes;
      String filename;
      String mimeType;

      if (type == 'pdf') {
        bytes = await _exportService.generateTransactionsPdf(
          adminCtrl.storeName ?? "Warkop Alam POS",
          transactions,
        );
        filename =
            "Laporan_Transaksi_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf";
        mimeType = "application/pdf";
      } else {
        bytes = await _exportService.generateTransactionsExcel(
          adminCtrl.storeName ?? "Warkop Alam POS",
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
      if (!mounted) return;
      _showError("Gagal ekspor transaksi: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Stock Management Methods
  Future<void> _handleRestockAll() async {
    final adminCtrl = context.read<AdminController>();
    final storeId = adminCtrl.storeId;
    if (storeId == null) {
      _showError("Store belum siap. Silakan coba kembali.");
      return;
    }
    final db = context.read<AppDatabase>();

    final amount = await _showRestockAmountDialog("Restock Semua Barang");
    if (amount == null || amount <= 0) return;

    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      // Update all products with stock management enabled
      await (db.update(db.products)..where(
            (t) =>
                t.storeId.equals(storeId) &
                t.isStockManaged.equals(true) &
                t.isDeleted.equals(false),
          ))
          .write(
            ProductsCompanion.custom(
              stockQuantity: db.products.stockQuantity + Variable(amount.toDouble()),
            ),
          );

      if (!mounted) return;
      _showSuccess("Berhasil menambah $amount stok ke semua barang");
    } catch (e) {
      if (!mounted) return;
      _showError("Gagal restock: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRestockByCategory() async {
    final adminCtrl = context.read<AdminController>();
    final storeId = adminCtrl.storeId;
    if (storeId == null) {
      _showError("Store belum siap. Silakan coba kembali.");
      return;
    }
    final db = context.read<AppDatabase>();

    final categories = await (db.select(
      db.categories,
    )..where((t) => t.storeId.equals(storeId))).get();
    if (categories.isEmpty) {
      if (!mounted) return;
      _showError("Belum ada kategori");
      return;
    }

    final selectedCategory = await _showCategorySelectionDialog(categories);
    if (selectedCategory == null) return;

    final amount = await _showRestockAmountDialog(
      "Restock Kategori: ${selectedCategory.name ?? ''}",
    );
    if (amount == null || amount <= 0) return;

    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      await (db.update(db.products)..where(
            (t) =>
                t.storeId.equals(storeId) &
                t.categoryId.equals(selectedCategory.id) &
                t.isStockManaged.equals(true) &
                t.isDeleted.equals(false),
          ))
          .write(
            ProductsCompanion.custom(
              stockQuantity: db.products.stockQuantity + Variable(amount.toDouble()),
            ),
          );

      if (!mounted) return;
      _showSuccess(
        "Berhasil menambah $amount stok ke kategori ${selectedCategory.name ?? ''}",
      );
    } catch (e) {
      if (!mounted) return;
      _showError("Gagal restock kategori: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleEmptyStock(bool all) async {
    final adminCtrl = context.read<AdminController>();
    final storeId = adminCtrl.storeId;
    if (storeId == null) {
      _showError("Store belum siap. Silakan coba kembali.");
      return;
    }
    final db = context.read<AppDatabase>();
    Category? selectedCategory;

    if (!all) {
      final categories = await (db.select(
        db.categories,
      )..where((t) => t.storeId.equals(storeId))).get();
      selectedCategory = await _showCategorySelectionDialog(categories);
      if (selectedCategory == null) return;
    }

    if (!mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => KasirDialog(
        title: all ? "Kosongkan Semua Stok?" : "Kosongkan Stok Kategori?",
        message: all
            ? "Semua stok barang 'Terbatas' akan diubah menjadi 0. Tindakan ini tidak dapat dibatalkan."
            : "Stok barang '${selectedCategory?.name ?? 'Kategori'}' akan diubah menjadi 0. Tindakan ini tidak dapat dibatalkan.",
        icon: Icons.warning_amber_rounded,
        iconColor: _colors['danger'],
        isDestructive: true,
        primaryActionLabel: "Kosongkan",
        secondaryActionLabel: "Batal",
        onPrimaryAction: () => Navigator.pop(ctx, true),
      ),
    );

    if (confirm != true) return;

    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final query = db.update(db.products)
        ..where(
          (t) =>
              t.storeId.equals(storeId) &
              t.isStockManaged.equals(true) &
              t.isDeleted.equals(false),
        );

      if (!all && selectedCategory != null) {
        query.where((t) => t.categoryId.equals(selectedCategory!.id));
      }

      await query.write(const ProductsCompanion(stockQuantity: Value(0.0)));

      if (!mounted) return;
      _showSuccess("Berhasil mengosongkan stok");
    } catch (e) {
      if (!mounted) return;
      _showError("Gagal mengosongkan stok: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Dialog Helpers
  Future<int?> _showRestockAmountDialog(String title) async {
    final controller = TextEditingController();
    return showDialog<int>(
      context: context,
      builder: (ctx) => KasirDialog(
        title: title,
        icon: Icons.add_business_rounded,
        iconColor: _colors['restock'],
        content: Column(
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                labelText: "Jumlah Tambahan",
                labelStyle: GoogleFonts.openSans(fontSize: 14),
                hintText: "Contoh: 10",
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white10
                    : Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
        primaryActionLabel: "Simpan",
        secondaryActionLabel: "Batal",
        onPrimaryAction: () =>
            Navigator.pop(ctx, int.tryParse(controller.text)),
      ),
    );
  }

  Future<Category?> _showCategorySelectionDialog(
    List<Category> categories,
  ) async {
    return showDialog<Category>(
      context: context,
      builder: (ctx) => KasirDialog(
        title: "Pilih Kategori",
        icon: Icons.grid_view,
        iconColor: _colors['category'],
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => Navigator.pop(ctx, cat),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white10
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _colors['category']!.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.label,
                            size: 14,
                            color: _colors['category'],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          cat.name!,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.chevron_right,
                          size: 14,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        secondaryActionLabel: "Batal",
      ),
    );
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: _colors['danger'],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: isDark ? const Color(0xFF374151) : const Color(0xFFE2E8F0),
            height: 1,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : Colors.black87,
          ),
          onPressed: () {
            if (widget.onBack != null) {
              widget.onBack!();
            } else if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          "Manajemen Data & Stok",
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 18,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      // ── Ekspor & Impor Data ──────────────────────────────
                      _buildSectionHeader("EKSPOR & IMPOR DATA"),
                      _buildGroupedSection(
                        isDark: isDark,
                        items: [
                          _buildSettingsActionItem(
                            label: "Ekspor Produk (.xlsx)",
                            icon: Icons.inventory_2_outlined,
                            color: _colors['export']!,
                            onTap: _exportProducts,
                            isDark: isDark,
                          ),
                          _buildSettingsActionItem(
                            label: "Impor Produk (Excel)",
                            icon: Icons.cloud_upload_outlined,
                            color: _colors['import']!,
                            onTap: _handleBulkImport,
                            isDark: isDark,
                          ),
                          _buildSettingsActionItem(
                            label: "Laporan Transaksi",
                            icon: Icons.description_outlined,
                            color: _colors['transactions']!,
                            onTap: () => _showExportFormatDialog('transaksi'),
                            isDark: isDark,
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      // ── Manajemen Stok ──────────────────────────────────
                      _buildSectionHeader("MANAJEMEN STOK"),
                      _buildGroupedSection(
                        isDark: isDark,
                        items: [
                          _buildSettingsActionItem(
                            label: "Restock Semua Barang",
                            icon: Icons.playlist_add_check_rounded,
                            color: _colors['restock']!,
                            onTap: _handleRestockAll,
                            isDark: isDark,
                          ),
                          _buildSettingsActionItem(
                            label: "Restock per Kategori",
                            icon: Icons.grid_view,
                            color: _colors['category']!,
                            onTap: _handleRestockByCategory,
                            isDark: isDark,
                          ),
                          _buildSettingsActionItem(
                            label: "Kosongkan Semua Stok",
                            icon: Icons.delete_sweep_rounded,
                            color: _colors['danger']!,
                            onTap: () => _handleEmptyStock(true),
                            isDark: isDark,
                          ),
                          _buildSettingsActionItem(
                            label: "Kosongkan Stok Kategori",
                            icon: Icons.delete_outline_rounded,
                            color: _colors['danger']!,
                            onTap: () => _handleEmptyStock(false),
                            isDark: isDark,
                          ),
                          _buildSettingsActionItem(
                            label: "Reset Riwayat Transaksi & Tren",
                            icon: Icons.history_toggle_off_rounded,
                            color: _colors['danger']!,
                            onTap: () {
                              final adminCtrl = context.read<AdminController>();
                              final storeId = adminCtrl.storeId;
                              if (storeId != null) {
                                ResetTransactionsDialog.show(
                                  context,
                                  storeId: storeId,
                                );
                              }
                            },
                            isDark: isDark,
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  // ── Section header ────────────────────────────────────────────────────────
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ── Grouped section container ─────────────────────────────────────────────
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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

  // ── Settings-style list item ──────────────────────────────────────────────
  Widget _buildSettingsActionItem({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 22),
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
        Icons.chevron_right_rounded,
        color: isDark ? Colors.white24 : Colors.grey.shade400,
        size: 20,
      ),
    );
  }

  // ── Cleaned up legacy methods ──


  void _showExportFormatDialog(String category) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  "Pilih Format Ekspor",
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    _buildExportOption(
                      icon: Icons.picture_as_pdf,
                      label: "PDF Document",
                      color: Colors.red,
                      onTap: () {
                        Navigator.pop(context);
                        _exportTransactions('pdf');
                      },
                    ),
                    const SizedBox(width: 16),
                    _buildExportOption(
                      icon: Icons.table_chart,
                      label: "Excel Spreadsheet",
                      color: Colors.green,
                      onTap: () {
                        Navigator.pop(context);
                        _exportTransactions('excel');
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExportOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: GoogleFonts.openSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

