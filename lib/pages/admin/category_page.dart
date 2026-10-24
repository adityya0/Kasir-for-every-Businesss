import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/app_database.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';
import '../../widgets/kasir_dialog.dart';

class CategoryPage extends StatefulWidget {
  final String storeId;
  final VoidCallback? onBack;
  final VoidCallback? onNavigateToProducts;
  const CategoryPage({
    super.key,
    required this.storeId,
    this.onBack,
    this.onNavigateToProducts,
  });

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  bool _isLoading = true;
  List<Category> _categories = [];
  Map<String, int> _productCounts = {};

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      final db = Provider.of<AppDatabase>(context, listen: false);
      final data =
          await (db.select(db.categories)
                ..where((t) => t.storeId.equals(widget.storeId))
                ..orderBy([(t) => drift.OrderingTerm.asc(t.name)]))
              .get();

      // 2. Fetch non-deleted products to count them
      final products =
          await (db.select(db.products)
                ..where((t) => t.storeId.equals(widget.storeId))
                ..where((t) => t.isDeleted.equals(false)))
              .get();

      final Map<String, int> counts = {};
      for (var p in products) {
        if (p.categoryId != null) {
          counts[p.categoryId!] = (counts[p.categoryId!] ?? 0) + 1;
        }
      }

      if (mounted) {
        setState(() {
          _categories = data;
          _productCounts = counts;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("CategoryPage: Fetch failed: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showCategorySheet({Category? category}) async {
    final isEditing = category != null;
    final controller = TextEditingController(text: category?.name);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isEditing ? "Edit Kategori" : "Tambah Kategori",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                autofocus: true,
                style: GoogleFonts.openSans(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black87,
                ),
                decoration: InputDecoration(
                  hintText: "Nama Kategori (Contoh: Makanan)",
                  hintStyle: GoogleFonts.openSans(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white38
                        : Colors.grey[400],
                  ),
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: Icon(
                    Icons.grid_view,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white70
                        : Colors.grey,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    final name = controller.text.trim();
                    if (name.isEmpty) return;

                    final db = Provider.of<AppDatabase>(context, listen: false);
                    try {
                      if (isEditing) {
                        await (db.update(
                          db.categories,
                        )..where((t) => t.id.equals(category.id))).write(
                          CategoriesCompanion(
                            name: drift.Value(name),
                            lastUpdated: drift.Value(DateTime.now()),
                          ),
                        );
                      } else {
                        final id = const Uuid().v4();
                        await db
                            .into(db.categories)
                            .insert(
                              CategoriesCompanion.insert(
                                id: id,
                                name: drift.Value(name),
                                storeId: drift.Value(widget.storeId),
                                lastUpdated: drift.Value(DateTime.now()),
                              ),
                            );
                      }
                      if (context.mounted) {
                        Navigator.pop(ctx);
                        _fetchCategories();
                      }
                    } catch (e) {
                      debugPrint("Error saving category: $e");
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC0392B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    isEditing ? "Simpan Perubahan" : "Tambah Kategori",
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteCategory(String id) async {
    final category = _categories.firstWhere((c) => c.id == id);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => KasirDialog(
        title: "Hapus Kategori?",
        message:
            "Tindakan ini tidak dapat dibatalkan. Kategori '${category.name}' akan dihapus.",
        icon: Icons.delete,
        iconColor: Colors.redAccent,
        primaryActionLabel: "Hapus",
        isDestructive: true,
        onPrimaryAction: () => Navigator.pop(ctx, true),
        secondaryActionLabel: "Batal",
      ),
    );

    if (confirm == true && mounted) {
      try {
        final db = Provider.of<AppDatabase>(context, listen: false);
        await (db.delete(db.categories)..where((t) => t.id.equals(id))).go();
        _fetchCategories();
      } catch (e) {
        debugPrint("Error deleting category: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Manajemen Kategori",
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF2D3436),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: widget.onBack != null
            ? IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: isDark ? Colors.white : const Color(0xFF2D3436),
                ),
                onPressed: widget.onBack,
              )
            : const SizedBox.shrink(),
        actions: [
          if (widget.onNavigateToProducts != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: widget.onNavigateToProducts,
                icon: Icon(
                  Icons.inventory_2_outlined,
                  size: 18,
                  color: isDark ? Colors.white70 : const Color(0xFF2D3436),
                ),
                label: Text(
                  "Produk",
                  style: GoogleFonts.openSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : const Color(0xFF2D3436),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _categories.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.grid_view, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    "Belum ada kategori",
                    style: GoogleFonts.openSans(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
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
                      backgroundColor: Colors.indigo.withValues(alpha: 0.1),
                      child: const Icon(
                        Icons.grid_view,
                        color: Colors.indigo,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      cat.name ?? '',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: isDark ? Colors.white : const Color(0xFF2D3436),
                      ),
                    ),
                    subtitle: Text(
                      "${_productCounts[cat.id] ?? 0} Produk",
                      style: GoogleFonts.openSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white38 : Colors.grey[600],
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.edit,
                            size: 20,
                            color: Colors.grey,
                          ),
                          onPressed: () => _showCategorySheet(category: cat),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 20,
                            color: Colors.redAccent,
                          ),
                          onPressed: () => _deleteCategory(cat.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCategorySheet(),
        backgroundColor: const Color(0xFFC0392B),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          "Tambah Kategori",
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

