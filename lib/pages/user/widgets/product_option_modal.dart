import 'package:flutter/material.dart';
import '../../../services/app_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' as drift;
import '../../../core/app_theme.dart';

class ProductOptionModal extends StatefulWidget {
  final Product product;

  const ProductOptionModal({super.key, required this.product});

  @override
  State<ProductOptionModal> createState() => _ProductOptionModalState();
}

class _ProductOptionModalState extends State<ProductOptionModal> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _options = [];
  final Map<String, String> _selectedValues = {}; // OptionID -> ValueID
  final _notesController = TextEditingController();
  Unit? _unit;
  Stream<Product>? _productStream;

  final _currencyFormat = NumberFormat.currency(
    locale: 'id',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to access context for provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchOptions();
      _initStreams();
    });
  }

  void _initStreams() {
    final db = context.read<AppDatabase>();
    _productStream = (db.select(db.products)..where((t) => t.id.equals(widget.product.id))).watchSingle();
    
    if (widget.product.unitId != null) {
      (db.select(db.units)..where((t) => t.id.equals(widget.product.unitId!))).getSingleOrNull().then((u) {
        if (mounted) setState(() => _unit = u);
      });
    }
  }

  Future<void> _fetchOptions() async {
    if (!mounted) return;

    try {
      final db = context.read<AppDatabase>();

      final optionsResults =
          await (db.select(db.productOptions)
                ..where((t) => t.productId.equals(widget.product.id))
                ..orderBy([(t) => drift.OrderingTerm.asc(t.optionName)]))
              .get();

      List<Map<String, dynamic>> finalOptions = [];

      for (var opt in optionsResults) {
        final values = await (db.select(
          db.productOptionValues,
        )..where((t) => t.optionId.equals(opt.id))).get();

        final optMap = opt.toJson();
        optMap['product_option_values'] = values
            .map((v) => v.toJson())
            .toList();
        finalOptions.add(optMap);
      }

      if (mounted) {
        setState(() {
          _options = finalOptions;
          // Set defaults for required options if possible
          for (var opt in _options) {
            final values = List<Map<String, dynamic>>.from(
              opt['product_option_values'] ?? [],
            );
            if (opt['isRequired'] == true && values.isNotEmpty) {
              _selectedValues[opt['id']] = values[0]['id'];
            }
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching product options: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double _calculateTotalPrice() {
    double total = widget.product.salePrice ?? 0;

    for (var entry in _selectedValues.entries) {
      final optId = entry.key;
      final valId = entry.value;

      final opt = _options.firstWhere((o) => o['id'] == optId);
      final vals = List<Map<String, dynamic>>.from(
        opt['product_option_values'] ?? [],
      );
      final val = vals.firstWhere((v) => v['id'] == valId);

      total += (val['priceAdjustment'] as num?)?.toDouble() ?? 0.0;
    }

    return total;
  }

  double _calculateStockConsumption() {
    double multiplier = 1.0;
    
    for (var entry in _selectedValues.entries) {
      final optId = entry.key;
      final valId = entry.value;

      final opt = _options.firstWhere((o) => o['id'] == optId);
      final vals = List<Map<String, dynamic>>.from(
        opt['product_option_values'] ?? [],
      );
      final val = vals.firstWhere((v) => v['id'] == valId);

      final sm = val['stockMultiplier'];
      if (sm != null) {
        multiplier *= (sm as num).toDouble();
      }
    }
    
    return multiplier;
  }

  void _confirmSelection() {
    // Validate required options
    for (var opt in _options) {
      if (opt['isRequired'] == true &&
          !_selectedValues.containsKey(opt['id'])) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${opt['optionName'] ?? 'Opsi'} wajib dipilih!"),
          ),
        );
        return;
      }
    }

    // Build selection data
    List<Map<String, dynamic>> choices = [];
    for (var entry in _selectedValues.entries) {
      final opt = _options.firstWhere((o) => o['id'] == entry.key);
      final val = List<Map<String, dynamic>>.from(
        opt['product_option_values'] ?? [],
      ).firstWhere((v) => v['id'] == entry.value);

      choices.add({
        'option_id': opt['id'],
        'option_name': opt['optionName'],
        'value_id': val['id'],
        'value_name': val['valueName'],
        'price_adjustment': val['priceAdjustment'],
        'stock_multiplier': val['stockMultiplier'],
      });
    }

    Navigator.pop(context, {
      'choices': choices,
      'total_price': _calculateTotalPrice(),
      'notes': _notesController.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const primaryColor = AppTheme.primaryColor;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Drag Handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: StreamBuilder<Product>(
                stream: _productStream,
                initialData: widget.product,
                builder: (context, snapshot) {
                  final p = snapshot.data ?? widget.product;
                  final currentStock = p.stockQuantity ?? 0.0;
                  final remainingPriceLabel = _currencyFormat.format(widget.product.salePrice ?? 0);
                  
                  return Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.name ?? "Unknown Product",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  remainingPriceLabel,
                                  style: GoogleFonts.openSans(
                                    color: primaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (p.isStockManaged) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: primaryColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      "Stok: ${NumberFormat.decimalPattern('id').format(currentStock)} ${_unit?.code ?? ''}",
                                      style: GoogleFonts.openSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: primaryColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  );
                }
              ),
            ),
            const Divider(),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        ..._options.map(
                          (opt) => _buildOptionSection(opt, isDark),
                        ),

                        const SizedBox(height: 16),
                        Text(
                          "Catatan Khusus",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _notesController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            hintText:
                                "Contoh: Jangan pakai bawang, pedas banget...",
                            hintStyle: GoogleFonts.openSans(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                            filled: true,
                            fillColor: isDark
                                ? Colors.grey[800]
                                : Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
            ),

            // Footer
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
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        StreamBuilder<Product>(
                          stream: _productStream,
                          initialData: widget.product,
                          builder: (context, snapshot) {
                            final p = snapshot.data ?? widget.product;
                            if (!p.isStockManaged) {
                              return Text(
                                "Total Harga",
                                style: GoogleFonts.openSans(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              );
                            }
                            final currentStock = p.stockQuantity ?? 0.0;
                            final consumption = _calculateStockConsumption();
                            final remaining = currentStock - consumption;
                            
                            return Row(
                              children: [
                                Text(
                                  "Sisa Stok: ",
                                  style: GoogleFonts.openSans(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  "${NumberFormat.decimalPattern('id').format(remaining)} ${_unit?.code ?? ''}",
                                  style: GoogleFonts.openSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: remaining < 0 ? Colors.red : Colors.green[700],
                                  ),
                                ),
                              ],
                            );
                          }
                        ),
                        Text(
                          _currencyFormat.format(_calculateTotalPrice()),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 50,
                    width: 160,
                    child: ElevatedButton(
                      onPressed: _confirmSelection,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        "Tambah ke Cart",
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
          ],
        ),
      ),
    );
  }

  Widget _buildOptionSection(Map<String, dynamic> opt, bool isDark) {
    const primaryColor = AppTheme.primaryColor;
    final values = List<Map<String, dynamic>>.from(
      opt['product_option_values'] ?? [],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              opt['optionName'] ?? "Opsi",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (opt['isRequired'] == true) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryDark.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  "WAJIB",
                  style: GoogleFonts.openSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryDark,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: values.map((val) {
            final isSelected = _selectedValues[opt['id']] == val['id'];
            final adj = (val['priceAdjustment'] as num?)?.toDouble() ?? 0.0;

            return ChoiceChip(
              label: Text(
                adj != 0
                    ? "${val['valueName'] ?? ''} (${adj > 0 ? '+' : ''}${_currencyFormat.format(adj)})"
                    : (val['valueName'] ?? ''),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedValues[opt['id']] = val['id'];
                  } else if (opt['isRequired'] != true) {
                    _selectedValues.remove(opt['id']);
                  }
                });
              },
              backgroundColor: isDark ? Colors.grey[800] : Colors.white,
              selectedColor: primaryColor.withValues(alpha: 0.1),
              labelStyle: GoogleFonts.openSans(
                fontSize: 13,
                color: isSelected
                    ? primaryColor
                    : (isDark ? Colors.white : Colors.black87),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected
                      ? primaryColor
                      : Colors.grey.withValues(alpha: 0.2),
                ),
              ),
              showCheckmark: false,
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

