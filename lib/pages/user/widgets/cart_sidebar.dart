import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../services/app_database.dart';
import '../../../widgets/order_numpad.dart';
import 'package:provider/provider.dart';
import '../../../controllers/admin_controller.dart';
import '../../../controllers/settings_controller.dart';
import '../../../services/platform/file_manager.dart';
import '../../../core/app_theme.dart';
import '../../../widgets/custom_toast.dart';
import 'split_bill_dialog.dart';

class CartSidebar extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final Map<String, dynamic>? discountData;
  final Function(String cartId) onRemoveItem;
  final Function(Product product, {List? options, String? notes, double? price})
  onAddItem;
  final Function(double cashReceived, String paymentMethod, {String? status, List<Map<String, dynamic>>? splitPayments, double? discount})
  onCheckout;
  final VoidCallback? onAbortTransaction;
  final Function(bool isPaymentMode)? onModeChanged;
  final bool isProcessing;
  final TextEditingController? searchController;
  final Function(String)? onSearchChanged;
  final Function(String)? onSearchSubmitted;
  final VoidCallback? onSearchClear;
  final bool isGridView;
  final VoidCallback? onToggleGrid;
  final Customer? selectedCustomer;
  final Function(Customer?)? onCustomerSelected;
  final String? lastModifiedCartId;
  final VoidCallback? onClose;
  final VoidCallback onHoldCart;
  // Called when user wants to split cart into 2 separate bills
  final Function(List<Map<String, dynamic>> bill1, List<Map<String, dynamic>> bill2)? onSplitItems;

  const CartSidebar({
    super.key,
    this.searchController,
    this.onSearchChanged,
    this.onSearchSubmitted,
    this.onSearchClear,
    required this.cartItems,
    required this.isProcessing,
    this.discountData,
    this.onModeChanged,
    required this.onRemoveItem,
    required this.onAddItem,
    required this.onCheckout,
    this.onAbortTransaction,
    this.isGridView = true,
    this.onToggleGrid,
    this.selectedCustomer,
    this.onCustomerSelected,
    this.lastModifiedCartId,
    this.onClose,
    required this.onHoldCart,
    this.onSplitItems,
  });

  @override
  State<CartSidebar> createState() => _CartSidebarState();
}

class _CartSidebarState extends State<CartSidebar> {
  final TextEditingController _cashController = TextEditingController();
  final FocusNode _cashFocusNode = FocusNode();
  double _cashReceived = 0;
  String _selectedPaymentMethod = "Tunai";
  bool _isPaymentMode = false; // Toggle between Cart Review and Payment
  int _selectedItemIndex = -1; // Added for Odoo selection
  OrderNumpadMode _numpadMode = OrderNumpadMode.qty;
  String _numpadBuffer = "";
  bool _isFirstInput =
      true; // Flag for flexible "overwrite on first digit" logic
  final ScrollController _scrollController = ScrollController();
  bool _isOrderSummaryExpanded = false; // Toggle for expanding order summary

  // Manual discount applied by cashier
  double _manualDiscount = 0;
  bool _manualDiscountIsPercent = false;
  String _manualDiscountLabel = "";

  // Split Payment — list of partial payments, null = not in split-payment mode
  List<Map<String, dynamic>>? _splitPayments;
  List<PaymentMethod> _cachedPaymentMethods = [];

  final _currencyFormat = NumberFormat.currency(
    locale: 'id',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    if (_isPaymentMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _cashFocusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _cashController.dispose();
    _cashFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleNumpadTap(String val) {
    // Strip dots (thousands separator in 'id' locale)
    String rawValue = _cashController.text.replaceAll('.', '');

    if (val == "C") {
      rawValue = "";
    } else if (val == "backspace") {
      if (rawValue.isNotEmpty) {
        rawValue = rawValue.substring(0, rawValue.length - 1);
      }
    } else if (val == "000") {
      if (rawValue.length < 10 && rawValue.isNotEmpty) {
        rawValue += "000";
      }
    } else if (val == ".") {
      // Decimal support if needed, though rare for IDR cash
      if (!rawValue.contains(".") &&
          rawValue.length < 11 &&
          rawValue.isNotEmpty) {
        rawValue += ".";
      }
    } else {
      if (rawValue.length < 12) {
        rawValue += val;
      }
    }

    if (rawValue.isEmpty) {
      _cashReceived = 0;
      _cashController.text = "0"; // Safer than empty string
    } else {
      _cashReceived = double.tryParse(rawValue) ?? 0;
      _cashController.text = NumberFormat.decimalPattern(
        'id',
      ).format(_cashReceived);
    }
    setState(() {});
  }

  void _handleOrderNumpadTap(String val) {
    if (_selectedItemIndex == -1 ||
        _selectedItemIndex >= widget.cartItems.length) {
      return;
    }

    if (val == "C") {
      _numpadBuffer = "";
      _isFirstInput = true;
    } else if (val == "000") {
      if (_isFirstInput) {
        _numpadBuffer = "0";
        _isFirstInput = false;
      } else {
        _numpadBuffer += "000";
      }
    } else if (val == ".") {
      if (_isFirstInput) {
        _numpadBuffer = "0.";
        _isFirstInput = false;
      } else if (!_numpadBuffer.contains(".")) {
        _numpadBuffer += ".";
      }
    } else {
      if (_isFirstInput) {
        _numpadBuffer = val;
        _isFirstInput = false;
      } else {
        _numpadBuffer += val;
      }
    }

    _applyNumpadValue();
  }

  void _handleOrderNumpadBackspace() {
    if (_selectedItemIndex == -1 ||
        _selectedItemIndex >= widget.cartItems.length) {
      return;
    }

    if (_numpadBuffer.isNotEmpty) {
      // Remove last digit from buffer as usual
      _numpadBuffer = _numpadBuffer.substring(0, _numpadBuffer.length - 1);
      if (_numpadBuffer.isEmpty) {
        _isFirstInput = true;
      }
      _applyNumpadValue();
    } else {
      // Buffer is empty - Determine behavior based on mode
      final item = widget.cartItems[_selectedItemIndex];

      if (_numpadMode == OrderNumpadMode.qty) {
        // User wants to "delete just one qty" - handle as decrement
        int currentQty = item['quantity'] as int;
        if (currentQty > 0) {
          final newQty = currentQty - 1;
          setState(() {
            item['quantity'] = newQty;
          });

          if (newQty == 0) {
            widget.onRemoveItem(item['cart_id']);
            setState(() {
              _selectedItemIndex = -1;
              _isFirstInput = true;
              _numpadBuffer = "";
            });
          }
        }
      } else {
        // For Price or Discount, keep the "erasing digit" behavior
        String currentValStr;
        if (_numpadMode == OrderNumpadMode.price) {
          currentValStr = (item['price'] as double).toInt().toString();
        } else {
          return;
        }

        if (currentValStr.length > 1) {
          _numpadBuffer = currentValStr.substring(0, currentValStr.length - 1);
          _isFirstInput = false;
          _applyNumpadValue();
          _numpadBuffer =
              ""; // Clear buffer so next click starts fresh from new state
        } else {
          _numpadBuffer = "0";
          _isFirstInput = true;
          _applyNumpadValue();
          _numpadBuffer = "";
        }
      }
    }
  }

  void _handleOrderNumpadToggleSign() {
    if (_numpadBuffer.startsWith("-")) {
      _numpadBuffer = _numpadBuffer.substring(1);
    } else if (_numpadBuffer.isNotEmpty) {
      _numpadBuffer = "-$_numpadBuffer";
    }
    _applyNumpadValue();
  }

  void _applyNumpadValue() {
    if (_selectedItemIndex == -1) {
      return;
    }

    final item = widget.cartItems[_selectedItemIndex];
    double val = double.tryParse(_numpadBuffer) ?? 0;

    if (_numpadMode == OrderNumpadMode.qty) {
      final int requestedQty = val.toInt().clamp(0, 999);
      int finalQty = requestedQty;

      // Stock Check
      final Product p = item['product'];
      if (p.isStockManaged) {
        // Total of THIS product already in cart, EXCLUDING the one currently selected
        final otherItemsQty = widget.cartItems
            .asMap()
            .entries
            .where(
              (entry) =>
                  entry.key != _selectedItemIndex &&
                  (entry.value['product'] as Product).id == p.id,
            )
            .fold(0, (sum, entry) => sum + (entry.value['quantity'] as int));

        final maxAllowedForThisItem = (p.stockQuantity ?? 0.0) - otherItemsQty;

        if (requestedQty > maxAllowedForThisItem) {
          finalQty = maxAllowedForThisItem.toInt().clamp(0, 999);
          _numpadBuffer = finalQty
              .toString(); // Update buffer to reflect reality

          CustomToast.show(
            context,
            "Stok tidak mencukupi! Maksimal tersedia ${p.stockQuantity} item.",
            isError: true,
          );
        }
      }

      setState(() {
        item['quantity'] = finalQty;
      });

      // Remove items with qty = 0
      if (finalQty == 0) {
        widget.onRemoveItem(item['cart_id']);
        setState(() {
          _selectedItemIndex = -1;
          _numpadBuffer = '';
          _isFirstInput = true;
        });
      }
    } else if (_numpadMode == OrderNumpadMode.disc) {
      // Handle discount if field exists
    } else if (_numpadMode == OrderNumpadMode.price) {
      setState(() {
        item['price'] = val;
      });
    }

    // If cart is now empty, close the sheet if it's a popable route
    if (widget.cartItems.isEmpty && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Only pop if we are in a modal context (like bottom sheet on mobile)
        if (mounted && Navigator.canPop(context)) Navigator.pop(context);
      });
    }
  }

  void _incrementQty(int index) {
    setState(() {
      final item = widget.cartItems[index];
      final Product p = item['product'];
      final currentQty = item['quantity'] as int;

      // Stock Check
      if (p.isStockManaged) {
        // Calculate total in cart for this specific product (in case there are different variants)
        final totalInCart = widget.cartItems
            .where((it) => (it['product'] as Product).id == p.id)
            .fold(0, (sum, it) => sum + (it['quantity'] as int));

        if (totalInCart >= (p.stockQuantity ?? 0)) {
          CustomToast.show(
            context,
            "Stok tidak mencukupi! Hanya tersedia ${p.stockQuantity} item.",
            isError: true,
          );
          return;
        }
      }

      item['quantity'] = (currentQty + 1).clamp(1, 999);
    });
  }

  void _decrementQty(int index) {
    final item = widget.cartItems[index];
    final currentQty = item['quantity'] as int;
    if (currentQty > 1) {
      setState(() {
        item['quantity'] = currentQty - 1;
      });
    } else {
      widget.onRemoveItem(item['cart_id']);
    }
  }

  int _getCartTotalCount() {
    return widget.cartItems.fold(
      0,
      (sum, item) => sum + (item['quantity'] as int),
    );
  }

  @override
  void didUpdateWidget(covariant CartSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Smart auto-selection: Follow the last addition or increment only if it changed
    if (widget.cartItems.isNotEmpty) {
      // ONLY trigger auto-select/scroll if the parent explicitly modified a NEW item
      bool idChanged =
          widget.lastModifiedCartId != null &&
          widget.lastModifiedCartId != oldWidget.lastModifiedCartId;

      if (idChanged) {
        int targetSelection = widget.cartItems.indexWhere(
          (it) => it['cart_id'] == widget.lastModifiedCartId,
        );

        if (targetSelection != -1 &&
            targetSelection < widget.cartItems.length) {
          _selectedItemIndex = targetSelection;
          _numpadBuffer = "";
          _isFirstInput = true;
        }
      } else if (_selectedItemIndex == -1) {
        // Fallback: if absolutely nothing is selected yet, pick the first one
        _selectedItemIndex = 0;
      }
    } else {
      _selectedItemIndex = -1;
    }

    // If cart is empty and we are still in payment mode, auto-reset to cart view
    if (widget.cartItems.isEmpty && _isPaymentMode) {
      // Use post-frame callback to avoid setState() during build error
      // when notifying parent about mode change
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _numpadBuffer = "";
          _isFirstInput = true;
          _selectedItemIndex = -1;
          _isPaymentMode = false;
          _cashReceived = 0;
          _cashController.clear();
          _manualDiscount = 0;
          _manualDiscountLabel = "";
        });
        // Ensure parent knows we are no longer in payment mode
        widget.onModeChanged?.call(false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const primaryColor = AppTheme.primaryColor;

    return ValueListenableBuilder<bool>(
      valueListenable: SettingsController.instance.pajakEnabled,
      builder: (context, pajakEnabled, _) {
        return ValueListenableBuilder<double>(
          valueListenable: SettingsController.instance.pajakRate,
          builder: (context, pajakRate, _) {
            return ValueListenableBuilder<String>(
              valueListenable: SettingsController.instance.pajakName,
              builder: (context, pajakName, _) {
                double subTotal = widget.cartItems.fold(
                  0,
                  (sum, item) =>
                      sum + ((item['price'] as double) * (item['quantity'] as int)),
                );
                double promoDiscount = widget.discountData?['total_discount'] ?? 0.0;
                // Manual discount: percentage of subTotal or fixed amount
                double manualDiscountAmount = _manualDiscountIsPercent
                    ? (subTotal * _manualDiscount / 100)
                    : _manualDiscount;
                double discount = promoDiscount + manualDiscountAmount;

                double subtotalAfterDiscount = (subTotal - discount).clamp(0.0, double.infinity);
                double pajakAmount = 0;
                if (pajakEnabled) {
                  pajakAmount = subtotalAfterDiscount * (pajakRate / 100);
                }
                
                double total = subtotalAfterDiscount + pajakAmount;
                if (total < 0) total = 0;

                double change = _cashReceived - total;

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final isDesktop =
                        constraints.maxWidth >= 600 ||
                        MediaQuery.of(context).size.width >= 720;
                    final isNarrow = constraints.maxWidth < 320;

                    return Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF8F9FA),
                        border: Border(
                          left: BorderSide(
                            color: isDark ? Colors.white10 : Colors.grey[200]!,
                          ),
                        ),
                      ),
                      child: SafeArea(
                        top: !isDesktop,
                        bottom: !isDesktop,
                        child: Column(
                          children: [
                            _buildHeader(isDark, primaryColor, isDesktop, isNarrow),
                            Expanded(
                              child: _isPaymentMode
                                  ? _buildPaymentView(
                                      isDark,
                                      primaryColor,
                                      subTotal,
                                      discount,
                                      total,
                                      change,
                                      isDesktop,
                                      isNarrow,
                                      pajakAmount: pajakAmount,
                                      pajakName: pajakName,
                                      promoDiscount: promoDiscount,
                                      manualDiscountAmount: manualDiscountAmount,
                                    )
                                  : _buildCartView(
                                      isDark,
                                      primaryColor,
                                      total,
                                      isDesktop,
                                      isNarrow,
                                      pajakAmount: pajakAmount,
                                      pajakName: pajakName,
                                      promoDiscount: promoDiscount,
                                      manualDiscountAmount: manualDiscountAmount,
                                    ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }
            );
          }
        );
      }
    );
  }

  Widget _buildHeader(
    bool isDark,
    Color primaryColor,
    bool isDesktop,
    bool isNarrow,
  ) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        isNarrow ? 12 : 24,
        isDesktop ? 24 : 48, // Added more padding over SafeArea to push it down from the bezel
        isNarrow ? 12 : 16,
        16,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                if (_isPaymentMode)
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: isDark ? Colors.white : const Color(0xFF2D3436),
                    ),
                    onPressed: () => setState(() {
                      _isPaymentMode = false;
                      _numpadBuffer = "";
                      _isFirstInput = true;
                    }),
                  ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    _isPaymentMode
                        ? "Pembayaran"
                        : (isDesktop ? "Detail Pesanan" : "Keranjang"),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: isNarrow ? 16 : (isDesktop ? 22 : 20),
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF2D3436),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isDesktop && !_isPaymentMode && widget.cartItems.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: IconButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            title: Text(
                              "Batalkan Transaksi?",
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            content: Text(
                              "Semua item dalam keranjang akan dihapus. Lanjutkan?",
                              style: GoogleFonts.openSans(),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: Text(
                                  "Tidak",
                                  style: GoogleFonts.openSans(color: Colors.grey),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  setState(() {
                                    _manualDiscount = 0;
                                    _manualDiscountLabel = "";
                                  });
                                    _isPaymentMode = false;
                                    widget.onModeChanged?.call(false);
                                  widget.onAbortTransaction?.call();
                                },
                                child: Text(
                                  "Ya, Batal",
                                  style: GoogleFonts.openSans(
                                    color: Colors.red,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.cancel_outlined,
                        color: Colors.grey,
                        size: 20,
                      ),
                      tooltip: "Batalkan Pesanan",
                    ),
                  ),
              ],
            ),
          ),
          Row(
            children: [
              if (!isDesktop && !_isPaymentMode && widget.cartItems.isNotEmpty)
                TextButton.icon(
                  onPressed: () {
                    widget.onAbortTransaction?.call();
                    Navigator.pop(context);
                  },
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                    size: 18,
                  ),
                  label: Text(
                    "Batal",
                    style: GoogleFonts.openSans(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else if (_isPaymentMode && widget.cartItems.isNotEmpty)
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.white10 : Colors.grey[200]!,
                    ),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.view_list,
                      color: isDark ? Colors.white : Colors.black87,
                      size: 22,
                    ),
                    onPressed: () {
                      setState(() => _isPaymentMode = false);
                      widget.onModeChanged?.call(false);
                      widget.onHoldCart();
                    },
                    tooltip: "Simpan Pesanan",
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                  ),
                )
              else if (widget.cartItems.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "${_getCartTotalCount()} Item",
                    style: GoogleFonts.plusJakartaSans(
                      color: primaryColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              if (widget.onClose != null) ...[
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                      width: 1,
                    ),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: isDark ? Colors.white70 : const Color(0xFF64748B),
                    ),
                    onPressed: widget.onClose,
                    tooltip: "Tutup Sidebar",
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCartView(
    bool isDark,
    Color primaryColor,
    double total,
    bool isDesktop,
    bool isNarrow, {
    required double pajakAmount,
    required String pajakName,
    required double promoDiscount,
    required double manualDiscountAmount,
  }) {
    if (widget.cartItems.isEmpty && !isDesktop) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: isDark ? Colors.white10 : Colors.grey[200],
            ),
            const SizedBox(height: 16),
            Text(
              "Keranjang kosong",
              style: GoogleFonts.openSans(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: widget.cartItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shopping_cart_outlined,
                        size: 80,
                        color: isDark ? Colors.white10 : Colors.grey[200],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Keranjang kosong",
                        style: GoogleFonts.openSans(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  controller: _scrollController,
                  padding: EdgeInsets.fromLTRB(
                    isNarrow ? 12 : 24,
                    16,
                    isNarrow ? 12 : 24,
                    24,
                  ),
                  physics: const BouncingScrollPhysics(),
                  itemCount: widget.cartItems.length,
                  separatorBuilder: (c, i) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final item = widget.cartItems[i];
                    final Product p = item['product'];
                    final qty = item['quantity'] as int;
                    final price = item['price'] as double;
                    final isSelected = _selectedItemIndex == i;

                    final appliedIds =
                        widget.discountData?['applied_cart_ids'] as List? ?? [];
                    final itemDiscounts =
                        widget.discountData?['item_discounts'] as Map? ?? {};
                    final isPromo = appliedIds.contains(item['cart_id']);
                    final itemDiscount =
                        itemDiscounts[item['cart_id']] as double? ?? 0.0;

                    return Dismissible(
                      key: Key(item['cart_id'].toString()),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 24),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(isDesktop || isNarrow ? 12 : 20),
                        ),
                        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
                      ),
                      onDismissed: (direction) {
                        widget.onRemoveItem(item['cart_id']);
                        if (_selectedItemIndex == i) {
                          setState(() {
                            _selectedItemIndex = -1;
                            _numpadBuffer = "";
                            _isFirstInput = true;
                          });
                        } else if (_selectedItemIndex > i) {
                          setState(() {
                            _selectedItemIndex--;
                          });
                        }
                      },
                      child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedItemIndex = i;
                          _numpadBuffer = "";
                          _isFirstInput = true;
                        });
                      },
                      borderRadius: BorderRadius.circular(isDesktop ? 12 : 20),
                      child: Container(
                        padding: EdgeInsets.all(
                          isNarrow ? 8 : (isDesktop ? 10 : 16),
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF2C2C2E)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(
                            isDesktop || isNarrow ? 12 : 20,
                          ),
                          border: Border.all(
                            color: isSelected
                                ? primaryColor
                                : Colors.transparent,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: 0.05,
                              ),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.name ?? "Unknown",
                                    style: GoogleFonts.openSans(
                                      fontWeight: FontWeight.w600,
                                      fontSize: isNarrow
                                          ? 13
                                          : (isDesktop ? 14 : 16),
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _currencyFormat.format(price),
                                    style: GoogleFonts.openSans(
                                      fontSize: 13,
                                      color: isSelected
                                          ? primaryColor
                                          : Colors.grey[600]!,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (isPromo)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withValues(
                                            alpha: 0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          itemDiscount > 0
                                              ? "PROMO -${_currencyFormat.format(itemDiscount)}"
                                              : "PROMO",
                                          style: GoogleFonts.openSans(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ),
                                    ),
                                  if (true) ...[
                                    // Qty Controls
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _buildQtyBtn(
                                          Icons.remove,
                                          () => _decrementQty(i),
                                          isDark,
                                          primaryColor,
                                        ),
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: isNarrow ? 8 : 12,
                                          ),
                                          child: Text(
                                            "$qty",
                                            style: GoogleFonts.openSans(
                                              fontWeight: FontWeight.w600,
                                              fontSize: isNarrow ? 14 : 16,
                                              color: isDark
                                                  ? Colors.white
                                                  : Colors.black87,
                                            ),
                                          ),
                                        ),
                                        _buildQtyBtn(
                                          Icons.add,
                                          () => _incrementQty(i),
                                          isDark,
                                          primaryColor,
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    _currencyFormat.format(price * qty),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w600,
                                      fontSize: isNarrow
                                          ? 13
                                          : (isDesktop ? 16 : 15),
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                IconButton(
                                  onPressed: () =>
                                      widget.onRemoveItem(item['cart_id']),
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: Colors.redAccent,
                                    size: 20,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
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
        ),
        _buildSummaryAndNumpad(isDark, primaryColor, total, isDesktop, pajakAmount: pajakAmount, pajakName: pajakName, promoDiscount: promoDiscount, manualDiscountAmount: manualDiscountAmount),
      ],
    );
  }

  Widget _buildQtyBtn(
    IconData icon,
    VoidCallback onTap,
    bool isDark,
    Color primaryColor,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: primaryColor),
      ),
    );
  }

  Widget _buildSummaryAndNumpad(
    bool isDark,
    Color primaryColor,
    double total,
    bool isDesktop, {
    required double pajakAmount,
    required String pajakName,
    required double promoDiscount,
    required double manualDiscountAmount,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Divider(height: 1),
        _buildOdooSummary(isDark, primaryColor, total, pajakAmount: pajakAmount, pajakName: pajakName, promoDiscount: promoDiscount, manualDiscountAmount: manualDiscountAmount),
        ValueListenableBuilder<bool>(
          valueListenable: SettingsController.instance.showNumpad,
          builder: (context, showNumpad, child) {
            if (!showNumpad) return const SizedBox();
            return SizedBox(
              height: 200,
              child: OrderNumpad(
                mode: _numpadMode,
                onModeChanged: (m) => setState(() {
                  _numpadMode = m;
                  _isFirstInput = true;
                }),
                onTap: _handleOrderNumpadTap,
                onBackspace: _handleOrderNumpadBackspace,
                onToggleSign: _handleOrderNumpadToggleSign,
              ),
            );
          }
        ),
        _buildCartActionButton(primaryColor, total, isDesktop),
      ],
    );
  }

  Widget _buildCartActionButton(
    Color primaryColor,
    double total,
    bool isDesktop,
  ) {
    final totalQty = _getCartTotalCount();
    final hasItems = widget.cartItems.isNotEmpty && totalQty > 0;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, isDesktop ? 16 : 8),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: isDesktop ? 52 : 56,
            child: ElevatedButton(
              onPressed: hasItems
                  ? () => setState(() {
                      _isPaymentMode = true;
                      _selectedPaymentMethod = "Tunai"; // Default for mobile
                      widget.onModeChanged?.call(true);
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) _cashFocusNode.requestFocus();
                      });
                    })
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[300],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 0,
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Pilih Pembayaran",
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOdooSummary(
    bool isDark,
    Color primaryColor,
    double total, {
    required double pajakAmount,
    required String pajakName,
    required double promoDiscount,
    required double manualDiscountAmount,
  }) {
    final double totalDiscount = promoDiscount + manualDiscountAmount;
    final double subtotalBeforeDiscount = total + totalDiscount - pajakAmount;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.grey[50],
      child: Column(
        children: [
          if (totalDiscount > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Subtotal",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
                Text(
                  _currencyFormat.format(subtotalBeforeDiscount),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.discount_rounded, size: 14, color: Color(0xFF10B981)),
                    const SizedBox(width: 4),
                    Text(
                      widget.discountData?['is_member_discount'] == true
                          ? (widget.discountData?['promo_names'] != null && (widget.discountData!['promo_names'] as List).isNotEmpty
                              ? "${(widget.discountData!['promo_names'] as List).first}"
                              : "Diskon Member")
                          : (widget.discountData?['promo_names'] != null && (widget.discountData!['promo_names'] as List).isNotEmpty
                              ? "${(widget.discountData!['promo_names'] as List).first}"
                              : "Diskon"),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
                Text(
                  "-${_currencyFormat.format(totalDiscount)}",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF10B981),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  "Total (${_getCartTotalCount()} Item)",
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                _currencyFormat.format(total),
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  color: primaryColor,
                ),
              ),
            ],
          ),
          if (pajakAmount > 0) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  pajakName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  _currencyFormat.format(pajakAmount),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // --- NEW HELPER METHODS REPLACING OLD ONES ---
  Widget _buildCombinedOrderSummaryCard(
    bool isDark,
    Color primaryColor,
    double subTotal,
    double discount,
    double pajakAmount,
    String pajakName,
    double total,
    double promoDiscount,
    double manualDiscountAmount,
  ) {
    final displayCount = _isOrderSummaryExpanded ? widget.cartItems.length : 4;
    final hasMoreItems = widget.cartItems.length > 4;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.receipt_long_outlined, color: primaryColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "Ringkasan & Rincian Pesanan",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "${_getCartTotalCount()} item",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Items List
          ...widget.cartItems.take(displayCount).map((item) {
            final p = item['product'] as Product;
            final qty = item['quantity'] as int;
            final price = item['price'] as double;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.fastfood_outlined, size: 16, color: primaryColor),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name ?? "Item",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          "${_currencyFormat.format(price)} x $qty",
                          style: GoogleFonts.openSans(
                            fontSize: 11,
                            color: isDark ? Colors.white54 : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _currencyFormat.format(price * qty),
                    style: GoogleFonts.openSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            );
          }),
          if (hasMoreItems)
            InkWell(
              onTap: () => setState(() => _isOrderSummaryExpanded = !_isOrderSummaryExpanded),
              borderRadius: BorderRadius.circular(8),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isOrderSummaryExpanded
                            ? "Lebih Sedikit"
                            : "... dan ${widget.cartItems.length - 4} item lainnya",
                        style: GoogleFonts.openSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _isOrderSummaryExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        size: 16,
                        color: primaryColor,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8),
          Divider(color: isDark ? Colors.white10 : Colors.grey[200]),
          const SizedBox(height: 8),
          _buildDetailRow("Subtotal", subTotal, isDark),
          if (promoDiscount > 0)
            _buildDetailRow(
              widget.discountData?['is_member_discount'] == true
                  ? (widget.discountData?['promo_names'] != null &&
                          (widget.discountData!['promo_names'] as List).isNotEmpty
                      ? "${(widget.discountData!['promo_names'] as List).first}"
                      : "Diskon Member")
                  : (widget.discountData?['promo_names'] != null &&
                          (widget.discountData!['promo_names'] as List).isNotEmpty
                      ? "${(widget.discountData!['promo_names'] as List).first}"
                      : "Diskon Promo"),
              -promoDiscount,
              isDark,
              customColor: const Color(0xFF10B981),
            ),
          if (manualDiscountAmount > 0)
            _buildDetailRow(
              _manualDiscountLabel.isNotEmpty
                  ? "Diskon ($_manualDiscountLabel)"
                  : "Diskon Manual",
              -manualDiscountAmount,
              isDark,
              customColor: const Color(0xFF10B981),
            ),
          if (pajakAmount > 0) _buildDetailRow(pajakName, pajakAmount, isDark),
          const SizedBox(height: 6),
          Divider(color: isDark ? Colors.white10 : Colors.grey[200]),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: primaryColor.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Total",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  _currencyFormat.format(total),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, double amount, bool isDark, {Color? customColor}) {
    final color = customColor ?? (isDark ? Colors.white70 : Colors.black87);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: color,
              fontWeight: customColor != null ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            _currencyFormat.format(amount),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickCashBtnOutlined(String label, double amount, bool isDark, Color primaryColor) {
    final bool isSelected = (_cashReceived == amount && amount > 0) || (label == "Pas" && _cashReceived == amount);

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: () {
          if (!mounted) return;
          setState(() {
            _cashReceived = amount;
            _cashController.text = NumberFormat.decimalPattern("id").format(amount);
          });
          _cashFocusNode.requestFocus();
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected
                ? primaryColor.withValues(alpha: 0.15)
                : primaryColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? primaryColor : primaryColor.withValues(alpha: 0.35),
              width: isSelected ? 1.5 : 1.2,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isSelected ? primaryColor : (isDark ? Colors.white : Colors.black87),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color primaryColor,
    required bool isDark,
    bool isSelected = false,
    Color? customColor,
    required VoidCallback? onTap,
  }) {
    final Color activeColor = customColor ?? primaryColor;
    final bool isDisabled = onTap == null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: isDisabled
              ? (isDark ? Colors.white.withValues(alpha: 0.02) : Colors.grey[100])
              : (isSelected
                  ? activeColor.withValues(alpha: 0.14)
                  : activeColor.withValues(alpha: 0.05)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDisabled
                ? (isDark ? Colors.white10 : Colors.grey[300]!)
                : (isSelected ? activeColor : activeColor.withValues(alpha: 0.35)),
            width: isSelected ? 1.5 : 1.2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isDisabled ? Colors.grey : activeColor,
              size: 18,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: isDisabled ? Colors.grey : activeColor,
                fontWeight: FontWeight.w600,
                fontSize: 10.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentView(
    bool isDark,
    Color primaryColor,
    double subTotal,
    double discount,
    double total,
    double change,
    bool isDesktop,
    bool isNarrow, {
    required double pajakAmount,
    required String pajakName,
    required double promoDiscount,
    required double manualDiscountAmount,
  }) {
    return Column(
      children: [
        // TOP SCROLLABLE AREA: Order Summary & Total Details
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCombinedOrderSummaryCard(
                  isDark,
                  primaryColor,
                  subTotal,
                  discount,
                  pajakAmount,
                  pajakName,
                  total,
                  promoDiscount,
                  manualDiscountAmount,
                ),
              ],
            ),
          ),
        ),

        const Divider(height: 1),

        // Numpad remains dynamically rendered if enabled
        ValueListenableBuilder<bool>(
          valueListenable: SettingsController.instance.showNumpad,
          builder: (context, showNumpad, child) {
            if (!showNumpad) return const SizedBox();
            return SizedBox(
              height: 200,
              child: Opacity(
                opacity: _selectedPaymentMethod == "Tunai" ? 1.0 : 0.5,
                child: IgnorePointer(
                  ignoring: _selectedPaymentMethod != "Tunai",
                  child: OrderNumpad(
                    mode: _numpadMode,
                    onModeChanged: (_) {}, 
                    onTap: _handleNumpadTap,
                    onBackspace: () => _handleNumpadTap("backspace"),
                    onToggleSign: () {},
                  ),
                ),
              ),
            );
          }
        ),

        // Bottom Controls Panel: Quick Cash -> Cash Input -> Compact 3x2 Grid -> Total & Checkout
        Container(
          padding: EdgeInsets.fromLTRB(16, 12, 16, isDesktop ? 16 : 12),
          decoration: BoxDecoration(
             color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          ),
          child: Column(
             mainAxisSize: MainAxisSize.min,
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
                // 1. Opsi Jumlah Pembayaran (Jumlah Cepat)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Jumlah Cepat",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white54 : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildQuickCashBtnOutlined("Pas", total, isDark, primaryColor),
                      _buildQuickCashBtnOutlined("Rp 50.000", 50000, isDark, primaryColor),
                      _buildQuickCashBtnOutlined("Rp 100.000", 100000, isDark, primaryColor),
                      _buildQuickCashBtnOutlined("Rp 200.000", 200000, isDark, primaryColor),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // 2. Input Uang Diterima & Kembalian Field
                ValueListenableBuilder<bool>(
                  valueListenable: SettingsController.instance.showNumpad,
                  builder: (context, showNumpad, child) {
                    return TextField(
                      controller: _cashController,
                      focusNode: _cashFocusNode,
                      autofocus: true,
                      readOnly: showNumpad,
                      showCursor: true,
                      keyboardType: showNumpad ? TextInputType.none : TextInputType.number,
                      onChanged: showNumpad ? null : (val) {
                        setState(() {
                          String rawValue = val.replaceAll(RegExp(r"[^\d]"), "");
                          _cashReceived = double.tryParse(rawValue) ?? 0;
                        });
                      },
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: "Masukan jumlah uang",
                        hintStyle: GoogleFonts.openSans(color: Colors.grey, fontSize: 13),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(left: 12, right: 6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Rp",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                        isDense: true,
                        filled: true,
                        fillColor: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: isDark ? Colors.white10 : Colors.grey[300]!,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: isDark ? Colors.white10 : Colors.grey[300]!,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: primaryColor,
                            width: 1.8,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18, color: Colors.grey),
                          onPressed: () {
                            _cashController.clear();
                            _cashReceived = 0;
                            setState(() {});
                            _cashFocusNode.requestFocus();
                          },
                        ),
                      ),
                    );
                  }
                ),

                // Green Kembalian display
                if (_selectedPaymentMethod == "Tunai" && _cashReceived >= total && _cashReceived > 0)
                  Padding(
                     padding: const EdgeInsets.only(top: 8),
                     child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                           color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.green.withValues(alpha: 0.06),
                           border: Border.all(color: Colors.green, width: 1.2),
                           borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                           children: [
                              Text("Kembalian", style: GoogleFonts.plusJakartaSans(color: Colors.green, fontWeight: FontWeight.w600, fontSize: 13)),
                              Text(_currencyFormat.format(_cashReceived - total), style: GoogleFonts.plusJakartaSans(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 15)),
                           ]
                        )
                     )
                  ),

                const SizedBox(height: 10),

                // 3. Compact 3x2 Square Grid for Payment Methods & Action Controls
                FutureBuilder<List<PaymentMethod>>(
                  future: context.read<AdminController>().paymentMethodService.getPaymentMethods(context.read<AdminController>().storeId ?? "").then((list) => list.where((m) => m.isActive).toList()),
                  builder: (context, snapshot) {
                     final customMethods = snapshot.data ?? [];
                     if (customMethods.isNotEmpty && _cachedPaymentMethods.isEmpty) {
                       WidgetsBinding.instance.addPostFrameCallback((_) {
                         if (mounted) setState(() => _cachedPaymentMethods = customMethods);
                       });
                     }
                     return Column(
                       children: [
                         // Row 1: [ Tunai ] [ QRIS / Non-Tunai ] [ Pelanggan ]
                         ValueListenableBuilder<bool>(
                           valueListenable: SettingsController.instance.featureLoyaltyEnabled,
                           builder: (context, loyaltyEnabled, _) {
                             return Row(
                               children: [
                                 Expanded(
                                   child: _buildActionCard(
                                     icon: Icons.money,
                                     label: "Tunai",
                                     primaryColor: primaryColor,
                                     isDark: isDark,
                                     isSelected: _selectedPaymentMethod == "Tunai",
                                     onTap: () {
                                       setState(() { _selectedPaymentMethod = "Tunai"; });
                                       _cashFocusNode.requestFocus();
                                     },
                                   ),
                                 ),
                                 const SizedBox(width: 6),
                                 Expanded(
                                   child: _buildActionCard(
                                     icon: Icons.qr_code_scanner,
                                     label: _selectedPaymentMethod != "Tunai" && _selectedPaymentMethod.isNotEmpty ? _selectedPaymentMethod : "QRIS",
                                     primaryColor: primaryColor,
                                     isDark: isDark,
                                     isSelected: _selectedPaymentMethod != "Tunai",
                                     onTap: () => _showPaymentMethodPicker(customMethods, total, primaryColor, isDark),
                                   ),
                                 ),
                                 if (loyaltyEnabled) ...[
                                   const SizedBox(width: 6),
                                   Expanded(
                                     child: _buildActionCard(
                                       icon: Icons.person_outline,
                                       label: widget.selectedCustomer?.name ?? "Pelanggan",
                                       primaryColor: primaryColor,
                                       isDark: isDark,
                                       isSelected: widget.selectedCustomer != null,
                                       customColor: widget.selectedCustomer != null && widget.discountData?['is_member_discount'] == true
                                           ? const Color(0xFF10B981)
                                           : null,
                                       onTap: () => _showCustomerSearchDialog(isDark),
                                     ),
                                   ),
                                 ],
                               ],
                             );
                           },
                         ),
                         const SizedBox(width: 6, height: 6),
                         // Row 2: [ Diskon ] [ Pisah Bill ] [ Split Pay ]
                         Row(
                           children: [
                             Expanded(
                               child: _buildActionCard(
                                 icon: _manualDiscount > 0 ? Icons.discount_rounded : Icons.discount_outlined,
                                 label: _manualDiscount > 0
                                     ? (_manualDiscountIsPercent
                                         ? "Diskon ${_manualDiscount.toStringAsFixed(0)}%"
                                         : "Diskon ${_currencyFormat.format(_manualDiscount)}")
                                     : "Diskon",
                                 primaryColor: primaryColor,
                                 isDark: isDark,
                                 customColor: _manualDiscount > 0 ? Colors.green : primaryColor,
                                 isSelected: _manualDiscount > 0,
                                 onTap: () => _showDiscountSheet(isDark, primaryColor, subTotal),
                               ),
                             ),
                             const SizedBox(width: 6),
                             Expanded(
                               child: _buildActionCard(
                                 icon: Icons.call_split_rounded,
                                 label: "Pisah Bill",
                                 primaryColor: primaryColor,
                                 isDark: isDark,
                                 customColor: Colors.deepPurple,
                                 onTap: widget.cartItems.length < 2
                                     ? null
                                     : () => _showSplitItemDialog(isDark),
                               ),
                             ),
                             const SizedBox(width: 6),
                             Expanded(
                               child: _buildActionCard(
                                 icon: Icons.payment_rounded,
                                 label: _splitPayments != null ? "${_splitPayments!.length} Metode" : "Split Pay",
                                 primaryColor: primaryColor,
                                 isDark: isDark,
                                 customColor: _splitPayments != null ? Colors.green : Colors.teal,
                                 isSelected: _splitPayments != null,
                                 onTap: () => _showSplitPaymentSheet(isDark, total, _cachedPaymentMethods),
                               ),
                             ),
                           ],
                         ),
                       ],
                     );
                  }
                ),

                // Split Payment summary badges
                if (_splitPayments != null) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: _splitPayments!.map((p) => Chip(
                      label: Text(
                        "${p['method']}: ${_currencyFormat.format(p['amount'])}",
                        style: GoogleFonts.openSans(fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                      deleteIcon: const Icon(Icons.close, size: 14),
                      onDeleted: () => setState(() => _splitPayments = null),
                      backgroundColor: Colors.teal.withValues(alpha: 0.1),
                      side: const BorderSide(color: Colors.teal),
                    )).toList(),
                  ),
                ],
                const SizedBox(height: 10),

                // Proses Pembayaran Button
                SizedBox(
                   width: double.infinity,
                   height: 50,
                   child: ElevatedButton(
                      onPressed: widget.isProcessing ? null : () {
                          // Split Payment path
                          if (_splitPayments != null) {
                            final combinedLabel = _splitPayments!.map((p) => p['method']).join('+');
                            widget.onCheckout(total, combinedLabel, splitPayments: _splitPayments, discount: discount);
                            return;
                          }
                          if (_selectedPaymentMethod == "Tunai" && _cashReceived < total) {
                             if (widget.selectedCustomer == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                   const SnackBar(content: Text("Pilih atau tambah pelanggan terlebih dahulu untuk transaksi hutang."), backgroundColor: Colors.redAccent,),
                                );
                                _showCustomerSearchDialog(isDark);
                                return;
                             }
                             _showDebtConfirmation(context, total, primaryColor, isDark, discount: discount);
                             return;
                          }
                          widget.onCheckout(_cashReceived, _selectedPaymentMethod, discount: discount);
                      },
                      style: ElevatedButton.styleFrom(
                         backgroundColor: primaryColor, // Orange
                         foregroundColor: Colors.white,
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                         elevation: 0,
                      ),
                      child: widget.isProcessing ? const CircularProgressIndicator(color: Colors.white) : Text(
                         "Proses Pembayaran", 
                         style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700)
                      )
                   )
                ),
             ]
          )
        ),
      ],
    );
  }
  void _showDebtConfirmation(BuildContext context, double total, Color primaryColor, bool isDark, {double? discount}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Hutang / Piutang",
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Uang diterima (${_currencyFormat.format(_cashReceived)}) kurang dari total belanja (${_currencyFormat.format(total)}).",
              style: GoogleFonts.openSans(
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Jadikan sebagai hutang?",
              style: GoogleFonts.openSans(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "Batal",
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.onCheckout(_cashReceived, "Tunai", status: 'debt', discount: discount);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text("Ya, Hutang"),
          ),
        ],
      ),
    );
  }


  // -------------------------------------------------------------------------
  // SPLIT ITEM: open the SplitItemDialog to split cart into 2 bills
  // -------------------------------------------------------------------------
  void _showSplitItemDialog(bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => SplitItemDialog(
        cartItems: widget.cartItems,
        onSplitItems: (bill1, bill2) {
          widget.onSplitItems?.call(bill1, bill2);
        },
      ),
    );
  }

  // -------------------------------------------------------------------------
  // SPLIT PAYMENT: open the SplitPaymentSheet to pay with multiple methods
  // -------------------------------------------------------------------------
  void _showSplitPaymentSheet(bool isDark, double total, List<PaymentMethod> customMethods) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SplitPaymentSheet(
        total: total,
        customMethods: customMethods,
        onConfirm: (payments) {
          setState(() => _splitPayments = payments);
        },
      ),
    );
  }

  void _showDiscountSheet(bool isDark, Color primaryColor, double subTotal) {
    final discountCtrl = TextEditingController(
      text: _manualDiscount > 0 ? (_manualDiscountIsPercent ? _manualDiscount.toStringAsFixed(0) : _manualDiscount.toInt().toString()) : ""
    );
    bool isPercent = _manualDiscountIsPercent;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final adminCtrl = context.read<AdminController>();
          final storeId = adminCtrl.storeId;

          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1C1E) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Tambah Diskon",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Custom Discount Input
                  Text(
                    "Diskon Kustom",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: discountCtrl,
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          decoration: InputDecoration(
                            hintText: "0",
                            prefixText: isPercent ? null : "Rp ",
                            suffixText: isPercent ? "%" : null,
                            filled: true,
                            fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[50],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            _buildDiscountTypeBtn("Rp", !isPercent, isDark, primaryColor, () => setModalState(() => isPercent = false)),
                            _buildDiscountTypeBtn("%", isPercent, isDark, primaryColor, () => setModalState(() => isPercent = true)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Promotions Section
                  if (storeId != null) ...[
                    Text(
                      "Promosi Berjalan",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FutureBuilder<List<Promotion>>(
                      future: adminCtrl.promotionService.getActivePromotions(storeId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final promos = snapshot.data ?? [];
                        if (promos.isEmpty) {
                          return Text(
                            "Tidak ada promosi aktif saat ini.",
                            style: GoogleFonts.openSans(color: Colors.grey, fontSize: 13),
                          );
                        }
                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: promos.length,
                          separatorBuilder: (c, i) => const SizedBox(height: 8),
                          itemBuilder: (context, i) {
                            final p = promos[i];
                            final isSelected = _manualDiscountLabel == p.name;
                            return InkWell(
                              onTap: () {
                                setState(() {
                                  _manualDiscount = (p.value ?? 0).toDouble();
                                  _manualDiscountIsPercent = (p.discountType == 'percentage');
                                  _manualDiscountLabel = p.name ?? "Promo";
                                });
                                Navigator.pop(ctx);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? primaryColor.withValues(alpha: 0.1)
                                      : (isDark
                                          ? Colors.white.withValues(alpha: 0.03)
                                          : Colors.grey[50]),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: isSelected ? primaryColor : Colors.transparent),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.local_offer_outlined, color: isSelected ? primaryColor : Colors.grey, size: 20),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            p.name ?? "Promo",
                                            style: GoogleFonts.plusJakartaSans(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                              color: isDark ? Colors.white : Colors.black87,
                                            ),
                                          ),
                                          Text(
                                            p.discountType == 'percentage' ? "${(p.value ?? 0).toInt()}% OFF" : "Diskon ${_currencyFormat.format(p.value ?? 0)}",
                                            style: GoogleFonts.openSans(fontSize: 12, color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isSelected) Icon(Icons.check_circle, color: primaryColor, size: 20),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                  
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      if (_manualDiscount > 0)
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              setState(() {
                                _manualDiscount = 0;
                                _manualDiscountLabel = "";
                              });
                              Navigator.pop(ctx);
                            },
                            child: const Text("Hapus Diskon", style: TextStyle(color: Colors.redAccent)),
                          ),
                        ),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            final val = double.tryParse(discountCtrl.text) ?? 0;
                            setState(() {
                              _manualDiscount = val;
                              _manualDiscountIsPercent = isPercent;
                              _manualDiscountLabel = ""; // Custom discount
                            });
                            Navigator.pop(ctx);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text("Terapkan"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDiscountTypeBtn(String label, bool active, bool isDark, Color primaryColor, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: active ? primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            color: active ? Colors.white : (isDark ? Colors.white38 : Colors.black38),
          ),
        ),
      ),
    );
  }

  void _showCustomerSearchDialog(bool isDark) {
    final searchCtrl = TextEditingController();
    final db = context.read<AppDatabase>();
    List<Customer> allCustomers = [];
    List<Customer> filtered = [];
    const primaryColor = Color(0xFFC0392B);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (ctx) => StatefulBuilder(
        builder: (context, ss) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1C1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Handlebar
              Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Text(
                      "Pilih Pelanggan",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? primaryColor.withValues(alpha: 0.1)
                            : primaryColor.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showAddCustomerDialog(isDark);
                        },
                        icon: const Icon(Icons.add_rounded, size: 18, color: primaryColor),
                        label: Text(
                          "Tambah",
                          style: GoogleFonts.plusJakartaSans(
                            color: primaryColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    if (widget.selectedCustomer != null) ...[
                      const SizedBox(width: 6),
                      TextButton.icon(
                        onPressed: () {
                          widget.onCustomerSelected?.call(null);
                          Navigator.pop(ctx);
                        },
                        icon: const Icon(Icons.person_remove_outlined, size: 16, color: Colors.redAccent),
                        label: Text(
                          "Hapus",
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.redAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.grey[100],
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded, size: 20),
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.grey[50],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? Colors.white10 : Colors.grey[200]!,
                    ),
                  ),
                  child: TextField(
                    controller: searchCtrl,
                    style: GoogleFonts.openSans(
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      hintText: "Cari nama atau nomor HP...",
                      hintStyle: GoogleFonts.openSans(color: Colors.grey),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: primaryColor,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                    ),
                    onChanged: (val) {
                      ss(() {
                        filtered = allCustomers
                            .where(
                              (c) =>
                                  (c.name?.toLowerCase().contains(
                                        val.toLowerCase(),
                                      ) ??
                                      false) ||
                                  (c.phoneNumber?.contains(val) ?? false),
                            )
                            .toList();
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // Results List
              Expanded(
                child: FutureBuilder<List<Customer>>(
                  future: (db.select(db.customers)).get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        allCustomers.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (allCustomers.isEmpty && snapshot.hasData) {
                      allCustomers = snapshot.data!;
                      filtered = allCustomers;
                    }

                    if (filtered.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.05),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.person_search_rounded,
                                size: 60,
                                color: primaryColor.withValues(alpha: 0.3),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              "Pelanggan tidak ditemukan",
                              style: GoogleFonts.openSans(
                                color: Colors.grey,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Coba cari dengan kata kunci lain",
                              style: GoogleFonts.openSans(
                                color: Colors.grey[400],
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(24),
                      itemCount: filtered.length,
                      itemBuilder: (c, i) {
                        final cust = filtered[i];
                        final isSelected =
                            widget.selectedCustomer?.id == cust.id;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: () {
                              widget.onCustomerSelected?.call(isSelected ? null : cust);
                              Navigator.pop(ctx);
                            },
                            borderRadius: BorderRadius.circular(18),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? primaryColor.withValues(alpha: 0.05)
                                    : (isDark
                                          ? Colors.white.withValues(alpha: 0.02)
                                          : Colors.white),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: isSelected
                                      ? primaryColor
                                      : (isDark
                                            ? Colors.white10
                                            : Colors.grey[200]!),
                                  width: isSelected ? 2 : 1,
                                ),
                                boxShadow: [
                                  if (!isDark && !isSelected)
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.03,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: primaryColor.withValues(
                                      alpha: 0.1,
                                    ),
                                    child: Text(
                                      cust.name
                                              ?.substring(0, 1)
                                              .toUpperCase() ??
                                          "P",
                                      style: GoogleFonts.plusJakartaSans(
                                        color: primaryColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          cust.name ?? "-",
                                          style: GoogleFonts.openSans(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15,
                                            color: isDark
                                                ? Colors.white
                                                : Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.phone_iphone_rounded,
                                              size: 12,
                                              color: Colors.grey[500],
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              cust.phoneNumber ??
                                                  "Tanpa nomor HP",
                                              style: GoogleFonts.openSans(
                                                fontSize: 13,
                                                color: Colors.grey[500],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: primaryColor.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          "${cust.points}",
                                          style: GoogleFonts.plusJakartaSans(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: primaryColor,
                                          ),
                                        ),
                                        Text(
                                          "Poin",
                                          style: GoogleFonts.openSans(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w600,
                                            color: primaryColor.withValues(
                                              alpha: 0.7,
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddCustomerDialog(bool isDark) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final admin = context.read<AdminController>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Tambah Pelanggan Baru",
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                labelText: "Nama Lengkap",
                labelStyle: TextStyle(color: Colors.grey[600]),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: phoneController,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                labelText: "No. HP",
                labelStyle: TextStyle(color: Colors.grey[600]),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: emailController,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                labelText: "Email (Opsional)",
                labelStyle: TextStyle(color: Colors.grey[600]),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Batal", style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final db = context.read<AppDatabase>();
                // We'll use the CustomerService logic directly or via provider if available
                // Based on imports, CustomerService is not imported here.
                // I should add the import or use the db directly.
                // Let's check imports in cart_sidebar.dart
                final id = "CUST-${DateTime.now().millisecondsSinceEpoch}";
                final customer = Customer(
                  id: id,
                  storeId: admin.storeId,
                  name: nameController.text,
                  phoneNumber: phoneController.text,
                  email: emailController.text,
                  points: 0,
                  createdAt: DateTime.now(),
                );

                await db.into(db.customers).insert(customer);

                if (!context.mounted) return;
                widget.onCustomerSelected?.call(customer);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC0392B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text("Simpan & Pilih"),
          ),
        ],
      ),
    );
  }


  void _showPaymentMethodPicker(
    List<PaymentMethod> methods,
    double total,
    Color primaryColor,
    bool isDark,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1C1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Pilih Metode Digital",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...methods.map((m) {
              final isSelected = _selectedPaymentMethod == m.name;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedPaymentMethod = m.name;
                      _cashReceived = total;
                      _cashController.text = NumberFormat.decimalPattern(
                        'id',
                      ).format(total);
                    });
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? primaryColor.withValues(alpha: 0.05)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? primaryColor
                            : Colors.grey.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          m.type == 'qris'
                              ? Icons.qr_code_scanner
                              : Icons.account_balance_wallet,
                          color: isSelected ? primaryColor : Colors.grey,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m.name,
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? primaryColor
                                      : (isDark
                                            ? Colors.white
                                            : Colors.black87),
                                ),
                              ),
                              if (m.username != null)
                                Text(
                                  "A.N. ${m.username}",
                                  style: GoogleFonts.openSans(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              if (m.details != null)
                                Text(
                                  m.details!,
                                  style: GoogleFonts.openSans(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (m.type == 'qris' && m.qrisUrl != null)
                          IconButton(
                            icon: const Icon(Icons.qr_code, size: 20),
                            onPressed: () => _showQRISDialog(m),
                            color: primaryColor,
                          ),
                        if (isSelected)
                          Icon(Icons.check_circle, color: primaryColor),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }


  void _showQRISDialog(PaymentMethod method) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        contentPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    method.name,
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (method.qrisUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image(
                  image: FileManager().getImageProvider(method.qrisUrl!),
                  fit: BoxFit.contain,
                ),
              ),
            const SizedBox(height: 16),
            if (method.username != null && method.username!.isNotEmpty)
              Text(
                "A.N. ${method.username}",
                style: GoogleFonts.openSans(fontWeight: FontWeight.w600),
              ),
            if (method.details != null && method.details!.isNotEmpty)
              Text(
                method.details!,
                style: GoogleFonts.openSans(color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }

}

class DottedLine extends StatelessWidget {
  const DottedLine({super.key});
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 4.0;
        const dashHeight = 1.0;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return const SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Colors.grey),
              ),
            );
          }),
        );
      },
    );
  }
}

