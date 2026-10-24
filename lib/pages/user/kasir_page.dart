import 'dart:async';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../widgets/product_grid.dart';
import 'widgets/cart_sidebar.dart';
import '../../services/order_service.dart';
import '../../services/receipt_service.dart';
import 'widgets/table_dashboard_sheet.dart';
import 'package:provider/provider.dart';
import '../../controllers/admin_controller.dart';
import '../../controllers/settings_controller.dart';
import 'widgets/product_option_modal.dart';
import 'widgets/payment_success_dialog.dart';
import '../../core/app_theme.dart';
import '../../widgets/big_search_bar.dart';
import '../../services/app_database.dart';
import '../../services/platform/file_manager.dart';
import '../admin/report/expense_management_page.dart';
import '../admin/debt/debt_management_page.dart';
import '../admin/employee/employee_management_page.dart';
import '../attendance/attendance_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../controllers/analytics_controller.dart';

class KasirPage extends StatefulWidget {
  final bool showSidebar;
  final VoidCallback? onMenuPressed;
  final Function(int)? onNavigateToIndex;
  const KasirPage({
    super.key,
    this.showSidebar = true,
    this.onMenuPressed,
    this.onNavigateToIndex,
  });

  @override
  State<KasirPage> createState() => _KasirPageState();
}

class _KasirPageState extends State<KasirPage> {
  late OrderService _orderService;
  final _receiptService = ReceiptService();
  final _currencyFormat = NumberFormat.currency(
    locale: 'id',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  String? _storeId;
  String _selectedCategory = "Semua";
  String _searchQuery = "";
  String _selectedFilter = "Popular";
  final List<Map<String, dynamic>> _cartItems = [];
  List<String> _categories = ["Semua"];
  final Map<String, String> _categoryMap = {}; // Name -> ID

  List<Map<String, dynamic>> _promoCategories = [];
  int _selectedPromoIndex = -1; // -1 = none selected

  Map<String, int> _salesMap = {};

  static const _promoColors = [
    Color(0xFFC0392B), // Brand
    Color(0xFFE05A4E), // Brand Light
    Color(0xFF8B1A1A), // Brand Dark
    Color(0xFF384333),
    Color(0xFF4A5744),
  ];

  final Color _primaryColor = AppTheme.primaryColor;
  String? _storeName;
  String? _storeLogoUrl;

  double _cashReceived = 0;
  String _selectedPaymentMethod = "Tunai";
  final TextEditingController _cashController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  
  // Table Management
  StoreTable? _selectedTable;

  bool _isGridView = true;
  Map<String, dynamic> _discountData = {
    'total_discount': 0.0,
    'promo_names': [],
  };
  bool _isPaymentFullscreen = false;
  // ignore: unused_field
  List<Map<String, dynamic>>? _splitPaymentsData;
  String? _lastModifiedCartId;
  Customer? _selectedCustomer;
  StateSetter? _activeSheetSetState;
  bool _isSidebarVisible = true;
  final List<String> _recentProductIds = [];
  final List<Map<String, dynamic>> _heldCarts = [];

  Timer? _notificationTimer;
  String? _notificationMessage;
  Color _notificationColor = Colors.redAccent;

  void _showTopNotification(String message, {Color color = Colors.redAccent}) {
    _notificationTimer?.cancel();
    setState(() {
      _notificationMessage = message;
      _notificationColor = color;
    });
    _notificationTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _notificationMessage = null);
      }
    });
  }

  Future<void> _recalculateDiscounts() async {
    if (_storeId == null) return;

    final adminCtrl = context.read<AdminController>();
    final result = await adminCtrl.promotionService.calculateDiscounts(
      storeId: _storeId!,
      cartItems: _cartItems,
      selectedCustomerId: _selectedCustomer?.id,
    );

    if (mounted) {
      final double newDiscount = (result['total_discount'] as num?)?.toDouble() ?? 0.0;

      setState(() {
        _discountData = result;
      });
      _activeSheetSetState?.call(() {});

      if (_selectedCustomer != null && newDiscount > 0 && result['is_member_discount'] == true) {
        final formattedDisc = NumberFormat.currency(
          locale: 'id_ID',
          symbol: 'Rp ',
          decimalDigits: 0,
        ).format(newDiscount);
        _showTopNotification(
          "Diskon Member diterapkan untuk ${_selectedCustomer!.name ?? 'Member'}! (-$formattedDisc)",
          color: Colors.green,
        );
      }
    }
  }

  void _holdCurrentCart() {
    if (_cartItems.isEmpty) {
      _showTopNotification("Keranjang masih kosong.");
      return;
    }

    final String refName = _selectedCustomer?.name ?? "";
    final String timestamp = DateFormat('HH:mm').format(DateTime.now());
    final String label = refName.isNotEmpty ? "$refName ($timestamp)" : "Pesanan #$timestamp";

    setState(() {
      _heldCarts.add({
        'label': label,
        'items': List<Map<String, dynamic>>.from(_cartItems),
        'customer': _selectedCustomer,
        'discountData': Map<String, dynamic>.from(_discountData),
        'timestamp': DateTime.now(),
      });
      _resetPOS();
    });

    _showTopNotification("Pesanan disimpan dalam antrean.", color: Colors.green);
  }

  void _deleteHeldCart(int index) {
    setState(() {
      _heldCarts.removeAt(index);
    });
  }

  Future<void> _resumeHeldCart(int index) async {
    final held = _heldCarts[index];

    if (_cartItems.isNotEmpty) {
      final shouldSwap = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Ganti Keranjang?"),
          content: const Text("Pesanan saat ini belum selesai. Simpan yang saat ini dan tukar dengan pesanan ini?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Ya, Tukar"),
            ),
          ],
        ),
      );

      if (shouldSwap != true) return;

      final String refName = _selectedCustomer?.name ?? "";
      final String timestamp = DateFormat('HH:mm').format(DateTime.now());
      final String label = refName.isNotEmpty ? "$refName ($timestamp)" : "Pesanan #$timestamp";
      
      final currentCart = {
        'label': label,
        'items': List<Map<String, dynamic>>.from(_cartItems),
        'customer': _selectedCustomer,
        'discountData': Map<String, dynamic>.from(_discountData),
        'timestamp': DateTime.now(),
      };

      setState(() {
        _heldCarts.removeAt(index);
        _heldCarts.add(currentCart);
        _restoreCart(held);
      });
    } else {
      setState(() {
        _heldCarts.removeAt(index);
        _restoreCart(held);
      });
    }
  }

  void _restoreCart(Map<String, dynamic> held) {
    _cartItems.clear();
    _cartItems.addAll(held['items']);
    _selectedCustomer = held['customer'];
    _discountData = held['discountData'];
    _cashReceived = 0;
    _cashController.clear();
  }

  Widget _buildHeldCartsIcon(bool isDark) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.white10 : Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: isDark ? const Color(0xFF374151) : const Color(0xFFCBD5E1), width: 1.2,
            ),
          ),
          child: IconButton(
            icon: Icon(
              Icons.receipt_long_outlined,
              color: isDark ? Colors.white : Colors.black87,
              size: 24,
            ),
            onPressed: _showHeldCartsDialog,
            tooltip: "Antrean Pesanan",
          ),
        ),
        if (_heldCarts.isNotEmpty)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: const BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 20,
                minHeight: 20,
              ),
              child: Text(
                _heldCarts.length.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildKasirShortcutsButton(bool isDark) {
    return Container(
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
          color: Color(0xFFC0392B),
          size: 24,
        ),
        onPressed: () => _showKasirQuickShortcutsSheet(context, isDark),
        tooltip: "Pintasan Cepat",
      ),
    );
  }

  void _showKasirQuickShortcutsSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(
              color: isDark ? const Color(0xFF374151) : const Color(0xFFCBD5E1),
              width: 1.2,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC0392B).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.bolt_rounded, color: Color(0xFFC0392B), size: 20),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Pintasan Cepat Kasir",
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            "Buka menu langsung tanpa keluar dari Kasir",
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
              const SizedBox(height: 20),
              SingleChildScrollView(
                child: Center(
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildKasirShortcutTile(
                        icon: Icons.inventory_2_outlined,
                        label: "Kelola Produk",
                        subtitle: "Atur & tambah stok",
                        color: const Color(0xFF2563EB),
                        isDark: isDark,
                        onTap: () {
                          Navigator.pop(ctx);
                          widget.onNavigateToIndex?.call(1);
                        },
                      ),
                      ValueListenableBuilder<bool>(
                        valueListenable: SettingsController.instance.featureLoyaltyEnabled,
                        builder: (context, loyaltyEnabled, _) {
                          if (!loyaltyEnabled) return const SizedBox.shrink();
                          return _buildKasirShortcutTile(
                            icon: Icons.people_outline_rounded,
                            label: "Data Pelanggan",
                            subtitle: "Member & loyalitas",
                            color: const Color(0xFF4F46E5),
                            isDark: isDark,
                            onTap: () {
                              Navigator.pop(ctx);
                              widget.onNavigateToIndex?.call(12);
                            },
                          );
                        },
                      ),
                      _buildKasirShortcutTile(
                        icon: Icons.payments_outlined,
                        label: "Catat Pengeluaran",
                        subtitle: "Bahan, gas, kas kecil",
                        color: const Color(0xFFDC2626),
                        isDark: isDark,
                        onTap: () {
                          Navigator.pop(ctx);
                          if (_storeId != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ExpenseManagementPage(storeId: _storeId!),
                              ),
                            );
                          }
                        },
                      ),
                      _buildKasirShortcutTile(
                        icon: Icons.receipt_long_outlined,
                        label: "Riwayat Transaksi",
                        subtitle: "Daftar struk / order",
                        color: const Color(0xFF7C3AED),
                        isDark: isDark,
                        onTap: () {
                          Navigator.pop(ctx);
                          widget.onNavigateToIndex?.call(4);
                        },
                      ),
                      _buildKasirShortcutTile(
                        icon: Icons.credit_card_outlined,
                        label: "Buku Hutang",
                        subtitle: "Catatan piutang & kasbon",
                        color: const Color(0xFFD97706),
                        isDark: isDark,
                        onTap: () {
                          Navigator.pop(ctx);
                          if (_storeId != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DebtManagementPage(storeId: _storeId!),
                              ),
                            );
                          }
                        },
                      ),
                      _buildKasirShortcutTile(
                        icon: Icons.discount_outlined,
                        label: "Promosi & Diskon",
                        subtitle: "Atur promo & voucher",
                        color: const Color(0xFFEA580C),
                        isDark: isDark,
                        onTap: () {
                          Navigator.pop(ctx);
                          widget.onNavigateToIndex?.call(17);
                        },
                      ),
                      _buildKasirShortcutTile(
                        icon: Icons.badge_outlined,
                        label: "Kelola Pegawai",
                        subtitle: "Daftar staf & gaji",
                        color: const Color(0xFF0D9488),
                        isDark: isDark,
                        onTap: () {
                          Navigator.pop(ctx);
                          if (widget.onNavigateToIndex != null) {
                            widget.onNavigateToIndex!(5);
                          } else if (_storeId != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EmployeeManagementPage(storeId: _storeId!),
                              ),
                            );
                          }
                        },
                      ),
                      _buildKasirShortcutTile(
                        icon: Icons.fingerprint_rounded,
                        label: "Absensi Pegawai",
                        subtitle: "Check-in & shift kerja",
                        color: const Color(0xFFE11D48),
                        isDark: isDark,
                        onTap: () {
                          Navigator.pop(ctx);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AttendancePage(showSidebar: false),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKasirShortcutTile({
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
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 155,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF27272A) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? const Color(0xFF3F3F46) : const Color(0xFFE2E8F0),
              width: 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 10),
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

  void _showHeldCartsDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Antrean Pesanan",
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            IconButton(
              onPressed: () => Navigator.pop(ctx),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: _heldCarts.isEmpty
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      "Belum ada pesanan yang disimpan.",
                      style: GoogleFonts.openSans(color: Colors.grey),
                    ),
                  ],
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: _heldCarts.length,
                  itemBuilder: (context, index) {
                    final held = _heldCarts[index];
                    final List items = held['items'];
                    final double total = items.fold(0, (sum, item) => sum + (item['price'] * item['quantity']));

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[50],
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: isDark ? const Color(0xFF374151) : const Color(0xFFCBD5E1), width: 1.2),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        title: Text(
                          held['label'],
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        subtitle: Text(
                          "${items.length} item • ${_currencyFormat.format(total)}",
                          style: GoogleFonts.openSans(color: Colors.grey),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                              onPressed: () {
                                _deleteHeldCart(index);
                                Navigator.pop(ctx);
                                _showHeldCartsDialog();
                              },
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                _resumeHeldCart(index);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                              ),
                              child: const Text("Lanjutkan"),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _isGridView = SettingsController.instance.isGridView.value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final db = context.read<AppDatabase>();
      _orderService = OrderService(db);
      _initData();
    });
  }

  Future<void> _initData() async {
    await context.read<AdminController>().loadInitialData();
    if (mounted) {
      _loadStoreId();
    }
  }

  Future<void> _loadCategories() async {
    if (_storeId == null) return;

    final db = context.read<AppDatabase>();
    final localCategories = await (db.select(
      db.categories,
    )..where((t) => t.storeId.equals(_storeId!))).get();

    if (mounted) {
      setState(() {
        _categoryMap.clear();
        List<String> names = ["Semua"];
        for (var c in localCategories) {
          final name = c.name ?? "Unnamed";
          names.add(name);
          _categoryMap[name] = c.id;
        }
        _categories = names;
      });
    }
    await _loadActivePromos();
    await _loadSalesMap();
  }

  Future<void> _loadActivePromos() async {
    if (_storeId == null) return;
    final adminCtrl = context.read<AdminController>();
    final db = context.read<AppDatabase>();

    final activePromos = await adminCtrl.promotionService.getActivePromotions(
      _storeId!,
    );

    final List<Map<String, dynamic>> promoChips = [];
    for (final promo in activePromos) {
      if (promo.type != 'discount' || promo.value == null) continue;

      final items = await (db.select(
        db.promotionItems,
      )..where((t) => t.promotionId.equals(promo.id))).get();

      final Set<String> categoryIds = {};
      final Set<String> productIds = {};
      for (final item in items) {
        if (item.categoryId != null) categoryIds.add(item.categoryId!);
        if (item.productId != null) productIds.add(item.productId!);
      }

      promoChips.add({
        'name': promo.name ?? 'Promo',
        'value': promo.value,
        'discountType': promo.discountType,
        'categoryIds': categoryIds,
        'productIds': productIds,
        'isAllProducts': items.isEmpty,
      });
    }

    if (mounted) {
      setState(() {
        _promoCategories = promoChips;
        _selectedPromoIndex = -1;
      });
    }
  }

  Future<void> _loadSalesMap() async {
    if (_storeId == null) return;
    final db = context.read<AppDatabase>();

    final txItems = await (db.select(db.transactionItems)).get();
    final txIds =
        await (db.select(db.transactions)
              ..where((t) => t.storeId.equals(_storeId!)))
            .get()
            .then((rows) => {for (var r in rows) r.id});

    final Map<String, int> map = {};
    for (final item in txItems) {
      if (item.transactionId != null && txIds.contains(item.transactionId)) {
        final pid = item.productId;
        if (pid != null) {
          map[pid] = (map[pid] ?? 0) + (item.quantity ?? 0);
        }
      }
    }

    if (mounted) {
      setState(() => _salesMap = map);
    }
  }

  Future<void> _loadStoreId() async {
    final adminCtrl = context.read<AdminController>();
    if (adminCtrl.storeId != null) {
      setState(() {
        _storeId = adminCtrl.storeId;
        _storeName = adminCtrl.storeName;
        _storeLogoUrl = adminCtrl.storeLogo;
      });
      _loadCategories();
    }
  }

  int _getCartTotalCount() {
    return _cartItems.fold(0, (sum, item) => sum + (item['quantity'] as int));
  }

  double _getCartTotal() {
    return _cartItems.fold(0, (sum, item) {
      return sum +
          ((item['price'] as num).toDouble() * (item['quantity'] as int));
    });
  }

  Future<void> _handleProductSelection(
    Product product, {
    List? options,
    String? notes,
    double? price,
  }) async {
    if (options != null || notes != null || price != null) {
      _addToCart(product, options: options, notes: notes, price: price);
      return;
    }

    final db = context.read<AppDatabase>();
    final optionsRes = await (db.select(
      db.productOptions,
    )..where((t) => t.productId.equals(product.id))).get();

    final count = optionsRes.length;

    if (count > 0 && mounted) {
      final result = await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => ProductOptionModal(product: product),
      );

      if (!mounted) return;
      if (result != null) {
        _addToCart(
          product,
          options: result['choices'],
          notes: result['notes'],
          price: result['total_price'],
        );
      }
    } else {
      _addToCart(product, price: product.salePrice ?? 0);
    }
  }

  void _addToCart(
    Product product, {
    List? options,
    String? notes,
    double? price,
  }) {
    if (product.isStockManaged) {
      final currentInCart = _cartItems
          .where((item) => (item['product'] as Product).id == product.id)
          .fold(0, (sum, item) => sum + (item['quantity'] as int));

      if (currentInCart >= (product.stockQuantity ?? 0)) {
        if (mounted) {
          _showTopNotification(
            "Stok tidak mencukupi! Hanya tersedia ${product.stockQuantity} item.",
            color: Colors.redAccent,
          );
        }
        return;
      }
    }

    setState(() {
      final existingIndex = _cartItems.indexWhere((item) {
        bool sameProduct = (item['product'] as Product).id == product.id;
        final currentOptions = item['selected_options'] as List?;
        bool sameOptions = _compareOptions(currentOptions, options);
        bool sameNotes = (item['notes'] ?? '').trim() == (notes ?? '').trim();
        return sameProduct && sameOptions && sameNotes;
      });

      if (existingIndex != -1) {
        _cartItems[existingIndex]['quantity']++;
        _lastModifiedCartId = _cartItems[existingIndex]['cart_id'];
      } else {
        final newId = DateTime.now().microsecondsSinceEpoch.toString();
        _cartItems.add({
          'cart_id': newId,
          'product': product,
          'quantity': 1,
          'selected_options': options ?? [],
          'notes': notes ?? '',
          'price': price ?? product.salePrice ?? 0,
        });
        _lastModifiedCartId = newId;
      }
      _recalculateDiscounts();
      _isSidebarVisible = true;
      
      // Sound & Haptic Feedback
      SystemSound.play(SystemSoundType.click);
      HapticFeedback.lightImpact();
    });
  }

  bool _compareOptions(List? a, List? b) {
    final listA = a ?? [];
    final listB = b ?? [];

    if (listA.isEmpty && listB.isEmpty) return true;
    if (listA.length != listB.length) return false;

    final sortedA = List<Map<String, dynamic>>.from(listA)
      ..sort((x, y) => x['value_id'].compareTo(y['value_id']));
    final sortedB = List<Map<String, dynamic>>.from(listB)
      ..sort((x, y) => x['value_id'].compareTo(y['value_id']));

    for (int i = 0; i < sortedA.length; i++) {
      if (sortedA[i]['value_id'] != sortedB[i]['value_id']) return false;
    }
    return true;
  }

  void _removeFromCart(String cartId) {
    setState(() {
      final index = _cartItems.indexWhere((item) => item['cart_id'] == cartId);
      if (index != -1) {
        if (_cartItems[index]['quantity'] > 1) {
          _cartItems[index]['quantity']--;
        } else {
          _cartItems.removeAt(index);
        }
      }
      _recalculateDiscounts();
    });
  }

  Future<void> _processCheckout({
    String? status,
    List<Map<String, dynamic>>? splitPayments,
    double? appliedDiscount,
  }) async {
    if (_isProcessing || _cartItems.isEmpty || _storeId == null) return;

    setState(() => _isProcessing = true);
    try {
      final adminCtrl = context.read<AdminController>();
      final db = context.read<AppDatabase>();
      AnalyticsController? analyticsCtrl;
      try {
        analyticsCtrl = context.read<AnalyticsController>();
      } catch (_) {}

      String? uId = adminCtrl.userId;
      if (uId == null || uId.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        uId = prefs.getString('current_user_id');
      }
      if (uId == null || uId.isEmpty) {
        final firstProfile = await (db.select(db.profiles)..limit(1)).getSingleOrNull();
        uId = firstProfile?.id ?? 'system_cashier';
      }

      String effectiveStoreId = _storeId ?? adminCtrl.storeId ?? '';
      if (effectiveStoreId.isEmpty) {
        final firstStore = await (db.select(db.stores)..limit(1)).getSingleOrNull();
        effectiveStoreId = firstStore?.id ?? 'default_store';
        _storeId = effectiveStoreId;
      }

      double totalAmount = 0;
      List<Map<String, dynamic>> items = [];

      for (var cartItem in _cartItems) {
        final Product p = cartItem['product'];
        final qty = cartItem['quantity'] as int;
        final price = cartItem['price'] as double;
        final total = price * qty;

        totalAmount += total;
        items.add({
          'id': "${DateTime.now().microsecondsSinceEpoch}_${p.id}",
          'product_id': p.id,
          'product_name': p.name,
          'quantity': qty,
          'unit_price': price,
          'total_price': total,
          'notes': cartItem['notes'],
          'selected_options': cartItem['selected_options'],
        });
      }

      final double promoDiscount = (_discountData['total_discount'] as num?)?.toDouble() ?? 0.0;
      final double discount = (appliedDiscount != null && appliedDiscount > 0)
          ? appliedDiscount
          : promoDiscount;

      // Determine discount label and customer info
      String? discountLabel;
      final bool isMember = _selectedCustomer != null;
      final bool isMemberPromo = _discountData['is_member_discount'] == true;
      final List<dynamic>? promoNames = _discountData['promo_names'] as List<dynamic>?;
      if (isMemberPromo || (isMember && promoDiscount > 0)) {
        discountLabel = promoNames != null && promoNames.isNotEmpty
            ? promoNames.first.toString()
            : "Diskon Member";
      } else if (promoNames != null && promoNames.isNotEmpty) {
        discountLabel = promoNames.first.toString();
      } else if (discount > 0) {
        discountLabel = "Diskon";
      }
      final String? customerName = _selectedCustomer?.name;

      final subtotalAfterDiscount = (totalAmount - discount).clamp(0.0, double.infinity);
      
      final settings = SettingsController.instance;
      double pajakAmount = 0;
      if (settings.pajakEnabled.value) {
        pajakAmount = subtotalAfterDiscount * (settings.pajakRate.value / 100);
      }
      
      final finalTotal = subtotalAfterDiscount + pajakAmount;

      final txId = await _orderService.createOrder(
        storeId: effectiveStoreId,
        userId: uId,
        totalAmount: finalTotal,
        cashReceived: _cashReceived,
        change: _cashReceived - finalTotal,
        paymentMethod: splitPayments != null ? splitPayments.map((p) => p['method']).join('+') : _selectedPaymentMethod,
        items: items,
        customerId: _selectedCustomer?.id,
        tableNumber: _selectedTable?.name, // Record table name
        status: status,
        discount: discount,
        discountLabel: discountLabel,
        customerName: customerName,
        subtotal: totalAmount,
        pajakAmount: pajakAmount,
      );

      try {
        analyticsCtrl?.refreshData();
      } catch (_) {}

      // Update Table Status to occupied
      if (_selectedTable != null) {
        await (db.update(db.storeTables)..where((t) => t.id.equals(_selectedTable!.id))).write(
          const StoreTablesCompanion(status: drift.Value('waiting')), // Changed to waiting for "Pay-First" flow
        );
      }

      for (var cartItem in _cartItems) {
        final Product p = cartItem['product'];
        _recentProductIds.remove(p.id);
        _recentProductIds.insert(0, p.id);
      }

      final bool isDebt = status == 'debt';
      final now = DateTime.now();
      final double finalCash = _cashReceived;
      final double finalChange = _cashReceived - finalTotal;
      final currentStoreName = _storeName ?? "Warkop Alam POS";
      final currentStoreLogo = _storeLogoUrl;

      final List<Map<String, dynamic>> receiptItems = [];
      for (var cartItem in _cartItems) {
        final Product p = cartItem['product'];
        receiptItems.add({
          'name': p.name,
          'quantity': cartItem['quantity'],
          'unit_price': cartItem['price'],
          'total_price': (cartItem['price'] as double) * (cartItem['quantity'] as int),
          'notes': cartItem['notes'],
        });
      }

      final String? selectedTableNumber = _selectedTable?.name;

      final pdfData = await _receiptService.generateReceiptPdf(
        storeName: currentStoreName,
        storeLogoUrl: currentStoreLogo,
        transactionId: txId.substring(0, 8).toUpperCase(),
        createdAt: now,
        items: receiptItems,
        subtotal: totalAmount,
        discount: discount,
        discountLabel: discountLabel,
        customerName: customerName,
        pajakAmount: pajakAmount,
        pajakName: settings.pajakName.value,
        pajakRate: settings.pajakRate.value,
        totalAmount: finalTotal,
        cashReceived: finalCash,
        change: finalChange,
        paymentMethod: _selectedPaymentMethod,
        showStoreName: settings.receiptShowStoreName.value,
        showAddress: settings.receiptShowAddress.value,
        showDate: settings.receiptShowDate.value,
        showDetails: settings.receiptShowDetails.value,
        showThankYou: settings.receiptShowThankYou.value,
        showLogo: settings.receiptShowLogo.value,
        showEmail: settings.receiptShowEmail.value,
        showTable: settings.receiptShowTable.value,
        storeAddress: adminCtrl.storeAddress,
        storeEmail: adminCtrl.storeEmail,
        thankYouMessage: settings.receiptThankYouMessage.value,
        tableNumber: selectedTableNumber,
        isDebt: isDebt,
      );

      if (mounted) {
        _resetPOS();
        Navigator.of(context).maybePop();

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => PaymentSuccessDialog(
            pdfData: pdfData,
            transactionId: txId.substring(0, 8).toUpperCase(),
            subtotal: totalAmount,
            discount: discount,
            discountLabel: discountLabel,
            customerName: customerName,
            pajakAmount: pajakAmount,
            pajakName: settings.pajakName.value,
            totalAmount: finalTotal,
            cashReceived: finalCash,
            change: finalChange,
            storeName: currentStoreName,
            createdAt: now,
            items: receiptItems,
            paymentMethod: _selectedPaymentMethod,
            onNewTransaction: _resetPOS,
            isDebt: isDebt,
            tableNumber: selectedTableNumber,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showTopNotification("Checkout Gagal: $e", color: Colors.red);
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showTableSelectionDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TableDashboardSheet(
        selectedTable: _selectedTable,
        onTableSelected: (table) {
          setState(() => _selectedTable = table);
        },
      ),
    );
  }

  void _resetPOS() {
    setState(() {
      _cartItems.clear();
      _cashReceived = 0;
      _cashController.clear();
      _isPaymentFullscreen = false;
      _discountData = {
        'total_discount': 0.0,
        'promo_count': 0,
        'promo_names': [],
      };
      _selectedCustomer = null;
      _selectedTable = null;
      _splitPaymentsData = null;
    });
  }

  bool _isProcessing = false;

  @override
  void dispose() {
    _searchController.dispose();
    _cashController.dispose();
    super.dispose();
  }

  Future<void> _searchAndAddBySku(String sku) async {
    if (sku.isEmpty || _storeId == null) return;

    final db = context.read<AppDatabase>();
    final res = await (db.select(db.products)
          ..where((t) => t.storeId.equals(_storeId!))
          ..where((t) => t.sku.equals(sku))
          ..where((t) => t.isDeleted.equals(false)))
        .get();

    if (res.isNotEmpty) {
      final product = res.first;
      if (!mounted) return;
      _handleProductSelection(product);
      setState(() {
        _searchController.clear();
        _searchQuery = "";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isWide = MediaQuery.of(context).size.width >= 1024;
    final adminCtrl = context.watch<AdminController>();

    if (adminCtrl.storeId != null && adminCtrl.storeId != _storeId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _storeId = adminCtrl.storeId;
            _storeName = adminCtrl.storeName;
            _storeLogoUrl = adminCtrl.storeLogo;
          });
          _loadCategories();
        }
      });
    }

    return PopScope(
      canPop: !_isPaymentFullscreen && _cartItems.isEmpty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        if (_isPaymentFullscreen) {
          setState(() => _isPaymentFullscreen = false);
          return;
        }

        if (_cartItems.isNotEmpty) {
          final shouldLeave = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Batalkan Transaksi?'),
              content: const Text('Keranjang akan dikosongkan. Apakah Anda yakin ingin membatalkan transaksi ini?'),
              actions: [
                TextButton(
                  child: const Text('Lanjutkan Transaksi'),
                  onPressed: () => Navigator.pop(ctx, false),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Ya, Batalkan'),
                ),
              ],
            ),
          );

          if (shouldLeave == true && mounted) {
            _resetPOS();
          }
          return;
        }
      },
      child: Scaffold(
        drawer: null,
        appBar: isWide
            ? null
            : AppBar(
                backgroundColor: isDark ? const Color(0xFF1A1C1E) : Colors.white,
                elevation: 0,
                leading: null,
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Image.asset(
                        'assets/logo/logo.png',
                        height: 24,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _storeName ?? "Warkop Alam POS",
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: Icon(
                      _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
                      color: isDark ? Colors.white : Colors.black87,
                      size: 24,
                    ),
                    onPressed: () {
                      final newValue = !_isGridView;
                      setState(() => _isGridView = newValue);
                      SettingsController.instance.setGridView(newValue);
                    },
                  ),
                  ValueListenableBuilder<bool>(
                    valueListenable: SettingsController.instance.featureMejaEnabled,
                    builder: (context, enabled, _) {
                      if (!enabled) return const SizedBox.shrink();
                      return IconButton(
                        icon: Icon(
                          Icons.table_restaurant_outlined,
                          color: _selectedTable != null ? _primaryColor : (isDark ? Colors.white : Colors.black87),
                        ),
                        onPressed: _showTableSelectionDialog,
                      );
                    }
                  ),
                  _buildHeldCartsIcon(isDark),
                  const SizedBox(width: 8),
                  _buildKasirShortcutsButton(isDark),
                  const SizedBox(width: 8),
                ],
              ),
        body: _storeId == null
            ? const Center(child: CircularProgressIndicator())
            : Stack(
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWideScreen = constraints.maxWidth >= 720;

                      if (isWideScreen) {
                        return Row(
                          children: [
                            Expanded(
                              flex: _isSidebarVisible ? 7 : 1,
                              child: LayoutBuilder(
                                builder: (context, mainConstraints) {
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFF1A1C1E) : Colors.white,
                                          border: Border(
                                            bottom: BorderSide(
                                              color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E7EB),
                                              width: 1.5,
                                            ),
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                        child: LayoutBuilder(
                                          builder: (context, headerConstraints) {
                                            const double minHeaderWidth = 750;
                                            final bool needsScroll = headerConstraints.maxWidth < minHeaderWidth;
                                            final rowContent = Row(
                                              children: [
                                                Expanded(
                                                  child: BigSearchBar(
                                                    controller: _searchController,
                                                    autoFocus: true,
                                                    hintText: "Cari menu atau Scan SKU...",
                                                    onChanged: (val) => setState(
                                                      () => _searchQuery = val.toLowerCase(),
                                                    ),
                                                    onSubmitted: _searchAndAddBySku,
                                                    onClear: () {
                                                      setState(() {
                                                        _searchController.clear();
                                                        _searchQuery = "";
                                                      });
                                                    },
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                ValueListenableBuilder<bool>(
                                                  valueListenable: SettingsController.instance.featureMejaEnabled,
                                                  builder: (context, enabled, _) {
                                                    if (!enabled) return const SizedBox.shrink();
                                                    return _buildSecondaryHeaderAction(
                                                      label: _selectedTable != null ? _selectedTable!.name : "Pilih Meja",
                                                      icon: Icons.table_restaurant_outlined,
                                                      onTap: _showTableSelectionDialog,
                                                      isActive: _selectedTable != null,
                                                      isDark: isDark,
                                                    );
                                                  }
                                                ),
                                                const SizedBox(width: 12),
                                                _buildCategoryDropdown(isDark),
                                                const SizedBox(width: 12),
                                                _buildHeldCartsIcon(isDark),
                                                const SizedBox(width: 12),
                                                _buildKasirShortcutsButton(isDark),
                                                const SizedBox(width: 12),
                                                Container(
                                                  decoration: BoxDecoration(
                                                    color: isDark ? Colors.white10 : Colors.white,
                                                    borderRadius: BorderRadius.circular(15),
                                                    border: Border.all(
                                                      color: isDark ? const Color(0xFF374151) : const Color(0xFFCBD5E1), width: 1.2,
                                                    ),
                                                  ),
                                                  child: IconButton(
                                                    icon: Icon(
                                                      _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
                                                      color: isDark ? Colors.white : Colors.black87,
                                                    ),
                                                    onPressed: () {
                                                      final newValue = !_isGridView;
                                                      setState(() => _isGridView = newValue);
                                                      SettingsController.instance.setGridView(newValue);
                                                    },
                                                    tooltip: _isGridView ? "Tampilan List" : "Tampilan Grid",
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                ValueListenableBuilder<bool>(
                                                  valueListenable: SettingsController.instance.showFilterTabs,
                                                  builder: (context, show, _) {
                                                    return Container(
                                                      decoration: BoxDecoration(
                                                        color: show ? _primaryColor.withValues(alpha: 0.1) : (isDark ? Colors.white10 : Colors.white),
                                                        borderRadius: BorderRadius.circular(15),
                                                        border: Border.all(
                                                          color: show ? _primaryColor : (isDark ? const Color(0xFF374151) : const Color(0xFFCBD5E1)), width: 1.2,
                                                        ),
                                                      ),
                                                      child: IconButton(
                                                        icon: Icon(
                                                          show ? Icons.filter_list_rounded : Icons.filter_list_off_rounded,
                                                          color: show ? _primaryColor : (isDark ? Colors.white : Colors.black87),
                                                        ),
                                                        onPressed: () => SettingsController.instance.setShowFilterTabs(!show),
                                                        tooltip: show ? "Sembunyikan Filter" : "Tampilkan Filter",
                                                      ),
                                                    );
                                                  },
                                                ),
                                                if (!_isSidebarVisible) ...[
                                                  const SizedBox(width: 12),
                                                  Container(
                                                    decoration: BoxDecoration(
                                                      color: isDark ? Colors.white10 : Colors.white,
                                                      borderRadius: BorderRadius.circular(15),
                                                      border: Border.all(
                                                        color: isDark ? const Color(0xFF374151) : const Color(0xFFCBD5E1), width: 1.2,
                                                      ),
                                                    ),
                                                    child: Stack(
                                                      clipBehavior: Clip.none,
                                                      children: [
                                                        IconButton(
                                                          icon: const Icon(Icons.shopping_cart_outlined),
                                                          color: _primaryColor,
                                                          onPressed: () => setState(() => _isSidebarVisible = true),
                                                          tooltip: "Buka Keranjang",
                                                        ),
                                                        if (_cartItems.isNotEmpty)
                                                          Positioned(
                                                            top: 2,
                                                            right: 2,
                                                            child: Container(
                                                              padding: const EdgeInsets.all(4),
                                                              decoration: BoxDecoration(
                                                                color: Colors.redAccent,
                                                                shape: BoxShape.circle,
                                                                border: Border.all(color: Colors.white, width: 1.5),
                                                              ),
                                                              constraints: const BoxConstraints(
                                                                minWidth: 16,
                                                                minHeight: 16,
                                                              ),
                                                              child: Text(
                                                                "${_cartItems.fold<int>(0, (sum, it) => sum + (it['quantity'] as int))}",
                                                                style: const TextStyle(
                                                                  color: Colors.white,
                                                                  fontSize: 9,
                                                                  fontWeight: FontWeight.bold,
                                                                ),
                                                                textAlign: TextAlign.center,
                                                              ),
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            );
                                            if (needsScroll) {
                                              return SingleChildScrollView(
                                                scrollDirection: Axis.horizontal,
                                                physics: const BouncingScrollPhysics(),
                                                child: SizedBox(
                                                  width: minHeaderWidth,
                                                  child: rowContent,
                                                ),
                                              );
                                            }
                                            return rowContent;
                                          },
                                        ),
                                      ),
                                      if (_promoCategories.isNotEmpty)
                                        SizedBox(
                                            height: 64,
                                            child: ListView(
                                              scrollDirection: Axis.horizontal,
                                              padding: const EdgeInsets.symmetric(horizontal: 24),
                                              children: [
                                                ..._promoCategories.asMap().entries.map((entry) {
                                                  final i = entry.key;
                                                  final p = entry.value;
                                                  final promoColor = _promoColors[i % _promoColors.length];
                                                  final isPromoSelected = _selectedPromoIndex == i;
                                                  final valueStr = p['discountType'] == 'percentage'
                                                      ? '${(p['value'] as double).toStringAsFixed(0)}% OFF'
                                                      : 'Diskon';
                                                  return Center(
                                                    child: Padding(
                                                      padding: const EdgeInsets.only(right: 12),
                                                      child: GestureDetector(
                                                        onTap: () => setState(() {
                                                          _selectedPromoIndex = isPromoSelected ? -1 : i;
                                                          if (!isPromoSelected) _selectedCategory = "Semua";
                                                        }),
                                                        child: AnimatedContainer(
                                                          duration: const Duration(milliseconds: 200),
                                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                                          decoration: BoxDecoration(
                                                            color: isPromoSelected ? promoColor : promoColor.withValues(alpha: 0.1),
                                                            borderRadius: BorderRadius.circular(16),
                                                            border: Border.all(color: promoColor, width: 2),
                                                            boxShadow: [
                                                              if (isPromoSelected)
                                                                BoxShadow(
                                                                  color: promoColor.withValues(alpha: 0.3),
                                                                  blurRadius: 10,
                                                                  offset: const Offset(0, 4),
                                                                ),
                                                            ],
                                                          ),
                                                          child: Row(
                                                            mainAxisSize: MainAxisSize.min,
                                                            children: [
                                                              Icon(
                                                                Icons.local_offer_rounded,
                                                                size: 16,
                                                                color: isPromoSelected ? Colors.white : promoColor,
                                                              ),
                                                              const SizedBox(width: 8),
                                                              Text(
                                                                '${p['name']}  ·  $valueStr',
                                                                style: GoogleFonts.openSans(
                                                                  fontSize: 13,
                                                                  fontWeight: FontWeight.w600,
                                                                  color: isPromoSelected ? Colors.white : promoColor,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                }),
                                              ],
                                            ),
                                        ),
                                      ValueListenableBuilder<bool>(
                                        valueListenable: SettingsController.instance.showFilterTabs,
                                        builder: (context, show, _) {
                                          if (!show) return const SizedBox.shrink();
                                          return Padding(
                                            padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
                                            child: Row(
                                              children: [
                                                _buildFilterTab("Popular", _selectedFilter == "Popular"),
                                                const SizedBox(width: 24),
                                                _buildFilterTab("Recent", _selectedFilter == "Recent"),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            ValueListenableBuilder<bool>(
                                              valueListenable: SettingsController.instance.showFilterTabs,
                                              builder: (context, show, _) {
                                                if (!show) return const SizedBox.shrink();
                                                return _buildNewArrivalsStrip();
                                              },
                                            ),
                                            Expanded(
                                              child: ProductGrid(
                                                storeId: _storeId!,
                                                searchQuery: _searchQuery,
                                                categoryFilter: _selectedPromoIndex >= 0
                                                    ? null
                                                    : (_selectedCategory == "Semua" ? "Semua" : _categoryMap[_selectedCategory]),
                                                promoProductIds: _selectedPromoIndex >= 0
                                                    ? (_promoCategories[_selectedPromoIndex]['isAllProducts'] as bool
                                                        ? null
                                                        : _promoCategories[_selectedPromoIndex]['productIds'] as Set<String>)
                                                    : null,
                                                promoCategoryIds: _selectedPromoIndex >= 0
                                                    ? (_promoCategories[_selectedPromoIndex]['isAllProducts'] as bool
                                                        ? null
                                                        : _promoCategories[_selectedPromoIndex]['categoryIds'] as Set<String>)
                                                    : null,
                                                filterType: _selectedFilter,
                                                salesMap: _salesMap,
                                                recentProductIds: _recentProductIds,
                                                isGridView: _isGridView,
                                                onItemTap: (Product product) {
                                                  _handleProductSelection(product);
                                                  setState(() {});
                                                },
                                                actionBuilder: (context, Product p) => _buildActionIcon(p),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                            if (_isSidebarVisible)
                              Expanded(
                                flex: constraints.maxWidth < 1024 ? 4 : 3,
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border(
                                      left: BorderSide(
                                        color: isDark ? const Color(0xFF374151) : const Color(0xFFCBD5E1), width: 1.2,
                                      ),
                                    ),
                                  ),
                                  child: CartSidebar(
                                    searchController: _searchController,
                                    onSearchChanged: (val) => setState(
                                      () => _searchQuery = val.toLowerCase(),
                                    ),
                                    onSearchSubmitted: _searchAndAddBySku,
                                    onSearchClear: () {
                                      setState(() {
                                        _searchController.clear();
                                        _searchQuery = "";
                                      });
                                    },
                                    cartItems: _cartItems,
                                    isProcessing: _isProcessing,
                                    discountData: _discountData,
                                    isGridView: _isGridView,
                                    onToggleGrid: () {
                                      final newValue = !_isGridView;
                                      setState(() => _isGridView = newValue);
                                      SettingsController.instance.setGridView(newValue);
                                    },
                                    onModeChanged: (isPayment) {
                                      setState(() {
                                        _isPaymentFullscreen = isPayment;
                                        if (isPayment) _isSidebarVisible = true;
                                      });
                                    },
                                    onRemoveItem: (cartId) {
                                      _removeFromCart(cartId);
                                      setState(() {});
                                    },
                                    onAddItem: (Product product, {options, notes, price}) {
                                      _handleProductSelection(product, options: options, notes: notes, price: price);
                                      setState(() {});
                                    },
                                    onCheckout: (cash, method, {status, splitPayments, discount}) {
                                      setState(() {
                                        _cashReceived = cash;
                                        _selectedPaymentMethod = method;
                                        _splitPaymentsData = splitPayments;
                                      });
                                      _processCheckout(status: status, splitPayments: splitPayments, appliedDiscount: discount);
                                    },
                                    onAbortTransaction: () {
                                      setState(() {
                                        _cartItems.clear();
                                        _cashReceived = 0;
                                        _selectedCustomer = null;
                                        _lastModifiedCartId = null;
                                        _isPaymentFullscreen = false;
                                        _isSidebarVisible = false;
                                        _discountData = {
                                          'total_discount': 0.0,
                                          'promo_count': 0,
                                          'promo_names': [],
                                        };
                                      });
                                    },
                                    selectedCustomer: _selectedCustomer,
                                    onCustomerSelected: (cust) async {
                                      setState(() => _selectedCustomer = cust);
                                      await _recalculateDiscounts();
                                    },
                                    onClose: () => setState(() => _isSidebarVisible = false),
                                    lastModifiedCartId: _lastModifiedCartId,
                                    onHoldCart: _holdCurrentCart,
                                     onSplitItems: (bill1, bill2) {
                                       // Hold bill2 as a separate queued cart
                                       final String label = 'Split Bill 2 (${DateFormat('HH:mm').format(DateTime.now())})';
                                       _heldCarts.add({
                                         'label': label,
                                         'items': List<Map<String, dynamic>>.from(bill2),
                                         'customer': _selectedCustomer,
                                         'discountData': Map<String, dynamic>.from(_discountData),
                                         'timestamp': DateTime.now(),
                                       });
                                       // Replace current cart with bill1
                                       setState(() {
                                         _cartItems.clear();
                                         _cartItems.addAll(bill1);
                                         _discountData = {'total_discount': 0.0, 'promo_count': 0, 'promo_names': []};
                                       });
                                       _recalculateDiscounts();
                                       _showTopNotification('Bill dibagi! Bill ke-2 ada di antrean.', color: Colors.deepPurple);
                                     },
                                  ),
                                ),
                              ),
                          ],
                        );
                      } else {
                        return Stack(
                          children: [
                            Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: BigSearchBar(
                                          controller: _searchController,
                                          autoFocus: true,
                                          hintText: "Cari menu...",
                                          onChanged: (val) => setState(
                                            () => _searchQuery = val.toLowerCase(),
                                          ),
                                          onClear: () {
                                            setState(() {
                                              _searchController.clear();
                                              _searchQuery = "";
                                            });
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      _buildCategoryDropdown(isDark, isMobile: true),
                                    ],
                                  ),
                                ),
                                ValueListenableBuilder<bool>(
                                  valueListenable: SettingsController.instance.showFilterTabs,
                                  builder: (context, show, _) {
                                    if (!show || _promoCategories.isEmpty) return const SizedBox.shrink();
                                    return SizedBox(
                                      height: 64,
                                      child: ListView(
                                        scrollDirection: Axis.horizontal,
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        children: [
                                          ..._promoCategories.asMap().entries.map((entry) {
                                            final i = entry.key;
                                            final p = entry.value;
                                            final promoColor = _promoColors[i % _promoColors.length];
                                            final isPromoSelected = _selectedPromoIndex == i;
                                            final valueStr = p['discountType'] == 'percentage'
                                                ? '${(p['value'] as double).toStringAsFixed(0)}% OFF'
                                                : 'Diskon';
                                            return Padding(
                                              padding: const EdgeInsets.only(right: 8, bottom: 4, top: 4),
                                              child: GestureDetector(
                                                onTap: () => setState(() {
                                                  _selectedPromoIndex = isPromoSelected ? -1 : i;
                                                  if (!isPromoSelected) _selectedCategory = "Semua";
                                                }),
                                                child: AnimatedContainer(
                                                  duration: const Duration(milliseconds: 200),
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                  decoration: BoxDecoration(
                                                    color: isPromoSelected ? promoColor : promoColor.withValues(alpha: 0.1),
                                                    borderRadius: BorderRadius.circular(20),
                                                    border: Border.all(color: promoColor, width: 1.5),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons.local_offer_rounded,
                                                        size: 12,
                                                        color: isPromoSelected ? Colors.white : promoColor,
                                                      ),
                                                      const SizedBox(width: 5),
                                                      Text(
                                                        '${p['name']}  ·  $valueStr',
                                                        style: GoogleFonts.openSans(
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.w600,
                                                          color: isPromoSelected ? Colors.white : promoColor,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            );
                                          }),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                Expanded(
                                  child: ProductGrid(
                                    storeId: _storeId!,
                                    searchQuery: _searchQuery,
                                    categoryFilter: _selectedPromoIndex >= 0
                                        ? null
                                        : (_selectedCategory == "Semua" ? "Semua" : _categoryMap[_selectedCategory]),
                                    promoProductIds: _selectedPromoIndex >= 0
                                        ? (_promoCategories[_selectedPromoIndex]['isAllProducts'] as bool
                                            ? null
                                            : _promoCategories[_selectedPromoIndex]['productIds'] as Set<String>)
                                        : null,
                                    promoCategoryIds: _selectedPromoIndex >= 0
                                        ? (_promoCategories[_selectedPromoIndex]['isAllProducts'] as bool
                                            ? null
                                            : _promoCategories[_selectedPromoIndex]['categoryIds'] as Set<String>)
                                        : null,
                                    filterType: _selectedFilter,
                                    salesMap: _salesMap,
                                    recentProductIds: _recentProductIds,
                                    isGridView: _isGridView,
                                    onItemTap: (Product product) {
                                      _handleProductSelection(product);
                                      setState(() {});
                                    },
                                    actionBuilder: (context, Product p) => _buildActionIcon(p),
                                  ),
                                ),
                              ],
                            ),
                            if (_cartItems.isNotEmpty)
                              Positioned(
                                bottom: 12,
                                left: 20,
                                right: 20,
                                child: GestureDetector(
                                  onTap: _showCartSheet,
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: _primaryColor,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _primaryColor.withValues(alpha: 0.4),
                                          blurRadius: 20,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.2),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Text(
                                            "${_getCartTotalCount()}",
                                            style: GoogleFonts.openSans(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                "Total",
                                                style: GoogleFonts.openSans(
                                                  color: Colors.white70,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              FittedBox(
                                                fit: BoxFit.scaleDown,
                                                alignment: Alignment.centerLeft,
                                                child: Text(
                                                  _currencyFormat.format(_getCartTotal()),
                                                  style: GoogleFonts.plusJakartaSans(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Spacer(),
                                        const Icon(Icons.shopping_bag_outlined, color: Colors.white),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      }
                    },
                  ),
                  _buildTopNotification(),
                ],
              ),
      ),
    );
  }

  Widget _buildFilterTab(String label, bool isActive) {
    const primaryColor = Color(0xFFC0392B);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () => setState(() => _selectedFilter = label),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              color: isActive ? (isDark ? Colors.white : Colors.black) : Colors.grey,
            ),
          ),
          if (isActive)
            Container(
              margin: const EdgeInsets.only(top: 4),
              height: 3,
              width: 24,
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryDropdown(bool isDark, {bool isMobile = false}) {
    return Container(
      height: isMobile ? 45 : 50,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: isDark ? const Color(0xFF374151) : const Color(0xFFCBD5E1), width: 1.2),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedPromoIndex >= 0 ? null : _selectedCategory,
          hint: Text(
            "Kategori",
            style: GoogleFonts.openSans(
              fontSize: 13,
              color: isDark ? Colors.white70 : Colors.grey[600],
            ),
          ),
          dropdownColor: isDark ? const Color(0xFF1A1C1E) : Colors.white,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: isDark ? Colors.white70 : Colors.grey[600],
            size: 20,
          ),
          items: _categories.map((String cat) {
            return DropdownMenuItem<String>(
              value: cat,
              child: Text(
                cat,
                style: GoogleFonts.openSans(
                  fontSize: 13,
                  fontWeight: _selectedCategory == cat ? FontWeight.w600 : FontWeight.normal,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedCategory = newValue;
                _selectedPromoIndex = -1;
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildTopNotification() {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutBack,
      top: _notificationMessage != null ? 12 : -100,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _notificationColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _notificationColor.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _notificationMessage ?? "",
                style: GoogleFonts.openSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewArrivalsStrip() {
    if (_searchQuery.isNotEmpty || _selectedPromoIndex >= 0 || _selectedCategory != "Semua") {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final db = Provider.of<AppDatabase>(context, listen: false);

    return StreamBuilder<List<Product>>(
      stream: (db.select(db.products)
            ..where((t) => t.storeId.equals(_storeId ?? ''))
            ..where((t) => t.isDeleted.equals(false))
            ..orderBy([(t) => drift.OrderingTerm(expression: t.createdAt, mode: drift.OrderingMode.desc)])
            ..limit(8))
          .watch(),
      builder: (context, snapshot) {
        final products = snapshot.data ?? [];
        if (products.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.fiber_new_rounded, size: 16, color: _primaryColor),
                        const SizedBox(width: 4),
                        Text(
                          'Baru Ditambahkan',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 160,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final p = products[index];
                  final isOutOfStock = p.isStockManaged && (p.stockQuantity ?? 0) <= 0;
                  return GestureDetector(
                    onTap: isOutOfStock ? null : () => _handleProductSelection(p),
                    child: Opacity(
                      opacity: isOutOfStock ? 0.5 : 1.0,
                      child: Container(
                        width: 120,
                        margin: const EdgeInsets.only(right: 12, bottom: 4),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                              child: Container(
                                height: 90,
                                width: double.infinity,
                                color: isDark ? Colors.grey[800] : Colors.grey[100],
                                child: p.imageUrl != null
                                    ? Image(image: FileManager().getImageProvider(p.imageUrl!), fit: BoxFit.cover)
                                    : Icon(Icons.fastfood_rounded, size: 36, color: Colors.grey[400]),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.name ?? '-',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _currencyFormat.format(p.salePrice ?? 0),
                                    style: GoogleFonts.openSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: _primaryColor,
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
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: Divider(height: 8),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionIcon(Product p) {
    final isStockManaged = p.isStockManaged;
    final stockQty = p.stockQuantity ?? 0;
    final isOutOfStock = isStockManaged && stockQty <= 0;

    final qty = _cartItems
        .where((item) => (item['product'] as Product).id == p.id)
        .fold(0, (sum, item) => sum + (item['quantity'] as int));

    if (isOutOfStock) {
      return Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(color: Colors.grey[300], shape: BoxShape.circle),
        child: const Icon(Icons.block_rounded, color: Colors.white, size: 16),
      );
    }

    if (qty > 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _primaryColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: _primaryColor.withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          qty.toString(),
          style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
        ),
      );
    }

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: _primaryColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
    );
  }

  void _showCartSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          _activeSheetSetState = setSheetState;
          return SizedBox(
            height: MediaQuery.of(context).size.height,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: CartSidebar(
                searchController: _searchController,
                onSearchChanged: (val) => setState(() {
                  _searchQuery = val.toLowerCase();
                  setSheetState(() {});
                }),
                onSearchSubmitted: (val) {
                  _searchAndAddBySku(val);
                  setSheetState(() {});
                },
                onSearchClear: () {
                  setState(() {
                    _searchController.clear();
                    _searchQuery = "";
                  });
                  setSheetState(() {});
                },
                cartItems: _cartItems,
                isProcessing: _isProcessing,
                discountData: _discountData,
                onRemoveItem: (cartId) {
                  _removeFromCart(cartId);
                  setSheetState(() {});
                  setState(() {});
                },
                onAddItem: (Product product, {options, notes, price}) {
                  _handleProductSelection(product, options: options, notes: notes, price: price);
                  setSheetState(() {});
                  setState(() {});
                },
                onCheckout: (cash, method, {status, splitPayments, discount}) {
                  setState(() {
                    _cashReceived = cash;
                    _selectedPaymentMethod = method;
                    _splitPaymentsData = splitPayments;
                  });
                  Navigator.pop(context);
                  _processCheckout(
                    status: status,
                    splitPayments: splitPayments,
                    appliedDiscount: discount,
                  );
                },
                onAbortTransaction: () {
                  setState(() {
                    _cartItems.clear();
                    _cashReceived = 0;
                    _selectedCustomer = null;
                    _discountData = {'total_discount': 0.0, 'promo_count': 0, 'promo_names': []};
                  });
                },
                selectedCustomer: _selectedCustomer,
                onCustomerSelected: (cust) async {
                  setSheetState(() => _selectedCustomer = cust);
                  setState(() => _selectedCustomer = cust);
                  await _recalculateDiscounts();
                  if (ctx.mounted) {
                    setSheetState(() {});
                  }
                },
                onHoldCart: () {
                  Navigator.pop(context);
                  _holdCurrentCart();
                },
                onSplitItems: (bill1, bill2) {
                  Navigator.pop(context);
                  final String label = 'Split Bill 2 (${DateFormat('HH:mm').format(DateTime.now())})';
                  _heldCarts.add({
                    'label': label,
                    'items': List<Map<String, dynamic>>.from(bill2),
                    'customer': _selectedCustomer,
                    'discountData': Map<String, dynamic>.from(_discountData),
                    'timestamp': DateTime.now(),
                  });
                  setState(() {
                    _cartItems.clear();
                    _cartItems.addAll(bill1);
                    _discountData = {'total_discount': 0.0, 'promo_count': 0, 'promo_names': []};
                  });
                  _recalculateDiscounts();
                  _showTopNotification('Bill dibagi! Bill ke-2 ada di antrean.', color: Colors.deepPurple);
                },
              ),
            ),
          );
        },
      ),
    ).whenComplete(() {
      _activeSheetSetState = null;
    });
  }

  Widget _buildSecondaryHeaderAction({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool isActive = false,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive 
              ? _primaryColor.withValues(alpha: 0.1) 
              : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive 
                ? _primaryColor.withValues(alpha: 0.3) 
                : (isDark ? const Color(0xFF374151) : const Color(0xFFCBD5E1)), width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon, 
              size: 20, 
              color: isActive ? _primaryColor : (isDark ? Colors.white70 : Colors.black54)
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isActive ? _primaryColor : (isDark ? Colors.white70 : Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

