import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../services/platform/file_manager.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import 'package:provider/provider.dart';
import '../../../services/app_database.dart';
import 'package:drift/drift.dart' as drift;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../../controllers/settings_controller.dart';
import '../../../services/supplier_service.dart';

class ProductFormSheet extends StatefulWidget {
  final Product? product; // If null, Add mode. If not, Edit mode.
  final String storeId;

  const ProductFormSheet({super.key, this.product, required this.storeId});

  @override
  State<ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends State<ProductFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _buyPriceController = TextEditingController(); // Harga Beli
  final _salePriceController = TextEditingController(); // Harga Jual
  final _stockController = TextEditingController();
  final _minStockController = TextEditingController(text: '5');

  bool _isLoading = false;

  // Stock Management Logic
  bool _isStockManaged = true; // Default to managed

  // Image Logic
  XFile? _imageFile;
  String? _currentImageUrl;
  final ImagePicker _picker = ImagePicker();

  // Category Logic
  String? _selectedCategoryId;
  List<Category> _categories = [];

  // Supplier Logic
  String? _selectedSupplierId;
  List<Supplier> _availableSuppliers = [];

  // Unit (Satuan) Logic
  String? _selectedUnitId;
  List<Unit> _availableUnits = [];

  // Variant & Options Logic
  bool _enableVariants = false;
  List<Map<String, dynamic>> _productOptions = [];

  final Color _primaryColor = const Color(0xFF00BF63);
  
  // Wholesale Pricing
  List<Map<String, dynamic>> _wholesalePrices = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadSuppliers();
    _loadUnits();
    if (widget.product != null) {
      _nameController.text = widget.product!.name ?? '';
      _skuController.text = widget.product!.sku ?? '';
      _descriptionController.text = widget.product!.description ?? '';
      final buyP = widget.product!.buyPrice ?? widget.product!.basePrice ?? 0;
      _buyPriceController.text = (buyP % 1 == 0 ? buyP.toInt() : buyP).toString();
      final saleP = widget.product!.salePrice ?? 0;
      _salePriceController.text = (saleP % 1 == 0 ? saleP.toInt() : saleP).toString();
      final stockQ = widget.product!.stockQuantity ?? 0;
      _stockController.text = (stockQ % 1 == 0 ? stockQ.toInt() : stockQ).toString();

      _isStockManaged = widget.product!.isStockManaged;
      _currentImageUrl = widget.product!.imageUrl;
      _selectedCategoryId = widget.product!.categoryId;
      _selectedUnitId = widget.product!.unitId;
      
      // Parse Wholesale Prices
      if (widget.product!.wholesalePricesJson != null) {
        try {
          final List decoded = jsonDecode(widget.product!.wholesalePricesJson!);
          _wholesalePrices = decoded.cast<Map<String, dynamic>>();
        } catch (_) {}
      }
      
      _fetchOptions();
      _loadProductMinStock(widget.product!.id);
    }
  }


  Future<void> _loadProductMinStock(String prodId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMin = prefs.getDouble('product_min_stock_$prodId');
      if (savedMin != null && mounted) {
        _minStockController.text = (savedMin % 1 == 0 ? savedMin.toInt() : savedMin).toString();
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _descriptionController.dispose();
    _buyPriceController.dispose();
    _salePriceController.dispose();
    _stockController.dispose();
    _minStockController.dispose();
    super.dispose();
  }

  Future<void> _fetchOptions() async {
    if (widget.product == null) return;
    try {
      final db = Provider.of<AppDatabase>(context, listen: false);
      final options = await (db.select(
        db.productOptions,
      )..where((t) => t.productId.equals(widget.product!.id))).get();

      final List<Map<String, dynamic>> formattedOptions = [];
      for (var opt in options) {
        final values = await (db.select(
          db.productOptionValues,
        )..where((t) => t.optionId.equals(opt.id))).get();

        formattedOptions.add({
          'id': opt.id,
          'option_name': opt.optionName,
          'is_required': opt.isRequired,
          'product_option_values': values
              .map(
                (v) => {
                  'id': v.id,
                  'value_name': v.valueName,
                  'price_adjustment': v.priceAdjustment,
                  'stockMultiplier': v.stockMultiplier,
                },
              )
              .toList(),
        });
      }

      if (mounted) {
        setState(() {
          _productOptions = formattedOptions;
            if (_productOptions.isNotEmpty) {
              _enableVariants = true;
            }
          });
        }
      } catch (e) {
        debugPrint("Error fetching options: $e");
      }
    }


  Future<void> _loadSuppliers() async {
    try {
      final db = Provider.of<AppDatabase>(context, listen: false);
      final supplierService = SupplierService(db);
      final list = await supplierService.getSuppliers(widget.storeId);
      String? matchedSupplierId;

      if (widget.product != null) {
        final prodId = widget.product!.id;
        for (final s in list) {
          if (s.productUsualStock.containsKey(prodId) || s.productPrices.containsKey(prodId)) {
            matchedSupplierId = s.id;
            break;
          }
        }
      }

      if (mounted) {
        setState(() {
          _availableSuppliers = list;
          _selectedSupplierId = matchedSupplierId ?? _selectedSupplierId;
        });
      }
    } catch (e) {
      debugPrint("Error loading suppliers: $e");
    }
  }

  Future<void> _addNewSupplier() async {
    final db = Provider.of<AppDatabase>(context, listen: false);
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final addressCtrl = TextEditingController();

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Tambah Supplier Baru",
          style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Nama Supplier *", style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: nameCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: "Contoh: CV Sumber Berkah",
                  fillColor: Colors.grey.withValues(alpha: 0.1),
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 12),
              Text("No. Telepon / WhatsApp", style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: "Contoh: 08123456789",
                  fillColor: Colors.grey.withValues(alpha: 0.1),
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 12),
              Text("Alamat Supplier (Opsional)", style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: addressCtrl,
                decoration: InputDecoration(
                  hintText: "Contoh: Jl. Industri No. 45",
                  fillColor: Colors.grey.withValues(alpha: 0.1),
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text("Batal", style: GoogleFonts.openSans(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx, true);
            },
            child: const Text("Simpan Supplier", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (created == true && nameCtrl.text.trim().isNotEmpty) {
      try {
        final supplierService = SupplierService(db);
        final newSup = await supplierService.addSupplier(
          storeId: widget.storeId,
          name: nameCtrl.text.trim(),
          phone: phoneCtrl.text.trim(),
          address: addressCtrl.text.trim(),
        );

        if (!mounted) return;
        setState(() {
          if (!_availableSuppliers.any((s) => s.id == newSup.id)) {
            _availableSuppliers.add(newSup);
          }
          _selectedSupplierId = newSup.id;
        });

        await _loadSuppliers();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Supplier '${newSup.name}' berhasil ditambahkan!"),
              backgroundColor: _primaryColor,
            ),
          );
        }
      } catch (e) {
        debugPrint("Error adding new supplier: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Gagal menambahkan supplier: $e"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _loadUnits() async {
    try {
      final db = Provider.of<AppDatabase>(context, listen: false);
      final unitQuery = db.select(db.units);
      unitQuery.where((t) => t.storeId.isNull() | t.storeId.equals(widget.storeId));
      unitQuery.orderBy([(t) => drift.OrderingTerm.asc(t.name)]);
      var list = await unitQuery.get();

      if (list.isEmpty) {
        final defaultUnits = [
          {'id': 'uPcs', 'name': 'Pieces (Buah)', 'code': 'Pcs', 'fractional': false},
          {'id': 'uPack', 'name': 'Pack (Bungkus)', 'code': 'Pack', 'fractional': false},
          {'id': 'uLsn', 'name': 'Lusin (12 pcs)', 'code': 'Lsn', 'fractional': false},
          {'id': 'uBox', 'name': 'Box / Dus', 'code': 'Box', 'fractional': false},
          {'id': 'uBtl', 'name': 'Botol', 'code': 'Btl', 'fractional': false},
          {'id': 'uKg', 'name': 'Kilogram', 'code': 'Kg', 'fractional': true},
          {'id': 'uGram', 'name': 'Gram', 'code': 'Gr', 'fractional': true},
          {'id': 'uLiter', 'name': 'Liter', 'code': 'L', 'fractional': true},
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
        list = await unitQuery.get();
      }

      if (mounted) {
        setState(() {
          _availableUnits = list;
        });
      }
    } catch (e) {
      debugPrint("Error loading units: $e");
    }
  }

  Future<void> _addNewUnit() async {
    final db = Provider.of<AppDatabase>(context, listen: false);
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    bool isFractional = false;

    final created = await showModalBottomSheet<bool>(
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
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD97706).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.straighten_rounded, color: Color(0xFFD97706), size: 20),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "Tambah Satuan Baru",
                          style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text("Nama Satuan *", style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameCtrl,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: "Contoh: Lusin, Pack, Pieces, Dus",
                        fillColor: inputFill,
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text("Kode / Singkatan *", style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: codeCtrl,
                      decoration: InputDecoration(
                        hintText: "Contoh: Lsn, Pack, Pcs, Box, Kg",
                        fillColor: inputFill,
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text("Format Angka", style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setSheetState(() => isFractional = false),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: !isFractional ? _primaryColor.withValues(alpha: 0.12) : inputFill,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: !isFractional ? _primaryColor : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                "Bilangan Bulat\n(Pcs, Lsn, Pack)",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: !isFractional ? _primaryColor : null,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            onTap: () => setSheetState(() => isFractional = true),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: isFractional ? Colors.purple.withValues(alpha: 0.12) : inputFill,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isFractional ? Colors.purple : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                "Desimal / Pecahan\n(Kg, Liter)",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isFractional ? Colors.purple : null,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: Text("Batal", style: GoogleFonts.openSans(color: Colors.grey)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD97706),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () {
                              if (nameCtrl.text.trim().isEmpty || codeCtrl.text.trim().isEmpty) return;
                              Navigator.pop(ctx, true);
                            },
                            child: const Text("Simpan Satuan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );

    if (created == true && nameCtrl.text.trim().isNotEmpty && codeCtrl.text.trim().isNotEmpty) {
      try {
        final newId = 'u_${const Uuid().v4().substring(0, 8)}';
        final newUnit = Unit(
          id: newId,
          storeId: widget.storeId,
          name: nameCtrl.text.trim(),
          code: codeCtrl.text.trim(),
          isFractional: isFractional,
          createdAt: DateTime.now(),
        );

        await db.into(db.units).insert(
          UnitsCompanion.insert(
            id: newId,
            storeId: drift.Value(widget.storeId),
            name: newUnit.name,
            code: newUnit.code,
            isFractional: drift.Value(isFractional),
            createdAt: drift.Value(DateTime.now()),
          ),
        );

        if (!mounted) return;
        setState(() {
          if (!_availableUnits.any((u) => u.id == newUnit.id)) {
            _availableUnits.add(newUnit);
          }
          _selectedUnitId = newUnit.id;
        });

        await _loadUnits();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Satuan '${newUnit.name}' (${newUnit.code}) berhasil ditambahkan!"),
              backgroundColor: const Color(0xFFD97706),
            ),
          );
        }
      } catch (e) {
        debugPrint("Error adding unit: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Gagal menambahkan satuan: $e"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _loadCategories() async {
    try {
      final db = Provider.of<AppDatabase>(context, listen: false);
      final response =
          await (db.select(db.categories)
                ..where((t) => t.storeId.equals(widget.storeId))
                ..orderBy([(t) => drift.OrderingTerm.asc(t.name)]))
              .get();
      if (mounted) {
        setState(() {
          _categories = response;
          if (_selectedCategoryId != null &&
              !_categories.any((c) => c.id == _selectedCategoryId)) {
            _selectedCategoryId = null;
          }
        });
      }
    } catch (e) {
      debugPrint("Error loading categories: $e");
    }
  }

  void _addOption() {
    setState(() {
      _productOptions.add({
        'id': const Uuid().v4(),
        'option_name': '',
        'is_required': false,
        'product_option_values': [],
      });
      _enableVariants = true;
    });
  }


  void _removeOption(int index) {
    setState(() {
      _productOptions.removeAt(index);
      if (_productOptions.isEmpty) _enableVariants = false;
    });
  }

  void _addValue(int optionIndex) {
    setState(() {
      _productOptions[optionIndex]['product_option_values'].add({
        'id': const Uuid().v4(),
        'value_name': '',
        'price_adjustment': 0.0,
        'stockMultiplier': 1.0,
      });
    });
  }

  void _removeValue(int optionIndex, int valueIndex) {
    setState(() {
      _productOptions[optionIndex]['product_option_values'].removeAt(
        valueIndex,
      );
    });
  }

  Future<void> _showAddCategoryDialog() async {
    final controller = TextEditingController();
    final newCategoryName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Tambah Kategori",
          style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: "Nama Kategori (Contoh: Makanan, Minuman)",
            fillColor: Colors.grey.withValues(alpha: 0.1),
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Batal", style: GoogleFonts.openSans(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text("Simpan", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (newCategoryName != null && newCategoryName.isNotEmpty) {
      if (!mounted) return;
      setState(() => _isLoading = true);
      try {
        final db = Provider.of<AppDatabase>(context, listen: false);
        final id = const Uuid().v4();
        await db
            .into(db.categories)
            .insert(
              CategoriesCompanion.insert(
                id: id,
                name: drift.Value(newCategoryName),
                storeId: drift.Value(widget.storeId),
                lastUpdated: drift.Value(DateTime.now()),
              ),
            );

        await _loadCategories();
        if (mounted) {
          setState(() {
            _selectedCategoryId = id;
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Gagal menambah kategori: $e"),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Ambil Foto Produk",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSourceOption(
                  icon: Icons.camera_alt_rounded,
                  label: "Kamera",
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                _buildSourceOption(
                  icon: Icons.photo_library_rounded,
                  label: "Galeri",
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: _primaryColor, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.openSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _imageFile = pickedFile;
      });
    }
  }

  Future<String?> _saveLocalImage() async {
    if (_imageFile == null) return _currentImageUrl;

    try {
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}${p.extension(_imageFile!.path)}';
      final savedPath = await FileManager().saveFile(_imageFile!, fileName);

      return savedPath;
    } catch (e) {
      debugPrint("Save Image Error: $e");
      throw "Gagal simpan gambar: $e";
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final db = Provider.of<AppDatabase>(context, listen: false);
      final imageUrl = await _saveLocalImage();

      final name = _nameController.text.trim();
      final sku = _skuController.text.trim();
      final description = _descriptionController.text.trim();
      final buyPrice = double.tryParse(_buyPriceController.text.trim()) ?? 0.0;
      final salePrice =
          double.tryParse(_salePriceController.text.trim()) ?? 0.0;
      final stock = _isStockManaged
          ? (double.tryParse(_stockController.text.trim()) ?? 0.0)
          : 0.0;

      final productId = widget.product?.id ?? const Uuid().v4();

      await db.transaction(() async {
        final companion = ProductsCompanion(
          id: drift.Value(productId),
          storeId: drift.Value(widget.storeId),
          name: drift.Value(name),
          sku: drift.Value(sku.isEmpty ? null : sku),
          description: drift.Value(description.isEmpty ? null : description),
          basePrice: drift.Value(buyPrice),
          buyPrice: drift.Value(buyPrice),
          salePrice: drift.Value(salePrice),
          stockQuantity: drift.Value(stock),
          isStockManaged: drift.Value(_isStockManaged),
          categoryId: drift.Value(_selectedCategoryId),
          unitId: drift.Value(_selectedUnitId),
          imageUrl: drift.Value(imageUrl),
          wholesalePricesJson: drift.Value(_wholesalePrices.isNotEmpty 
            ? jsonEncode(_wholesalePrices) 
            : null),
          isAvailable: const drift.Value(true),
          lastUpdated: drift.Value(DateTime.now()),
        );

        await db.into(db.products).insertOnConflictUpdate(companion);

        if (_isStockManaged) {
          final minStockVal = double.tryParse(_minStockController.text.trim()) ?? 5.0;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setDouble('product_min_stock_$productId', minStockVal);
        }

        // Delete old options for a clean state
        await (db.delete(
          db.productOptions,
        )..where((t) => t.productId.equals(productId))).go();

        if (_enableVariants) {
          for (var opt in _productOptions) {
            final optName = opt['option_name'].toString().trim();
            if (optName.isEmpty) continue;

            final optId = const Uuid().v4();
            await db
                .into(db.productOptions)
                .insert(
                  ProductOptionsCompanion.insert(
                    id: optId,
                    productId: drift.Value(productId),
                    storeId: drift.Value(widget.storeId),
                    optionName: drift.Value(optName),
                    isRequired: drift.Value(
                      opt['is_required'] == true || opt['is_required'] == 1,
                    ),
                    lastUpdated: drift.Value(DateTime.now()),
                  ),
                );

            final values = List<Map<String, dynamic>>.from(
              opt['product_option_values'] ?? [],
            );

            for (var val in values) {
              final valName = val['value_name'].toString().trim();
              if (valName.isEmpty) continue;

              await db
                  .into(db.productOptionValues)
                  .insert(
                    ProductOptionValuesCompanion.insert(
                      id: const Uuid().v4(),
                      optionId: drift.Value(optId),
                      valueName: drift.Value(valName),
                      priceAdjustment: drift.Value(
                        val['price_adjustment']?.toDouble() ?? 0.0,
                      ),
                      stockMultiplier: drift.Value(
                        val['stockMultiplier']?.toDouble() ?? 1.0,
                      ),
                    ),
                  );
            }
          }
        }
      });

      // Update supplier linkage
      try {
        final supplierService = SupplierService(db);
        if (_selectedSupplierId != null) {
          await supplierService.linkProductToSupplier(
            storeId: widget.storeId,
            supplierId: _selectedSupplierId!,
            productId: productId,
            buyPrice: buyPrice > 0 ? buyPrice : null,
            usualStock: stock > 0 ? stock.round() : null,
          );
        } else {
          await supplierService.unlinkProductFromSuppliers(
            storeId: widget.storeId,
            productId: productId,
          );
        }
      } catch (e) {
        debugPrint("Error linking product to supplier: $e");
      }

      if (mounted) Navigator.pop(context, true); // Return true on success
    } catch (e) {
      debugPrint("Save Product Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal simpan: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool> _onWillPop() async {
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buang Perubahan?'),
        content: const Text('Data yang Anda masukkan akan hilang. Apakah Anda yakin ingin membatalkan?'),
        actions: [
          TextButton(
            child: const Text('Lanjutkan Edit'),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya, Buang'),
          ),
        ],
      ),
    );
    return shouldPop ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final headingColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final subtleBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final inputBorderColor = isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1);
    final inputFill = isDark ? const Color(0xFF0F172A) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Container(
        height: MediaQuery.of(context).size.height * 0.92,
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF131D2D) : const Color(0xFFF8FAFC),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle Bar
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _primaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      widget.product == null ? Icons.add_box_rounded : Icons.edit_note_rounded,
                      color: _primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.product == null ? "Tambah Produk Baru" : "Edit Produk",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w700,
                            color: headingColor,
                          ),
                        ),
                        Text(
                          widget.product == null
                              ? "Lengkapi detail katalog & harga produk"
                              : "Perbarui informasi, harga, dan stok",
                          style: GoogleFonts.openSans(
                            fontSize: 11.5,
                            color: secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      final shouldPop = await _onWillPop();
                      if (shouldPop && context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                    icon: Icon(Icons.close_rounded, color: secondaryTextColor),
                    tooltip: "Tutup",
                  ),
                ],
              ),
            ),

            Divider(height: 1, color: borderColor),

            // Form Content
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                  children: [
                    // ── CARD 1: INFORMASI UTAMA & FOTO ──────────────────────────────
                    _buildSectionCard(
                      cardBg: cardBg,
                      borderColor: borderColor,
                      title: "INFORMASI UTAMA",
                      icon: Icons.inventory_2_outlined,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top row: Photo Thumbnail + Nama & Kategori
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Photo Thumbnail (84x84)
                              GestureDetector(
                                onTap: _showImageSourceDialog,
                                child: Stack(
                                  children: [
                                    Container(
                                      width: 84,
                                      height: 84,
                                      decoration: BoxDecoration(
                                        color: subtleBg,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: inputBorderColor, width: 1.1),
                                        image: _imageFile != null
                                            ? DecorationImage(
                                                image: FileManager().getImageProvider(_imageFile!.path),
                                                fit: BoxFit.cover,
                                              )
                                            : (_currentImageUrl != null
                                                ? DecorationImage(
                                                    image: FileManager().getImageProvider(_currentImageUrl!),
                                                    fit: BoxFit.cover,
                                                  )
                                                : null),
                                      ),
                                      child: (_imageFile == null && _currentImageUrl == null)
                                          ? Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.add_a_photo_outlined,
                                                  size: 24,
                                                  color: _primaryColor,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  "Foto",
                                                  style: GoogleFonts.plusJakartaSans(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: secondaryTextColor,
                                                  ),
                                                ),
                                              ],
                                            )
                                          : null,
                                    ),
                                    if (_imageFile != null || _currentImageUrl != null)
                                      Positioned(
                                        right: 4,
                                        bottom: 4,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: _primaryColor,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.2),
                                                blurRadius: 3,
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.edit,
                                            size: 11,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Nama & Kategori
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildCompactField(
                                      label: "Nama Produk *",
                                      controller: _nameController,
                                      hintText: "Contoh: Es Kopi Susu Gula Aren",
                                      isDark: isDark,
                                      isRequired: true,
                                      inputFill: inputFill,
                                      inputBorderColor: inputBorderColor,
                                      textColor: textColor,
                                      prefixIcon: Icons.fastfood_outlined,
                                    ),
                                    const SizedBox(height: 10),
                                    _buildCategoryDropdown(
                                      isDark: isDark,
                                      inputFill: inputFill,
                                      inputBorderColor: inputBorderColor,
                                      textColor: textColor,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Row: SKU + Satuan (2 Columns)
                          Row(
                            children: [
                              Expanded(
                                child: _buildCompactField(
                                  label: "SKU / Barcode",
                                  controller: _skuController,
                                  hintText: "Opsional",
                                  isDark: isDark,
                                  isRequired: false,
                                  inputFill: inputFill,
                                  inputBorderColor: inputBorderColor,
                                  textColor: textColor,
                                  prefixIcon: Icons.qr_code_rounded,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildUnitDropdown(
                                  isDark: isDark,
                                  inputFill: inputFill,
                                  inputBorderColor: inputBorderColor,
                                  textColor: textColor,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          // Supplier Pemasok
                          _buildSupplierDropdown(
                            isDark: isDark,
                            inputFill: inputFill,
                            inputBorderColor: inputBorderColor,
                            textColor: textColor,
                          ),

                          const SizedBox(height: 10),

                          // Deskripsi
                          _buildCompactField(
                            label: "Deskripsi Produk",
                            controller: _descriptionController,
                            hintText: "Catatan rasa, komposisi, atau catatan porsi (opsional)",
                            isDark: isDark,
                            isRequired: false,
                            maxLines: 2,
                            inputFill: inputFill,
                            inputBorderColor: inputBorderColor,
                            textColor: textColor,
                            prefixIcon: Icons.notes_rounded,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ── CARD 2: HARGA & KEUNTUNGAN ──────────────────────────────────
                    _buildSectionCard(
                      cardBg: cardBg,
                      borderColor: borderColor,
                      title: "HARGA & KEUNTUNGAN",
                      icon: Icons.payments_outlined,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildCompactField(
                                  label: "Harga Beli (Modal)",
                                  controller: _buyPriceController,
                                  hintText: "0",
                                  isDark: isDark,
                                  isNumber: true,
                                  prefixText: "Rp ",
                                  isRequired: false,
                                  inputFill: inputFill,
                                  inputBorderColor: inputBorderColor,
                                  textColor: textColor,
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildCompactField(
                                  label: "Harga Jual (Kasir) *",
                                  controller: _salePriceController,
                                  hintText: "0",
                                  isDark: isDark,
                                  isNumber: true,
                                  prefixText: "Rp ",
                                  isRequired: true,
                                  inputFill: inputFill,
                                  inputBorderColor: inputBorderColor,
                                  textColor: textColor,
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                            ],
                          ),
                          _buildProfitMarginBadge(isDark),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ── CARD 3: MANAJEMEN STOK ──────────────────────────────────────
                    _buildSectionCard(
                      cardBg: cardBg,
                      borderColor: borderColor,
                      title: "MANAJEMEN STOK",
                      icon: Icons.inventory_outlined,
                      headerTrailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _isStockManaged
                                  ? _primaryColor.withValues(alpha: 0.12)
                                  : Colors.grey.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _isStockManaged ? "Stok Terbatas" : "Unlimited",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: _isStockManaged ? _primaryColor : secondaryTextColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Switch(
                            value: _isStockManaged,
                            activeThumbColor: _primaryColor,
                            onChanged: (val) => setState(() => _isStockManaged = val),
                          ),
                        ],
                      ),
                      child: _isStockManaged
                          ? Row(
                              children: [
                                Expanded(
                                  child: _buildCompactField(
                                    label: "Jumlah Stok Saat Ini",
                                    controller: _stockController,
                                    hintText: "0",
                                    isDark: isDark,
                                    isNumber: true,
                                    isRequired: true,
                                    inputFill: inputFill,
                                    inputBorderColor: inputBorderColor,
                                    textColor: textColor,
                                    prefixIcon: Icons.numbers_rounded,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _buildCompactField(
                                    label: "Batas Minimum (Peringatan)",
                                    controller: _minStockController,
                                    hintText: "5",
                                    isDark: isDark,
                                    isNumber: true,
                                    isRequired: false,
                                    inputFill: inputFill,
                                    inputBorderColor: inputBorderColor,
                                    textColor: textColor,
                                    prefixIcon: Icons.warning_amber_rounded,
                                  ),
                                ),
                              ],
                            )
                          : Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: subtleBg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.all_inclusive_rounded, size: 18, color: secondaryTextColor),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      "Produk selalu tersedia di kasir tanpa batasan stok.",
                                      style: GoogleFonts.openSans(fontSize: 12, color: secondaryTextColor),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),

                    const SizedBox(height: 14),

                    // ── CARD 4: VARIAN & OPSI (LEVEL, TOPPING, DSB) ────────────────
                    _buildSectionCard(
                      cardBg: cardBg,
                      borderColor: borderColor,
                      title: "VARIAN & OPSI TAMBAHAN",
                      icon: Icons.tune_rounded,
                      headerTrailing: Switch(
                        value: _enableVariants,
                        activeThumbColor: _primaryColor,
                        onChanged: (val) {
                          setState(() {
                            _enableVariants = val;
                            if (val && _productOptions.isEmpty) {
                              _addOption();
                            }
                          });
                        },
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Tambahkan opsi seperti Level Pedas, Rasa, Topping, atau Ukuran Porsi.",
                            style: GoogleFonts.openSans(fontSize: 11.5, color: secondaryTextColor),
                          ),
                          if (_enableVariants) ...[
                            const SizedBox(height: 12),
                            ...List.generate(_productOptions.length, (optIdx) {
                              final opt = _productOptions[optIdx];
                              return _buildOptionItem(opt, optIdx, textColor, isDark);
                            }),
                            const SizedBox(height: 8),
                            Center(
                              child: OutlinedButton.icon(
                                onPressed: _addOption,
                                icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                                label: const Text("Tambah Grup Opsi Baru", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _primaryColor,
                                  side: BorderSide(color: _primaryColor.withValues(alpha: 0.4)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // ── CARD 5: HARGA GROSIR (JIKA AKTIF) ───────────────────────────
                    if (SettingsController.instance.featureGrosirEnabled.value) ...[
                      const SizedBox(height: 14),
                      _buildSectionCard(
                        cardBg: cardBg,
                        borderColor: borderColor,
                        title: "HARGA GROSIR / BERJENJANG",
                        icon: Icons.layers_outlined,
                        child: _buildWholesalePricingSection(inputFill, textColor),
                      ),
                    ],

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            // ── STICKY BOTTOM ACTIONS ─────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: cardBg,
                border: Border(top: BorderSide(color: borderColor, width: 1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Batal
                  OutlinedButton(
                    onPressed: () async {
                      final shouldPop = await _onWillPop();
                      if (shouldPop && context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: secondaryTextColor,
                      side: BorderSide(color: inputBorderColor),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      "Batal",
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13.5),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Simpan Produk
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _saveProduct,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.check_rounded, size: 18),
                      label: Text(
                        _isLoading
                            ? "Menyimpan..."
                            : (widget.product == null ? "Simpan Produk" : "Perbarui Produk"),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required Color cardBg,
    required Color borderColor,
    required String title,
    required IconData icon,
    Widget? headerTrailing,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: _primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: _primaryColor,
                    ),
                  ),
                ],
              ),
              if (headerTrailing != null) headerTrailing,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildCompactField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    required bool isDark,
    required Color inputFill,
    required Color inputBorderColor,
    required Color textColor,
    bool isRequired = false,
    bool isNumber = false,
    String? prefixText,
    IconData? prefixIcon,
    int maxLines = 1,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white70 : const Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          maxLines: maxLines,
          onChanged: onChanged,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
          validator: (val) {
            if (!isRequired) return null;
            if (val == null || val.trim().isEmpty) return "$label wajib diisi";
            return null;
          },
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: GoogleFonts.openSans(
              fontSize: 12,
              color: isDark ? Colors.white30 : Colors.grey.shade400,
            ),
            prefixText: prefixText,
            prefixStyle: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _primaryColor,
            ),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, size: 16, color: isDark ? Colors.white54 : const Color(0xFF64748B))
                : null,
            prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            isDense: true,
            filled: true,
            fillColor: inputFill,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical: maxLines > 1 ? 10 : 9,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: inputBorderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: inputBorderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: _primaryColor, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.red.shade400, width: 1),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfitMarginBadge(bool isDark) {
    final buy = double.tryParse(_buyPriceController.text.trim()) ?? 0.0;
    final sale = double.tryParse(_salePriceController.text.trim()) ?? 0.0;

    if (sale <= 0) return const SizedBox.shrink();

    final profit = sale - buy;
    final marginPct = sale > 0 ? (profit / sale) * 100 : 0.0;
    final isLoss = profit < 0;

    final badgeBg = isLoss
        ? (isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.3) : const Color(0xFFFFF1F2))
        : (isDark ? const Color(0xFF064E3B).withValues(alpha: 0.3) : const Color(0xFFECFDF5));
    final badgeBorder = isLoss ? const Color(0xFFFDA4AF) : const Color(0xFFA7F3D0);
    final textColor = isLoss ? const Color(0xFFE11D48) : const Color(0xFF059669);

    final NumberFormat curFmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: badgeBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: badgeBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isLoss ? Icons.trending_down_rounded : Icons.trending_up_rounded,
            size: 15,
            color: textColor,
          ),
          const SizedBox(width: 6),
          Text(
            isLoss
                ? "Rugi: ${curFmt.format(profit.abs())} (${marginPct.toStringAsFixed(1)}%)"
                : "Estimasi Untung: ${curFmt.format(profit)} (Margin ${marginPct.toStringAsFixed(1)}%)",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDropdown({
    required bool isDark,
    required Color inputFill,
    required Color inputBorderColor,
    required Color textColor,
  }) {
    final isSelectedValid = _selectedCategoryId != null &&
        _categories.any((c) => c.id == _selectedCategoryId);
    final validSelectedValue = isSelectedValid ? _selectedCategoryId : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Kategori Produk",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white70 : const Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 5),
        DropdownButtonFormField<String?>(
          key: ValueKey("cat_dd_${validSelectedValue ?? 'none'}_${_categories.length}"),
          initialValue: validSelectedValue,
          isExpanded: true,
          dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          style: GoogleFonts.plusJakartaSans(color: textColor, fontWeight: FontWeight.w600, fontSize: 13),
          decoration: InputDecoration(
            hintText: "Pilih Kategori",
            hintStyle: GoogleFonts.openSans(fontSize: 12, color: Colors.grey.shade400),
            prefixIcon: Icon(Icons.category_outlined, size: 16, color: isDark ? Colors.white54 : const Color(0xFF64748B)),
            prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            suffixIcon: IconButton(
              onPressed: _showAddCategoryDialog,
              icon: Icon(Icons.add_circle_outline_rounded, color: _primaryColor, size: 18),
              tooltip: "Tambah Kategori Baru",
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
            isDense: true,
            filled: true,
            fillColor: inputFill,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: inputBorderColor)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: inputBorderColor)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _primaryColor, width: 1.5)),
          ),
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Text(
                "Tanpa Kategori",
                style: GoogleFonts.plusJakartaSans(fontSize: 13, color: textColor),
              ),
            ),
            ..._categories.map((cat) {
              return DropdownMenuItem<String?>(
                value: cat.id,
                child: Text(
                  cat.name ?? '',
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, color: textColor),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }),
            DropdownMenuItem<String?>(
              value: "NEW_CATEGORY",
              child: Row(
                children: [
                  Icon(Icons.add, color: _primaryColor, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    "Buat Kategori Baru",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: _primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
          onChanged: (val) {
            if (val == "NEW_CATEGORY") {
              _showAddCategoryDialog();
            } else {
              setState(() => _selectedCategoryId = val);
            }
          },
        ),
      ],
    );
  }

  Widget _buildUnitDropdown({
    required bool isDark,
    required Color inputFill,
    required Color inputBorderColor,
    required Color textColor,
  }) {
    final isSelectedValid = _selectedUnitId != null &&
        _availableUnits.any((u) => u.id == _selectedUnitId);
    final validSelectedValue = isSelectedValid ? _selectedUnitId : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Satuan Produk",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white70 : const Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 5),
        DropdownButtonFormField<String?>(
          key: ValueKey("unit_dd_${validSelectedValue ?? 'none'}_${_availableUnits.length}"),
          initialValue: validSelectedValue,
          isExpanded: true,
          dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          style: GoogleFonts.plusJakartaSans(color: textColor, fontWeight: FontWeight.w600, fontSize: 13),
          decoration: InputDecoration(
            hintText: "Pilih Satuan",
            hintStyle: GoogleFonts.openSans(fontSize: 12, color: Colors.grey.shade400),
            prefixIcon: const Icon(Icons.straighten_rounded, size: 16, color: Color(0xFFD97706)),
            prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            suffixIcon: IconButton(
              onPressed: _addNewUnit,
              icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFFD97706), size: 18),
              tooltip: "Tambah Satuan Baru",
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
            isDense: true,
            filled: true,
            fillColor: inputFill,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: inputBorderColor)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: inputBorderColor)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _primaryColor, width: 1.5)),
          ),
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Text(
                "Tanpa Satuan",
                style: GoogleFonts.plusJakartaSans(fontSize: 13, color: textColor),
              ),
            ),
            ..._availableUnits.map((u) {
              return DropdownMenuItem<String?>(
                value: u.id,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        u.name,
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, color: textColor),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD97706).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        u.code,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFD97706),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            DropdownMenuItem<String?>(
              value: "NEW_UNIT",
              child: Row(
                children: [
                  const Icon(Icons.add, color: Color(0xFFD97706), size: 16),
                  const SizedBox(width: 6),
                  Text(
                    "Buat Satuan Baru",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFD97706),
                    ),
                  ),
                ],
              ),
            ),
          ],
          onChanged: (val) {
            if (val == "NEW_UNIT") {
              _addNewUnit();
            } else {
              setState(() => _selectedUnitId = val);
            }
          },
        ),
      ],
    );
  }

  Widget _buildSupplierDropdown({
    required bool isDark,
    required Color inputFill,
    required Color inputBorderColor,
    required Color textColor,
  }) {
    final isSelectedValid = _selectedSupplierId != null &&
        _availableSuppliers.any((s) => s.id == _selectedSupplierId);
    final validSelectedValue = isSelectedValid ? _selectedSupplierId : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Supplier Pemasok",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white70 : const Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 5),
        DropdownButtonFormField<String?>(
          key: ValueKey("sup_dd_${validSelectedValue ?? 'none'}_${_availableSuppliers.length}"),
          initialValue: validSelectedValue,
          isExpanded: true,
          dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          style: GoogleFonts.plusJakartaSans(color: textColor, fontWeight: FontWeight.w600, fontSize: 13),
          decoration: InputDecoration(
            hintText: "Pilih Supplier Pemasok",
            hintStyle: GoogleFonts.openSans(fontSize: 12, color: Colors.grey.shade400),
            prefixIcon: const Icon(Icons.local_shipping_outlined, size: 16, color: Color(0xFF0D9488)),
            prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            suffixIcon: IconButton(
              onPressed: _addNewSupplier,
              icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF0D9488), size: 18),
              tooltip: "Tambah Supplier Baru",
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
            isDense: true,
            filled: true,
            fillColor: inputFill,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: inputBorderColor)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: inputBorderColor)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _primaryColor, width: 1.5)),
          ),
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Text(
                "Tanpa Supplier",
                style: GoogleFonts.plusJakartaSans(fontSize: 13, color: textColor),
              ),
            ),
            ..._availableSuppliers.map((sup) {
              return DropdownMenuItem<String?>(
                value: sup.id,
                child: Text(
                  sup.name,
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, color: textColor),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }),
            DropdownMenuItem<String?>(
              value: "NEW_SUPPLIER",
              child: Row(
                children: [
                  const Icon(Icons.add, color: Color(0xFF0D9488), size: 16),
                  const SizedBox(width: 6),
                  Text(
                    "Buat Supplier Baru",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0D9488),
                    ),
                  ),
                ],
              ),
            ),
          ],
          onChanged: (val) {
            if (val == "NEW_SUPPLIER") {
              _addNewSupplier();
            } else {
              setState(() => _selectedSupplierId = val);
            }
          },
        ),
      ],
    );
  }

  Widget _buildOptionItem(
    Map<String, dynamic> opt,
    int idx,
    Color textColor,
    bool isDark,
  ) {
    final values = List<Map<String, dynamic>>.from(
      opt['product_option_values'] ?? [],
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: opt['option_name'],
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                  decoration: InputDecoration(
                    hintText: "Nama Grup Opsi (Contoh: Level Pedas)",
                    isDense: true,
                    border: InputBorder.none,
                    hintStyle: GoogleFonts.openSans(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  onChanged: (val) => opt['option_name'] = val,
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red,
                  size: 18,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                onPressed: () => _removeOption(idx),
              ),
            ],
          ),
          Divider(height: 1, color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                "Wajib dipilih oleh pelanggan?",
                style: GoogleFonts.openSans(fontSize: 11.5, color: Colors.grey),
              ),
              const Spacer(),
              Switch(
                value: opt['is_required'] ?? false,
                onChanged: (val) => setState(() => opt['is_required'] = val),
                activeThumbColor: _primaryColor,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            "Pilihan Opsi & Tambahan Harga:",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white70 : const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 6),
          ...List.generate(values.length, (valIdx) {
            final val = values[valIdx];
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      initialValue: val['value_name'],
                      style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w600, color: textColor),
                      decoration: InputDecoration(
                        hintText: "Nama Opsi",
                        hintStyle: GoogleFonts.openSans(fontSize: 11.5, color: Colors.grey),
                        isDense: true,
                        filled: true,
                        fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFCBD5E1)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFCBD5E1)),
                        ),
                      ),
                      onChanged: (v) => val['value_name'] = v,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      initialValue: (val['price_adjustment'] ?? 0).toString(),
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w600, color: textColor),
                      decoration: InputDecoration(
                        hintText: "Harga +/-",
                        hintStyle: GoogleFonts.openSans(fontSize: 11.5, color: Colors.grey),
                        prefixText: "Rp ",
                        prefixStyle: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700, color: _primaryColor),
                        isDense: true,
                        filled: true,
                        fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFCBD5E1)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFCBD5E1)),
                        ),
                      ),
                      onChanged: (v) =>
                          val['price_adjustment'] = double.tryParse(v) ?? 0.0,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.remove_circle_outline,
                      color: Colors.grey,
                      size: 16,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    onPressed: () => _removeValue(idx, valIdx),
                  ),
                ],
              ),
            );
          }),
          TextButton.icon(
            onPressed: () => _addValue(idx),
            icon: const Icon(Icons.add, size: 15),
            label: const Text("Tambah Pilihan", style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
            style: TextButton.styleFrom(
              foregroundColor: _primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWholesalePricingSection(Color inputFill, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Harga otomatis berubah sesuai kuantitas pembelian di kasir.",
          style: GoogleFonts.openSans(
            fontSize: 11.5,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 10),
        ...List.generate(_wholesalePrices.length, (index) {
          final tier = _wholesalePrices[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildSimpleInput(
                    "Min. Qty",
                    tier['minQty']?.toString() ?? '',
                    (val) => setState(() => tier['minQty'] = int.tryParse(val) ?? 0),
                    isNumber: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: _buildSimpleInput(
                    "Harga Satuan",
                    tier['price']?.toString() ?? '',
                    (val) => setState(() => tier['price'] = double.tryParse(val) ?? 0.0),
                    isNumber: true,
                    isPrice: true,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: () => setState(() => _wholesalePrices.removeAt(index)),
                ),
              ],
            ),
          );
        }),
        TextButton.icon(
          onPressed: () => setState(() => _wholesalePrices.add({'minQty': 0, 'price': 0.0})),
          icon: const Icon(Icons.add_rounded, size: 16),
          label: const Text("Tambah Jenjang Grosir", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF0284C7),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleInput(String label, String initialValue, Function(String) onChanged, {bool isNumber = false, bool isPrice = false}) {
    return TextFormField(
      initialValue: initialValue,
      onChanged: onChanged,
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.plusJakartaSans(fontSize: 11),
        prefixText: isPrice ? 'Rp ' : null,
        prefixStyle: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: _primaryColor),
        isDense: true,
        filled: true,
        fillColor: Theme.of(context).cardColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
    );
  }
}

