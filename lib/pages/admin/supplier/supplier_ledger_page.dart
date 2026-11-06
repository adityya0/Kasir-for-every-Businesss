import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../services/app_database.dart';
import '../../../services/payment_method_service.dart';
import '../../../services/supplier_service.dart';
import '../../../widgets/kasir_dialog.dart';

class SupplierLedgerPage extends StatefulWidget {
  final String storeId;
  final Supplier supplier;
  final VoidCallback? onSupplierUpdated;

  const SupplierLedgerPage({
    super.key,
    required this.storeId,
    required this.supplier,
    this.onSupplierUpdated,
  });

  @override
  State<SupplierLedgerPage> createState() => _SupplierLedgerPageState();
}

class _SupplierLedgerPageState extends State<SupplierLedgerPage> {
  late Supplier _supplier;
  late SupplierService _supplierService;
  late PaymentMethodService _paymentMethodService;

  List<SupplierTransaction> _transactions = [];
  List<Product> _allProducts = [];
  List<PaymentMethod> _paymentMethods = [];
  bool _isLoading = true;

  final _currencyFormat = NumberFormat.currency(
    locale: 'id',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static const Color primaryGreen = Color(0xFF00BF63);

  @override
  void initState() {
    super.initState();
    _supplier = widget.supplier;
    final db = Provider.of<AppDatabase>(context, listen: false);
    _supplierService = SupplierService(db);
    _paymentMethodService = PaymentMethodService(db);
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final db = Provider.of<AppDatabase>(context, listen: false);

      // Refresh supplier
      final suppliers = await _supplierService.getSuppliers(widget.storeId);
      final currentSup = suppliers.firstWhere(
        (s) => s.id == _supplier.id,
        orElse: () => _supplier,
      );

      // Fetch transactions
      final txs = await _supplierService.getSupplierTransactions(
        widget.storeId,
        _supplier.id,
      );

      // Fetch products
      final prods = await (db.select(db.products)
            ..where((t) => t.storeId.equals(widget.storeId) & t.isDeleted.equals(false))
            ..orderBy([(t) => drift.OrderingTerm.asc(t.name)]))
          .get();

      // Fetch payment methods
      final pms = await _paymentMethodService.getPaymentMethods(widget.storeId);

      if (mounted) {
        setState(() {
          _supplier = currentSup;
          _transactions = txs;
          _allProducts = prods;
          _paymentMethods = pms;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching supplier ledger: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          _supplier.name,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_supplier.phone != null && _supplier.phone!.trim().isNotEmpty)
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline_rounded, color: primaryGreen),
              tooltip: "Hubungi WhatsApp",
              onPressed: _openWhatsAppChat,
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: "Muat Ulang",
            onPressed: _fetchData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryGreen))
          : RefreshIndicator(
              onRefresh: _fetchData,
              color: primaryGreen,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Header Card Ala Buku Niaga (Gambar 2)
                        _buildSupplierHeaderCard(isDark),
                        const SizedBox(height: 18),

                        // 2. Action Buttons Banner (Catat Pasokan & Retur)
                        _buildQuickActionButtons(isDark),
                        const SizedBox(height: 24),

                        // 3. Section Title RIWAYAT
                        Row(
                          children: [
                            Text(
                              "RIWAYAT",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                                color: isDark ? Colors.white60 : Colors.blueGrey[600],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: (isDark ? Colors.white10 : Colors.grey[200]),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                "${_transactions.length} mutasi",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white70 : Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // 4. Daftar Riwayat Transaksi (PB, BH, RB)
                        if (_transactions.isEmpty)
                          _buildEmptyLedgerState(isDark)
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _transactions.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (ctx, index) {
                              return _buildTransactionCard(_transactions[index], isDark);
                            },
                          ),

                        const SizedBox(height: 60),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  /// 1. Header Card Persis Seperti Gambar 2 (Buku Niaga)
  Widget _buildSupplierHeaderCard(bool isDark) {
    final debt = _supplier.unpaidBalance;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row TIPE: SUPPLIER
          Row(
            children: [
              SizedBox(
                width: 90,
                child: Text(
                  "TIPE",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white54 : Colors.grey[600],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "SUPPLIER",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0284C7),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // TELP
          Row(
            children: [
              SizedBox(
                width: 90,
                child: Text(
                  "TELP",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white54 : Colors.grey[600],
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  (_supplier.phone != null && _supplier.phone!.trim().isNotEmpty)
                      ? _supplier.phone!.trim()
                      : "-",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ALAMAT
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 90,
                child: Text(
                  "ALAMAT",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white54 : Colors.grey[600],
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  (_supplier.address != null && _supplier.address!.trim().isNotEmpty)
                      ? _supplier.address!.trim().toUpperCase()
                      : "-",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // PIUTANG
          Row(
            children: [
              SizedBox(
                width: 90,
                child: Text(
                  "PIUTANG",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white54 : Colors.grey[600],
                  ),
                ),
              ),
              Text(
                "Rp 0",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // HUTANG (Highlighted merah/oranye tebal)
          Row(
            children: [
              SizedBox(
                width: 90,
                child: Text(
                  "HUTANG",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ),
              Text(
                _currencyFormat.format(debt),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: debt > 0
                      ? const Color(0xFFDC2626) // Merah tegas jika ada hutang
                      : primaryGreen, // Hijau jika lunas
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Action Buttons: Bayar Hutang, Edit, Hapus
          Row(
            children: [
              // Tombol Kuning / Orange: Bayar Hutang
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: debt > 0 ? _openPaymentDialog : () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Hutang supplier ini sudah lunas (Rp 0)."),
                        backgroundColor: primaryGreen,
                      ),
                    );
                  },
                  icon: const Icon(Icons.payment_rounded, size: 18),
                  label: Text(
                    "Bayar Hutang",
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: debt > 0 ? const Color(0xFFF59E0B) : Colors.grey[400],
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Tombol Edit
              OutlinedButton.icon(
                onPressed: _openEditSupplierDialog,
                icon: const Icon(Icons.edit_outlined, size: 17),
                label: Text(
                  "Edit",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? Colors.white70 : const Color(0xFF334155),
                  side: BorderSide(
                    color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Tombol Hapus (Merah)
              IconButton(
                onPressed: _confirmDeleteSupplier,
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 19),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.all(12),
                ),
                tooltip: "Hapus Supplier",
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 2. Action Buttons Banner (Catat Pasokan & Retur Barang)
  Widget _buildQuickActionButtons(bool isDark) {
    return Row(
      children: [
        // Tombol Pasokan Masuk (PB)
        Expanded(
          child: InkWell(
            onTap: _openPurchaseDialog,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0284C7).withValues(alpha: isDark ? 0.15 : 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_shopping_cart_rounded, size: 18, color: Color(0xFF0284C7)),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      "+ Pasokan Masuk (PB)",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0284C7),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Tombol Retur Barang (RB)
        Expanded(
          child: InkWell(
            onTap: _openReturnDialog,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withValues(alpha: isDark ? 0.15 : 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.assignment_return_outlined, size: 18, color: Color(0xFF8B5CF6)),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      "Retur Barang (RB)",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF8B5CF6),
                      ),
                      overflow: TextOverflow.ellipsis,
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

  /// 3. Kartu Riwayat Transaksi (PB, BH, RB) Persis Seperti Gambar 2
  Widget _buildTransactionCard(SupplierTransaction tx, bool isDark) {
    final isPurchase = tx.isPurchase;
    final isPayment = tx.isPayment;
    final isReturn = tx.isReturn;

    Color badgeBg;
    Color badgeText;
    String badgeTitle;

    if (isPurchase) {
      badgeBg = const Color(0xFFE0F2FE);
      badgeText = const Color(0xFF0284C7);
      badgeTitle = "PEMBELIAN";
    } else if (isPayment) {
      badgeBg = const Color(0xFFFEE2E2);
      badgeText = const Color(0xFFDC2626);
      badgeTitle = "BAYAR HUTANG";
    } else {
      badgeBg = const Color(0xFFF3E8FF);
      badgeText = const Color(0xFF8B5CF6);
      badgeTitle = "RETUR BARANG";
    }

    // Format Tanggal: Kam, 5 Nov 2026
    final dateStr = DateFormat("EEE, d MMM yyyy", "id_ID").format(tx.createdAt);

    return InkWell(
      onTap: () => _openTransactionDetailSheet(tx),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges: Tipe + Nomor + Status
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          badgeTitle,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: badgeText,
                          ),
                        ),
                      ),
                      Text(
                        tx.transactionNo,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      if (isPurchase)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: tx.paymentStatus == 'hutang'
                                ? const Color(0xFFFEF3C7)
                                : const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            tx.paymentStatus == 'hutang' ? "HUTANG" : "LUNAS",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: tx.paymentStatus == 'hutang'
                                  ? const Color(0xFFD97706)
                                  : const Color(0xFF16A34A),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Keterangan Supplier & Sumber Akun
                  Text(
                    isPurchase
                        ? "Supplier: ${_supplier.name}"
                        : (isPayment
                            ? "Ke ${_supplier.name} · ${tx.paymentMethod ?? 'Kas'}"
                            : "Retur ke ${_supplier.name}"),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white70 : const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 3),

                  // Tanggal
                  Text(
                    dateStr,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: isDark ? Colors.white38 : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),

            // Nominal Kanan
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "${(isPayment || isReturn) ? '-' : ''}${_currencyFormat.format(tx.totalAmount)}",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: isPayment
                        ? const Color(0xFFDC2626) // Merah tanda bayar keluar
                        : (isReturn
                            ? const Color(0xFF8B5CF6) // Ungu tanda retur
                            : (isDark ? Colors.white : const Color(0xFF0F172A))),
                  ),
                ),
                if (tx.items.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    "${tx.items.length} jenis item",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyLedgerState(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            "Belum Ada Riwayat Transaksi",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white70 : const Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Gunakan tombol '+ Pasokan Masuk' untuk mencatat drop barang pertama dari supplier ini.",
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // ─── DIALOG: BAYAR HUTANG (BH-xxxx) ─────────────────────────────────────────
  void _openPaymentDialog() {
    final debt = _supplier.unpaidBalance;
    final amountCtrl = TextEditingController(text: debt.toStringAsFixed(0));
    final notesCtrl = TextEditingController(text: "Setoran hasil jualan");

    // Default to Kas Toko
    PaymentMethod? selectedMethod = _paymentMethods.cast<PaymentMethod?>().firstWhere(
      (m) => m?.type.toLowerCase() == 'cash' || (m?.name.toLowerCase().contains('kas') ?? false),
      orElse: () => _paymentMethods.isNotEmpty ? _paymentMethods.first : null,
    );

    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            final double currentAmount = double.tryParse(amountCtrl.text) ?? 0.0;
            final double remainingDebt = (debt - currentAmount) > 0 ? (debt - currentAmount) : 0.0;

            return KasirDialog(
              title: "Bayar Hutang Supplier",
              icon: Icons.payments_rounded,
              iconColor: const Color(0xFFF59E0B),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info Box Sisa Hutang
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Total Hutang Saat Ini:",
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          _currencyFormat.format(debt),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFD97706),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Input Nominal Bayar
                  Text("Nominal Pembayaran *", style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                    decoration: InputDecoration(
                      prefixText: "Rp ",
                      prefixIcon: const Icon(Icons.attach_money, size: 20),
                      filled: true,
                      fillColor: isDark ? Colors.white10 : Colors.grey[100],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    onChanged: (_) => setDialogState(() {}),
                  ),
                  const SizedBox(height: 6),

                  // Shortcut Button: Bayar Lunas Penuh
                  Align(
                    alignment: Alignment.centerRight,
                    child: InkWell(
                      onTap: () {
                        setDialogState(() {
                          amountCtrl.text = debt.toStringAsFixed(0);
                        });
                      },
                      child: Text(
                        "Bayar Lunas Penuh (${_currencyFormat.format(debt)})",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0284C7),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Pilihan Sumber Pembayaran (Kas / Bank)
                  Text("Potong Dari Saldo *", style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<PaymentMethod>(
                        value: selectedMethod,
                        isExpanded: true,
                        dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                        items: _paymentMethods.map((pm) {
                          return DropdownMenuItem<PaymentMethod>(
                            value: pm,
                            child: Row(
                              children: [
                                Icon(
                                  pm.type == 'cash' ? Icons.money_rounded : Icons.account_balance_wallet_rounded,
                                  size: 18,
                                  color: primaryGreen,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    pm.name,
                                    style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setDialogState(() => selectedMethod = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Otomatis mengurangi saldo akun ini di Buku Kas (bisa sampai saldo minus jika uang fisik kurang).",
                    style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: Colors.grey, fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 14),

                  // Catatan (Opsional)
                  Text("Catatan Setoran", style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: notesCtrl,
                    style: GoogleFonts.plusJakartaSans(fontSize: 12),
                    decoration: InputDecoration(
                      hintText: "Contoh: Setoran shift sore",
                      filled: true,
                      fillColor: isDark ? Colors.white10 : Colors.grey[100],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Info Sisa Hutang Setelah Bayar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Sisa Hutang Setelah Setor:", style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w500)),
                      Text(
                        _currencyFormat.format(remainingDebt),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: remainingDebt == 0 ? primaryGreen : const Color(0xFFD97706),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              primaryActionLabel: "Simpan & Bayar",
              onPrimaryAction: () async {
                final amount = double.tryParse(amountCtrl.text) ?? 0.0;
                if (amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Nominal pembayaran harus lebih dari 0"), backgroundColor: Colors.orange),
                  );
                  return;
                }

                Navigator.pop(ctx);
                setState(() => _isLoading = true);

                try {
                  final newTx = await _supplierService.recordPayment(
                    storeId: widget.storeId,
                    supplierId: _supplier.id,
                    amount: amount,
                    paymentMethod: selectedMethod?.name ?? 'Kas',
                    paymentMethodId: selectedMethod?.id,
                    notes: notesCtrl.text.trim(),
                  );

                  await _fetchData();
                  widget.onSupplierUpdated?.call();

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Berhasil mencatat setoran bayar hutang ${newTx.transactionNo}!"),
                        backgroundColor: primaryGreen,
                        action: (_supplier.phone != null && _supplier.phone!.isNotEmpty)
                            ? SnackBarAction(
                                label: "KIRIM WA",
                                textColor: Colors.white,
                                onPressed: () => _sharePaymentToWhatsApp(newTx),
                              )
                            : null,
                      ),
                    );
                  }
                } catch (e) {
                  debugPrint("Error recording payment: $e");
                  if (mounted) {
                    setState(() => _isLoading = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Gagal bayar hutang: $e"), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              secondaryActionLabel: "Batal",
            );
          },
        );
      },
    );
  }

  // ─── DIALOG: PASOKAN MASUK (PB-xxxx) ────────────────────────────────────────
  void _openPurchaseDialog() {
    final List<Map<String, dynamic>> draftItems = [];
    String paymentStatus = 'hutang'; // Default hutang tempo
    PaymentMethod? selectedMethod = _paymentMethods.cast<PaymentMethod?>().firstWhere(
      (m) => m?.type.toLowerCase() == 'cash' || (m?.name.toLowerCase().contains('kas') ?? false),
      orElse: () => _paymentMethods.isNotEmpty ? _paymentMethods.first : null,
    );
    final notesCtrl = TextEditingController(text: "Drop pasokan barang");

    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            final totalPurchase = draftItems.fold<double>(
              0.0,
              (sum, item) => sum + ((item['qty'] as num? ?? 0) * (item['price'] as num? ?? 0)),
            );

            return Dialog(
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 550),
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.add_shopping_cart_rounded, color: Color(0xFF0284C7), size: 22),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Catat Pasokan Masuk (PB)",
                                  style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700),
                                ),
                                Text(
                                  "Stok produk di kasir otomatis bertambah",
                                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 14),

                      // Daftar Item yang di-drop
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Item Barang Diterima (${draftItems.length})", style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700)),
                          TextButton.icon(
                            onPressed: () => _showAddItemSheet(dialogCtx, draftItems, setDialogState),
                            icon: const Icon(Icons.add_rounded, size: 16),
                            label: const Text("+ Tambah Item"),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF0284C7),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      if (draftItems.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white10 : Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.inventory_2_outlined, color: Colors.grey, size: 32),
                              const SizedBox(height: 6),
                              Text(
                                "Belum ada item barang dipilih.",
                                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 6),
                              ElevatedButton(
                                onPressed: () => _showAddItemSheet(dialogCtx, draftItems, setDialogState),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0284C7),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  minimumSize: Size.zero,
                                ),
                                child: const Text("Pilih Barang"),
                              ),
                            ],
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: draftItems.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, idx) {
                            final item = draftItems[idx];
                            final qty = (item['qty'] as num? ?? 1).toDouble();
                            final price = (item['price'] as num? ?? 0).toDouble();
                            final subtotal = qty * price;

                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['name'] ?? 'Produk',
                                          style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700),
                                        ),
                                        Text(
                                          "${qty % 1 == 0 ? qty.toInt() : qty} pcs x ${_currencyFormat.format(price)}",
                                          style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.grey[600]),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    _currencyFormat.format(subtotal),
                                    style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xFF0284C7)),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close_rounded, size: 16, color: Colors.red),
                                    onPressed: () {
                                      setDialogState(() {
                                        draftItems.removeAt(idx);
                                      });
                                    },
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                      const SizedBox(height: 14),

                      // Total Pasokan
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Total Nilai Pasokan:", style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700)),
                            Text(
                              _currencyFormat.format(totalPurchase),
                              style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF0284C7)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Pilihan Status Pembayaran: HUTANG (Tempo) vs LUNAS
                      Text("Metode Pembayaran Tagihan *", style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const Center(child: Text("HUTANG (Tempo)")),
                              selected: paymentStatus == 'hutang',
                              onSelected: (_) => setDialogState(() => paymentStatus = 'hutang'),
                              selectedColor: const Color(0xFFFEF3C7),
                              labelStyle: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 11.5,
                                color: paymentStatus == 'hutang' ? const Color(0xFFD97706) : Colors.grey,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ChoiceChip(
                              label: const Center(child: Text("LUNAS (Bayar Langsung)")),
                              selected: paymentStatus == 'lunas',
                              onSelected: (_) => setDialogState(() => paymentStatus = 'lunas'),
                              selectedColor: const Color(0xFFDCFCE7),
                              labelStyle: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 11.5,
                                color: paymentStatus == 'lunas' ? const Color(0xFF16A34A) : Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      if (paymentStatus == 'lunas') ...[
                        Text("Potong Dari Saldo *", style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white10 : Colors.grey[100],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<PaymentMethod>(
                              value: selectedMethod,
                              isExpanded: true,
                              dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                              items: _paymentMethods.map((pm) {
                                return DropdownMenuItem<PaymentMethod>(
                                  value: pm,
                                  child: Text(pm.name, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600)),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setDialogState(() => selectedMethod = val);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],

                      // Catatan
                      Text("Catatan (Opsional)", style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      TextField(
                        controller: notesCtrl,
                        style: GoogleFonts.plusJakartaSans(fontSize: 12),
                        decoration: InputDecoration(
                          hintText: "Contoh: Drop pagi 50 pcs",
                          filled: true,
                          fillColor: isDark ? Colors.white10 : Colors.grey[100],
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: Text("Batal", style: GoogleFonts.plusJakartaSans(color: Colors.grey)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: draftItems.isEmpty
                                  ? null
                                  : () async {
                                      Navigator.pop(ctx);
                                      setState(() => _isLoading = true);

                                      try {
                                        final items = draftItems.map((e) {
                                          final q = (e['qty'] as num).toDouble();
                                          final p = (e['price'] as num).toDouble();
                                          return SupplierTransactionItem(
                                            productId: e['id'] as String,
                                            productName: e['name'] as String,
                                            quantity: q,
                                            unitPrice: p,
                                            subtotal: q * p,
                                          );
                                        }).toList();

                                        final newTx = await _supplierService.recordPurchase(
                                          storeId: widget.storeId,
                                          supplierId: _supplier.id,
                                          items: items,
                                          paymentStatus: paymentStatus,
                                          paymentMethod: paymentStatus == 'lunas' ? (selectedMethod?.name ?? 'Kas') : null,
                                          paymentMethodId: paymentStatus == 'lunas' ? selectedMethod?.id : null,
                                          notes: notesCtrl.text.trim(),
                                        );

                                        await _fetchData();
                                        widget.onSupplierUpdated?.call();

                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                "Berhasil mencatat pasokan ${newTx.transactionNo}! Stok produk otomatis bertambah.",
                                              ),
                                              backgroundColor: primaryGreen,
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        debugPrint("Error recording purchase: $e");
                                        if (mounted) {
                                          setState(() => _isLoading = false);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text("Gagal mencatat pasokan: $e"), backgroundColor: Colors.red),
                                          );
                                        }
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0284C7),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: Text(
                                "Simpan Pasokan",
                                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
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
          },
        );
      },
    );
  }

  void _showAddItemSheet(
    BuildContext parentCtx,
    List<Map<String, dynamic>> draftItems,
    StateSetter setParentState,
  ) {
    Product? selectedProd = _allProducts.isNotEmpty ? _allProducts.first : null;
    final qtyCtrl = TextEditingController(text: "10");
    final priceCtrl = TextEditingController(
      text: (selectedProd?.buyPrice ?? selectedProd?.basePrice ?? 0.0).toStringAsFixed(0),
    );

    showDialog(
      context: parentCtx,
      builder: (sheetCtx) {
        final isDark = Theme.of(sheetCtx).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return KasirDialog(
              title: "Pilih Barang Pasokan",
              icon: Icons.inventory_rounded,
              iconColor: const Color(0xFF0284C7),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Pilih Produk *", style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Product>(
                        value: selectedProd,
                        isExpanded: true,
                        dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                        items: _allProducts.map((p) {
                          return DropdownMenuItem<Product>(
                            value: p,
                            child: Text(
                              p.name ?? "Produk",
                              style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setSheetState(() {
                              selectedProd = val;
                              final buyP = val.buyPrice ?? val.basePrice ?? 0.0;
                              priceCtrl.text = buyP.toStringAsFixed(0);
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Jumlah (Qty) *", style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: qtyCtrl,
                              keyboardType: TextInputType.number,
                              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: isDark ? Colors.white10 : Colors.grey[100],
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Harga Beli Modal *", style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: priceCtrl,
                              keyboardType: TextInputType.number,
                              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                              decoration: InputDecoration(
                                prefixText: "Rp ",
                                filled: true,
                                fillColor: isDark ? Colors.white10 : Colors.grey[100],
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              primaryActionLabel: "Tambahkan",
              onPrimaryAction: () {
                if (selectedProd == null) return;
                final qty = double.tryParse(qtyCtrl.text) ?? 0.0;
                final price = double.tryParse(priceCtrl.text) ?? 0.0;
                if (qty <= 0) return;

                setParentState(() {
                  draftItems.add({
                    'id': selectedProd!.id,
                    'name': selectedProd!.name ?? 'Produk',
                    'qty': qty,
                    'price': price,
                  });
                });

                Navigator.pop(sheetCtx);
              },
              secondaryActionLabel: "Batal",
            );
          },
        );
      },
    );
  }

  // ─── DIALOG: RETUR BARANG (RB-xxxx) ─────────────────────────────────────────
  void _openReturnDialog() {
    Product? selectedProd = _allProducts.isNotEmpty ? _allProducts.first : null;
    final qtyCtrl = TextEditingController(text: "1");
    final priceCtrl = TextEditingController(
      text: (selectedProd?.buyPrice ?? selectedProd?.basePrice ?? 0.0).toStringAsFixed(0),
    );
    final reasonCtrl = TextEditingController(text: "Basi / Cacat / Tidak laku");

    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return KasirDialog(
              title: "Retur Barang ke Supplier",
              icon: Icons.assignment_return_rounded,
              iconColor: const Color(0xFF8B5CF6),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Retur barang akan memotong stok di kasir dan otomatis memotong tagihan hutang supplier ini.",
                    style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),

                  Text("Pilih Produk Diretur *", style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Product>(
                        value: selectedProd,
                        isExpanded: true,
                        dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                        items: _allProducts.map((p) {
                          return DropdownMenuItem<Product>(
                            value: p,
                            child: Text(
                              "${p.name ?? 'Produk'} (Stok: ${(p.stockQuantity ?? 0).toInt()})",
                              style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() {
                              selectedProd = val;
                              final buyP = val.buyPrice ?? val.basePrice ?? 0.0;
                              priceCtrl.text = buyP.toStringAsFixed(0);
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Jumlah Retur *", style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: qtyCtrl,
                              keyboardType: TextInputType.number,
                              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: isDark ? Colors.white10 : Colors.grey[100],
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Harga Pengurang *", style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: priceCtrl,
                              keyboardType: TextInputType.number,
                              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                              decoration: InputDecoration(
                                prefixText: "Rp ",
                                filled: true,
                                fillColor: isDark ? Colors.white10 : Colors.grey[100],
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Text("Alasan Retur", style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: reasonCtrl,
                    style: GoogleFonts.plusJakartaSans(fontSize: 12),
                    decoration: InputDecoration(
                      hintText: "Contoh: Basi / Cacat fisik / Rusak",
                      filled: true,
                      fillColor: isDark ? Colors.white10 : Colors.grey[100],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                ],
              ),
              primaryActionLabel: "Proses Retur",
              onPrimaryAction: () async {
                if (selectedProd == null) return;
                final qty = double.tryParse(qtyCtrl.text) ?? 0.0;
                final price = double.tryParse(priceCtrl.text) ?? 0.0;
                if (qty <= 0) return;

                Navigator.pop(ctx);
                setState(() => _isLoading = true);

                try {
                  final newTx = await _supplierService.recordReturn(
                    storeId: widget.storeId,
                    supplierId: _supplier.id,
                    items: [
                      SupplierTransactionItem(
                        productId: selectedProd!.id,
                        productName: selectedProd!.name ?? 'Produk',
                        quantity: qty,
                        unitPrice: price,
                        subtotal: qty * price,
                      ),
                    ],
                    notes: reasonCtrl.text.trim(),
                  );

                  await _fetchData();
                  widget.onSupplierUpdated?.call();

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Berhasil mencatat retur barang ${newTx.transactionNo}! Hutang dan stok dikurangi."),
                        backgroundColor: primaryGreen,
                      ),
                    );
                  }
                } catch (e) {
                  debugPrint("Error recording return: $e");
                  if (mounted) {
                    setState(() => _isLoading = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Gagal retur: $e"), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              secondaryActionLabel: "Batal",
            );
          },
        );
      },
    );
  }

  // ─── DETAIL NOTA TRANSAKSI ──────────────────────────────────────────────────
  void _openTransactionDetailSheet(SupplierTransaction tx) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Faktur #${tx.transactionNo}",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: tx.isPurchase
                          ? (tx.paymentStatus == 'hutang' ? const Color(0xFFFEF3C7) : const Color(0xFFDCFCE7))
                          : (tx.isPayment ? const Color(0xFFFEE2E2) : const Color(0xFFF3E8FF)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      tx.isPurchase
                          ? (tx.paymentStatus == 'hutang' ? "BELUM LUNAS (HUTANG)" : "LUNAS (TUNAI)")
                          : (tx.isPayment ? "PELUNASAN SETORAN" : "RETUR BARANG"),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: tx.isPurchase
                            ? (tx.paymentStatus == 'hutang' ? const Color(0xFFD97706) : const Color(0xFF16A34A))
                            : (tx.isPayment ? const Color(0xFFDC2626) : const Color(0xFF8B5CF6)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                DateFormat("EEEE, d MMMM yyyy HH:mm", "id_ID").format(tx.createdAt),
                style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: Colors.grey),
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 14),

              if (tx.items.isNotEmpty) ...[
                Text("Daftar Item:", style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                ...tx.items.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            "${item.productName} (${item.quantity % 1 == 0 ? item.quantity.toInt() : item.quantity} pcs)",
                            style: GoogleFonts.plusJakartaSans(fontSize: 12.5),
                          ),
                        ),
                        Text(
                          _currencyFormat.format(item.subtotal),
                          style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 8),
                const Divider(height: 1),
                const SizedBox(height: 8),
              ],

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Total Transaksi:", style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700)),
                  Text(
                    _currencyFormat.format(tx.totalAmount),
                    style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF0284C7)),
                  ),
                ],
              ),

              if (tx.notes != null && tx.notes!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  "Catatan: ${tx.notes}",
                  style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: Colors.grey, fontStyle: FontStyle.italic),
                ),
              ],
              const SizedBox(height: 20),

              // Tombol WhatsApp & Tutup
              Row(
                children: [
                  if (_supplier.phone != null && _supplier.phone!.isNotEmpty) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          if (tx.isPayment) {
                            _sharePaymentToWhatsApp(tx);
                          } else {
                            _sharePurchaseToWhatsApp(tx);
                          }
                        },
                        icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: primaryGreen),
                        label: const Text("Kirim ke WhatsApp"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryGreen,
                          side: const BorderSide(color: primaryGreen),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF334155),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text("Tutup"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── EDIT & DELETE SUPPLIER ────────────────────────────────────────────────
  void _openEditSupplierDialog() {
    final nameCtrl = TextEditingController(text: _supplier.name);
    final phoneCtrl = TextEditingController(text: _supplier.phone ?? '');
    final addrCtrl = TextEditingController(text: _supplier.address ?? '');
    final notesCtrl = TextEditingController(text: _supplier.notes ?? '');

    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return KasirDialog(
          title: "Edit Supplier",
          icon: Icons.edit_note_rounded,
          iconColor: const Color(0xFF0284C7),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Nama Supplier *", style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: nameCtrl,
                style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: isDark ? Colors.white10 : Colors.grey[100],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 10),

              Text("No. WhatsApp / HP", style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                style: GoogleFonts.plusJakartaSans(fontSize: 13),
                decoration: InputDecoration(
                  hintText: "Contoh: 08814030655",
                  filled: true,
                  fillColor: isDark ? Colors.white10 : Colors.grey[100],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 10),

              Text("Alamat Gudang / Lokasi", style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: addrCtrl,
                style: GoogleFonts.plusJakartaSans(fontSize: 13),
                decoration: InputDecoration(
                  hintText: "Contoh: GG MELATI NO. 26",
                  filled: true,
                  fillColor: isDark ? Colors.white10 : Colors.grey[100],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 10),

              Text("Catatan", style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: notesCtrl,
                style: GoogleFonts.plusJakartaSans(fontSize: 12),
                decoration: InputDecoration(
                  hintText: "Contoh: Kontak bos gudang pusat",
                  filled: true,
                  fillColor: isDark ? Colors.white10 : Colors.grey[100],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
          primaryActionLabel: "Simpan Perubahan",
          onPrimaryAction: () async {
            final name = nameCtrl.text.trim();
            if (name.isEmpty) return;

            Navigator.pop(ctx);
            setState(() => _isLoading = true);

            try {
              final updated = _supplier.copyWith(
                name: name,
                phone: phoneCtrl.text.trim(),
                address: addrCtrl.text.trim(),
                notes: notesCtrl.text.trim(),
              );

              await _supplierService.updateSupplier(updated);
              await _fetchData();
              widget.onSupplierUpdated?.call();

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Profil supplier berhasil diperbarui!"), backgroundColor: primaryGreen),
                );
              }
            } catch (e) {
              debugPrint("Error updating supplier: $e");
              if (mounted) setState(() => _isLoading = false);
            }
          },
          secondaryActionLabel: "Batal",
        );
      },
    );
  }

  void _confirmDeleteSupplier() {
    showDialog(
      context: context,
      builder: (ctx) => KasirDialog(
        title: "Hapus Supplier?",
        message: "Data supplier '${_supplier.name}' akan dihapus dari sistem. Riwayat transaksi sebelumnya tetap tercatat.",
        icon: Icons.delete_outline_rounded,
        iconColor: Colors.red,
        isDestructive: true,
        primaryActionLabel: "Hapus",
        onPrimaryAction: () async {
          Navigator.pop(ctx);
          await _supplierService.deleteSupplier(_supplier.id, widget.storeId);
          widget.onSupplierUpdated?.call();
          if (mounted) {
            Navigator.pop(context); // Back to supplier list
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Supplier '${_supplier.name}' berhasil dihapus.")),
            );
          }
        },
        secondaryActionLabel: "Batal",
      ),
    );
  }

  // ─── WHATSAPP INTEGRATION ──────────────────────────────────────────────────
  void _openWhatsAppChat() async {
    final phone = _supplier.phone?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';
    if (phone.isEmpty) return;

    final formatted = phone.startsWith('0') ? '62${phone.substring(1)}' : phone;
    final url = Uri.parse("https://wa.me/$formatted");

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _sharePaymentToWhatsApp(SupplierTransaction tx) async {
    final phone = _supplier.phone?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';
    final formatted = phone.startsWith('0') ? '62${phone.substring(1)}' : phone;

    final msg = """
*BUKTI SETORAN / BAYAR HUTANG*
---------------------------------------
No Transaksi: ${tx.transactionNo}
Tanggal: ${DateFormat("dd/MM/yyyy HH:mm").format(tx.createdAt)}
Penerima: ${_supplier.name}
Metode: ${tx.paymentMethod ?? 'Kas Toko'}
---------------------------------------
*Nominal Setoran: ${_currencyFormat.format(tx.totalAmount)}*
*Sisa Hutang: ${_currencyFormat.format(_supplier.unpaidBalance)}*
---------------------------------------
Catatan: ${tx.notes ?? '-'}

_Tercatat otomatis via KAKILIMA POS_
""".trim();

    final url = Uri.parse("https://wa.me/$formatted?text=${Uri.encodeComponent(msg)}");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _sharePurchaseToWhatsApp(SupplierTransaction tx) async {
    final phone = _supplier.phone?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';
    final formatted = phone.startsWith('0') ? '62${phone.substring(1)}' : phone;

    final itemsStr = tx.items.map((i) => "• ${i.productName}: ${i.quantity.toInt()} pcs x ${_currencyFormat.format(i.unitPrice)} = ${_currencyFormat.format(i.subtotal)}").join("\n");

    final msg = """
*BUKTI PENERIMAAN PASOKAN BARANG*
---------------------------------------
No Faktur: ${tx.transactionNo}
Tanggal: ${DateFormat("dd/MM/yyyy HH:mm").format(tx.createdAt)}
Supplier: ${_supplier.name}
Status: ${tx.paymentStatus.toUpperCase()}
---------------------------------------
*Rincian Barang:*
$itemsStr
---------------------------------------
*Total Pasokan: ${_currencyFormat.format(tx.totalAmount)}*
*Total Hutang Berjalan: ${_currencyFormat.format(_supplier.unpaidBalance)}*

_Tercatat otomatis via KAKILIMA POS_
""".trim();

    final url = Uri.parse("https://wa.me/$formatted?text=${Uri.encodeComponent(msg)}");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}
