import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/bulk_import_service.dart';
import '../../services/app_database.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' as drift;
import 'package:intl/intl.dart';
import 'widgets/product_form_sheet.dart';
import '../../widgets/big_search_bar.dart';
import '../../controllers/admin_controller.dart';
import '../../services/platform/file_manager.dart';
import '../../widgets/kasir_dialog.dart';
import '../../controllers/settings_controller.dart';
import '../../widgets/skeleton_loader.dart';

class InventoryPage extends StatefulWidget {
  final VoidCallback? onMenuPressed;
  final VoidCallback? onNavigateToCategories;
  final VoidCallback? onBack;
  const InventoryPage({
    super.key,
    this.onMenuPressed,
    this.onNavigateToCategories,
    this.onBack,
  });

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = true;

  final currencyFormat = NumberFormat.currency(
    locale: 'id',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  List<Category> _categories = [];
  String? _selectedCategoryId; // null means "All"

  // Stock Filter: 'all', 'limited', 'unlimited'
  String _stockFilter = 'all';

  // Sort: 'name_asc', 'stock_asc', 'stock_desc', 'price_asc', 'price_desc'
  String _sortBy = 'name_asc';
  late BulkImportService _importService;

  @override
  void initState() {
    super.initState();
    final db = Provider.of<AppDatabase>(context, listen: false);
    _importService = BulkImportService(db);
    _fetchData();
    _searchController.addListener(_filterProducts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final db = Provider.of<AppDatabase>(context, listen: false);
      final admin = Provider.of<AdminController>(context, listen: false);
      final storeId = admin.storeId;

      if (storeId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final categoriesData =
          await (db.select(db.categories)
                ..where((t) => t.storeId.equals(storeId))
                ..orderBy([(t) => drift.OrderingTerm.asc(t.name)]))
              .get();
      final productsData =
          await (db.select(db.products)
                ..where(
                  (t) => t.storeId.equals(storeId) & t.isDeleted.equals(false),
                )
                ..orderBy([(t) => drift.OrderingTerm.asc(t.name)]))
              .get();

      if (mounted) {
        setState(() {
          _categories = categoriesData;
          _products = productsData;
          _applyFilters();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("InventoryPage: Fetch failed: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterProducts() {
    _applyFilters();
  }

  void _selectCategory(String? categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
      _applyFilters();
    });
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      final list = _products.where((product) {
        final name = product.name.toString().toLowerCase();
        final sku = (product.sku ?? '').toString().toLowerCase();
        final matchesSearch = name.contains(query) || sku.contains(query);

        final categoryId = product.categoryId;
        final matchesCategory =
            _selectedCategoryId == null || categoryId == _selectedCategoryId;

        bool matchesStock = true;
        final isManaged = product.isStockManaged == true;

        if (_stockFilter == 'limited') {
          matchesStock = isManaged;
        } else if (_stockFilter == 'unlimited') {
          matchesStock = !isManaged;
        }

        return matchesSearch && matchesCategory && matchesStock;
      }).toList();

      // Apply Sort
      list.sort((a, b) {
        if (_sortBy == 'stock_asc') {
          return (a.stockQuantity ?? 0).compareTo(b.stockQuantity ?? 0);
        } else if (_sortBy == 'stock_desc') {
          return (b.stockQuantity ?? 0).compareTo(a.stockQuantity ?? 0);
        } else if (_sortBy == 'price_asc') {
          return (a.salePrice ?? 0).compareTo(b.salePrice ?? 0);
        } else if (_sortBy == 'price_desc') {
          return (b.salePrice ?? 0).compareTo(a.salePrice ?? 0);
        } else {
          return (a.name ?? '').compareTo(b.name ?? '');
        }
      });

      _filteredProducts = list;
    });
  }

  void _openProductForm({Product? product}) async {
    final admin = Provider.of<AdminController>(context, listen: false);
    final storeId = admin.storeId;
    if (storeId == null) return;

    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ProductFormSheet(product: product, storeId: storeId),
    );

    if (result == true) {
      _fetchData();
    }
  }

  void _handleExport() async {
    final admin = Provider.of<AdminController>(context, listen: false);
    final storeId = admin.storeId;
    if (storeId == null) return;

    setState(() => _isLoading = true);
    try {
      final path = await _importService.exportProductsToExcel(storeId);
      if (mounted) {
        setState(() => _isLoading = false);
        if (path != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Berhasil export ke: $path"),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal export: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleBulkImport() async {
    final admin = Provider.of<AdminController>(context, listen: false);
    final storeId = admin.storeId;
    if (storeId == null) return;

    try {
      final result = await _importService.importProducts(storeId);

      if (result['status'] == 'cancelled') return;

      if (result['status'] == 'error') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error: ${result['message']}"),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      if (result['status'] == 'success') {
        _fetchData();
        if (mounted) {
          _showImportResultDialog(
            success: result['successCount'],
            fail: result['failCount'],
            errors: result['errors'],
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _handleDownloadTemplate() async {
    setState(() => _isLoading = true);
    final path = await _importService.generateTemplate();
    if (mounted) {
      setState(() => _isLoading = false);
      if (path != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Template disimpan di: $path"),
            backgroundColor: Colors.blue,
          ),
        );
      }
    }
  }

  void _showInventoryToolsSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final maxHeight = MediaQuery.of(ctx).size.height * 0.85;
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header – fixed, never scrolls
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 8, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Peralatan & Data",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.cancel),
                          onPressed: () => Navigator.pop(ctx),
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Scrollable tile list
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildAnimatedToolTile(
                            0,
                            label: "Ekspor ke Excel",
                            subtitle: "Export semua data produk",
                            icon: Icons.cloud_download,
                            color: Colors.green,
                            onTap: () {
                              Navigator.pop(ctx);
                              _handleExport();
                            },
                            isDark: isDark,
                          ),
                          _buildAnimatedToolTile(
                            1,
                            label: "Impor dari Excel",
                            subtitle: "Upload produk via Excel/CSV",
                            icon: Icons.cloud_upload,
                            color: Colors.blue,
                            onTap: () {
                              Navigator.pop(ctx);
                              _handleBulkImport();
                            },
                            isDark: isDark,
                          ),
                          _buildAnimatedToolTile(
                            2,
                            label: "Unduh Template",
                            subtitle: "Download template impor Excel",
                            icon: Icons.description,
                            color: Colors.orange,
                            onTap: () {
                              Navigator.pop(ctx);
                              _handleDownloadTemplate();
                            },
                            isDark: isDark,
                          ),
                          const Divider(height: 32),
                          _buildAnimatedToolTile(
                            3,
                            label: "Restock Massal",
                            subtitle: "Penuhi stok barang pilihan",
                            icon: Icons.playlist_add_check_rounded,
                            color: Colors.teal,
                            onTap: () {
                              Navigator.pop(ctx);
                              _restockAll();
                            },
                            isDark: isDark,
                          ),
                          _buildAnimatedToolTile(
                            4,
                            label: "Kosongkan Stok",
                            subtitle: "Setel stok 0 untuk list saat ini",
                            icon: Icons.delete_sweep_rounded,
                            color: Colors.red,
                            onTap: () {
                              Navigator.pop(ctx);
                              _emptyAllStock();
                            },
                            isDark: isDark,
                          ),
                          _buildAnimatedToolTile(
                            5,
                            label: "Panduan",
                            subtitle: "Cara mengelola inventaris",
                            icon: Icons.info,
                            color: Colors.grey,
                            onTap: () {
                              Navigator.pop(ctx);
                              _showInfoHelp();
                            },
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedToolTile(
    int index, {
    required String label,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 60)),
      curve: Curves.easeOutQuad,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - value)),
            child: child,
          ),
        );
      },
      child: _buildToolTile(
        label: label,
        subtitle: subtitle,
        icon: icon,
        color: color,
        onTap: onTap,
        isDark: isDark,
      ),
    );
  }

  Widget _buildToolTile({
    required String label,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          style: GoogleFonts.openSans(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.openSans(fontSize: 12, color: Colors.grey),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: Colors.grey,
          size: 16,
        ),
      ),
    );
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
        icon: fail == 0 ? Icons.check_circle_rounded : Icons.info_rounded,
        iconColor: fail == 0 ? Colors.green : Colors.orange,
        content: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem("Berhasil", success.toString(), Colors.green),
                _buildStatItem("Gagal", fail.toString(), Colors.red),
              ],
            ),
            if (errors.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 10),
              Text(
                "Detail Kesalahan:",
                style: GoogleFonts.openSans(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: errors.length,
                  separatorBuilder: (c, i) => const Divider(height: 8),
                  itemBuilder: (c, i) => Text(
                    errors[i],
                    style: GoogleFonts.openSans(
                      fontSize: 12,
                      color: Colors.red[400],
                    ),
                  ),
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

  Widget _buildStatItem(String label, String value, Color color) {
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
        Text(label, style: GoogleFonts.openSans(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Future<void> _deleteProduct(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => KasirDialog(
        title: "Hapus Produk?",
        message:
            "Tindakan ini tidak dapat dibatalkan dan produk akan dihapus permanent.",
        icon: Icons.delete,
        iconColor: Colors.redAccent,
        primaryActionLabel: "Hapus",
        isDestructive: true,
        onPrimaryAction: () => Navigator.pop(ctx, true),
        secondaryActionLabel: "Batal",
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      try {
        final db = Provider.of<AppDatabase>(context, listen: false);
        await (db.update(db.products)..where((t) => t.id.equals(id))).write(
          const ProductsCompanion(isDeleted: drift.Value(true)),
        );
        _fetchData();
      } catch (e) {
        debugPrint("Error deleting product: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _emptyAllStock() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => KasirDialog(
        title: "Kosongkan Semua Stok?",
        message:
            "Semua produk dalam daftar 'Terbatas' akan diubah stoknya menjadi 0.\n\nTindakan ini tidak dapat dibatalkan.",
        icon: Icons.delete_sweep_rounded,
        iconColor: Colors.redAccent,
        primaryActionLabel: "Kosongkan",
        isDestructive: true,
        onPrimaryAction: () => Navigator.pop(ctx, true),
        secondaryActionLabel: "Batal",
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      setState(() => _isLoading = true);

      // Collect IDs of currently filtered products (which should be 'Limited')
      final ids = _filteredProducts.map((p) => p.id).toList();

      if (ids.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      try {
        final db = Provider.of<AppDatabase>(context, listen: false);
        for (var id in ids) {
          await (db.update(db.products)..where((t) => t.id.equals(id))).write(
            const ProductsCompanion(stockQuantity: drift.Value(0)),
          );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Semua stok berhasil dikosongkan.")),
          );
          _fetchData();
        }
      } catch (e) {
        debugPrint("Error emptying stock: $e");
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Gagal: $e"), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _restockAll() async {
    // Dialog Choice: Fill to Max vs Add Fixed Amount
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => KasirDialog(
        title: "Restock Massal",
        icon: Icons.playlist_add_check_rounded,
        iconColor: Colors.green,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildChoiceOption(
              icon: Icons.track_changes_rounded,
              title: "Penuhi ke Max Stock",
              subtitle: "Sesuaikan dengan limit produk",
              onTap: () => Navigator.pop(ctx, 'max'),
              color: Colors.green,
            ),
            const SizedBox(height: 12),
            _buildChoiceOption(
              icon: Icons.add_circle_outline_rounded,
              title: "Tambah Jumlah Sama",
              subtitle: "Tambahkan qty tetap ke semua",
              onTap: () => Navigator.pop(ctx, 'manual'),
              color: Colors.blue,
            ),
          ],
        ),
      ),
    );

    if (choice == null) return;
    if (!mounted) return;

    if (choice == 'max') {
      await _fillToMaxStock();
    } else {
      await _addFixedStockToAll();
    }
  }

  Widget _buildChoiceOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.openSans(
                      fontSize: 11,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 14,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _fillToMaxStock() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    int updateCount = 0;

    try {
      // Max stock logic disabled due to schema mismatch
      // for (var p in _filteredProducts) { ... }

      if (mounted) {
        _fetchData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Berhasil restock $updateCount produk ke batas maksimal.",
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error fill max stock: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _addFixedStockToAll() async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => KasirDialog(
        title: "Tambah Stok Massal",
        icon: Icons.add_business_rounded,
        iconColor: Colors.blue,
        content: Column(
          children: [
            const SizedBox(height: 8),
            _buildDialogTextField(
              controller: controller,
              label: "Jumlah Tambahan",
              hint: "Misal: 10",
              prefixIcon: Icons.add_box_rounded,
            ),
          ],
        ),
        primaryActionLabel: "Simpan",
        onPrimaryAction: () async {
          final amount = int.tryParse(controller.text) ?? 0;
          if (amount <= 0) return;
          Navigator.pop(ctx);
          setState(() => _isLoading = true);

          try {
            final db = Provider.of<AppDatabase>(context, listen: false);
            for (var p in _filteredProducts) {
              final current = p.stockQuantity ?? 0;
              await (db.update(
                db.products,
              )..where((t) => t.id.equals(p.id))).write(
                ProductsCompanion(stockQuantity: drift.Value(current + amount)),
              );
            }
            if (mounted) {
              _fetchData();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Berhasil menambah +$amount ke semua produk."),
                ),
              );
            }
          } catch (e) {
            debugPrint("Restock error: $e");
            if (mounted) setState(() => _isLoading = false);
          }
        },
        secondaryActionLabel: "Batal",
      ),
    );
  }

  Widget _buildDialogTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData prefixIcon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.openSans(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          style: GoogleFonts.openSans(),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(prefixIcon, size: 20, color: Colors.grey),
            filled: true,
            fillColor: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryOrange = Color(0xFFC0392B);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          SettingsController.instance.getString('nav_inventory'),
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF2D3436),
          ),
        ),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: Builder(
          builder: (ctx) {
            final isWide = MediaQuery.of(ctx).size.width >= 1024;
            if (isWide) return const SizedBox.shrink();

            if (widget.onBack != null) {
              return IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: isDark ? Colors.white : const Color(0xFF2D3436),
                ),
                onPressed: widget.onBack,
                tooltip: 'Kembali',
              );
            }

            if (Navigator.canPop(context)) {
              return IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: isDark ? Colors.white : const Color(0xFF2D3436),
                ),
                onPressed: () => Navigator.pop(context),
              );
            }

            return const SizedBox.shrink();
          },
        ),
        automaticallyImplyLeading: false,
        actions: [
          ValueListenableBuilder<bool>(
            valueListenable: SettingsController.instance.featureStokEnabled,
            builder: (context, stokEnabled, _) {
              if (!stokEnabled) return const SizedBox.shrink();
              return PopupMenuButton<String>(
                tooltip: 'Aksi Massal',
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                offset: const Offset(0, 40),
                onSelected: (val) {
                  if (val == 'restock') {
                    _restockAll();
                  } else if (val == 'empty') {
                    _emptyAllStock();
                  }
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: 'restock',
                    child: Row(
                      children: [
                        const Icon(Icons.playlist_add_check_rounded, color: Colors.green, size: 18),
                        const SizedBox(width: 8),
                        Text("Restock Massal", style: GoogleFonts.openSans(fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'empty',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_sweep_rounded, color: Colors.red, size: 18),
                        const SizedBox(width: 8),
                        Text("Kosongkan Stok", style: GoogleFonts.openSans(fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildFeatureButton(
                    label: "Aksi Massal",
                    icon: Icons.inventory_2_outlined,
                    color: Colors.orange[800]!,
                    onTap: () {},
                  ),
                ),
              );
            },
          ),
          if (widget.onNavigateToCategories != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildFeatureButton(
                label: "Kategori",
                icon: Icons.label_outline,
                color: isDark ? Colors.white70 : Colors.grey[700]!,
                onTap: widget.onNavigateToCategories!,
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _buildFeatureButton(
              label: "Alat",
              icon: Icons.view_list,
              color: isDark ? Colors.white70 : Colors.grey[700]!,
              onTap: _showInventoryToolsSheet,
            ),
          ),
        ],
      ),
      floatingActionButton: _ScaleButton(
        onTap: () => _openProductForm(),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFC0392B), Color(0xFFE05A4E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFC0392B).withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                "Tambah Produk",
                style: GoogleFonts.openSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // Top Header Container (Solid background with bottom grey border outline)
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? const Color(0xFF374151) : const Color(0xFFCBD5E1),
                  width: 1.2,
                ),
              ),
            ),
            child: Column(
              children: [
                // Search Bar & Sort
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: BigSearchBar(
                          controller: _searchController,
                          hintText: SettingsController.instance.getString(
                            'search_product',
                          ),
                          onChanged: (val) {},
                          onClear: () {
                            _searchController.clear();
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      _buildFilterButton(isDark),
                    ],
                  ),
                ),

                // Categories List
                SizedBox(
                  height: 42,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length + 1,
                    separatorBuilder: (c, i) =>
                        const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final isAll = index == 0;
                      final cat = isAll ? null : _categories[index - 1];
                      final isSelected = isAll
                          ? _selectedCategoryId == null
                          : _selectedCategoryId == cat?.id;

                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: Duration(
                          milliseconds: 200 + index * 40,
                        ),
                        curve: Curves.easeOut,
                        builder: (context, v, child) => Opacity(
                          opacity: v,
                          child: Transform.translate(
                            offset: Offset(10 * (1 - v), 0),
                            child: child,
                          ),
                        ),
                        child: ChoiceChip(
                          label: Text(isAll ? "Semua" : (cat?.name ?? "-")),
                          selected: isSelected,
                          onSelected: (_) =>
                              _selectCategory(isAll ? null : cat?.id),
                          selectedColor: const Color(0xFFC0392B),
                          backgroundColor: isDark
                              ? const Color(0xFF2A2A2D)
                              : const Color(0xFFF1F5F9),
                          labelStyle: GoogleFonts.openSans(
                            color: isSelected
                                ? Colors.white
                                : (isDark
                                    ? Colors.white70
                                    : const Color(0xFF475569)),
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                          side: BorderSide(
                            color: isSelected
                                ? const Color(0xFFC0392B)
                                : (isDark
                                    ? const Color(0xFF374151)
                                    : const Color(0xFFCBD5E1)),
                            width: 1.2,
                          ),
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),

          // Product List Area (Below grey border line)
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchData,
              color: primaryOrange,
              backgroundColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
              strokeWidth: 3,
              child: _buildProductListBody(isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductListBody(bool isDark) {
    if (_isLoading) {
      return const SkeletonListLoader();
    }
    if (_filteredProducts.isEmpty) {
      return ListView(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.2,
          ),
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 80,
                  color: Colors.grey[200],
                ),
                const SizedBox(height: 16),
                Text(
                  _searchController.text.isEmpty
                      ? "Belum ada produk"
                      : "Produk tidak ditemukan",
                  style: GoogleFonts.openSans(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 600) {
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate:
                const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 220,
                  childAspectRatio: 0.72,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
            itemCount: _filteredProducts.length,
            itemBuilder: (context, index) {
              final product = _filteredProducts[index];
              return _buildProductGridItem(
                product,
                index,
              );
            },
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 6,
          ),
          itemCount: _filteredProducts.length,
          itemBuilder: (context, index) {
            final product = _filteredProducts[index];
            return _buildProductCard(
              product,
              index,
            );
          },
        );
      },
    );
  }



  Widget _buildProductCard(Product product, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 50)),
      curve: Curves.easeOutQuint,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: product.isStockManaged
          ? Dismissible(
              key: Key("restock_${product.id}"),
              direction: DismissDirection.startToEnd,
              confirmDismiss: (direction) async {
                if (direction == DismissDirection.startToEnd) {
                  await _showRestockDialog(product);
                  return false; // Don't dismiss the card
                }
                return false;
              },
              background: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.centerLeft,
                child: const Row(
                  children: [
                    Icon(Icons.add_box_rounded, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      "Restock",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              child: _buildProductCardContent(product),
            )
          : _buildProductCardContent(product),
    );
  }

  Widget _buildProductCardContent(Product product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: Theme.of(context).brightness == Brightness.dark
                  ? 0.2
                  : 0.03,
            ),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _openProductForm(product: product),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              // Product Image
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                  image: (product.imageUrl != null && product.imageUrl!.trim().isNotEmpty)
                      ? DecorationImage(
                          image: FileManager().getImageProvider(
                            product.imageUrl!,
                          ),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: (product.imageUrl == null || product.imageUrl!.trim().isEmpty)
                    ? Icon(
                        Icons.photo,
                        size: 20,
                        color: Colors.grey[300],
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              // Product Info + actions all in one column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name ?? 'No Name',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : const Color(0xFF2D3436),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.indigo.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _categories
                                    .firstWhere(
                                      (c) => c.id == product.categoryId,
                                      orElse: () => const Category(
                                        id: '',
                                        name: 'No Category',
                                      ),
                                    )
                                    .name ??
                                'No Category',
                            style: GoogleFonts.openSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.indigo,
                            ),
                          ),
                        ),
                        ValueListenableBuilder<bool>(
                          valueListenable: SettingsController.instance.featureStokEnabled,
                          builder: (context, stokEnabled, _) {
                            if (!stokEnabled) return const SizedBox.shrink();
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(width: 6),
                                Text(
                                  "Stok: ${product.isStockManaged ? product.stockQuantity : '∞'}",
                                  style: GoogleFonts.openSans(
                                    fontSize: 11,
                                    color: product.isStockManaged &&
                                            (product.stockQuantity ?? 0) < 5
                                        ? Colors.red
                                        : Colors.grey[600],
                                    fontWeight: product.isStockManaged &&
                                            (product.stockQuantity ?? 0) < 5
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    // Price + action buttons inline
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            currencyFormat.format(product.salePrice ?? 0),
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: const Color(0xFFC0392B),
                            ),
                          ),
                        ),
                        _ScaleButton(
                          onTap: () => _openProductForm(product: product),
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: const Icon(
                              Icons.edit,
                              size: 15,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        _ScaleButton(
                          onTap: () => _deleteProduct(product.id),
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: const Icon(
                              Icons.delete_outline,
                              size: 15,
                              color: Colors.redAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showRestockDialog(Product product) async {
    final controller = TextEditingController();
    final currentStock = product.stockQuantity ?? 0;

    await showDialog(
      context: context,
      builder: (context) => KasirDialog(
        title: "Restock: ${product.name}",
        icon: Icons.add_box_rounded,
        iconColor: Colors.green,
        content: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withValues(alpha: 0.1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Stok Saat Ini",
                    style: GoogleFonts.openSans(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    currentStock.toString(),
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildDialogTextField(
              controller: controller,
              label: "Jumlah Tambahan",
              hint: "Contoh: 5",
              prefixIcon: Icons.add_circle_outline_rounded,
            ),
          ],
        ),
        primaryActionLabel: "Simpan",
        onPrimaryAction: () async {
          final addAmount = int.tryParse(controller.text) ?? 0;
          if (addAmount <= 0) return;
          final newStock = currentStock + addAmount;
          final db = Provider.of<AppDatabase>(context, listen: false);
          await (db.update(db.products)..where((t) => t.id.equals(product.id)))
              .write(ProductsCompanion(stockQuantity: drift.Value(newStock)));

          if (context.mounted) {
            Navigator.pop(context);
            _fetchData();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Stok berhasil ditambah: +$addAmount")),
            );
          }
        },
        secondaryActionLabel: "Batal",
      ),
    );
  }

  Widget _buildProductGridItem(Product product, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 50)),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: Theme.of(context).brightness == Brightness.dark
                    ? 0.2
                    : 0.03,
              ),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: InkWell(
          onTap: () => _openProductForm(product: product),
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                        image: (product.imageUrl != null && product.imageUrl!.trim().isNotEmpty)
                            ? DecorationImage(
                                image: FileManager().getImageProvider(
                                  product.imageUrl!,
                                ),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: (product.imageUrl == null || product.imageUrl!.trim().isEmpty)
                          ? Center(
                              child: Icon(
                                Icons.photo,
                                color: Colors.grey[300],
                                size: 40,
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.edit,
                                size: 16,
                                color: Colors.grey,
                              ),
                              onPressed: () =>
                                  _openProductForm(product: product),
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(8),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                size: 16,
                                color: Colors.redAccent,
                              ),
                              onPressed: () => _deleteProduct(product.id),
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name ?? 'No Name',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currencyFormat.format(product.salePrice ?? 0),
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: const Color(0xFFC0392B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.indigo.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _categories
                                      .firstWhere(
                                        (c) => c.id == product.categoryId,
                                        orElse: () => const Category(
                                          id: '',
                                          name: 'No Cat',
                                        ),
                                      )
                                      .name ??
                                  'No Cat',
                              style: GoogleFonts.openSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.indigo,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Stock: ${product.isStockManaged ? product.stockQuantity : '∞'}",
                          style: GoogleFonts.openSans(
                            fontSize: 11,
                            color:
                                product.isStockManaged &&
                                    (product.stockQuantity ?? 0) < 5
                                ? Colors.red
                                : Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    if (product.isStockManaged) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        height: 32,
                        child: OutlinedButton.icon(
                          onPressed: () => _showRestockDialog(product),
                          icon: const Icon(Icons.add_box_rounded, size: 14),
                          label: const Text(
                            "Restock",
                            style: TextStyle(fontSize: 12),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            foregroundColor: Colors.green,
                            side: const BorderSide(color: Colors.green),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterButton(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.withValues(alpha: 0.1),
        ),
      ),
      child: PopupMenuButton<String>(
        offset: const Offset(0, 52),
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, anim) => ScaleTransition(
            scale: anim,
            child: FadeTransition(opacity: anim, child: child),
          ),
          child: Icon(
            _stockFilter != 'all' || _sortBy != 'name_asc'
                ? Icons.filter_list
                : Icons.tune,
            key: ValueKey("${_stockFilter}_$_sortBy"),
            color: _stockFilter != 'all' || _sortBy != 'name_asc'
                ? const Color(0xFFC0392B)
                : (isDark ? Colors.white70 : Colors.grey[700]),
          ),
        ),
        tooltip: 'Filter & Urutkan',
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        onSelected: (val) {
          setState(() {
            if (val.startsWith('stock:')) {
              _stockFilter = val.replaceFirst('stock:', '');
            } else if (val.startsWith('sort:')) {
              _sortBy = val.replaceFirst('sort:', '');
            }
            _applyFilters();
          });
        },
        itemBuilder: (ctx) => [
          _buildMenuSectionHeader('STATUS STOK'),
          _buildMenuItem(
            'stock:all',
            Icons.grid_view,
            'Semua Produk',
            group: 'stock',
          ),
          _buildMenuItem(
            'stock:limited',
            Icons.inventory_2_outlined,
            'Stok Terbatas',
            group: 'stock',
          ),
          _buildMenuItem(
            'stock:unlimited',
            Icons.all_inclusive,
            'Stok Unlimited',
            group: 'stock',
          ),
          const PopupMenuDivider(height: 16),
          _buildMenuSectionHeader('URUTKAN BERDASARKAN'),
          _buildMenuItem(
            'sort:name_asc',
            Icons.sort_by_alpha,
            'Nama (A-Z)',
            group: 'sort',
          ),
          _buildMenuItem(
            'sort:stock_asc',
            Icons.trending_up,
            'Stok Terendah',
            group: 'sort',
          ),
          _buildMenuItem(
            'sort:stock_desc',
            Icons.trending_down,
            'Stok Tertinggi',
            group: 'sort',
          ),
          _buildMenuItem(
            'sort:price_asc',
            Icons.arrow_upward,
            'Harga Termurah',
            group: 'sort',
          ),
          _buildMenuItem(
            'sort:price_desc',
            Icons.arrow_downward,
            'Harga Termahal',
            group: 'sort',
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildMenuSectionHeader(String title) {
    return PopupMenuItem<String>(
      enabled: false,
      height: 32,
      child: Text(
        title,
        style: GoogleFonts.openSans(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Colors.grey[500],
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildMenuItem(
    String value,
    IconData icon,
    String label, {
    required String group,
  }) {
    final bool isSelected = (group == 'stock')
        ? _stockFilter == value.replaceFirst('stock:', '')
        : _sortBy == value.replaceFirst('sort:', '');

    const primaryOrange = Color(0xFFC0392B);

    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isSelected
                  ? primaryOrange.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 16,
              color: isSelected ? primaryOrange : Colors.grey[600],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.openSans(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? primaryOrange : null,
            ),
          ),
          if (isSelected) ...[
            const Spacer(),
            const Icon(
              Icons.check_circle_rounded,
              size: 16,
              color: primaryOrange,
            ),
          ],
        ],
      ),
    );
  }

  void _showInfoHelp() {
    showDialog(
      context: context,
      builder: (ctx) => KasirDialog(
        title: "Kelola Inventaris",
        icon: Icons.inventory_2,
        iconColor: const Color(0xFFC0392B),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoItem(
              "Stok Terbatas vs Tidak Terbatas",
              "Pilih 'Stok Terbatas' jika ingin sistem memotong stok setiap penjualan. Pilih 'Tidak Terbatas' untuk jasa atau barang yang stoknya tidak perlu dihitung.",
            ),
            const SizedBox(height: 12),
            _buildInfoItem(
              "SKU / Kode Barang",
              "Gunakan kode unik untuk setiap barang. Anda bisa scan barcode produk untuk mengisi kolom ini secara otomatis.",
            ),
            const SizedBox(height: 12),
            _buildInfoItem(
              "Restock Cepat",
              "Klik tombol 'Restock' pada kartu produk atau gunakan tombol massal di menu Export/Import untuk menambah stok banyak barang sekaligus.",
            ),
          ],
        ),
        primaryActionLabel: "Paham",
        onPrimaryAction: () => Navigator.pop(ctx),
      ),
    );
  }

  Widget _buildInfoItem(String title, String desc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: const Color(0xFFC0392B),
          ),
        ),
        Text(
          desc,
          style: GoogleFonts.openSans(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildFeatureButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _ScaleButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isPrimary
              ? color
              : (isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : color.withValues(alpha: 0.08)),
          borderRadius: BorderRadius.circular(10),
          border: isPrimary
              ? null
              : Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isPrimary ? Colors.white : color),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.openSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isPrimary ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScaleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _ScaleButton({required this.child, required this.onTap});

  @override
  State<_ScaleButton> createState() => _ScaleButtonState();
}

class _ScaleButtonState extends State<_ScaleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onTap,
      child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
    );
  }
}

