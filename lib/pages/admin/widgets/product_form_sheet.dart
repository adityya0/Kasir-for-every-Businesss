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
import '../../../controllers/settings_controller.dart';

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
  final _maxStockController = TextEditingController();

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

  // Variant & Options Logic
  bool _enableVariants = false;
  List<Map<String, dynamic>> _productOptions = [];

  final Color _primaryColor = const Color(0xFFC0392B);
  
  // Wholesale Pricing
  List<Map<String, dynamic>> _wholesalePrices = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
    if (widget.product != null) {
      _nameController.text = widget.product!.name ?? '';
      _skuController.text = widget.product!.sku ?? '';
      _descriptionController.text = widget.product!.description ?? '';
      _buyPriceController.text = (widget.product!.buyPrice ?? widget.product!.basePrice ?? 0).toString();
      _salePriceController.text = (widget.product!.salePrice ?? 0).toString();
      _stockController.text = (widget.product!.stockQuantity ?? 0).toString();

      _isStockManaged = widget.product!.isStockManaged;
      _currentImageUrl = widget.product!.imageUrl;
      _selectedCategoryId = widget.product!.categoryId;
      
      // Parse Wholesale Prices
      if (widget.product!.wholesalePricesJson != null) {
        try {
          final List decoded = jsonDecode(widget.product!.wholesalePricesJson!);
          _wholesalePrices = decoded.cast<Map<String, dynamic>>();
        } catch (_) {}
      }
      
      _fetchOptions();
    }
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
          unitId: drift.Value(widget.product?.unitId),
          imageUrl: drift.Value(imageUrl),
          wholesalePricesJson: drift.Value(_wholesalePrices.isNotEmpty 
            ? jsonEncode(_wholesalePrices) 
            : null),
          isAvailable: const drift.Value(true),
          lastUpdated: drift.Value(DateTime.now()),
        );

        await db.into(db.products).insertOnConflictUpdate(companion);

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
    final headingColor = isDark ? Colors.white : const Color(0xFF2D3436);
    final inputFill = isDark ? Colors.grey.shade800 : const Color(0xFFF1F2F6);
    final textColor = isDark ? Colors.white70 : Colors.black87;

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
        height: MediaQuery.of(context).size.height * 0.9, // Taller sheet
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
      child: Column(
        children: [
          // Handle Bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
            child: Row(
              children: [
                Text(
                  widget.product == null ? "Tambah Produk" : "Edit Produk",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: headingColor,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),

          const Divider(),

          // Form Scrollable
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
                children: [
                  // Image Picker
                  Center(
                    child: GestureDetector(
                      onTap: _showImageSourceDialog,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: inputFill,
                          borderRadius: BorderRadius.circular(20),
                          image: _imageFile != null
                              ? DecorationImage(
                                  // For Web compatibility, use NetworkImage with blob URL?
                                  // Or just rely on kIsWeb check?
                                  // Actually FileImage(File(path)) doesn't work on Web.
                                  // But XFile.path on Web is a Blob URL.
                                  // So NetworkImage(path) works for XFile on Web!
                                  // But on mobile/desktop, FileImage(File(path)) is needed.
                                  // A simple cross-platform way is `Image.memory` if we read bytes,
                                  // but that's async.
                                  // Let's use `NetworkImage` if path starts with `blob:`, else `FileImage`.
                                  image: FileManager().getImageProvider(
                                    _imageFile!.path,
                                  ),
                                  fit: BoxFit.cover,
                                )
                              : (_currentImageUrl != null
                                    ? DecorationImage(
                                        image: FileManager().getImageProvider(
                                          _currentImageUrl!,
                                        ),
                                        fit: BoxFit.cover,
                                      )
                                    : null),
                          border: Border.all(
                            color: Colors.grey.withValues(alpha: 0.3),
                          ),
                        ),
                        child: (_imageFile == null && _currentImageUrl == null)
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_a_photo_rounded,
                                    size: 30,
                                    color: Colors.grey[500],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Foto Produk",
                                    style: GoogleFonts.openSans(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildInput(
                    "Nama Produk",
                    _nameController,
                    Icons.fastfood_rounded,
                    inputFill,
                    textColor,
                  ),
                  const SizedBox(height: 16),

                  // SKU Row
                  _buildInput(
                    "SKU (Opsional)",
                    _skuController,
                    Icons.qr_code_rounded,
                    inputFill,
                    textColor,
                    isRequired: false,
                  ),
                  const SizedBox(height: 16),
                  
                  // Kategori
                  _buildCategoryDropdown(inputFill, textColor),
                  const SizedBox(height: 16),

                  _buildInput(
                    "Deskripsi",
                    _descriptionController,
                    Icons.description_rounded,
                    inputFill,
                    textColor,
                    maxLines: 3,
                    isRequired: false,
                  ),
                  const SizedBox(height: 16),

                  // Prices Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildInput(
                          "Harga Beli",
                          _buyPriceController,
                          Icons.shopping_bag_outlined,
                          inputFill,
                          textColor,
                          isNumber: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInput(
                          "Harga Jual",
                          _salePriceController,
                          Icons.attach_money_rounded,
                          inputFill,
                          textColor,
                          isNumber: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Variants & Options Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: inputFill,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.tune_rounded, color: _primaryColor),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Varian & Opsi",
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w600,
                                        color: textColor,
                                      ),
                                    ),
                                    Text(
                                      "Contoh: Level Pedas, Topping, dll.",
                                      style: GoogleFonts.openSans(
                                        fontSize: 12,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            Switch(
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
                          ],
                        ),
                        if (_enableVariants) ...[
                          const SizedBox(height: 16),
                          ...List.generate(_productOptions.length, (optIdx) {
                            final opt = _productOptions[optIdx];
                            return _buildOptionItem(
                              opt,
                              optIdx,
                              textColor,
                              isDark,
                            );
                          }),
                          const SizedBox(height: 10),
                          Center(
                            child: TextButton.icon(
                              onPressed: _addOption,
                              icon: const Icon(Icons.add_circle_outline),
                              label: const Text("Tambah Grup Opsi"),
                              style: TextButton.styleFrom(
                                foregroundColor: _primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Stock Management Switch
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: inputFill,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.inventory_2_rounded,
                                  color: _primaryColor,
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Kelola Stok",
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w600,
                                        color: textColor,
                                      ),
                                    ),
                                    Text(
                                      _isStockManaged
                                          ? "Stok Terbatas"
                                          : "Stok Unlimited",
                                      style: GoogleFonts.openSans(
                                        fontSize: 12,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Switch(
                              value: _isStockManaged,
                              activeThumbColor: _primaryColor,
                              onChanged: (val) {
                                setState(() => _isStockManaged = val);
                              },
                            ),
                          ],
                        ),
                        if (_isStockManaged) ...[
                          const SizedBox(height: 16),
                          _buildInput(
                            "Jumlah Stok Saat Ini",
                            _stockController,
                            Icons.numbers_rounded,
                            theme.cardColor, // Nested, so contrast slightly
                            textColor,
                            isNumber: true,
                          ),
                          const SizedBox(height: 12),
                          _buildInput(
                            "Stok Maksimum (Opsional)",
                            _maxStockController,
                            Icons.vertical_align_top_rounded,
                            theme.cardColor,
                            textColor,
                            isNumber: true,
                            isRequired: false,
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // Wholesale Pricing Section
                  if (SettingsController.instance.featureGrosirEnabled.value) ...[
                    const SizedBox(height: 16),
                    _buildWholesalePricingSection(inputFill, textColor),
                  ],

                  const SizedBox(height: 100), // Bottom padding
                ],
              ),
            ),
          ),

          // Submit Button (Fixed at Bottom)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        "Simpan Produk",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildCategoryDropdown(Color fillColor, Color textColor) {
    return DropdownButtonFormField<String>(
      key: ValueKey(_selectedCategoryId),
      initialValue: _selectedCategoryId,
      isExpanded: true, // Prevent text overflow
      dropdownColor: Theme.of(context).cardColor,
      style: GoogleFonts.openSans(color: textColor, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: "Kategori",
        labelStyle: GoogleFonts.openSans(color: Colors.grey[500]),
        prefixIcon: Icon(Icons.category_rounded, color: _primaryColor),
        // Shortcut button inside the dropdown
        suffixIcon: IconButton(
          onPressed: _showAddCategoryDialog,
          icon: Icon(Icons.add_circle_outline_rounded, color: _primaryColor),
          tooltip: "Tambah Kategori Baru",
        ),
        filled: true,
        fillColor: fillColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      items: [
        DropdownMenuItem<String>(
          value: null,
          child: Text(
            "Tanpa Kategori",
            style: GoogleFonts.openSans(fontSize: 14, color: textColor),
          ),
        ),
        ..._categories.map((cat) {
          return DropdownMenuItem<String>(
            value: cat.id,
            child: Text(
              cat.name ?? '',
              style: GoogleFonts.openSans(fontSize: 14, color: textColor),
              overflow: TextOverflow.ellipsis,
            ),
          );
        }),
        DropdownMenuItem<String>(
          value: "NEW_CATEGORY",
          child: Row(
            children: [
              const Icon(Icons.add, color: Color(0xFFC0392B), size: 18),
              const SizedBox(width: 8),
              Text(
                "Buat Baru",
                style: GoogleFonts.openSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFC0392B),
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
    );
  }


  Widget _buildInput(
    String label,
    TextEditingController controller,
    IconData icon,
    Color fillColor,
    Color textColor, {
    bool isNumber = false,
    bool isRequired = true,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      style: GoogleFonts.openSans(color: textColor, fontWeight: FontWeight.w500),
      validator: (val) {
        if (!isRequired) return null;
        if (val == null || val.isEmpty) return "$label wajib diisi";
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.openSans(color: Colors.grey[500]),
        prefixIcon: maxLines > 1
            ? Container(
                margin: const EdgeInsets.only(bottom: 40), // Align icon top
                child: Icon(icon, color: _primaryColor),
              )
            : Icon(icon, color: _primaryColor),
        filled: true,
        fillColor: fillColor,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: _primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.red[300]!, width: 1),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
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
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: opt['option_name'],
                  style: GoogleFonts.openSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                  decoration: InputDecoration(
                    hintText: "Nama Grup Opsi (Misal: Pilih Kematangan)",
                    isDense: true,
                    border: InputBorder.none,
                    hintStyle: GoogleFonts.openSans(
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                  ),
                  onChanged: (val) => opt['option_name'] = val,
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                  size: 20,
                ),
                onPressed: () => _removeOption(idx),
              ),
            ],
          ),
          const Divider(),
          Row(
            children: [
              Text(
                "Wajib dipilih?",
                style: GoogleFonts.openSans(fontSize: 12, color: Colors.grey[600]),
              ),
              const Spacer(),
              Switch(
                value: opt['is_required'] ?? false,
                onChanged: (val) => setState(() => opt['is_required'] = val),
                activeThumbColor: _primaryColor,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Pilihan Opsi:",
            style: GoogleFonts.openSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          ...List.generate(values.length, (valIdx) {
            final val = values[valIdx];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      initialValue: val['value_name'],
                      style: GoogleFonts.openSans(fontSize: 13, color: textColor),
                      decoration: InputDecoration(
                        hintText: "Nama Opsi",
                        isDense: true,
                        filled: true,
                        fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
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
                      style: GoogleFonts.openSans(fontSize: 13, color: textColor),
                      decoration: InputDecoration(
                        hintText: "Harga +/-",
                        isDense: true,
                        filled: true,
                        fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
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
                      size: 18,
                    ),
                    onPressed: () => _removeValue(idx, valIdx),
                  ),
                ],
              ),
            );
          }),
          TextButton.icon(
            onPressed: () => _addValue(idx),
            icon: const Icon(Icons.add, size: 16),
            label: const Text("Tambah Pilihan", style: TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(foregroundColor: _primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildWholesalePricingSection(Color inputFill, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: inputFill,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.layers_rounded, color: Colors.blue),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Harga Grosir / Berjenjang",
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  Text(
                    "Harga otomatis berubah sesuai kuantitas",
                    style: GoogleFonts.openSans(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(_wholesalePrices.length, (index) {
            final tier = _wholesalePrices[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
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
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: _buildSimpleInput(
                      "Harga",
                      tier['price']?.toString() ?? '',
                      (val) => setState(() => tier['price'] = double.tryParse(val) ?? 0.0),
                      isNumber: true,
                      isPrice: true,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                    onPressed: () => setState(() => _wholesalePrices.removeAt(index)),
                  ),
                ],
              ),
            );
          }),
          TextButton.icon(
            onPressed: () => setState(() => _wholesalePrices.add({'minQty': 0, 'price': 0.0})),
            icon: const Icon(Icons.add_road_rounded),
            label: const Text("Tambah Jenjang Harga"),
            style: TextButton.styleFrom(foregroundColor: Colors.blue),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleInput(String label, String initialValue, Function(String) onChanged, {bool isNumber = false, bool isPrice = false}) {
    return TextFormField(
      initialValue: initialValue,
      onChanged: onChanged,
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        prefixText: isPrice ? 'Rp ' : null,
        filled: true,
        fillColor: Theme.of(context).cardColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}

