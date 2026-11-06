import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../controllers/admin_controller.dart';
import '../../services/app_database.dart';
import '../../services/platform/file_manager.dart';
import '../../services/supplier_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:drift/drift.dart' show Value, OrderingTerm;
import 'package:uuid/uuid.dart';
import '../../widgets/activity_detail_sheet.dart';
import '../../widgets/transaction_result_dialog.dart';

class PaymentSettingsPage extends StatefulWidget {
  final String storeId;
  const PaymentSettingsPage({super.key, required this.storeId});

  @override
  State<PaymentSettingsPage> createState() => _PaymentSettingsPageState();
}

enum FinancialRecordType {
  sale,
  expense,
  otherIncome,
  capital,
  prive,
  transfer,
  purchase,
  payDebt,
  receivePiutang,
  returnItem,
  reconciliation,
}

class FinancialRecord {
  final String id;
  final String code;
  final FinancialRecordType type;
  final String badgeLabel;
  final Color badgeBgColor;
  final Color badgeTextColor;
  final String? secondaryBadge;
  final Color? secondaryBadgeBg;
  final Color? secondaryBadgeText;
  final String title;
  final String subtitle;
  final String rawCategory;
  final String rawNotes;
  final String methodName;
  final double amount;
  final String amountText;
  final Color amountColor;
  final bool isIncome;
  final DateTime date;
  final Expense? expenseSource;
  final SupplierTransaction? supplierTxSource;
  final bool canEdit;
  final bool canDelete;

  FinancialRecord({
    required this.id,
    this.code = '',
    required this.type,
    required this.badgeLabel,
    required this.badgeBgColor,
    required this.badgeTextColor,
    this.secondaryBadge,
    this.secondaryBadgeBg,
    this.secondaryBadgeText,
    required this.title,
    required this.subtitle,
    required this.rawCategory,
    required this.rawNotes,
    required this.methodName,
    required this.amount,
    required this.amountText,
    required this.amountColor,
    required this.isIncome,
    required this.date,
    this.expenseSource,
    this.supplierTxSource,
    required this.canEdit,
    required this.canDelete,
  });
}

class _QuickActionItem {
  final IconData icon;
  final String label;
  final Color iconColor;
  final VoidCallback onTap;

  const _QuickActionItem({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.onTap,
  });
}

class _PaymentSettingsPageState extends State<PaymentSettingsPage> with SingleTickerProviderStateMixin {
  final Color _primaryColor = const Color(0xFF00BF63);
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  bool _isLoading = true;
  List<PaymentMethod> _methods = [];
  List<FinancialRecord> _financialRecords = [];
  String _selectedAccountFilter = 'Semua Akun';
  String _selectedTypeFilter = 'Semua';
  String _selectedDateFilter = 'Semua';

  Map<String, double> _initialBalances = {};
  Map<String, double> _incomes = {};
  Map<String, double> _outflows = {};
  Map<String, double> _inflows = {};
  Map<String, double> _currentBalances = {};
  double _todayCashSalesSum = 0.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final adminCtrl = context.read<AdminController>();
      final service = adminCtrl.paymentMethodService;
      final db = context.read<AppDatabase>();

      // 1. Ensure default accounts & fetch all payment methods
      await service.ensureDefaultPaymentMethods(widget.storeId);
      final methods = await service.getPaymentMethods(widget.storeId);

      // 2. Fetch and calculate summaries per method (including sales transactions)
      final summaries = await service.calculateMethodSummaries(widget.storeId);
      final initialMap = summaries.map((k, v) => MapEntry(k, v.initialBalance));
      final incomeMap = summaries.map((k, v) => MapEntry(k, v.salesIncome));
      final inflowMap = summaries.map((k, v) => MapEntry(k, v.otherInflow));
      final outflowMap = summaries.map((k, v) => MapEntry(k, v.totalOutflow));
      final balanceMap = summaries.map((k, v) => MapEntry(k, v.currentBalance));

      // 3. Fetch pure financial records for Buku Kas:
      // Biaya, Pemasukan Lain, Transfer, Terima Piutang, Bayar Hutang, Setor Modal, Prive, dan Cek Fisik Kas
      // (Tidak termasuk Penjualan & Pembelian barang)
      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);
      final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);
      double todayCashSales = 0.0;
      final allStoreTxs = await (db.select(db.transactions)).get();
      final validTodayTxs = allStoreTxs.where((t) {
        final s = t.status.toLowerCase().trim();
        final isStore = t.storeId == null || t.storeId == widget.storeId || t.storeId == 'default_store';
        return isStore && s != 'cancelled' && s != 'batal';
      }).toList();

      for (final tx in validTodayTxs) {
        final dt = tx.createdAt;
        if (dt != null && !dt.isBefore(startOfToday) && !dt.isAfter(endOfToday)) {
          final m = (tx.paymentMethod ?? 'tunai').toLowerCase().trim();
          if (m.contains('tunai') || m.contains('kas') || m.contains('cash') || m.isEmpty) {
            final effectiveAmt = (tx.status == 'debt') ? (tx.cashReceived ?? 0.0) : (tx.totalAmount ?? 0.0);
            todayCashSales += effectiveAmt;
          }
        }
      }

      final supplierService = SupplierService(db);
      final suppliers = await supplierService.getSuppliers(widget.storeId);
      final supNameMap = {for (final s in suppliers) s.id: s.name};
      final allSupTxs = await supplierService.getAllStoreTransactions(widget.storeId);

      final allExpsAsc = await (db.select(db.expenses)
            ..where((e) => e.storeId.equals(widget.storeId))
            ..orderBy([(e) => OrderingTerm.asc(e.date)]))
          .get();

      final List<FinancialRecord> records = [];

      // a) Bayar Hutang ke Supplier (BH-xxxx)
      for (final stx in allSupTxs) {
        if (stx.type == 'payment') {
          final supName = supNameMap[stx.supplierId] ?? 'Supplier';
          final mName = (stx.paymentMethod != null && stx.paymentMethod!.isNotEmpty)
              ? stx.paymentMethod!
              : 'Kas';
          final stxNote = (stx.notes ?? '').trim();
          final noteSuffix = stxNote.isNotEmpty ? ' · $stxNote' : '';
          records.add(FinancialRecord(
            id: stx.id,
            code: stx.transactionNo,
            type: FinancialRecordType.payDebt,
            badgeLabel: 'BAYAR HUTANG',
            badgeBgColor: const Color(0xFFFFF1F2),
            badgeTextColor: const Color(0xFFBE123C),
            title: 'Bayar Hutang',
            subtitle: 'Ke $supName · $mName$noteSuffix',
            rawCategory: 'Bayar Hutang',
            rawNotes: stx.notes ?? '',
            methodName: mName,
            amount: stx.totalAmount,
            amountText: '-${_currencyFormat.format(stx.totalAmount)}',
            amountColor: const Color(0xFFE05260),
            isIncome: false,
            date: stx.createdAt,
            supplierTxSource: stx,
            canEdit: false,
            canDelete: false,
          ));
        } else if (stx.type == 'purchase') {
          final supName = supNameMap[stx.supplierId] ?? 'Supplier';
          final isHutang = stx.paymentStatus.toLowerCase() == 'hutang';
          final paid = stx.paidAmount;
          final mName = (stx.paymentMethod != null && stx.paymentMethod!.isNotEmpty)
              ? stx.paymentMethod!
              : (paid > 0 ? 'Kas' : 'Hutang');
          final stxNote = (stx.notes ?? '').trim();
          final noteSuffix = stxNote.isNotEmpty ? ' · $stxNote' : '';
          records.add(FinancialRecord(
            id: stx.id,
            code: stx.transactionNo,
            type: FinancialRecordType.purchase,
            badgeLabel: 'PEMBELIAN',
            badgeBgColor: const Color(0xFFFEF3C7),
            badgeTextColor: const Color(0xFFB45309),
            secondaryBadge: isHutang ? 'HUTANG' : 'LUNAS',
            secondaryBadgeBg: isHutang ? const Color(0xFFFFF1F2) : const Color(0xFFECFDF5),
            secondaryBadgeText: isHutang ? const Color(0xFFBE123C) : const Color(0xFF047857),
            title: 'Pembelian Stok',
            subtitle: 'Dari $supName$noteSuffix',
            rawCategory: 'Pembelian',
            rawNotes: stx.notes ?? '',
            methodName: mName,
            amount: paid, // Uang yang benar-benar keluar dari kas/bank saat pembelian
            amountText: _currencyFormat.format(stx.totalAmount),
            amountColor: const Color(0xFFE05260),
            isIncome: false,
            date: stx.createdAt,
            supplierTxSource: stx,
            canEdit: false,
            canDelete: false,
          ));
        } else if (stx.type == 'return') {
          final supName = supNameMap[stx.supplierId] ?? 'Supplier';
          final isLunas = stx.paymentStatus.toLowerCase() == 'lunas';
          final mName = (stx.paymentMethod != null && stx.paymentMethod!.isNotEmpty)
              ? stx.paymentMethod!
              : (isLunas ? 'Kas' : '-');
          final stxNote = (stx.notes ?? '').trim();
          final noteSuffix = stxNote.isNotEmpty ? ' · $stxNote' : '';
          records.add(FinancialRecord(
            id: stx.id,
            code: stx.transactionNo,
            type: FinancialRecordType.returnItem,
            badgeLabel: 'RETUR PEMBELIAN',
            badgeBgColor: const Color(0xFFF1F5F9),
            badgeTextColor: const Color(0xFF475569),
            secondaryBadge: isLunas ? 'DANA KEMBALI' : 'POTONG HUTANG',
            secondaryBadgeBg: isLunas ? const Color(0xFFECFDF5) : const Color(0xFFFEF3C7),
            secondaryBadgeText: isLunas ? const Color(0xFF047857) : const Color(0xFFB45309),
            title: 'Retur ke Supplier',
            subtitle: 'Ke $supName · ${isLunas ? 'Masuk ke $mName' : 'Potong hutang'}$noteSuffix',
            rawCategory: 'Retur Pembelian',
            rawNotes: stx.notes ?? '',
            methodName: mName,
            amount: isLunas ? stx.paidAmount : 0.0, // Jika lunas, dihitung kas masuk; jika hutang, 0.0 (tidak dihitung di buku kas)
            amountText: isLunas ? '+${_currencyFormat.format(stx.totalAmount)}' : _currencyFormat.format(stx.totalAmount),
            amountColor: isLunas ? const Color(0xFF0D7A4E) : const Color(0xFF64748B),
            isIncome: isLunas,
            date: stx.createdAt,
            supplierTxSource: stx,
            canEdit: false,
            canDelete: false,
          ));
        }
      }

      // b) Biaya, Pemasukan Lain, Transfer, Terima Piutang, Bayar Hutang, Setor Modal, Prive, dan Cek Fisik Kas
      int prCounter = 0;
      int tfCounter = 0;
      int smCounter = 0;
      int plCounter = 0;
      int tpCounter = 0;
      int bhCounter = 0;
      int cfCounter = 0;
      int byCounter = 0;

      for (final exp in allExpsAsc) {
        final notes = exp.notes ?? '';
        // Skip duplicate expense entries automatically created by PB-xxxx, BH-xxxx, or RB-xxxx
        if (notes.contains('(PB-') || notes.contains('(BH-') || notes.contains('(RB-')) {
          continue;
        }
        final cat = exp.category.trim().isEmpty ? 'Biaya' : exp.category.trim();
        final amt = exp.amount ?? 0.0;
        final expDate = exp.date ?? DateTime.now();

        String detectedMethod = 'Kas';
        for (final m in methods) {
          if (notes.contains('[${m.name}]') ||
              notes.toLowerCase().contains('dari ${m.name.toLowerCase()}') ||
              notes.toLowerCase().contains('ke ${m.name.toLowerCase()}') ||
              notes.toLowerCase().contains(m.name.toLowerCase())) {
            detectedMethod = m.name;
            break;
          }
        }

        final cleanNote = notes
            .replaceAll(RegExp(r'\[[^\]]+\]'), '')
            .replaceAll(RegExp(r'\(Tarik dari [^\)]+\)'), '')
            .trim();

        final cLower = cat.toLowerCase();
        final isInflow = cat == 'Pemasukan Lain' ||
            cat == 'Setor Modal' ||
            cLower.contains('piutang') ||
            cLower.contains('pemasukan') ||
            cLower.contains('modal') ||
            cLower.contains('cashback') ||
            cLower.contains('bonus') ||
            cLower.contains('tip') ||
            cLower.contains('bunga') ||
            cLower.contains('titipan') ||
            notes.contains('[INFLOW]');

        if (cat == 'Cek Fisik Kas' || cLower.contains('cek fisik') || notes.contains('[CEK_FISIK]')) {
          cfCounter++;
          final code = 'CF-${cfCounter.toString().padLeft(4, '0')}';
          final isLebih = notes.contains('Lebih');
          final isKurang = notes.contains('Kurang');
          records.add(FinancialRecord(
            id: exp.id,
            code: code,
            type: FinancialRecordType.reconciliation,
            badgeLabel: 'CEK FISIK KAS',
            badgeBgColor: const Color(0xFFFEF3C7),
            badgeTextColor: const Color(0xFFD97706),
            secondaryBadge: isLebih ? 'LEBIH' : (isKurang ? 'KURANG' : 'COCOK'),
            secondaryBadgeBg: isLebih
                ? const Color(0xFFE0F2FE)
                : (isKurang ? const Color(0xFFFFF1F2) : const Color(0xFFECFDF5)),
            secondaryBadgeText: isLebih
                ? const Color(0xFF0369A1)
                : (isKurang ? const Color(0xFFBE123C) : const Color(0xFF065F46)),
            title: 'Cek Fisik Kas',
            subtitle: '${cleanNote.isNotEmpty ? cleanNote : "Rekonsiliasi Kas"} · $detectedMethod',
            rawCategory: cat,
            rawNotes: notes,
            methodName: detectedMethod,
            amount: amt,
            amountText: amt == 0
                ? 'Rp 0'
                : '${isLebih ? '+' : (isKurang ? '-' : '')}${_currencyFormat.format(amt)}',
            amountColor: isLebih
                ? const Color(0xFF0284C7)
                : (isKurang ? const Color(0xFFE05260) : const Color(0xFF0D8A50)),
            isIncome: isLebih,
            date: expDate,
            expenseSource: exp,
            canEdit: false,
            canDelete: true,
          ));
        } else if (cat == 'Prive / Tarik Saldo' || cLower.contains('prive') || cLower.contains('tarik')) {
          prCounter++;
          final code = 'PR-${prCounter.toString().padLeft(4, '0')}';
          records.add(FinancialRecord(
            id: exp.id,
            code: code,
            type: FinancialRecordType.prive,
            badgeLabel: 'PRIVE / PRIBADI',
            badgeBgColor: const Color(0xFFFEF3C7),
            badgeTextColor: const Color(0xFFB45309),
            title: 'Prive / Pribadi',
            subtitle: 'Prive / Pribadi · $detectedMethod',
            rawCategory: cat,
            rawNotes: notes,
            methodName: detectedMethod,
            amount: amt,
            amountText: '-${_currencyFormat.format(amt)}',
            amountColor: const Color(0xFFE05260),
            isIncome: false,
            date: expDate,
            expenseSource: exp,
            canEdit: true,
            canDelete: true,
          ));
        } else if (cat == 'Transfer Saldo') {
          tfCounter++;
          final code = 'TF-${tfCounter.toString().padLeft(4, '0')}';
          records.add(FinancialRecord(
            id: exp.id,
            code: code,
            type: FinancialRecordType.transfer,
            badgeLabel: 'TRANSFER',
            badgeBgColor: const Color(0xFFE0E7FF),
            badgeTextColor: const Color(0xFF4338CA),
            title: 'Transfer Saldo',
            subtitle: '${cleanNote.isNotEmpty ? cleanNote : cat} · $detectedMethod',
            rawCategory: cat,
            rawNotes: notes,
            methodName: detectedMethod,
            amount: amt,
            amountText: _currencyFormat.format(amt),
            amountColor: const Color(0xFF4338CA),
            isIncome: false,
            date: expDate,
            expenseSource: exp,
            canEdit: true,
            canDelete: true,
          ));
        } else if (cLower.contains('piutang')) {
          tpCounter++;
          final code = 'TP-${tpCounter.toString().padLeft(4, '0')}';
          records.add(FinancialRecord(
            id: exp.id,
            code: code,
            type: FinancialRecordType.receivePiutang,
            badgeLabel: 'TERIMA PIUTANG',
            badgeBgColor: const Color(0xFFD1FAE5),
            badgeTextColor: const Color(0xFF047857),
            title: 'Terima Piutang',
            subtitle: '${cleanNote.isNotEmpty ? cleanNote : "Terima Piutang"} · $detectedMethod',
            rawCategory: cat,
            rawNotes: notes,
            methodName: detectedMethod,
            amount: amt,
            amountText: '+${_currencyFormat.format(amt)}',
            amountColor: const Color(0xFF047857),
            isIncome: true,
            date: expDate,
            expenseSource: exp,
            canEdit: true,
            canDelete: true,
          ));
        } else if (cLower.contains('hutang')) {
          bhCounter++;
          final code = 'BH-${bhCounter.toString().padLeft(4, '0')}';
          records.add(FinancialRecord(
            id: exp.id,
            code: code,
            type: FinancialRecordType.payDebt,
            badgeLabel: 'BAYAR HUTANG',
            badgeBgColor: const Color(0xFFFFF1F2),
            badgeTextColor: const Color(0xFFBE123C),
            title: 'Bayar Hutang',
            subtitle: '${cleanNote.isNotEmpty ? cleanNote : "Bayar Hutang"} · $detectedMethod',
            rawCategory: cat,
            rawNotes: notes,
            methodName: detectedMethod,
            amount: amt,
            amountText: '-${_currencyFormat.format(amt)}',
            amountColor: const Color(0xFFE05260),
            isIncome: false,
            date: expDate,
            expenseSource: exp,
            canEdit: true,
            canDelete: true,
          ));
        } else if (cat == 'Setor Modal' || cLower.contains('modal')) {
          smCounter++;
          final code = 'SM-${smCounter.toString().padLeft(4, '0')}';
          records.add(FinancialRecord(
            id: exp.id,
            code: code,
            type: FinancialRecordType.capital,
            badgeLabel: 'SETOR MODAL',
            badgeBgColor: const Color(0xFFD1FAE5),
            badgeTextColor: const Color(0xFF047857),
            title: 'Setor Modal',
            subtitle: '$cat · $detectedMethod',
            rawCategory: cat,
            rawNotes: notes,
            methodName: detectedMethod,
            amount: amt,
            amountText: '+${_currencyFormat.format(amt)}',
            amountColor: const Color(0xFF047857),
            isIncome: true,
            date: expDate,
            expenseSource: exp,
            canEdit: true,
            canDelete: true,
          ));
        } else if (isInflow) {
          plCounter++;
          final code = 'PL-${plCounter.toString().padLeft(4, '0')}';
          records.add(FinancialRecord(
            id: exp.id,
            code: code,
            type: FinancialRecordType.otherIncome,
            badgeLabel: 'PEMASUKAN LAIN',
            badgeBgColor: const Color(0xFFD1FAE5),
            badgeTextColor: const Color(0xFF047857),
            title: cat,
            subtitle: '$cat · $detectedMethod',
            rawCategory: cat,
            rawNotes: notes,
            methodName: detectedMethod,
            amount: amt,
            amountText: '+${_currencyFormat.format(amt)}',
            amountColor: const Color(0xFF047857),
            isIncome: true,
            date: expDate,
            expenseSource: exp,
            canEdit: true,
            canDelete: true,
          ));
        } else {
          // Biaya Operasional Toko
          byCounter++;
          final code = 'BY-${byCounter.toString().padLeft(4, '0')}';
          records.add(FinancialRecord(
            id: exp.id,
            code: code,
            type: FinancialRecordType.expense,
            badgeLabel: 'BIAYA',
            badgeBgColor: const Color(0xFFFFF1F2),
            badgeTextColor: const Color(0xFFBE123C),
            title: cat,
            subtitle: '$cat · $detectedMethod',
            rawCategory: cat,
            rawNotes: notes,
            methodName: detectedMethod,
            amount: amt,
            amountText: '-${_currencyFormat.format(amt)}',
            amountColor: const Color(0xFFE05260),
            isIncome: false,
            date: expDate,
            expenseSource: exp,
            canEdit: true,
            canDelete: true,
          ));
        }
      }

      records.sort((a, b) => b.date.compareTo(a.date));

      if (mounted) {
        setState(() {
          _methods = methods;
          _financialRecords = records;
          _initialBalances = initialMap;
          _incomes = incomeMap;
          _outflows = outflowMap;
          _inflows = inflowMap;
          _currentBalances = balanceMap;
          _todayCashSalesSum = todayCashSales;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading financial data: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<FinancialRecord> get _filteredRecords {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final sevenDaysAgo = startOfToday.subtract(const Duration(days: 6));
    final startOfMonth = DateTime(now.year, now.month, 1);

    return _financialRecords.where((r) {
      if (_selectedAccountFilter != 'Semua Akun') {
        if (!r.methodName.toLowerCase().contains(_selectedAccountFilter.toLowerCase())) {
          return false;
        }
      }
      if (_selectedTypeFilter == 'Masuk' && (!r.isIncome || r.type == FinancialRecordType.purchase)) return false;
      if (_selectedTypeFilter == 'Keluar' && (r.isIncome || r.type == FinancialRecordType.purchase)) return false;

      if (_selectedDateFilter == 'Hari Ini') {
        if (r.date.isBefore(startOfToday) || r.date.isAfter(endOfToday)) return false;
      } else if (_selectedDateFilter == '7 Hari') {
        if (r.date.isBefore(sevenDaysAgo) || r.date.isAfter(endOfToday)) return false;
      } else if (_selectedDateFilter == 'Bulan Ini') {
        if (r.date.isBefore(startOfMonth) || r.date.isAfter(endOfToday)) return false;
      }

      return true;
    }).toList();
  }





  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          "Keuangan",
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth >= 680;

                return RefreshIndicator(
                  onRefresh: _loadData,
                  color: _primaryColor,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                        children: [
                          // 1. Paling Atas: Akun (bisa ditambah & dikurang)
                          _buildAkunSection(isDark, isDesktop),
                          const SizedBox(height: 20),

                          // 2. Di Tengah: Catat Keuangan
                          _buildMenuCepatBar(isDark),
                          const SizedBox(height: 20),

                          // 3. Paling Bawah: Buku Kas
                          _buildBukuKasSection(isDark),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildAkunSection(bool isDark, bool isDesktop) {
    return Container(
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 13, 16, 11),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      "Akun & Saldo",
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
                        color: _primaryColor.withValues(alpha: isDark ? 0.2 : 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "${_methods.length} Akun",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                InkWell(
                  onTap: () => _showAddEditMethodDialog(),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_circle_outline_rounded, size: 14, color: _primaryColor),
                        const SizedBox(width: 4),
                        Text(
                          "Tambah",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _primaryColor,
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
          Padding(
            padding: const EdgeInsets.all(12),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isDesktop ? 3 : 2,
                mainAxisExtent: 88,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: _methods.length + 1,
              itemBuilder: (context, index) {
                if (index == _methods.length) {
                  return _buildAddAccountGridCard(isDark);
                }
                return _buildMethodCard(_methods[index], isDark, isGrid: true);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddAccountGridCard(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.3) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
          width: 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showAddEditMethodDialog(),
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: _primaryColor.withValues(alpha: isDark ? 0.2 : 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.add_rounded,
                    size: 18,
                    color: _primaryColor,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  "Tambah Akun",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBukuKasSection(bool isDark) {
    final filtered = _filteredRecords;

    return Container(
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      "Buku Kas",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "${filtered.length} Transaksi",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    _buildCompactTypeFilterChip("Semua", isDark),
                    const SizedBox(width: 4),
                    _buildCompactTypeFilterChip("Masuk", isDark),
                    const SizedBox(width: 4),
                    _buildCompactTypeFilterChip("Keluar", isDark),
                  ],
                ),
              ],
            ),
          ),
          Divider(height: 1, color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Row(
              children: [
                // Dropdown 1: Periode Waktu
                Expanded(
                  child: _buildBukuKasDropdown<String>(
                    value: _selectedDateFilter,
                    items: [
                      DropdownMenuItem(
                        value: 'Semua',
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today_rounded, size: 14, color: _primaryColor),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Text(
                                "Semua Waktu",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _primaryColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'Hari Ini',
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today_rounded, size: 14, color: _primaryColor),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Text(
                                "Hari Ini",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _primaryColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: '7 Hari',
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today_rounded, size: 14, color: _primaryColor),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Text(
                                "7 Hari",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _primaryColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'Bulan Ini',
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today_rounded, size: 14, color: _primaryColor),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Text(
                                "Bulan Ini",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _primaryColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedDateFilter = val);
                      }
                    },
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 10),
                // Dropdown 2: Metode / Akun
                Expanded(
                  child: _buildBukuKasDropdown<String>(
                    value: (_methods.any((m) => m.name == _selectedAccountFilter) || _selectedAccountFilter == 'Semua Akun')
                        ? _selectedAccountFilter
                        : 'Semua Akun',
                    items: [
                      DropdownMenuItem(
                        value: 'Semua Akun',
                        child: Row(
                          children: [
                            Icon(Icons.account_balance_wallet_outlined, size: 14, color: _primaryColor),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Text(
                                "Semua Akun",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _primaryColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ..._methods.map(
                        (m) => DropdownMenuItem(
                          value: m.name,
                          child: Row(
                            children: [
                              Icon(Icons.account_balance_wallet_outlined, size: 14, color: _primaryColor),
                              const SizedBox(width: 7),
                              Expanded(
                                child: Text(
                                  m.name,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: _primaryColor,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedAccountFilter = val);
                      }
                    },
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
          if (filtered.isEmpty)
            _buildEmptyTransactionsState(isDark)
          else
            ...List.generate(filtered.length, (i) {
              return Column(
                children: [
                  _buildFinancialRecordCard(filtered[i], isDark),
                  if (i < filtered.length - 1)
                    Divider(
                      height: 1,
                      color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                    ),
                ],
              );
            }),
        ],
      ),
    );
  }

  Widget _buildCompactTypeFilterChip(String label, bool isDark) {
    final isSelected = _selectedTypeFilter == label;
    Color activeColor = _primaryColor;
    if (label == 'Masuk') activeColor = const Color(0xFF00BF63);
    if (label == 'Keluar') activeColor = const Color(0xFFE05260);

    return InkWell(
      onTap: () {
        setState(() {
          _selectedTypeFilter = label;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: isDark ? 0.25 : 0.12)
              : (isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? activeColor : Colors.transparent,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? activeColor : (isDark ? Colors.white60 : const Color(0xFF64748B)),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCepatBar(bool isDark) {
    return Container(
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 13, 16, 11),
            child: Text(
              "Catat Keuangan",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ),
          Divider(height: 1, color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
          Padding(
            padding: const EdgeInsets.all(12),
            child: LayoutBuilder(
              builder: (context, c) {
                final isWide = c.maxWidth >= 600;
                final items = [
                  _QuickActionItem(
                    icon: Icons.credit_card_outlined,
                    label: "Biaya",
                    iconColor: const Color(0xFFE05260),
                    onTap: () => _showAddExpenseDialog(),
                  ),
                  _QuickActionItem(
                    icon: Icons.add_circle_outline_rounded,
                    label: "Pemasukan Lain",
                    iconColor: const Color(0xFF16A34A),
                    onTap: () => _showAddInflowDialog(),
                  ),
                  _QuickActionItem(
                    icon: Icons.swap_horiz_rounded,
                    label: "Transfer",
                    iconColor: const Color(0xFF0284C7),
                    onTap: () => _showQuickTransferDialog(),
                  ),
                  _QuickActionItem(
                    icon: Icons.check_circle_outline_rounded,
                    label: "Terima Piutang",
                    iconColor: const Color(0xFF0D9488),
                    onTap: () => _showTerimaPiutangDialog(),
                  ),
                  _QuickActionItem(
                    icon: Icons.credit_card_rounded,
                    label: "Bayar Hutang",
                    iconColor: const Color(0xFFE05260),
                    onTap: () => _showBayarHutangDialog(),
                  ),
                  _QuickActionItem(
                    icon: Icons.vertical_align_bottom_rounded,
                    label: "Setor Modal",
                    iconColor: const Color(0xFF059669),
                    onTap: () => _showSetorModalDialog(),
                  ),
                  _QuickActionItem(
                    icon: Icons.undo_rounded,
                    label: "Prive",
                    iconColor: const Color(0xFF9333EA),
                    onTap: () => _showPriveQuickDialog(),
                  ),
                  _QuickActionItem(
                    icon: Icons.balance_rounded,
                    label: "Cek Fisik Kas",
                    iconColor: const Color(0xFFD97706),
                    onTap: () => _showReconciliationDialog(),
                  ),
                ];

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isWide ? 4 : 2,
                    mainAxisExtent: 40,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _buildUniformQuickActionCard(
                      icon: item.icon,
                      label: item.label,
                      iconColor: item.iconColor,
                      onTap: item.onTap,
                      isDark: isDark,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUniformQuickActionCard({
    required IconData icon,
    required String label,
    required Color iconColor,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Material(
      color: isDark ? const Color(0xFF0F172A) : Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
              width: 1.0,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBukuKasDropdown<T>({
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    required bool isDark,
  }) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFCBD5E1),
          width: 1.0,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: _primaryColor, size: 20),
          isExpanded: true,
          dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: _primaryColor,
          ),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  void _openRecordDetail(FinancialRecord record) {
    ActivityDetailType detailType;
    final bLower = record.badgeLabel.toLowerCase();
    if (bLower.contains('retur') || record.type == FinancialRecordType.returnItem) {
      detailType = ActivityDetailType.retur;
    } else if (bLower.contains('pembelian') || record.type == FinancialRecordType.purchase) {
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

    ActivityDetailSheet.show(
      context: context,
      type: detailType,
      code: record.code,
      title: record.badgeLabel,
      date: record.date,
      amount: record.supplierTxSource != null && (record.type == FinancialRecordType.purchase || record.type == FinancialRecordType.returnItem)
          ? record.supplierTxSource!.totalAmount
          : record.amount,
      isDebt: record.secondaryBadge == 'HUTANG' || record.secondaryBadge == 'POTONG HUTANG',
      paidAmount: record.supplierTxSource?.paidAmount,
      remainingDebt: record.type == FinancialRecordType.purchase
          ? ((record.supplierTxSource?.totalAmount ?? record.amount) - (record.supplierTxSource?.paidAmount ?? 0.0)).clamp(0.0, double.infinity)
          : null,
      contactName: record.subtitle.contains('·')
          ? record.subtitle.split('·').first.replaceAll(RegExp(r'^(Ke|Dari|Pelanggan:|Supplier:)\s*'), '').trim()
          : (record.subtitle.startsWith('Dari ')
              ? record.subtitle.replaceFirst('Dari ', '')
              : (record.subtitle.startsWith('Ke ') ? record.subtitle.replaceFirst('Ke ', '') : null)),
      accountName: record.methodName,
      categoryName: record.rawCategory,
      notes: record.rawNotes,
      rawSupplierTx: record.supplierTxSource,
      rawExpense: record.expenseSource,
      onRefresh: () {
        _loadData();
      },
    );
  }

  Widget _buildFinancialRecordCard(FinancialRecord record, bool isDark) {
    String dateLabel;
    try {
      dateLabel = DateFormat('EEE, d MMM yyyy', 'id_ID').format(record.date);
    } catch (_) {
      dateLabel = DateFormat('dd/MM/yyyy').format(record.date);
    }

    return InkWell(
      onTap: () => _openRecordDetail(record),
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
                          color: record.badgeBgColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          record.badgeLabel,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: record.badgeTextColor,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      Text(
                        record.code,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      if (record.secondaryBadge != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: record.secondaryBadgeBg ?? const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            record.secondaryBadge!,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: record.secondaryBadgeText ?? const Color(0xFFB45309),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    record.subtitle,
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
              record.amountText,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark && record.amountColor == const Color(0xFF0F172A)
                    ? Colors.white
                    : record.amountColor,
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildEmptyTransactionsState(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_rounded,
              size: 40,
              color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            "Belum Ada Transaksi",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Transaksi pengeluaran biaya, penjualan kasir, atau mutasi akun akan muncul di sini.",
            textAlign: TextAlign.center,
            style: GoogleFonts.openSans(
              fontSize: 12,
              color: isDark ? Colors.white60 : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddExpenseDialog() async {
    final activeMethods = _methods.where((m) => m.isActive).toList();
    if (activeMethods.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tidak ada akun kas/metode pembayaran yang aktif")),
      );
      return;
    }

    PaymentMethod selectedMethod = activeMethods.first;
    final categoryCtrl = TextEditingController();
    final amountCtrl = TextEditingController(text: '0');
    final notesCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();

    final suggestions = [
      'Listrik & Air',
      'Gaji & Upah',
      'Operasional',
      'Sewa Tempat',
      'Bahan Baku & Dapur',
      'Promosi & Pemasaran',
    ];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final dark = Theme.of(ctx).brightness == Brightness.dark;
            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              decoration: BoxDecoration(
                color: dark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "BIAYA",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: dark ? Colors.white : const Color(0xFF0F172A),
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
                                color: dark ? Colors.white24 : const Color(0xFFCBD5E1),
                              ),
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              size: 20,
                              color: dark ? Colors.white70 : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Divider(height: 1, color: dark ? Colors.white12 : const Color(0xFFE2E8F0)),
                    const SizedBox(height: 16),

                    // TANGGAL
                    Text(
                      "TANGGAL",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: dark ? Colors.white70 : const Color(0xFF64748B),
                      ),
                    ),
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
                        decoration: BoxDecoration(
                          color: dark ? const Color(0xFF0F172A) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: dark ? Colors.white24 : const Color(0xFFCBD5E1),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('dd/MM/yyyy').format(selectedDate),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: dark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 20,
                              color: dark ? Colors.white60 : const Color(0xFF475569),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // DIAMBIL DARI AKUN
                    Text(
                      "DIAMBIL DARI AKUN",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: dark ? Colors.white70 : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: dark ? const Color(0xFF0F172A) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: dark ? Colors.white24 : const Color(0xFFCBD5E1),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<PaymentMethod>(
                          value: selectedMethod,
                          isExpanded: true,
                          dropdownColor: dark ? const Color(0xFF1E293B) : Colors.white,
                          icon: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: dark ? Colors.white60 : const Color(0xFF475569),
                          ),
                          items: activeMethods.map((m) {
                            return DropdownMenuItem(
                              value: m,
                              child: Text(
                                "${m.name} (${_currencyFormat.format(_currentBalances[m.id] ?? 0)})",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: dark ? Colors.white : const Color(0xFF0F172A),
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

                    // KATEGORI BIAYA
                    Text(
                      "KATEGORI BIAYA",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: dark ? Colors.white70 : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: categoryCtrl,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: dark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      decoration: InputDecoration(
                        hintText: "mis. Listrik & Air",
                        hintStyle: GoogleFonts.openSans(fontSize: 13.5, color: Colors.grey),
                        filled: true,
                        fillColor: dark ? const Color(0xFF0F172A) : Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: dark ? Colors.white24 : const Color(0xFFCBD5E1)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: dark ? Colors.white24 : const Color(0xFFCBD5E1)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: suggestions.map((sug) {
                        final isSelected = categoryCtrl.text.trim().toLowerCase() == sug.toLowerCase();
                        return InkWell(
                          onTap: () => setSheetState(() => categoryCtrl.text = sug),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF0D7A4E).withValues(alpha: 0.14)
                                  : (dark ? Colors.white10 : const Color(0xFFF1F5F9)),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF0D7A4E)
                                    : (dark ? Colors.white12 : const Color(0xFFE2E8F0)),
                              ),
                            ),
                            child: Text(
                              sug,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? const Color(0xFF0D7A4E)
                                    : (dark ? Colors.white70 : const Color(0xFF475569)),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

                    // JUMLAH (RP)
                    Text(
                      "JUMLAH (RP)",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: dark ? Colors.white70 : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: amountCtrl,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: dark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      decoration: InputDecoration(
                        hintText: "0",
                        filled: true,
                        fillColor: dark ? const Color(0xFF0F172A) : Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: dark ? Colors.white24 : const Color(0xFFCBD5E1)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: dark ? Colors.white24 : const Color(0xFFCBD5E1)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // CATATAN
                    Text(
                      "CATATAN",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: dark ? Colors.white70 : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: notesCtrl,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: dark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      decoration: InputDecoration(
                        hintText: "opsional",
                        hintStyle: GoogleFonts.openSans(fontSize: 13.5, color: Colors.grey),
                        filled: true,
                        fillColor: dark ? const Color(0xFF0F172A) : Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: dark ? Colors.white24 : const Color(0xFFCBD5E1)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: dark ? Colors.white24 : const Color(0xFFCBD5E1)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Bottom Buttons: [ Batal ] & [ ✓ Simpan ]
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            side: BorderSide(color: dark ? Colors.white24 : const Color(0xFFCBD5E1)),
                          ),
                          child: Text(
                            "Batal",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: dark ? Colors.white70 : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D7A4E),
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
                                const SnackBar(content: Text("Masukkan jumlah biaya yang valid")),
                              );
                              return;
                            }
                            final cat = categoryCtrl.text.trim().isEmpty
                                ? 'Operasional'
                                : categoryCtrl.text.trim();
                            Navigator.pop(ctx);
                            try {
                              final service = context.read<AdminController>().paymentMethodService;
                              await service.recordExpense(
                                storeId: widget.storeId,
                                method: selectedMethod,
                                category: cat,
                                amount: amt,
                                notes: notesCtrl.text.trim(),
                                date: selectedDate,
                              );
                              _loadData();
                              if (mounted) {
                                TransactionResultDialog.show(
                                  context: context,
                                  isSuccess: true,
                                  title: "Biaya Berhasil Dicatat!",
                                  subtitle: "Pengeluaran biaya $cat telah tersimpan ke buku kas.",
                                  dateTime: selectedDate,
                                  totalAmount: amt,
                                  paidAmount: amt,
                                  statusBadge: "LUNAS",
                                  statusBadgeBg: const Color(0xFFECFDF5),
                                  statusBadgeText: const Color(0xFF047857),
                                  accountName: selectedMethod.name,
                                  category: cat,
                                  notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                                );
                              }
                            } catch (e) {
                              debugPrint("Error recordExpense: $e");
                              if (mounted) {
                                TransactionResultDialog.show(
                                  context: context,
                                  isSuccess: false,
                                  title: "Pencatatan Biaya Gagal",
                                  subtitle: "Terjadi kesalahan saat mencatat pengeluaran biaya.",
                                  errorMessage: e.toString(),
                                  totalAmount: amt,
                                  category: cat,
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.check_rounded, size: 18),
                          label: Text(
                            "Simpan",
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showTerimaPiutangDialog() async {
    final activeMethods = _methods.where((m) => m.isActive).toList();
    if (activeMethods.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tidak ada akun kas/metode pembayaran yang aktif")),
      );
      return;
    }

    final db = context.read<AppDatabase>();
    final service = context.read<AdminController>().paymentMethodService;
    final allCustomers = await (db.select(db.customers)
          ..where((t) => t.storeId.equals(widget.storeId))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();

    final debtTxs = await (db.select(db.transactions)
          ..where((t) => t.storeId.equals(widget.storeId))
          ..where((t) => t.status.equals('debt')))
        .get();

    final Map<String, double> debtByCustomer = {};
    for (final tx in debtTxs) {
      final cid = tx.customerId;
      final unpaid = ((tx.totalAmount ?? 0.0) - (tx.cashReceived ?? 0.0)).clamp(0.0, double.infinity);
      if (cid != null && unpaid > 0) {
        debtByCustomer[cid] = (debtByCustomer[cid] ?? 0.0) + unpaid;
      }
    }

    if (!mounted) return;

    PaymentMethod selectedMethod = activeMethods.first;
    Customer? selectedCustomer = allCustomers.isNotEmpty ? allCustomers.first : null;
    bool isCustomCustomer = allCustomers.isEmpty;
    final customCustomerCtrl = TextEditingController();
    final amountCtrl = TextEditingController(
      text: selectedCustomer != null && (debtByCustomer[selectedCustomer.id] ?? 0) > 0
          ? (debtByCustomer[selectedCustomer.id]!.toInt().toString())
          : '0',
    );
    final notesCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final dark = Theme.of(ctx).brightness == Brightness.dark;
            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              decoration: BoxDecoration(
                color: dark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "TERIMA PIUTANG",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: dark ? Colors.white : const Color(0xFF0F172A),
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
                                color: dark ? Colors.white24 : const Color(0xFFCBD5E1),
                              ),
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              size: 20,
                              color: dark ? Colors.white70 : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Divider(height: 1, color: dark ? Colors.white12 : const Color(0xFFE2E8F0)),
                    const SizedBox(height: 16),

                    // TANGGAL
                    Text(
                      "TANGGAL",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: dark ? Colors.white70 : const Color(0xFF64748B),
                      ),
                    ),
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
                        decoration: BoxDecoration(
                          color: dark ? const Color(0xFF0F172A) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: dark ? Colors.white24 : const Color(0xFFCBD5E1),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('dd/MM/yyyy').format(selectedDate),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: dark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 20,
                              color: dark ? Colors.white60 : const Color(0xFF475569),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // PELANGGAN
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "PELANGGAN",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: dark ? Colors.white70 : const Color(0xFF64748B),
                          ),
                        ),
                        if (allCustomers.isNotEmpty)
                          InkWell(
                            onTap: () => setSheetState(() => isCustomCustomer = !isCustomCustomer),
                            child: Text(
                              isCustomCustomer ? "Pilih dari Daftar" : "+ Input Pelanggan Baru",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0D7A4E),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (isCustomCustomer)
                      TextField(
                        controller: customCustomerCtrl,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: dark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        decoration: InputDecoration(
                          hintText: "Ketik nama pelanggan...",
                          filled: true,
                          fillColor: dark ? const Color(0xFF0F172A) : Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: dark ? Colors.white24 : const Color(0xFFCBD5E1)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: dark ? Colors.white24 : const Color(0xFFCBD5E1)),
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: dark ? const Color(0xFF0F172A) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: dark ? Colors.white24 : const Color(0xFFCBD5E1),
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<Customer>(
                            value: selectedCustomer,
                            isExpanded: true,
                            dropdownColor: dark ? const Color(0xFF1E293B) : Colors.white,
                            items: allCustomers.map((c) {
                              final debt = debtByCustomer[c.id] ?? 0.0;
                              final cName = c.name ?? 'Pelanggan';
                              return DropdownMenuItem(
                                value: c,
                                child: Text(
                                  debt > 0
                                      ? "$cName (Piutang: ${_currencyFormat.format(debt)})"
                                      : cName,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: dark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setSheetState(() {
                                  selectedCustomer = val;
                                  final debt = debtByCustomer[val.id] ?? 0.0;
                                  if (debt > 0) {
                                    amountCtrl.text = debt.toInt().toString();
                                  }
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    const SizedBox(height: 14),

                    // MASUK KE AKUN
                    Text(
                      "MASUK KE AKUN",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: dark ? Colors.white70 : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: dark ? const Color(0xFF0F172A) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: dark ? Colors.white24 : const Color(0xFFCBD5E1),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<PaymentMethod>(
                          value: selectedMethod,
                          isExpanded: true,
                          dropdownColor: dark ? const Color(0xFF1E293B) : Colors.white,
                          items: activeMethods.map((m) {
                            return DropdownMenuItem(
                              value: m,
                              child: Text(
                                "${m.name} (${_currencyFormat.format(_currentBalances[m.id] ?? 0)})",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: dark ? Colors.white : const Color(0xFF0F172A),
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

                    // JUMLAH (RP)
                    Text(
                      "JUMLAH DITERIMA (RP)",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: dark ? Colors.white70 : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: amountCtrl,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: dark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      decoration: InputDecoration(
                        hintText: "0",
                        filled: true,
                        fillColor: dark ? const Color(0xFF0F172A) : Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: dark ? Colors.white24 : const Color(0xFFCBD5E1)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: dark ? Colors.white24 : const Color(0xFFCBD5E1)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // CATATAN
                    Text(
                      "CATATAN",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: dark ? Colors.white70 : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: notesCtrl,
                      decoration: InputDecoration(
                        hintText: "opsional",
                        hintStyle: GoogleFonts.openSans(fontSize: 13.5, color: Colors.grey),
                        filled: true,
                        fillColor: dark ? const Color(0xFF0F172A) : Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: dark ? Colors.white24 : const Color(0xFFCBD5E1)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: dark ? Colors.white24 : const Color(0xFFCBD5E1)),
                        ),
                      ),
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
                            side: BorderSide(color: dark ? Colors.white24 : const Color(0xFFCBD5E1)),
                          ),
                          child: Text(
                            "Batal",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: dark ? Colors.white70 : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D7A4E),
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
                                const SnackBar(content: Text("Masukkan jumlah piutang yang valid")),
                              );
                              return;
                            }

                            String customerName = "Pelanggan";
                            String? customerId;
                            if (isCustomCustomer) {
                              final cname = customCustomerCtrl.text.trim();
                              if (cname.isNotEmpty) {
                                customerName = cname;
                                final newId = const Uuid().v4();
                                await db.into(db.customers).insert(
                                      CustomersCompanion.insert(
                                        id: newId,
                                        storeId: Value(widget.storeId),
                                        name: Value(cname),
                                        createdAt: Value(DateTime.now()),
                                      ),
                                    );
                                customerId = newId;
                              }
                            } else if (selectedCustomer != null) {
                              customerName = selectedCustomer!.name ?? 'Pelanggan';
                              customerId = selectedCustomer!.id;
                            }

                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                            }

                            double totalCustDebt = 0.0;
                            double remainingPayment = amt;
                            for (final dtx in debtTxs) {
                              final matchById = customerId != null && dtx.customerId == customerId;
                              final matchByName = (dtx.customerName ?? '').toLowerCase() == customerName.toLowerCase();
                              if (matchById || matchByName) {
                                final curReceived = dtx.cashReceived ?? 0.0;
                                final totalTx = dtx.totalAmount ?? 0.0;
                                final unpaid = (totalTx - curReceived).clamp(0.0, double.infinity);
                                totalCustDebt += unpaid;
                                if (unpaid > 0 && remainingPayment > 0) {
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

                            final extraNote = notesCtrl.text.trim();
                            try {
                              await service.recordInflow(
                                storeId: widget.storeId,
                                method: selectedMethod,
                                category: 'Terima Piutang',
                                amount: amt,
                                notes: extraNote.isNotEmpty
                                    ? 'Pelanggan: $customerName ($extraNote)'
                                    : 'Pelanggan: $customerName',
                                date: selectedDate,
                              );
                              _loadData();

                              if (mounted) {
                                final remDebt = (totalCustDebt - amt).clamp(0.0, double.infinity);
                                TransactionResultDialog.show(
                                  context: context,
                                  isSuccess: true,
                                  title: "Terima Piutang Berhasil!",
                                  subtitle: "Penerimaan piutang dari $customerName telah tersimpan.",
                                  dateTime: selectedDate,
                                  totalAmount: amt,
                                  paidAmount: amt,
                                  remainingDebt: remDebt > 0 ? remDebt : null,
                                  statusBadge: remDebt <= 0 ? "LUNAS" : "SEBAGIAN",
                                  statusBadgeBg: remDebt <= 0 ? const Color(0xFFECFDF5) : const Color(0xFFFEF3C7),
                                  statusBadgeText: remDebt <= 0 ? const Color(0xFF047857) : const Color(0xFFB45309),
                                  contactName: customerName,
                                  contactRole: "Pelanggan",
                                  accountName: selectedMethod.name,
                                  category: "Terima Piutang",
                                  notes: extraNote.isEmpty ? null : extraNote,
                                );
                              }
                            } catch (e) {
                              debugPrint("Error recordInflow terima piutang: $e");
                              if (mounted) {
                                TransactionResultDialog.show(
                                  context: context,
                                  isSuccess: false,
                                  title: "Terima Piutang Gagal",
                                  subtitle: "Terjadi kesalahan saat memproses penerimaan piutang.",
                                  errorMessage: e.toString(),
                                  totalAmount: amt,
                                  contactName: customerName,
                                  contactRole: "Pelanggan",
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.check_rounded, size: 18),
                          label: Text(
                            "Simpan",
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showBayarHutangDialog() async {
    final activeMethods = _methods.where((m) => m.isActive).toList();
    if (activeMethods.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tidak ada akun kas/metode pembayaran yang aktif")),
      );
      return;
    }

    final db = context.read<AppDatabase>();
    final supplierService = SupplierService(db);
    final suppliers = await supplierService.getSuppliers(widget.storeId);

    if (!mounted) return;
    if (suppliers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Belum ada data supplier untuk pembayaran hutang")),
      );
      return;
    }

    PaymentMethod selectedMethod = activeMethods.first;
    Supplier selectedSupplier = suppliers.firstWhere(
      (s) => s.unpaidBalance > 0,
      orElse: () => suppliers.first,
    );
    final amountCtrl = TextEditingController(
      text: selectedSupplier.unpaidBalance > 0 ? selectedSupplier.unpaidBalance.toInt().toString() : '0',
    );
    final notesCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final dark = Theme.of(ctx).brightness == Brightness.dark;
            final bool hasDebt = selectedSupplier.unpaidBalance > 0;
            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              decoration: BoxDecoration(
                color: dark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
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
                            fontWeight: FontWeight.w700,
                            color: dark ? Colors.white : const Color(0xFF0F172A),
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
                                color: dark ? Colors.white24 : const Color(0xFFCBD5E1),
                              ),
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              size: 20,
                              color: dark ? Colors.white70 : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Divider(height: 1, color: dark ? Colors.white12 : const Color(0xFFE2E8F0)),
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
                          color: dark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: dark ? Colors.white12 : const Color(0xFFE2E8F0)),
                        ),
                        child: RichText(
                          text: TextSpan(
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: dark ? Colors.white70 : const Color(0xFF0F172A),
                            ),
                            children: [
                              TextSpan(
                                text: "Sisa hutang ${selectedSupplier.name}: ",
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              TextSpan(
                                text: _currencyFormat.format(selectedSupplier.unpaidBalance),
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

                    // TANGGAL
                    Text(
                      "TANGGAL",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: dark ? Colors.white70 : const Color(0xFF64748B),
                      ),
                    ),
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
                        decoration: BoxDecoration(
                          color: dark ? const Color(0xFF0F172A) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: dark ? Colors.white24 : const Color(0xFFCBD5E1),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('dd/MM/yyyy').format(selectedDate),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: dark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 20,
                              color: dark ? Colors.white60 : const Color(0xFF475569),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // DIAMBIL DARI AKUN
                    Text(
                      "DIAMBIL DARI AKUN",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: dark ? Colors.white70 : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: dark ? const Color(0xFF0F172A) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: dark ? Colors.white24 : const Color(0xFFCBD5E1),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<PaymentMethod>(
                          value: selectedMethod,
                          isExpanded: true,
                          dropdownColor: dark ? const Color(0xFF1E293B) : Colors.white,
                          items: activeMethods.map((m) {
                            return DropdownMenuItem(
                              value: m,
                              child: Text(
                                "${m.name} (${_currencyFormat.format(_currentBalances[m.id] ?? 0)})",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: dark ? Colors.white : const Color(0xFF0F172A),
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

                    // SUPPLIER
                    Text(
                      "SUPPLIER",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: dark ? Colors.white70 : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: dark ? const Color(0xFF0F172A) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: dark ? Colors.white24 : const Color(0xFFCBD5E1),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<Supplier>(
                          value: selectedSupplier,
                          isExpanded: true,
                          dropdownColor: dark ? const Color(0xFF1E293B) : Colors.white,
                          items: suppliers.map((s) {
                            final hasSupDebt = s.unpaidBalance > 0;
                            return DropdownMenuItem(
                              value: s,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      s.name,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: dark ? Colors.white : const Color(0xFF0F172A),
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
                              setSheetState(() {
                                selectedSupplier = val;
                                amountCtrl.text = val.unpaidBalance > 0
                                    ? (val.unpaidBalance % 1 == 0 ? val.unpaidBalance.toInt().toString() : val.unpaidBalance.toStringAsFixed(0))
                                    : '0';
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // JUMLAH (RP)
                    Text(
                      "JUMLAH (RP)",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: dark ? Colors.white70 : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: amountCtrl,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: dark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      decoration: InputDecoration(
                        hintText: "0",
                        filled: true,
                        fillColor: dark ? const Color(0xFF0F172A) : Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: dark ? Colors.white24 : const Color(0xFFCBD5E1)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: dark ? Colors.white24 : const Color(0xFFCBD5E1)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // CATATAN
                    Text(
                      "CATATAN",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: dark ? Colors.white70 : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: notesCtrl,
                      decoration: InputDecoration(
                        hintText: "opsional",
                        hintStyle: GoogleFonts.openSans(fontSize: 13.5, color: Colors.grey),
                        filled: true,
                        fillColor: dark ? const Color(0xFF0F172A) : Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: dark ? Colors.white24 : const Color(0xFFCBD5E1)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: dark ? Colors.white24 : const Color(0xFFCBD5E1)),
                        ),
                      ),
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
                            side: BorderSide(color: dark ? Colors.white24 : const Color(0xFFCBD5E1)),
                          ),
                          child: Text(
                            "Batal",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: dark ? Colors.white70 : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: !hasDebt ? (dark ? Colors.white12 : const Color(0xFFE2E8F0)) : const Color(0xFF0D7A4E),
                            foregroundColor: !hasDebt ? (dark ? Colors.white38 : const Color(0xFF94A3B8)) : Colors.white,
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
                                      const SnackBar(content: Text("Masukkan jumlah pembayaran hutang yang valid")),
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
                                  final methodBal = _currentBalances[selectedMethod.id] ?? 0.0;
                                  if (amt > methodBal) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text("Saldo akun ${selectedMethod.name} tidak mencukupi (Saldo: ${_currencyFormat.format(methodBal)})"),
                                        backgroundColor: const Color(0xFFE05260),
                                      ),
                                    );
                                    return;
                                  }
                                  if (ctx.mounted) {
                                    Navigator.pop(ctx);
                                  }
                                  try {
                                    final tx = await supplierService.recordPayment(
                                      storeId: widget.storeId,
                                      supplierId: selectedSupplier.id,
                                      amount: amt,
                                      paymentMethod: selectedMethod.name,
                                      paymentMethodId: selectedMethod.id,
                                      notes: notesCtrl.text.trim(),
                                      customDate: selectedDate,
                                    );
                                    _loadData();

                                    if (mounted) {
                                      final remDebt = (selectedSupplier.unpaidBalance - amt).clamp(0.0, double.infinity);
                                      TransactionResultDialog.show(
                                        context: context,
                                        isSuccess: true,
                                        title: "Pembayaran Hutang Berhasil!",
                                        subtitle: "Transaksi #${tx.transactionNo} telah tersimpan.",
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
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showAddInflowDialog() async {
    final activeMethods = _methods.where((m) => m.isActive).toList();
    if (activeMethods.isEmpty) return;

    PaymentMethod selectedMethod = activeMethods.first;
    String selectedCategory = 'Pemasukan Lain';
    final amountCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();

    final categories = [
      'Pemasukan Lain',
      'Cashback & Bonus',
      'Tip Pelanggan',
      'Pendapatan Bunga',
      'Titipan Dana',
      'Lainnya',
    ];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final dark = Theme.of(ctx).brightness == Brightness.dark;
            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              decoration: BoxDecoration(
                color: dark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
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
                          color: Colors.grey.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00BF63).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF00BF63), size: 22),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "Catat Pemasukan Lain",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Text("Pilih Akun Penerima *", style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF1E293B)),
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.white,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<PaymentMethod>(
                          value: selectedMethod,
                          isExpanded: true,
                          dropdownColor: Colors.white,
                          items: activeMethods.map((m) {
                            return DropdownMenuItem(
                              value: m,
                              child: Text(
                                "${m.name} (Saldo: ${_currencyFormat.format(_currentBalances[m.id] ?? 0)})",
                                style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF00BF63)),
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

                    Text("Kategori Pemasukan *", style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF1E293B)),
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.white,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedCategory,
                          isExpanded: true,
                          dropdownColor: Colors.white,
                          items: categories.map((cat) {
                            return DropdownMenuItem(
                              value: cat,
                              child: Text(
                                cat,
                                style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF00BF63)),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setSheetState(() => selectedCategory = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    Text("Nominal Pemasukan (Rp) *", style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: amountCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: "Contoh: 100.000",
                        prefixText: "Rp ",
                        filled: true,
                        fillColor: dark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF1E293B))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF1E293B))),
                      ),
                    ),
                    const SizedBox(height: 14),

                    Text("Catatan / Keterangan", style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: notesCtrl,
                      decoration: InputDecoration(
                        hintText: "Contoh: Bonus cashback supplier, tip pelanggan",
                        filled: true,
                        fillColor: dark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF1E293B))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF1E293B))),
                      ),
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00BF63),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          final clean = amountCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '');
                          final amt = double.tryParse(clean) ?? 0.0;
                          if (amt <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Masukkan nominal pemasukan yang valid")),
                            );
                            return;
                          }
                          Navigator.pop(ctx);
                          try {
                            final service = context.read<AdminController>().paymentMethodService;
                            await service.recordInflow(
                              storeId: widget.storeId,
                              method: selectedMethod,
                              category: selectedCategory,
                              amount: amt,
                              notes: notesCtrl.text.trim(),
                              date: selectedDate,
                            );
                            _loadData();
                            if (mounted) {
                              TransactionResultDialog.show(
                                context: context,
                                isSuccess: true,
                                title: "Pemasukan Berhasil Dicatat!",
                                subtitle: "Pemasukan lain sebesar ${_currencyFormat.format(amt)} via ${selectedMethod.name} telah tersimpan.",
                                dateTime: selectedDate,
                                totalAmount: amt,
                                paidAmount: amt,
                                statusBadge: "LUNAS",
                                statusBadgeBg: const Color(0xFFECFDF5),
                                statusBadgeText: const Color(0xFF047857),
                                accountName: selectedMethod.name,
                                category: selectedCategory,
                                notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                              );
                            }
                          } catch (e) {
                            debugPrint("Error recordInflow: $e");
                            if (mounted) {
                              TransactionResultDialog.show(
                                context: context,
                                isSuccess: false,
                                title: "Pemasukan Gagal",
                                subtitle: "Terjadi kesalahan saat mencatat pemasukan lain.",
                                errorMessage: e.toString(),
                                totalAmount: amt,
                                category: selectedCategory,
                              );
                            }
                          }
                        },
                        child: Text(
                          "Simpan Pemasukan",
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showSetorModalDialog() async {
    final activeMethods = _methods.where((m) => m.isActive).toList();
    if (activeMethods.isEmpty) return;

    PaymentMethod selectedMethod = activeMethods.first;
    final amountCtrl = TextEditingController();
    final notesCtrl = TextEditingController(text: "Setor modal kas toko");
    DateTime selectedDate = DateTime.now();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final dark = Theme.of(ctx).brightness == Brightness.dark;
            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              decoration: BoxDecoration(
                color: dark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
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
                          color: Colors.grey.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.vertical_align_bottom_rounded, color: Color(0xFF0284C7), size: 22),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "Setor Modal Kas",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Text("Pilih Akun Kas / Bank *", style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF1E293B)),
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.white,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<PaymentMethod>(
                          value: selectedMethod,
                          isExpanded: true,
                          dropdownColor: Colors.white,
                          items: activeMethods.map((m) {
                            return DropdownMenuItem(
                              value: m,
                              child: Text(
                                "${m.name} (Saldo: ${_currencyFormat.format(_currentBalances[m.id] ?? 0)})",
                                style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF00BF63)),
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

                    Text("Nominal Setor Modal (Rp) *", style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: amountCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: "Contoh: 500.000",
                        prefixText: "Rp ",
                        filled: true,
                        fillColor: dark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF1E293B))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF1E293B))),
                      ),
                    ),
                    const SizedBox(height: 14),

                    Text("Catatan", style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: notesCtrl,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: dark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF1E293B))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF1E293B))),
                      ),
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          final clean = amountCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '');
                          final amt = double.tryParse(clean) ?? 0.0;
                          if (amt <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Masukkan nominal modal yang valid")),
                            );
                            return;
                          }
                          Navigator.pop(ctx);
                          try {
                            final service = context.read<AdminController>().paymentMethodService;
                            await service.recordInflow(
                              storeId: widget.storeId,
                              method: selectedMethod,
                              category: 'Setor Modal',
                              amount: amt,
                              notes: notesCtrl.text.trim(),
                              date: selectedDate,
                            );
                            _loadData();
                            if (mounted) {
                              TransactionResultDialog.show(
                                context: context,
                                isSuccess: true,
                                title: "Setor Modal Berhasil!",
                                subtitle: "Penambahan modal ke ${selectedMethod.name} telah tersimpan.",
                                dateTime: selectedDate,
                                totalAmount: amt,
                                paidAmount: amt,
                                statusBadge: "LUNAS",
                                statusBadgeBg: const Color(0xFFECFDF5),
                                statusBadgeText: const Color(0xFF047857),
                                accountName: selectedMethod.name,
                                category: "Setor Modal",
                                notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                              );
                            }
                          } catch (e) {
                            debugPrint("Error recordInflow setor modal: $e");
                            if (mounted) {
                              TransactionResultDialog.show(
                                context: context,
                                isSuccess: false,
                                title: "Setor Modal Gagal",
                                subtitle: "Terjadi kesalahan saat mencatat setor modal.",
                                errorMessage: e.toString(),
                                totalAmount: amt,
                                category: "Setor Modal",
                              );
                            }
                          }
                        },
                        child: Text(
                          "Simpan Setor Modal",
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showPriveQuickDialog({PaymentMethod? fromMethod}) {
    final active = _methods.where((m) => m.isActive).toList();
    if (active.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tidak ada akun kas/metode pembayaran yang aktif")),
      );
      return;
    }
    _showWithdrawDialog(initialMethod: fromMethod ?? active.first);
  }

  void _showQuickTransferDialog() {
    final active = _methods.where((m) => m.isActive).toList();
    if (active.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Minimal harus ada 2 akun aktif untuk melakukan transfer")),
      );
      return;
    }
    _showTransferDialog();
  }

  Future<void> _showReconciliationDialog() async {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final todayCashRecords = _financialRecords.where((r) {
      if (r.type == FinancialRecordType.reconciliation) return false;
      if (r.date.isBefore(startOfToday) || r.date.isAfter(endOfToday)) return false;
      final m = r.methodName.toLowerCase();
      return m.contains('kas') || m.contains('tunai') || m == 'cash';
    }).toList();

    final cashInToday = _todayCashSalesSum +
        todayCashRecords.where((r) => r.isIncome).fold<double>(0.0, (s, r) => s + r.amount);
    final cashOutToday = todayCashRecords.where((r) => !r.isIncome).fold<double>(0.0, (s, r) => s + r.amount);

    final cashMethod = _methods.firstWhere(
      (m) => m.type == 'cash' || m.name.toLowerCase().contains('kas') || m.name.toLowerCase().contains('tunai'),
      orElse: () => _methods.isNotEmpty ? _methods.first : PaymentMethod(id: 'cash', storeId: widget.storeId, name: 'Kas', type: 'cash', isActive: true),
    );
    final initialCash = _initialBalances[cashMethod.id] ?? 0.0;
    final expectedCashInDrawer = initialCash + cashInToday - cashOutToday;

    final physicalCtrl = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final dark = Theme.of(ctx).brightness == Brightness.dark;
            final clean = physicalCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '');
            final physicalAmt = double.tryParse(clean) ?? 0.0;
            final hasInput = physicalCtrl.text.trim().isNotEmpty;
            final diff = physicalAmt - expectedCashInDrawer;

            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              decoration: BoxDecoration(
                color: dark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
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
                          color: Colors.grey.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.balance_rounded, color: Color(0xFF8B5CF6), size: 22),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Cek Fisik & Rekonsiliasi Kas",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              "Cocokkan uang laci kasir dengan sistem",
                              style: GoogleFonts.openSans(
                                fontSize: 11.5,
                                color: dark ? Colors.white60 : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: dark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: dark ? Colors.white12 : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildReconRow("Modal Kas Awal", _currencyFormat.format(initialCash), dark),
                          const SizedBox(height: 6),
                          _buildReconRow("Penjualan & Kas Masuk Hari Ini", "+ ${_currencyFormat.format(cashInToday)}", dark, valueColor: const Color(0xFF00BF63)),
                          const SizedBox(height: 6),
                          _buildReconRow("Pengeluaran & Tarik Hari Ini", "- ${_currencyFormat.format(cashOutToday)}", dark, valueColor: const Color(0xFFE05260)),
                          const Divider(height: 16),
                          _buildReconRow(
                            "Kas Seharusnya di Laci",
                            _currencyFormat.format(expectedCashInDrawer),
                            dark,
                            isBold: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      "Uang Tunai Fisik di Laci Sekarang *",
                      style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: physicalCtrl,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setModalState(() {}),
                      decoration: InputDecoration(
                        hintText: "Hitung dan masukkan uang fisik",
                        prefixText: "Rp ",
                        filled: true,
                        fillColor: dark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF1E293B))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF1E293B))),
                      ),
                    ),
                    const SizedBox(height: 14),

                    if (hasInput) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: diff == 0
                              ? const Color(0xFF00BF63).withValues(alpha: 0.1)
                              : (diff > 0
                                  ? const Color(0xFF0284C7).withValues(alpha: 0.1)
                                  : const Color(0xFFE05260).withValues(alpha: 0.1)),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: diff == 0
                                ? const Color(0xFF00BF63)
                                : (diff > 0 ? const Color(0xFF0284C7) : const Color(0xFFE05260)),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              diff == 0
                                  ? Icons.check_circle_rounded
                                  : (diff > 0 ? Icons.arrow_circle_up_rounded : Icons.warning_amber_rounded),
                              color: diff == 0
                                  ? const Color(0xFF00BF63)
                                  : (diff > 0 ? const Color(0xFF0284C7) : const Color(0xFFE05260)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    diff == 0
                                        ? "Kas Cocok Sempurna!"
                                        : (diff > 0 ? "Kas Lebih" : "Kas Kurang"),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: diff == 0
                                          ? const Color(0xFF00BF63)
                                          : (diff > 0 ? const Color(0xFF0284C7) : const Color(0xFFE05260)),
                                    ),
                                  ),
                                  Text(
                                    diff == 0
                                        ? "Uang fisik di laci sama persis dengan sistem."
                                        : "Selisih: ${_currencyFormat.format(diff.abs())}",
                                    style: GoogleFonts.openSans(
                                      fontSize: 11.5,
                                      color: dark ? Colors.white70 : const Color(0xFF475569),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00BF63),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          if (!hasInput) {
                            Navigator.pop(ctx);
                            return;
                          }
                          final db = context.read<AppDatabase>();
                          final statusLabel = diff == 0
                              ? 'Cocok'
                              : (diff > 0 ? 'Lebih' : 'Kurang');
                          final reconNote =
                              'Fisik: ${_currencyFormat.format(physicalAmt)} · Sistem: ${_currencyFormat.format(expectedCashInDrawer)} ($statusLabel) [${cashMethod.name}] [CEK_FISIK]';
                          await db.into(db.expenses).insert(
                                ExpensesCompanion.insert(
                                  id: const Uuid().v4(),
                                  storeId: Value(widget.storeId),
                                  category: 'Cek Fisik Kas',
                                  amount: Value(diff.abs()),
                                  date: Value(DateTime.now()),
                                  notes: Value(reconNote),
                                ),
                              );
                          if (ctx.mounted) Navigator.pop(ctx);
                          await _loadData();
                        },
                        child: Text(
                          "Simpan Cek Fisik Kas",
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildReconRow(String label, String value, bool dark, {Color? valueColor, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.openSans(
            fontSize: 12,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: dark ? Colors.white70 : const Color(0xFF475569),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w700,
            color: valueColor ?? (dark ? Colors.white : const Color(0xFF0F172A)),
          ),
        ),
      ],
    );
  }

  Widget _buildMethodCard(PaymentMethod method, bool isDark, {bool isGrid = false}) {
    final initBal = _initialBalances[method.id] ?? 0.0;
    final income = _incomes[method.id] ?? 0.0;
    final outflow = _outflows[method.id] ?? 0.0;
    final inflow = _inflows[method.id] ?? 0.0;
    final currentBal = _currentBalances[method.id] ?? (initBal + income + inflow - outflow);

    String badgeLabel;
    IconData typeIcon;
    Color iconColor;
    final typeLower = method.type.toLowerCase();

    if (typeLower == 'cash' || typeLower == 'kas') {
      badgeLabel = "KAS";
      typeIcon = Icons.payments_outlined;
      iconColor = const Color(0xFF00BF63);
    } else if (typeLower == 'bank') {
      badgeLabel = "BANK";
      typeIcon = Icons.account_balance_outlined;
      iconColor = const Color(0xFF0284C7);
    } else if (typeLower == 'qris') {
      badgeLabel = "QRIS";
      typeIcon = Icons.qr_code_rounded;
      iconColor = const Color(0xFF8B5CF6);
    } else if (typeLower == 'ewallet') {
      badgeLabel = "E-WALLET";
      typeIcon = Icons.account_balance_wallet_outlined;
      iconColor = const Color(0xFF0D9488);
    } else {
      badgeLabel = method.type.toUpperCase();
      typeIcon = Icons.credit_card_outlined;
      iconColor = const Color(0xFF64748B);
    }

    return Container(
      margin: isGrid ? EdgeInsets.zero : const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.5) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: method.isActive
              ? (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))
              : Colors.grey.withValues(alpha: 0.25),
          width: 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showAddEditMethodDialog(method: method),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(11, 10, 11, 9),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: isDark ? 0.2 : 0.1),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Icon(typeIcon, size: 14, color: iconColor),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            method.name,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 1.5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: iconColor.withValues(alpha: isDark ? 0.15 : 0.08),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              badgeLabel,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                                color: iconColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!method.isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          "OFF",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                  ],
                ),
                Text(
                  _currencyFormat.format(currentBal),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: currentBal >= 0
                        ? (isDark ? Colors.white : const Color(0xFF0F172A))
                        : const Color(0xFFE05260),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showAddEditMethodDialog({PaymentMethod? method}) async {
    final nameCtrl = TextEditingController(text: method?.name ?? '');
    final detailsCtrl = TextEditingController(text: method?.details ?? '');
    final usernameCtrl = TextEditingController(text: method?.username ?? '');

    double existingBal = 0.0;
    if (method != null) {
      existingBal = _initialBalances[method.id] ?? 0.0;
    }
    final saldoAwalCtrl = TextEditingController(
      text: existingBal > 0
          ? (existingBal % 1 == 0 ? existingBal.toInt().toString() : existingBal.toString())
          : '0',
    );

    String rawType = (method?.type ?? 'kas').toLowerCase();
    if (rawType == 'cash') rawType = 'kas';
    String type = ['kas', 'bank', 'qris', 'ewallet'].contains(rawType) ? rawType : 'kas';
    String? qrisUrl = method?.qrisUrl;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) {
          final darkSheet = Theme.of(ctx).brightness == Brightness.dark;
          return Container(
            decoration: BoxDecoration(
              color: darkSheet ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              left: 20,
              right: 20,
              top: 16,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        method == null ? "TAMBAH AKUN" : "EDIT AKUN",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: darkSheet ? Colors.white : const Color(0xFF0F172A),
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
                              color: darkSheet ? Colors.white24 : const Color(0xFFCBD5E1),
                            ),
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            size: 20,
                            color: darkSheet ? Colors.white70 : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Divider(height: 1, color: darkSheet ? Colors.white12 : const Color(0xFFE2E8F0)),
                  const SizedBox(height: 16),

                  // 1. NAMA AKUN
                  Text(
                    "NAMA AKUN",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: darkSheet ? Colors.white70 : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: nameCtrl,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: darkSheet ? Colors.white : const Color(0xFF0F172A),
                    ),
                    decoration: InputDecoration(
                      hintText: "Contoh: Kas, Qris, BCA",
                      hintStyle: GoogleFonts.openSans(fontSize: 13.5, color: Colors.grey),
                      filled: true,
                      fillColor: darkSheet ? const Color(0xFF0F172A) : Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: darkSheet ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: darkSheet ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 2. JENIS
                  Text(
                    "JENIS",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: darkSheet ? Colors.white70 : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: darkSheet ? const Color(0xFF0F172A) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: darkSheet ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: type,
                        isExpanded: true,
                        dropdownColor: darkSheet ? const Color(0xFF1E293B) : Colors.white,
                        icon: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: darkSheet ? Colors.white60 : const Color(0xFF475569),
                        ),
                        style: GoogleFonts.plusJakartaSans(
                          color: darkSheet ? Colors.white : const Color(0xFF0F172A),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        items: const [
                          DropdownMenuItem(value: 'kas', child: Text("kas")),
                          DropdownMenuItem(value: 'bank', child: Text("bank")),
                          DropdownMenuItem(value: 'qris', child: Text("qris")),
                          DropdownMenuItem(value: 'ewallet', child: Text("ewallet")),
                        ],
                        onChanged: (val) {
                          if (val != null) ss(() => type = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 3. SALDO AWAL
                  Text(
                    "SALDO AWAL",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: darkSheet ? Colors.white70 : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: saldoAwalCtrl,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: darkSheet ? Colors.white : const Color(0xFF0F172A),
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: darkSheet ? const Color(0xFF0F172A) : Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: darkSheet ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: darkSheet ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Saldo awal = uang yang sudah ada saat mulai memakai aplikasi. Transaksi selanjutnya dihitung otomatis.",
                    style: GoogleFonts.openSans(
                      fontSize: 11.5,
                      color: darkSheet ? Colors.white54 : const Color(0xFF64748B),
                    ),
                  ),

                  if (type == 'qris') ...[
                    const SizedBox(height: 14),
                    Text(
                      "FOTO QRIS (OPSIONAL)",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: darkSheet ? Colors.white70 : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () async {
                        final picker = ImagePicker();
                        final image = await picker.pickImage(source: ImageSource.gallery);
                        if (image != null) {
                          final fileName = 'qris_${DateTime.now().millisecondsSinceEpoch}${p.extension(image.path)}';
                          final savedPath = await FileManager().saveFile(image, fileName);
                          ss(() => qrisUrl = savedPath);
                        }
                      },
                      child: Container(
                        height: 120,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: darkSheet ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: qrisUrl != null ? _primaryColor : const Color(0xFFCBD5E1),
                            width: 1.2,
                          ),
                        ),
                        child: qrisUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(11),
                                child: Image(
                                  image: FileManager().getImageProvider(qrisUrl!),
                                  fit: BoxFit.contain,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.qr_code_rounded, size: 32, color: _primaryColor),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Ketuk untuk Upload Foto QRIS",
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Bottom Buttons: [ 🗑 ] [ Batal ] [ ✓ Simpan ]
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (method != null) ...[
                        InkWell(
                          onTap: () {
                            Navigator.pop(ctx);
                            _confirmDelete(method);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 44,
                            height: 46,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE05260),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: darkSheet ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                        ),
                        child: Text(
                          "Batal",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: darkSheet ? Colors.white70 : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: () async {
                          if (nameCtrl.text.trim().isEmpty) return;
                          final adminCtrl = context.read<AdminController>();
                          final service = adminCtrl.paymentMethodService;
                          final parsedBal = double.tryParse(saldoAwalCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;

                          if (method == null) {
                            await service.createPaymentMethod(
                              storeId: widget.storeId,
                              name: nameCtrl.text.trim(),
                              type: type,
                              details: detailsCtrl.text.trim(),
                              username: usernameCtrl.text.trim(),
                              qrisUrl: qrisUrl,
                              initialBalance: parsedBal,
                            );
                          } else {
                            final updated = method.copyWith(
                              name: nameCtrl.text.trim(),
                              type: type,
                              details: Value(detailsCtrl.text.trim()),
                              username: Value(usernameCtrl.text.trim()),
                              qrisUrl: Value(qrisUrl),
                            );
                            await service.updatePaymentMethod(updated, initialBalance: parsedBal);
                          }

                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                            _loadData();
                          }
                        },
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: Text(
                          "Simpan",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D7A4E),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
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

  Future<void> _confirmDelete(PaymentMethod method) async {
    final curBal = _currentBalances[method.id] ?? 0.0;
    if (curBal > 0) {
      final doTransfer = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Saldo Masih Mengendap",
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            "Akun '${method.name}' masih memiliki sisa saldo sebesar ${_currencyFormat.format(curBal)}.\n\nSilakan transfer terlebih dahulu saldo ke akun atau metode pembayaran lain sebelum menghapus akun ini.",
            style: GoogleFonts.openSans(fontSize: 13, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Tutup"),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00BF63),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.swap_horiz_rounded, size: 18),
              label: const Text("Transfer Saldo"),
            ),
          ],
        ),
      );

      if (doTransfer == true && mounted) {
        _showTransferDialog(fromMethod: method, currentBal: curBal);
      }
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Hapus Akun '${method.name}'?",
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: Text(
          "Yakin ingin menghapus '${method.name}'? Akun ini tidak akan muncul lagi di pilihan pembayaran kasir.",
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
              backgroundColor: const Color(0xFFE05260),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Hapus"),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final service = context.read<AdminController>().paymentMethodService;
      await service.deletePaymentMethod(method.id, storeId: widget.storeId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Akun '${method.name}' berhasil dihapus."),
            backgroundColor: const Color(0xFFE05260),
          ),
        );
      }
      _loadData();
    }
  }

  Future<void> _showWithdrawDialog({PaymentMethod? initialMethod}) async {
    final activeMethods = _methods.where((m) => m.isActive).toList();
    if (activeMethods.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tidak ada akun kas/metode pembayaran yang aktif")),
      );
      return;
    }
    PaymentMethod selectedMethod = initialMethod ?? activeMethods.first;
    final amountCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) {
        final dark = Theme.of(ctx).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (ctx, ss) {
            final activeBal = _currentBalances[selectedMethod.id] ?? 0.0;
            void setPercent(double pct) {
              final val = (activeBal * pct).clamp(0.0, double.infinity);
              amountCtrl.text = val % 1 == 0 ? val.toInt().toString() : val.toStringAsFixed(0);
              ss(() {});
            }

            return AlertDialog(
              backgroundColor: dark ? const Color(0xFF1E293B) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE05260).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.call_made_rounded, color: Color(0xFFE05260), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Prive / Tarik Saldo",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          "${selectedMethod.name} · Saldo: ${_currencyFormat.format(activeBal)}",
                          style: GoogleFonts.openSans(
                            fontSize: 11.5,
                            color: activeBal > 0 ? const Color(0xFF0D9488) : const Color(0xFFE05260),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Pilih Akun Penarikan (Prive)
                    Text(
                      "TARIK DARI AKUN",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: dark ? Colors.white70 : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: dark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: dark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<PaymentMethod>(
                          value: selectedMethod,
                          isExpanded: true,
                          dropdownColor: dark ? const Color(0xFF1E293B) : Colors.white,
                          items: activeMethods.map((m) {
                            final b = _currentBalances[m.id] ?? 0.0;
                            return DropdownMenuItem<PaymentMethod>(
                              value: m,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      m.name,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                        color: dark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    _currencyFormat.format(b),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: b > 0 ? const Color(0xFF0D8A50) : const Color(0xFFE05260),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              ss(() {
                                selectedMethod = val;
                                amountCtrl.clear();
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    Text(
                      "JUMLAH PENARIKAN (RP)",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: dark ? Colors.white70 : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: amountCtrl,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFE05260),
                      ),
                      decoration: InputDecoration(
                        prefixText: "Rp ",
                        prefixStyle: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFE05260),
                        ),
                        hintText: "0",
                        filled: true,
                        fillColor: dark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: dark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (activeBal > 0) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          for (final pct in [0.25, 0.50, 0.75, 1.0])
                            InkWell(
                              onTap: () => setPercent(pct),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: dark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: dark ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Text(
                                  pct == 1.0 ? "Semua (100%)" : "${(pct * 100).toInt()}%",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: dark ? Colors.white70 : const Color(0xFF334155),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                    ],
                    Text(
                      "CATATAN / KETERANGAN",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: dark ? Colors.white70 : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: notesCtrl,
                      decoration: InputDecoration(
                        hintText: "Contoh: Tarik saldo ke rekening pribadi (Prive)",
                        hintStyle: GoogleFonts.openSans(fontSize: 11.5, color: Colors.grey),
                        filled: true,
                        fillColor: dark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: dark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Batal"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE05260),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    final cleanText = amountCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '');
                    final amt = double.tryParse(cleanText) ?? 0.0;
                    if (amt <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Masukkan jumlah penarikan yang valid")),
                      );
                      return;
                    }
                    if (amt > activeBal) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Saldo akun ${selectedMethod.name} tidak mencukupi (Saldo: ${_currencyFormat.format(activeBal)})"),
                          backgroundColor: const Color(0xFFE05260),
                        ),
                      );
                      return;
                    }
                    Navigator.pop(ctx);
                    try {
                      final service = context.read<AdminController>().paymentMethodService;
                      await service.addOutflow(
                        widget.storeId,
                        selectedMethod,
                        amt,
                        notes: notesCtrl.text.trim().isNotEmpty
                            ? '${notesCtrl.text.trim()} (Tarik dari ${selectedMethod.name})'
                            : 'Prive / Tarik saldo dari ${selectedMethod.name}',
                      );
                      _loadData();
                      if (mounted) {
                        TransactionResultDialog.show(
                          context: context,
                          isSuccess: true,
                          title: "Penarikan Saldo Berhasil!",
                          subtitle: "Tarik saldo (Prive) dari ${selectedMethod.name} telah tersimpan.",
                          dateTime: DateTime.now(),
                          totalAmount: amt,
                          paidAmount: amt,
                          statusBadge: "LUNAS",
                          statusBadgeBg: const Color(0xFFECFDF5),
                          statusBadgeText: const Color(0xFF047857),
                          accountName: selectedMethod.name,
                          category: "Prive / Tarik Saldo",
                          notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                        );
                      }
                    } catch (e) {
                      debugPrint("Error addOutflow prive: $e");
                      if (mounted) {
                        TransactionResultDialog.show(
                          context: context,
                          isSuccess: false,
                          title: "Penarikan Saldo Gagal",
                          subtitle: "Terjadi kesalahan saat memproses penarikan saldo.",
                          errorMessage: e.toString(),
                          totalAmount: amt,
                          accountName: selectedMethod.name,
                          category: "Prive / Tarik Saldo",
                        );
                      }
                    }
                  },
                  child: const Text("Tarik Sekarang"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showTransferDialog({
    PaymentMethod? initialFromMethod,
    PaymentMethod? fromMethod,
    double? currentBal,
  }) async {
    final active = _methods.where((m) => m.isActive).toList();
    if (active.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Perlu minimal 2 akun pembayaran aktif untuk transfer")),
      );
      return;
    }

    final initialSrc = initialFromMethod ?? fromMethod;
    PaymentMethod selectedSource = initialSrc ??
        active.firstWhere(
          (m) => (_currentBalances[m.id] ?? 0.0) > 0,
          orElse: () => active.first,
        );

    List<PaymentMethod> getAvailableTargets(PaymentMethod src) {
      return active.where((m) => m.id != src.id).toList();
    }

    List<PaymentMethod> availableTargets = getAvailableTargets(selectedSource);
    PaymentMethod selectedTarget = availableTargets.first;

    final amountCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) {
        final dark = Theme.of(ctx).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (ctx, ss) {
            final double sourceBal = _currentBalances[selectedSource.id] ?? 0.0;
            final bool isSourceZero = sourceBal <= 0;

            void setPercent(double pct) {
              if (isSourceZero) return;
              final val = (sourceBal * pct).clamp(0.0, double.infinity);
              amountCtrl.text = val % 1 == 0 ? val.toInt().toString() : val.toStringAsFixed(0);
              ss(() {});
            }

            return AlertDialog(
              backgroundColor: dark ? const Color(0xFF1E293B) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.swap_horiz_rounded, color: Color(0xFF2563EB), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Transfer Antar Akun",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          "Pindahkan saldo antar akun keuangan",
                          style: GoogleFonts.openSans(
                            fontSize: 11.5,
                            color: dark ? Colors.white60 : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. DARI AKUN (SUMBER TRANSFER)
                    Text(
                      "DARI AKUN (SUMBER)",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: dark ? Colors.white70 : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: dark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSourceZero
                              ? const Color(0xFFE05260)
                              : (dark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                          width: isSourceZero ? 1.4 : 1.0,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<PaymentMethod>(
                          value: selectedSource,
                          isExpanded: true,
                          dropdownColor: dark ? const Color(0xFF1E293B) : Colors.white,
                          items: active.map((m) {
                            final b = _currentBalances[m.id] ?? 0.0;
                            return DropdownMenuItem<PaymentMethod>(
                              value: m,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      "${m.name} (${m.type.toUpperCase()})",
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    _currencyFormat.format(b),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: b > 0 ? const Color(0xFF0D8A50) : const Color(0xFFE05260),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              ss(() {
                                selectedSource = val;
                                availableTargets = getAvailableTargets(selectedSource);
                                if (!availableTargets.any((t) => t.id == selectedTarget.id)) {
                                  selectedTarget = availableTargets.first;
                                }
                                amountCtrl.clear();
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    if (isSourceZero) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF1F2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFECDD3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: Color(0xFFE05260), size: 16),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                "Saldo ${selectedSource.name} Rp 0. Tidak dapat melakukan transfer dari akun ini.",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFBE123C),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 14),

                    // 2. TUJUAN TRANSFER (KE AKUN)
                    Text(
                      "TUJUAN TRANSFER (KE AKUN)",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: dark ? Colors.white70 : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: dark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: dark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<PaymentMethod>(
                          value: selectedTarget,
                          isExpanded: true,
                          dropdownColor: dark ? const Color(0xFF1E293B) : Colors.white,
                          items: availableTargets.map((m) {
                            final b = _currentBalances[m.id] ?? 0.0;
                            return DropdownMenuItem<PaymentMethod>(
                              value: m,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      "${m.name} (${m.type.toUpperCase()})",
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    _currencyFormat.format(b),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: dark ? Colors.white60 : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) ss(() => selectedTarget = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 3. JUMLAH TRANSFER (RP)
                    Text(
                      "JUMLAH TRANSFER (RP)",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: dark ? Colors.white70 : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: amountCtrl,
                      keyboardType: TextInputType.number,
                      enabled: !isSourceZero,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isSourceZero ? Colors.grey : const Color(0xFF2563EB),
                      ),
                      decoration: InputDecoration(
                        prefixText: "Rp ",
                        prefixStyle: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          color: isSourceZero ? Colors.grey : const Color(0xFF2563EB),
                        ),
                        hintText: "0",
                        filled: true,
                        fillColor: dark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: dark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (!isSourceZero) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          for (final pct in [0.25, 0.50, 0.75, 1.0])
                            InkWell(
                              onTap: () => setPercent(pct),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: dark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: dark ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Text(
                                  pct == 1.0 ? "Semua (100%)" : "${(pct * 100).toInt()}%",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: dark ? Colors.white70 : const Color(0xFF334155),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                    ],

                    // 4. CATATAN TRANSFER
                    Text(
                      "CATATAN TRANSFER",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: dark ? Colors.white70 : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: notesCtrl,
                      decoration: InputDecoration(
                        hintText: "Contoh: Setor kas laci ke rekening bank",
                        hintStyle: GoogleFonts.openSans(fontSize: 11.5, color: Colors.grey),
                        filled: true,
                        fillColor: dark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: dark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Batal"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    if (isSourceZero) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Tidak dapat melakukan transfer karena saldo akun ${selectedSource.name} adalah Rp 0 / kosong"),
                          backgroundColor: const Color(0xFFE05260),
                        ),
                      );
                      return;
                    }
                    final cleanText = amountCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '');
                    final amt = double.tryParse(cleanText) ?? 0.0;
                    if (amt <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Masukkan nominal transfer yang valid"), backgroundColor: Color(0xFFE05260)),
                      );
                      return;
                    }
                    if (amt > sourceBal) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Saldo akun ${selectedSource.name} tidak mencukupi (Saldo: ${_currencyFormat.format(sourceBal)})"),
                          backgroundColor: const Color(0xFFE05260),
                        ),
                      );
                      return;
                    }
                    Navigator.pop(ctx);
                    try {
                      final service = context.read<AdminController>().paymentMethodService;
                      await service.transferBalance(
                        storeId: widget.storeId,
                        fromMethod: selectedSource,
                        toMethod: selectedTarget,
                        amount: amt,
                        notes: notesCtrl.text.trim(),
                      );
                      _loadData();
                      if (mounted) {
                        TransactionResultDialog.show(
                          context: context,
                          isSuccess: true,
                          title: "Transfer Saldo Berhasil!",
                          subtitle: "Pemindahan saldo dari ${selectedSource.name} ke ${selectedTarget.name} telah selesai.",
                          dateTime: DateTime.now(),
                          totalAmount: amt,
                          paidAmount: amt,
                          statusBadge: "SELESAI",
                          statusBadgeBg: const Color(0xFFE0F2FE),
                          statusBadgeText: const Color(0xFF0369A1),
                          accountName: "${selectedSource.name} ➔ ${selectedTarget.name}",
                          category: "Transfer Antar Akun",
                          notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                        );
                      }
                    } catch (e) {
                      debugPrint("Error transferBalance: $e");
                      if (mounted) {
                        TransactionResultDialog.show(
                          context: context,
                          isSuccess: false,
                          title: "Transfer Saldo Gagal",
                          subtitle: "Terjadi kesalahan saat memproses transfer saldo.",
                          errorMessage: e.toString(),
                          totalAmount: amt,
                          accountName: "${selectedSource.name} ➔ ${selectedTarget.name}",
                          category: "Transfer Antar Akun",
                        );
                      }
                    }
                  },
                  child: const Text("Transfer Sekarang"),
                ),
              ],
            );
          },
        );
      },
    );
  }


}
