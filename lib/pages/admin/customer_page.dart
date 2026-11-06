import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' show OrderingTerm, Value;
import '../../services/app_database.dart';
import '../../services/customer_service.dart';
import '../../services/supplier_service.dart';
import '../../services/payment_method_service.dart';
import '../../controllers/admin_controller.dart';
import '../../widgets/kasir_dialog.dart';
import '../../widgets/activity_detail_sheet.dart';
import '../../widgets/transaction_result_dialog.dart';

class _UnifiedContactItem {
  final String id;
  final String name;
  final String phone;
  final String addressOrNotes;
  final bool isSupplier;
  final double piutang;
  final double hutang;
  final Customer? customerSource;
  final Supplier? supplierSource;

  _UnifiedContactItem({
    required this.id,
    required this.name,
    required this.phone,
    required this.addressOrNotes,
    required this.isSupplier,
    required this.piutang,
    required this.hutang,
    this.customerSource,
    this.supplierSource,
  });
}

class _ContactHistoryEntry {
  final String id;
  final String badgeLabel;
  final Color badgeBgColor;
  final Color badgeTextColor;
  final String code;
  final String? secondaryBadge;
  final Color? secondaryBadgeBg;
  final Color? secondaryBadgeText;
  final String subtitle;
  final DateTime date;
  final String amountText;
  final Color amountColor;
  final Transaction? rawTransaction;
  final SupplierTransaction? rawSupplierTx;
  final Expense? rawExpense;

  _ContactHistoryEntry({
    required this.id,
    required this.badgeLabel,
    required this.badgeBgColor,
    required this.badgeTextColor,
    required this.code,
    this.secondaryBadge,
    this.secondaryBadgeBg,
    this.secondaryBadgeText,
    required this.subtitle,
    required this.date,
    required this.amountText,
    required this.amountColor,
    this.rawTransaction,
    this.rawSupplierTx,
    this.rawExpense,
  });
}

class CustomerPage extends StatefulWidget {
  final VoidCallback? onMenuPressed;
  final VoidCallback? onBack;
  final Function(int)? onNavigateToIndex;
  final String initialRoleFilter; // 'Semua', 'Pelanggan', 'Supplier'

  const CustomerPage({
    super.key,
    this.onMenuPressed,
    this.onBack,
    this.onNavigateToIndex,
    this.initialRoleFilter = 'Semua',
  });

  @override
  State<CustomerPage> createState() => _CustomerPageState();
}

class _CustomerPageState extends State<CustomerPage> {
  static const Color _primaryGreen = Color(0xFF00BF63);
  static const Color _accentGreen = Color(0xFF00BF63);

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  final TextEditingController _searchController = TextEditingController();
  late CustomerService _customerService;
  late SupplierService _supplierService;
  late PaymentMethodService _paymentMethodService;

  bool _isLoading = true;
  String _roleFilter = 'Semua'; // 'Semua', 'Pelanggan', 'Supplier'
  String _searchQuery = '';

  List<_UnifiedContactItem> _allContacts = [];
  List<Transaction> _allStoreTransactions = [];
  List<Expense> _allStoreExpenses = [];
  List<SupplierTransaction> _allSupplierTransactions = [];
  List<PaymentMethod> _activePaymentMethods = [];
  Map<String, double> _methodBalances = {};

  double _totalPiutang = 0.0;
  double _totalHutang = 0.0;

  @override
  void initState() {
    super.initState();
    _roleFilter = widget.initialRoleFilter;
    final db = context.read<AppDatabase>();
    _customerService = CustomerService(db);
    _supplierService = SupplierService(db);
    _paymentMethodService = PaymentMethodService(db);
    _searchController.addListener(() {
      if (mounted) {
        setState(() => _searchQuery = _searchController.text.trim());
      }
    });
    _loadContactsData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadContactsData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final admin = context.read<AdminController>();
      final db = context.read<AppDatabase>();
      final storeId = admin.storeId;
      if (storeId == null || storeId.isEmpty) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // 1. Fetch Customers & Suppliers
      final customers = await _customerService.getCustomers(storeId);
      final suppliers = await _supplierService.getSuppliers(storeId);

      // 2. Fetch Store Transactions (for customer sales & piutang)
      final allTxs = await (db.select(db.transactions)
            ..where((t) => t.storeId.equals(storeId))
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .get();

      // 3. Fetch Store Expenses (for Terima Piutang & mutasi)
      final allExps = await (db.select(db.expenses)
            ..where((e) => e.storeId.equals(storeId))
            ..orderBy([(e) => OrderingTerm.asc(e.date)]))
          .get();

      // 4. Fetch Supplier Transactions
      final allSupTxs = await _supplierService.getAllStoreTransactions(storeId);

      // 5. Fetch Payment Methods & Current Balances
      await _paymentMethodService.ensureDefaultPaymentMethods(storeId);
      final methods = await _paymentMethodService.getPaymentMethods(storeId);
      final activeMethods = methods.where((m) => m.isActive).toList();
      final balances = await _paymentMethodService.calculateCurrentBalances(storeId);

      // 6. Compute Customer Piutang
      final debtTxs = allTxs.where((t) => t.status == 'debt').toList();
      double sumPiutang = 0.0;
      final Map<String, double> piutangByCustomerId = {};
      final Map<String, double> piutangByCustomerName = {};

      for (final dtx in debtTxs) {
        final rem = ((dtx.totalAmount ?? 0.0) - (dtx.cashReceived ?? 0.0)).clamp(0.0, double.infinity);
        if (rem <= 0) continue;
        sumPiutang += rem;
        if (dtx.customerId != null && dtx.customerId!.isNotEmpty) {
          piutangByCustomerId[dtx.customerId!] = (piutangByCustomerId[dtx.customerId!] ?? 0.0) + rem;
        } else if (dtx.customerName != null && dtx.customerName!.trim().isNotEmpty) {
          final key = dtx.customerName!.trim().toLowerCase();
          piutangByCustomerName[key] = (piutangByCustomerName[key] ?? 0.0) + rem;
        }
      }

      // 7. Build Unified Contact List
      final List<_UnifiedContactItem> unified = [];
      final Set<String> matchedCustomerNames = {};

      for (final c in customers) {
        final cName = (c.name ?? 'Pelanggan').trim();
        final cKey = cName.toLowerCase();
        double cPiutang = piutangByCustomerId[c.id] ?? 0.0;
        if (piutangByCustomerName.containsKey(cKey)) {
          cPiutang += piutangByCustomerName[cKey]!;
          matchedCustomerNames.add(cKey);
        }
        unified.add(_UnifiedContactItem(
          id: c.id,
          name: cName,
          phone: (c.phoneNumber ?? '').trim(),
          addressOrNotes: (c.email ?? '').trim(),
          isSupplier: false,
          piutang: cPiutang,
          hutang: 0.0,
          customerSource: c,
        ));
      }

      // Include any debt customerName not yet in db.customers
      piutangByCustomerName.forEach((key, remAmt) {
        if (!matchedCustomerNames.contains(key) && remAmt > 0) {
          final sampleTx = debtTxs.firstWhere(
            (t) => (t.customerName ?? '').trim().toLowerCase() == key,
            orElse: () => debtTxs.first,
          );
          final displayName = (sampleTx.customerName ?? 'Pelanggan').trim();
          unified.add(_UnifiedContactItem(
            id: 'debt_cust_$key',
            name: displayName,
            phone: '',
            addressOrNotes: '',
            isSupplier: false,
            piutang: remAmt,
            hutang: 0.0,
          ));
        }
      });

      double sumHutang = 0.0;
      for (final s in suppliers) {
        final sHutang = s.unpaidBalance > 0 ? s.unpaidBalance : 0.0;
        sumHutang += sHutang;
        String latestTxNote = '';
        for (final stx in allSupTxs) {
          if (stx.supplierId == s.id && (stx.notes ?? '').trim().isNotEmpty) {
            latestTxNote = stx.notes!.trim();
            break;
          }
        }
        final baseNotes = (s.address ?? s.notes ?? '').trim();
        final combinedNotes = baseNotes.isNotEmpty ? baseNotes : latestTxNote;
        unified.add(_UnifiedContactItem(
          id: s.id,
          name: s.name.trim(),
          phone: (s.phone ?? '').trim(),
          addressOrNotes: combinedNotes,
          isSupplier: true,
          piutang: 0.0,
          hutang: sHutang,
          supplierSource: s,
        ));
      }

      // Sort: contacts with hutang/piutang > 0 first, then alphabetical
      unified.sort((a, b) {
        final aActive = (a.hutang + a.piutang) > 0 ? 1 : 0;
        final bActive = (b.hutang + b.piutang) > 0 ? 1 : 0;
        if (aActive != bActive) return bActive.compareTo(aActive);
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

      if (mounted) {
        setState(() {
          _allContacts = unified;
          _allStoreTransactions = allTxs;
          _allStoreExpenses = allExps;
          _allSupplierTransactions = allSupTxs;
          _activePaymentMethods = activeMethods;
          _methodBalances = balances;
          _totalPiutang = sumPiutang;
          _totalHutang = sumHutang;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading unified contacts: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<_UnifiedContactItem> get _filteredContacts {
    return _allContacts.where((item) {
      if (_roleFilter == 'Pelanggan' && item.isSupplier) return false;
      if (_roleFilter == 'Supplier' && !item.isSupplier) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchName = item.name.toLowerCase().contains(q);
        final matchPhone = item.phone.toLowerCase().contains(q);
        final matchAddr = item.addressOrNotes.toLowerCase().contains(q);
        return matchName || matchPhone || matchAddr;
      }
      return true;
    }).toList();
  }

  List<_ContactHistoryEntry> _buildHistoryForContact(_UnifiedContactItem contact) {
    final List<_ContactHistoryEntry> entries = [];

    if (contact.isSupplier && contact.supplierSource != null) {
      final sup = contact.supplierSource!;
      final supTxs = _allSupplierTransactions
          .where((t) => t.supplierId == sup.id)
          .toList();

      for (final stx in supTxs) {
        final cleanNote = (stx.notes ?? '').trim();
        final noteSuffix = cleanNote.isNotEmpty ? ' · $cleanNote' : '';
        if (stx.type == 'purchase') {
          final isHutang = stx.paymentStatus.toLowerCase() == 'hutang';
          final paid = stx.paidAmount;
          final payNote = paid > 0 && isHutang
              ? ' · Dibayar ${_currencyFormat.format(paid)}'
              : (paid > 0 ? ' · Lunas' : ' · Belum dibayar');
          entries.add(_ContactHistoryEntry(
            id: stx.id,
            badgeLabel: 'PEMBELIAN',
            badgeBgColor: const Color(0xFFE0F2FE),
            badgeTextColor: const Color(0xFF0369A1),
            code: stx.transactionNo,
            secondaryBadge: isHutang ? 'HUTANG' : 'LUNAS',
            secondaryBadgeBg: isHutang ? const Color(0xFFFFF1F2) : const Color(0xFFECFDF5),
            secondaryBadgeText: isHutang ? const Color(0xFFBE123C) : const Color(0xFF047857),
            subtitle: 'Supplier: ${sup.name}$payNote$noteSuffix',
            date: stx.createdAt,
            amountText: _currencyFormat.format(stx.totalAmount),
            amountColor: const Color(0xFFE05260),
            rawSupplierTx: stx,
          ));
        } else if (stx.type == 'payment') {
          final mName = (stx.paymentMethod != null && stx.paymentMethod!.isNotEmpty)
              ? stx.paymentMethod!
              : 'Kas';
          entries.add(_ContactHistoryEntry(
            id: stx.id,
            badgeLabel: 'BAYAR HUTANG',
            badgeBgColor: const Color(0xFFFFF1F2),
            badgeTextColor: const Color(0xFFBE123C),
            code: stx.transactionNo,
            subtitle: 'Ke ${sup.name} · $mName$noteSuffix',
            date: stx.createdAt,
            amountText: '-${_currencyFormat.format(stx.totalAmount)}',
            amountColor: const Color(0xFFE05260),
            rawSupplierTx: stx,
          ));
        } else if (stx.type == 'return') {
          entries.add(_ContactHistoryEntry(
            id: stx.id,
            badgeLabel: 'RETUR',
            badgeBgColor: const Color(0xFFF3E8FF),
            badgeTextColor: const Color(0xFF7E22CE),
            code: stx.transactionNo,
            subtitle: 'Ke ${sup.name}$noteSuffix',
            date: stx.createdAt,
            amountText: '-${_currencyFormat.format(stx.totalAmount)}',
            amountColor: const Color(0xFF7E22CE),
            rawSupplierTx: stx,
          ));
        }
      }
    } else {
      // Customer history: sales (PJ-xxxx) + Terima Piutang (TP-xxxx)
      final cId = contact.customerSource?.id;
      final cNameLower = contact.name.toLowerCase();

      for (int i = 0; i < _allStoreTransactions.length; i++) {
        final tx = _allStoreTransactions[i];
        final matchId = cId != null && tx.customerId == cId;
        final matchName = (tx.customerName ?? '').trim().toLowerCase() == cNameLower;
        if (!matchId && !matchName) continue;

        final pjNo = 'PJ-${(i + 1).toString().padLeft(4, '0')}';
        final isDebt = tx.status == 'debt';
        entries.add(_ContactHistoryEntry(
          id: tx.id,
          badgeLabel: 'PENJUALAN',
          badgeBgColor: const Color(0xFFD1FAE5),
          badgeTextColor: const Color(0xFF047857),
          code: pjNo,
          secondaryBadge: isDebt ? 'PIUTANG' : null,
          secondaryBadgeBg: isDebt ? const Color(0xFFFEF3C7) : null,
          secondaryBadgeText: isDebt ? const Color(0xFFB45309) : null,
          subtitle: 'Pelanggan: ${contact.name}',
          date: tx.createdAt ?? DateTime.now(),
          amountText: _currencyFormat.format(tx.totalAmount ?? 0),
          amountColor: isDebt ? const Color(0xFFE05260) : const Color(0xFF0D8A50),
          rawTransaction: tx,
        ));
      }

      int tpCounter = 0;
      for (final exp in _allStoreExpenses) {
        final cat = exp.category.trim().toLowerCase();
        final notes = exp.notes ?? '';
        if (cat.contains('piutang')) {
          tpCounter++;
          if (notes.toLowerCase().contains(cNameLower)) {
            String methodLabel = 'Kas';
            for (final m in _activePaymentMethods) {
              if (notes.contains('[${m.name}]') || notes.toLowerCase().contains(m.name.toLowerCase())) {
                methodLabel = m.name;
                break;
              }
            }
            entries.add(_ContactHistoryEntry(
              id: exp.id,
              badgeLabel: 'TERIMA PIUTANG',
              badgeBgColor: const Color(0xFFD1FAE5),
              badgeTextColor: const Color(0xFF047857),
              code: 'TP-${tpCounter.toString().padLeft(4, '0')}',
              subtitle: 'Pelanggan: ${contact.name} · $methodLabel',
              date: exp.date ?? DateTime.now(),
              amountText: '+${_currencyFormat.format(exp.amount ?? 0)}',
              amountColor: const Color(0xFF047857),
              rawExpense: exp,
            ));
          }
        }
      }
    }

    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries;
  }

  bool _contactHasHistory(_UnifiedContactItem contact) {
    // 1. Periksa riwayat yang sudah tergenerate untuk kontak ini
    final history = _buildHistoryForContact(contact);
    if (history.isNotEmpty) return true;

    // 2. Periksa sisa saldo hutang atau piutang berjalan
    if (contact.hutang > 0 || contact.piutang > 0) return true;

    // 3. Periksa seluruh transaksi penjualan toko yang terkait dengan pelanggan ini
    final cNameLower = contact.name.trim().toLowerCase();
    final cId = contact.customerSource?.id;
    final hasTx = _allStoreTransactions.any((t) {
      final matchId = cId != null && t.customerId == cId;
      final matchName = (t.customerName ?? '').trim().toLowerCase() == cNameLower;
      return matchId || matchName;
    });
    if (hasTx) return true;

    // 4. Periksa seluruh transaksi supplier yang terkait
    if (contact.supplierSource != null) {
      final sId = contact.supplierSource!.id;
      final hasSupTx = _allSupplierTransactions.any((t) => t.supplierId == sId);
      if (hasSupTx) return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = _filteredContacts;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF4F6F0),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: (widget.onBack != null || Navigator.canPop(context))
            ? IconButton(
                icon: Icon(
                  Icons.arrow_back_rounded,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                onPressed: () {
                  if (widget.onBack != null) {
                    widget.onBack!();
                  } else if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                },
              )
            : null,
        title: Text(
          "Pelanggan & Supplier",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CupertinoActivityIndicator())
          : RefreshIndicator(
              onRefresh: _loadContactsData,
              color: _accentGreen,
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // 1. Search Bar + Tombol Tambah (+) Hijau
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                                  width: 1.2,
                                ),
                              ),
                              child: TextField(
                                controller: _searchController,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                                decoration: InputDecoration(
                                  hintText: "Cari kontak...",
                                  hintStyle: GoogleFonts.openSans(
                                    fontSize: 13.5,
                                    color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                                  ),
                                  prefixIcon: Icon(
                                    Icons.search_rounded,
                                    size: 20,
                                    color: isDark ? Colors.white54 : const Color(0xFF64748B),
                                  ),
                                  suffixIcon: _searchQuery.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear_rounded, size: 18),
                                          onPressed: () => _searchController.clear(),
                                        )
                                      : null,
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          InkWell(
                            onTap: () => _showAddOrEditContactSheet(),
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: _primaryGreen,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFF064E3B),
                                  width: 1.2,
                                ),
                              ),
                              child: const Icon(
                                Icons.add_rounded,
                                color: Colors.white,
                                size: 26,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // 2. Role Filter Pills (Semua, Pelanggan, Supplier)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildRoleFilterPill("Semua", isDark),
                            const SizedBox(width: 8),
                            _buildRoleFilterPill("Pelanggan", isDark),
                            const SizedBox(width: 8),
                            _buildRoleFilterPill("Supplier", isDark),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 3. 2-Column Summary Cards: TOTAL PIUTANG & TOTAL HUTANG
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "TOTAL PIUTANG",
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.4,
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      _currencyFormat.format(_totalPiutang),
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 21,
                                        fontWeight: FontWeight.w800,
                                        color: _totalPiutang > 0
                                            ? _primaryGreen
                                            : (isDark ? Colors.white : const Color(0xFF0F172A)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "uang di pelanggan",
                                    style: GoogleFonts.openSans(
                                      fontSize: 11.5,
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "TOTAL HUTANG",
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.4,
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      _currencyFormat.format(_totalHutang),
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 21,
                                        fontWeight: FontWeight.w800,
                                        color: _totalHutang > 0
                                            ? const Color(0xFFE05260)
                                            : (isDark ? Colors.white : const Color(0xFF0F172A)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "ke supplier",
                                    style: GoogleFonts.openSans(
                                      fontSize: 11.5,
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 4. Container Card Kontak (Pelanggan & Supplier) - Versi Kita
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Bagian
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 13, 16, 11),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        _roleFilter == 'Pelanggan'
                                            ? "Daftar Pelanggan"
                                            : (_roleFilter == 'Supplier'
                                                ? "Daftar Supplier"
                                                : "Pelanggan & Supplier"),
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                        decoration: BoxDecoration(
                                          color: _primaryGreen.withValues(alpha: isDark ? 0.2 : 0.1),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          "${filtered.length} Kontak",
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: _primaryGreen,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  InkWell(
                                    onTap: () => _showAddOrEditContactSheet(),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.add_circle_outline_rounded, size: 14, color: _primaryGreen),
                                          const SizedBox(width: 4),
                                          Text(
                                            "Tambah",
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: _primaryGreen,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Divider(height: 1, color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),

                            // List Kontak atau Tampilan Kosong
                            if (filtered.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                                child: Center(
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.people_outline_rounded,
                                        size: 40,
                                        color: isDark ? Colors.white30 : const Color(0xFF94A3B8),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        "Belum ada kontak yang sesuai.",
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: filtered.length,
                                separatorBuilder: (_, __) => Divider(
                                  height: 1,
                                  color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                                ),
                                itemBuilder: (context, index) {
                                  return _buildContactRow(filtered[index], isDark);
                                },
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildRoleFilterPill(String label, bool isDark) {
    final isSelected = _roleFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _roleFilter = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected
              ? _primaryGreen
              : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? _primaryGreen
                : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : const Color(0xFF334155)),
          ),
        ),
      ),
    );
  }

  Widget _buildContactRow(_UnifiedContactItem contact, bool isDark) {
    final isSup = contact.isSupplier;
    final avatarBg = isSup
        ? (isDark ? const Color(0xFF0369A1).withValues(alpha: 0.2) : const Color(0xFFE0F2FE))
        : (isDark ? const Color(0xFF00BF63).withValues(alpha: 0.2) : const Color(0xFFECFDF5));
    final avatarColor = isSup ? const Color(0xFF0284C7) : const Color(0xFF00BF63);

    final double balanceValue = isSup ? contact.hutang : contact.piutang;
    final String balanceCaption = isSup
        ? (contact.hutang > 0 ? "Hutang Toko" : "Lunas")
        : (contact.piutang > 0 ? "Piutang" : "Lunas");
    final Color balanceColor = balanceValue > 0
        ? (isSup ? const Color(0xFFE05260) : const Color(0xFF00BF63))
        : (isDark ? Colors.white54 : const Color(0xFF94A3B8));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showContactDetailSheet(contact),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar Icon
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: avatarBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isSup ? Icons.storefront_rounded : Icons.person_rounded,
                  size: 20,
                  color: avatarColor,
                ),
              ),
              const SizedBox(width: 12),

              // Detail Kontak
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            contact.name,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: avatarBg,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            isSup ? "SUPPLIER" : "PELANGGAN",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w700,
                              color: avatarColor,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (contact.phone.isNotEmpty) ...[
                          Icon(
                            Icons.phone_outlined,
                            size: 11,
                            color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            contact.phone,
                            style: GoogleFonts.openSans(
                              fontSize: 11.5,
                              color: isDark ? Colors.white60 : const Color(0xFF64748B),
                            ),
                          ),
                          if (contact.addressOrNotes.isNotEmpty) ...[
                            Text(
                              " · ",
                              style: TextStyle(color: isDark ? Colors.white38 : const Color(0xFF94A3B8)),
                            ),
                          ],
                        ],
                        if (contact.addressOrNotes.isNotEmpty)
                          Expanded(
                            child: Text(
                              contact.addressOrNotes,
                              style: GoogleFonts.openSans(
                                fontSize: 11.5,
                                color: isDark ? Colors.white60 : const Color(0xFF64748B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          )
                        else if (contact.phone.isEmpty)
                          Text(
                            "-",
                            style: GoogleFonts.openSans(
                              fontSize: 11.5,
                              color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Saldo Hutang / Piutang
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _currencyFormat.format(balanceValue),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: balanceColor,
                    ),
                  ),
                  const SizedBox(height: 1.5),
                  Text(
                    balanceCaption,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openHistoryDetail(_ContactHistoryEntry item, _UnifiedContactItem contact, StateSetter setSheetState) {
    ActivityDetailType detailType;
    final bLower = item.badgeLabel.toLowerCase();
    if (bLower.contains('penjualan')) {
      detailType = ActivityDetailType.penjualan;
    } else if (bLower.contains('pembelian')) {
      detailType = ActivityDetailType.pembelian;
    } else if (bLower.contains('bayar hutang')) {
      detailType = ActivityDetailType.bayarHutang;
    } else if (bLower.contains('terima piutang')) {
      detailType = ActivityDetailType.terimaPiutang;
    } else {
      detailType = ActivityDetailType.biaya;
    }

    final double rawAmt = item.rawTransaction?.totalAmount ??
        item.rawSupplierTx?.totalAmount ??
        item.rawExpense?.amount ??
        0.0;

    ActivityDetailSheet.show(
      context: context,
      type: detailType,
      code: item.code,
      title: item.badgeLabel,
      date: item.date,
      amount: rawAmt,
      contactName: contact.name,
      accountName: item.rawTransaction?.paymentMethod ?? item.rawSupplierTx?.paymentMethod ?? 'Kas',
      categoryName: item.rawExpense?.category,
      notes: item.rawExpense?.notes ?? item.rawSupplierTx?.notes,
      isDebt: item.secondaryBadge?.toUpperCase() == 'PIUTANG' || item.secondaryBadge?.toUpperCase() == 'HUTANG' || item.rawTransaction?.status == 'debt',
      paidAmount: item.rawTransaction?.cashReceived ?? (item.rawSupplierTx?.paidAmount),
      remainingDebt: item.rawTransaction != null && item.rawTransaction!.status == 'debt'
          ? (((item.rawTransaction!.totalAmount ?? 0.0) - (item.rawTransaction!.cashReceived ?? 0.0)).clamp(0.0, double.infinity))
          : (item.rawSupplierTx != null
              ? ((item.rawSupplierTx!.totalAmount - item.rawSupplierTx!.paidAmount).clamp(0.0, double.infinity))
              : null),
      rawTransaction: item.rawTransaction,
      rawSupplierTx: item.rawSupplierTx,
      rawExpense: item.rawExpense,
      onRefresh: () async {
        await _loadContactsData();
        setSheetState(() {});
      },
    );
  }

  // ─── Bottom Sheet Detail Kontak (Persis Gambar 2) ─────────────────────────
  Future<void> _showContactDetailSheet(_UnifiedContactItem initialContact) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final isDark = Theme.of(ctx).brightness == Brightness.dark;
            // Ambil data terbaru dari state utama bila sudah di-refresh
            final contact = _allContacts.firstWhere(
              (c) => c.id == initialContact.id && c.isSupplier == initialContact.isSupplier,
              orElse: () => initialContact,
            );
            final isSup = contact.isSupplier;
            final badgeBg = isSup ? const Color(0xFFE0F2FE) : const Color(0xFFD1FAE5);
            final badgeText = isSup ? const Color(0xFF0369A1) : const Color(0xFF047857);
            final badgeLabel = isSup ? "SUPPLIER" : "PELANGGAN";
            final history = _buildHistoryForContact(contact);
            final dayFormat = DateFormat('EEE, d MMM yyyy', 'id_ID');

            return Align(
              alignment: Alignment.bottomCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 600,
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
                      // Header: Nama Kontak Uppercase + Tombol Close [X]
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 16, 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                contact.name.toUpperCase(),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            InkWell(
                              onTap: () => Navigator.pop(ctx),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                                    width: 1.2,
                                  ),
                                ),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 20,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Divider(height: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),

                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Info Rows: TIPE, TELP, PIUTANG, HUTANG
                              _buildDetailInfoRow(
                                label: "TIPE",
                                isDark: isDark,
                                valueWidget: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                                  decoration: BoxDecoration(
                                    color: badgeBg,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    badgeLabel,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: badgeText,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              _buildDetailInfoRow(
                                label: "TELP",
                                isDark: isDark,
                                valueWidget: Text(
                                  contact.phone.isNotEmpty ? contact.phone : "-",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              _buildDetailInfoRow(
                                label: "PIUTANG",
                                isDark: isDark,
                                valueWidget: Text(
                                  _currencyFormat.format(contact.piutang),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: contact.piutang > 0
                                        ? _primaryGreen
                                        : (isDark ? Colors.white : const Color(0xFF0F172A)),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              _buildDetailInfoRow(
                                label: "HUTANG",
                                isDark: isDark,
                                valueWidget: Text(
                                  _currencyFormat.format(contact.hutang),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: contact.hutang > 0
                                        ? const Color(0xFFE05260)
                                        : (isDark ? Colors.white : const Color(0xFF0F172A)),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              _buildDetailInfoRow(
                                label: "STATUS",
                                isDark: isDark,
                                valueWidget: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: (isSup ? contact.hutang : contact.piutang) > 0
                                        ? (isSup
                                            ? (isDark ? const Color(0xFF881337).withValues(alpha: 0.35) : const Color(0xFFFFF1F2))
                                            : (isDark ? const Color(0xFF78350F).withValues(alpha: 0.35) : const Color(0xFFFEF3C7)))
                                        : (isDark ? const Color(0xFF064E3B).withValues(alpha: 0.35) : const Color(0xFFECFDF5)),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    isSup
                                        ? (contact.hutang > 0
                                            ? "Toko Berhutang: ${_currencyFormat.format(contact.hutang)}"
                                            : "✓ Lunas (Tidak Ada Hutang)")
                                        : (contact.piutang > 0
                                            ? "Piutang Berjalan: ${_currencyFormat.format(contact.piutang)}"
                                            : "✓ Lunas (Tidak Ada Piutang)"),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: (isSup ? contact.hutang : contact.piutang) > 0
                                        ? (isSup ? const Color(0xFFE05260) : const Color(0xFFD97706))
                                        : const Color(0xFF047857),
                                    ),
                                  ),
                                ),
                              ),
                              if (contact.addressOrNotes.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                _buildDetailInfoRow(
                                  label: "CATATAN",
                                  isDark: isDark,
                                  valueWidget: Text(
                                    contact.addressOrNotes,
                                    style: GoogleFonts.openSans(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? Colors.white70 : const Color(0xFF334155),
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 18),

                              // Action Buttons: [ Bayar Hutang / Terima Piutang ] [ Edit ] [ 🗑 ]
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  if (isSup && contact.supplierSource != null)
                                    InkWell(
                                      onTap: () async {
                                        await _showBayarHutangSupplierSheet(contact.supplierSource!);
                                        if (ctx.mounted) setSheetState(() {});
                                      },
                                      borderRadius: BorderRadius.circular(11),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE5A923),
                                          borderRadius: BorderRadius.circular(11),
                                          border: Border.all(
                                            color: const Color(0xFF78350F),
                                            width: 1.2,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.credit_card_rounded,
                                              size: 17,
                                              color: Color(0xFF0F172A),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              "Bayar Hutang",
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: const Color(0xFF0F172A),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  else if (!isSup)
                                    InkWell(
                                      onTap: () async {
                                        await _showTerimaPiutangCustomerSheet(contact);
                                        if (ctx.mounted) setSheetState(() {});
                                      },
                                      borderRadius: BorderRadius.circular(11),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE5A923),
                                          borderRadius: BorderRadius.circular(11),
                                          border: Border.all(
                                            color: const Color(0xFF78350F),
                                            width: 1.2,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.check_rounded,
                                              size: 17,
                                              color: Color(0xFF0F172A),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              "Terima Piutang",
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: const Color(0xFF0F172A),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                  // Tombol Edit
                                  InkWell(
                                    onTap: () async {
                                      Navigator.pop(ctx);
                                      await _showAddOrEditContactSheet(existing: contact);
                                    },
                                    borderRadius: BorderRadius.circular(11),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF0F172A) : Colors.white,
                                        borderRadius: BorderRadius.circular(11),
                                        border: Border.all(
                                          color: isDark ? Colors.white30 : const Color(0xFF64748B),
                                          width: 1.2,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.edit_outlined,
                                            size: 16,
                                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            "Edit",
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  // Tombol Hapus [ 🗑 ]
                                  InkWell(
                                    onTap: () async {
                                      final hasHistory = _contactHasHistory(contact);
                                      if (hasHistory) {
                                        await showDialog(
                                          context: context,
                                          builder: (dialogCtx) => KasirDialog(
                                            title: "Tidak Dapat Dihapus",
                                            message: "Kontak '${contact.name}' tidak dapat dihapus karena memiliki riwayat transaksi/aktivitas di toko.",
                                            icon: Icons.warning_amber_rounded,
                                            iconColor: const Color(0xFFE05260),
                                            primaryActionLabel: "Mengerti",
                                            onPrimaryAction: () => Navigator.pop(dialogCtx),
                                          ),
                                        );
                                        return;
                                      }

                                      final confirmed = await _confirmDeleteContact(contact);
                                      if (!confirmed) return;
                                      if (ctx.mounted) Navigator.pop(ctx);
                                      if (!mounted) return;
                                      final admin = context.read<AdminController>();
                                      final sId = admin.storeId ?? '';
                                      if (contact.isSupplier && contact.supplierSource != null) {
                                        await _supplierService.deleteSupplier(contact.supplierSource!.id, sId);
                                      } else if (contact.customerSource != null) {
                                        await _customerService.deleteCustomer(contact.customerSource!.id);
                                      }
                                      await _loadContactsData();
                                    },
                                    borderRadius: BorderRadius.circular(11),
                                    child: Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE05260),
                                        borderRadius: BorderRadius.circular(11),
                                      ),
                                      child: const Icon(
                                        Icons.delete_outline_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 22),

                              // RIWAYAT Section
                              Text(
                                "RIWAYAT",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 8),

                              Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF0F172A) : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                    width: 1.2,
                                  ),
                                ),
                                child: history.isEmpty
                                    ? Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
                                        child: Center(
                                          child: Text(
                                            "Belum ada riwayat transaksi untuk kontak ini.",
                                            style: GoogleFonts.openSans(
                                              fontSize: 12.5,
                                              color: isDark ? Colors.white54 : const Color(0xFF64748B),
                                            ),
                                          ),
                                        ),
                                      )
                                    : ListView.separated(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemCount: history.length,
                                        separatorBuilder: (_, __) => Divider(
                                          height: 1,
                                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                        ),
                                        itemBuilder: (context, idx) {
                                          final item = history[idx];
                                          String dateLabel;
                                          try {
                                            dateLabel = dayFormat.format(item.date);
                                          } catch (_) {
                                            dateLabel = DateFormat('dd/MM/yyyy').format(item.date);
                                          }

                                          return InkWell(
                                            onTap: () => _openHistoryDetail(item, contact, setSheetState),
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                                              child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Wrap(
                                                        spacing: 8,
                                                        runSpacing: 4,
                                                        crossAxisAlignment: WrapCrossAlignment.center,
                                                        children: [
                                                          Container(
                                                            padding: const EdgeInsets.symmetric(
                                                              horizontal: 9,
                                                              vertical: 3,
                                                            ),
                                                            decoration: BoxDecoration(
                                                              color: item.badgeBgColor,
                                                              borderRadius: BorderRadius.circular(12),
                                                            ),
                                                            child: Text(
                                                              item.badgeLabel,
                                                              style: GoogleFonts.plusJakartaSans(
                                                                fontSize: 10.5,
                                                                fontWeight: FontWeight.w800,
                                                                color: item.badgeTextColor,
                                                                letterSpacing: 0.3,
                                                              ),
                                                            ),
                                                          ),
                                                          Text(
                                                            item.code,
                                                            style: GoogleFonts.plusJakartaSans(
                                                              fontSize: 13.5,
                                                              fontWeight: FontWeight.w800,
                                                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                                                            ),
                                                          ),
                                                          if (item.secondaryBadge != null)
                                                            Container(
                                                              padding: const EdgeInsets.symmetric(
                                                                horizontal: 8,
                                                                vertical: 2.5,
                                                              ),
                                                              decoration: BoxDecoration(
                                                                color: item.secondaryBadgeBg ?? const Color(0xFFFEF3C7),
                                                                borderRadius: BorderRadius.circular(8),
                                                              ),
                                                              child: Text(
                                                                item.secondaryBadge!,
                                                                style: GoogleFonts.plusJakartaSans(
                                                                  fontSize: 10,
                                                                  fontWeight: FontWeight.w800,
                                                                  color: item.secondaryBadgeText ?? const Color(0xFFB45309),
                                                                ),
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 5),
                                                      Text(
                                                        item.subtitle,
                                                        style: GoogleFonts.openSans(
                                                          fontSize: 12.5,
                                                          fontWeight: FontWeight.w500,
                                                          color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        dateLabel,
                                                        style: GoogleFonts.openSans(
                                                          fontSize: 11.5,
                                                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Text(
                                                  item.amountText,
                                                  style: GoogleFonts.plusJakartaSans(
                                                    fontSize: 15.5,
                                                    fontWeight: FontWeight.w800,
                                                    color: item.amountColor,
                                                  ),
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

  Widget _buildDetailInfoRow({
    required String label,
    required Widget valueWidget,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 85,
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: valueWidget,
          ),
        ),
      ],
    );
  }

  // ─── Bottom Sheet: Tambah / Edit Kontak (Pelanggan atau Supplier) ─────────
  Future<void> _showAddOrEditContactSheet({_UnifiedContactItem? existing}) async {
    final isEditing = existing != null;
    String selectedType = existing != null
        ? (existing.isSupplier ? 'Supplier' : 'Pelanggan')
        : (_roleFilter == 'Supplier' ? 'Supplier' : 'Pelanggan');
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    final notesCtrl = TextEditingController(
      text: existing != null && existing.isSupplier && existing.supplierSource != null
          ? (existing.supplierSource!.address ?? existing.supplierSource!.notes ?? '')
          : (existing?.addressOrNotes ?? ''),
    );

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final isDark = Theme.of(ctx).brightness == Brightness.dark;
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isEditing ? "EDIT KONTAK" : "TAMBAH KONTAK",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              InkWell(
                                onTap: () => Navigator.pop(ctx),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.close_rounded,
                                    size: 20,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Divider(height: 1, color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                          const SizedBox(height: 16),

                          if (!isEditing) ...[
                            _buildSheetLabel("TIPE KONTAK", isDark),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              decoration: _inputBoxDecoration(isDark),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: selectedType,
                                  isExpanded: true,
                                  dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                                  items: ['Pelanggan', 'Supplier', 'Pelanggan & Supplier'].map((t) {
                                    return DropdownMenuItem(
                                      value: t,
                                      child: Text(
                                        t,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) setSheetState(() => selectedType = val);
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],

                          _buildSheetLabel("NAMA KONTAK", isDark),
                          const SizedBox(height: 6),
                          TextField(
                            controller: nameCtrl,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                            decoration: _textFieldDecoration("Contoh: Bu Endang / Budi", isDark),
                          ),
                          const SizedBox(height: 14),

                          _buildSheetLabel("NO. TELEPON / WHATSAPP", isDark),
                          const SizedBox(height: 6),
                          TextField(
                            controller: phoneCtrl,
                            keyboardType: TextInputType.phone,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                            decoration: _textFieldDecoration("0812xxxxxxxx", isDark),
                          ),
                          const SizedBox(height: 14),

                          _buildSheetLabel("ALAMAT / CATATAN", isDark),
                          const SizedBox(height: 6),
                          TextField(
                            controller: notesCtrl,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                            decoration: _textFieldDecoration("opsional", isDark),
                          ),
                          const SizedBox(height: 22),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton(
                                onPressed: () => Navigator.pop(ctx),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  side: BorderSide(
                                    color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                                  ),
                                ),
                                child: Text(
                                  "Batal",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white70 : const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _primaryGreen,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 0,
                                ),
                                onPressed: () async {
                                  final name = nameCtrl.text.trim();
                                  if (name.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Nama kontak wajib diisi")),
                                    );
                                    return;
                                  }
                                  final phone = phoneCtrl.text.trim();
                                  final notes = notesCtrl.text.trim();

                                  final admin = context.read<AdminController>();
                                  final storeId = admin.storeId ?? '';
                                  if (ctx.mounted) Navigator.pop(ctx);

                                  if (isEditing) {
                                    if (existing.isSupplier && existing.supplierSource != null) {
                                      await _supplierService.updateSupplier(
                                        existing.supplierSource!.copyWith(
                                          name: name,
                                          phone: phone,
                                          address: notes,
                                          notes: notes,
                                          unpaidBalance: existing.supplierSource!.unpaidBalance,
                                        ),
                                      );
                                    } else if (existing.customerSource != null) {
                                      await _customerService.updateCustomer(
                                        existing.customerSource!.copyWith(
                                          name: Value(name),
                                          phoneNumber: Value(phone.isEmpty ? null : phone),
                                          email: Value(notes.isEmpty ? null : notes),
                                        ),
                                      );
                                    }
                                  } else {
                                    if (selectedType == 'Pelanggan & Supplier') {
                                      await _customerService.addCustomer(
                                        storeId: storeId,
                                        name: name,
                                        phoneNumber: phone.isEmpty ? null : phone,
                                        email: notes.isEmpty ? null : notes,
                                      );
                                      await _supplierService.addSupplier(
                                        storeId: storeId,
                                        name: name,
                                        phone: phone,
                                        address: notes,
                                        notes: notes,
                                        unpaidBalance: 0.0,
                                      );
                                    } else if (selectedType == 'Supplier') {
                                      await _supplierService.addSupplier(
                                        storeId: storeId,
                                        name: name,
                                        phone: phone,
                                        address: notes,
                                        notes: notes,
                                        unpaidBalance: 0.0,
                                      );
                                    } else {
                                      await _customerService.addCustomer(
                                        storeId: storeId,
                                        name: name,
                                        phoneNumber: phone.isEmpty ? null : phone,
                                        email: notes.isEmpty ? null : notes,
                                      );
                                    }
                                  }

                                  await _loadContactsData();
                                },
                                icon: const Icon(Icons.check_rounded, size: 18),
                                label: Text(
                                  "Simpan",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
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
  }

  // ─── Bottom Sheet: Bayar Hutang Supplier ──────────────────────────────────
  Future<void> _showBayarHutangSupplierSheet(Supplier supplier) async {
    if (_activePaymentMethods.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Belum ada akun kas/bank yang aktif")),
      );
      return;
    }

    final supplierList = _allContacts
        .where((c) => c.isSupplier && c.supplierSource != null)
        .map((c) => c.supplierSource!)
        .toList();
    if (!supplierList.any((s) => s.id == supplier.id)) {
      supplierList.insert(0, supplier);
    }

    Supplier selectedSupplier = supplierList.firstWhere(
      (s) => s.id == supplier.id,
      orElse: () => supplier,
    );
    DateTime selectedDate = DateTime.now();
    PaymentMethod selectedMethod = _activePaymentMethods.first;
    final amountCtrl = TextEditingController(
      text: selectedSupplier.unpaidBalance > 0
          ? selectedSupplier.unpaidBalance.toInt().toString()
          : '',
    );
    final notesCtrl = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final isDark = Theme.of(ctx).brightness == Brightness.dark;
            final bool hasDebt = selectedSupplier.unpaidBalance > 0;
            final sisaHutang = hasDebt
                ? selectedSupplier.unpaidBalance
                : 0.0;
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "BAYAR HUTANG",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              InkWell(
                                onTap: () => Navigator.pop(ctx),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.close_rounded,
                                    size: 20,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Divider(height: 1, color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                          const SizedBox(height: 16),

                          // Info Banner Sisa Hutang Supplier / Peringatan Tidak Memiliki Hutang
                          if (!hasDebt)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF1F2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFFECDD3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.info_outline_rounded, color: Color(0xFFE05260), size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      "Toko tidak memiliki hutang ke ${selectedSupplier.name} (Sisa hutang: Rp 0). Transaksi pembayaran hutang tidak dapat dilakukan.",
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFFBE123C),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F0),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: RichText(
                                text: TextSpan(
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    color: isDark ? Colors.white70 : const Color(0xFF0F172A),
                                  ),
                                  children: [
                                    TextSpan(
                                      text: "Sisa hutang ${selectedSupplier.name}: ",
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                    TextSpan(
                                      text: _currencyFormat.format(sisaHutang),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFFE05260),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          const SizedBox(height: 16),

                          _buildSheetLabel("TANGGAL", isDark),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: ctx,
                                initialDate: selectedDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                setSheetState(() => selectedDate = picked);
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                              decoration: _inputBoxDecoration(isDark),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    DateFormat('dd/MM/yyyy').format(selectedDate),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    size: 20,
                                    color: isDark ? Colors.white60 : const Color(0xFF475569),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          _buildSheetLabel("DIAMBIL DARI AKUN", isDark),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: _inputBoxDecoration(isDark),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<PaymentMethod>(
                                value: selectedMethod,
                                isExpanded: true,
                                dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                                items: _activePaymentMethods.map((m) {
                                  return DropdownMenuItem(
                                    value: m,
                                    child: Text(
                                      "${m.name} (${_currencyFormat.format(_methodBalances[m.id] ?? 0)})",
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setSheetState(() => selectedMethod = val);
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          _buildSheetLabel("SUPPLIER", isDark),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: _inputBoxDecoration(isDark),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedSupplier.id,
                                isExpanded: true,
                                dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                                items: supplierList.map((s) {
                                  final hasSupDebt = s.unpaidBalance > 0;
                                  return DropdownMenuItem<String>(
                                    value: s.id,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            s.name,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Text(
                                          hasSupDebt ? "Hutang: ${_currencyFormat.format(s.unpaidBalance)}" : "Lunas (Rp 0)",
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: hasSupDebt ? const Color(0xFFE05260) : const Color(0xFF0D8A50),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    final found = supplierList.firstWhere(
                                      (s) => s.id == val,
                                      orElse: () => selectedSupplier,
                                    );
                                    setSheetState(() {
                                      selectedSupplier = found;
                                      amountCtrl.text = found.unpaidBalance > 0
                                          ? (found.unpaidBalance % 1 == 0 ? found.unpaidBalance.toInt().toString() : found.unpaidBalance.toStringAsFixed(0))
                                          : '0';
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          _buildSheetLabel("JUMLAH (RP)", isDark),
                          const SizedBox(height: 6),
                          TextField(
                            controller: amountCtrl,
                            keyboardType: TextInputType.number,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                            decoration: _textFieldDecoration("0", isDark),
                          ),
                          const SizedBox(height: 14),

                          _buildSheetLabel("CATATAN", isDark),
                          const SizedBox(height: 6),
                          TextField(
                            controller: notesCtrl,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                            decoration: _textFieldDecoration("opsional", isDark),
                          ),
                          const SizedBox(height: 22),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton(
                                onPressed: () => Navigator.pop(ctx),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  side: BorderSide(
                                    color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                                  ),
                                ),
                                child: Text(
                                  "Batal",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white70 : const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: !hasDebt ? (isDark ? Colors.white12 : const Color(0xFFE2E8F0)) : _primaryGreen,
                                  foregroundColor: !hasDebt ? (isDark ? Colors.white38 : const Color(0xFF94A3B8)) : Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 0,
                                ),
                                onPressed: !hasDebt
                                    ? () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text("Toko tidak memiliki hutang ke ${selectedSupplier.name}. Transaksi tidak dapat dilakukan."),
                                            backgroundColor: const Color(0xFFE05260),
                                          ),
                                        );
                                      }
                                    : () async {
                                        final clean = amountCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '');
                                        final amt = double.tryParse(clean) ?? 0.0;
                                        if (amt <= 0) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text("Masukkan jumlah bayar hutang yang valid")),
                                          );
                                          return;
                                        }
                                        if (selectedSupplier.unpaidBalance <= 0) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text("Toko tidak memiliki hutang ke ${selectedSupplier.name}."),
                                              backgroundColor: const Color(0xFFE05260),
                                            ),
                                          );
                                          return;
                                        }
                                        if (amt > selectedSupplier.unpaidBalance) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text("Nominal pembayaran melebihi sisa hutang ke ${selectedSupplier.name} (${_currencyFormat.format(selectedSupplier.unpaidBalance)})"),
                                              backgroundColor: const Color(0xFFE05260),
                                            ),
                                          );
                                          return;
                                        }
                                        final admin = context.read<AdminController>();
                                        final storeId = admin.storeId ?? '';
                                        if (ctx.mounted) Navigator.pop(ctx);

                                        try {
                                          final tx = await _supplierService.recordPayment(
                                            storeId: storeId,
                                            supplierId: selectedSupplier.id,
                                            amount: amt,
                                            paymentMethod: selectedMethod.name,
                                            paymentMethodId: selectedMethod.id,
                                            notes: notesCtrl.text.trim(),
                                            customDate: selectedDate,
                                          );
                                          await _loadContactsData();
                                          if (mounted) {
                                            final remDebt = (selectedSupplier.unpaidBalance - amt).clamp(0.0, double.infinity);
                                            TransactionResultDialog.show(
                                              context: context,
                                              isSuccess: true,
                                              title: "Pembayaran Hutang Berhasil!",
                                              subtitle: "Transaksi #${tx.transactionNo} telah berhasil dicatat.",
                                              transactionCode: tx.transactionNo,
                                              dateTime: tx.createdAt,
                                              totalAmount: amt,
                                              paidAmount: amt,
                                              remainingDebt: remDebt > 0 ? remDebt : null,
                                              statusBadge: remDebt <= 0 ? "LUNAS" : "SEBAGIAN",
                                              statusBadgeBg: remDebt <= 0 ? const Color(0xFFECFDF5) : const Color(0xFFFEF3C7),
                                              statusBadgeText: remDebt <= 0 ? const Color(0xFF047857) : const Color(0xFFB45309),
                                              contactName: selectedSupplier.name,
                                              contactRole: "Supplier",
                                              contactPhone: selectedSupplier.phone,
                                              accountName: selectedMethod.name,
                                              category: "Bayar Hutang Supplier",
                                              notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                                            );
                                          }
                                        } catch (e) {
                                          debugPrint("Error recordPayment: $e");
                                          if (mounted) {
                                            TransactionResultDialog.show(
                                              context: context,
                                              isSuccess: false,
                                              title: "Pembayaran Hutang Gagal",
                                              subtitle: "Terjadi kesalahan saat memproses pembayaran hutang.",
                                              errorMessage: e.toString(),
                                              totalAmount: amt,
                                              contactName: selectedSupplier.name,
                                              contactRole: "Supplier",
                                            );
                                          }
                                        }
                                      },
                                icon: const Icon(Icons.check_rounded, size: 18),
                                label: Text(
                                  "Simpan",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
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
  }

  // ─── Bottom Sheet: Terima Piutang Pelanggan ───────────────────────────────
  Future<void> _showTerimaPiutangCustomerSheet(_UnifiedContactItem contact) async {
    if (_activePaymentMethods.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Belum ada akun kas/bank yang aktif")),
      );
      return;
    }

    DateTime selectedDate = DateTime.now();
    PaymentMethod selectedMethod = _activePaymentMethods.first;
    final amountCtrl = TextEditingController(
      text: contact.piutang > 0 ? contact.piutang.toInt().toString() : '',
    );
    final notesCtrl = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final isDark = Theme.of(ctx).brightness == Brightness.dark;
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "TERIMA PIUTANG — ${contact.name.toUpperCase()}",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              InkWell(
                                onTap: () => Navigator.pop(ctx),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.close_rounded,
                                    size: 20,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Divider(height: 1, color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                          const SizedBox(height: 16),

                          _buildSheetLabel("TANGGAL", isDark),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: ctx,
                                initialDate: selectedDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                setSheetState(() => selectedDate = picked);
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                              decoration: _inputBoxDecoration(isDark),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    DateFormat('dd/MM/yyyy').format(selectedDate),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    size: 20,
                                    color: isDark ? Colors.white60 : const Color(0xFF475569),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          _buildSheetLabel("MASUK KE AKUN", isDark),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: _inputBoxDecoration(isDark),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<PaymentMethod>(
                                value: selectedMethod,
                                isExpanded: true,
                                dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                                items: _activePaymentMethods.map((m) {
                                  return DropdownMenuItem(
                                    value: m,
                                    child: Text(
                                      "${m.name} (${_currencyFormat.format(_methodBalances[m.id] ?? 0)})",
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setSheetState(() => selectedMethod = val);
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          _buildSheetLabel("JUMLAH DITERIMA (RP)", isDark),
                          const SizedBox(height: 6),
                          TextField(
                            controller: amountCtrl,
                            keyboardType: TextInputType.number,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                            decoration: _textFieldDecoration("0", isDark),
                          ),
                          const SizedBox(height: 14),

                          _buildSheetLabel("CATATAN", isDark),
                          const SizedBox(height: 6),
                          TextField(
                            controller: notesCtrl,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                            decoration: _textFieldDecoration("opsional", isDark),
                          ),
                          const SizedBox(height: 22),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton(
                                onPressed: () => Navigator.pop(ctx),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  side: BorderSide(
                                    color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                                  ),
                                ),
                                child: Text(
                                  "Batal",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white70 : const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _primaryGreen,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 0,
                                ),
                                onPressed: () async {
                                  final clean = amountCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '');
                                  final amt = double.tryParse(clean) ?? 0.0;
                                  if (amt <= 0) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Masukkan jumlah piutang yang diterima")),
                                    );
                                    return;
                                  }
                                  final admin = context.read<AdminController>();
                                  final db = context.read<AppDatabase>();
                                  final storeId = admin.storeId ?? '';
                                  if (ctx.mounted) Navigator.pop(ctx);

                                  final debtTxs = _allStoreTransactions.where((t) => t.status == 'debt').toList();
                                  double remainingPayment = amt;
                                  for (final dtx in debtTxs) {
                                    if (remainingPayment <= 0) break;
                                    final matchById = contact.customerSource != null && dtx.customerId == contact.customerSource!.id;
                                    final matchByName = (dtx.customerName ?? '').trim().toLowerCase() == contact.name.toLowerCase();
                                    if (matchById || matchByName) {
                                      final curReceived = dtx.cashReceived ?? 0.0;
                                      final totalTx = dtx.totalAmount ?? 0.0;
                                      final unpaid = (totalTx - curReceived).clamp(0.0, double.infinity);
                                      if (unpaid > 0) {
                                        final payPortion = remainingPayment >= unpaid ? unpaid : remainingPayment;
                                        final nextReceived = curReceived + payPortion;
                                        final nextStatus = nextReceived >= totalTx ? 'completed' : 'debt';
                                        await (db.update(db.transactions)..where((t) => t.id.equals(dtx.id))).write(
                                          TransactionsCompanion(
                                            cashReceived: Value(nextReceived),
                                            status: Value(nextStatus),
                                          ),
                                        );
                                        remainingPayment -= payPortion;
                                      }
                                    }
                                  }

                                  final extraNote = notesCtrl.text.trim().isNotEmpty
                                      ? " (${notesCtrl.text.trim()})"
                                      : "";
                                  try {
                                    await _paymentMethodService.recordInflow(
                                      storeId: storeId,
                                      method: selectedMethod,
                                      category: 'Terima Piutang',
                                      amount: amt,
                                      notes: "Pelanggan: ${contact.name}$extraNote",
                                      date: selectedDate,
                                    );

                                    final remPiutang = (contact.piutang - amt).clamp(0.0, double.infinity);
                                    await _loadContactsData();
                                    if (mounted) {
                                      TransactionResultDialog.show(
                                        context: context,
                                        isSuccess: true,
                                        title: "Terima Piutang Berhasil!",
                                        subtitle: "Penerimaan piutang dari ${contact.name} telah berhasil dicatat.",
                                        dateTime: selectedDate,
                                        totalAmount: amt,
                                        paidAmount: amt,
                                        remainingDebt: remPiutang > 0 ? remPiutang : null,
                                        statusBadge: remPiutang <= 0 ? "LUNAS" : "SEBAGIAN",
                                        statusBadgeBg: remPiutang <= 0 ? const Color(0xFFECFDF5) : const Color(0xFFFEF3C7),
                                        statusBadgeText: remPiutang <= 0 ? const Color(0xFF047857) : const Color(0xFFB45309),
                                        contactName: contact.name,
                                        contactRole: "Pelanggan",
                                        contactPhone: contact.phone,
                                        accountName: selectedMethod.name,
                                        category: "Terima Piutang",
                                        notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                                      );
                                    }
                                  } catch (e) {
                                    debugPrint("Error recordInflow terima piutang: $e");
                                    if (mounted) {
                                      TransactionResultDialog.show(
                                        context: context,
                                        isSuccess: false,
                                        title: "Terima Piutang Gagal",
                                        subtitle: "Terjadi kesalahan saat mencatat penerimaan piutang.",
                                        errorMessage: e.toString(),
                                        totalAmount: amt,
                                        contactName: contact.name,
                                        contactRole: "Pelanggan",
                                      );
                                    }
                                  }
                                },
                                icon: const Icon(Icons.check_rounded, size: 18),
                                label: Text(
                                  "Simpan",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
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
  }

  Future<bool> _confirmDeleteContact(_UnifiedContactItem contact) async {
    if (_contactHasHistory(contact)) {
      await showDialog(
        context: context,
        builder: (ctx) => KasirDialog(
          title: "Tidak Dapat Dihapus",
          message: "Kontak '${contact.name}' tidak dapat dihapus karena masih memiliki riwayat transaksi/aktivitas di toko.",
          icon: Icons.warning_amber_rounded,
          iconColor: const Color(0xFFE05260),
          primaryActionLabel: "Mengerti",
          onPrimaryAction: () => Navigator.pop(ctx),
        ),
      );
      return false;
    }

    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => KasirDialog(
        title: "Hapus Kontak?",
        message: "Hapus '${contact.name}' dari daftar secara permanen?",
        icon: Icons.delete_outline_rounded,
        iconColor: const Color(0xFFE05260),
        isDestructive: true,
        primaryActionLabel: "Hapus",
        onPrimaryAction: () => Navigator.pop(ctx, true),
        secondaryActionLabel: "Batal",
        onSecondaryAction: () => Navigator.pop(ctx, false),
      ),
    );
    return res == true;
  }

  Widget _buildSheetLabel(String text, bool isDark) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        color: isDark ? Colors.white70 : const Color(0xFF64748B),
      ),
    );
  }

  BoxDecoration _inputBoxDecoration(bool isDark) {
    return BoxDecoration(
      color: isDark ? const Color(0xFF0F172A) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
      ),
    );
  }

  InputDecoration _textFieldDecoration(String hint, bool isDark) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.openSans(fontSize: 13.5, color: Colors.grey),
      filled: true,
      fillColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
      ),
    );
  }
}
