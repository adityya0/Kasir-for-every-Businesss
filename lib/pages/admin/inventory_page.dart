import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/bulk_import_service.dart';
import '../../services/app_database.dart';
import '../../services/supplier_service.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' as drift;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'widgets/product_form_sheet.dart';
import '../../widgets/big_search_bar.dart';
import '../../controllers/admin_controller.dart';
import '../../services/platform/file_manager.dart';
import '../../widgets/kasir_dialog.dart';
import '../../controllers/settings_controller.dart';
import '../../widgets/skeleton_loader.dart';
import 'category_page.dart';
import 'report/profit_loss_page.dart';
import 'trends_page.dart';

class _StockCardEntry {
  final DateTime date;
  final String code;
  final String description;
  final double qtyDelta;
  double saldoAfter;

  _StockCardEntry({
    required this.date,
    required this.code,
    required this.description,
    required this.qtyDelta,
    this.saldoAfter = 0,
  });
}

class InventoryPage extends StatefulWidget {
  final VoidCallback? onMenuPressed;
  final VoidCallback? onNavigateToCategories;
  final VoidCallback? onBack;
  final Function(int)? onNavigateToIndex;
  final int initialTabIndex;

  const InventoryPage({
    super.key,
    this.onMenuPressed,
    this.onNavigateToCategories,
    this.onBack,
    this.onNavigateToIndex,
    this.initialTabIndex = 0,
  });

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = true;
  late int _activeTopTab;

  final currencyFormat = NumberFormat.currency(
    locale: 'id',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  List<Category> _categories = [];
  Map<String, String> _unitCodes = {};
  String? _selectedCategoryId; // null means "All"

  // Stock Filter: 'all', 'limited', 'unlimited'
  String _stockFilter = 'all';

  // Sort: 'name_asc', 'stock_asc', 'stock_desc', 'price_asc', 'price_desc'
  String _sortBy = 'name_asc';
  late BulkImportService _importService;

  @override
  void initState() {
    super.initState();
    _activeTopTab = widget.initialTabIndex;
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
      final unitsData =
          await (db.select(db.units)
                ..where((t) => t.storeId.equals(storeId)))
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
          _unitCodes = {for (final u in unitsData) u.id: u.code};
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
    final stokEnabled = SettingsController.instance.featureStokEnabled.value;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                border: Border.all(
                  color: isDark ? const Color(0xFF374151) : const Color(0xFFCBD5E1),
                  width: 1.2,
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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

                  // Header matching Kasir & Keuangan style
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
                                "Pintasan Cepat Produk",
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                "Kategori, aksi massal stok & manajemen data",
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
                  const SizedBox(height: 16),

                  // 2-Column Responsive Grid
                  Flexible(
                    child: SingleChildScrollView(
                      child: GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        mainAxisExtent: 104,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _buildInventoryToolCard(
                            icon: Icons.label_outline_rounded,
                            label: "Kelola Kategori",
                            subtitle: "Atur grup & label produk",
                            color: const Color(0xFF8B5CF6),
                            isDark: isDark,
                            onTap: () {
                              Navigator.pop(ctx);
                              if (widget.onNavigateToCategories != null) {
                                widget.onNavigateToCategories!();
                              } else {
                                final admin = Provider.of<AdminController>(context, listen: false);
                                final storeId = admin.storeId;
                                if (storeId != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => CategoryPage(
                                        storeId: storeId,
                                        onBack: () => Navigator.pop(context),
                                      ),
                                    ),
                                  ).then((_) => _fetchData());
                                }
                              }
                            },
                          ),
                          _buildInventoryToolCard(
                            icon: Icons.local_shipping_outlined,
                            label: "Pasokan & Supplier",
                            subtitle: "Uang modal & barang supplier",
                            color: const Color(0xFF0D9488),
                            isDark: isDark,
                            onTap: () {
                              Navigator.pop(ctx);
                              final admin = Provider.of<AdminController>(context, listen: false);
                              final storeId = admin.storeId;
                              if (storeId != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ProfitLossPage(
                                      storeId: storeId,
                                      initialLaporanView: true,
                                      initialTabIndex: 4,
                                      onBack: () => Navigator.pop(context),
                                    ),
                                  ),
                                ).then((_) => _fetchData());
                              }
                            },
                          ),
                          if (stokEnabled) ...[
                            _buildInventoryToolCard(
                              icon: Icons.playlist_add_check_rounded,
                              label: "Restock Massal",
                              subtitle: "Penuhi stok barang pilihan",
                              color: const Color(0xFF0D9488),
                              isDark: isDark,
                              onTap: () {
                                Navigator.pop(ctx);
                                _restockAll();
                              },
                            ),
                            _buildInventoryToolCard(
                              icon: Icons.all_inclusive_rounded,
                              label: "Tambah Semua Stok",
                              subtitle: "Tambah stok seluruh produk",
                              color: const Color(0xFF0284C7),
                              isDark: isDark,
                              onTap: () {
                                Navigator.pop(ctx);
                                _addFixedStockToAll();
                              },
                            ),
                            _buildInventoryToolCard(
                              icon: Icons.delete_sweep_rounded,
                              label: "Kosongkan Stok",
                              subtitle: "Setel stok 0 untuk list ini",
                              color: const Color(0xFFDC2626),
                              isDark: isDark,
                              onTap: () {
                                Navigator.pop(ctx);
                                _emptyAllStock();
                              },
                            ),
                          ],
                          _buildInventoryToolCard(
                            icon: Icons.cloud_download_outlined,
                            label: "Ekspor ke Excel",
                            subtitle: "Export semua data produk",
                            color: const Color(0xFF00BF63),
                            isDark: isDark,
                            onTap: () {
                              Navigator.pop(ctx);
                              _handleExport();
                            },
                          ),
                          _buildInventoryToolCard(
                            icon: Icons.cloud_upload_outlined,
                            label: "Impor dari Excel",
                            subtitle: "Upload produk via Excel",
                            color: const Color(0xFF2563EB),
                            isDark: isDark,
                            onTap: () {
                              Navigator.pop(ctx);
                              _handleBulkImport();
                            },
                          ),
                          _buildInventoryToolCard(
                            icon: Icons.description_outlined,
                            label: "Unduh Template",
                            subtitle: "Template impor Excel",
                            color: const Color(0xFFD97706),
                            isDark: isDark,
                            onTap: () {
                              Navigator.pop(ctx);
                              _handleDownloadTemplate();
                            },
                          ),
                          _buildInventoryToolCard(
                            icon: Icons.info_outline_rounded,
                            label: "Panduan",
                            subtitle: "Cara mengelola inventaris",
                            color: const Color(0xFF64748B),
                            isDark: isDark,
                            onTap: () {
                              Navigator.pop(ctx);
                              _showInfoHelp();
                            },
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

  Widget _buildInventoryToolCard({
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
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF27272A) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? const Color(0xFF3F3F46) : const Color(0xFFE2E8F0),
              width: 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 8),
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
    // Dialog Choice: Per Kategori vs Semua Produk vs Penuhi ke Target
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => KasirDialog(
        title: "Restock Massal",
        icon: Icons.playlist_add_check_rounded,
        iconColor: const Color(0xFF00BF63),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildChoiceOption(
              icon: Icons.category_rounded,
              title: "Restock per Kategori",
              subtitle: "Pilih kategori & tambah stok massal",
              onTap: () => Navigator.pop(ctx, 'category'),
              color: const Color(0xFF8B5CF6),
            ),
            const SizedBox(height: 12),
            _buildChoiceOption(
              icon: Icons.all_inclusive_rounded,
              title: "Tambah Semua Produk",
              subtitle: "Tambahkan qty tetap ke seluruh produk",
              onTap: () => Navigator.pop(ctx, 'all'),
              color: const Color(0xFF0284C7),
            ),
            const SizedBox(height: 12),
            _buildChoiceOption(
              icon: Icons.track_changes_rounded,
              title: "Penuhi ke Target Stok",
              subtitle: "Genapkan stok di bawah batas minimal",
              onTap: () => Navigator.pop(ctx, 'target'),
              color: const Color(0xFF00BF63),
            ),
          ],
        ),
      ),
    );

    if (choice == null) return;
    if (!mounted) return;

    if (choice == 'category') {
      await _restockByCategory();
    } else if (choice == 'all') {
      await _addFixedStockToAll();
    } else if (choice == 'target') {
      await _fillToMaxStock();
    }
  }

  Future<void> _restockByCategory() async {
    if (_categories.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Belum ada kategori yang dibuat."),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    String selectedCatId = _selectedCategoryId ?? _categories.first.id;
    final controller = TextEditingController(text: "10");

    await showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            final currentCategory = _categories.firstWhere(
              (c) => c.id == selectedCatId,
              orElse: () => _categories.first,
            );
            final targetProducts = _products
                .where((p) => p.categoryId == selectedCatId && !p.isDeleted)
                .toList();

            return KasirDialog(
              title: "Restock per Kategori",
              icon: Icons.category_rounded,
              iconColor: const Color(0xFF8B5CF6),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    "Pilih Kategori",
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedCatId,
                        isExpanded: true,
                        dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        items: _categories.map((cat) {
                          final count = _products
                              .where((p) => p.categoryId == cat.id && !p.isDeleted)
                              .length;
                          return DropdownMenuItem<String>(
                            value: cat.id,
                            child: Row(
                              children: [
                                const Icon(Icons.folder_outlined, size: 18, color: Color(0xFF8B5CF6)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    cat.name ?? "Kategori",
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    "$count item",
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF8B5CF6),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() {
                              selectedCatId = val;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDialogTextField(
                    controller: controller,
                    label: "Jumlah Tambahan Stok (Qty)",
                    hint: "Misal: 10",
                    prefixIcon: Icons.add_box_rounded,
                  ),
                  const SizedBox(height: 10),
                  // Preset Quick Chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [5, 10, 20, 50, 100].map((preset) {
                      return InkWell(
                        onTap: () {
                          setDialogState(() {
                            controller.text = preset.toString();
                          });
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B5CF6).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF8B5CF6).withValues(alpha: 0.25),
                            ),
                          ),
                          child: Text(
                            "+$preset",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF8B5CF6),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  // Info summary box
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          size: 18,
                          color: Color(0xFF8B5CF6),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            targetProducts.isEmpty
                                ? "Kategori '${currentCategory.name ?? "Kategori"}' belum memiliki produk."
                                : "Akan menambah stok ke ${targetProducts.length} produk di kategori '${currentCategory.name ?? "Kategori"}'.",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white70 : const Color(0xFF475569),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              primaryActionLabel: "Restock Kategori",
              onPrimaryAction: () async {
                final amount = double.tryParse(controller.text) ?? 0;
                if (amount <= 0) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text("Jumlah stok harus lebih dari 0"),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }
                if (targetProducts.isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text("Tidak ada produk di kategori '${currentCategory.name ?? "Kategori"}'"),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                Navigator.pop(ctx);
                setState(() => _isLoading = true);

                try {
                  final db = Provider.of<AppDatabase>(context, listen: false);
                  for (var p in targetProducts) {
                    final current = p.stockQuantity ?? 0.0;
                    await (db.update(db.products)..where((t) => t.id.equals(p.id))).write(
                      ProductsCompanion(
                        stockQuantity: drift.Value(current + amount),
                        lastUpdated: drift.Value(DateTime.now()),
                      ),
                    );
                  }
                  if (mounted) {
                    await _fetchData();
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "Berhasil restock +${amount % 1 == 0 ? amount.toInt() : amount} ke ${targetProducts.length} produk di '${currentCategory.name ?? "Kategori"}'!",
                        ),
                        backgroundColor: const Color(0xFF00BF63),
                      ),
                    );
                  }
                } catch (e) {
                  debugPrint("Restock error: $e");
                  if (mounted) {
                    setState(() => _isLoading = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Gagal restock: $e"), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              secondaryActionLabel: "Batal",
            );
          },
        );
      },
    );
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
    final controller = TextEditingController(text: "50");
    final activeProducts = _products.where((p) => !p.isDeleted).toList();

    await showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return KasirDialog(
              title: "Penuhi ke Target Stok",
              icon: Icons.track_changes_rounded,
              iconColor: const Color(0xFF00BF63),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  _buildDialogTextField(
                    controller: controller,
                    label: "Target Batas Stok",
                    hint: "Misal: 50",
                    prefixIcon: Icons.trending_up_rounded,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [20, 50, 100, 200].map((preset) {
                      return InkWell(
                        onTap: () {
                          setDialogState(() {
                            controller.text = preset.toString();
                          });
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00BF63).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF00BF63).withValues(alpha: 0.25),
                            ),
                          ),
                          child: Text(
                            "$preset",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF00BF63),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00BF63).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFF00BF63).withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          size: 18,
                          color: Color(0xFF00BF63),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Produk dengan stok di bawah target akan digenapkan menjadi target tersebut.",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white70 : const Color(0xFF475569),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              primaryActionLabel: "Penuhi Stok",
              onPrimaryAction: () async {
                final target = double.tryParse(controller.text) ?? 0;
                if (target <= 0) return;
                Navigator.pop(ctx);
                setState(() => _isLoading = true);

                int updateCount = 0;
                try {
                  final db = Provider.of<AppDatabase>(context, listen: false);
                  for (var p in activeProducts) {
                    final current = p.stockQuantity ?? 0.0;
                    if (current < target) {
                      await (db.update(
                        db.products,
                      )..where((t) => t.id.equals(p.id))).write(
                        ProductsCompanion(
                          stockQuantity: drift.Value(target),
                          lastUpdated: drift.Value(DateTime.now()),
                        ),
                      );
                      updateCount++;
                    }
                  }
                  if (mounted) {
                    await _fetchData();
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "Berhasil menggenapkan stok $updateCount produk ke target $target.",
                        ),
                        backgroundColor: const Color(0xFF00BF63),
                      ),
                    );
                  }
                } catch (e) {
                  debugPrint("Error fill target stock: $e");
                  if (mounted) setState(() => _isLoading = false);
                }
              },
              secondaryActionLabel: "Batal",
            );
          },
        );
      },
    );
  }

  Future<void> _addFixedStockToAll() async {
    final controller = TextEditingController(text: "10");
    final activeProducts = _products.where((p) => !p.isDeleted).toList();

    await showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return KasirDialog(
              title: "Tambah Semua Stok",
              icon: Icons.all_inclusive_rounded,
              iconColor: const Color(0xFF0284C7),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  _buildDialogTextField(
                    controller: controller,
                    label: "Jumlah Tambahan Stok (Qty)",
                    hint: "Misal: 10",
                    prefixIcon: Icons.add_box_rounded,
                  ),
                  const SizedBox(height: 10),
                  // Preset Quick Chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [5, 10, 20, 50, 100].map((preset) {
                      return InkWell(
                        onTap: () {
                          setDialogState(() {
                            controller.text = preset.toString();
                          });
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0284C7).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF0284C7).withValues(alpha: 0.25),
                            ),
                          ),
                          child: Text(
                            "+$preset",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0284C7),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          size: 18,
                          color: Color(0xFF0284C7),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Akan menambahkan stok ke ${activeProducts.length} seluruh produk di toko.",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white70 : const Color(0xFF475569),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              primaryActionLabel: "Simpan",
              onPrimaryAction: () async {
                final amount = double.tryParse(controller.text) ?? 0;
                if (amount <= 0) return;
                Navigator.pop(ctx);
                setState(() => _isLoading = true);

                try {
                  final db = Provider.of<AppDatabase>(context, listen: false);
                  for (var p in activeProducts) {
                    final current = p.stockQuantity ?? 0.0;
                    await (db.update(
                      db.products,
                    )..where((t) => t.id.equals(p.id))).write(
                      ProductsCompanion(
                        stockQuantity: drift.Value(current + amount),
                        lastUpdated: drift.Value(DateTime.now()),
                      ),
                    );
                  }
                  if (mounted) {
                    await _fetchData();
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "Berhasil menambah +${amount % 1 == 0 ? amount.toInt() : amount} ke seluruh ${activeProducts.length} produk.",
                        ),
                        backgroundColor: const Color(0xFF00BF63),
                      ),
                    );
                  }
                } catch (e) {
                  debugPrint("Restock error: $e");
                  if (mounted) setState(() => _isLoading = false);
                }
              },
              secondaryActionLabel: "Batal",
            );
          },
        );
      },
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
    const primaryGreen = Color(0xFF00BF63);

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
                tooltip: "Pintasan Cepat Produk",
                onPressed: _showInventoryToolsSheet,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Sub-nav switcher: [ 📦 Daftar Produk ]  [ 📈 Tren Terlaris ]
          Container(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
            child: Container(
              height: 38,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF27272A) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        if (_activeTopTab != 0) setState(() => _activeTopTab = 0);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.all(2.5),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _activeTopTab == 0
                              ? (isDark ? const Color(0xFF18181B) : Colors.white)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: _activeTopTab == 0
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 15,
                              color: _activeTopTab == 0
                                  ? const Color(0xFF00BF63)
                                  : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "Daftar Produk",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: _activeTopTab == 0 ? FontWeight.w700 : FontWeight.w600,
                                color: _activeTopTab == 0
                                    ? (isDark ? Colors.white : const Color(0xFF0F172A))
                                    : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        if (_activeTopTab != 1) setState(() => _activeTopTab = 1);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.all(2.5),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _activeTopTab == 1
                              ? (isDark ? const Color(0xFF18181B) : Colors.white)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: _activeTopTab == 1
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.trending_up_rounded,
                              size: 16,
                              color: _activeTopTab == 1
                                  ? const Color(0xFF00BF63)
                                  : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "Tren Terlaris",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: _activeTopTab == 1 ? FontWeight.w700 : FontWeight.w600,
                                color: _activeTopTab == 1
                                    ? (isDark ? Colors.white : const Color(0xFF0F172A))
                                    : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _activeTopTab == 0
                ? Column(
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
                            // Search Bar, Filter & Add (+) Button
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: BigSearchBar(
                                      controller: _searchController,
                                      hintText: "Cari barang...",
                                      onChanged: (val) {},
                                      onClear: () {
                                        _searchController.clear();
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildFilterButton(isDark),
                                  const SizedBox(width: 8),
                                  Material(
                                    color: const Color(0xFF00BF63),
                                    borderRadius: BorderRadius.circular(14),
                                    child: InkWell(
                                      onTap: () => _openProductForm(),
                                      borderRadius: BorderRadius.circular(14),
                                      child: const SizedBox(
                                        width: 48,
                                        height: 48,
                                        child: Icon(
                                          Icons.add_rounded,
                                          color: Colors.white,
                                          size: 26,
                                        ),
                                      ),
                                    ),
                                  ),
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

                                  return ChoiceChip(
                                    label: Text(isAll ? "Semua" : (cat?.name ?? "-")),
                                    selected: isSelected,
                                    onSelected: (_) =>
                                        _selectCategory(isAll ? null : cat?.id),
                                    selectedColor: const Color(0xFF00BF63),
                                    backgroundColor: isDark
                                        ? const Color(0xFF2A2A2D)
                                        : Colors.white,
                                    labelStyle: GoogleFonts.plusJakartaSans(
                                      color: isSelected
                                          ? Colors.white
                                          : (isDark
                                              ? Colors.white70
                                              : const Color(0xFF334155)),
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      fontSize: 12.5,
                                    ),
                                    side: BorderSide(
                                      color: isSelected
                                          ? const Color(0xFF00BF63)
                                          : (isDark
                                              ? const Color(0xFF374151)
                                              : const Color(0xFFCBD5E1)),
                                      width: 1.2,
                                    ),
                                    visualDensity: VisualDensity.compact,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),

                      // Product List Area (Unified Daftar Barang Card)
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: _fetchData,
                          color: primaryGreen,
                          backgroundColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                          strokeWidth: 3,
                          child: _buildProductListBody(isDark),
                        ),
                      ),
                    ],
                  )
                : TrendsPage(
                    storeId: Provider.of<AdminController>(context, listen: false).storeId ?? 'default_store',
                    onNavigateToIndex: widget.onNavigateToIndex ?? (idx) {},
                    embedded: true,
                  ),
          ),
        ],
      ),
    );
  }

  String _formatQty(double val) {
    return val % 1 == 0 ? val.toInt().toString() : val.toStringAsFixed(1);
  }

  String _getUnitLabel(Product p) {
    if (p.unitId != null && _unitCodes.containsKey(p.unitId)) {
      return _unitCodes[p.unitId!]!;
    }
    return 'pcs';
  }

  String _getCategoryName(Product p) {
    return _categories
            .firstWhere(
              (c) => c.id == p.categoryId,
              orElse: () => const Category(id: '', name: 'Tanpa Kategori'),
            )
            .name ??
        'Tanpa Kategori';
  }

  double _getProductBuyPrice(Product p) {
    final buy = p.buyPrice ?? 0.0;
    if (buy > 0) return buy;
    final base = p.basePrice ?? 0.0;
    if (base > 0) return base;
    return 0.0;
  }

  double _getProductStockValue(Product p) {
    final qty = (p.stockQuantity ?? 0.0) > 0 ? (p.stockQuantity ?? 0.0) : 0.0;
    final buy = _getProductBuyPrice(p);
    final unitVal = buy > 0 ? buy : (p.salePrice ?? 0.0);
    return qty * unitVal;
  }

  Widget _buildProductListBody(bool isDark) {
    if (_isLoading) {
      return const SkeletonListLoader();
    }

    double totalStockValue = 0.0;
    for (final p in _filteredProducts) {
      totalStockValue += _getProductStockValue(p);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 40),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: Daftar Barang [count] (Kiri) | Nilai stok: Rp ... (Kanan)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00BF63).withValues(alpha: isDark ? 0.2 : 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.inventory_2_rounded,
                                size: 16,
                                color: Color(0xFF00BF63),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Daftar Barang",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(width: 7),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7.5, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                "${_filteredProducts.length}",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white70 : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00BF63).withValues(alpha: isDark ? 0.16 : 0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFF00BF63).withValues(alpha: 0.25),
                                width: 0.8,
                              ),
                            ),
                            child: RichText(
                              overflow: TextOverflow.ellipsis,
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: "Nilai stok: ",
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? const Color(0xFFA7F3D0) : const Color(0xFF047857),
                                    ),
                                  ),
                                  TextSpan(
                                    text: currencyFormat.format(totalStockValue),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                      color: isDark ? const Color(0xFF00BF63) : const Color(0xFF047857),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    height: 1,
                    thickness: 1.2,
                    color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                  ),

                  if (_filteredProducts.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 48,
                              color: isDark ? Colors.white24 : Colors.grey.shade300,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _searchController.text.isEmpty
                                  ? "Belum ada barang"
                                  : "Barang tidak ditemukan",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white54 : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...List.generate(_filteredProducts.length, (index) {
                      final product = _filteredProducts[index];
                      return Column(
                        children: [
                          _buildSimpleProductRow(product, isDark),
                          if (index < _filteredProducts.length - 1)
                            Divider(
                              height: 1,
                              color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                            ),
                        ],
                      );
                    }),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleProductRow(Product product, bool isDark) {
    final catName = _getCategoryName(product);
    final buyPrice = _getProductBuyPrice(product);
    final salePrice = product.salePrice ?? 0.0;
    final unit = _getUnitLabel(product);
    final qty = product.stockQuantity ?? 0.0;
    final stockText = product.isStockManaged
        ? "${_formatQty(qty)} $unit"
        : "∞ $unit";
    final isLowStock = product.isStockManaged && qty < 5;

    return InkWell(
      onTap: () => _showProductDetailSheet(product),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Gambar Produk
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  width: 1.0,
                ),
                image: (product.imageUrl != null && product.imageUrl!.trim().isNotEmpty)
                    ? DecorationImage(
                        image: FileManager().getImageProvider(product.imageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: (product.imageUrl == null || product.imageUrl!.trim().isEmpty)
                  ? Icon(
                      Icons.inventory_2_outlined,
                      size: 22,
                      color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                    )
                  : null,
            ),
            const SizedBox(width: 12),

            // Kiri: Nama Barang + (Kategori & Modal) + Stock Status Badge
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    product.name ?? 'Tanpa Nama',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      letterSpacing: -0.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            catName,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : const Color(0xFF475569),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "Beli ${currencyFormat.format(buyPrice)}",
                        style: GoogleFonts.openSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6.5, vertical: 2),
                    decoration: BoxDecoration(
                      color: isLowStock
                          ? const Color(0xFFFFF1F2)
                          : (product.isStockManaged
                              ? const Color(0xFFECFDF5)
                              : (isDark ? Colors.white10 : const Color(0xFFF1F5F9))),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isLowStock
                            ? const Color(0xFFFECDD3)
                            : (product.isStockManaged
                                ? const Color(0xFFA7F3D0)
                                : Colors.transparent),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isLowStock
                              ? Icons.warning_amber_rounded
                              : (product.isStockManaged
                                  ? Icons.inventory_2_rounded
                                  : Icons.all_inclusive_rounded),
                          size: 11,
                          color: isLowStock
                              ? const Color(0xFFBE123C)
                              : (product.isStockManaged
                                  ? const Color(0xFF047857)
                                  : (isDark ? Colors.white70 : const Color(0xFF64748B))),
                        ),
                        const SizedBox(width: 3.5),
                        Text(
                          isLowStock ? "Sisa $stockText" : "Stok $stockText",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: isLowStock
                                ? const Color(0xFFBE123C)
                                : (product.isStockManaged
                                    ? const Color(0xFF047857)
                                    : (isDark ? Colors.white70 : const Color(0xFF64748B))),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Kanan: Harga Jual Prominen & Chevron
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "HARGA JUAL",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF94A3B8),
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  currencyFormat.format(salePrice),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF00BF63),
                  ),
                ),
                const SizedBox(height: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: Color(0xFF94A3B8),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<List<_StockCardEntry>> _loadProductStockCard(Product product) async {
    final db = Provider.of<AppDatabase>(context, listen: false);
    final admin = Provider.of<AdminController>(context, listen: false);
    final storeId = admin.storeId ?? '';
    final List<_StockCardEntry> rawMovements = [];

    try {
      // 1. Sales (PJ-xxxx)
      final allTxs = await (db.select(db.transactions)
            ..where((t) => t.storeId.equals(storeId))
            ..orderBy([(t) => drift.OrderingTerm.asc(t.createdAt)]))
          .get();
      final txOrderMap = <String, int>{};
      final txMap = <String, Transaction>{};
      for (int i = 0; i < allTxs.length; i++) {
        txOrderMap[allTxs[i].id] = i + 1;
        txMap[allTxs[i].id] = allTxs[i];
      }

      final allCusts = await (db.select(db.customers)
            ..where((c) => c.storeId.equals(storeId)))
          .get();
      final custMap = {for (final c in allCusts) c.id: (c.name ?? 'Umum')};

      final prodTxItems = await (db.select(db.transactionItems)
            ..where((ti) => ti.productId.equals(product.id)))
          .get();

      for (final ti in prodTxItems) {
        final tx = txMap[ti.transactionId];
        if (tx == null) continue;
        final pjNo = 'PJ-${(txOrderMap[tx.id] ?? 1).toString().padLeft(4, '0')}';
        final custName = (tx.customerName != null && tx.customerName!.trim().isNotEmpty)
            ? tx.customerName!.trim()
            : (tx.customerId != null && custMap.containsKey(tx.customerId)
                ? custMap[tx.customerId]!
                : 'Umum');
        final qtySold = (ti.quantity ?? 1).toDouble();
        rawMovements.add(_StockCardEntry(
          date: tx.createdAt ?? DateTime.now(),
          code: pjNo,
          description: "Pelanggan: $custName",
          qtyDelta: -qtySold,
        ));
      }

      // 2. Supplier Purchases & Returns (PB-xxxx / RB-xxxx)
      final supplierService = SupplierService(db);
      final suppliers = await supplierService.getSuppliers(storeId);
      final supMap = {for (final s in suppliers) s.id: s.name};
      final allSupTxs = await supplierService.getAllStoreTransactions(storeId);

      for (final stx in allSupTxs) {
        if (stx.type == 'purchase' || stx.type == 'return') {
          final supName = supMap[stx.supplierId] ?? '-';
          for (final item in stx.items) {
            final matchesId = item.productId == product.id;
            final matchesName = item.productId.isEmpty &&
                item.productName.toLowerCase().trim() ==
                    (product.name ?? '').toLowerCase().trim();
            if (matchesId || matchesName) {
              rawMovements.add(_StockCardEntry(
                date: stx.createdAt,
                code: stx.transactionNo,
                description: stx.type == 'return'
                    ? "Retur: $supName"
                    : "Supplier: $supName",
                qtyDelta: stx.type == 'return' ? -item.quantity : item.quantity,
              ));
            }
          }
        }
      }

      // 3. Stock Opname Logs (OP-xxxx)
      final prefs = await SharedPreferences.getInstance();
      final rawLogs = prefs.getStringList('stock_opname_logs_$storeId') ?? [];
      for (final raw in rawLogs) {
        try {
          final map = jsonDecode(raw) as Map<String, dynamic>;
          if (map['productId'] == product.id) {
            final delta = (map['qtyDelta'] as num?)?.toDouble() ?? 0.0;
            final notes = (map['notes'] as String? ?? '').trim();
            final dt = DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now();
            rawMovements.add(_StockCardEntry(
              date: dt,
              code: map['code'] as String? ?? 'OP-0001',
              description: notes.isNotEmpty ? "Opname: $notes" : "Opname stok",
              qtyDelta: delta,
            ));
          }
        } catch (_) {}
      }

      // Sort descending (newest first)
      rawMovements.sort((a, b) => b.date.compareTo(a.date));

      // Compute running saldo backwards from current product stock
      double runningStock = product.stockQuantity ?? 0.0;
      for (final m in rawMovements) {
        m.saldoAfter = runningStock;
        runningStock = runningStock - m.qtyDelta;
      }

      // If remaining stock before all recorded movements > 0, add "Stok awal" row at the bottom
      if (runningStock > 0) {
        rawMovements.add(_StockCardEntry(
          date: product.createdAt ?? DateTime.now(),
          code: '',
          description: "Stok awal",
          qtyDelta: runningStock,
          saldoAfter: runningStock,
        ));
      }
    } catch (e) {
      debugPrint("Error loading stock card: $e");
    }

    return rawMovements.take(30).toList();
  }

  Future<void> _showProductDetailSheet(Product initialProduct) async {
    Product currentProduct = initialProduct;
    List<_StockCardEntry> stockCard = await _loadProductStockCard(currentProduct);
    final prefs = await SharedPreferences.getInstance();
    double minStock = prefs.getDouble('product_min_stock_${currentProduct.id}') ?? 5.0;
    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final isDark = Theme.of(ctx).brightness == Brightness.dark;
            final catName = _getCategoryName(currentProduct);
            final unit = _getUnitLabel(currentProduct);
            final qty = currentProduct.stockQuantity ?? 0.0;
            final buyPrice = _getProductBuyPrice(currentProduct);
            final salePrice = currentProduct.salePrice ?? 0.0;
            final stockValue = _getProductStockValue(currentProduct);

            return Align(
              alignment: Alignment.bottomCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 580,
                  maxHeight: MediaQuery.of(ctx).size.height * 0.88,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: NAMA BARANG (UPPERCASE) + [X] Close Button
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                (currentProduct.name ?? 'BARANG').toUpperCase(),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2,
                                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () => Navigator.pop(ctx),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                                    width: 1,
                                  ),
                                ),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 19,
                                  color: isDark ? Colors.white70 : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                      ),

                      // Body Content (Scrollable)
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDetailRow(
                                label: "KATEGORI",
                                isDark: isDark,
                                valueWidget: Text(
                                  catName,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              _buildDetailRow(
                                label: "STOK",
                                isDark: isDark,
                                valueWidget: RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: currentProduct.isStockManaged
                                            ? "${_formatQty(qty)} $unit"
                                            : "∞ $unit",
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                                        ),
                                      ),
                                      if (currentProduct.isStockManaged)
                                        TextSpan(
                                          text: " (min. ${_formatQty(minStock)})",
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w400,
                                            color: isDark ? Colors.white.withValues(alpha: 0.5) : const Color(0xFF64748B),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              _buildDetailRow(
                                label: "HARGA BELI",
                                isDark: isDark,
                                valueWidget: Text(
                                  currencyFormat.format(buyPrice),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              _buildDetailRow(
                                label: "HARGA JUAL",
                                isDark: isDark,
                                valueWidget: Text(
                                  currencyFormat.format(salePrice),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              _buildDetailRow(
                                label: "NILAI STOK",
                                isDark: isDark,
                                valueWidget: Text(
                                  currencyFormat.format(stockValue),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              Text(
                                "KARTU STOK (30 TERAKHIR)",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.3,
                                  color: isDark ? Colors.white.withValues(alpha: 0.55) : const Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Table Header: TANGGAL | KETERANGAN | QTY | SALDO
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 78,
                                      child: Text(
                                        "TANGGAL",
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.2,
                                          color: isDark ? Colors.white.withValues(alpha: 0.5) : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        "KETERANGAN",
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.2,
                                          color: isDark ? Colors.white.withValues(alpha: 0.5) : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 56,
                                      child: Text(
                                        "QTY",
                                        textAlign: TextAlign.right,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.2,
                                          color: isDark ? Colors.white.withValues(alpha: 0.5) : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 62,
                                      child: Text(
                                        "SALDO",
                                        textAlign: TextAlign.right,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.2,
                                          color: isDark ? Colors.white.withValues(alpha: 0.5) : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Divider(
                                height: 1,
                                thickness: 1,
                                color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                              ),

                              if (stockCard.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 28),
                                  child: Center(
                                    child: Text(
                                      "Belum ada riwayat pergerakan stok",
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12.5,
                                        color: isDark ? Colors.white54 : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                )
                              else
                                ...List.generate(stockCard.length, (i) {
                                  final entry = stockCard[i];
                                  final isPlus = entry.qtyDelta >= 0;
                                  final qtyStr =
                                      "${isPlus ? '+' : ''}${_formatQty(entry.qtyDelta)}";
                                  return Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 9,
                                        ),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            SizedBox(
                                              width: 78,
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    DateFormat('d MMM', 'id_ID').format(entry.date),
                                                    style: GoogleFonts.plusJakartaSans(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w500,
                                                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                                                    ),
                                                  ),
                                                  if (entry.code.isNotEmpty) ...[
                                                    const SizedBox(height: 1.5),
                                                    Text(
                                                      entry.code,
                                                      style: GoogleFonts.plusJakartaSans(
                                                        fontSize: 10.5,
                                                        fontWeight: FontWeight.w400,
                                                        color: isDark ? Colors.white.withValues(alpha: 0.5) : const Color(0xFF64748B),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                            Expanded(
                                              child: Text(
                                                entry.description,
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 12.5,
                                                  fontWeight: FontWeight.w400,
                                                  color: isDark ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF334155),
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              width: 56,
                                              child: Text(
                                                qtyStr,
                                                textAlign: TextAlign.right,
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 12.5,
                                                  fontWeight: FontWeight.w600,
                                                  color: isPlus
                                                      ? const Color(0xFF0D7A4E)
                                                      : const Color(0xFFC0392B),
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              width: 62,
                                              child: Text(
                                                _formatQty(entry.saldoAfter),
                                                textAlign: TextAlign.right,
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 12.5,
                                                  fontWeight: FontWeight.w500,
                                                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (i < stockCard.length - 1)
                                        Divider(
                                          height: 1,
                                          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                                        ),
                                    ],
                                  );
                                }),
                            ],
                          ),
                        ),
                      ),

                      // Bottom Action Bar: [ 🗑 ] [ Opname ] [ ✏️ Edit ]
                      Divider(
                        height: 1,
                        thickness: 1.2,
                        color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Tombol Hapus [ 🗑 ]
                            InkWell(
                              onTap: () async {
                                Navigator.pop(ctx);
                                await _deleteProduct(currentProduct.id);
                              },
                              borderRadius: BorderRadius.circular(11),
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFC0392B),
                                  borderRadius: BorderRadius.circular(11),
                                ),
                                child: const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 20,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Tombol [ Opname ]
                            OutlinedButton(
                              onPressed: () async {
                                final updated = await _showOpnameProductSheet(currentProduct);
                                if (updated != null) {
                                  final freshCard = await _loadProductStockCard(updated);
                                  if (ctx.mounted) {
                                    setSheetState(() {
                                      currentProduct = updated;
                                      stockCard = freshCard;
                                    });
                                  }
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                                side: BorderSide(
                                  color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                                  width: 1.1,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(
                                "Opname",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Tombol [ ✏️ Edit ]
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(ctx);
                                _openProductForm(product: currentProduct);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0D7A4E),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: const Icon(Icons.edit_outlined, size: 16),
                              label: Text(
                                "Edit",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow({
    required String label,
    required Widget valueWidget,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 105,
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
              color: isDark ? Colors.white.withValues(alpha: 0.55) : const Color(0xFF64748B),
            ),
          ),
        ),
        Expanded(child: valueWidget),
      ],
    );
  }

  Future<Product?> _showOpnameProductSheet(Product product) async {
    final currentStock = product.stockQuantity ?? 0.0;
    final unit = _getUnitLabel(product);
    final physicalCtrl = TextEditingController(text: _formatQty(currentStock));
    final notesCtrl = TextEditingController();
    Product? updatedProduct;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final isDark = Theme.of(ctx).brightness == Brightness.dark;
            final newQty = double.tryParse(
                  physicalCtrl.text.replaceAll(',', '.').replaceAll(RegExp(r'[^0-9.]'), ''),
                ) ??
                currentStock;
            final diff = newQty - currentStock;

            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 540),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  "OPNAME STOK — ${(product.name ?? '').toUpperCase()}",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.2,
                                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: () => Navigator.pop(ctx),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                                      width: 1,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.close_rounded,
                                    size: 19,
                                    color: isDark ? Colors.white70 : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Divider(height: 1, color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                          const SizedBox(height: 16),

                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Stok Sistem Saat Ini",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? Colors.white70 : const Color(0xFF64748B),
                                  ),
                                ),
                                Text(
                                  "${_formatQty(currentStock)} $unit",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          Text(
                            "STOK FISIK SEBENARNYA ($unit)",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                              color: isDark ? Colors.white.withValues(alpha: 0.55) : const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: physicalCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            autofocus: true,
                            onChanged: (_) => setModalState(() {}),
                            decoration: InputDecoration(
                              hintText: "Masukkan jumlah stok fisik",
                              filled: true,
                              fillColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Selisih opname: ${diff >= 0 ? '+' : ''}${_formatQty(diff)} $unit",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: diff == 0
                                  ? const Color(0xFF64748B)
                                  : (diff > 0 ? const Color(0xFF0D7A4E) : const Color(0xFFC0392B)),
                            ),
                          ),
                          const SizedBox(height: 14),

                          Text(
                            "KETERANGAN / CATATAN (OPSIONAL)",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                              color: isDark ? Colors.white.withValues(alpha: 0.55) : const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: notesCtrl,
                            decoration: InputDecoration(
                              hintText: "mis. Opname stok rutin / barang rusak",
                              filled: true,
                              fillColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton(
                                onPressed: () => Navigator.pop(ctx),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(11),
                                  ),
                                ),
                                child: Text(
                                  "Batal",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  final db = Provider.of<AppDatabase>(context, listen: false);
                                  final admin = Provider.of<AdminController>(context, listen: false);
                                  final storeId = admin.storeId ?? '';

                                  await (db.update(db.products)
                                        ..where((t) => t.id.equals(product.id)))
                                      .write(
                                    ProductsCompanion(
                                      stockQuantity: drift.Value(newQty),
                                      isStockManaged: const drift.Value(true),
                                      lastUpdated: drift.Value(DateTime.now()),
                                    ),
                                  );

                                  final prefs = await SharedPreferences.getInstance();
                                  final logsKey = 'stock_opname_logs_$storeId';
                                  final logs = prefs.getStringList(logsKey) ?? [];
                                  final opCode = 'OP-${(logs.length + 1).toString().padLeft(4, '0')}';
                                  logs.add(jsonEncode({
                                    'id': const Uuid().v4(),
                                    'code': opCode,
                                    'productId': product.id,
                                    'qtyDelta': diff,
                                    'notes': notesCtrl.text.trim(),
                                    'createdAt': DateTime.now().toIso8601String(),
                                  }));
                                  await prefs.setStringList(logsKey, logs);

                                  updatedProduct = product.copyWith(
                                    stockQuantity: drift.Value(newQty),
                                    isStockManaged: true,
                                    lastUpdated: drift.Value(DateTime.now()),
                                  );

                                  if (ctx.mounted) Navigator.pop(ctx);
                                  await _fetchData();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0D7A4E),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(11),
                                  ),
                                ),
                                icon: const Icon(Icons.check_rounded, size: 17),
                                label: Text(
                                  "Simpan Opname",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    return updatedProduct;
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
                ? const Color(0xFF00BF63)
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

    const primaryGreen = Color(0xFF00BF63);

    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isSelected
                  ? primaryGreen.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 16,
              color: isSelected ? primaryGreen : Colors.grey[600],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.openSans(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? primaryGreen : null,
            ),
          ),
          if (isSelected) ...[
            const Spacer(),
            const Icon(
              Icons.check_circle_rounded,
              size: 16,
              color: primaryGreen,
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
        iconColor: const Color(0xFF00BF63),
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
            color: const Color(0xFF00BF63),
          ),
        ),
        Text(
          desc,
          style: GoogleFonts.openSans(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
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

