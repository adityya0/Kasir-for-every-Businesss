import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/app_database.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';
import '../../widgets/kasir_dialog.dart';

class UnitManagementPage extends StatefulWidget {
  final String? storeId;
  final VoidCallback? onBack;
  final VoidCallback? onNavigateToProducts;

  const UnitManagementPage({
    super.key,
    this.storeId,
    this.onBack,
    this.onNavigateToProducts,
  });

  @override
  State<UnitManagementPage> createState() => _UnitManagementPageState();
}

class _UnitManagementPageState extends State<UnitManagementPage> {
  bool _isLoading = true;
  List<Unit> _units = [];
  Map<String, int> _productCounts = {};
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  static const Color _primaryColor = Color(0xFF00BF63);

  @override
  void initState() {
    super.initState();
    _fetchUnits();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchUnits() async {
    try {
      final db = Provider.of<AppDatabase>(context, listen: false);

      // Fetch units (either store specific or global/null)
      final unitQuery = db.select(db.units);
      if (widget.storeId != null) {
        unitQuery.where((t) => t.storeId.isNull() | t.storeId.equals(widget.storeId!));
      }
      unitQuery.orderBy([(t) => drift.OrderingTerm.asc(t.name)]);
      var data = await unitQuery.get();

      // If empty, auto-seed default common units
      if (data.isEmpty) {
        await _seedDefaultUnits(db);
        data = await unitQuery.get();
      }

      // Fetch products to count usage
      final prodQuery = db.select(db.products)..where((t) => t.isDeleted.equals(false));
      if (widget.storeId != null) {
        prodQuery.where((t) => t.storeId.equals(widget.storeId!));
      }
      final products = await prodQuery.get();

      final Map<String, int> counts = {};
      for (var p in products) {
        if (p.unitId != null && p.unitId!.isNotEmpty) {
          counts[p.unitId!] = (counts[p.unitId!] ?? 0) + 1;
        }
      }

      if (mounted) {
        setState(() {
          _units = data;
          _productCounts = counts;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("UnitManagementPage: Fetch failed: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _seedDefaultUnits(AppDatabase db) async {
    final defaultUnits = [
      {'id': 'uPcs', 'name': 'Pieces (Buah)', 'code': 'Pcs', 'fractional': false},
      {'id': 'uPack', 'name': 'Pack (Bungkus)', 'code': 'Pack', 'fractional': false},
      {'id': 'uLsn', 'name': 'Lusin (12 pcs)', 'code': 'Lsn', 'fractional': false},
      {'id': 'uBox', 'name': 'Box / Dus', 'code': 'Box', 'fractional': false},
      {'id': 'uBtl', 'name': 'Botol', 'code': 'Btl', 'fractional': false},
      {'id': 'uKg', 'name': 'Kilogram', 'code': 'Kg', 'fractional': true},
      {'id': 'uGram', 'name': 'Gram', 'code': 'Gr', 'fractional': true},
      {'id': 'uLiter', 'name': 'Liter', 'code': 'L', 'fractional': true},
      {'id': 'uPorsi', 'name': 'Porsi', 'code': 'Prs', 'fractional': false},
      {'id': 'uCup', 'name': 'Cup / Gelas', 'code': 'Cup', 'fractional': false},
    ];

    for (var u in defaultUnits) {
      try {
        await db.into(db.units).insertOnConflictUpdate(
          UnitsCompanion.insert(
            id: u['id'] as String,
            storeId: drift.Value(widget.storeId),
            name: u['name'] as String,
            code: u['code'] as String,
            isFractional: drift.Value(u['fractional'] as bool),
            createdAt: drift.Value(DateTime.now()),
          ),
        );
      } catch (_) {}
    }
  }

  Future<void> _showUnitSheet({Unit? unit}) async {
    final isEditing = unit != null;
    final nameCtrl = TextEditingController(text: unit?.name);
    final codeCtrl = TextEditingController(text: unit?.code);
    bool isFractional = unit?.isFractional ?? false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final cardColor = Theme.of(context).cardColor;
          final inputFill = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100];

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              ),
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
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
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD97706).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.straighten_rounded,
                            color: Color(0xFFD97706),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isEditing ? "Edit Satuan Produk" : "Tambah Satuan Baru",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                "Contoh: Pcs, Pack, Lusin, Dus, Kg",
                                style: GoogleFonts.openSans(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Nama Satuan
                    Text(
                      "Nama Satuan *",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameCtrl,
                      autofocus: !isEditing,
                      decoration: InputDecoration(
                        hintText: "Misal: Pieces, Pack, Lusin, Box",
                        filled: true,
                        fillColor: inputFill,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(Icons.label_outline_rounded),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Kode / Singkatan
                    Text(
                      "Kode / Singkatan *",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: codeCtrl,
                      decoration: InputDecoration(
                        hintText: "Misal: Pcs, Pack, Lsn, Box, Kg",
                        filled: true,
                        fillColor: inputFill,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(Icons.short_text_rounded),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Tipe Input (Bulat vs Pecahan)
                    Text(
                      "Format Kuantitas / Angka",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setSheetState(() => isFractional = false),
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: !isFractional ? _primaryColor.withValues(alpha: 0.12) : inputFill,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: !isFractional ? _primaryColor : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        !isFractional ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                                        size: 18,
                                        color: !isFractional ? _primaryColor : Colors.grey,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        "Bilangan Bulat",
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: !isFractional ? _primaryColor : null,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Pcs, Pack, Lusin, Dus",
                                    style: GoogleFonts.openSans(fontSize: 11, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: () => setSheetState(() => isFractional = true),
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: isFractional ? Colors.purple.withValues(alpha: 0.12) : inputFill,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isFractional ? Colors.purple : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        isFractional ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                                        size: 18,
                                        color: isFractional ? Colors.purple : Colors.grey,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        "Pecahan / Desimal",
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: isFractional ? Colors.purple : null,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Kg, Gram, Liter",
                                    style: GoogleFonts.openSans(fontSize: 11, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Tombol Simpan
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () async {
                          final name = nameCtrl.text.trim();
                          final code = codeCtrl.text.trim();
                          if (name.isEmpty || code.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Nama dan kode satuan tidak boleh kosong!"),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          final db = Provider.of<AppDatabase>(context, listen: false);
                          try {
                            if (isEditing) {
                              await (db.update(db.units)..where((t) => t.id.equals(unit.id))).write(
                                UnitsCompanion(
                                  name: drift.Value(name),
                                  code: drift.Value(code),
                                  isFractional: drift.Value(isFractional),
                                ),
                              );
                            } else {
                              final newId = 'u_${const Uuid().v4().substring(0, 8)}';
                              await db.into(db.units).insert(
                                UnitsCompanion.insert(
                                  id: newId,
                                  storeId: drift.Value(widget.storeId),
                                  name: name,
                                  code: code,
                                  isFractional: drift.Value(isFractional),
                                  createdAt: drift.Value(DateTime.now()),
                                ),
                              );
                            }

                            if (context.mounted) {
                              Navigator.pop(ctx);
                              _fetchUnits();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isEditing
                                        ? "Satuan '$name' berhasil diperbarui!"
                                        : "Satuan '$name' berhasil ditambahkan!",
                                  ),
                                  backgroundColor: _primaryColor,
                                ),
                              );
                            }
                          } catch (e) {
                            debugPrint("Error saving unit: $e");
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Gagal menyimpan satuan: $e"),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        child: Text(
                          isEditing ? "Simpan Perubahan" : "Tambah Satuan",
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
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
        },
      ),
    );
  }

  Future<void> _deleteUnit(Unit unit) async {
    final usedCount = _productCounts[unit.id] ?? 0;
    final warningMsg = usedCount > 0
        ? "Ada $usedCount produk yang saat ini menggunakan satuan '${unit.name}' (${unit.code}). Jika dihapus, produk tersebut akan dialihkan ke 'Tanpa Satuan'."
        : "Satuan '${unit.name}' (${unit.code}) akan dihapus secara permanen.";

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => KasirDialog(
        title: "Hapus Satuan?",
        message: warningMsg,
        icon: Icons.delete_outline_rounded,
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

        // If used by products, nullify their unitId
        if (usedCount > 0) {
          await (db.update(db.products)..where((t) => t.unitId.equals(unit.id))).write(
            const ProductsCompanion(
              unitId: drift.Value(null),
            ),
          );
        }

        // Delete the unit
        await (db.delete(db.units)..where((t) => t.id.equals(unit.id))).go();
        _fetchUnits();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Satuan '${unit.name}' berhasil dihapus!"),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      } catch (e) {
        debugPrint("Error deleting unit: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filteredUnits = _units.where((u) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return u.name.toLowerCase().contains(q) || u.code.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Kelola Satuan Produk",
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: widget.onBack != null
            ? IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 20,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
                onPressed: widget.onBack,
              )
            : IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 20,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
                onPressed: () => Navigator.pop(context),
              ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: "Muat Ulang / Pulihkan Standar",
            onPressed: () async {
              final db = Provider.of<AppDatabase>(context, listen: false);
              await _seedDefaultUnits(db);
              _fetchUnits();
            },
          ),
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
          : Column(
              children: [
                // Search & Quick Info Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    decoration: InputDecoration(
                      hintText: "Cari satuan (pcs, pack, lusin, box, kg...)",
                      hintStyle: GoogleFonts.openSans(
                        fontSize: 13,
                        color: isDark ? Colors.white38 : Colors.grey[500],
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: isDark ? Colors.white54 : Colors.grey[600],
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: isDark ? Colors.white12 : Colors.grey.withValues(alpha: 0.15),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: isDark ? Colors.white12 : Colors.grey.withValues(alpha: 0.15),
                        ),
                      ),
                    ),
                  ),
                ),

                // List of Units
                Expanded(
                  child: filteredUnits.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.straighten_rounded,
                                size: 72,
                                color: Colors.grey.withValues(alpha: 0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? "Satuan '$_searchQuery' tidak ditemukan"
                                    : "Belum ada satuan produk",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFD97706),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: const Icon(Icons.restore_rounded, color: Colors.white, size: 18),
                                label: const Text(
                                  "Pulihkan Satuan Standar (Pcs, Pack, Lusin)",
                                  style: TextStyle(color: Colors.white),
                                ),
                                onPressed: () async {
                                  final db = Provider.of<AppDatabase>(context, listen: false);
                                  await _seedDefaultUnits(db);
                                  _fetchUnits();
                                },
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                          itemCount: filteredUnits.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final unit = filteredUnits[index];
                            final count = _productCounts[unit.id] ?? 0;

                            return Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDark ? Colors.white12 : Colors.grey.withValues(alpha: 0.15),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD97706).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    unit.code,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      color: const Color(0xFFD97706),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        unit.name,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: unit.isFractional
                                            ? Colors.purple.withValues(alpha: 0.1)
                                            : _primaryColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        unit.isFractional ? "Desimal" : "Bulat",
                                        style: GoogleFonts.openSans(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: unit.isFractional ? Colors.purple : _primaryColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.inventory_2_outlined,
                                        size: 14,
                                        color: isDark ? Colors.white38 : Colors.grey[500],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        count > 0 ? "$count Produk terhubung" : "Belum ada produk",
                                        style: GoogleFonts.openSans(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: isDark ? Colors.white54 : Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF2563EB)),
                                      tooltip: "Edit Satuan",
                                      onPressed: () => _showUnitSheet(unit: unit),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.redAccent),
                                      tooltip: "Hapus Satuan",
                                      onPressed: () => _deleteUnit(unit),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUnitSheet(),
        backgroundColor: const Color(0xFFD97706),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          "Tambah Satuan",
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
