import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:open_filex/open_filex.dart';
import 'package:drift/drift.dart' hide Column;
import '../../../controllers/analytics_controller.dart';
import '../../../services/app_database.dart';
import '../../../services/export_service.dart';
import '../../../services/supplier_service.dart';
import '../../../services/platform/file_manager.dart';
import '../widgets/pinterest_card.dart';
import '../widgets/green_date_picker_dialog.dart';
import 'expense_management_page.dart';
import '../customer_page.dart';
import '../payment_settings_page.dart';
import '../../../services/payment_method_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../../widgets/activity_detail_sheet.dart';
import '../../../widgets/transaction_result_dialog.dart';

class ProfitLossPage extends StatefulWidget {
  final String storeId;
  final VoidCallback? onMenuPressed;
  final VoidCallback? onBack;
  final Function(int)? onNavigateToIndex;
  final bool initialLaporanView;
  final int initialTabIndex;
  const ProfitLossPage({
    super.key,
    required this.storeId,
    this.onMenuPressed,
    this.onBack,
    this.onNavigateToIndex,
    this.initialLaporanView = false,
    this.initialTabIndex = 0,
  });

  @override
  State<ProfitLossPage> createState() => _ProfitLossPageState();
}

class _ProfitLossPageState extends State<ProfitLossPage> {
  final _currencyFormat = NumberFormat.currency(
    locale: 'id',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  final _exportService = ExportService();

  // Tab State: 0: Laba Rugi, 1: Arus Kas, 2: Transaksi, 3: Grafik, 4: Pasokan
  int _selectedTabIndex = 0;

  // Toggle between main "Uang" overview (Beranda Keuangan) and full "Laporan" view
  bool _isShowingLaporanView = false;

  // Selected date range state
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();

  // Expenses grouped by category & transaction list for current range
  Map<String, double> _expenseCategories = {};
  List<Transaction> _periodTransactions = [];
  List<Expense> _periodExpenses = [];
  List<SupplierReportSummary> _supplierSummaries = [];
  List<SupplierTransaction> _periodSupplierTxs = [];
  bool _isLoadingDetails = false;
  double _totalPiutang = 0.0;
  double _totalHutangSupplier = 0.0;
  double _operationalExpensesSum = 0.0;
  double _totalExpensesSum = 0.0;
  double _periodOtherIncomeSum = 0.0;
  double _periodSupplierPurchaseSum = 0.0;
  double _drawerBaseCash = 0.0;
  List<PaymentMethod> _activePaymentMethods = [];
  Map<String, double> _methodCurrentBalances = {};
  double _realCumulativeSaldoKasBank = 0.0;
  List<_RecentActivityItem> _recentActivities = [];

  bool _isInflowCategory(String category, {String? notes}) {
    final c = category.toLowerCase().trim();
    final n = (notes ?? '').toLowerCase().trim();
    return c == 'pemasukan lain' ||
        c == 'terima piutang' ||
        c == 'setor modal' ||
        c.contains('pemasukan') ||
        c.contains('piutang') ||
        n.contains('[inflow]');
  }

  bool _isStockRestockCategory(String category, {String? notes}) {
    final c = category.toLowerCase().trim();
    final n = (notes ?? '').toLowerCase().trim();
    return c.contains('supplier') ||
           c.contains('restock') ||
           c.contains('kulakan') ||
           c.contains('pasokan') ||
           c.contains('pembelian stok') ||
           c.contains('pembelian barang') ||
           c.contains('beli stok') ||
           c.contains('penyesuaian') ||
           c.contains('stok awal') ||
           c.contains('stok') ||
           c.contains('modal') ||
           c.contains('setor modal') ||
           c.contains('prive') ||
           c.contains('tarik') ||
           c.contains('transfer') ||
           c.contains('cek fisik') ||
           n.contains('[cek_fisik]') ||
           n.contains('stok awal') ||
           n.contains('tarik') ||
           n.contains('transfer') ||
           n.contains('penyesuaian stok') ||
           n.contains('modal awal');
  }

  @override
  void initState() {
    super.initState();
    _isShowingLaporanView = widget.initialLaporanView;
    _selectedTabIndex = widget.initialTabIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctrl = context.read<AnalyticsController>();
      ctrl.init(widget.storeId).then((_) {
        _applyRange(ctrl.selectedRange, updateCtrl: false);
      });
    });
  }

  void _applyRange(ChartRange range, {bool updateCtrl = true}) {
    final now = DateTime.now();
    DateTime start;
    DateTime end = DateTime(now.year, now.month, now.day, 23, 59, 59);

    switch (range) {
      case ChartRange.today:
        start = DateTime(now.year, now.month, now.day);
        break;
      case ChartRange.sevenDays:
        start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
        break;
      case ChartRange.month:
        start = DateTime(now.year, now.month, 1);
        break;
      case ChartRange.allTime:
        start = DateTime(2020, 1, 1);
        break;
      case ChartRange.thirtyDays:
        start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 29));
        break;
      case ChartRange.custom:
        start = _startDate;
        end = _endDate;
        break;
    }

    setState(() {
      _startDate = start;
      _endDate = end;
    });

    if (updateCtrl) {
      final ctrl = context.read<AnalyticsController>();
      if (range == ChartRange.custom) {
        ctrl.setRange(range, start: start, end: end);
      } else {
        ctrl.setRange(range);
      }
    }

    _loadDetailData();
  }

  Future<void> _loadDetailData() async {
    if (!mounted) return;
    setState(() => _isLoadingDetails = true);

    try {
      final db = context.read<AppDatabase>();
      final startDay = DateTime(_startDate.year, _startDate.month, _startDate.day, 0, 0, 0);
      final endDay = DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59);

      // 1. Fetch Expenses in range
      final exps = await (db.select(db.expenses)
        ..where((e) => e.storeId.equals(widget.storeId))
        ..where((e) => e.date.isBiggerOrEqualValue(startDay) & e.date.isSmallerOrEqualValue(endDay))
      ).get();

      final Map<String, double> catMap = {};
      double opExpSum = 0.0;
      double totalExpSum = 0.0;
      double otherIncSum = 0.0;

      for (final exp in exps) {
        final cat = (exp.category.trim().isEmpty ? 'Lain-lain' : exp.category.trim());
        final amt = exp.amount ?? 0;

        if (_isInflowCategory(cat, notes: exp.notes)) {
          if (!cat.toLowerCase().contains('modal')) {
            otherIncSum += amt;
          }
        } else if (_isStockRestockCategory(cat, notes: exp.notes)) {
          // Modal aset stok & penyesuaian (bukan biaya operasional)
          totalExpSum += amt;
        } else {
          catMap[cat] = (catMap[cat] ?? 0) + amt;
          opExpSum += amt;
          totalExpSum += amt;
        }
      }

      // 2. Fetch Transactions in range
      final txs = await (db.select(db.transactions)
        ..where((t) => t.storeId.equals(widget.storeId))
        ..where((t) => t.createdAt.isBiggerOrEqualValue(startDay) & t.createdAt.isSmallerOrEqualValue(endDay))
        ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
      ).get();

      // 3. Fetch Supplier analytics for this period
      final supplierService = SupplierService(db);
      final suppliers = await supplierService.getSuppliers(widget.storeId);
      final products = await (db.select(db.products)..where((p) => p.storeId.equals(widget.storeId))).get();
      final prodMap = {for (final p in products) p.id: p};

      // Cari cutoff pelunasan supplier agar tagihan berjalan tidak terpotong oleh filter tanggal atas
      DateTime? earliestCutoff;
      for (final s in suppliers) {
        if (s.lastSettledAt == null) {
          earliestCutoff = null;
          break;
        }
        if (earliestCutoff == null || s.lastSettledAt!.isBefore(earliestCutoff)) {
          earliestCutoff = s.lastSettledAt;
        }
      }

      List<Transaction> supTxs = txs;
      if (earliestCutoff == null || earliestCutoff.isBefore(startDay)) {
        var q = db.select(db.transactions)..where((t) => t.storeId.equals(widget.storeId));
        if (earliestCutoff != null) {
          q = q..where((t) => t.createdAt.isBiggerThanValue(earliestCutoff!));
        }
        supTxs = await q.get();
      }

      final supTxMap = {for (final t in supTxs) t.id: t};
      final supTxIds = supTxs.map((t) => t.id).toList();
      final List<TransactionItem> supTxItems = supTxIds.isNotEmpty
          ? await (db.select(db.transactionItems)..where((ti) => ti.transactionId.isIn(supTxIds))).get()
          : [];

      final List<SupplierReportSummary> summaries = [];
      for (final sup in suppliers) {
        final supProdIds = {...sup.productUsualStock.keys, ...sup.productPrices.keys};
        final List<SupplierProductDetail> details = [];
        final supCutoff = sup.lastSettledAt;

        int totalQty = 0;
        double totalCost = 0.0;
        double totalGross = 0.0;

        for (final pId in supProdIds) {
          final prod = prodMap[pId];
          final prodName = prod?.name ?? "Produk #$pId";
          final unitPrice = sup.productPrices[pId] ?? (prod?.buyPrice ?? prod?.basePrice ?? 0.0);
          final salePrice = prod?.salePrice ?? 0.0;

          // Hitung seluruh transaksi berjalan sejak pelunasan terakhir (supCutoff)
          final itemsForProd = supTxItems.where((ti) {
            if (ti.productId != pId) return false;
            final tx = supTxMap[ti.transactionId];
            if (tx == null) return false;
            if (supCutoff != null && (tx.createdAt == null || !tx.createdAt!.isAfter(supCutoff))) {
              return false;
            }
            return true;
          }).toList();

          final qty = itemsForProd.fold<int>(0, (s, i) => s + (i.quantity ?? 1));
          final gross = itemsForProd.fold<double>(0.0, (s, i) => s + (i.totalPrice ?? 0.0));
          final cost = qty * unitPrice;
          final unitSale = qty > 0 ? (gross / qty) : salePrice;

          totalQty += qty;
          totalCost += cost;
          totalGross += gross;

          if (qty > 0) {
            details.add(SupplierProductDetail(
              productId: pId,
              productName: prodName,
              qtySold: qty,
              unitBuyPrice: unitPrice,
              unitSalePrice: unitSale,
              subtotalCost: cost,
              subtotalGross: gross,
            ));
          }
        }

        final directPaid = exps
            .where((e) => e.category == 'Restock Supplier' && (e.notes?.contains(sup.name) ?? false))
            .where((e) => supCutoff == null || (e.date != null && e.date!.isAfter(supCutoff)))
            .fold<double>(0.0, (s, e) => s + (e.amount ?? 0.0));

        summaries.add(SupplierReportSummary(
          supplier: sup,
          totalQtySold: totalQty,
          totalSupplierCost: totalCost,
          totalGrossSales: totalGross,
          directExpensesPaid: directPaid,
          productDetails: details,
        ));
      }

      // 4. Fetch Customer Debts (Piutang Belum Lunas)
      final debtTxs = await (db.select(db.transactions)
            ..where((t) => t.storeId.equals(widget.storeId))
            ..where((t) => t.status.equals('debt')))
          .get();
      final totalPiutang = debtTxs.fold<double>(
        0.0,
        (sum, t) => sum + ((t.totalAmount ?? 0) - (t.cashReceived ?? 0)),
      );

      // 5. Fetch Supplier unpaid balance (Hutang Pasokan)
      final totalHutangSup = suppliers.fold<double>(
        0.0,
        (sum, s) => sum + s.unpaidBalance,
      );

      // 6. Fetch Payment Methods & Saldo per Metode (termasuk korelasi transaksi penjualan lengkap)
      final paymentService = PaymentMethodService(db);
      await paymentService.ensureDefaultPaymentMethods(widget.storeId);
      final pMethods = await paymentService.getPaymentMethods(widget.storeId);
      final methodSummaries = await paymentService.calculateMethodSummaries(widget.storeId);
      final Map<String, double> methodCurrentBalances = {
        for (var e in methodSummaries.entries) e.key: e.value.currentBalance
      };
      final activeMethods = pMethods.where((m) => m.isActive).toList();
      final realTotalBalance = activeMethods.fold<double>(
        0.0,
        (s, m) => s + (methodCurrentBalances[m.id] ?? 0.0),
      );

      // 8. Fetch all supplier transactions & customers to build Aktivitas Terakhir & period purchase sum
      final allSupTxs = await supplierService.getAllStoreTransactions(widget.storeId);
      final supNameMap = {for (final s in suppliers) s.id: s.name};
      double periodPurchaseSum = 0.0;
      for (final stx in allSupTxs) {
        if (stx.type == 'purchase' &&
            !stx.createdAt.isBefore(startDay) &&
            !stx.createdAt.isAfter(endDay)) {
          periodPurchaseSum += stx.totalAmount;
        }
      }

      final allStoreTxs = await (db.select(db.transactions)
            ..where((t) => t.storeId.equals(widget.storeId))
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .get();
      final allStoreExps = await (db.select(db.expenses)
            ..where((e) => e.storeId.equals(widget.storeId))
            ..orderBy([(e) => OrderingTerm.asc(e.date)]))
          .get();
      final allCustomers = await (db.select(db.customers)
            ..where((c) => c.storeId.equals(widget.storeId)))
          .get();
      final custMap = {for (final c in allCustomers) c.id: (c.name ?? 'Umum')};

      final List<_RecentActivityItem> recentItems = [];

      // a) Sales (PJ-xxxx)
      for (int i = 0; i < allStoreTxs.length; i++) {
        final tx = allStoreTxs[i];
        final pjNo = 'PJ-${(i + 1).toString().padLeft(4, '0')}';
        final custName = (tx.customerName != null && tx.customerName!.trim().isNotEmpty)
            ? tx.customerName!.trim()
            : (tx.customerId != null && custMap.containsKey(tx.customerId)
                ? custMap[tx.customerId]!
                : 'Umum');
        final isDebt = tx.status == 'debt';
        recentItems.add(_RecentActivityItem(
          id: tx.id,
          badgeLabel: 'PENJUALAN',
          badgeBgColor: const Color(0xFFD1FAE5),
          badgeTextColor: const Color(0xFF047857),
          code: pjNo,
          secondaryBadge: isDebt ? 'PIUTANG' : null,
          secondaryBadgeBg: isDebt ? const Color(0xFFFEF3C7) : null,
          secondaryBadgeText: isDebt ? const Color(0xFFB45309) : null,
          subtitle: 'Pelanggan: $custName',
          date: tx.createdAt ?? DateTime.now(),
          amountText: _currencyFormat.format(tx.totalAmount ?? 0),
          amountColor: const Color(0xFF047857),
          rawTransaction: tx,
          amountValue: (tx.totalAmount ?? 0).toDouble(),
          customerName: custName,
          paymentMethodName: tx.paymentMethod ?? 'Kas',
        ));
      }

      // b) Supplier Transactions (PB-xxxx, BH-xxxx, RB-xxxx)
      for (final stx in allSupTxs) {
        final supName = supNameMap[stx.supplierId] ?? 'Supplier';
        final stxNote = (stx.notes ?? '').trim();
        final noteSuffix = stxNote.isNotEmpty ? ' · $stxNote' : '';
        if (stx.type == 'purchase') {
          final isHutang = stx.paymentStatus.toLowerCase() == 'hutang';
          recentItems.add(_RecentActivityItem(
            id: stx.id,
            badgeLabel: 'PEMBELIAN',
            badgeBgColor: const Color(0xFFE0F2FE),
            badgeTextColor: const Color(0xFF0369A1),
            code: stx.transactionNo,
            secondaryBadge: isHutang ? 'HUTANG' : 'LUNAS',
            secondaryBadgeBg: isHutang ? const Color(0xFFFEF3C7) : const Color(0xFFD1FAE5),
            secondaryBadgeText: isHutang ? const Color(0xFFB45309) : const Color(0xFF047857),
            subtitle: 'Supplier: $supName$noteSuffix',
            date: stx.createdAt,
            amountText: '${isHutang ? '' : '-'}${_currencyFormat.format(stx.totalAmount)}',
            amountColor: isHutang ? const Color(0xFFE05260) : const Color(0xFF0F172A),
            rawSupplierTx: stx,
            amountValue: stx.totalAmount,
            supplierName: supName,
            paymentMethodName: stx.paymentMethod ?? 'Kas',
          ));
        } else if (stx.type == 'payment') {
          final mName = (stx.paymentMethod != null && stx.paymentMethod!.isNotEmpty)
              ? stx.paymentMethod!
              : 'Kas';
          recentItems.add(_RecentActivityItem(
            id: stx.id,
            badgeLabel: 'BAYAR HUTANG',
            badgeBgColor: const Color(0xFFFFF1F2),
            badgeTextColor: const Color(0xFFBE123C),
            code: stx.transactionNo,
            subtitle: 'Ke $supName · $mName$noteSuffix',
            date: stx.createdAt,
            amountText: '-${_currencyFormat.format(stx.totalAmount)}',
            amountColor: const Color(0xFFE05260),
            rawSupplierTx: stx,
            amountValue: stx.totalAmount,
            supplierName: supName,
            paymentMethodName: mName,
          ));
        } else if (stx.type == 'return') {
          recentItems.add(_RecentActivityItem(
            id: stx.id,
            badgeLabel: 'RETUR',
            badgeBgColor: const Color(0xFFF3E8FF),
            badgeTextColor: const Color(0xFF7E22CE),
            code: stx.transactionNo,
            subtitle: 'Ke $supName$noteSuffix',
            date: stx.createdAt,
            amountText: '-${_currencyFormat.format(stx.totalAmount)}',
            amountColor: const Color(0xFF7E22CE),
            rawSupplierTx: stx,
            amountValue: stx.totalAmount,
            supplierName: supName,
          ));
        }
      }

      // c) Expenses, Prive, Inflows, Terima Piutang, Transfer, Setor Modal, Cek Fisik Kas
      int byCounter = 0;
      int prCounter = 0;
      int plCounter = 0;
      int tpCounter = 0;
      int cfCounter = 0;
      int tfCounter = 0;
      int smCounter = 0;
      int bhManualCounter = 0;
      for (final exp in allStoreExps) {
        final notes = exp.notes ?? '';
        // Skip duplicate expense entries automatically created by PB-xxxx or BH-xxxx
        if (notes.contains('(PB-') || notes.contains('(BH-')) {
          continue;
        }
        final cat = exp.category.trim().isEmpty ? 'Biaya' : exp.category.trim();
        final amt = exp.amount ?? 0.0;
        String methodLabel = 'Kas';
        for (final m in pMethods) {
          if (notes.contains('[${m.name}]') || notes.toLowerCase().contains(m.name.toLowerCase())) {
            methodLabel = m.name;
            break;
          }
        }
        final cleanNote = notes
            .replaceAll(RegExp(r'\[[^\]]+\]'), '')
            .replaceAll(RegExp(r'\(Tarik dari [^\)]+\)'), '')
            .trim();

        final cLower = cat.toLowerCase();
        if (cLower.contains('cek fisik') || notes.contains('[CEK_FISIK]')) {
          cfCounter++;
          final isLebih = notes.contains('Lebih');
          final isKurang = notes.contains('Kurang');
          recentItems.add(_RecentActivityItem(
            id: exp.id,
            badgeLabel: 'CEK FISIK KAS',
            badgeBgColor: const Color(0xFFFEF3C7),
            badgeTextColor: const Color(0xFFD97706),
            code: 'CF-${cfCounter.toString().padLeft(4, '0')}',
            secondaryBadge: isLebih ? 'LEBIH' : (isKurang ? 'KURANG' : 'COCOK'),
            secondaryBadgeBg: isLebih
                ? const Color(0xFFE0F2FE)
                : (isKurang ? const Color(0xFFFFF1F2) : const Color(0xFFECFDF5)),
            secondaryBadgeText: isLebih
                ? const Color(0xFF0369A1)
                : (isKurang ? const Color(0xFFBE123C) : const Color(0xFF065F46)),
            subtitle: '${cleanNote.isNotEmpty ? cleanNote : "Rekonsiliasi Kas"} · $methodLabel',
            date: exp.date ?? DateTime.now(),
            amountText: amt == 0
                ? 'Rp 0'
                : '${isLebih ? '+' : (isKurang ? '-' : '')}${_currencyFormat.format(amt)}',
            amountColor: isLebih
                ? const Color(0xFF0284C7)
                : (isKurang ? const Color(0xFFE05260) : const Color(0xFF0D8A50)),
            rawExpense: exp,
            amountValue: amt,
            paymentMethodName: methodLabel,
          ));
        } else if (cLower.contains('transfer') || notes.contains('[TRANSFER]')) {
          tfCounter++;
          recentItems.add(_RecentActivityItem(
            id: exp.id,
            badgeLabel: 'TRANSFER',
            badgeBgColor: const Color(0xFFE0F2FE),
            badgeTextColor: const Color(0xFF0369A1),
            code: 'TF-${tfCounter.toString().padLeft(4, '0')}',
            subtitle: cleanNote.isNotEmpty ? cleanNote : 'Transfer Antar Akun',
            date: exp.date ?? DateTime.now(),
            amountText: _currencyFormat.format(amt),
            amountColor: const Color(0xFF0284C7),
            rawExpense: exp,
            amountValue: amt,
            paymentMethodName: methodLabel,
          ));
        } else if (cLower.contains('prive') || cLower.contains('tarik')) {
          prCounter++;
          recentItems.add(_RecentActivityItem(
            id: exp.id,
            badgeLabel: 'PRIVE / PRIBADI',
            badgeBgColor: const Color(0xFFFEF3C7),
            badgeTextColor: const Color(0xFFB45309),
            code: 'PR-${prCounter.toString().padLeft(4, '0')}',
            subtitle: '${cleanNote.isNotEmpty ? cleanNote : "Prive / Pribadi"} · $methodLabel',
            date: exp.date ?? DateTime.now(),
            amountText: '-${_currencyFormat.format(amt)}',
            amountColor: const Color(0xFFE05260),
            rawExpense: exp,
            amountValue: amt,
            paymentMethodName: methodLabel,
          ));
        } else if (cLower.contains('piutang')) {
          tpCounter++;
          recentItems.add(_RecentActivityItem(
            id: exp.id,
            badgeLabel: 'TERIMA PIUTANG',
            badgeBgColor: const Color(0xFFD1FAE5),
            badgeTextColor: const Color(0xFF047857),
            code: 'TP-${tpCounter.toString().padLeft(4, '0')}',
            subtitle: '${cleanNote.isNotEmpty ? cleanNote : "Terima Piutang"} · $methodLabel',
            date: exp.date ?? DateTime.now(),
            amountText: '+${_currencyFormat.format(amt)}',
            amountColor: const Color(0xFF047857),
            rawExpense: exp,
            amountValue: amt,
            paymentMethodName: methodLabel,
          ));
        } else if (cLower.contains('bayar hutang') || cLower.contains('pelunasan hutang')) {
          bhManualCounter++;
          recentItems.add(_RecentActivityItem(
            id: exp.id,
            badgeLabel: 'BAYAR HUTANG',
            badgeBgColor: const Color(0xFFFFF1F2),
            badgeTextColor: const Color(0xFFBE123C),
            code: 'BH-${bhManualCounter.toString().padLeft(4, '0')}',
            subtitle: '${cleanNote.isNotEmpty ? cleanNote : "Bayar Hutang"} · $methodLabel',
            date: exp.date ?? DateTime.now(),
            amountText: '-${_currencyFormat.format(amt)}',
            amountColor: const Color(0xFFE05260),
            rawExpense: exp,
            amountValue: amt,
            paymentMethodName: methodLabel,
          ));
        } else if (cLower.contains('setor modal') || cLower.contains('modal tambahan')) {
          smCounter++;
          recentItems.add(_RecentActivityItem(
            id: exp.id,
            badgeLabel: 'SETOR MODAL',
            badgeBgColor: const Color(0xFFD1FAE5),
            badgeTextColor: const Color(0xFF047857),
            code: 'SM-${smCounter.toString().padLeft(4, '0')}',
            subtitle: '${cleanNote.isNotEmpty ? cleanNote : "Setor Modal"} · $methodLabel',
            date: exp.date ?? DateTime.now(),
            amountText: '+${_currencyFormat.format(amt)}',
            amountColor: const Color(0xFF047857),
            rawExpense: exp,
            amountValue: amt,
            paymentMethodName: methodLabel,
          ));
        } else if (_isInflowCategory(cat, notes: notes)) {
          plCounter++;
          recentItems.add(_RecentActivityItem(
            id: exp.id,
            badgeLabel: 'PEMASUKAN LAIN',
            badgeBgColor: const Color(0xFFD1FAE5),
            badgeTextColor: const Color(0xFF047857),
            code: 'PL-${plCounter.toString().padLeft(4, '0')}',
            subtitle: '$cat${cleanNote.isNotEmpty ? " ($cleanNote)" : ""} · $methodLabel',
            date: exp.date ?? DateTime.now(),
            amountText: '+${_currencyFormat.format(amt)}',
            amountColor: const Color(0xFF047857),
            rawExpense: exp,
            amountValue: amt,
            paymentMethodName: methodLabel,
          ));
        } else {
          byCounter++;
          recentItems.add(_RecentActivityItem(
            id: exp.id,
            badgeLabel: 'BIAYA',
            badgeBgColor: const Color(0xFFFFF1F2),
            badgeTextColor: const Color(0xFFBE123C),
            code: 'BY-${byCounter.toString().padLeft(4, '0')}',
            subtitle: '$cat${cleanNote.isNotEmpty ? " ($cleanNote)" : ""} · $methodLabel',
            date: exp.date ?? DateTime.now(),
            amountText: '-${_currencyFormat.format(amt)}',
            amountColor: const Color(0xFFE05260),
            rawExpense: exp,
            amountValue: amt,
            paymentMethodName: methodLabel,
          ));
        }
      }

      recentItems.sort((a, b) => b.date.compareTo(a.date));

      // 9. Fetch Drawer Cash (Uang Kas di Laci / Modal Kembalian) & Bank base
      final prefs = await SharedPreferences.getInstance();
      final savedDrawer = prefs.getDouble('drawer_base_cash_${widget.storeId}') ?? 0.0;
      final cashMethod = activeMethods.where((m) => m.name.toLowerCase().contains('kas') || m.type == 'cash' || m.type == 'kas').firstOrNull ?? (activeMethods.isNotEmpty ? activeMethods.first : null);
      final effectiveDrawerCash = (cashMethod != null && methodCurrentBalances.containsKey(cashMethod.id))
          ? methodCurrentBalances[cashMethod.id]!
          : savedDrawer;

      if (mounted) {
        setState(() {
          _expenseCategories = catMap;
          _periodTransactions = txs;
          _periodExpenses = exps;
          _supplierSummaries = summaries;
          _totalPiutang = totalPiutang;
          _totalHutangSupplier = totalHutangSup;
          _operationalExpensesSum = opExpSum;
          _totalExpensesSum = totalExpSum;
          _periodOtherIncomeSum = otherIncSum;
          _periodSupplierPurchaseSum = periodPurchaseSum;
          _drawerBaseCash = effectiveDrawerCash;
          _activePaymentMethods = activeMethods;
          _methodCurrentBalances = methodCurrentBalances;
          _realCumulativeSaldoKasBank = realTotalBalance;
          _recentActivities = recentItems;
          _periodSupplierTxs = allSupTxs;
          _isLoadingDetails = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading report detail: $e");
      if (mounted) setState(() => _isLoadingDetails = false);
    }
  }






  Future<void> _handleComprehensiveExport(String format) async {
    try {
      final db = context.read<AppDatabase>();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              SizedBox(width: 12),
              Text("Menyiapkan laporan keuangan lengkap..."),
            ],
          ),
          duration: Duration(seconds: 2),
          backgroundColor: Color(0xFF00BF63),
        ),
      );

      final allTxs = await (db.select(db.transactions)
        ..where((t) => t.storeId.equals(widget.storeId))
        ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
      ).get();

      final allExps = await (db.select(db.expenses)
        ..where((e) => e.storeId.equals(widget.storeId))
        ..orderBy([(e) => OrderingTerm.desc(e.date)])
      ).get();

      // Fetch all-time supplier statistics
      final allTxIds = allTxs.map((t) => t.id).toList();
      final allTxItems = allTxIds.isNotEmpty
          ? await (db.select(db.transactionItems)..where((ti) => ti.transactionId.isIn(allTxIds))).get()
          : <TransactionItem>[];
      final suppliers = await SupplierService(db).getSuppliers(widget.storeId);
      final products = await (db.select(db.products)..where((p) => p.storeId.equals(widget.storeId))).get();
      final prodMap = {for (final p in products) p.id: p};

      final List<Map<String, dynamic>> supplierExports = [];
      final allTxMap = {for (final t in allTxs) t.id: t};
      for (final sup in suppliers) {
        final supProdIds = {...sup.productUsualStock.keys, ...sup.productPrices.keys};
        final supCutoff = sup.lastSettledAt;
        int totalQty = 0;
        double totalCost = 0.0;
        double totalGross = 0.0;
        final List<String> prodNames = [];

        for (final pId in supProdIds) {
          final prod = prodMap[pId];
          final name = prod?.name ?? "Produk #$pId";
          prodNames.add(name);
          final price = sup.productPrices[pId] ?? (prod?.buyPrice ?? prod?.basePrice ?? 0.0);

          final items = allTxItems.where((ti) {
            if (ti.productId != pId) return false;
            final tx = allTxMap[ti.transactionId];
            if (tx == null) return false;
            if (supCutoff != null && (tx.createdAt == null || !tx.createdAt!.isAfter(supCutoff))) {
              return false;
            }
            return true;
          });
          final q = items.fold<int>(0, (s, i) => s + (i.quantity ?? 1));
          final g = items.fold<double>(0.0, (s, i) => s + (i.totalPrice ?? 0.0));
          totalQty += q;
          totalCost += q * price;
          totalGross += g;
        }

        final directPaid = allExps
            .where((e) => e.category == 'Restock Supplier' && (e.notes?.contains(sup.name) ?? false))
            .where((e) => supCutoff == null || (e.date != null && e.date!.isAfter(supCutoff)))
            .fold<double>(0.0, (s, e) => s + (e.amount ?? 0.0));

        supplierExports.add({
          'supplierName': sup.name,
          'phone': sup.phone ?? '-',
          'productNames': prodNames.isEmpty ? 'Belum terhubung' : prodNames.join(", "),
          'totalQtySold': totalQty,
          'totalCost': totalCost + directPaid,
          'totalGross': totalGross,
        });
      }

      final fmtTime = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      Uint8List bytes;
      String filename;
      String mimeType;

      if (format == 'pdf') {
        bytes = await _exportService.generateFinancialReportPdf(
          storeName: "KakiLima Pos",
          transactions: allTxs,
          expenses: allExps,
          supplierReports: supplierExports,
        );
        filename = "Laporan_Keuangan_Lengkap_AllTime_$fmtTime.pdf";
        mimeType = "application/pdf";
      } else if (format == 'excel') {
        bytes = await _exportService.generateFinancialReportExcel(
          storeName: "KakiLima Pos",
          transactions: allTxs,
          expenses: allExps,
          supplierReports: supplierExports,
        );
        filename = "Laporan_Keuangan_Lengkap_AllTime_$fmtTime.xlsx";
        mimeType = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
      } else {
        bytes = _exportService.generateFinancialReportCsv(
          storeName: "KakiLima Pos",
          transactions: allTxs,
          expenses: allExps,
          supplierReports: supplierExports,
        );
        filename = "Laporan_Keuangan_Lengkap_AllTime_$fmtTime.csv";
        mimeType = "text/csv";
      }

      final savedPath = await FileManager().saveAndShareBytes(
        filename,
        bytes,
        mimeType: mimeType,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Laporan keuangan lengkap berhasil disimpan di folder Download\n($filename)",
              style: GoogleFonts.openSans(fontSize: 13, color: Colors.white),
            ),
            backgroundColor: const Color(0xFF00BF63),
            duration: const Duration(seconds: 6),
            action: (savedPath != null)
                ? SnackBarAction(
                    label: "Buka",
                    textColor: Colors.white,
                    onPressed: () => OpenFilex.open(savedPath),
                  )
                : null,
          ),
        );
      }
    } catch (e) {
      debugPrint("Comprehensive Export Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal mengekspor laporan: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getPeriodLabel(AnalyticsController ctrl) {
    switch (ctrl.selectedRange) {
      case ChartRange.today:
        return "Hari Ini (${DateFormat('dd MMM yyyy').format(_startDate)})";
      case ChartRange.sevenDays:
        return "7 Hari Terakhir (${DateFormat('dd MMM').format(_startDate)} - ${DateFormat('dd MMM yyyy').format(_endDate)})";
      case ChartRange.month:
        return "Bulan Ini (${DateFormat('MMMM yyyy').format(_startDate)})";
      case ChartRange.thirtyDays:
        return "30 Hari Terakhir (${DateFormat('dd MMM').format(_startDate)} - ${DateFormat('dd MMM yyyy').format(_endDate)})";
      case ChartRange.allTime:
        return "Semua Waktu";
      case ChartRange.custom:
        return "${DateFormat('dd/MM/yyyy').format(_startDate)} - ${DateFormat('dd/MM/yyyy').format(_endDate)}";
    }
  }

  Future<void> _handleFilteredExport(AnalyticsController controller, String format) async {
    try {
      final fmtTime = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      Uint8List bytes;
      String filename;
      String mimeType;

      final sales = _getCurrentSales(controller);
      final cogs = _getCurrentCOGS(controller);
      final grossProfit = sales - cogs;
      final totalExp = _getCurrentExpenses(controller);
      final netProfit = grossProfit - totalExp;
      final txCount = _getCurrentTxCount(controller);
      final periodLabel = _getPeriodLabel(controller);

      final supplierMaps = _supplierSummaries.map((s) => {
        'supplierName': s.supplier.name,
        'phone': s.supplier.phone ?? '-',
        'productNames': s.productDetails.map((d) => d.productName).join(", "),
        'totalQtySold': s.totalQtySold,
        'totalCost': s.totalSupplierCost + s.directExpensesPaid,
        'totalGross': s.totalGrossSales,
        'netProfit': s.netProfit,
      }).toList();

      if (_selectedTabIndex == 2) {
        // Tab Transaksi
        if (_periodTransactions.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Tidak ada transaksi pada periode $periodLabel untuk diekspor"),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }

        if (format == 'pdf') {
          bytes = await _exportService.generateTransactionsPdf(
            "KakiLima Pos",
            _periodTransactions,
            periodLabel: periodLabel,
            startDate: _startDate,
            endDate: _endDate,
          );
          filename = "Laporan_Transaksi_$fmtTime.pdf";
          mimeType = "application/pdf";
        } else if (format == 'excel') {
          bytes = await _exportService.generateTransactionsExcel(
            "KakiLima Pos",
            _periodTransactions,
            periodLabel: periodLabel,
            startDate: _startDate,
            endDate: _endDate,
          );
          filename = "Laporan_Transaksi_$fmtTime.xlsx";
          mimeType = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
        } else {
          bytes = _exportService.generateTransactionsCsv(
            storeName: "KakiLima Pos",
            startDate: _startDate,
            endDate: _endDate,
            transactions: _periodTransactions,
          );
          filename = "Laporan_Transaksi_$fmtTime.csv";
          mimeType = "text/csv";
        }
      } else if (_selectedTabIndex == 1) {
        // Tab Arus Kas: Mendukung PDF, Excel, dan CSV
        final startDay = DateTime(_startDate.year, _startDate.month, _startDate.day, 0, 0, 0);
        final endDay = DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59);

        double cashSalesSum = 0.0;
        for (final tx in _periodTransactions) {
          final status = tx.status.toLowerCase().trim();
          final isCompleted = status == 'completed' || status == 'lunas' || status == 'success' || status.isEmpty;
          final isDebt = status == 'debt' || status == 'piutang' || status == 'pending';
          if (isCompleted) {
            cashSalesSum += (tx.totalAmount ?? 0.0);
          } else if (isDebt) {
            cashSalesSum += (tx.cashReceived ?? 0.0);
          }
        }

        double setorModalSum = 0.0;
        double pemasukanLainSum = 0.0;
        double terimaPiutangSum = 0.0;
        double biayaOperasionalSum = 0.0;
        double priveSum = 0.0;
        double pembelianTunaiExpenseSum = 0.0;
        double bayarHutangExpenseSum = 0.0;

        for (final exp in _periodExpenses) {
          final cat = exp.category.trim().toLowerCase();
          final notes = (exp.notes ?? '').trim().toLowerCase();
          final double amt = exp.amount ?? 0.0;
          if (cat.contains('transfer') || notes.contains('transfer') || notes.contains('[transfer]')) continue;
          final isInflow = _isInflowCategory(exp.category, notes: exp.notes);
          if (isInflow) {
            if (cat.contains('modal') || notes.contains('modal')) {
              setorModalSum += amt;
            } else if (cat.contains('piutang') || notes.contains('piutang') || notes.contains('terima piutang')) {
              terimaPiutangSum += amt;
            } else {
              pemasukanLainSum += amt;
            }
          } else {
            if (cat.contains('prive') || cat.contains('pribadi') || notes.contains('prive') || notes.contains('pribadi')) {
              priveSum += amt;
            } else if (cat.contains('hutang') || notes.contains('bayar hutang') || notes.contains('pelunasan supplier')) {
              bayarHutangExpenseSum += amt;
            } else if (cat.contains('pembelian') || cat.contains('supplier') || cat.contains('kulakan') || notes.contains('pembelian pasokan')) {
              pembelianTunaiExpenseSum += amt;
            } else {
              biayaOperasionalSum += amt;
            }
          }
        }

        double supPurchaseCashSum = 0.0;
        double supDebtPaymentSum = 0.0;
        for (final stx in _periodSupplierTxs) {
          if (stx.createdAt.isBefore(startDay) || stx.createdAt.isAfter(endDay)) continue;
          if (stx.type == 'purchase') {
            final paid = stx.paymentStatus == 'lunas' ? stx.totalAmount : 0.0;
            supPurchaseCashSum += paid;
          } else if (stx.type == 'payment') {
            supDebtPaymentSum += stx.totalAmount;
          }
        }

        final pembelianTunaiDP = pembelianTunaiExpenseSum > 0 ? pembelianTunaiExpenseSum : supPurchaseCashSum;
        final bayarHutang = bayarHutangExpenseSum > 0 ? bayarHutangExpenseSum : supDebtPaymentSum;
        final kasMasuk = cashSalesSum + setorModalSum + pemasukanLainSum + terimaPiutangSum;
        final kasKeluar = biayaOperasionalSum + priveSum + pembelianTunaiDP + bayarHutang;
        final arusKasBersih = kasMasuk - kasKeluar;

        final accountNotes = <String>[];
        for (final m in _activePaymentMethods) {
          final bal = _methodCurrentBalances[m.id] ?? 0.0;
          accountNotes.add("${m.name} ${_currencyFormat.format(bal)}");
        }
        final balancesNote = accountNotes.isNotEmpty
            ? "Saldo saat ini: ${accountNotes.join(' · ')} (transfer antar akun tidak dihitung arus)."
            : "Saldo saat ini: Kas ${_currencyFormat.format(_drawerBaseCash)} (transfer antar akun tidak dihitung arus).";

        if (format == 'pdf') {
          bytes = await _exportService.generateCashFlowPdf(
            storeName: "KakiLima Pos",
            startDate: _startDate,
            endDate: _endDate,
            penjualanTunaiDP: cashSalesSum > 0 ? cashSalesSum : null,
            terimaPiutang: terimaPiutangSum > 0 ? terimaPiutangSum : null,
            setorModal: setorModalSum > 0 ? setorModalSum : null,
            pemasukanLain: pemasukanLainSum > 0 ? pemasukanLainSum : null,
            biaya: biayaOperasionalSum > 0 ? biayaOperasionalSum : null,
            prive: priveSum > 0 ? priveSum : null,
            pembelianTunaiDP: pembelianTunaiDP > 0 ? pembelianTunaiDP : null,
            bayarHutang: bayarHutang > 0 ? bayarHutang : null,
            totalCashIn: kasMasuk,
            totalCashOut: kasKeluar,
            netCashFlow: arusKasBersih,
            accountBalancesNote: balancesNote,
          );
          filename = "Laporan_Arus_Kas_$fmtTime.pdf";
          mimeType = "application/pdf";
        } else if (format == 'excel') {
          bytes = await _exportService.generateCashFlowExcel(
            storeName: "KakiLima Pos",
            startDate: _startDate,
            endDate: _endDate,
            penjualanTunaiDP: cashSalesSum > 0 ? cashSalesSum : null,
            terimaPiutang: terimaPiutangSum > 0 ? terimaPiutangSum : null,
            setorModal: setorModalSum > 0 ? setorModalSum : null,
            pemasukanLain: pemasukanLainSum > 0 ? pemasukanLainSum : null,
            biaya: biayaOperasionalSum > 0 ? biayaOperasionalSum : null,
            prive: priveSum > 0 ? priveSum : null,
            pembelianTunaiDP: pembelianTunaiDP > 0 ? pembelianTunaiDP : null,
            bayarHutang: bayarHutang > 0 ? bayarHutang : null,
            totalCashIn: kasMasuk,
            totalCashOut: kasKeluar,
            netCashFlow: arusKasBersih,
            accountBalancesNote: balancesNote,
          );
          filename = "Laporan_Arus_Kas_$fmtTime.xlsx";
          mimeType = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
        } else {
          bytes = _exportService.generateCashFlowCsv(
            storeName: "KakiLima Pos",
            startDate: _startDate,
            endDate: _endDate,
            penjualanTunaiDP: cashSalesSum > 0 ? cashSalesSum : null,
            terimaPiutang: terimaPiutangSum > 0 ? terimaPiutangSum : null,
            setorModal: setorModalSum > 0 ? setorModalSum : null,
            pemasukanLain: pemasukanLainSum > 0 ? pemasukanLainSum : null,
            biaya: biayaOperasionalSum > 0 ? biayaOperasionalSum : null,
            prive: priveSum > 0 ? priveSum : null,
            pembelianTunaiDP: pembelianTunaiDP > 0 ? pembelianTunaiDP : null,
            bayarHutang: bayarHutang > 0 ? bayarHutang : null,
            totalCashIn: kasMasuk,
            totalCashOut: kasKeluar,
            netCashFlow: arusKasBersih,
            accountBalancesNote: balancesNote,
          );
          filename = "Laporan_Arus_Kas_$fmtTime.csv";
          mimeType = "text/csv";
        }
      } else {
        // Tab Laba Rugi (_selectedTabIndex == 0) atau Pasokan Supplier (_selectedTabIndex == 4)
        final prefix = _selectedTabIndex == 0
            ? "Laba_Rugi"
            : (_selectedTabIndex == 4 ? "Pasokan_Supplier" : "Keuangan");

        if (format == 'pdf') {
          bytes = await _exportService.generateFinancialReportPdf(
            storeName: "KakiLima Pos",
            transactions: _periodTransactions,
            expenses: _periodExpenses,
            supplierReports: supplierMaps,
            periodLabel: periodLabel,
          );
          filename = "Laporan_${prefix}_$fmtTime.pdf";
          mimeType = "application/pdf";
        } else if (format == 'excel') {
          bytes = await _exportService.generateFinancialReportExcel(
            storeName: "KakiLima Pos",
            transactions: _periodTransactions,
            expenses: _periodExpenses,
            supplierReports: supplierMaps,
            periodLabel: periodLabel,
          );
          filename = "Laporan_${prefix}_$fmtTime.xlsx";
          mimeType = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
        } else {
          // CSV Laba Rugi
          bytes = _exportService.generateProfitLossCsv(
            storeName: "KakiLima Pos",
            startDate: _startDate,
            endDate: _endDate,
            sales: sales,
            cogs: cogs,
            grossProfit: grossProfit,
            expensesByCategory: _expenseCategories,
            totalExpenses: totalExp,
            netProfit: netProfit,
            txCount: txCount,
          );
          filename = "Laporan_Laba_Rugi_$fmtTime.csv";
          mimeType = "text/csv";
        }
      }

      final savedPath = await FileManager().saveAndShareBytes(
        filename,
        bytes,
        mimeType: mimeType,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Laporan berhasil disimpan di folder Download ($filename)",
              style: GoogleFonts.openSans(fontSize: 13, color: Colors.white),
            ),
            backgroundColor: const Color(0xFF00BF63),
            duration: const Duration(seconds: 6),
            action: (savedPath != null)
                ? SnackBarAction(
                    label: "Buka",
                    textColor: Colors.white,
                    onPressed: () => OpenFilex.open(savedPath),
                  )
                : null,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal mengunduh laporan ($format): $e")),
        );
      }
    }
  }

  // ─── Data Helpers ────────────────────────────────────────────────────────
  double _getCurrentSales(AnalyticsController ctrl) {
    switch (ctrl.selectedRange) {
      case ChartRange.today: return ctrl.todaySales;
      case ChartRange.sevenDays: return ctrl.sevenDaysSales;
      case ChartRange.thirtyDays: return ctrl.thirtyDaysSales;
      case ChartRange.month: return ctrl.thisMonthSales;
      case ChartRange.allTime: return ctrl.allTimeSales;
      case ChartRange.custom: return ctrl.customSales;
    }
  }

  double _getCurrentCOGS(AnalyticsController ctrl) {
    switch (ctrl.selectedRange) {
      case ChartRange.today: return ctrl.todayCOGS;
      case ChartRange.sevenDays: return ctrl.sevenDaysCOGS;
      case ChartRange.thirtyDays: return ctrl.thirtyDaysCOGS;
      case ChartRange.month: return ctrl.thisMonthCOGS;
      case ChartRange.allTime: return ctrl.allTimeCOGS;
      case ChartRange.custom: return ctrl.customCOGS;
    }
  }

  double _getCurrentExpenses(AnalyticsController ctrl) {
    switch (ctrl.selectedRange) {
      case ChartRange.today: return ctrl.todayExpenses;
      case ChartRange.sevenDays: return ctrl.sevenDaysExpenses;
      case ChartRange.thirtyDays: return ctrl.thirtyDaysExpenses;
      case ChartRange.month: return ctrl.thisMonthExpenses;
      case ChartRange.allTime: return ctrl.allTimeExpenses;
      case ChartRange.custom: return ctrl.customExpenses;
    }
  }

  int _getCurrentTxCount(AnalyticsController ctrl) {
    switch (ctrl.selectedRange) {
      case ChartRange.today: return ctrl.todayTransactionCount;
      case ChartRange.sevenDays: return ctrl.sevenDaysTransactionCount;
      case ChartRange.thirtyDays: return ctrl.thirtyDaysTransactionCount;
      case ChartRange.month: return ctrl.totalTransactionCount;
      case ChartRange.allTime: return ctrl.allTimeTransactionCount;
      case ChartRange.custom: return ctrl.customTransactionCount;
    }
  }

  void _showFinancialToolsSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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

                  // Header matching Kasir & Tren style
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
                                "Pintasan Cepat Keuangan",
                                style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              "Kelola supplier & ekspor laporan all-time",
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

                // 2-Column Responsive Grid (sebaris dua menu kotak-kotak rapi tanpa overflow)
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
                      // 1. Pelanggan & Supplier
                      _buildFinancialToolCard(
                        icon: Icons.people_alt_outlined,
                        label: "Pelanggan & Supplier",
                        subtitle: "Kontak, piutang & hutang",
                        color: const Color(0xFF0D9488),
                        isDark: isDark,
                        onTap: () {
                          Navigator.pop(ctx);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CustomerPage(
                                onBack: () => Navigator.pop(context),
                              ),
                            ),
                          ).then((_) => _loadDetailData());
                        },
                      ),
                      // 2. Catatan Pengeluaran
                      _buildFinancialToolCard(
                        icon: Icons.payments_outlined,
                        label: "Catatan Pengeluaran",
                        subtitle: "Biaya operasional & kas",
                        color: const Color(0xFFDC2626),
                        isDark: isDark,
                        onTap: () {
                          Navigator.pop(ctx);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ExpenseManagementPage(storeId: widget.storeId),
                            ),
                          ).then((_) => _loadDetailData());
                        },
                      ),
                      // 3. Kirim WA
                      _buildFinancialToolCard(
                        icon: Icons.share_rounded,
                        label: "Kirim WA",
                        subtitle: "Laporan tutup buku WA",
                        color: const Color(0xFF00BF63),
                        isDark: isDark,
                        onTap: () {
                          Navigator.pop(ctx);
                          final controller = context.read<AnalyticsController>();
                          final sales = _getCurrentSales(controller);
                          final cogs = _getCurrentCOGS(controller);
                          final grossProfit = sales - cogs;
                          final operationalExpenses = _operationalExpensesSum;
                          final netProfit = grossProfit - operationalExpenses;
                          final txCount = _getCurrentTxCount(controller);
                          _openWhatsAppReportDialog(
                            context,
                            sales: sales,
                            cogs: cogs,
                            grossProfit: grossProfit,
                            operationalExpenses: operationalExpenses,
                            netProfit: netProfit,
                            txCount: txCount,
                            controller: controller,
                            isDark: isDark,
                          );
                        },
                      ),
                      // 4. Unduh PDF
                      _buildFinancialToolCard(
                        icon: Icons.picture_as_pdf_rounded,
                        label: "Unduh PDF",
                        subtitle: "Laporan all-time PDF",
                        color: Colors.redAccent,
                        isDark: isDark,
                        onTap: () {
                          Navigator.pop(ctx);
                          _handleComprehensiveExport('pdf');
                        },
                      ),
                      // 5. Unduh Excel
                      _buildFinancialToolCard(
                        icon: Icons.table_chart_rounded,
                        label: "Unduh Excel",
                        subtitle: "Workbook all-time Excel",
                        color: const Color(0xFF00BF63),
                        isDark: isDark,
                        onTap: () {
                          Navigator.pop(ctx);
                          _handleComprehensiveExport('excel');
                        },
                      ),
                      // 6. Unduh CSV
                      _buildFinancialToolCard(
                        icon: Icons.description_outlined,
                        label: "Unduh CSV",
                        subtitle: "Ekspor all-time CSV",
                        color: const Color(0xFF0D9488),
                        isDark: isDark,
                        onTap: () {
                          Navigator.pop(ctx);
                          _handleComprehensiveExport('csv');
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

  Widget _buildFinancialToolCard({
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: !_isShowingLaporanView || widget.initialLaporanView,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _isShowingLaporanView && !widget.initialLaporanView) {
          setState(() => _isShowingLaporanView = false);
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        appBar: AppBar(
          leading: _isShowingLaporanView
              ? IconButton(
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  tooltip: widget.initialLaporanView ? "Kembali" : "Kembali ke Halaman Uang",
                  onPressed: () {
                    if (widget.initialLaporanView) {
                      if (widget.onBack != null) {
                        widget.onBack!();
                      } else if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                    } else {
                      setState(() => _isShowingLaporanView = false);
                    }
                  },
                )
              : null,
          title: Text(
            _isShowingLaporanView
                ? (_selectedTabIndex == 4 ? "Pasokan & Supplier" : "Laporan")
                : "Uang",
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              fontSize: 18,
            ),
          ),
          centerTitle: false,
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              height: 1,
            ),
          ),
          actions: [
            if (!_isShowingLaporanView)
              TextButton.icon(
                onPressed: () => setState(() => _isShowingLaporanView = true),
                icon: const Icon(Icons.analytics_outlined, size: 18, color: Color(0xFF00BF63)),
                label: Text(
                  "Laporan",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF00BF63),
                  ),
                ),
              ),
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
                  tooltip: "Pintasan Cepat Keuangan",
                  onPressed: _showFinancialToolsSheet,
                ),
              ),
            ),
          ],
        ),
        body: Consumer<AnalyticsController>(
          builder: (context, controller, child) {
            if (controller.isLoading) {
              return const Center(child: CupertinoActivityIndicator());
            }

            final sales = _getCurrentSales(controller);
            final cogs = _getCurrentCOGS(controller);
            final grossProfit = sales - cogs;
            // Biaya Operasional murni (tidak memotong ganda modal Restock Supplier yang sudah diperhitungkan di HPP):
            final operationalExpenses = _operationalExpensesSum;
            final netProfit = grossProfit - operationalExpenses + _periodOtherIncomeSum;
            final totalCashOut = _totalExpensesSum > 0 ? _totalExpensesSum : _getCurrentExpenses(controller);
            final txCount = _getCurrentTxCount(controller);

            return RefreshIndicator(
              onRefresh: () async {
                await controller.refreshData();
                await _loadDetailData();
              },
              color: const Color(0xFF00BF63),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: !_isShowingLaporanView
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 1. Ringkasan Keuangan 4 Grid (Saldo Kas + Bank, Omzet Hari Ini, Laba, Piutang/Hutang)
                              _buildFinancial4Grid(
                                controller: controller,
                                sales: sales,
                                cogs: cogs,
                                grossProfit: grossProfit,
                                operationalExpenses: operationalExpenses,
                                netProfit: netProfit,
                                totalCashOut: totalCashOut,
                                txCount: txCount,
                                isDark: isDark,
                              ),
                              const SizedBox(height: 14),

                              // 2. 4 Tombol Fitur Aksi Cepat (Kasir, Pembelian, Catat Biaya, Terima Piutang)
                              _buildQuickAction4Buttons(isDark),
                              const SizedBox(height: 16),

                              // 3. Card Aktivitas Terakhir + Tombol "Semua" (Ke Halaman Laporan)
                              _buildRecentActivitiesCard(isDark),
                              const SizedBox(height: 40),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 1. Top Period Filter Dropdown
                              _buildPeriodPills(controller, isDark),
                              const SizedBox(height: 12),

                              // 2. Tab Menu Bar (Laba Rugi, Arus Kas, Transaksi, Grafik)
                              if (_selectedTabIndex != 4) ...[
                                _buildTabBar(isDark),
                                const SizedBox(height: 16),
                              ],

                              // 3. Tab Body Content
                              if (_isLoadingDetails)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 40),
                                  child: Center(child: CupertinoActivityIndicator()),
                                )
                              else ...[
                                if (_selectedTabIndex == 0)
                                  _buildLabaRugiTab(controller, sales, cogs, grossProfit, operationalExpenses, netProfit, txCount, isDark)
                                else if (_selectedTabIndex == 1)
                                  _buildArusKasTab(controller, sales, totalCashOut, isDark)
                                else if (_selectedTabIndex == 2)
                                  _buildTransaksiTab(controller, sales, txCount, isDark)
                                else if (_selectedTabIndex == 3)
                                  _buildGrafikTab(controller, netProfit, isDark)
                                else if (_selectedTabIndex == 4)
                                  _buildPasokanTab(isDark),
                              ],

                              const SizedBox(height: 40),
                            ],
                          ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ─── 1. Period Selector Dropdown (Hemat Tempat & Fungsionalitas Sama) ──────
  Widget _buildPeriodPills(AnalyticsController controller, bool isDark) {
    final isCustom = controller.selectedRange == ChartRange.custom;
    final activeRange = controller.selectedRange == ChartRange.thirtyDays
        ? ChartRange.month
        : controller.selectedRange;

    final customLabel = isCustom
        ? "Tanggal: ${DateFormat('dd/MM/yy').format(_startDate)} - ${DateFormat('dd/MM/yy').format(_endDate)}"
        : "Pilih Tanggal...";

    return Row(
      children: [
        Expanded(
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                width: 1.0,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<ChartRange>(
                value: activeRange,
                isExpanded: true,
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Color(0xFF00BF63),
                  size: 22,
                ),
                dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                items: [
                  DropdownMenuItem(
                    value: ChartRange.today,
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 15, color: Color(0xFF00BF63)),
                        const SizedBox(width: 8),
                        Text(
                          "Periode: Hari Ini",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: ChartRange.sevenDays,
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 15, color: Color(0xFF00BF63)),
                        const SizedBox(width: 8),
                        Text(
                          "Periode: 7 Hari Terakhir",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: ChartRange.month,
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 15, color: Color(0xFF00BF63)),
                        const SizedBox(width: 8),
                        Text(
                          "Periode: Bulan Ini",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: ChartRange.allTime,
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 15, color: Color(0xFF00BF63)),
                        const SizedBox(width: 8),
                        Text(
                          "Periode: Semua Waktu",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: ChartRange.custom,
                    child: Row(
                      children: [
                        const Icon(Icons.date_range_rounded, size: 15, color: Color(0xFF00BF63)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            customLabel,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                onChanged: (val) {
                  if (val == null) return;
                  if (val == ChartRange.custom) {
                    _showRangePicker(controller);
                  } else {
                    _applyRange(val);
                  }
                },
              ),
            ),
          ),
        ),
        if (isCustom) ...[
          const SizedBox(width: 8),
          InkWell(
            onTap: () => _showRangePicker(controller),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF00BF63).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF00BF63), width: 1.2),
              ),
              child: const Icon(
                Icons.edit_calendar_rounded,
                color: Color(0xFF00BF63),
                size: 20,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _showRangePicker(AnalyticsController controller) async {
    final picked = await showDialog<DateTimeRange>(
      context: context,
      builder: (ctx) => GreenDateRangePickerDialog(
        initialStartDate: _startDate,
        initialEndDate: _endDate,
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
      ),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _applyRange(ChartRange.custom);
    }
  }


  // ─── 3. Tab Bar Menu (Lebar Penuh, Tanpa Icon, Tanpa Scroll Horizontal) ────
  Widget _buildTabBar(bool isDark) {
    const tabs = [
      "Laba Rugi",
      "Arus Kas",
      "Transaksi",
      "Grafik",
    ];

    return Row(
      children: List.generate(tabs.length, (idx) {
        final isSelected = _selectedTabIndex == idx;
        final label = tabs[idx];
        const activeColor = Color(0xFF00BF63);

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: idx < tabs.length - 1 ? 6 : 0),
            child: GestureDetector(
              onTap: () => setState(() => _selectedTabIndex = idx),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 9),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? activeColor
                      : (isDark ? const Color(0xFF1E293B) : Colors.white),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected
                        ? activeColor
                        : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                    width: 1.0,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: activeColor.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  // ─── 4. Tab Content: Laba Rugi ────────────────────────────────────────────
  Widget _buildLabaRugiTab(
    AnalyticsController controller,
    double sales,
    double cogs,
    double grossProfit,
    double expenses,
    double netProfit,
    int txCount,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Laporan Laba Rugi",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    _buildExportButton(controller, isDark),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1),

              // Rows
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  children: [
                    _buildReportRow(
                      "Penjualan",
                      _currencyFormat.format(sales),
                      isDark,
                    ),
                    const SizedBox(height: 10),
                    _buildReportRow(
                      "Harga pokok penjualan (HPP)",
                      "- ${_currencyFormat.format(cogs)}",
                      isDark,
                      isNegative: true,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(height: 1),
                    ),
                    _buildReportRow(
                      "Laba Kotor",
                      _currencyFormat.format(grossProfit),
                      isDark,
                      isHighlight: true,
                      highlightColor: const Color(0xFF00BF63),
                    ),
                    const SizedBox(height: 12),

                    // Expenses breakdown by category
                    if (_expenseCategories.isEmpty)
                      _buildReportRow(
                        "Operasional (Belum ada catatan)",
                        "- Rp 0",
                        isDark,
                        isSubItem: true,
                      )
                    else
                      ..._expenseCategories.entries.map((e) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _buildReportRow(
                            e.key,
                            "- ${_currencyFormat.format(e.value)}",
                            isDark,
                            isSubItem: true,
                          ),
                        );
                      }),

                    const SizedBox(height: 4),
                    _buildReportRow(
                      "Biaya operasional",
                      expenses > 0 ? "- ${_currencyFormat.format(expenses)}" : "Rp 0",
                      isDark,
                      isNegative: expenses > 0,
                    ),
                    const SizedBox(height: 10),
                    _buildReportRow(
                      "Pemasukan lain",
                      "+ ${_currencyFormat.format(_periodOtherIncomeSum)}",
                      isDark,
                      highlightColor: const Color(0xFF00BF63),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(height: 1),
                    ),
                    _buildReportRow(
                      "LABA BERSIH",
                      "${netProfit < 0 ? '- ' : ''}${_currencyFormat.format(netProfit.abs())}",
                      isDark,
                      isBoldTotal: true,
                      highlightColor: netProfit >= 0
                          ? const Color(0xFF00BF63)
                          : const Color(0xFFEF4444),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "Pembelian periode ini: ${_currencyFormat.format(_periodSupplierPurchaseSum)} · $txCount nota penjualan. Pembelian menambah stok (bukan biaya) — masuk laba rugi lewat HPP saat barang terjual.",
                        style: GoogleFonts.openSans(
                          fontSize: 11.5,
                          height: 1.4,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildPeriodFooter(isDark),
      ],
    );
  }

  // ─── 5. Tab Content: Arus Kas (Format Detail Niaga POS) ────────────────────
  Widget _buildArusKasTab(
    AnalyticsController controller,
    double sales,
    double expenses,
    bool isDark,
  ) {
    final startDay = DateTime(_startDate.year, _startDate.month, _startDate.day, 0, 0, 0);
    final endDay = DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59);

    // 1. Penjualan tunai/DP
    double cashSalesSum = 0.0;
    for (final tx in _periodTransactions) {
      final status = tx.status.toLowerCase().trim();
      final isCompleted = status == 'completed' || status == 'lunas' || status == 'success' || status.isEmpty;
      final isDebt = status == 'debt' || status == 'piutang' || status == 'pending';
      if (isCompleted) {
        cashSalesSum += (tx.totalAmount ?? 0.0);
      } else if (isDebt) {
        cashSalesSum += (tx.cashReceived ?? 0.0);
      }
    }

    // 2. Streams from Buku Kas (_periodExpenses)
    double setorModalSum = 0.0;
    double pemasukanLainSum = 0.0;
    double terimaPiutangSum = 0.0;
    double biayaOperasionalSum = 0.0;
    double priveSum = 0.0;
    double pembelianTunaiExpenseSum = 0.0;
    double bayarHutangExpenseSum = 0.0;

    for (final exp in _periodExpenses) {
      final cat = exp.category.trim().toLowerCase();
      final notes = (exp.notes ?? '').trim().toLowerCase();
      final double amt = exp.amount ?? 0.0;

      // Transfer antar akun tidak dihitung arus kas
      if (cat.contains('transfer') || notes.contains('transfer') || notes.contains('[transfer]')) {
        continue;
      }

      final isInflow = _isInflowCategory(exp.category, notes: exp.notes);

      if (isInflow) {
        if (cat.contains('modal') || notes.contains('modal')) {
          setorModalSum += amt;
        } else if (cat.contains('piutang') || notes.contains('piutang') || notes.contains('terima piutang')) {
          terimaPiutangSum += amt;
        } else {
          pemasukanLainSum += amt;
        }
      } else {
        if (cat.contains('prive') || cat.contains('pribadi') || notes.contains('prive') || notes.contains('pribadi')) {
          priveSum += amt;
        } else if (cat.contains('hutang') || notes.contains('bayar hutang') || notes.contains('pelunasan supplier')) {
          bayarHutangExpenseSum += amt;
        } else if (cat.contains('pembelian') || cat.contains('supplier') || cat.contains('kulakan') || notes.contains('pembelian pasokan')) {
          pembelianTunaiExpenseSum += amt;
        } else {
          biayaOperasionalSum += amt;
        }
      }
    }

    // 3. Streams from Supplier Transactions (allSupTxs in period)
    double supPurchaseCashSum = 0.0;
    double supDebtPaymentSum = 0.0;
    for (final stx in _periodSupplierTxs) {
      if (stx.createdAt.isBefore(startDay) || stx.createdAt.isAfter(endDay)) continue;
      if (stx.type == 'purchase') {
        final paid = stx.paymentStatus == 'lunas' ? stx.totalAmount : 0.0;
        supPurchaseCashSum += paid;
      } else if (stx.type == 'payment') {
        supDebtPaymentSum += stx.totalAmount;
      }
    }

    final pembelianTunaiDP = pembelianTunaiExpenseSum > 0 ? pembelianTunaiExpenseSum : supPurchaseCashSum;
    final bayarHutang = bayarHutangExpenseSum > 0 ? bayarHutangExpenseSum : supDebtPaymentSum;

    // Totals
    final kasMasuk = cashSalesSum + setorModalSum + pemasukanLainSum + terimaPiutangSum;
    final kasKeluar = biayaOperasionalSum + priveSum + pembelianTunaiDP + bayarHutang;
    final arusKasBersih = kasMasuk - kasKeluar;

    // Current Balances Note
    final accountNotes = <String>[];
    for (final m in _activePaymentMethods) {
      final bal = _methodCurrentBalances[m.id] ?? 0.0;
      accountNotes.add("${m.name} ${_currencyFormat.format(bal)}");
    }
    final balancesNote = accountNotes.isNotEmpty
        ? "Saldo saat ini: ${accountNotes.join(' · ')} (transfer antar akun tidak dihitung arus)."
        : "Saldo saat ini: Kas ${_currencyFormat.format(_drawerBaseCash)} (transfer antar akun tidak dihitung arus).";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card: Laporan Arus Kas + Export Button (PDF, Excel, CSV)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Laporan Arus Kas",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    _buildExportButton(controller, isDark),
                  ],
                ),
              ),
              Divider(height: 1, thickness: 1, color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Item rows: Hanya tampilkan jika terjadi (> 0)
                    if (cashSalesSum > 0)
                      _buildArusKasRow(label: "Penjualan tunai/DP", amount: cashSalesSum, isInflow: true, isDark: isDark),
                    if (terimaPiutangSum > 0)
                      _buildArusKasRow(label: "Terima Piutang", amount: terimaPiutangSum, isInflow: true, isDark: isDark),
                    if (setorModalSum > 0)
                      _buildArusKasRow(label: "Setor Modal", amount: setorModalSum, isInflow: true, isDark: isDark),
                    if (pemasukanLainSum > 0)
                      _buildArusKasRow(label: "Pemasukan Lain", amount: pemasukanLainSum, isInflow: true, isDark: isDark),
                    if (biayaOperasionalSum > 0)
                      _buildArusKasRow(label: "Biaya", amount: biayaOperasionalSum, isInflow: false, isDark: isDark),
                    if (priveSum > 0)
                      _buildArusKasRow(label: "Prive / Pribadi", amount: priveSum, isInflow: false, isDark: isDark),
                    if (pembelianTunaiDP > 0)
                      _buildArusKasRow(label: "Pembelian tunai/DP", amount: pembelianTunaiDP, isInflow: false, isDark: isDark),
                    if (bayarHutang > 0)
                      _buildArusKasRow(label: "Bayar Hutang", amount: bayarHutang, isInflow: false, isDark: isDark),

                    if (cashSalesSum <= 0 && terimaPiutangSum <= 0 && setorModalSum <= 0 && pemasukanLainSum <= 0 && biayaOperasionalSum <= 0 && priveSum <= 0 && pembelianTunaiDP <= 0 && bayarHutang <= 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          "Belum ada mutasi arus kas pada periode ini",
                          style: GoogleFonts.openSans(
                            fontSize: 12.5,
                            fontStyle: FontStyle.italic,
                            color: isDark ? Colors.white54 : const Color(0xFF64748B),
                          ),
                        ),
                      ),

                    const SizedBox(height: 4),
                    Divider(height: 16, thickness: 1, color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),

                    // Kas Masuk
                    _buildArusKasTotalRow(
                      label: "Kas Masuk",
                      amount: kasMasuk,
                      color: const Color(0xFF0D7A4E),
                      isDark: isDark,
                    ),

                    Divider(height: 16, thickness: 1, color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),

                    // Kas Keluar
                    _buildArusKasTotalRow(
                      label: "Kas Keluar",
                      amount: kasKeluar,
                      color: const Color(0xFFE05260),
                      isDark: isDark,
                    ),

                    Divider(height: 16, thickness: 1, color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),

                    // Arus Kas Bersih
                    _buildArusKasTotalRow(
                      label: "Arus Kas Bersih",
                      amount: arusKasBersih,
                      color: arusKasBersih >= 0 ? const Color(0xFF0D7A4E) : const Color(0xFFE05260),
                      isDark: isDark,
                      isLarge: true,
                    ),

                    Divider(height: 16, thickness: 1, color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),

                    // Note on balances
                    Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 4),
                      child: Text(
                        balancesNote,
                        style: GoogleFonts.openSans(
                          fontSize: 11.5,
                          height: 1.45,
                          color: isDark ? Colors.white54 : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Periode under card
        Padding(
          padding: const EdgeInsets.only(top: 12, left: 4),
          child: Text(
            "Periode: ${DateFormat('yyyy-MM-dd').format(_startDate)} s/d ${DateFormat('yyyy-MM-dd').format(_endDate)}",
            style: GoogleFonts.openSans(
              fontSize: 11.5,
              color: isDark ? Colors.white54 : const Color(0xFF64748B),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildArusKasRow({
    required String label,
    required double amount,
    required bool isInflow,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
          ),
          Text(
            "${isInflow ? '+ ' : '- '}${_currencyFormat.format(amount)}",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isInflow ? const Color(0xFF0D7A4E) : const Color(0xFFE05260),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArusKasTotalRow({
    required String label,
    required double amount,
    required Color color,
    required bool isDark,
    bool isLarge = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: isLarge ? 13.5 : 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          Text(
            _currencyFormat.format(amount),
            style: GoogleFonts.plusJakartaSans(
              fontSize: isLarge ? 14 : 13.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ─── 6. Tab Content: Transaksi (Menyatu & Konsisten dengan Aktivitas Terakhir / Buku Kas) ──
  Widget _buildTransaksiTab(
    AnalyticsController controller,
    double sales,
    int txCount,
    bool isDark,
  ) {
    final dayFormat = DateFormat('EEE, d MMM yyyy', 'id_ID');
    final startDay = DateTime(_startDate.year, _startDate.month, _startDate.day);
    final endDay = DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59);

    final periodActivities = controller.selectedRange == ChartRange.allTime
        ? _recentActivities
        : _recentActivities
            .where((item) => !item.date.isBefore(startDay) && !item.date.isAfter(endDay))
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Title di Kiri + Pilihan Export di Kanan
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Riwayat Transaksi (${periodActivities.length})",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    _buildExportButton(controller, isDark),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1),

              if (periodActivities.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                  child: Center(
                    child: Text(
                      "Tidak ada transaksi pada periode ini.",
                      style: GoogleFonts.openSans(
                        fontSize: 13,
                        color: isDark ? Colors.white54 : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: periodActivities.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                  itemBuilder: (context, index) {
                    final item = periodActivities[index];
                    String dateLabel;
                    try {
                      dateLabel = dayFormat.format(item.date);
                    } catch (_) {
                      dateLabel = DateFormat('dd/MM/yyyy').format(item.date);
                    }

                    return InkWell(
                      onTap: () => _openActivityDetail(item),
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
                                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
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
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
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
                                color: isDark && item.amountColor == const Color(0xFF0F172A)
                                    ? Colors.white
                                    : item.amountColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildPeriodFooter(isDark),
      ],
    );
  }

  // ─── 7. Tab Content: Grafik ───────────────────────────────────────────────
  Widget _buildGrafikTab(
    AnalyticsController controller,
    double netProfit,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildChartSection(controller, isDark),
        const SizedBox(height: 24),
        Text(
          "Pertumbuhan Bisnis",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        _buildGrowthIndicators(controller, isDark),
        const SizedBox(height: 12),
        _buildPeriodFooter(isDark),
      ],
    );
  }


  // ─── Shared UI Helpers ────────────────────────────────────────────────────
  Widget _buildExportButton(AnalyticsController controller, bool isDark) {
    return PopupMenuButton<String>(
      onSelected: (format) => _handleFilteredExport(controller, format),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      tooltip: "Pilih Format Ekspor (Sesuai Filter)",
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'pdf',
          child: Row(
            children: [
              const Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent, size: 18),
              const SizedBox(width: 8),
              Text(
                "Ekspor PDF",
                style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'excel',
          child: Row(
            children: [
              const Icon(Icons.table_chart_rounded, color: Color(0xFF00BF63), size: 18),
              const SizedBox(width: 8),
              Text(
                "Ekspor Excel",
                style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'csv',
          child: Row(
            children: [
              const Icon(Icons.description_outlined, color: Color(0xFF0D9488), size: 18),
              const SizedBox(width: 8),
              Text(
                "Ekspor CSV",
                style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.file_download_outlined,
              size: 15,
              color: Color(0xFF00BF63),
            ),
            const SizedBox(width: 4),
            Text(
              "Ekspor",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: isDark ? Colors.white70 : const Color(0xFF64748B),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportRow(
    String label,
    String value,
    bool isDark, {
    bool isNegative = false,
    bool isHighlight = false,
    bool isBoldTotal = false,
    bool isSubItem = false,
    Color? highlightColor,
  }) {
    Color textColor;
    if (highlightColor != null) {
      textColor = highlightColor;
    } else if (isNegative) {
      textColor = isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626);
    } else if (isDark) {
      textColor = Colors.white;
    } else {
      textColor = const Color(0xFF0F172A);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Padding(
          padding: EdgeInsets.only(left: isSubItem ? 16 : 0),
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: isBoldTotal ? 14 : (isSubItem ? 12 : 13),
              fontWeight: isBoldTotal
                  ? FontWeight.w800
                  : (isHighlight ? FontWeight.w700 : FontWeight.w500),
              color: isSubItem
                  ? (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))
                  : (isDark ? Colors.white : const Color(0xFF1E293B)),
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: isBoldTotal ? 16 : 13,
            fontWeight: (isBoldTotal || isHighlight) ? FontWeight.w800 : FontWeight.w600,
            color: textColor,
          ),
        ),
      ],
    );
  }

  // ─── 8. Tab Content: Pasokan Supplier ─────────────────────────────────────
  Widget _buildPasokanTab(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSupplierSummarySection(isDark),
        const SizedBox(height: 16),
        _buildPeriodFooter(isDark),
      ],
    );
  }

  Widget _buildSupplierSummarySection(bool isDark) {
    final totalMoney = _supplierSummaries.fold<double>(0.0, (s, sm) => s + sm.totalMoneyPaidToSupplier);
    final totalGross = _supplierSummaries.fold<double>(0.0, (s, sm) => s + sm.totalGrossSales);
    final totalNetProfit = totalGross - totalMoney;
    final totalPcs = _supplierSummaries.fold<int>(0, (s, sm) => s + sm.totalQtySold);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.local_shipping_outlined, color: Colors.teal, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Laporan Pasokan & Supplier",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Uang modal supplier & produk terjual",
                        style: GoogleFonts.openSans(
                          fontSize: 11.5,
                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: "Mulai dari awal (Reset semua)",
                  child: InkWell(
                    onTap: _confirmResetAllSuppliersReport,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.teal.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.teal.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.restart_alt_rounded, size: 14, color: Colors.teal),
                          const SizedBox(width: 4),
                          Text(
                            "Reset",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.teal,
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
          const Divider(height: 1),

          // Total Metrics Badges (Laba Bersih, Omset, Modal, Terjual)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    // Laba Bersih Supplier
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF0F172A)
                              : (totalNetProfit >= 0 ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2)),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: (totalNetProfit >= 0 ? const Color(0xFF00BF63) : Colors.redAccent)
                                .withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  totalNetProfit >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                                  size: 14,
                                  color: totalNetProfit >= 0 ? const Color(0xFF00BF63) : Colors.redAccent,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "Laba Bersih Supplier",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    color: totalNetProfit >= 0 ? const Color(0xFF00BF63) : Colors.redAccent,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              (totalNetProfit >= 0 ? "+" : "") + _currencyFormat.format(totalNetProfit),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: totalNetProfit >= 0 ? const Color(0xFF00BF63) : Colors.redAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Omset Penjualan Barang Supplier
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.25)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Total Penjualan (Omset)",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: const Color(0xFF2563EB),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _currencyFormat.format(totalGross),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF2563EB),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    // Modal ke Supplier
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF0FDFA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.teal.withValues(alpha: 0.25)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Total Biaya/Modal Supplier",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: Colors.teal,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _currencyFormat.format(totalMoney),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Colors.teal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Barang Terjual
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFD97706).withValues(alpha: 0.25)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Barang Supplier Terjual",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: const Color(0xFFD97706),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "$totalPcs pcs",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFFD97706),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Supplier Breakdown List
          if (_supplierSummaries.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF27272A) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "Belum ada supplier yang terdaftar atau dihubungkan ke produk. Hubungkan produk ke supplier di menu Kelola Supplier.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.openSans(fontSize: 12, color: Colors.grey),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: _supplierSummaries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final summary = _supplierSummaries[index];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? Colors.white12 : Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(Icons.storefront_outlined, size: 16, color: Colors.teal),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    summary.supplier.name,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: (summary.netProfit >= 0 ? const Color(0xFF00BF63) : Colors.redAccent)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: (summary.netProfit >= 0 ? const Color(0xFF00BF63) : Colors.redAccent)
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              "Laba Bersih: ${summary.netProfit >= 0 ? "+" : ""}${_currencyFormat.format(summary.netProfit)}",
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w800,
                                fontSize: 11.5,
                                color: summary.netProfit >= 0 ? const Color(0xFF00BF63) : Colors.redAccent,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Text(
                            "Penjualan: ${_currencyFormat.format(summary.totalGrossSales)}",
                            style: GoogleFonts.openSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : const Color(0xFF334155),
                            ),
                          ),
                          Text("•", style: TextStyle(color: Colors.grey[400])),
                          Text(
                            "Modal: ${_currencyFormat.format(summary.totalMoneyPaidToSupplier)}",
                            style: GoogleFonts.openSans(fontSize: 11, color: Colors.grey),
                          ),
                          Text("•", style: TextStyle(color: Colors.grey[400])),
                          Text(
                            "${summary.totalQtySold} pcs terjual (${summary.productDetails.length} produk)",
                            style: GoogleFonts.openSans(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                      if (summary.productDetails.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        ...summary.productDetails.map((det) {
                          final net = det.netProfit;
                          return Container(
                            margin: const EdgeInsets.only(top: 6),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        det.productName,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      (net >= 0 ? "+" : "") + _currencyFormat.format(net),
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w800,
                                        color: net >= 0 ? const Color(0xFF00BF63) : Colors.redAccent,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "${det.qtySold} pcs  (Beli @ ${_currencyFormat.format(det.unitBuyPrice)}  |  Jual @ ${_currencyFormat.format(det.unitSalePrice)})",
                                      style: GoogleFonts.openSans(
                                        fontSize: 11,
                                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                      ),
                                    ),
                                    Text(
                                      "Laba Bersih",
                                      style: GoogleFonts.openSans(
                                        fontSize: 10,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Omset: ${_currencyFormat.format(det.subtotalGross)}  -  Modal: ${_currencyFormat.format(det.subtotalCost)}",
                                      style: GoogleFonts.openSans(
                                        fontSize: 10.5,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      det.subtotalGross > 0
                                          ? "Margin: ${(net / det.subtotalGross * 100).toStringAsFixed(1)}%"
                                          : "Margin: 0%",
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w600,
                                        color: net >= 0 ? const Color(0xFF00BF63) : Colors.redAccent,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }),
                      ],

                      const SizedBox(height: 10),
                      if (summary.productDetails.isEmpty)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_outline_rounded, size: 16, color: Color(0xFF00BF63)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  summary.supplier.lastSettledAt != null
                                      ? "Semua pasokan sudah lunas. Belum ada penjualan produk baru sejak pelunasan terakhir."
                                      : "Belum ada produk supplier ini yang terjual pada periode ini.",
                                  style: GoogleFonts.openSans(
                                    fontSize: 11,
                                    color: isDark ? Colors.white70 : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (summary.totalSupplierCost > 0 || summary.totalQtySold > 0) ...[
                            OutlinedButton.icon(
                              onPressed: () => _confirmResetSupplierReport(summary.supplier),
                              icon: const Icon(Icons.restart_alt_rounded, size: 14, color: Colors.teal),
                              label: Text(
                                "Reset Pasokan",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.teal,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.teal),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          ElevatedButton.icon(
                            onPressed: () => _openSupplierSettlementModal(summary.supplier),
                            icon: const Icon(Icons.payments_rounded, size: 14, color: Colors.white),
                            label: Text(
                              summary.totalSupplierCost > 0 ? "Lunasi Tagihan Supplier" : "Catat Pelunasan",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00BF63),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              elevation: 0,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Future<void> _confirmResetSupplierReport(Supplier supplier) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.restart_alt_rounded, color: Colors.teal),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                "Mulai dari Awal?",
                style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Text(
          "Kosongkan laporan pasokan berjalan untuk ${supplier.name}? Laporan pasokan dan modal akan direset kembali ke Rp 0 untuk memulai pencatatan baru dari awal.",
          style: GoogleFonts.openSans(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Mulai dari Awal"),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final db = context.read<AppDatabase>();
      final supplierService = SupplierService(db);
      await supplierService.updateSupplier(supplier.copyWith(
        lastSettledAt: DateTime.now(),
        unpaidBalance: 0.0,
      ));
      await _loadDetailData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Laporan pasokan ${supplier.name} telah dikosongkan dan dimulai dari awal."),
            backgroundColor: const Color(0xFF00BF63),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _confirmResetAllSuppliersReport() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.restart_alt_rounded, color: Colors.teal),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                "Mulai dari Awal Semua?",
                style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Text(
          "Kosongkan seluruh laporan pasokan berjalan untuk semua supplier? Laporan pasokan dan modal akan direset kembali ke Rp 0 dan pencatatan baru akan dimulai dari awal.",
          style: GoogleFonts.openSans(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Mulai dari Awal Semua"),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final db = context.read<AppDatabase>();
      final supplierService = SupplierService(db);
      final suppliers = await supplierService.getSuppliers(widget.storeId);
      final now = DateTime.now();
      for (final s in suppliers) {
        await supplierService.updateSupplier(s.copyWith(
          lastSettledAt: now,
          unpaidBalance: 0.0,
        ));
      }
      await _loadDetailData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Seluruh laporan pasokan supplier telah dikosongkan dan dimulai dari awal."),
            backgroundColor: Color(0xFF00BF63),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _openSupplierSettlementModal(Supplier supplier) async {
    final db = context.read<AppDatabase>();
    final supplierService = SupplierService(db);
    final currentBill = await supplierService.getOutstandingBill(widget.storeId, supplier);

    if (!mounted) return;

    final payCtrl = TextEditingController(
      text: currentBill > 0 ? currentBill.toStringAsFixed(0) : '',
    );
    final notesCtrl = TextEditingController();
    String paymentMethod = 'Kas Toko (Tunai)';
    bool isSubmitting = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: SafeArea(
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(ctx).size.height * 0.88,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00BF63).withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.payments_rounded,
                                    color: Color(0xFF00BF63),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Pelunasan Supplier",
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 16.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      supplier.name,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        color: Colors.grey[500],
                                        fontWeight: FontWeight.w500,
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
                      ),
                      const Divider(height: 1),
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: currentBill > 0
                                      ? (isDark ? const Color(0xFF2E2413) : const Color(0xFFFFFBEB))
                                      : (isDark ? const Color(0xFF132A1C) : const Color(0xFFF0FDF4)),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: currentBill > 0
                                        ? (isDark ? Colors.amber[800]!.withValues(alpha: 0.5) : const Color(0xFFFDE68A))
                                        : (isDark ? const Color(0xFF00BF63).withValues(alpha: 0.3) : const Color(0xFFBBF7D0)),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "Tagihan Pasokan Berjalan",
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: isDark ? Colors.grey[300] : Colors.grey[700],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: currentBill > 0 ? Colors.amber : const Color(0xFF00BF63),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            currentBill > 0 ? "Belum Lunas" : "Lunas",
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _currencyFormat.format(currentBill),
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        color: currentBill > 0
                                            ? (isDark ? Colors.amber[300] : const Color(0xFFB45309))
                                            : const Color(0xFF00BF63),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      "Pelunasan akan mereset tagihan supplier ini menjadi Rp 0 (Lunas) & otomatis dicatat sebagai pengeluaran kas. Data profil supplier tetap tersimpan utuh.",
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Nominal Pembayaran (Rp) *",
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (currentBill > 0)
                                    InkWell(
                                      onTap: () {
                                        setSheetState(() {
                                          payCtrl.text = currentBill.toStringAsFixed(0);
                                        });
                                      },
                                      child: Text(
                                        "Lunas Penuh",
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF00BF63),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: payCtrl,
                                keyboardType: TextInputType.number,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                                decoration: InputDecoration(
                                  prefixText: "Rp ",
                                  prefixStyle: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF00BF63),
                                  ),
                                  hintText: "0",
                                  filled: true,
                                  fillColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF8FAFC),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: isDark ? Colors.white12 : Colors.grey[300]!,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFF00BF63), width: 2),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "Metode Pembayaran",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                children: [
                                  'Kas Toko (Tunai)',
                                  'Transfer Bank',
                                  'QRIS / Dompet Digital',
                                ].map((method) {
                                  final isSelected = paymentMethod == method;
                                  return ChoiceChip(
                                    label: Text(
                                      method,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                        color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                                      ),
                                    ),
                                    selected: isSelected,
                                    selectedColor: const Color(0xFF00BF63),
                                    backgroundColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF1F5F9),
                                    onSelected: (val) {
                                      if (val) setSheetState(() => paymentMethod = method);
                                    },
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "Catatan Pelunasan (Opsional)",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: notesCtrl,
                                style: GoogleFonts.plusJakartaSans(fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: "Contoh: Pelunasan pasokan periode ini",
                                  hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.grey),
                                  filled: true,
                                  fillColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF8FAFC),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: isDark ? Colors.white12 : Colors.grey[300]!,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: isSubmitting
                                ? null
                                : () async {
                                    final val = double.tryParse(payCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0.0;
                                    if (val <= 0) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text("Masukkan nominal pembayaran yang valid!"),
                                          backgroundColor: Colors.redAccent,
                                        ),
                                      );
                                      return;
                                    }

                                    setSheetState(() => isSubmitting = true);
                                    try {
                                      final remaining = await supplierService.settleSupplierPayment(
                                        storeId: widget.storeId,
                                        supplier: supplier,
                                        amount: val,
                                        paymentMethod: paymentMethod,
                                        totalBillBeforePayment: currentBill,
                                        notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                                      );

                                      if (ctx.mounted) Navigator.pop(ctx);
                                      await _loadDetailData();

                                      if (mounted) {
                                        TransactionResultDialog.show(
                                          context: this.context,
                                          isSuccess: true,
                                          title: remaining > 0 ? "Pembayaran Sebagian Berhasil!" : "Pelunasan Supplier Berhasil!",
                                          subtitle: remaining > 0
                                              ? "Pembayaran ke ${supplier.name} telah dicatat. Sisa tagihan berjalan."
                                              : "Seluruh tagihan ke ${supplier.name} telah lunas.",
                                          totalAmount: val,
                                          paidAmount: val,
                                          remainingDebt: remaining > 0 ? remaining : null,
                                          statusBadge: remaining > 0 ? "SEBAGIAN" : "LUNAS",
                                          statusBadgeBg: remaining > 0 ? const Color(0xFFFEF3C7) : const Color(0xFFECFDF5),
                                          statusBadgeText: remaining > 0 ? const Color(0xFFB45309) : const Color(0xFF047857),
                                          contactName: supplier.name,
                                          contactRole: "Supplier",
                                          contactPhone: supplier.phone,
                                          accountName: paymentMethod,
                                          category: "Pelunasan Supplier",
                                          notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                                          onShareWhatsApp: () {
                                            SupplierService.shareSettlementToWhatsApp(
                                              phone: supplier.phone,
                                              supplierName: supplier.name,
                                              storeName: "KakiLima Pos",
                                              amountPaid: val,
                                              remainingBalance: remaining,
                                              paymentMethod: paymentMethod,
                                              settledAt: DateTime.now(),
                                              notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                                            );
                                          },
                                        );
                                      }
                                    } catch (e) {
                                      debugPrint("Error settling from report: $e");
                                      if (ctx.mounted) Navigator.pop(ctx);
                                      if (mounted) {
                                        TransactionResultDialog.show(
                                          context: this.context,
                                          isSuccess: false,
                                          title: "Pelunasan Gagal",
                                          subtitle: "Terjadi kesalahan saat memproses pelunasan supplier.",
                                          errorMessage: e.toString(),
                                          totalAmount: val,
                                          contactName: supplier.name,
                                          contactRole: "Supplier",
                                        );
                                      }
                                    }
                                  },
                            icon: isSubmitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Icon(Icons.check_circle_rounded, color: Colors.white),
                            label: Text(
                              isSubmitting ? "Memproses..." : "Konfirmasi Pelunasan & Reset",
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00BF63),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
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
        );
      },
    );
  }

  Widget _buildPeriodFooter(bool isDark) {
    final fmt = DateFormat('yyyy-MM-dd');
    return Center(
      child: Text(
        "Periode: ${fmt.format(_startDate)} s/d ${fmt.format(_endDate)}",
        style: GoogleFonts.openSans(
          fontSize: 12,
          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
        ),
      ),
    );
  }

  // ─── Quick Shortcuts ──────────────────────────────────────────────────────


  // ─── WhatsApp Report Sharing ──────────────────────────────────────────────
  void _openWhatsAppReportDialog(
    BuildContext context, {
    required double sales,
    required double cogs,
    required double grossProfit,
    required double operationalExpenses,
    required double netProfit,
    required int txCount,
    required AnalyticsController controller,
    required bool isDark,
  }) async {
    final db = context.read<AppDatabase>();
    final prefs = await SharedPreferences.getInstance();
    final savedPhone = prefs.getString('owner_wa_phone') ?? '';
    final phoneCtrl = TextEditingController(text: savedPhone);

    String storeName = "Kakilima POS";
    try {
      final store = await (db.select(db.stores)..where((s) => s.id.equals(widget.storeId))).getSingleOrNull();
      if (store != null && store.name != null && store.name!.isNotEmpty) {
        storeName = store.name!;
      }
    } catch (_) {}

    String periodLabel = "Hari Ini (${DateFormat('dd MMM yyyy').format(DateTime.now())})";
    if (controller.selectedRange == ChartRange.sevenDays) {
      periodLabel = "7 Hari Terakhir";
    } else if (controller.selectedRange == ChartRange.month) {
      periodLabel = "Bulan Ini (${DateFormat('MMMM yyyy').format(DateTime.now())})";
    } else if (controller.selectedRange == ChartRange.allTime) {
      periodLabel = "Semua Waktu";
    } else if (controller.selectedRange == ChartRange.custom) {
      periodLabel = "${DateFormat('dd/MM/yy').format(_startDate)} - ${DateFormat('dd/MM/yy').format(_endDate)}";
    }

    final currency = _currencyFormat;

    final buffer = StringBuffer();
    buffer.writeln("📊 *LAPORAN KEUANGAN & TUTUP BUKU*");
    buffer.writeln("🏪 *Toko:* $storeName");
    buffer.writeln("📅 *Periode:* $periodLabel");
    buffer.writeln("─────────────────────────");
    buffer.writeln("💰 *OMZET PENJUALAN:* ${currency.format(sales)} ($txCount Transaksi)");
    buffer.writeln("📦 *HPP (Modal Pokok):* ${currency.format(cogs)}");
    buffer.writeln("📈 *LABA KOTOR:* ${currency.format(grossProfit)}");
    buffer.writeln("📉 *BIAYA OPERASIONAL:* ${currency.format(operationalExpenses)}");
    buffer.writeln("─────────────────────────");
    buffer.writeln("💵 *LABA BERSIH:* ${currency.format(netProfit)}");
    buffer.writeln("─────────────────────────");
    buffer.writeln("🏦 *STATUS SALDO ASET SAAT INI:*");
    buffer.writeln("• Total Saldo Kas + Bank: ${currency.format(_realCumulativeSaldoKasBank)}");
    if (_totalPiutang > 0) {
      buffer.writeln("• Piutang Pelanggan: ${currency.format(_totalPiutang)}");
    }
    buffer.writeln("─────────────────────────");
    buffer.writeln("✨ _Dihasilkan otomatis oleh Sistem POS Kakilima_");

    final reportText = buffer.toString();

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00BF63).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.share_rounded, color: Color(0xFF00BF63), size: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Kirim Laporan ke WhatsApp",
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Nomor WhatsApp Tujuan (Owner):",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : const Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      style: GoogleFonts.plusJakartaSans(
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        hintText: "Contoh: 08123456789 atau kosongkan",
                        hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey),
                        prefixIcon: const Icon(Icons.phone_android_rounded, size: 18, color: Color(0xFF00BF63)),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFF00BF63), width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Pratinjau Pesan:",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : const Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        reportText,
                        style: GoogleFonts.firaCode(
                          fontSize: 11,
                          height: 1.4,
                          color: isDark ? Colors.white70 : const Color(0xFF334155),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: Text("Batal", style: GoogleFonts.plusJakartaSans(color: Colors.grey)),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    SharePlus.instance.share(ShareParams(text: reportText));
                  },
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: const Text("Bagikan Lainnya"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0284C7),
                    side: const BorderSide(color: Color(0xFF0284C7)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    final rawPhone = phoneCtrl.text.trim();
                    if (rawPhone.isNotEmpty) {
                      await prefs.setString('owner_wa_phone', rawPhone);
                    }
                    String targetPhone = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');
                    if (targetPhone.startsWith('0')) {
                      targetPhone = '62${targetPhone.substring(1)}';
                    }

                    Uri waUri;
                    if (targetPhone.isNotEmpty) {
                      waUri = Uri.parse("https://wa.me/$targetPhone?text=${Uri.encodeComponent(reportText)}");
                    } else {
                      waUri = Uri.parse("https://wa.me/?text=${Uri.encodeComponent(reportText)}");
                    }

                    try {
                      if (await canLaunchUrl(waUri)) {
                        await launchUrl(waUri, mode: LaunchMode.externalApplication);
                      } else {
                        await SharePlus.instance.share(ShareParams(text: reportText));
                      }
                    } catch (_) {
                      await SharePlus.instance.share(ShareParams(text: reportText));
                    }

                    if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                  },
                  icon: const Icon(Icons.send_rounded, size: 16, color: Colors.white),
                  label: const Text("Kirim WhatsApp", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00BF63),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ─── Existing Chart & KPI Components ──────────────────────────────────────
  // ─── 4-Grid Financial Overview (Detailed Kas, Omzet, Laba, Piutang) ──────
  Widget _buildFinancial4Grid({
    required AnalyticsController controller,
    required double sales,
    required double cogs,
    required double grossProfit,
    required double operationalExpenses,
    required double netProfit,
    required double totalCashOut,
    required int txCount,
    required bool isDark,
  }) {
    final totalSaldoKasBank = _realCumulativeSaldoKasBank;
    final accountCount = _activePaymentMethods.isNotEmpty ? _activePaymentMethods.where((m) => m.isActive).length : 2;

    // Menentukan label dinamis sesuai rentang waktu yang dipilih
    String omzetTitle = "OMZET PERIODE INI";
    String labaTitle = "LABA PERIODE INI";
    if (controller.selectedRange == ChartRange.today) {
      omzetTitle = "OMZET HARI INI";
      labaTitle = "LABA HARI INI";
    } else if (controller.selectedRange == ChartRange.month) {
      omzetTitle = "OMZET BULAN INI";
      labaTitle = "LABA BULAN INI";
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 768;
        final crossAxisCount = isDesktop ? 4 : 2;

        return GridView(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 110,
          ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            // 1. Saldo Kas + Bank (Uang di Laci + Bank Digital + Akun Lain)
            _buildFinancialGridCard(
              title: "SALDO KAS + BANK",
              value: _currencyFormat.format(totalSaldoKasBank),
              subtitle: "$accountCount akun · kelola keuangan",
              isDark: isDark,
              valueColor: totalSaldoKasBank >= 0 ? const Color(0xFF0D9488) : const Color(0xFFDC2626),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PaymentSettingsPage(storeId: widget.storeId),
                  ),
                ).then((_) {
                  _loadDetailData();
                });
              },
            ),
            // 2. Omzet Penjualan
            _buildFinancialGridCard(
              title: omzetTitle,
              value: _currencyFormat.format(sales),
              subtitle: "$txCount nota",
              isDark: isDark,
              valueColor: isDark ? Colors.white : const Color(0xFF0F172A),
              onTap: () => setState(() {
                _isShowingLaporanView = true;
                _selectedTabIndex = 2;
              }),
            ),
            // 3. Laba Bersih
            _buildFinancialGridCard(
              title: labaTitle,
              value: "${netProfit < 0 ? '- ' : ''}${_currencyFormat.format(netProfit.abs())}",
              subtitle: "setelah HPP & biaya",
              isDark: isDark,
              valueColor: netProfit >= 0 ? const Color(0xFF0D9488) : const Color(0xFFDC2626),
              onTap: () => setState(() {
                _isShowingLaporanView = true;
                _selectedTabIndex = 0;
              }),
            ),
            // 4. Piutang / Hutang
            _buildFinancialGridCard(
              title: "PIUTANG / HUTANG",
              value: _currencyFormat.format(_totalPiutang),
              subtitle: "hutang ${_currencyFormat.format(_totalHutangSupplier)}",
              isDark: isDark,
              valueColor: _totalPiutang > 0
                  ? const Color(0xFF0D7A4E)
                  : (isDark ? Colors.white : const Color(0xFF0F172A)),
              subtitleColor: _totalHutangSupplier > 0 ? const Color(0xFFE05260) : null,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CustomerPage(
                      onBack: () => Navigator.pop(context),
                    ),
                  ),
                ).then((_) => _loadDetailData());
              },
            ),
          ],
        );
      },
    );
  }

  // ─── 4 Tombol Aksi Cepat (Versi Orisinal Kakilima POS) ─────────────────────
  Widget _buildQuickAction4Buttons(bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 768;
        final crossAxisCount = isDesktop ? 4 : 2;

        return GridView(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            mainAxisExtent: 66,
          ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            // 1. Kasir (Hijau Khas Brand POS)
            _buildActionCard(
              label: "Kasir",
              subtitle: "Buka POS Penjualan",
              icon: Icons.point_of_sale_rounded,
              accentColor: const Color(0xFF00BF63),
              isDark: isDark,
              onTap: () {
                if (widget.onNavigateToIndex != null) {
                  widget.onNavigateToIndex!(0);
                } else {
                  Navigator.maybePop(context);
                }
              },
            ),
            // 2. Pembelian (Biru Aset & Pasokan Stok)
            _buildActionCard(
              label: "Pembelian",
              subtitle: "Stok Barang Masuk",
              icon: Icons.inventory_2_outlined,
              accentColor: const Color(0xFF0284C7),
              isDark: isDark,
              onTap: _showPembelianSheet,
            ),
            // 3. Catat Biaya (Merah Muda / Coral Pengeluaran)
            _buildActionCard(
              label: "Catat Biaya",
              subtitle: "Beban Operasional",
              icon: Icons.receipt_long_outlined,
              accentColor: const Color(0xFFE05260),
              isDark: isDark,
              onTap: _showCatatBiayaSheet,
            ),
            // 4. Terima Piutang (Teal Kas Masuk)
            _buildActionCard(
              label: "Terima Piutang",
              subtitle: "Pelunasan Pelanggan",
              icon: Icons.account_balance_wallet_outlined,
              accentColor: const Color(0xFF0D9488),
              isDark: isDark,
              onTap: _showTerimaPiutangSheet,
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionCard({
    required String label,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: isDark ? 0.22 : 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: accentColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
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
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openActivityDetail(_RecentActivityItem item) {
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
    } else if (bLower.contains('prive')) {
      detailType = ActivityDetailType.prive;
    } else if (bLower.contains('setor modal')) {
      detailType = ActivityDetailType.setorModal;
    } else if (bLower.contains('transfer')) {
      detailType = ActivityDetailType.transfer;
    } else if (bLower.contains('pemasukan lain')) {
      detailType = ActivityDetailType.pemasukanLain;
    } else {
      detailType = ActivityDetailType.biaya;
    }

    final double rawAmt = item.rawTransaction?.totalAmount ??
        item.rawSupplierTx?.totalAmount ??
        item.rawExpense?.amount ??
        item.amountValue;

    ActivityDetailSheet.show(
      context: context,
      type: detailType,
      code: item.code,
      title: item.badgeLabel,
      date: item.date,
      amount: rawAmt,
      contactName: item.customerName ?? item.supplierName,
      accountName: item.paymentMethodName ?? (item.rawTransaction?.paymentMethod ?? item.rawSupplierTx?.paymentMethod ?? 'Kas'),
      categoryName: item.rawExpense?.category ?? (bLower.contains('biaya') ? item.badgeLabel : null),
      notes: item.rawExpense?.notes ?? item.rawSupplierTx?.notes,
      isDebt: item.secondaryBadge?.toUpperCase() == 'PIUTANG' || item.secondaryBadge?.toUpperCase() == 'HUTANG' || item.rawTransaction?.status == 'debt',
      paidAmount: item.rawTransaction?.cashReceived ?? (item.rawSupplierTx?.paymentStatus == 'hutang' ? 0.0 : item.rawSupplierTx?.totalAmount),
      remainingDebt: item.rawTransaction != null && item.rawTransaction!.status == 'debt'
          ? (((item.rawTransaction!.totalAmount ?? 0.0) - (item.rawTransaction!.cashReceived ?? 0.0)).clamp(0.0, double.infinity))
          : (item.rawSupplierTx != null && item.rawSupplierTx!.paymentStatus == 'hutang' ? item.rawSupplierTx!.totalAmount : null),
      rawTransaction: item.rawTransaction,
      rawSupplierTx: item.rawSupplierTx,
      rawExpense: item.rawExpense,
      onRefresh: () {
        _loadDetailData();
      },
    );
  }

  // ─── Card Aktivitas Terakhir + Tombol "Semua" (Ke Halaman Laporan) ───────
  Widget _buildRecentActivitiesCard(bool isDark) {
    final dayFormat = DateFormat('EEE, d MMM yyyy', 'id_ID');

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: "Aktivitas Terakhir" + Button "Semua"
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Aktivitas Terakhir",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                InkWell(
                  onTap: () => setState(() {
                    _isShowingLaporanView = true;
                    _selectedTabIndex = 2; // Buka tab Transaksi di Laporan
                  }),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                        width: 1.2,
                      ),
                    ),
                    child: Text(
                      "Semua",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1),

          if (_isLoadingDetails)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CupertinoActivityIndicator()),
            )
          else if (_recentActivities.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
              child: Center(
                child: Text(
                  "Belum ada aktivitas transaksi keuangan.",
                  style: GoogleFonts.openSans(
                    fontSize: 13,
                    color: isDark ? Colors.white54 : const Color(0xFF64748B),
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _recentActivities.length > 12 ? 12 : _recentActivities.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
              itemBuilder: (context, index) {
                final item = _recentActivities[index];
                String dateLabel;
                try {
                  dateLabel = dayFormat.format(item.date);
                } catch (_) {
                  dateLabel = DateFormat('dd/MM/yyyy').format(item.date);
                }

                return InkWell(
                  onTap: () => _openActivityDetail(item),
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
                                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
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
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
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
                            color: isDark && item.amountColor == const Color(0xFF0F172A)
                                ? Colors.white
                                : item.amountColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ─── Bottom Sheet 1: CATAT BIAYA (Gambar 2) ───────────────────────────────
  Future<void> _showCatatBiayaSheet() async {
    final db = context.read<AppDatabase>();
    final pmService = PaymentMethodService(db);
    await pmService.ensureDefaultPaymentMethods(widget.storeId);
    final methods = _activePaymentMethods.isNotEmpty
        ? _activePaymentMethods
        : await pmService.getPaymentMethods(widget.storeId);

    if (!mounted) return;

    DateTime selectedDate = DateTime.now();
    PaymentMethod? selectedMethod = methods.isNotEmpty ? methods.first : null;
    final categoryCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    bool isSaving = false;

    final suggestions = [
      'Listrik & Air',
      'Gaji / Upah',
      'Bensin / Transport',
      'Plastik & Kemasan',
      'Gas / Bahan Bakar',
      'Sewa Tempat',
      'Makan & Minum',
      'Internet / Pulsa',
      'Prive / Pribadi',
    ];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 600,
                    maxHeight: MediaQuery.of(ctx).size.height * 0.9,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "BIAYA",
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
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
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
                        const Divider(height: 1),
                        Flexible(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // TANGGAL
                                _buildSheetFieldLabel("TANGGAL", isDark),
                                const SizedBox(height: 6),
                                InkWell(
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: ctx,
                                      initialDate: selectedDate,
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime.now().add(const Duration(days: 365)),
                                    );
                                    if (picked != null) {
                                      setSheetState(() => selectedDate = picked);
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                                    decoration: _sheetInputBoxDecoration(isDark),
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
                                          color: isDark ? Colors.white70 : const Color(0xFF475569),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),

                                // DIAMBIL DARI AKUN
                                _buildSheetFieldLabel("DIAMBIL DARI AKUN", isDark),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  decoration: _sheetInputBoxDecoration(isDark),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: selectedMethod?.id,
                                      isExpanded: true,
                                      dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                                      items: methods.map((m) {
                                        final bal = _methodCurrentBalances[m.id] ?? 0.0;
                                        return DropdownMenuItem<String>(
                                          value: m.id,
                                          child: Text(
                                            "${m.name} (${_currencyFormat.format(bal)})",
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          final found = methods.firstWhere((m) => m.id == val);
                                          setSheetState(() => selectedMethod = found);
                                        }
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),

                                // KATEGORI BIAYA (Input Bebas + Suggestion Chips)
                                _buildSheetFieldLabel("KATEGORI BIAYA", isDark),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: categoryCtrl,
                                  onChanged: (_) => setSheetState(() {}),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                  decoration: _sheetTextFieldDecoration(
                                    hint: "mis. Listrik & Air (ketik bebas nama biaya)",
                                    isDark: isDark,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: suggestions.map((s) {
                                    final isSelected = categoryCtrl.text.trim().toLowerCase() == s.toLowerCase();
                                    return InkWell(
                                      onTap: () => setSheetState(() => categoryCtrl.text = s),
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? const Color(0xFF00BF63).withValues(alpha: 0.15)
                                              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: isSelected
                                                ? const Color(0xFF00BF63)
                                                : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                                          ),
                                        ),
                                        child: Text(
                                          s,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11.5,
                                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                            color: isSelected
                                                ? const Color(0xFF00BF63)
                                                : (isDark ? Colors.white70 : const Color(0xFF475569)),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 14),

                                // JUMLAH (RP)
                                _buildSheetFieldLabel("JUMLAH (RP)", isDark),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: amountCtrl,
                                  keyboardType: TextInputType.number,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                  decoration: _sheetTextFieldDecoration(
                                    hint: "0",
                                    isDark: isDark,
                                  ),
                                ),
                                const SizedBox(height: 14),

                                // CATATAN
                                _buildSheetFieldLabel("CATATAN", isDark),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: notesCtrl,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                  decoration: _sheetTextFieldDecoration(
                                    hint: "opsional",
                                    isDark: isDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Divider(height: 1),
                        // Bottom Actions
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton(
                                onPressed: () => Navigator.pop(ctx),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  side: BorderSide(
                                    color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                                  ),
                                ),
                                child: Text(
                                  "Batal",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton.icon(
                                onPressed: isSaving
                                    ? null
                                    : () async {
                                        final rawAmt = double.tryParse(
                                              amountCtrl.text.replaceAll(RegExp(r'[^0-9.]'), ''),
                                            ) ??
                                            0.0;
                                        if (rawAmt <= 0) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text("Masukkan jumlah biaya yang valid!"),
                                              backgroundColor: Colors.redAccent,
                                            ),
                                          );
                                          return;
                                        }
                                        if (selectedMethod == null) return;

                                        setSheetState(() => isSaving = true);
                                        final cat = categoryCtrl.text.trim().isEmpty
                                            ? 'Biaya Operasional'
                                            : categoryCtrl.text.trim();

                                        await pmService.recordExpense(
                                          storeId: widget.storeId,
                                          method: selectedMethod!,
                                          category: cat,
                                          amount: rawAmt,
                                          notes: notesCtrl.text.trim(),
                                          date: selectedDate,
                                        );

                                        if (!mounted) return;
                                        final analytics = context.read<AnalyticsController>();
                                        if (ctx.mounted) Navigator.pop(ctx);
                                        await analytics.refreshData();
                                        await _loadDetailData();

                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                "✓ Biaya '$cat' (${_currencyFormat.format(rawAmt)}) berhasil dicatat dari ${selectedMethod!.name}",
                                              ),
                                              backgroundColor: const Color(0xFF0D7A4E),
                                            ),
                                          );
                                        }
                                      },
                                icon: const Icon(Icons.check_rounded, size: 18, color: Colors.white),
                                label: Text(
                                  isSaving ? "Menyimpan..." : "Simpan",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0D7A4E),
                                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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

  // ─── Bottom Sheet 2: TERIMA PIUTANG (Pelunasan Hutang Pelanggan) ──────────
  Future<void> _showTerimaPiutangSheet() async {
    final db = context.read<AppDatabase>();
    final pmService = PaymentMethodService(db);
    await pmService.ensureDefaultPaymentMethods(widget.storeId);
    final methods = _activePaymentMethods.isNotEmpty
        ? _activePaymentMethods
        : await pmService.getPaymentMethods(widget.storeId);

    List<Customer> customers = await (db.select(db.customers)
          ..where((c) => c.storeId.equals(widget.storeId))
          ..orderBy([(c) => OrderingTerm.asc(c.name)]))
        .get();

    final debtTxs = await (db.select(db.transactions)
          ..where((t) => t.storeId.equals(widget.storeId))
          ..where((t) => t.status.equals('debt'))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();

    // Hitung sisa piutang per customerId atau customerName
    final Map<String, double> custDebtMap = {};
    for (final tx in debtTxs) {
      final rem = (tx.totalAmount ?? 0.0) - (tx.cashReceived ?? 0.0);
      if (rem <= 0) continue;
      if (tx.customerId != null && tx.customerId!.isNotEmpty) {
        custDebtMap[tx.customerId!] = (custDebtMap[tx.customerId!] ?? 0.0) + rem;
      }
      if (tx.customerName != null && tx.customerName!.isNotEmpty) {
        for (final c in customers) {
          if ((c.name ?? '').trim().toLowerCase() == tx.customerName!.trim().toLowerCase() && c.id != tx.customerId) {
            custDebtMap[c.id] = (custDebtMap[c.id] ?? 0.0) + rem;
          }
        }
      }
    }

    if (!mounted) return;

    DateTime selectedDate = DateTime.now();
    PaymentMethod? selectedMethod = methods.isNotEmpty ? methods.first : null;
    String? selectedCustomerId;
    for (final c in customers) {
      if ((custDebtMap[c.id] ?? 0) > 0) {
        selectedCustomerId = c.id;
        break;
      }
    }
    selectedCustomerId ??= (customers.isNotEmpty ? customers.first.id : null);

    double initDebt = 0.0;
    if (selectedCustomerId != null && (custDebtMap[selectedCustomerId] ?? 0) > 0) {
      initDebt = custDebtMap[selectedCustomerId]!;
    } else if (_totalPiutang > 0) {
      initDebt = _totalPiutang;
    }

    bool isAddingNewCustomer = customers.isEmpty;
    final newCustomerNameCtrl = TextEditingController();
    final newCustomerPhoneCtrl = TextEditingController();
    final amountCtrl = TextEditingController(
      text: initDebt > 0 ? initDebt.toInt().toString() : '',
    );
    final notesCtrl = TextEditingController();
    bool isSaving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 600,
                    maxHeight: MediaQuery.of(ctx).size.height * 0.9,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "TERIMA PIUTANG",
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
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
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
                        const Divider(height: 1),
                        Flexible(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // TANGGAL
                                _buildSheetFieldLabel("TANGGAL", isDark),
                                const SizedBox(height: 6),
                                InkWell(
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: ctx,
                                      initialDate: selectedDate,
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime.now().add(const Duration(days: 365)),
                                    );
                                    if (picked != null) {
                                      setSheetState(() => selectedDate = picked);
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                                    decoration: _sheetInputBoxDecoration(isDark),
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
                                          color: isDark ? Colors.white70 : const Color(0xFF475569),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),

                                // PELANGGAN (Pilih atau Input Tambah Baru)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildSheetFieldLabel("PELANGGAN", isDark),
                                    InkWell(
                                      onTap: () {
                                        setSheetState(() {
                                          isAddingNewCustomer = !isAddingNewCustomer;
                                        });
                                      },
                                      child: Text(
                                        isAddingNewCustomer
                                            ? (customers.isNotEmpty ? "Pilih dari Daftar Pelanggan" : "")
                                            : "+ Input / Tambah Pelanggan Baru",
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF00BF63),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                if (!isAddingNewCustomer && customers.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14),
                                    decoration: _sheetInputBoxDecoration(isDark),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: selectedCustomerId,
                                        isExpanded: true,
                                        dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                                        hint: const Text("— pilih pelanggan —"),
                                        items: customers.map((c) {
                                          final debt = custDebtMap[c.id] ?? 0.0;
                                          final label = debt > 0
                                              ? "${c.name ?? 'Pelanggan'} (Piutang: ${_currencyFormat.format(debt)})"
                                              : (c.name ?? 'Pelanggan');
                                          return DropdownMenuItem<String>(
                                            value: c.id,
                                            child: Text(
                                              label,
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (val) {
                                          setSheetState(() {
                                            selectedCustomerId = val;
                                            final debt = val != null ? (custDebtMap[val] ?? 0.0) : 0.0;
                                            if (debt > 0) {
                                              amountCtrl.text = debt.toStringAsFixed(0);
                                            }
                                          });
                                        },
                                      ),
                                    ),
                                  )
                                else
                                  Column(
                                    children: [
                                      TextField(
                                        controller: newCustomerNameCtrl,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        ),
                                        decoration: _sheetTextFieldDecoration(
                                          hint: "Ketik nama pelanggan baru...",
                                          isDark: isDark,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      TextField(
                                        controller: newCustomerPhoneCtrl,
                                        keyboardType: TextInputType.phone,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13.5,
                                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        ),
                                        decoration: _sheetTextFieldDecoration(
                                          hint: "No. WhatsApp / Telepon (opsional)",
                                          isDark: isDark,
                                        ),
                                      ),
                                    ],
                                  ),
                                const SizedBox(height: 14),

                                // MASUK KE AKUN
                                _buildSheetFieldLabel("MASUK KE AKUN", isDark),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  decoration: _sheetInputBoxDecoration(isDark),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: selectedMethod?.id,
                                      isExpanded: true,
                                      dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                                      items: methods.map((m) {
                                        final bal = _methodCurrentBalances[m.id] ?? 0.0;
                                        return DropdownMenuItem<String>(
                                          value: m.id,
                                          child: Text(
                                            "${m.name} (${_currencyFormat.format(bal)})",
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          final found = methods.firstWhere((m) => m.id == val);
                                          setSheetState(() => selectedMethod = found);
                                        }
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),

                                // JUMLAH (RP)
                                _buildSheetFieldLabel("JUMLAH DITERIMA (RP)", isDark),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: amountCtrl,
                                  keyboardType: TextInputType.number,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                  decoration: _sheetTextFieldDecoration(
                                    hint: "0",
                                    isDark: isDark,
                                  ),
                                ),
                                const SizedBox(height: 14),

                                // CATATAN
                                _buildSheetFieldLabel("CATATAN", isDark),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: notesCtrl,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                  decoration: _sheetTextFieldDecoration(
                                    hint: "opsional",
                                    isDark: isDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Divider(height: 1),
                        // Bottom Actions
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton(
                                onPressed: () => Navigator.pop(ctx),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  side: BorderSide(
                                    color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                                  ),
                                ),
                                child: Text(
                                  "Batal",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton.icon(
                                onPressed: isSaving
                                    ? null
                                    : () async {
                                        final rawAmt = double.tryParse(
                                              amountCtrl.text.replaceAll(RegExp(r'[^0-9.]'), ''),
                                            ) ??
                                            0.0;
                                        if (rawAmt <= 0) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text("Masukkan jumlah piutang yang diterima!"),
                                              backgroundColor: Colors.redAccent,
                                            ),
                                          );
                                          return;
                                        }
                                        if (selectedMethod == null) return;

                                        String customerName = 'Pelanggan Umum';
                                        String? targetCustId = selectedCustomerId;

                                        if (isAddingNewCustomer) {
                                          final newName = newCustomerNameCtrl.text.trim();
                                          if (newName.isEmpty) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text("Masukkan nama pelanggan terlebih dahulu!"),
                                                backgroundColor: Colors.redAccent,
                                              ),
                                            );
                                            return;
                                          }
                                          setSheetState(() => isSaving = true);
                                          final newId = const Uuid().v4();
                                          await db.into(db.customers).insert(
                                            CustomersCompanion.insert(
                                              id: newId,
                                              storeId: Value(widget.storeId),
                                              name: Value(newName),
                                              phoneNumber: Value(
                                                newCustomerPhoneCtrl.text.trim().isEmpty
                                                    ? null
                                                    : newCustomerPhoneCtrl.text.trim(),
                                              ),
                                              createdAt: Value(DateTime.now()),
                                            ),
                                          );
                                          customerName = newName;
                                          targetCustId = newId;
                                        } else if (targetCustId != null) {
                                          setSheetState(() => isSaving = true);
                                          final c = customers.firstWhere((e) => e.id == targetCustId);
                                          customerName = c.name ?? 'Pelanggan';
                                        } else {
                                          setSheetState(() => isSaving = true);
                                        }

                                        // 1. Jika ada transaksi debt milik pelanggan ini, kurangi/lunasi otomatis
                                        double remainingPayment = rawAmt;
                                        for (final dtx in debtTxs) {
                                          if (remainingPayment <= 0) break;
                                          final matchById = targetCustId != null && dtx.customerId == targetCustId;
                                          final matchByName = (dtx.customerName ?? '').toLowerCase() == customerName.toLowerCase();
                                          if (matchById || matchByName || debtTxs.length == 1) {
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

                                        // 2. Catat pemasukan uang ke akun yang dipilih
                                        final extraNote = notesCtrl.text.trim().isNotEmpty
                                            ? " (${notesCtrl.text.trim()})"
                                            : "";
                                        await pmService.recordInflow(
                                          storeId: widget.storeId,
                                          method: selectedMethod!,
                                          category: 'Terima Piutang',
                                          amount: rawAmt,
                                          notes: "Pelanggan: $customerName$extraNote",
                                          date: selectedDate,
                                        );

                                        if (!mounted) return;
                                        final analytics = context.read<AnalyticsController>();
                                        if (ctx.mounted) Navigator.pop(ctx);
                                        await analytics.refreshData();
                                        await _loadDetailData();

                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                "✓ Penerimaan piutang ${_currencyFormat.format(rawAmt)} dari $customerName masuk ke ${selectedMethod!.name}",
                                              ),
                                              backgroundColor: const Color(0xFF0D7A4E),
                                            ),
                                          );
                                        }
                                      },
                                icon: const Icon(Icons.check_rounded, size: 18, color: Colors.white),
                                label: Text(
                                  isSaving ? "Menyimpan..." : "Simpan",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0D7A4E),
                                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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

  // ─── Bottom Sheet 3: PEMBELIAN / BARANG MASUK (Gambar 3 + Real Product List)
  Future<void> _showPembelianSheet() async {
    final db = context.read<AppDatabase>();
    final supplierService = SupplierService(db);
    final pmService = PaymentMethodService(db);
    await pmService.ensureDefaultPaymentMethods(widget.storeId);

    final suppliers = await supplierService.getSuppliers(widget.storeId);
    final methods = _activePaymentMethods.isNotEmpty
        ? _activePaymentMethods
        : await pmService.getPaymentMethods(widget.storeId);
    final allProducts = await (db.select(db.products)
          ..where((p) => p.storeId.equals(widget.storeId))
          ..where((p) => p.isDeleted.equals(false))
          ..orderBy([(p) => OrderingTerm.asc(p.name)]))
        .get();

    if (!mounted) return;

    DateTime selectedDate = DateTime.now();
    Supplier? selectedSupplier = suppliers.isNotEmpty ? suppliers.first : null;
    PaymentMethod? selectedMethod = methods.isNotEmpty ? methods.first : null;
    final searchCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    final paidCtrl = TextEditingController(text: '0');
    bool updateBuyPrice = true;
    bool isSaving = false;

    // Selected items in table: productId -> {product, qtyCtrl, priceCtrl}
    final List<_PurchaseDraftRow> selectedRows = [];

    void addOrIncrementProduct(Product p, StateSetter setSheetState) {
      final existingIdx = selectedRows.indexWhere((r) => r.product.id == p.id);
      if (existingIdx != -1) {
        final row = selectedRows[existingIdx];
        final curQty = int.tryParse(row.qtyCtrl.text) ?? 1;
        row.qtyCtrl.text = (curQty + 1).toString();
      } else {
        final defaultBuy = (selectedSupplier?.productPrices[p.id]) ??
            (p.buyPrice != null && p.buyPrice! > 0 ? p.buyPrice! : (p.basePrice ?? 0.0));
        selectedRows.add(
          _PurchaseDraftRow(
            product: p,
            qtyCtrl: TextEditingController(text: '1'),
            priceCtrl: TextEditingController(
              text: defaultBuy > 0 ? defaultBuy.toStringAsFixed(0) : '0',
            ),
          ),
        );
      }
      setSheetState(() {});
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final query = searchCtrl.text.trim().toLowerCase();
            final filteredProducts = query.isEmpty
                ? allProducts
                : allProducts.where((p) => (p.name ?? '').toLowerCase().contains(query)).toList();

            double grandTotal = 0.0;
            for (final r in selectedRows) {
              final q = int.tryParse(r.qtyCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
              final pr = double.tryParse(r.priceCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
              grandTotal += q * pr;
            }

            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 680,
                    maxHeight: MediaQuery.of(ctx).size.height * 0.92,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "PEMBELIAN / BARANG MASUK",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              InkWell(
                                onTap: () => Navigator.pop(ctx),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
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
                        const Divider(height: 1),
                        Flexible(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // TANGGAL
                                _buildSheetFieldLabel("TANGGAL", isDark),
                                const SizedBox(height: 6),
                                InkWell(
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: ctx,
                                      initialDate: selectedDate,
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime.now().add(const Duration(days: 365)),
                                    );
                                    if (picked != null) {
                                      setSheetState(() => selectedDate = picked);
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                                    decoration: _sheetInputBoxDecoration(isDark),
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
                                          color: isDark ? Colors.white70 : const Color(0xFF475569),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),

                                // SUPPLIER
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildSheetFieldLabel("SUPPLIER", isDark),
                                    InkWell(
                                      onTap: () {
                                        Navigator.pop(ctx);
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => CustomerPage(
                                              onBack: () => Navigator.pop(context),
                                            ),
                                          ),
                                        ).then((_) => _loadDetailData());
                                      },
                                      child: Text(
                                        suppliers.isEmpty ? "+ Buat Supplier Dulu" : "Kelola Supplier >",
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF00BF63),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  decoration: _sheetInputBoxDecoration(isDark),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: selectedSupplier?.id,
                                      isExpanded: true,
                                      hint: Text(
                                        "— pilih supplier —",
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 14,
                                          color: isDark ? Colors.white54 : const Color(0xFF64748B),
                                        ),
                                      ),
                                      dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                                      items: suppliers.map((s) {
                                        return DropdownMenuItem<String>(
                                          value: s.id,
                                          child: Text(
                                            s.name,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          final sup = suppliers.firstWhere((s) => s.id == val);
                                          setSheetState(() => selectedSupplier = sup);
                                        }
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),

                                // TAMBAH BARANG (Search + Daftar Produk Real Tanpa Gambar, Nama Saja)
                                _buildSheetFieldLabel("TAMBAH BARANG (KETUK PRODUK UNTUK PILIH)", isDark),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: searchCtrl,
                                  onChanged: (_) => setSheetState(() {}),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.5,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                  decoration: InputDecoration(
                                    prefixIcon: const Icon(Icons.search_rounded, size: 19),
                                    hintText: "Ketik nama barang...",
                                    hintStyle: GoogleFonts.openSans(fontSize: 13, color: Colors.grey),
                                    filled: true,
                                    fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // Daftar Produk Real Tanpa Gambar (Nama + Stok + Harga Beli)
                                Container(
                                  constraints: const BoxConstraints(maxHeight: 150),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: filteredProducts.isEmpty
                                      ? Padding(
                                          padding: const EdgeInsets.all(14),
                                          child: Center(
                                            child: Text(
                                              "Produk tidak ditemukan",
                                              style: GoogleFonts.openSans(fontSize: 12.5, color: Colors.grey),
                                            ),
                                          ),
                                        )
                                      : ListView.separated(
                                          shrinkWrap: true,
                                          padding: const EdgeInsets.symmetric(vertical: 4),
                                          itemCount: filteredProducts.length,
                                          separatorBuilder: (_, __) => Divider(
                                            height: 1,
                                            color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                                          ),
                                          itemBuilder: (context, idx) {
                                            final p = filteredProducts[idx];
                                            final isChosen = selectedRows.any((r) => r.product.id == p.id);
                                            final buyP = (selectedSupplier?.productPrices[p.id]) ??
                                                (p.buyPrice != null && p.buyPrice! > 0
                                                    ? p.buyPrice!
                                                    : (p.basePrice ?? 0.0));
                                            final curStk = (p.stockQuantity ?? 0).toInt();

                                            return InkWell(
                                              onTap: () => addOrIncrementProduct(p, setSheetState),
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      isChosen
                                                          ? Icons.check_circle_rounded
                                                          : Icons.add_circle_outline_rounded,
                                                      size: 18,
                                                      color: isChosen
                                                          ? const Color(0xFF00BF63)
                                                          : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        p.name ?? 'Produk',
                                                        style: GoogleFonts.plusJakartaSans(
                                                          fontSize: 13,
                                                          fontWeight: isChosen ? FontWeight.w700 : FontWeight.w600,
                                                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                    Text(
                                                      "Stok: $curStk · Beli: ${_currencyFormat.format(buyP)}",
                                                      style: GoogleFonts.openSans(
                                                        fontSize: 11.5,
                                                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                ),
                                const SizedBox(height: 14),

                                // TABEL BARANG | QTY | HRG BELI | SUBTOTAL
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                                        width: 1.2,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 4,
                                        child: Text(
                                          "BARANG",
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          "QTY",
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          "HRG BELI",
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          "SUBTOTAL",
                                          textAlign: TextAlign.right,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                if (selectedRows.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 20),
                                    child: Center(
                                      child: Text(
                                        "Ketuk barang pada daftar di atas untuk menambahkan.",
                                        style: GoogleFonts.openSans(
                                          fontSize: 12.5,
                                          color: isDark ? Colors.white54 : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: selectedRows.length,
                                    separatorBuilder: (_, __) => Divider(
                                      height: 1,
                                      color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                                    ),
                                    itemBuilder: (context, idx) {
                                      final row = selectedRows[idx];
                                      final q = int.tryParse(row.qtyCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                                      final pr = double.tryParse(row.priceCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
                                      final sub = q * pr;

                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        child: Row(
                                          children: [
                                            // Nama Barang + Hapus
                                            Expanded(
                                              flex: 4,
                                              child: Row(
                                                children: [
                                                  InkWell(
                                                    onTap: () {
                                                      setSheetState(() => selectedRows.removeAt(idx));
                                                    },
                                                    child: const Padding(
                                                      padding: EdgeInsets.only(right: 6),
                                                      child: Icon(Icons.close_rounded, size: 16, color: Colors.redAccent),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: Text(
                                                      row.product.name ?? 'Barang',
                                                      style: GoogleFonts.plusJakartaSans(
                                                        fontSize: 12.5,
                                                        fontWeight: FontWeight.w700,
                                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                                      ),
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            // QTY Input
                                            Expanded(
                                              flex: 2,
                                              child: SizedBox(
                                                height: 36,
                                                child: TextField(
                                                  controller: row.qtyCtrl,
                                                  keyboardType: TextInputType.number,
                                                  textAlign: TextAlign.center,
                                                  onChanged: (_) => setSheetState(() {}),
                                                  style: GoogleFonts.plusJakartaSans(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w700,
                                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                                  ),
                                                  decoration: InputDecoration(
                                                    contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                                                    filled: true,
                                                    fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                                    border: OutlineInputBorder(
                                                      borderRadius: BorderRadius.circular(8),
                                                      borderSide: BorderSide(
                                                        color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            // HRG BELI Input
                                            Expanded(
                                              flex: 3,
                                              child: SizedBox(
                                                height: 36,
                                                child: TextField(
                                                  controller: row.priceCtrl,
                                                  keyboardType: TextInputType.number,
                                                  textAlign: TextAlign.center,
                                                  onChanged: (_) => setSheetState(() {}),
                                                  style: GoogleFonts.plusJakartaSans(
                                                    fontSize: 12.5,
                                                    fontWeight: FontWeight.w700,
                                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                                  ),
                                                  decoration: InputDecoration(
                                                    contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                                                    filled: true,
                                                    fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                                    border: OutlineInputBorder(
                                                      borderRadius: BorderRadius.circular(8),
                                                      borderSide: BorderSide(
                                                        color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            // SUBTOTAL
                                            Expanded(
                                              flex: 3,
                                              child: Text(
                                                _currencyFormat.format(sub),
                                                textAlign: TextAlign.right,
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 12.5,
                                                  fontWeight: FontWeight.w800,
                                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                const SizedBox(height: 12),

                                // Kotak Hijau Total
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.4) : const Color(0xFFE6F4EA),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Total",
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        ),
                                      ),
                                      Text(
                                        _currencyFormat.format(grandTotal),
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF0D7A4E),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 14),

                                // JUMLAH DIBAYAR SEKARANG (OPSIONAL)
                                _buildSheetFieldLabel("PEMBAYARAN SAAT INI (OPSIONAL)", isDark),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: paidCtrl,
                                  keyboardType: TextInputType.number,
                                  onChanged: (_) => setSheetState(() {}),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                  decoration: InputDecoration(
                                    prefixText: "Rp ",
                                    prefixStyle: GoogleFonts.plusJakartaSans(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white70 : const Color(0xFF334155),
                                    ),
                                    hintText: "0",
                                    filled: true,
                                    fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // Quick presets
                                () {
                                  final rawPaid = double.tryParse(paidCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
                                  final actualPaid = rawPaid.clamp(0.0, grandTotal);
                                  final remainingDebt = (grandTotal - actualPaid).clamp(0.0, double.infinity);
                                  final bool isLunas = grandTotal > 0 && remainingDebt <= 0;
                                  final bool isPartial = actualPaid > 0 && remainingDebt > 0;
                                  final bool isFullDebt = actualPaid <= 0;

                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Row(
                                          children: [
                                            InkWell(
                                              onTap: () {
                                                paidCtrl.text = '0';
                                                setSheetState(() {});
                                              },
                                              borderRadius: BorderRadius.circular(8),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: isFullDebt
                                                      ? (isDark ? const Color(0xFF881337).withValues(alpha: 0.35) : const Color(0xFFFFF1F2))
                                                      : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: isFullDebt
                                                        ? const Color(0xFFE05260)
                                                        : (isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                                                  ),
                                                ),
                                                child: Text(
                                                  "Rp 0 (Hutang Penuh)",
                                                  style: GoogleFonts.plusJakartaSans(
                                                    fontSize: 11.5,
                                                    fontWeight: FontWeight.w700,
                                                    color: isFullDebt
                                                        ? const Color(0xFFE05260)
                                                        : (isDark ? Colors.white70 : const Color(0xFF475569)),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            InkWell(
                                              onTap: () {
                                                paidCtrl.text = (grandTotal * 0.5).round().toString();
                                                setSheetState(() {});
                                              },
                                              borderRadius: BorderRadius.circular(8),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: isPartial
                                                      ? (isDark ? const Color(0xFF78350F).withValues(alpha: 0.35) : const Color(0xFFFEF3C7))
                                                      : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: isPartial
                                                        ? const Color(0xFFD97706)
                                                        : (isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                                                  ),
                                                ),
                                                child: Text(
                                                  "50% (Bayar Sebagian)",
                                                  style: GoogleFonts.plusJakartaSans(
                                                    fontSize: 11.5,
                                                    fontWeight: FontWeight.w700,
                                                    color: isPartial
                                                        ? const Color(0xFFD97706)
                                                        : (isDark ? Colors.white70 : const Color(0xFF475569)),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            InkWell(
                                              onTap: () {
                                                paidCtrl.text = grandTotal.round().toString();
                                                setSheetState(() {});
                                              },
                                              borderRadius: BorderRadius.circular(8),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: isLunas
                                                      ? (isDark ? const Color(0xFF064E3B).withValues(alpha: 0.35) : const Color(0xFFECFDF5))
                                                      : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: isLunas
                                                        ? const Color(0xFF00BF63)
                                                        : (isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                                                  ),
                                                ),
                                                child: Text(
                                                  "Lunas (100%)",
                                                  style: GoogleFonts.plusJakartaSans(
                                                    fontSize: 11.5,
                                                    fontWeight: FontWeight.w700,
                                                    color: isLunas
                                                        ? const Color(0xFF00BF63)
                                                        : (isDark ? Colors.white70 : const Color(0xFF475569)),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      // Status Info Box
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                                        decoration: BoxDecoration(
                                          color: isLunas
                                              ? (isDark ? const Color(0xFF064E3B).withValues(alpha: 0.3) : const Color(0xFFECFDF5))
                                              : (isPartial
                                                  ? (isDark ? const Color(0xFF78350F).withValues(alpha: 0.3) : const Color(0xFFFEF3C7))
                                                  : (isDark ? const Color(0xFF881337).withValues(alpha: 0.25) : const Color(0xFFFFF1F2))),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: isLunas
                                                ? const Color(0xFF00BF63).withValues(alpha: 0.4)
                                                : (isPartial
                                                    ? const Color(0xFFD97706).withValues(alpha: 0.4)
                                                    : const Color(0xFFE05260).withValues(alpha: 0.4)),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              isLunas
                                                  ? Icons.check_circle_rounded
                                                  : (isPartial ? Icons.hourglass_bottom_rounded : Icons.info_outline_rounded),
                                              color: isLunas
                                                  ? const Color(0xFF00BF63)
                                                  : (isPartial ? const Color(0xFFD97706) : const Color(0xFFE05260)),
                                              size: 19,
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                isLunas
                                                    ? "Status: LUNAS. Saldo akun akan dipotong ${_currencyFormat.format(actualPaid)}. Tidak ada sisa hutang ke supplier."
                                                    : (isPartial
                                                        ? "Status: HUTANG SEBAGIAN. Kas dipotong ${_currencyFormat.format(actualPaid)}. Sisa ${_currencyFormat.format(remainingDebt)} dicatat sebagai hutang ke supplier."
                                                        : "Status: HUTANG PENUH. Saldo kas tidak dipotong. Total ${_currencyFormat.format(grandTotal)} dicatat sebagai hutang ke supplier."),
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: isLunas
                                                      ? (isDark ? const Color(0xFF6EE7B7) : const Color(0xFF047857))
                                                      : (isPartial
                                                          ? (isDark ? const Color(0xFFFCD34D) : const Color(0xFFB45309))
                                                          : (isDark ? const Color(0xFFFDA4AF) : const Color(0xFFBE123C))),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                }(),
                                const SizedBox(height: 14),

                                // BAYAR DARI AKUN
                                () {
                                  final rawPaid = double.tryParse(paidCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
                                  final actualPaid = rawPaid.clamp(0.0, grandTotal);
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildSheetFieldLabel(
                                        actualPaid > 0
                                            ? "BAYAR DARI AKUN (DIPOTONG RP ${actualPaid.toStringAsFixed(0)})"
                                            : "BAYAR DARI AKUN (OPSIONAL JIKA ADA PEMBAYARAN)",
                                        isDark,
                                      ),
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 14),
                                        decoration: _sheetInputBoxDecoration(isDark),
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton<String>(
                                            value: selectedMethod?.id,
                                            isExpanded: true,
                                            dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                                            items: methods.map((m) {
                                              final bal = _methodCurrentBalances[m.id] ?? 0.0;
                                              return DropdownMenuItem<String>(
                                                value: m.id,
                                                child: Text(
                                                  "${m.name} (${_currencyFormat.format(bal)})",
                                                  style: GoogleFonts.plusJakartaSans(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                            onChanged: (val) {
                                              if (val != null) {
                                                final found = methods.firstWhere((m) => m.id == val);
                                                setSheetState(() => selectedMethod = found);
                                              }
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }(),
                                const SizedBox(height: 12),

                                // Checkbox Perbarui harga beli barang
                                InkWell(
                                  onTap: () => setSheetState(() => updateBuyPrice = !updateBuyPrice),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: Checkbox(
                                            value: updateBuyPrice,
                                            activeColor: const Color(0xFF00BF63),
                                            onChanged: (val) => setSheetState(() => updateBuyPrice = val ?? true),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            "Perbarui harga beli barang sesuai harga di atas",
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // CATATAN OPSIONAL
                                _buildSheetFieldLabel("CATATAN", isDark),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: notesCtrl,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                  decoration: _sheetTextFieldDecoration(
                                    hint: "opsional",
                                    isDark: isDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Divider(height: 1),
                        // Bottom Buttons: Batal & Simpan Pembelian
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton(
                                onPressed: () => Navigator.pop(ctx),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  side: BorderSide(
                                    color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                                  ),
                                ),
                                child: Text(
                                  "Batal",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton.icon(
                                onPressed: isSaving
                                    ? null
                                    : () async {
                                        if (selectedSupplier == null) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text("Pilih supplier terlebih dahulu!"),
                                              backgroundColor: Colors.redAccent,
                                            ),
                                          );
                                          return;
                                        }
                                        final List<SupplierTransactionItem> txItems = [];
                                        for (final r in selectedRows) {
                                          final q = int.tryParse(r.qtyCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                                          final pr = double.tryParse(r.priceCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
                                          if (q > 0) {
                                            txItems.add(
                                              SupplierTransactionItem(
                                                productId: r.product.id,
                                                productName: r.product.name ?? 'Produk',
                                                quantity: q.toDouble(),
                                                unitPrice: pr,
                                                subtotal: q * pr,
                                              ),
                                            );
                                          }
                                        }
                                        if (txItems.isEmpty) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text("Pilih minimal 1 barang dengan Qty > 0!"),
                                              backgroundColor: Colors.redAccent,
                                            ),
                                          );
                                          return;
                                        }

                                        final rawPaid = double.tryParse(paidCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
                                        final actualPaid = rawPaid.clamp(0.0, grandTotal);
                                        final remainingDebt = (grandTotal - actualPaid).clamp(0.0, double.infinity);
                                        final effectiveStatus = remainingDebt > 0 ? 'hutang' : 'lunas';

                                        setSheetState(() => isSaving = true);
                                        try {
                                          final tx = await supplierService.recordPurchase(
                                            storeId: widget.storeId,
                                            supplierId: selectedSupplier!.id,
                                            items: txItems,
                                            paymentStatus: effectiveStatus,
                                            paymentMethod: actualPaid > 0 ? (selectedMethod?.name ?? 'Kas') : 'Hutang',
                                            paymentMethodId: actualPaid > 0 ? selectedMethod?.id : null,
                                            notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                                            amountPaid: actualPaid,
                                            updateBuyPrice: updateBuyPrice,
                                            customDate: selectedDate,
                                          );

                                          if (!mounted) return;
                                          final analytics = context.read<AnalyticsController>();
                                          if (ctx.mounted) Navigator.pop(ctx);
                                          await analytics.refreshData();
                                          await _loadDetailData();

                                          if (mounted) {
                                            final itemSummaries = txItems
                                                .map((it) => "${it.productName} x ${it.quantity.toInt()} (${_currencyFormat.format(it.subtotal)})")
                                                .toList();

                                            TransactionResultDialog.show(
                                              context: context,
                                              isSuccess: true,
                                              title: "Pembelian Barang Berhasil!",
                                              subtitle: "Transaksi pasokan #${tx.transactionNo} telah tersimpan.",
                                              transactionCode: tx.transactionNo,
                                              dateTime: tx.createdAt,
                                              totalAmount: tx.totalAmount,
                                              paidAmount: actualPaid,
                                              remainingDebt: remainingDebt > 0 ? remainingDebt : null,
                                              statusBadge: effectiveStatus == 'lunas' ? 'LUNAS' : 'HUTANG',
                                              statusBadgeBg: effectiveStatus == 'lunas' ? const Color(0xFFECFDF5) : const Color(0xFFFFF1F2),
                                              statusBadgeText: effectiveStatus == 'lunas' ? const Color(0xFF047857) : const Color(0xFFBE123C),
                                              contactName: selectedSupplier!.name,
                                              contactRole: "Supplier",
                                              contactPhone: selectedSupplier!.phone,
                                              accountName: actualPaid > 0 ? (selectedMethod?.name ?? 'Kas') : 'Hutang (Tanpa Potong Saldo)',
                                              category: "Pembelian Pasokan",
                                              notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                                              itemSummaries: itemSummaries,
                                            );
                                          }
                                        } catch (e) {
                                          debugPrint("Error recordPurchase: $e");
                                          if (ctx.mounted) Navigator.pop(ctx);
                                          if (mounted) {
                                            TransactionResultDialog.show(
                                              context: context,
                                              isSuccess: false,
                                              title: "Pembelian Gagal",
                                              subtitle: "Terjadi kesalahan saat memproses pembelian pasokan.",
                                              errorMessage: e.toString(),
                                              totalAmount: grandTotal,
                                              contactName: selectedSupplier?.name,
                                              contactRole: "Supplier",
                                            );
                                          }
                                        }
                                      },
                                icon: const Icon(Icons.check_rounded, size: 18, color: Colors.white),
                                label: Text(
                                  isSaving ? "Menyimpan..." : "Simpan Pembelian",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0D7A4E),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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

  Widget _buildSheetFieldLabel(String text, bool isDark) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
      ),
    );
  }

  BoxDecoration _sheetInputBoxDecoration(bool isDark) {
    return BoxDecoration(
      color: isDark ? const Color(0xFF0F172A) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: isDark ? const Color(0xFF334155) : const Color(0xFF94A3B8),
        width: 1.2,
      ),
    );
  }

  InputDecoration _sheetTextFieldDecoration({required String hint, required bool isDark}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.openSans(
        fontSize: 13.5,
        color: isDark ? Colors.white38 : const Color(0xFF64748B),
      ),
      filled: true,
      fillColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF334155) : const Color(0xFF94A3B8),
          width: 1.2,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF334155) : const Color(0xFF94A3B8),
          width: 1.2,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF0D7A4E), width: 1.6),
      ),
    );
  }

  Widget _buildFinancialGridCard({
    required String title,
    required String value,
    required String subtitle,
    required bool isDark,
    required VoidCallback onTap,
    Color? valueColor,
    Color? subtitleColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              width: 1.2,
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  letterSpacing: 0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 7),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: valueColor ?? (isDark ? Colors.white : const Color(0xFF0F172A)),
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              const SizedBox(height: 7),
              Text(
                subtitle,
                style: GoogleFonts.openSans(
                  fontSize: 12,
                  fontWeight: subtitleColor != null ? FontWeight.w700 : FontWeight.w500,
                  color: subtitleColor ?? (isDark ? Colors.white60 : const Color(0xFF64748B)),
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

  Widget _buildChartSection(AnalyticsController controller, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Grafik Pendapatan",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        PinterestCard(
          padding: const EdgeInsets.fromLTRB(10, 24, 24, 16),
          child: SizedBox(
            height: 200,
            child: controller.chartData.isEmpty
                ? Center(
                    child: Text(
                      "Belum ada data grafik",
                      style: GoogleFonts.openSans(color: Colors.grey),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.black.withValues(alpha: 0.05),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 45,
                            getTitlesWidget: (value, meta) {
                              return SideTitleWidget(
                                meta: meta,
                                space: 8,
                                child: Text(
                                  NumberFormat.compactSimpleCurrency(
                                    locale: 'id',
                                  ).format(value),
                                  style: GoogleFonts.openSans(
                                    fontSize: 10,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              final idx = value.toInt();
                              final interval = controller.chartLabelInterval;
                              if (idx >= 0 && idx < controller.chartData.length) {
                                if (idx % interval == 0) {
                                  return SideTitleWidget(
                                    meta: meta,
                                    space: 8,
                                    child: Text(
                                      controller.chartData[idx]['label'],
                                      style: GoogleFonts.openSans(
                                        fontSize: 10,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  );
                                }
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: List.generate(controller.chartData.length, (i) {
                            return FlSpot(
                              i.toDouble(),
                              controller.chartData[i]['amount'],
                            );
                          }),
                          isCurved: true,
                          curveSmoothness: 0.35,
                          color: const Color(0xFF00BF63),
                          barWidth: 3,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF00BF63).withValues(alpha: 0.25),
                                const Color(0xFF00BF63).withValues(alpha: 0.0),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildGrowthIndicators(AnalyticsController controller, bool isDark) {
    return Column(
      children: [
        _buildGrowthCard("Mingguan", controller.weeklyGrowth, isDark),
        const SizedBox(height: 12),
        _buildGrowthCard("Bulanan", controller.monthlyGrowth, isDark),
      ],
    );
  }

  Widget _buildGrowthCard(String label, double growth, bool isDark) {
    final isPositive = growth >= 0;
    final color = isPositive
        ? const Color(0xFF00BF63)
        : const Color(0xFFEF4444);

    return PinterestCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isPositive
                  ? CupertinoIcons.graph_circle_fill
                  : CupertinoIcons.graph_circle,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  isPositive ? "Kenaikan performa" : "Penurunan performa",
                  style: GoogleFonts.openSans(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          Text(
            "${isPositive ? '+' : ''}${growth.toStringAsFixed(1)}%",
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class SupplierReportSummary {
  final Supplier supplier;
  final int totalQtySold;
  final double totalSupplierCost;
  final double totalGrossSales;
  final double directExpensesPaid;
  final List<SupplierProductDetail> productDetails;

  SupplierReportSummary({
    required this.supplier,
    required this.totalQtySold,
    required this.totalSupplierCost,
    required this.totalGrossSales,
    required this.directExpensesPaid,
    required this.productDetails,
  });

  double get totalMoneyPaidToSupplier => totalSupplierCost + directExpensesPaid + supplier.unpaidBalance;
  double get netProfit => totalGrossSales - totalSupplierCost;
}

class SupplierProductDetail {
  final String productId;
  final String productName;
  final int qtySold;
  final double unitBuyPrice;
  final double unitSalePrice;
  final double subtotalCost;
  final double subtotalGross;

  SupplierProductDetail({
    required this.productId,
    required this.productName,
    required this.qtySold,
    required this.unitBuyPrice,
    required this.unitSalePrice,
    required this.subtotalCost,
    required this.subtotalGross,
  });

  double get netProfit => subtotalGross - subtotalCost;
}

class _RecentActivityItem {
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
  final double amountValue;
  final String? customerName;
  final String? supplierName;
  final String? paymentMethodName;

  _RecentActivityItem({
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
    this.amountValue = 0.0,
    this.customerName,
    this.supplierName,
    this.paymentMethodName,
  });
}

class _PurchaseDraftRow {
  final Product product;
  final TextEditingController qtyCtrl;
  final TextEditingController priceCtrl;

  _PurchaseDraftRow({
    required this.product,
    required this.qtyCtrl,
    required this.priceCtrl,
  });
}
