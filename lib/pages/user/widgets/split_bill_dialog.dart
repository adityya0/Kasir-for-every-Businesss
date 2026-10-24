import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/app_theme.dart';
import '../../../services/app_database.dart';
import 'package:intl/intl.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SPLIT ITEM DIALOG — pisah keranjang menjadi 2 bill terpisah
// ─────────────────────────────────────────────────────────────────────────────
class SplitItemDialog extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final Function(
    List<Map<String, dynamic>> bill1,
    List<Map<String, dynamic>> bill2,
  ) onSplitItems;

  const SplitItemDialog({
    super.key,
    required this.cartItems,
    required this.onSplitItems,
  });

  @override
  State<SplitItemDialog> createState() => _SplitItemDialogState();
}

class _SplitItemDialogState extends State<SplitItemDialog> {
  final _fmt = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

  late List<Map<String, dynamic>> _bill1;
  late List<Map<String, dynamic>> _bill2;

  @override
  void initState() {
    super.initState();
    // Deep copy each item to avoid mutating the original list
    _bill1 = widget.cartItems
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    _bill2 = [];
  }

  double _totalOf(List<Map<String, dynamic>> items) =>
      items.fold(0.0, (s, i) => s + (i['price'] as double) * (i['quantity'] as int));

  /// Move ONE unit of item at [index] from [src] to [dst]
  void _moveOne(List<Map<String, dynamic>> src, List<Map<String, dynamic>> dst, int index) {
    setState(() {
      final srcItem = src[index];
      final cartId = srcItem['cart_id'] as String;

      // Decrement source
      if ((srcItem['quantity'] as int) > 1) {
        srcItem['quantity'] = (srcItem['quantity'] as int) - 1;
      } else {
        src.removeAt(index);
      }

      // Increment or add to destination
      final dstIdx = dst.indexWhere((i) => i['cart_id'] == cartId);
      if (dstIdx != -1) {
        dst[dstIdx]['quantity'] = (dst[dstIdx]['quantity'] as int) + 1;
      } else {
        final newEntry = Map<String, dynamic>.from(srcItem.isNotEmpty ? srcItem : widget.cartItems.firstWhere((i) => i['cart_id'] == cartId));
        newEntry['quantity'] = 1;
        dst.add(newEntry);
      }
    });
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canConfirm = _bill1.isNotEmpty && _bill2.isNotEmpty;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Pisah Item",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        "Tap ➜ pindahkan item ke Bill Baru",
                        style: GoogleFonts.openSans(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: isDark ? Colors.white54 : Colors.black38),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Two columns
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildColumn("Bill Saat Ini", _bill1, true, isDark)),
                    const SizedBox(width: 12),
                    const VerticalDivider(thickness: 1),
                    const SizedBox(width: 12),
                    Expanded(child: _buildColumn("Bill Baru", _bill2, false, isDark)),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey[400]!),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text("Batal", style: GoogleFonts.plusJakartaSans(color: Colors.grey)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: canConfirm
                          ? () {
                              widget.onSplitItems(_bill1, _bill2);
                              Navigator.pop(context);
                            }
                          : null,
                      icon: const Icon(Icons.call_split_rounded, size: 18),
                      label: Text(
                        "Pisahkan Menjadi 2 Bill",
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey[200],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColumn(
    String title,
    List<Map<String, dynamic>> items,
    bool isBill1,
    bool isDark,
  ) {
    final src = isBill1 ? _bill1 : _bill2;
    final dst = isBill1 ? _bill2 : _bill1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Column header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isBill1
                ? AppTheme.primaryColor.withValues(alpha: 0.08)
                : Colors.blue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isBill1 ? AppTheme.primaryColor : Colors.blue,
                ),
              ),
              Text(
                _fmt.format(_totalOf(items)),
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isBill1 ? AppTheme.primaryColor : Colors.blue,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Item list
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_cart_outlined, size: 40, color: Colors.grey[300]),
                      const SizedBox(height: 8),
                      Text("Belum ada item",
                          style: GoogleFonts.openSans(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final item = items[i];
                    final Product p = item['product'];
                    final qty = item['quantity'] as int;
                    final price = item['price'] as double;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? Colors.white10 : Colors.grey[200]!,
                        ),
                      ),
                      child: ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        title: Text(
                          p.name ?? 'Item',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          "${qty}x • ${_fmt.format(price)}",
                          style: GoogleFonts.openSans(fontSize: 11, color: Colors.grey),
                        ),
                        trailing: GestureDetector(
                          onTap: () => _moveOne(src, dst, i),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isBill1
                                  ? AppTheme.primaryColor.withValues(alpha: 0.1)
                                  : Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              isBill1
                                  ? Icons.arrow_forward_rounded
                                  : Icons.arrow_back_rounded,
                              size: 16,
                              color: isBill1 ? AppTheme.primaryColor : Colors.blue,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SPLIT PAYMENT SHEET — bayar satu tagihan dari 2 metode pembayaran berbeda
// ─────────────────────────────────────────────────────────────────────────────
class SplitPaymentSheet extends StatefulWidget {
  final double total;
  final List<PaymentMethod> customMethods;
  final Function(List<Map<String, dynamic>> payments) onConfirm;

  const SplitPaymentSheet({
    super.key,
    required this.total,
    required this.customMethods,
    required this.onConfirm,
  });

  @override
  State<SplitPaymentSheet> createState() => _SplitPaymentSheetState();
}

class _SplitPaymentSheetState extends State<SplitPaymentSheet> {
  final _fmt = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

  // Each payment entry: { 'method': String, 'amount': double, 'controller': TextEditingController }
  late List<Map<String, dynamic>> _payments;

  @override
  void initState() {
    super.initState();
    // Start with 2 default slots: Tunai + QRIS (or first custom method)
    final half = (widget.total / 2).roundToDouble();
    final secondHalf = widget.total - half;
    final defaultMethod2 = widget.customMethods.isNotEmpty
        ? widget.customMethods.first.name
        : 'QRIS';

    _payments = [
      {
        'method': 'Tunai',
        'amount': half,
        'controller': TextEditingController(text: half.toInt().toString()),
      },
      {
        'method': defaultMethod2,
        'amount': secondHalf,
        'controller': TextEditingController(text: secondHalf.toInt().toString()),
      },
    ];
  }

  @override
  void dispose() {
    for (final p in _payments) {
      (p['controller'] as TextEditingController).dispose();
    }
    super.dispose();
  }

  double get _totalPaid =>
      _payments.fold(0.0, (s, p) => s + (p['amount'] as double));
  double get _remaining => widget.total - _totalPaid;
  bool get _isBalanced => _remaining.abs() < 0.5; // < 50 sen tolerance

  void _updateAmount(int index, String raw) {
    setState(() {
      _payments[index]['amount'] = double.tryParse(raw) ?? 0.0;
    });
  }

  void _addSlot() {
    if (_payments.length >= 4) return; // max 4 slots
    setState(() {
      _payments.add({
        'method': 'Tunai',
        'amount': 0.0,
        'controller': TextEditingController(text: '0'),
      });
    });
  }

  void _removeSlot(int index) {
    if (_payments.length <= 2) return;
    ((_payments[index]['controller']) as TextEditingController).dispose();
    setState(() => _payments.removeAt(index));
  }

  List<String> get _availableMethods {
    final result = ['Tunai'];
    for (final m in widget.customMethods) {
      result.add(m.name);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final methods = _availableMethods;
    final maxSheetHeight = MediaQuery.of(context).size.height * 0.85;

    return Container(
      constraints: BoxConstraints(
        maxHeight: maxSheetHeight,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 24,
        left: 24,
        right: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Split Payment",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    "Bayar dengan beberapa metode",
                    style: GoogleFonts.openSans(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "Total: ${_fmt.format(widget.total)}",
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Scrollable area for slots & status indicator
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Payment slots
                  ...List.generate(_payments.length, (i) {
                    final p = _payments[i];
                    return _buildPaymentSlot(i, p, methods, isDark);
                  }),

                  // Add slot button
                  if (_payments.length < 4)
                    GestureDetector(
                      onTap: _addSlot,
                      child: Container(
                        margin: const EdgeInsets.only(top: 8, bottom: 16),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppTheme.primaryColor.withValues(alpha: 0.4),
                            style: BorderStyle.solid,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_circle_outline, size: 16, color: AppTheme.primaryColor),
                            const SizedBox(width: 8),
                            Text(
                              "Tambah Metode Lain",
                              style: GoogleFonts.plusJakartaSans(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Balance indicator
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _isBalanced
                          ? Colors.green.withValues(alpha: 0.08)
                          : _remaining < 0
                              ? Colors.orange.withValues(alpha: 0.08)
                              : Colors.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isBalanced ? Colors.green : _remaining < 0 ? Colors.orange : Colors.red,
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _isBalanced
                              ? "✓ Pembayaran Sesuai"
                              : _remaining < 0
                                  ? "⚠ Kelebihan Bayar"
                                  : "Sisa yang belum terbayar",
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: _isBalanced ? Colors.green : _remaining < 0 ? Colors.orange : Colors.red,
                          ),
                        ),
                        if (!_isBalanced)
                          Text(
                            _fmt.format(_remaining.abs()),
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: _remaining < 0 ? Colors.orange : Colors.red,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Confirm button fixed at bottom
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isBalanced
                  ? () {
                      final result = _payments
                          .map((p) => {
                                'method': p['method'] as String,
                                'amount': p['amount'] as double,
                              })
                          .toList();
                      widget.onConfirm(result);
                      Navigator.pop(context);
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[200],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: Text(
                "Konfirmasi Pembayaran",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSlot(
    int index,
    Map<String, dynamic> payment,
    List<String> methods,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey[50],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Pembayaran ${index + 1}",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white54 : Colors.grey,
                ),
              ),
              if (_payments.length > 2)
                GestureDetector(
                  onTap: () => _removeSlot(index),
                  child: Icon(Icons.remove_circle_outline, size: 18, color: Colors.red[300]),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Method selector
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isDark ? Colors.white24 : Colors.grey[300]!),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: payment['method'] as String,
                      dropdownColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      items: methods
                          .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => payment['method'] = val);
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Amount input
              Expanded(
                flex: 3,
                child: TextField(
                  controller: payment['controller'] as TextEditingController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    prefixText: "Rp ",
                    prefixStyle: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white54 : Colors.grey,
                    ),
                    isDense: true,
                    filled: true,
                    fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  onChanged: (val) => _updateAmount(index, val),
                ),
              ),
            ],
          ),
          // Quick fill button
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              final remaining = widget.total - _payments
                  .asMap()
                  .entries
                  .where((e) => e.key != index)
                  .fold(0.0, (s, e) => s + (e.value['amount'] as double));
              final fill = remaining.clamp(0.0, widget.total);
              setState(() {
                payment['amount'] = fill;
                (payment['controller'] as TextEditingController).text = fill.toInt().toString();
              });
            },
            child: Text(
              "Isi sisa: ${_fmt.format((widget.total - _payments.asMap().entries.where((e) => e.key != index).fold(0.0, (s, e) => s + (e.value['amount'] as double))).clamp(0, widget.total))}",
              style: GoogleFonts.openSans(
                fontSize: 11,
                color: AppTheme.primaryColor,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
