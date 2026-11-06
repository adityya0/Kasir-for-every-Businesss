import 'supplier_ledger_page.dart';

import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

import 'package:intl/intl.dart';

import 'package:provider/provider.dart';

import '../../../controllers/admin_controller.dart';

import '../../../services/app_database.dart';

import '../../../services/supplier_service.dart';

import '../../../services/expense_service.dart';

import '../../../services/export_service.dart';

import '../../../services/platform/file_manager.dart';

import 'package:open_filex/open_filex.dart';

import '../../../widgets/kasir_dialog.dart';

import 'package:drift/drift.dart' as drift;



class SupplierPage extends StatefulWidget {

  final VoidCallback? onBack;

  const SupplierPage({super.key, this.onBack});



  @override

  State<SupplierPage> createState() => _SupplierPageState();

}



class _SupplierPageState extends State<SupplierPage> {

  late SupplierService _supplierService;

  List<Supplier> _suppliers = [];

  List<Supplier> _filteredSuppliers = [];

  List<Product> _allProducts = [];

  Map<String, double> _outstandingBills = {};

  bool _isLoading = true;

  final TextEditingController _searchController = TextEditingController();



  final _currencyFormat = NumberFormat.currency(

    locale: 'id',

    symbol: 'Rp ',

    decimalDigits: 0,

  );



  static const Color primaryGreen = Color(0xFF00BF63);



  @override

  void initState() {

    super.initState();

    final db = Provider.of<AppDatabase>(context, listen: false);

    _supplierService = SupplierService(db);

    _fetchData();

    _searchController.addListener(_filterSuppliers);

  }



  @override

  void dispose() {

    _searchController.dispose();

    super.dispose();

  }



  Future<void> _fetchData() async {

    setState(() => _isLoading = true);

    try {

      final admin = Provider.of<AdminController>(context, listen: false);

      final db = Provider.of<AppDatabase>(context, listen: false);

      final storeId = admin.storeId ?? '';



      final sups = await _supplierService.getSuppliers(storeId);

      final prods = await (db.select(db.products)

            ..where((t) => t.storeId.equals(storeId) & t.isDeleted.equals(false)))

          .get();



      final bills = <String, double>{};

      for (final s in sups) {

        bills[s.id] = await _supplierService.getOutstandingBill(storeId, s);

      }



      if (mounted) {

        setState(() {

          _suppliers = sups;

          _allProducts = prods;

          _outstandingBills = bills;

          _applyFilter();

          _isLoading = false;

        });

      }

    } catch (e) {

      debugPrint("SupplierPage fetch error: $e");

      if (mounted) setState(() => _isLoading = false);

    }

  }



  void _filterSuppliers() {

    _applyFilter();

  }



  void _applyFilter() {

    final query = _searchController.text.trim().toLowerCase();

    setState(() {

      if (query.isEmpty) {

        _filteredSuppliers = List.from(_suppliers);

      } else {

        _filteredSuppliers = _suppliers.where((s) {

          final nameMatch = s.name.toLowerCase().contains(query);

          final phoneMatch = (s.phone ?? '').toLowerCase().contains(query);

          final addressMatch = (s.address ?? '').toLowerCase().contains(query);

          return nameMatch || phoneMatch || addressMatch;

        }).toList();

      }

    });

  }



  @override

  Widget build(BuildContext context) {

    final isDark = Theme.of(context).brightness == Brightness.dark;



    return Scaffold(

      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),

      appBar: AppBar(

        title: Row(

          children: [

            Container(

              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),

              decoration: BoxDecoration(

                color: Colors.white,

                borderRadius: BorderRadius.circular(8),

              ),

              child: Image.asset(

                'assets/logo/logo_icon.png',

                height: 22,

                fit: BoxFit.contain,

              ),

            ),

            const SizedBox(width: 10),

            Text(

              "Kelola Supplier",

              style: GoogleFonts.plusJakartaSans(

                fontWeight: FontWeight.w700,

                color: isDark ? Colors.white : Colors.black87,

                fontSize: 18,

              ),

            ),

          ],

        ),

        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,

        elevation: 0,

        centerTitle: false,

        leading: IconButton(

          icon: Icon(

            Icons.arrow_back_rounded,

            color: isDark ? Colors.white : Colors.black87,

          ),

          onPressed: widget.onBack ?? () => Navigator.pop(context),

        ),

        actions: [

          IconButton(

            icon: const Icon(Icons.receipt_long_rounded, color: primaryGreen),

            tooltip: "Riwayat Semua Pelunasan",

            onPressed: () => _openSettlementHistorySheet(null),

          ),

        ],

      ),

      body: _isLoading

          ? const Center(child: CircularProgressIndicator(color: primaryGreen))

          : RefreshIndicator(

              onRefresh: _fetchData,

              color: primaryGreen,

              child: Column(

                children: [

                  // Search Bar + Quick Add Button

                  Container(

                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,

                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),

                    child: Row(

                      children: [

                        Expanded(

                          child: Container(

                            height: 46,

                            decoration: BoxDecoration(

                              color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF1F5F9),

                              borderRadius: BorderRadius.circular(12),

                              border: Border.all(

                                color: isDark ? Colors.white12 : Colors.grey[200]!,

                              ),

                            ),

                            child: TextField(

                              controller: _searchController,

                              style: GoogleFonts.plusJakartaSans(fontSize: 14),

                              textAlignVertical: TextAlignVertical.center,

                              decoration: InputDecoration(

                                isDense: true,

                                hintText: "Cari supplier (nama, kontak)...",

                                hintStyle: GoogleFonts.plusJakartaSans(

                                  color: Colors.grey,

                                  fontSize: 13,

                                ),

                                prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Colors.grey),

                                suffixIcon: _searchController.text.isNotEmpty

                                    ? IconButton(

                                        icon: const Icon(Icons.clear_rounded, size: 18, color: Colors.grey),

                                        onPressed: () => _searchController.clear(),

                                      )

                                    : null,

                                border: InputBorder.none,

                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),

                              ),

                            ),

                          ),

                        ),

                        const SizedBox(width: 10),

                        Material(

                          color: primaryGreen,

                          borderRadius: BorderRadius.circular(12),

                          child: InkWell(

                            borderRadius: BorderRadius.circular(12),

                            onTap: () => _openSupplierFormDialog(),

                            child: const SizedBox(

                              width: 46,

                              height: 46,

                              child: Icon(

                                Icons.add_rounded,

                                color: Colors.white,

                                size: 24,

                              ),

                            ),

                          ),

                        ),

                      ],

                    ),

                  ),



                  // Supplier List

                  Expanded(

                    child: _filteredSuppliers.isEmpty

                        ? _buildEmptyState(isDark)

                        : ListView.separated(

                            padding: const EdgeInsets.all(16),

                            itemCount: _filteredSuppliers.length,

                            separatorBuilder: (_, __) => const SizedBox(height: 12),

                            itemBuilder: (ctx, index) {

                              final sup = _filteredSuppliers[index];

                              return _buildSupplierCard(sup, isDark);

                            },

                          ),

                  ),

                ],

              ),

            ),

    );

  }



  Widget _buildEmptyState(bool isDark) {

    return Center(

      child: SingleChildScrollView(

        padding: const EdgeInsets.all(32),

        child: Column(

          mainAxisAlignment: MainAxisAlignment.center,

          children: [

            Container(

              width: 80,

              height: 80,

              decoration: BoxDecoration(

                color: primaryGreen.withValues(alpha: 0.1),

                shape: BoxShape.circle,

              ),

              child: const Icon(

                Icons.local_shipping_outlined,

                color: primaryGreen,

                size: 40,

              ),

            ),

            const SizedBox(height: 16),

            Text(

              _searchController.text.isNotEmpty

                  ? "Supplier tidak ditemukan"

                  : "Belum Ada Supplier",

              style: GoogleFonts.plusJakartaSans(

                fontSize: 17,

                fontWeight: FontWeight.w700,

                color: isDark ? Colors.white : Colors.black87,

              ),

            ),

            const SizedBox(height: 6),

            Text(

              _searchController.text.isNotEmpty

                  ? "Coba kata kunci pencarian yang lain."

                  : "Daftarkan supplier Anda untuk mengatur pasokan barang rutin dan restock sekali klik.",

              textAlign: TextAlign.center,

              style: GoogleFonts.plusJakartaSans(

                fontSize: 13,

                color: Colors.grey[500],

              ),

            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(

              onPressed: () => _openSupplierFormDialog(),

              icon: const Icon(Icons.add_rounded, size: 18, color: Colors.white),

              label: Text(

                "Tambah Supplier Pertama",

                style: GoogleFonts.plusJakartaSans(

                  fontWeight: FontWeight.w700,

                  fontSize: 14,

                  color: Colors.white,

                ),

              ),

              style: ElevatedButton.styleFrom(

                backgroundColor: primaryGreen,

                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),

                shape: RoundedRectangleBorder(

                  borderRadius: BorderRadius.circular(14),

                ),

                elevation: 0,

              ),

            ),

          ],

        ),

      ),

    );

  }



    void _openSupplierLedger(Supplier sup) {

    final admin = Provider.of<AdminController>(context, listen: false);

    final storeId = admin.storeId ?? '';

    Navigator.push(

      context,

      MaterialPageRoute(

        builder: (_) => SupplierLedgerPage(

          storeId: storeId,

          supplier: sup,

          onSupplierUpdated: _fetchData,

        ),

      ),

    ).then((_) => _fetchData());

  }



  Widget _buildSupplierCard(Supplier sup, bool isDark) {

    final linkedProductCount = sup.productUsualStock.length;

    final bill = _outstandingBills[sup.id] ?? 0.0;



    return InkWell(

      onTap: () => _openSupplierLedger(sup),

      borderRadius: BorderRadius.circular(16),

      child: Container(

      decoration: BoxDecoration(

        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,

        borderRadius: BorderRadius.circular(16),

        border: Border.all(

          color: isDark ? Colors.white10 : Colors.grey[200]!,

        ),

        boxShadow: [

          BoxShadow(

            color: Colors.black.withValues(alpha: 0.03),

            blurRadius: 8,

            offset: const Offset(0, 2),

          ),

        ],

      ),

      padding: const EdgeInsets.all(16),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          // Row Header: Supplier Icon, Name, Options

          Row(

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              Container(

                width: 44,

                height: 44,

                decoration: BoxDecoration(

                  color: primaryGreen.withValues(alpha: 0.12),

                  borderRadius: BorderRadius.circular(12),

                ),

                child: const Icon(

                  Icons.local_shipping_rounded,

                  color: primaryGreen,

                  size: 24,

                ),

              ),

              const SizedBox(width: 12),

              Expanded(

                child: Column(

                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    Text(

                      sup.name,

                      style: GoogleFonts.plusJakartaSans(

                        fontWeight: FontWeight.w700,

                        fontSize: 16,

                        color: isDark ? Colors.white : Colors.black87,

                      ),

                    ),

                    if (sup.phone != null && sup.phone!.trim().isNotEmpty) ...[

                      const SizedBox(height: 2),

                      Row(

                        children: [

                          const Icon(Icons.phone_outlined, size: 13, color: Colors.grey),

                          const SizedBox(width: 4),

                          Text(

                            sup.phone!.trim(),

                            style: GoogleFonts.plusJakartaSans(

                              fontSize: 12,

                              color: Colors.grey[600],

                            ),

                          ),

                        ],

                      ),

                    ],

                  ],

                ),

              ),

              PopupMenuButton<String>(

                icon: const Icon(Icons.more_vert_rounded, size: 20, color: Colors.grey),

                color: isDark ? const Color(0xFF1E293B) : Colors.white,

                surfaceTintColor: Colors.transparent,

                elevation: 8,

                shape: RoundedRectangleBorder(

                  borderRadius: BorderRadius.circular(14),

                  side: BorderSide(

                    color: isDark ? const Color(0xFF475569) : const Color(0xFF1E293B),

                    width: 1.2,

                  ),

                ),

                onSelected: (val) {

                  final bill = _outstandingBills[sup.id] ?? 0.0;

                  if (val == 'restock') {
                    _openRestockFromSupplierSheet(sup);
                  } else if (val == 'settle') {

                    _openSettleSupplierSheet(sup, bill);

                  } else if (val == 'return') {

                    _openReturnProductSheet(sup);

                  } else if (val == 'history') {

                    _openSettlementHistorySheet(sup);

                  } else if (val == 'edit') {

                    _openSupplierFormDialog(supplier: sup);

                  } else if (val == 'delete') {

                    _confirmDeleteSupplier(sup);

                  }

                },

                itemBuilder: (ctx) => [

                  PopupMenuItem(

                    value: 'settle',

                    child: Row(

                      children: [

                        const Icon(Icons.payments_outlined, size: 18, color: primaryGreen),

                        const SizedBox(width: 8),

                        Text(

                          "Lunasi Tagihan",

                          style: GoogleFonts.plusJakartaSans(

                            fontSize: 13,

                            fontWeight: FontWeight.w600,

                            color: primaryGreen,

                          ),

                        ),

                      ],

                    ),

                  ),

                  PopupMenuItem(

                    value: 'return',

                    child: Row(

                      children: [

                        const Icon(Icons.assignment_return_outlined, size: 18, color: Colors.orange),

                        const SizedBox(width: 8),

                        Text(

                          "Catat Retur Titipan",

                          style: GoogleFonts.plusJakartaSans(

                            fontSize: 13,

                            fontWeight: FontWeight.w600,

                            color: Colors.orange[800],

                          ),

                        ),

                      ],

                    ),

                  ),

                  PopupMenuItem(

                    value: 'history',

                    child: Row(

                      children: [

                        const Icon(Icons.history_rounded, size: 18, color: Colors.blueGrey),

                        const SizedBox(width: 8),

                        Text("Riwayat Pembayaran", style: GoogleFonts.plusJakartaSans(fontSize: 13)),

                      ],

                    ),

                  ),

                  const PopupMenuDivider(),

                  PopupMenuItem(

                    value: 'edit',

                    child: Row(

                      children: [

                        const Icon(Icons.edit_outlined, size: 18, color: Colors.blue),

                        const SizedBox(width: 8),

                        Text("Edit Supplier", style: GoogleFonts.plusJakartaSans(fontSize: 13)),

                      ],

                    ),

                  ),

                  PopupMenuItem(

                    value: 'delete',

                    child: Row(

                      children: [

                        const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),

                        const SizedBox(width: 8),

                        Text("Hapus Supplier", style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.red)),

                      ],

                    ),

                  ),

                ],

              ),

            ],

          ),



          if (sup.address != null && sup.address!.trim().isNotEmpty) ...[

            const SizedBox(height: 8),

            Row(

              children: [

                const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),

                const SizedBox(width: 4),

                Expanded(

                  child: Text(

                    sup.address!.trim(),

                    style: GoogleFonts.plusJakartaSans(

                      fontSize: 12,

                      color: Colors.grey[600],

                    ),

                    maxLines: 1,

                    overflow: TextOverflow.ellipsis,

                  ),

                ),

              ],

            ),

          ],



          if (sup.notes != null && sup.notes!.trim().isNotEmpty) ...[

            const SizedBox(height: 4),

            Row(

              children: [

                const Icon(Icons.notes_rounded, size: 14, color: Colors.grey),

                const SizedBox(width: 4),

                Expanded(

                  child: Text(

                    sup.notes!.trim(),

                    style: GoogleFonts.plusJakartaSans(

                      fontSize: 11.5,

                      color: Colors.grey[500],

                      fontStyle: FontStyle.italic,

                    ),

                    maxLines: 1,

                    overflow: TextOverflow.ellipsis,

                  ),

                ),

              ],

            ),

          ],



          const SizedBox(height: 12),

          const Divider(height: 1),

          const SizedBox(height: 10),



          // Linked products preview

          Row(

            mainAxisAlignment: MainAxisAlignment.spaceBetween,

            children: [

              Text(

                "Produk & Stok Biasa ($linkedProductCount)",

                style: GoogleFonts.plusJakartaSans(

                  fontWeight: FontWeight.w600,

                  fontSize: 12,

                  color: isDark ? Colors.white70 : Colors.black87,

                ),

              ),

              InkWell(

                onTap: () => _openSupplierFormDialog(supplier: sup),

                child: Text(

                  "+ Atur Produk",

                  style: GoogleFonts.plusJakartaSans(

                    fontWeight: FontWeight.w700,

                    fontSize: 11.5,

                    color: primaryGreen,

                  ),

                ),

              ),

            ],

          ),

          const SizedBox(height: 8),



          if (linkedProductCount == 0) ...[

            Container(

              width: double.infinity,

              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),

              decoration: BoxDecoration(

                color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF8FAFC),

                borderRadius: BorderRadius.circular(8),

              ),

              child: Text(

                "Belum ada produk terhubung. Tekan 'Atur Produk' untuk menghubungkan barang dan stok biasanya.",

                style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: Colors.grey),

              ),

            ),

          ] else ...[

            Wrap(

              spacing: 6,

              runSpacing: 6,

              children: sup.productUsualStock.entries.take(4).map((entry) {

                final prod = _allProducts.cast<Product?>().firstWhere(

                  (p) => p?.id == entry.key,

                  orElse: () => null,

                );

                final prodName = prod?.name ?? "Produk #${entry.key.substring(0, 4)}";

                final usualStock = entry.value;



                return Container(

                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),

                  decoration: BoxDecoration(

                    color: primaryGreen.withValues(alpha: 0.08),

                    borderRadius: BorderRadius.circular(8),

                    border: Border.all(color: primaryGreen.withValues(alpha: 0.2)),

                  ),

                  child: Row(

                    mainAxisSize: MainAxisSize.min,

                    children: [

                      Text(

                        prodName,

                        style: GoogleFonts.plusJakartaSans(

                          fontSize: 11.5,

                          fontWeight: FontWeight.w600,

                          color: isDark ? Colors.white : Colors.black87,

                        ),

                      ),

                      const SizedBox(width: 4),

                      Container(

                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),

                        decoration: BoxDecoration(

                          color: primaryGreen,

                          borderRadius: BorderRadius.circular(6),

                        ),

                        child: Text(

                          "$usualStock pcs",

                          style: GoogleFonts.plusJakartaSans(

                            fontSize: 10,

                            fontWeight: FontWeight.w700,

                            color: Colors.white,

                          ),

                        ),

                      ),

                    ],

                  ),

                );

              }).toList(),

            ),

            if (linkedProductCount > 4) ...[

              const SizedBox(height: 4),

              Text(

                "+ ${linkedProductCount - 4} produk lainnya...",

                style: GoogleFonts.plusJakartaSans(

                  fontSize: 11,

                  color: Colors.grey[500],

                  fontWeight: FontWeight.w500,

                ),

              ),

            ],

          ],



          const SizedBox(height: 12),



          // Status Tagihan Pasokan Berjalan

          Container(

            width: double.infinity,

            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),

            decoration: BoxDecoration(

              color: bill > 0

                  ? (isDark ? const Color(0xFF332512) : const Color(0xFFFFFBEB))

                  : (isDark ? const Color(0xFF132A1C) : const Color(0xFFF0FDF4)),

              borderRadius: BorderRadius.circular(12),

              border: Border.all(

                color: bill > 0

                    ? (isDark ? Colors.amber[800]!.withValues(alpha: 0.5) : const Color(0xFFFDE68A))

                    : (isDark ? primaryGreen.withValues(alpha: 0.3) : const Color(0xFFBBF7D0)),

              ),

            ),

            child: Row(

              children: [

                Container(

                  padding: const EdgeInsets.all(6),

                  decoration: BoxDecoration(

                    color: bill > 0

                        ? Colors.amber.withValues(alpha: 0.15)

                        : primaryGreen.withValues(alpha: 0.15),

                    shape: BoxShape.circle,

                  ),

                  child: Icon(

                    bill > 0 ? Icons.pending_actions_rounded : Icons.check_circle_rounded,

                    size: 18,

                    color: bill > 0 ? (isDark ? Colors.amber[300] : const Color(0xFFD97706)) : primaryGreen,

                  ),

                ),

                const SizedBox(width: 10),

                Expanded(

                  child: Column(

                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [

                      Text(

                        bill > 0 ? "Tagihan Belum Lunas:" : "Status Pasokan:",

                        style: GoogleFonts.plusJakartaSans(

                          fontSize: 11,

                          fontWeight: FontWeight.w600,

                          color: bill > 0

                              ? (isDark ? Colors.amber[200] : const Color(0xFF92400E))

                              : (isDark ? Colors.green[200] : const Color(0xFF166534)),

                        ),

                      ),

                      Text(

                        bill > 0 ? _currencyFormat.format(bill) : "LUNAS (Rp 0)",

                        style: GoogleFonts.plusJakartaSans(

                          fontSize: 13.5,

                          fontWeight: FontWeight.w800,

                          color: bill > 0

                              ? (isDark ? Colors.amber[400] : const Color(0xFFB45309))

                              : primaryGreen,

                        ),

                      ),

                    ],

                  ),

                ),

                if (bill > 0)

                  ElevatedButton(

                    onPressed: () => _openSettleSupplierSheet(sup, bill),

                    style: ElevatedButton.styleFrom(

                      backgroundColor: const Color(0xFFD97706),

                      foregroundColor: Colors.white,

                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),

                      minimumSize: Size.zero,

                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,

                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),

                      elevation: 0,

                    ),

                    child: Text(

                      "Lunasi",

                      style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),

                    ),

                  )

                else

                  TextButton.icon(

                    onPressed: () => _openSettlementHistorySheet(sup),

                    icon: const Icon(Icons.history_rounded, size: 14, color: primaryGreen),

                    label: Text(

                      "Riwayat",

                      style: GoogleFonts.plusJakartaSans(

                        fontSize: 11.5,

                        fontWeight: FontWeight.w700,

                        color: primaryGreen,

                      ),

                    ),

                    style: TextButton.styleFrom(

                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),

                      minimumSize: Size.zero,

                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,

                    ),

                  ),

              ],

            ),

          ),



          const SizedBox(height: 12),



          // Action Buttons: Buku Riwayat (PB/BH) + Bayar Hutang (Ala Niaga)

          Row(

            children: [

              Expanded(

                child: OutlinedButton.icon(

                  onPressed: () => _openSupplierLedger(sup),

                  icon: const Icon(Icons.receipt_long_rounded, size: 16),

                  label: Text(

                    "Buku Riwayat (PB/BH)",

                    style: GoogleFonts.plusJakartaSans(

                      fontWeight: FontWeight.w700,

                      fontSize: 12,

                    ),

                  ),

                  style: OutlinedButton.styleFrom(

                    foregroundColor: const Color(0xFF0284C7),

                    side: const BorderSide(color: Color(0xFF0284C7), width: 1.2),

                    padding: const EdgeInsets.symmetric(vertical: 10),

                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),

                  ),

                ),

              ),

              const SizedBox(width: 8),

              Expanded(

                child: ElevatedButton.icon(

                  onPressed: () => _openSupplierLedger(sup),

                  icon: const Icon(Icons.payment_rounded, size: 16, color: Colors.white),

                  label: Text(

                    "Bayar Hutang",

                    style: GoogleFonts.plusJakartaSans(

                      fontWeight: FontWeight.w700,

                      fontSize: 12.5,

                      color: Colors.white,

                    ),

                  ),

                  style: ElevatedButton.styleFrom(

                    backgroundColor: const Color(0xFFF59E0B),

                    padding: const EdgeInsets.symmetric(vertical: 10),

                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),

                    elevation: 0,

                  ),

                ),

              ),

            ],

          ),

        ],

      ),

    ),

  );

}



  // --- SETTLE / PELUNASAN SUPPLIER SHEET ---

  Future<void> _openSettleSupplierSheet(Supplier supplier, double currentBill) async {

    final admin = Provider.of<AdminController>(context, listen: false);

    final storeId = admin.storeId ?? '';

    final breakdown = await _supplierService.getSupplierBillBreakdown(storeId, supplier);



    // Initial mode: if sales exist, default to 'sold'; otherwise if usual stock exists, default to 'usual'

    String calcMode = (breakdown.totalSoldCost > 0 || supplier.unpaidBalance > 0)

        ? 'sold'

        : (breakdown.totalUsualCost > 0 ? 'usual' : 'sold');



    final Map<String, int> activeQtys = {};

    void syncQtysForMode(String mode) {

      activeQtys.clear();

      for (final item in breakdown.items) {

        activeQtys[item.productId] = mode == 'sold' ? item.quantitySold : item.usualStock;

      }

    }

    syncQtysForMode(calcMode);



    double computeTotal() {

      double sum = supplier.unpaidBalance;

      for (final item in breakdown.items) {

        final q = activeQtys[item.productId] ?? 0;

        sum += q * item.unitPrice;

      }

      return sum;

    }



    final initialTotal = computeTotal();

    final payCtrl = TextEditingController(

      text: initialTotal > 0

          ? initialTotal.toStringAsFixed(0)

          : (currentBill > 0 ? currentBill.toStringAsFixed(0) : ''),

    );

    final notesCtrl = TextEditingController();

    String paymentMethod = 'Kas Toko (Tunai)';

    bool isSubmitting = false;



    if (!mounted) return;



    await showModalBottomSheet(

      context: context,

      isScrollControlled: true,

      backgroundColor: Colors.transparent,

      builder: (ctx) {

        final isDark = Theme.of(ctx).brightness == Brightness.dark;

        return StatefulBuilder(

          builder: (context, setSheetState) {

            final currentCalculated = computeTotal();

            final enteredVal = double.tryParse(payCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0.0;

            final displayPay = enteredVal > 0 ? enteredVal : currentCalculated;



            return Padding(

              padding: EdgeInsets.only(

                bottom: MediaQuery.of(ctx).viewInsets.bottom,

              ),

              child: SafeArea(

                child: Container(

                  constraints: BoxConstraints(

                    maxHeight: MediaQuery.of(ctx).size.height * 0.90,

                  ),

                  decoration: BoxDecoration(

                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,

                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),

                  ),

                  child: Column(

                    mainAxisSize: MainAxisSize.min,

                    children: [

                      // Header

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

                                    color: primaryGreen.withValues(alpha: 0.12),

                                    shape: BoxShape.circle,

                                  ),

                                  child: const Icon(

                                    Icons.payments_rounded,

                                    color: primaryGreen,

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



                      // Content

                      Flexible(

                        child: SingleChildScrollView(

                          padding: const EdgeInsets.all(20),

                          child: Column(

                            crossAxisAlignment: CrossAxisAlignment.start,

                            children: [

                              // Mode Switcher (Konsinyasi vs Pasokan Masuk)

                              if (breakdown.items.isNotEmpty) ...[

                                Container(

                                  margin: const EdgeInsets.only(bottom: 14),

                                  padding: const EdgeInsets.all(4),

                                  decoration: BoxDecoration(

                                    color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF1F5F9),

                                    borderRadius: BorderRadius.circular(12),

                                  ),

                                  child: Row(

                                    children: [

                                      Expanded(

                                        child: InkWell(

                                          onTap: () {

                                            setSheetState(() {

                                              calcMode = 'sold';

                                              syncQtysForMode('sold');

                                              final newTot = computeTotal();

                                              payCtrl.text = newTot > 0 ? newTot.toStringAsFixed(0) : '';

                                            });

                                          },

                                          borderRadius: BorderRadius.circular(10),

                                          child: Container(

                                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),

                                            decoration: BoxDecoration(

                                              color: calcMode == 'sold' ? primaryGreen : Colors.transparent,

                                              borderRadius: BorderRadius.circular(10),

                                            ),

                                            child: Row(

                                              mainAxisAlignment: MainAxisAlignment.center,

                                              children: [

                                                Icon(

                                                  Icons.shopping_bag_outlined,

                                                  size: 15,

                                                  color: calcMode == 'sold' ? Colors.white : (isDark ? Colors.grey[400] : Colors.grey[700]),

                                                ),

                                                const SizedBox(width: 5),

                                                Flexible(

                                                  child: Text(

                                                    "Terjual (${_currencyFormat.format(breakdown.grandTotalSold)})",

                                                    style: GoogleFonts.plusJakartaSans(

                                                      fontSize: 11.5,

                                                      fontWeight: calcMode == 'sold' ? FontWeight.w700 : FontWeight.w500,

                                                      color: calcMode == 'sold' ? Colors.white : (isDark ? Colors.grey[400] : Colors.grey[700]),

                                                    ),

                                                    overflow: TextOverflow.ellipsis,

                                                  ),

                                                ),

                                              ],

                                            ),

                                          ),

                                        ),

                                      ),

                                      Expanded(

                                        child: InkWell(

                                          onTap: () {

                                            setSheetState(() {

                                              calcMode = 'usual';

                                              syncQtysForMode('usual');

                                              final newTot = computeTotal();

                                              payCtrl.text = newTot > 0 ? newTot.toStringAsFixed(0) : '';

                                            });

                                          },

                                          borderRadius: BorderRadius.circular(10),

                                          child: Container(

                                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),

                                            decoration: BoxDecoration(

                                              color: calcMode == 'usual' ? primaryGreen : Colors.transparent,

                                              borderRadius: BorderRadius.circular(10),

                                            ),

                                            child: Row(

                                              mainAxisAlignment: MainAxisAlignment.center,

                                              children: [

                                                Icon(

                                                  Icons.inventory_2_outlined,

                                                  size: 15,

                                                  color: calcMode == 'usual' ? Colors.white : (isDark ? Colors.grey[400] : Colors.grey[700]),

                                                ),

                                                const SizedBox(width: 5),

                                                Flexible(

                                                  child: Text(

                                                    "Pasokan (${_currencyFormat.format(breakdown.grandTotalUsual)})",

                                                    style: GoogleFonts.plusJakartaSans(

                                                      fontSize: 11.5,

                                                      fontWeight: calcMode == 'usual' ? FontWeight.w700 : FontWeight.w500,

                                                      color: calcMode == 'usual' ? Colors.white : (isDark ? Colors.grey[400] : Colors.grey[700]),

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

                                  ),

                                ),

                              ],



                              // Outstanding summary card

                              Container(

                                width: double.infinity,

                                padding: const EdgeInsets.all(14),

                                decoration: BoxDecoration(

                                  color: currentCalculated > 0

                                      ? (isDark ? const Color(0xFF2E2413) : const Color(0xFFFFFBEB))

                                      : (isDark ? const Color(0xFF132A1C) : const Color(0xFFF0FDF4)),

                                  borderRadius: BorderRadius.circular(14),

                                  border: Border.all(

                                    color: currentCalculated > 0

                                        ? (isDark ? Colors.amber[800]!.withValues(alpha: 0.5) : const Color(0xFFFDE68A))

                                        : (isDark ? primaryGreen.withValues(alpha: 0.3) : const Color(0xFFBBF7D0)),

                                  ),

                                ),

                                child: Column(

                                  crossAxisAlignment: CrossAxisAlignment.start,

                                  children: [

                                    Row(

                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,

                                      children: [

                                        Text(

                                          calcMode == 'sold'

                                              ? "Kalkulasi Tagihan (Barang Terjual)"

                                              : "Kalkulasi Tagihan (Pasokan Masuk)",

                                          style: GoogleFonts.plusJakartaSans(

                                            fontSize: 12,

                                            fontWeight: FontWeight.w600,

                                            color: isDark ? Colors.grey[300] : Colors.grey[700],

                                          ),

                                        ),

                                        Container(

                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),

                                          decoration: BoxDecoration(

                                            color: currentCalculated > 0 ? Colors.amber : primaryGreen,

                                            borderRadius: BorderRadius.circular(6),

                                          ),

                                          child: Text(

                                            currentCalculated > 0 ? "Siap Bayar" : "Lunas (Rp 0)",

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

                                      _currencyFormat.format(currentCalculated),

                                      style: GoogleFonts.plusJakartaSans(

                                        fontSize: 22,

                                        fontWeight: FontWeight.w800,

                                        color: currentCalculated > 0

                                            ? (isDark ? Colors.amber[300] : const Color(0xFFB45309))

                                            : primaryGreen,

                                      ),

                                    ),

                                    const SizedBox(height: 6),

                                    Text(

                                      calcMode == 'sold'

                                          ? "Dihitung otomatis dari produk titipan yang laku di kasir sejak pelunasan terakhir${supplier.unpaidBalance > 0 ? ' + saldo sisa sebelumnya' : ''}. Langsung siap dibayar."

                                          : "Dihitung otomatis dari stok pasokan supplier (${supplier.name}) × harga beli satuan${supplier.unpaidBalance > 0 ? ' + saldo sisa sebelumnya' : ''}.",

                                      style: GoogleFonts.plusJakartaSans(

                                        fontSize: 11,

                                        color: isDark ? Colors.grey[400] : Colors.grey[600],

                                      ),

                                    ),

                                  ],

                                ),

                              ),



                              const SizedBox(height: 16),



                              // Itemized Breakdown Section

                              Container(

                                decoration: BoxDecoration(

                                  color: isDark ? const Color(0xFF252525) : const Color(0xFFF8FAFC),

                                  borderRadius: BorderRadius.circular(14),

                                  border: Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!),

                                ),

                                child: Column(

                                  crossAxisAlignment: CrossAxisAlignment.start,

                                  children: [

                                    Padding(

                                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),

                                      child: Row(

                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,

                                        children: [

                                          Row(

                                            children: [

                                              const Icon(Icons.receipt_long_rounded, size: 16, color: primaryGreen),

                                              const SizedBox(width: 6),

                                              Text(

                                                "Rincian Produk (${breakdown.items.length})",

                                                style: GoogleFonts.plusJakartaSans(

                                                  fontSize: 12.5,

                                                  fontWeight: FontWeight.w700,

                                                ),

                                              ),

                                            ],

                                          ),

                                          Text(

                                            "Harga Beli × Qty",

                                            style: GoogleFonts.plusJakartaSans(

                                              fontSize: 11,

                                              color: Colors.grey,

                                              fontWeight: FontWeight.w500,

                                            ),

                                          ),

                                        ],

                                      ),

                                    ),

                                    const Divider(height: 1),

                                    if (breakdown.items.isEmpty)

                                      Padding(

                                        padding: const EdgeInsets.all(14),

                                        child: Text(

                                          "Belum ada produk yang ditautkan ke ${supplier.name}.",

                                          style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey),

                                        ),

                                      )

                                    else

                                      ListView.separated(

                                        shrinkWrap: true,

                                        physics: const NeverScrollableScrollPhysics(),

                                        itemCount: breakdown.items.length,

                                        separatorBuilder: (_, __) => Divider(height: 1, color: isDark ? Colors.white10 : Colors.grey[200]),

                                        itemBuilder: (context, idx) {

                                          final item = breakdown.items[idx];

                                          final qty = activeQtys[item.productId] ?? 0;

                                          final subtotal = qty * item.unitPrice;



                                          return Padding(

                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),

                                            child: Row(

                                              children: [

                                                Expanded(

                                                  child: Column(

                                                    crossAxisAlignment: CrossAxisAlignment.start,

                                                    children: [

                                                      Text(

                                                        item.productName,

                                                        style: GoogleFonts.plusJakartaSans(

                                                          fontSize: 13,

                                                          fontWeight: FontWeight.w700,

                                                        ),

                                                        maxLines: 1,

                                                        overflow: TextOverflow.ellipsis,

                                                      ),

                                                      const SizedBox(height: 2),

                                                      Text(

                                                        "@ ${_currencyFormat.format(item.unitPrice)} / unit",

                                                        style: GoogleFonts.plusJakartaSans(

                                                          fontSize: 11,

                                                          color: Colors.grey[600],

                                                        ),

                                                      ),

                                                    ],

                                                  ),

                                                ),

                                                // Quantity Adjuster

                                                Container(

                                                  decoration: BoxDecoration(

                                                    color: isDark ? Colors.black26 : Colors.white,

                                                    borderRadius: BorderRadius.circular(8),

                                                    border: Border.all(color: Colors.grey.withValues(alpha: 0.25)),

                                                  ),

                                                  child: Row(

                                                    mainAxisSize: MainAxisSize.min,

                                                    children: [

                                                      InkWell(

                                                        onTap: () {

                                                          if (qty > 0) {

                                                            setSheetState(() {

                                                              activeQtys[item.productId] = qty - 1;

                                                              final newTot = computeTotal();

                                                              payCtrl.text = newTot > 0 ? newTot.toStringAsFixed(0) : '';

                                                            });

                                                          }

                                                        },

                                                        child: const Padding(

                                                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),

                                                          child: Icon(Icons.remove, size: 14),

                                                        ),

                                                      ),

                                                      Padding(

                                                        padding: const EdgeInsets.symmetric(horizontal: 6),

                                                        child: Text(

                                                          "$qty",

                                                          style: GoogleFonts.plusJakartaSans(

                                                            fontWeight: FontWeight.w700,

                                                            fontSize: 12.5,

                                                            color: qty > 0 ? primaryGreen : Colors.grey,

                                                          ),

                                                        ),

                                                      ),

                                                      InkWell(

                                                        onTap: () {

                                                          setSheetState(() {

                                                            activeQtys[item.productId] = qty + 1;

                                                            final newTot = computeTotal();

                                                            payCtrl.text = newTot > 0 ? newTot.toStringAsFixed(0) : '';

                                                          });

                                                        },

                                                        child: const Padding(

                                                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),

                                                          child: Icon(Icons.add, size: 14),

                                                        ),

                                                      ),

                                                    ],

                                                  ),

                                                ),

                                                const SizedBox(width: 10),

                                                // Subtotal

                                                SizedBox(

                                                  width: 84,

                                                  child: Text(

                                                    _currencyFormat.format(subtotal),

                                                    textAlign: TextAlign.end,

                                                    style: GoogleFonts.plusJakartaSans(

                                                      fontSize: 12.5,

                                                      fontWeight: FontWeight.w700,

                                                      color: qty > 0 ? (isDark ? Colors.white : Colors.black87) : Colors.grey,

                                                    ),

                                                  ),

                                                ),

                                              ],

                                            ),

                                          );

                                        },

                                      ),

                                    if (supplier.unpaidBalance > 0) ...[

                                      const Divider(height: 1),

                                      Padding(

                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),

                                        child: Row(

                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,

                                          children: [

                                            Text(

                                              "Saldo Belum Lunas Sebelumnya",

                                              style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: Colors.orange[700], fontWeight: FontWeight.w600),

                                            ),

                                            Text(

                                              "+ ${_currencyFormat.format(supplier.unpaidBalance)}",

                                              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.orange[700], fontWeight: FontWeight.w700),

                                            ),

                                          ],

                                        ),

                                      ),

                                    ],

                                    const Divider(height: 1),

                                    Padding(

                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),

                                      child: Row(

                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,

                                        children: [

                                          Text(

                                            "Total Kalkulasi Tagihan",

                                            style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700),

                                          ),

                                          Text(

                                            _currencyFormat.format(currentCalculated),

                                            style: GoogleFonts.plusJakartaSans(

                                              fontSize: 14,

                                              fontWeight: FontWeight.w800,

                                              color: primaryGreen,

                                            ),

                                          ),

                                        ],

                                      ),

                                    ),

                                  ],

                                ),

                              ),



                              const SizedBox(height: 18),



                              // Nominal Pelunasan

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

                                  if (currentCalculated > 0)

                                    InkWell(

                                      onTap: () {

                                        setSheetState(() {

                                          payCtrl.text = currentCalculated.toStringAsFixed(0);

                                        });

                                      },

                                      child: Text(

                                        "Lunas Penuh (${_currencyFormat.format(currentCalculated)})",

                                        style: GoogleFonts.plusJakartaSans(

                                          fontSize: 12,

                                          fontWeight: FontWeight.w700,

                                          color: primaryGreen,

                                        ),

                                      ),

                                    ),

                                ],

                              ),

                              const SizedBox(height: 8),

                              TextField(

                                controller: payCtrl,

                                keyboardType: TextInputType.number,

                                onChanged: (val) {

                                  setSheetState(() {});

                                },

                                style: GoogleFonts.plusJakartaSans(

                                  fontSize: 16,

                                  fontWeight: FontWeight.w700,

                                ),

                                decoration: InputDecoration(

                                  prefixText: "Rp ",

                                  prefixStyle: GoogleFonts.plusJakartaSans(

                                    fontSize: 16,

                                    fontWeight: FontWeight.w700,

                                    color: primaryGreen,

                                  ),

                                  hintText: currentCalculated > 0 ? currentCalculated.toStringAsFixed(0) : "0",

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

                                    borderSide: const BorderSide(color: primaryGreen, width: 2),

                                  ),

                                ),

                              ),



                              const SizedBox(height: 16),



                              // Metode Pembayaran

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

                                    selectedColor: primaryGreen,

                                    backgroundColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF1F5F9),

                                    onSelected: (val) {

                                      if (val) setSheetState(() => paymentMethod = method);

                                    },

                                  );

                                }).toList(),

                              ),



                              const SizedBox(height: 16),



                              // Catatan Pelunasan

                              Text(

                                "Catatan / No. Bukti Transfer (Opsional)",

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

                                  hintText: "Contoh: Transfer via BCA ref #89283",

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



                      // Submit Button

                      Padding(

                        padding: const EdgeInsets.all(16),

                        child: SizedBox(

                          width: double.infinity,

                          height: 48,

                          child: ElevatedButton.icon(

                            onPressed: isSubmitting

                                ? null

                                : () async {

                                    final val = double.tryParse(payCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? (currentCalculated > 0 ? currentCalculated : 0.0);

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

                                    final messenger = ScaffoldMessenger.of(context);

                                    try {

                                      final effectiveBill = currentCalculated > 0 ? currentCalculated : currentBill;

                                      final remaining = await _supplierService.settleSupplierPayment(

                                        storeId: storeId,

                                        supplier: supplier,

                                        amount: val,

                                        paymentMethod: paymentMethod,

                                        totalBillBeforePayment: effectiveBill,

                                        notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),

                                      );



                                      if (ctx.mounted) Navigator.pop(ctx);

                                      await _fetchData();



                                      final statusMsg = remaining > 0

                                          ? "Pembayaran sebagian ${_currencyFormat.format(val)} berhasil! Sisa tagihan ${_currencyFormat.format(remaining)} dicatat untuk siklus berikutnya."

                                          : "Pelunasan ${_currencyFormat.format(val)} ke ${supplier.name} berhasil! Tagihan lunas (Rp 0).";



                                      messenger.showSnackBar(

                                        SnackBar(

                                          content: Text(

                                            statusMsg,

                                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),

                                          ),

                                          backgroundColor: primaryGreen,

                                          behavior: SnackBarBehavior.floating,

                                          action: SnackBarAction(

                                            label: "Kirim WA",

                                            textColor: Colors.yellowAccent,

                                            onPressed: () {

                                              SupplierService.shareSettlementToWhatsApp(

                                                phone: supplier.phone,

                                                supplierName: supplier.name,

                                                storeName: admin.storeName ?? "Kakilima Pos",

                                                amountPaid: val,

                                                remainingBalance: remaining,

                                                paymentMethod: paymentMethod,

                                                settledAt: DateTime.now(),

                                                notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),

                                              );

                                            },

                                          ),

                                        ),

                                      );

                                    } catch (e) {

                                      debugPrint("Error settling payment: $e");

                                      setSheetState(() => isSubmitting = false);

                                      messenger.showSnackBar(

                                        SnackBar(content: Text("Gagal memproses pelunasan: $e")),

                                      );

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

                              isSubmitting

                                  ? "Memproses Pelunasan..."

                                  : "Konfirmasi Pelunasan ${_currencyFormat.format(displayPay)}",

                              style: GoogleFonts.plusJakartaSans(

                                fontWeight: FontWeight.w700,

                                fontSize: 13.5,

                                color: Colors.white,

                              ),

                            ),

                            style: ElevatedButton.styleFrom(

                              backgroundColor: primaryGreen,

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



  // --- CATAT RETUR BARANG TITIPAN / SUPPLIER ---

  Future<void> _openReturnProductSheet(Supplier supplier) async {

    final supProdIds = {...supplier.productUsualStock.keys, ...supplier.productPrices.keys};

    final linkedProducts = _allProducts.where((p) => supProdIds.contains(p.id)).toList();



    if (linkedProducts.isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(

        const SnackBar(

          content: Text("Belum ada produk yang terhubung dengan supplier ini."),

          backgroundColor: Colors.orange,

        ),

      );

      return;

    }



    String? selectedProdId = linkedProducts.first.id;

    final qtyCtrl = TextEditingController(text: '1');

    final reasonCtrl = TextEditingController(text: 'Sisa dagangan sore / tidak laku');

    bool isSubmitting = false;



    await showModalBottomSheet(

      context: context,

      isScrollControlled: true,

      backgroundColor: Colors.transparent,

      builder: (ctx) {

        final isDark = Theme.of(ctx).brightness == Brightness.dark;

        return StatefulBuilder(

          builder: (context, setSheetState) {

            final activeProduct = linkedProducts.firstWhere(

              (p) => p.id == selectedProdId,

              orElse: () => linkedProducts.first,

            );

            final currentStock = (activeProduct.stockQuantity ?? 0).toInt();



            return Padding(

              padding: EdgeInsets.only(

                bottom: MediaQuery.of(ctx).viewInsets.bottom,

              ),

              child: SafeArea(

                child: Container(

                  constraints: BoxConstraints(

                    maxHeight: MediaQuery.of(ctx).size.height * 0.85,

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

                                    color: Colors.orange.withValues(alpha: 0.12),

                                    shape: BoxShape.circle,

                                  ),

                                  child: const Icon(

                                    Icons.assignment_return_outlined,

                                    color: Colors.orange,

                                    size: 20,

                                  ),

                                ),

                                const SizedBox(width: 10),

                                Column(

                                  crossAxisAlignment: CrossAxisAlignment.start,

                                  children: [

                                    Text(

                                      "Catat Retur Barang Titipan",

                                      style: GoogleFonts.plusJakartaSans(

                                        fontSize: 16,

                                        fontWeight: FontWeight.w700,

                                      ),

                                    ),

                                    Text(

                                      "Kembalikan sisa produk ke ${supplier.name}",

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

                              Text(

                                "Pilih Produk yang Dikembalikan",

                                style: GoogleFonts.plusJakartaSans(

                                  fontSize: 13,

                                  fontWeight: FontWeight.w700,

                                ),

                              ),

                              const SizedBox(height: 8),

                              Container(

                                padding: const EdgeInsets.symmetric(horizontal: 14),

                                decoration: BoxDecoration(

                                  color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF8FAFC),

                                  borderRadius: BorderRadius.circular(12),

                                  border: Border.all(

                                    color: isDark ? Colors.white12 : Colors.grey[300]!,

                                  ),

                                ),

                                child: DropdownButtonHideUnderline(

                                  child: DropdownButton<String>(

                                    value: selectedProdId,

                                    isExpanded: true,

                                    dropdownColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,

                                    items: linkedProducts.map((p) {

                                      return DropdownMenuItem<String>(

                                        value: p.id,

                                        child: Text(

                                          "${p.name ?? 'Produk'} (Stok di gerobak: ${(p.stockQuantity ?? 0).toInt()})",

                                          style: GoogleFonts.plusJakartaSans(

                                            fontSize: 13,

                                            fontWeight: FontWeight.w600,

                                          ),

                                        ),

                                      );

                                    }).toList(),

                                    onChanged: (val) {

                                      if (val != null) {

                                        setSheetState(() => selectedProdId = val);

                                      }

                                    },

                                  ),

                                ),

                              ),

                              const SizedBox(height: 16),

                              Row(

                                mainAxisAlignment: MainAxisAlignment.spaceBetween,

                                children: [

                                  Text(

                                    "Jumlah Retur (pcs) *",

                                    style: GoogleFonts.plusJakartaSans(

                                      fontSize: 13,

                                      fontWeight: FontWeight.w700,

                                    ),

                                  ),

                                  if (currentStock > 0)

                                    InkWell(

                                      onTap: () {

                                        setSheetState(() => qtyCtrl.text = currentStock.toString());

                                      },

                                      child: Text(

                                        "Semua Sisa ($currentStock pcs)",

                                        style: GoogleFonts.plusJakartaSans(

                                          fontSize: 12,

                                          fontWeight: FontWeight.w700,

                                          color: Colors.orange[800],

                                        ),

                                      ),

                                    ),

                                ],

                              ),

                              const SizedBox(height: 8),

                              TextField(

                                controller: qtyCtrl,

                                keyboardType: TextInputType.number,

                                style: GoogleFonts.plusJakartaSans(

                                  fontSize: 16,

                                  fontWeight: FontWeight.w700,

                                ),

                                decoration: InputDecoration(

                                  hintText: "Contoh: 5",

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

                                    borderSide: const BorderSide(color: Colors.orange, width: 2),

                                  ),

                                ),

                              ),

                              const SizedBox(height: 16),

                              Text(

                                "Alasan / Keterangan Retur",

                                style: GoogleFonts.plusJakartaSans(

                                  fontSize: 13,

                                  fontWeight: FontWeight.w700,

                                ),

                              ),

                              const SizedBox(height: 8),

                              TextField(

                                controller: reasonCtrl,

                                style: GoogleFonts.plusJakartaSans(fontSize: 13),

                                decoration: InputDecoration(

                                  hintText: "Contoh: Sisa dagangan sore hari / basi",

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

                              const SizedBox(height: 12),

                              Container(

                                width: double.infinity,

                                padding: const EdgeInsets.all(12),

                                decoration: BoxDecoration(

                                  color: isDark ? const Color(0xFF2E2413) : const Color(0xFFFFFBEB),

                                  borderRadius: BorderRadius.circular(10),

                                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),

                                ),

                                child: Text(

                                  "💡 Retur akan mengurangi stok produk di gerobak tanpa mencatat tagihan ke supplier karena barang dikembalikan.",

                                  style: GoogleFonts.openSans(

                                    fontSize: 11.5,

                                    color: isDark ? Colors.orange[200] : const Color(0xFFB45309),

                                  ),

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

                                    final returnQty = int.tryParse(qtyCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

                                    if (returnQty <= 0) {

                                      ScaffoldMessenger.of(context).showSnackBar(

                                        const SnackBar(

                                          content: Text("Masukkan jumlah retur yang valid (minimal 1)!"),

                                          backgroundColor: Colors.redAccent,

                                        ),

                                      );

                                      return;

                                    }



                                    setSheetState(() => isSubmitting = true);

                                    final messenger = ScaffoldMessenger.of(context);

                                    final db = Provider.of<AppDatabase>(context, listen: false);



                                    try {

                                      final currentProd = await (db.select(db.products)..where((p) => p.id.equals(selectedProdId!))).getSingleOrNull();

                                      if (currentProd != null) {

                                        final newStock = ((currentProd.stockQuantity ?? 0.0) - returnQty).clamp(0.0, 999999.0);

                                        await (db.update(db.products)..where((p) => p.id.equals(selectedProdId!))).write(

                                          ProductsCompanion(stockQuantity: drift.Value(newStock)),

                                        );

                                      }



                                      if (ctx.mounted) Navigator.pop(ctx);

                                      await _fetchData();



                                      final prodLabel = activeProduct.name ?? 'Produk';

                                      messenger.showSnackBar(

                                        SnackBar(

                                          content: Text(

                                            "Retur $returnQty pcs $prodLabel ke ${supplier.name} berhasil dicatat!",

                                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),

                                          ),

                                          backgroundColor: Colors.orange[800],

                                          behavior: SnackBarBehavior.floating,

                                          action: SnackBarAction(

                                            label: "Kirim WA",

                                            textColor: Colors.yellowAccent,

                                            onPressed: () {

                                              SupplierService.shareReturnToWhatsApp(

                                                phone: supplier.phone,

                                                supplierName: supplier.name,

                                                storeName: "KakiLima Pos",

                                                productName: prodLabel,

                                                returnQty: returnQty,

                                                reason: reasonCtrl.text.trim().isEmpty ? null : reasonCtrl.text.trim(),

                                              );

                                            },

                                          ),

                                        ),

                                      );

                                    } catch (e) {

                                      debugPrint("Error recording return: $e");

                                      setSheetState(() => isSubmitting = false);

                                      messenger.showSnackBar(

                                        SnackBar(content: Text("Gagal mencatat retur: $e")),

                                      );

                                    }

                                  },

                            icon: const Icon(Icons.assignment_return_rounded, color: Colors.white),

                            label: Text(

                              isSubmitting ? "Menyimpan..." : "Simpan Retur",

                              style: GoogleFonts.plusJakartaSans(

                                fontWeight: FontWeight.w700,

                                fontSize: 14,

                                color: Colors.white,

                              ),

                            ),

                            style: ElevatedButton.styleFrom(

                              backgroundColor: Colors.orange[800],

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



  // --- SETTLEMENT HISTORY SHEET (Bisa untuk 1 supplier atau Semua Supplier) ---

  Future<void> _openSettlementHistorySheet([Supplier? supplier]) async {

    final admin = Provider.of<AdminController>(context, listen: false);

    final storeId = admin.storeId ?? '';

    List<SupplierSettlement> history = await _supplierService.getSettlements(

      storeId,

      supplierId: supplier?.id,

    );



    if (!mounted) return;



    await showModalBottomSheet(

      context: context,

      isScrollControlled: true,

      backgroundColor: Colors.transparent,

      builder: (ctx) {

        final isDark = Theme.of(ctx).brightness == Brightness.dark;



        return StatefulBuilder(

          builder: (context, setSheetState) {

            final totalPaid = history.fold<double>(0.0, (sum, s) => sum + s.amount);

            final title = supplier != null

                ? "Riwayat Pembayaran Supplier"

                : "Riwayat Semua Pelunasan Supplier";

            final subtitle = supplier != null

                ? supplier.name

                : "Semua catatan bukti bayar & pelunasan pasokan";



            return SafeArea(

              child: Container(

                constraints: BoxConstraints(

                  maxHeight: MediaQuery.of(ctx).size.height * 0.85,

                ),

                decoration: BoxDecoration(

                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,

                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),

                ),

                child: Column(

                  mainAxisSize: MainAxisSize.min,

                  children: [

                    // Header

                    Padding(

                      padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),

                      child: Row(

                        mainAxisAlignment: MainAxisAlignment.spaceBetween,

                        children: [

                          Expanded(

                            child: Column(

                              crossAxisAlignment: CrossAxisAlignment.start,

                              children: [

                                Text(

                                  title,

                                  style: GoogleFonts.plusJakartaSans(

                                    fontSize: 16.5,

                                    fontWeight: FontWeight.w700,

                                  ),

                                ),

                                Text(

                                  subtitle,

                                  style: GoogleFonts.plusJakartaSans(

                                    fontSize: 12,

                                    color: Colors.grey[500],

                                  ),

                                ),

                              ],

                            ),

                          ),

                          if (history.isNotEmpty)

                            PopupMenuButton<String>(

                              icon: Container(

                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),

                                decoration: BoxDecoration(

                                  color: primaryGreen.withValues(alpha: 0.1),

                                  borderRadius: BorderRadius.circular(8),

                                  border: Border.all(color: primaryGreen.withValues(alpha: 0.3)),

                                ),

                                child: Row(

                                  mainAxisSize: MainAxisSize.min,

                                  children: [

                                    const Icon(Icons.file_download_outlined, size: 16, color: primaryGreen),

                                    const SizedBox(width: 4),

                                    Text(

                                      "Ekspor",

                                      style: GoogleFonts.plusJakartaSans(

                                        fontSize: 12,

                                        fontWeight: FontWeight.w700,

                                        color: primaryGreen,

                                      ),

                                    ),

                                  ],

                                ),

                              ),

                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),

                              onSelected: (format) => _exportSupplierSettlements(

                                supplier: supplier,

                                history: history,

                                format: format,

                              ),

                              itemBuilder: (c) => [

                                PopupMenuItem(

                                  value: 'pdf',

                                  child: Row(

                                    children: [

                                      const Icon(Icons.picture_as_pdf_outlined, color: Colors.redAccent, size: 18),

                                      const SizedBox(width: 8),

                                      Text("Ekspor ke PDF", style: GoogleFonts.plusJakartaSans(fontSize: 13)),

                                    ],

                                  ),

                                ),

                                PopupMenuItem(

                                  value: 'excel',

                                  child: Row(

                                    children: [

                                      const Icon(Icons.table_chart_outlined, color: primaryGreen, size: 18),

                                      const SizedBox(width: 8),

                                      Text("Ekspor ke Excel (.xlsx)", style: GoogleFonts.plusJakartaSans(fontSize: 13)),

                                    ],

                                  ),

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



                    // Total Summary

                    Container(

                      width: double.infinity,

                      margin: const EdgeInsets.all(16),

                      padding: const EdgeInsets.all(14),

                      decoration: BoxDecoration(

                        color: primaryGreen.withValues(alpha: 0.1),

                        borderRadius: BorderRadius.circular(12),

                        border: Border.all(color: primaryGreen.withValues(alpha: 0.25)),

                      ),

                      child: Row(

                        mainAxisAlignment: MainAxisAlignment.spaceBetween,

                        children: [

                          Column(

                            crossAxisAlignment: CrossAxisAlignment.start,

                            children: [

                              Text(

                                "Total Telah Dibayarkan",

                                style: GoogleFonts.plusJakartaSans(

                                  fontSize: 11.5,

                                  fontWeight: FontWeight.w600,

                                  color: isDark ? Colors.grey[300] : Colors.grey[700],

                                ),

                              ),

                              Text(

                                _currencyFormat.format(totalPaid),

                                style: GoogleFonts.plusJakartaSans(

                                  fontSize: 18,

                                  fontWeight: FontWeight.w800,

                                  color: primaryGreen,

                                ),

                              ),

                            ],

                          ),

                          Container(

                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),

                            decoration: BoxDecoration(

                              color: primaryGreen,

                              borderRadius: BorderRadius.circular(8),

                            ),

                            child: Text(

                              "${history.length}x Pelunasan",

                              style: GoogleFonts.plusJakartaSans(

                                fontSize: 11,

                                fontWeight: FontWeight.w700,

                                color: Colors.white,

                              ),

                            ),

                          ),

                        ],

                      ),

                    ),



                    // History List

                    Expanded(

                      child: history.isEmpty

                          ? Center(

                              child: Padding(

                                padding: const EdgeInsets.all(32),

                                child: Column(

                                  mainAxisAlignment: MainAxisAlignment.center,

                                  children: [

                                    const Icon(Icons.history_toggle_off_rounded, size: 48, color: Colors.grey),

                                    const SizedBox(height: 12),

                                    Text(

                                      "Belum ada riwayat pelunasan",

                                      style: GoogleFonts.plusJakartaSans(

                                        fontSize: 15,

                                        fontWeight: FontWeight.w700,

                                        color: isDark ? Colors.white70 : Colors.black87,

                                      ),

                                    ),

                                    const SizedBox(height: 4),

                                    Text(

                                      supplier != null

                                          ? "Semua pelunasan atau pembayaran ke ${supplier.name} akan tercatat di sini."

                                          : "Semua pelunasan pasokan supplier akan tersimpan rapi di sini.",

                                      textAlign: TextAlign.center,

                                      style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey),

                                    ),

                                  ],

                                ),

                              ),

                            )

                          : ListView.separated(

                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),

                              itemCount: history.length,

                              separatorBuilder: (_, __) => const SizedBox(height: 8),

                              itemBuilder: (context, idx) {

                                final item = history[idx];

                                final dateFormat = DateFormat('dd MMM yyyy, HH:mm', 'id');

                                final targetSup = supplier ?? _suppliers.firstWhere(

                                  (s) => s.id == item.supplierId,

                                  orElse: () => Supplier(

                                    id: item.supplierId,

                                    storeId: storeId,

                                    name: 'Supplier',

                                    createdAt: DateTime.now(),

                                  ),

                                );



                                return Container(

                                  padding: const EdgeInsets.all(12),

                                  decoration: BoxDecoration(

                                    color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF8FAFC),

                                    borderRadius: BorderRadius.circular(12),

                                    border: Border.all(

                                      color: isDark ? Colors.white10 : Colors.grey[200]!,

                                    ),

                                  ),

                                  child: Row(

                                    children: [

                                      Container(

                                        padding: const EdgeInsets.all(8),

                                        decoration: BoxDecoration(

                                          color: primaryGreen.withValues(alpha: 0.12),

                                          shape: BoxShape.circle,

                                        ),

                                        child: const Icon(

                                          Icons.check_circle_rounded,

                                          color: primaryGreen,

                                          size: 18,

                                        ),

                                      ),

                                      const SizedBox(width: 10),

                                      Expanded(

                                        child: Column(

                                          crossAxisAlignment: CrossAxisAlignment.start,

                                          children: [

                                            Row(

                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,

                                              children: [

                                                Expanded(

                                                  child: Text(

                                                    targetSup.name,

                                                    style: GoogleFonts.plusJakartaSans(

                                                      fontSize: 13,

                                                      fontWeight: FontWeight.w700,

                                                      color: isDark ? Colors.white : const Color(0xFF0F172A),

                                                    ),

                                                    maxLines: 1,

                                                    overflow: TextOverflow.ellipsis,

                                                  ),

                                                ),

                                                Text(

                                                  _currencyFormat.format(item.amount),

                                                  style: GoogleFonts.plusJakartaSans(

                                                    fontSize: 14,

                                                    fontWeight: FontWeight.w800,

                                                    color: primaryGreen,

                                                  ),

                                                ),

                                              ],

                                            ),

                                            const SizedBox(height: 2),

                                            Text(

                                              "${item.paymentMethod} • ${dateFormat.format(item.settledAt)}",

                                              style: GoogleFonts.plusJakartaSans(

                                                fontSize: 11,

                                                color: Colors.grey[500],

                                              ),

                                            ),

                                            if (item.notes != null && item.notes!.trim().isNotEmpty) ...[

                                              const SizedBox(height: 2),

                                              Text(

                                                item.notes!.trim(),

                                                style: GoogleFonts.plusJakartaSans(

                                                  fontSize: 11,

                                                  color: isDark ? Colors.grey[400] : Colors.grey[600],

                                                  fontStyle: FontStyle.italic,

                                                ),

                                              ),

                                            ],

                                          ],

                                        ),

                                      ),

                                      const SizedBox(width: 4),

                                      IconButton(

                                        icon: const Icon(Icons.chat_bubble_outline_rounded, size: 19, color: Color(0xFF25D366)),

                                        tooltip: "Kirim Bukti ke WhatsApp",

                                        onPressed: () {

                                          SupplierService.shareSettlementToWhatsApp(

                                            phone: targetSup.phone,

                                            supplierName: targetSup.name,

                                            storeName: "KakiLima Pos",

                                            amountPaid: item.amount,

                                            remainingBalance: 0,

                                            paymentMethod: item.paymentMethod,

                                            settledAt: item.settledAt,

                                            notes: item.notes,

                                          );

                                        },

                                      ),

                                      IconButton(

                                        icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.redAccent),

                                        tooltip: "Hapus Pelunasan Ini",

                                        onPressed: () async {

                                          final messenger = ScaffoldMessenger.of(context);

                                          final confirm = await showDialog<bool>(

                                            context: ctx,

                                            builder: (dCtx) => AlertDialog(

                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),

                                              title: Row(

                                                children: [

                                                  const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 24),

                                                  const SizedBox(width: 8),

                                                  Text(

                                                    "Hapus Pelunasan?",

                                                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16),

                                                  ),

                                                ],

                                              ),

                                              content: Text(

                                                "Hapus riwayat pelunasan sebesar ${_currencyFormat.format(item.amount)} kepada ${targetSup.name}? Pengeluaran di buku kas toko juga akan dibatalkan.",

                                                style: GoogleFonts.openSans(fontSize: 13),

                                              ),

                                              actions: [

                                                TextButton(

                                                  onPressed: () => Navigator.pop(dCtx, false),

                                                  child: Text("Batal", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),

                                                ),

                                                ElevatedButton(

                                                  onPressed: () => Navigator.pop(dCtx, true),

                                                  style: ElevatedButton.styleFrom(

                                                    backgroundColor: Colors.redAccent,

                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),

                                                  ),

                                                  child: Text(

                                                    "Hapus",

                                                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: Colors.white),

                                                  ),

                                                ),

                                              ],

                                            ),

                                          );



                                          if (confirm == true) {

                                            await _supplierService.deleteSettlement(storeId, item.id);

                                            final updatedList = await _supplierService.getSettlements(

                                              storeId,

                                              supplierId: supplier?.id,

                                            );

                                            setSheetState(() {

                                              history = updatedList;

                                            });

                                            await _fetchData();

                                            messenger.showSnackBar(

                                              SnackBar(

                                                content: Text(

                                                  "Riwayat pelunasan berhasil dihapus.",

                                                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),

                                                ),

                                                backgroundColor: primaryGreen,

                                                behavior: SnackBarBehavior.floating,

                                              ),

                                            );

                                          }

                                        },

                                      ),

                                    ],

                                  ),

                                );

                              },

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



  Future<void> _exportSupplierSettlements({

    Supplier? supplier,

    required List<SupplierSettlement> history,

    required String format,

  }) async {

    final messenger = ScaffoldMessenger.of(context);

    final targetLabel = supplier != null ? supplier.name : "Semua Supplier";

    messenger.showSnackBar(

      SnackBar(

        content: Row(

          children: [

            const SizedBox(

              width: 16,

              height: 16,

              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),

            ),

            const SizedBox(width: 12),

            Text("Mengekspor riwayat pelunasan ($targetLabel)..."),

          ],

        ),

        duration: const Duration(seconds: 2),

        backgroundColor: primaryGreen,

      ),

    );



    try {

      final exportService = ExportService();

      final data = history.map((s) {

        final sup = supplier ?? _suppliers.firstWhere(

          (x) => x.id == s.supplierId,

          orElse: () => Supplier(id: s.supplierId, storeId: s.storeId, name: 'Supplier', createdAt: DateTime.now()),

        );

        return {

          'date': DateFormat('dd/MM/yyyy HH:mm').format(s.settledAt),

          'supplierName': sup.name,

          'paymentMethod': s.paymentMethod,

          'notes': s.notes ?? '-',

          'amount': s.amount,

        };

      }).toList();



      final fmtTime = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());

      Uint8List bytes;

      String filename;

      String mimeType;



      final labelClean = supplier != null

          ? supplier.name.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')

          : "Semua_Supplier";



      if (format == 'pdf') {

        bytes = await exportService.generateSupplierSettlementsPdf(

          storeName: "KakiLima Pos",

          settlements: data,

          periodLabel: supplier != null ? "Supplier: ${supplier.name}" : "Semua Supplier",

        );

        filename = "Pelunasan_${labelClean}_$fmtTime.pdf";

        mimeType = "application/pdf";

      } else {

        bytes = await exportService.generateSupplierSettlementsExcel(

          storeName: "KakiLima Pos",

          settlements: data,

          periodLabel: supplier != null ? "Supplier: ${supplier.name}" : "Semua Supplier",

        );

        filename = "Pelunasan_${labelClean}_$fmtTime.xlsx";

        mimeType = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";

      }



      final savedPath = await FileManager().saveAndShareBytes(

        filename,

        bytes,

        mimeType: mimeType,

      );



      messenger.clearSnackBars();

      messenger.showSnackBar(

        SnackBar(

          content: Text(

            "Riwayat pelunasan $targetLabel berhasil disimpan di folder Download\n($filename)",

            style: GoogleFonts.openSans(fontSize: 13, color: Colors.white),

          ),

          backgroundColor: primaryGreen,

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

    } catch (e) {

      debugPrint("Export error: $e");

      messenger.showSnackBar(SnackBar(content: Text("Gagal mengekspor riwayat pelunasan: $e")));

    }

  }



  // --- ADD / EDIT SUPPLIER DIALOG ---

  Future<void> _openSupplierFormDialog({Supplier? supplier}) async {

    final nameCtrl = TextEditingController(text: supplier?.name ?? '');

    final phoneCtrl = TextEditingController(text: supplier?.phone ?? '');

    final addressCtrl = TextEditingController(text: supplier?.address ?? '');

    final notesCtrl = TextEditingController(text: supplier?.notes ?? '');



    // Map of productId -> usual restock qty & unit buy prices

    final Map<String, int> productStocks = Map.from(supplier?.productUsualStock ?? {});

    final Map<String, double> productPrices = Map.from(supplier?.productPrices ?? {});



    await showModalBottomSheet(

      context: context,

      isScrollControlled: true,

      backgroundColor: Colors.transparent,

      builder: (ctx) {

        final isDark = Theme.of(ctx).brightness == Brightness.dark;

        return StatefulBuilder(

          builder: (context, setSheetState) {

            final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;

            return Padding(

              padding: EdgeInsets.only(bottom: bottomInset),

              child: SafeArea(

                child: Container(

                  constraints: BoxConstraints(

                    maxHeight: MediaQuery.of(ctx).size.height * 0.9,

                  ),

                  decoration: BoxDecoration(

                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,

                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),

                  ),

                  child: Column(

                    mainAxisSize: MainAxisSize.min,

                    children: [

                      // Header

                      Padding(

                        padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),

                        child: Row(

                          mainAxisAlignment: MainAxisAlignment.spaceBetween,

                          children: [

                            Text(

                              supplier == null ? "Tambah Supplier Baru" : "Edit Data Supplier",

                              style: GoogleFonts.plusJakartaSans(

                                fontSize: 17,

                                fontWeight: FontWeight.w700,

                              ),

                            ),

                            IconButton(

                              icon: const Icon(Icons.close_rounded),

                              onPressed: () => Navigator.pop(ctx),

                            ),

                          ],

                        ),

                      ),

                      const Divider(height: 1),



                      // Form Fields Scrollable

                      Expanded(

                        child: SingleChildScrollView(

                          physics: const AlwaysScrollableScrollPhysics(),

                          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,

                          padding: const EdgeInsets.all(20),

                          child: Column(

                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [

                            // Nama Supplier

                            _buildFieldLabel("Nama Supplier *"),

                            _buildTextField(nameCtrl, "Contoh: CV Sumber Berkah", isDark),

                            const SizedBox(height: 14),



                            // No Telepon

                            _buildFieldLabel("No. Telepon / WhatsApp"),

                            _buildTextField(phoneCtrl, "Contoh: 08123456789", isDark, keyboardType: TextInputType.phone),

                            const SizedBox(height: 14),



                            // Alamat

                            _buildFieldLabel("Alamat Supplier"),

                            _buildTextField(addressCtrl, "Contoh: Jl. Industri No. 45, Jakarta", isDark),

                            const SizedBox(height: 14),



                            // Catatan

                            _buildFieldLabel("Catatan (Opsional)"),

                            _buildTextField(notesCtrl, "Contoh: Minimum order 10 karton, antar tiap Senin", isDark, maxLines: 2),

                            const SizedBox(height: 24),



                            // Section: Produk & Stok Biasa

                            Column(

                              crossAxisAlignment: CrossAxisAlignment.start,

                              children: [

                                Text(

                                  "Produk & Stok Biasa",

                                  style: GoogleFonts.plusJakartaSans(

                                    fontSize: 15,

                                    fontWeight: FontWeight.w700,

                                    color: isDark ? Colors.white : const Color(0xFF0F172A),

                                  ),

                                ),

                                const SizedBox(height: 3),

                                Text(

                                  "Berapa jumlah yang biasanya Anda restock dari supplier ini?",

                                  style: GoogleFonts.plusJakartaSans(

                                    fontSize: 12,

                                    color: isDark ? Colors.white60 : Colors.grey[600],

                                  ),

                                ),

                                const SizedBox(height: 12),

                                SizedBox(

                                  width: double.infinity,

                                  child: ElevatedButton.icon(

                                    onPressed: () async {

                                      final selectedProds = await _showPickProductsDialog(

                                        alreadySelectedIds: productStocks.keys.toSet(),

                                      );

                                      if (selectedProds != null && selectedProds.isNotEmpty) {

                                        setSheetState(() {

                                          for (final p in selectedProds) {

                                            if (!productStocks.containsKey(p.id)) {

                                              productStocks[p.id] = 20; // Default 20 pcs

                                            }

                                            if (!productPrices.containsKey(p.id)) {

                                              productPrices[p.id] = (p.buyPrice ?? p.basePrice ?? 0.0);

                                            }

                                          }

                                        });

                                      }

                                    },

                                    icon: const Icon(Icons.add_circle_outline_rounded, size: 18, color: Colors.white),

                                    label: Text(

                                      "+ Tambah / Hubungkan Produk",

                                      style: GoogleFonts.plusJakartaSans(

                                        fontSize: 13,

                                        fontWeight: FontWeight.w700,

                                        color: Colors.white,

                                      ),

                                    ),

                                    style: ElevatedButton.styleFrom(

                                      backgroundColor: primaryGreen,

                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),

                                      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 16),

                                      elevation: 0,

                                    ),

                                  ),

                                ),

                              ],

                            ),

                            const SizedBox(height: 12),



                            if (productStocks.isEmpty) ...[

                              Container(

                                width: double.infinity,

                                padding: const EdgeInsets.all(16),

                                decoration: BoxDecoration(

                                  color: isDark ? Colors.white10 : Colors.grey[100],

                                  borderRadius: BorderRadius.circular(12),

                                  border: Border.all(color: isDark ? Colors.white12 : Colors.grey[300]!),

                                ),

                                child: Center(

                                  child: Text(

                                    "Belum ada produk yang dihubungkan ke supplier ini.\nTekan '+ Produk' untuk menghubungkan produk.",

                                    textAlign: TextAlign.center,

                                    style: GoogleFonts.plusJakartaSans(

                                      fontSize: 12,

                                      color: Colors.grey,

                                    ),

                                  ),

                                ),

                              ),

                            ] else ...[

                              ListView.separated(

                                shrinkWrap: true,

                                physics: const NeverScrollableScrollPhysics(),

                                itemCount: productStocks.length,

                                separatorBuilder: (_, __) => const SizedBox(height: 8),

                                itemBuilder: (context, idx) {

                                  final prodId = productStocks.keys.elementAt(idx);

                                  final usualQty = productStocks[prodId] ?? 10;

                                  final prod = _allProducts.cast<Product?>().firstWhere(

                                    (p) => p?.id == prodId,

                                    orElse: () => null,

                                  );

                                  final prodName = prod?.name ?? "Produk #$prodId";

                                  final currentStock = prod?.stockQuantity ?? 0;

                                  final price = productPrices[prodId] ?? (prod?.buyPrice ?? prod?.basePrice ?? 0.0);

                                  final subtotal = usualQty * price;



                                  return Container(

                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),

                                    decoration: BoxDecoration(

                                      color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF8FAFC),

                                      borderRadius: BorderRadius.circular(12),

                                      border: Border.all(color: isDark ? Colors.white12 : Colors.grey[200]!),

                                    ),

                                    child: Column(

                                      crossAxisAlignment: CrossAxisAlignment.start,

                                      children: [

                                        Row(

                                          children: [

                                            Expanded(

                                              child: Column(

                                                crossAxisAlignment: CrossAxisAlignment.start,

                                                children: [

                                                  Text(

                                                    prodName,

                                                    style: GoogleFonts.plusJakartaSans(

                                                      fontWeight: FontWeight.w700,

                                                      fontSize: 13,

                                                    ),

                                                  ),

                                                  Text(

                                                    "Stok saat ini: ${currentStock.toStringAsFixed(currentStock % 1 == 0 ? 0 : 1)} pcs",

                                                    style: GoogleFonts.plusJakartaSans(

                                                      fontSize: 11,

                                                      color: Colors.grey,

                                                    ),

                                                  ),

                                                ],

                                              ),

                                            ),

                                            IconButton(

                                              icon: const Icon(Icons.close_rounded, size: 18, color: Colors.redAccent),

                                              onPressed: () {

                                                setSheetState(() {

                                                  productStocks.remove(prodId);

                                                  productPrices.remove(prodId);

                                                });

                                              },

                                            ),

                                          ],

                                        ),

                                        const SizedBox(height: 8),

                                        Row(

                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,

                                          children: [

                                            // Harga Pasok Input Button

                                            InkWell(

                                              onTap: () async {

                                                final newPrice = await _showInputPriceDialog(price);

                                                if (newPrice != null) {

                                                  setSheetState(() => productPrices[prodId] = newPrice);

                                                }

                                              },

                                              borderRadius: BorderRadius.circular(8),

                                              child: Container(

                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),

                                                decoration: BoxDecoration(

                                                  color: Colors.teal.withValues(alpha: 0.1),

                                                  borderRadius: BorderRadius.circular(8),

                                                  border: Border.all(color: Colors.teal.withValues(alpha: 0.3)),

                                                ),

                                                child: Row(

                                                  mainAxisSize: MainAxisSize.min,

                                                  children: [

                                                    const Icon(Icons.payments_outlined, size: 14, color: Colors.teal),

                                                    const SizedBox(width: 4),

                                                    Text(

                                                      "Beli: ${_currencyFormat.format(price)}",

                                                      style: GoogleFonts.plusJakartaSans(

                                                        fontSize: 11.5,

                                                        fontWeight: FontWeight.w600,

                                                        color: Colors.teal,

                                                      ),

                                                    ),

                                                    const SizedBox(width: 2),

                                                    const Icon(Icons.edit_outlined, size: 12, color: Colors.teal),

                                                  ],

                                                ),

                                              ),

                                            ),



                                            // Usual Stock Stepper

                                            Container(

                                              decoration: BoxDecoration(

                                                color: isDark ? Colors.black26 : Colors.white,

                                                borderRadius: BorderRadius.circular(8),

                                                border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),

                                              ),

                                              child: Row(

                                                mainAxisSize: MainAxisSize.min,

                                                children: [

                                                  InkWell(

                                                    onTap: () {

                                                      if (usualQty > 1) {

                                                        setSheetState(() => productStocks[prodId] = usualQty - 1);

                                                      }

                                                    },

                                                    child: const Padding(

                                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),

                                                      child: Icon(Icons.remove, size: 16),

                                                    ),

                                                  ),

                                                  InkWell(

                                                    onTap: () async {

                                                      final val = await _showInputQuantityDialog(usualQty);

                                                      if (val != null) {

                                                        setSheetState(() => productStocks[prodId] = val);

                                                      }

                                                    },

                                                    child: Padding(

                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),

                                                      child: Text(

                                                        "$usualQty pcs",

                                                        style: GoogleFonts.plusJakartaSans(

                                                          fontWeight: FontWeight.w700,

                                                          fontSize: 12,

                                                          color: primaryGreen,

                                                        ),

                                                      ),

                                                    ),

                                                  ),

                                                  InkWell(

                                                    onTap: () {

                                                      setSheetState(() => productStocks[prodId] = usualQty + 1);

                                                    },

                                                    child: const Padding(

                                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),

                                                      child: Icon(Icons.add, size: 16),

                                                    ),

                                                  ),

                                                ],

                                              ),

                                            ),

                                          ],

                                        ),

                                        const SizedBox(height: 6),

                                        Align(

                                          alignment: Alignment.centerRight,

                                          child: Text(

                                            "Subtotal: ${_currencyFormat.format(subtotal)}",

                                            style: GoogleFonts.plusJakartaSans(

                                              fontSize: 11,

                                              fontWeight: FontWeight.w600,

                                              color: isDark ? Colors.white70 : const Color(0xFF64748B),

                                            ),

                                          ),

                                        ),

                                      ],

                                    ),

                                  );

                                },

                              ),

                            ],

                          ],

                        ),

                      ),

                    ),



                    // Bottom Save Button

                    Padding(

                      padding: const EdgeInsets.all(16),

                      child: SizedBox(

                        width: double.infinity,

                        height: 50,

                        child: ElevatedButton(

                          onPressed: () async {

                            final name = nameCtrl.text.trim();

                            if (name.isEmpty) {

                              ScaffoldMessenger.of(context).showSnackBar(

                                const SnackBar(content: Text("Nama supplier tidak boleh kosong")),

                              );

                              return;

                            }



                            final admin = Provider.of<AdminController>(context, listen: false);

                            final storeId = admin.storeId ?? '';



                            if (supplier == null) {

                              await _supplierService.addSupplier(

                                storeId: storeId,

                                name: name,

                                phone: phoneCtrl.text.trim(),

                                address: addressCtrl.text.trim(),

                                notes: notesCtrl.text.trim(),

                                productUsualStock: productStocks,

                                productPrices: productPrices,

                              );

                            } else {

                              final updated = supplier.copyWith(

                                name: name,

                                phone: phoneCtrl.text.trim(),

                                address: addressCtrl.text.trim(),

                                notes: notesCtrl.text.trim(),

                                productUsualStock: productStocks,

                                productPrices: productPrices,

                              );

                              await _supplierService.updateSupplier(updated);

                            }



                            if (ctx.mounted) Navigator.pop(ctx);

                            _fetchData();

                          },

                          style: ElevatedButton.styleFrom(

                            backgroundColor: primaryGreen,

                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),

                            elevation: 0,

                          ),

                          child: Text(

                            supplier == null ? "Simpan Supplier" : "Simpan Perubahan",

                            style: GoogleFonts.plusJakartaSans(

                              fontWeight: FontWeight.w700,

                              fontSize: 15,

                              color: Colors.white,

                            ),

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



  // --- RESTOCK CONFIRMATION FROM SUPPLIER ---

  Future<void> _openRestockFromSupplierSheet(Supplier supplier) async {

    // Map of productId -> restockQty

    final Map<String, int> restockQtys = {};

    for (final entry in supplier.productUsualStock.entries) {

      restockQtys[entry.key] = entry.value;

    }



    // Set of checked productIds

    final Set<String> checkedProductIds = Set.from(restockQtys.keys);



    await showModalBottomSheet(

      context: context,

      isScrollControlled: true,

      backgroundColor: Colors.transparent,

      builder: (ctx) {

        final isDark = Theme.of(ctx).brightness == Brightness.dark;

        return StatefulBuilder(

          builder: (context, setSheetState) {

            final totalPcs = checkedProductIds.fold<int>(

              0,

              (sum, id) => sum + (restockQtys[id] ?? 0),

            );

            final totalCost = checkedProductIds.fold<double>(0.0, (sum, id) {

              final prod = _allProducts.cast<Product?>().firstWhere((p) => p?.id == id, orElse: () => null);

              final price = supplier.productPrices[id] ?? (prod?.buyPrice ?? prod?.basePrice ?? 0.0);

              return sum + ((restockQtys[id] ?? 0) * price);

            });



            return SafeArea(

              child: Container(

                constraints: BoxConstraints(

                  maxHeight: MediaQuery.of(ctx).size.height * 0.9,

                ),

                decoration: BoxDecoration(

                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,

                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),

                ),

                child: Column(

                  mainAxisSize: MainAxisSize.min,

                  children: [

                    // Header

                    Padding(

                      padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),

                      child: Row(

                        mainAxisAlignment: MainAxisAlignment.spaceBetween,

                        children: [

                          Expanded(

                            child: Column(

                              crossAxisAlignment: CrossAxisAlignment.start,

                              children: [

                                Text(

                                  "Restock dari ${supplier.name}",

                                  style: GoogleFonts.plusJakartaSans(

                                    fontSize: 17,

                                    fontWeight: FontWeight.w700,

                                  ),

                                  overflow: TextOverflow.ellipsis,

                                ),

                                Text(

                                  "Jumlah telah diisi otomatis sesuai stok biasa.",

                                  style: GoogleFonts.plusJakartaSans(

                                    fontSize: 11.5,

                                    color: Colors.grey,

                                  ),

                                ),

                              ],

                            ),

                          ),

                          IconButton(

                            icon: const Icon(Icons.close_rounded),

                            onPressed: () => Navigator.pop(ctx),

                          ),

                        ],

                      ),

                    ),

                    const Divider(height: 1),



                    // Products to restock

                    Expanded(

                      child: restockQtys.isEmpty

                          ? Center(

                              child: Padding(

                                padding: const EdgeInsets.all(24),

                                child: Column(

                                  mainAxisAlignment: MainAxisAlignment.center,

                                  children: [

                                    const Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey),

                                    const SizedBox(height: 12),

                                    Text(

                                      "Belum ada produk yang dihubungkan ke ${supplier.name}.",

                                      textAlign: TextAlign.center,

                                      style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.grey),

                                    ),

                                    const SizedBox(height: 16),

                                    ElevatedButton.icon(

                                      onPressed: () async {

                                        Navigator.pop(ctx);

                                        _openSupplierFormDialog(supplier: supplier);

                                      },

                                      icon: const Icon(Icons.edit_outlined, size: 16, color: Colors.white),

                                      label: const Text("Atur Produk Supplier Ini", style: TextStyle(color: Colors.white)),

                                      style: ElevatedButton.styleFrom(backgroundColor: primaryGreen),

                                    ),

                                  ],

                                ),

                              ),

                            )

                          : ListView.separated(

                              padding: const EdgeInsets.all(16),

                              itemCount: restockQtys.length,

                              separatorBuilder: (_, __) => const SizedBox(height: 8),

                              itemBuilder: (context, idx) {

                                final prodId = restockQtys.keys.elementAt(idx);

                                final qty = restockQtys[prodId] ?? 0;

                                final isChecked = checkedProductIds.contains(prodId);



                                final prod = _allProducts.cast<Product?>().firstWhere(

                                  (p) => p?.id == prodId,

                                  orElse: () => null,

                                );

                                final prodName = prod?.name ?? "Produk #$prodId";

                                final currentStock = prod?.stockQuantity ?? 0;

                                final newStock = currentStock + (isChecked ? qty : 0);



                                return Container(

                                  padding: const EdgeInsets.all(12),

                                  decoration: BoxDecoration(

                                    color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF8FAFC),

                                    borderRadius: BorderRadius.circular(12),

                                    border: Border.all(

                                      color: isChecked ? primaryGreen.withValues(alpha: 0.4) : (isDark ? Colors.white12 : Colors.grey[200]!),

                                      width: isChecked ? 1.5 : 1,

                                    ),

                                  ),

                                  child: Row(

                                    children: [

                                      Checkbox(

                                        value: isChecked,

                                        activeColor: primaryGreen,

                                        onChanged: (val) {

                                          setSheetState(() {

                                            if (val == true) {

                                              checkedProductIds.add(prodId);

                                            } else {

                                              checkedProductIds.remove(prodId);

                                            }

                                          });

                                        },

                                      ),

                                      Expanded(

                                        child: Column(

                                          crossAxisAlignment: CrossAxisAlignment.start,

                                          children: [

                                            Text(

                                              prodName,

                                              style: GoogleFonts.plusJakartaSans(

                                                fontWeight: FontWeight.w700,

                                                fontSize: 13,

                                              ),

                                            ),

                                            const SizedBox(height: 2),

                                            Text(

                                              "Stok: ${currentStock.toStringAsFixed(0)} ➔ Menjadi: ${newStock.toStringAsFixed(0)} pcs",

                                              style: GoogleFonts.plusJakartaSans(

                                                fontSize: 11.5,

                                                fontWeight: FontWeight.w600,

                                                color: isChecked ? primaryGreen : Colors.grey,

                                              ),

                                            ),

                                          ],

                                        ),

                                      ),

                                      const SizedBox(width: 8),



                                      // Quantity Counter

                                      Container(

                                        decoration: BoxDecoration(

                                          color: isDark ? Colors.black26 : Colors.white,

                                          borderRadius: BorderRadius.circular(8),

                                          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),

                                        ),

                                        child: Row(

                                          mainAxisSize: MainAxisSize.min,

                                          children: [

                                            InkWell(

                                              onTap: () {

                                                if (qty > 1) {

                                                  setSheetState(() => restockQtys[prodId] = qty - 1);

                                                }

                                              },

                                              child: const Padding(

                                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),

                                                child: Icon(Icons.remove, size: 16),

                                              ),

                                            ),

                                            InkWell(

                                              onTap: () async {

                                                final val = await _showInputQuantityDialog(qty);

                                                if (val != null) {

                                                  setSheetState(() => restockQtys[prodId] = val);

                                                }

                                              },

                                              child: Padding(

                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),

                                                child: Text(

                                                  "+$qty",

                                                  style: GoogleFonts.plusJakartaSans(

                                                    fontWeight: FontWeight.w700,

                                                    fontSize: 13,

                                                    color: primaryGreen,

                                                  ),

                                                ),

                                              ),

                                            ),

                                            InkWell(

                                              onTap: () {

                                                setSheetState(() => restockQtys[prodId] = qty + 1);

                                              },

                                              child: const Padding(

                                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),

                                                child: Icon(Icons.add, size: 16),

                                              ),

                                            ),

                                          ],

                                        ),

                                      ),

                                    ],

                                  ),

                                );

                              },

                            ),

                    ),



                    // Bottom Confirm Button

                    if (restockQtys.isNotEmpty) ...[

                      Padding(

                        padding: const EdgeInsets.all(16),

                        child: Column(

                          children: [

                            Row(

                              mainAxisAlignment: MainAxisAlignment.spaceBetween,

                              children: [

                                Text(

                                  "${checkedProductIds.length} Produk dipilih",

                                  style: GoogleFonts.plusJakartaSans(

                                    fontWeight: FontWeight.w600,

                                    fontSize: 13,

                                    color: Colors.grey[600],

                                  ),

                                ),

                                Text(

                                  "Total Restock: $totalPcs pcs",

                                  style: GoogleFonts.plusJakartaSans(

                                    fontWeight: FontWeight.w700,

                                    fontSize: 13,

                                    color: primaryGreen,

                                  ),

                                ),

                              ],

                            ),

                            const SizedBox(height: 10),

                            SizedBox(

                              width: double.infinity,

                              height: 50,

                              child: ElevatedButton.icon(

                                onPressed: checkedProductIds.isEmpty

                                    ? null

                                    : () async {

                                        final itemSummaries = <String>[];

                                        for (final id in checkedProductIds) {

                                          final p = _allProducts.cast<Product?>().firstWhere((x) => x?.id == id, orElse: () => null);

                                          final name = p?.name ?? 'Item #$id';

                                          itemSummaries.add('$name (+${restockQtys[id]} pcs)');

                                        }



                                        await _applyRestock(

                                          supplierName: supplier.name,

                                          restockMap: {

                                            for (final id in checkedProductIds)

                                              id: restockQtys[id] ?? 0,

                                          },

                                          totalCost: totalCost,

                                          itemSummaries: itemSummaries,

                                        );

                                        if (ctx.mounted) Navigator.pop(ctx);

                                      },

                                icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white),

                                label: Text(

                                  totalCost > 0

                                      ? "Restock & Catat Biaya (${_currencyFormat.format(totalCost)})"

                                      : "Konfirmasi & Tambah Stok ($totalPcs pcs)",

                                  style: GoogleFonts.plusJakartaSans(

                                    fontWeight: FontWeight.w700,

                                    fontSize: 13.5,

                                    color: Colors.white,

                                  ),

                                ),

                                style: ElevatedButton.styleFrom(

                                  backgroundColor: primaryGreen,

                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),

                                  elevation: 0,

                                ),

                              ),

                            ),

                          ],

                        ),

                      ),

                    ],

                  ],

                ),

              ),

            );

          },

        );

      },

    );

  }



  Future<void> _applyRestock({

    required String supplierName,

    required Map<String, int> restockMap,

    double totalCost = 0.0,

    List<String> itemSummaries = const [],

  }) async {

    final db = Provider.of<AppDatabase>(context, listen: false);

    final admin = Provider.of<AdminController>(context, listen: false);

    final storeId = admin.storeId ?? '';

    int totalItems = 0;

    int totalQty = 0;



    try {

      for (final entry in restockMap.entries) {

        final prodId = entry.key;

        final addQty = entry.value;

        if (addQty <= 0) continue;



        final current = await (db.select(db.products)..where((t) => t.id.equals(prodId))).getSingleOrNull();

        if (current != null) {

          final newStock = (current.stockQuantity ?? 0) + addQty;

          await (db.update(db.products)..where((t) => t.id.equals(prodId))).write(

            ProductsCompanion(

              stockQuantity: drift.Value(newStock),

              lastUpdated: drift.Value(DateTime.now()),

            ),

          );

          totalItems++;

          totalQty += addQty;

        }

      }



      // Record to Expenses for Cash Flow & Report tracking if cost > 0

      if (totalCost > 0 && storeId.isNotEmpty) {

        final expenseService = ExpenseService(db);

        await expenseService.createExpense(

          storeId: storeId,

          category: 'Restock Supplier',

          amount: totalCost,

          notes: 'Restock dari $supplierName: ${itemSummaries.join(", ")}',

          date: DateTime.now(),

        );

      }



      await _fetchData();



      if (mounted) {

        ScaffoldMessenger.of(context).showSnackBar(

          SnackBar(

            content: Text(

              totalCost > 0

                  ? "Berhasil restock $totalItems barang (+$totalQty pcs) dari $supplierName & tercatat di Arus Kas (${_currencyFormat.format(totalCost)})!"

                  : "Berhasil restock $totalItems barang (total +$totalQty pcs) dari $supplierName!",

              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),

            ),

            backgroundColor: primaryGreen,

            behavior: SnackBarBehavior.floating,

          ),

        );

      }

    } catch (e) {

      debugPrint("Restock error: $e");

      if (mounted) {

        ScaffoldMessenger.of(context).showSnackBar(

          SnackBar(

            content: Text("Gagal melakukan restock: $e"),

            backgroundColor: Colors.red,

          ),

        );

      }

    }

  }



  // --- DELETE SUPPLIER ---

  Future<void> _confirmDeleteSupplier(Supplier sup) async {

    final confirm = await showDialog<bool>(

      context: context,

      builder: (ctx) => KasirDialog(

        title: "Hapus Supplier?",

        message: "Yakin ingin menghapus supplier '${sup.name}'? Data supplier dan daftar produk terhubung akan dihapus.",

        icon: Icons.delete_outline_rounded,

        iconColor: Colors.red,

        primaryActionLabel: "HAPUS",

        onPrimaryAction: () => Navigator.pop(ctx, true),

        secondaryActionLabel: "BATAL",

        onSecondaryAction: () => Navigator.pop(ctx, false),

      ),

    );



    if (confirm == true) {

      if (!mounted) return;

      final admin = Provider.of<AdminController>(context, listen: false);

      await _supplierService.deleteSupplier(sup.id, admin.storeId ?? '');

      _fetchData();

      if (mounted) {

        ScaffoldMessenger.of(context).showSnackBar(

          SnackBar(content: Text("Supplier '${sup.name}' telah dihapus.")),

        );

      }

    }

  }



  // --- PICK PRODUCTS DIALOG ---

  Future<List<Product>?> _showPickProductsDialog({

    required Set<String> alreadySelectedIds,

  }) async {

    final Set<String> newlySelected = Set.from(alreadySelectedIds);

    String query = '';



    return showDialog<List<Product>>(

      context: context,

      builder: (ctx) {

        final isDark = Theme.of(ctx).brightness == Brightness.dark;

        return StatefulBuilder(

          builder: (context, setDlgState) {

            final filtered = _allProducts.where((p) {

              final name = (p.name ?? '').toLowerCase();

              final sku = (p.sku ?? '').toLowerCase();

              return name.contains(query.toLowerCase()) || sku.contains(query.toLowerCase());

            }).toList();



            return Dialog(

              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),

              backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,

              child: ConstrainedBox(

                constraints: const BoxConstraints(maxWidth: 480, maxHeight: 560),

                child: Padding(

                  padding: const EdgeInsets.all(20),

                  child: Column(

                    children: [

                      Row(

                        mainAxisAlignment: MainAxisAlignment.spaceBetween,

                        children: [

                          Text(

                            "Pilih Produk",

                            style: GoogleFonts.plusJakartaSans(

                              fontWeight: FontWeight.w700,

                              fontSize: 16,

                            ),

                          ),

                          IconButton(

                            icon: const Icon(Icons.close_rounded, size: 20),

                            onPressed: () => Navigator.pop(ctx),

                          ),

                        ],

                      ),

                      const SizedBox(height: 8),



                      // Search field

                      Container(

                        padding: const EdgeInsets.symmetric(horizontal: 12),

                        decoration: BoxDecoration(

                          color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF1F5F9),

                          borderRadius: BorderRadius.circular(10),

                        ),

                        child: TextField(

                          onChanged: (val) => setDlgState(() => query = val),

                          decoration: const InputDecoration(

                            hintText: "Cari nama barang...",

                            icon: Icon(Icons.search, size: 18),

                            border: InputBorder.none,

                          ),

                        ),

                      ),

                      const SizedBox(height: 12),



                      // List of products

                      Expanded(

                        child: ListView.separated(

                          itemCount: filtered.length,

                          separatorBuilder: (_, __) => const Divider(height: 1),

                          itemBuilder: (context, idx) {

                            final prod = filtered[idx];

                            final isSel = newlySelected.contains(prod.id);



                            return CheckboxListTile(

                              value: isSel,

                              activeColor: primaryGreen,

                              title: Text(

                                prod.name ?? 'Produk',

                                style: GoogleFonts.plusJakartaSans(

                                  fontWeight: FontWeight.w600,

                                  fontSize: 13,

                                ),

                              ),

                              subtitle: Text(

                                "Stok: ${(prod.stockQuantity ?? 0).toStringAsFixed(0)} pcs",

                                style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.grey),

                              ),

                              onChanged: (val) {

                                setDlgState(() {

                                  if (val == true) {

                                    newlySelected.add(prod.id);

                                  } else {

                                    newlySelected.remove(prod.id);

                                  }

                                });

                              },

                            );

                          },

                        ),

                      ),

                      const SizedBox(height: 12),



                      SizedBox(

                        width: double.infinity,

                        height: 46,

                        child: ElevatedButton(

                          onPressed: () {

                            final chosen = _allProducts.where((p) => newlySelected.contains(p.id)).toList();

                            Navigator.pop(ctx, chosen);

                          },

                          style: ElevatedButton.styleFrom(

                            backgroundColor: primaryGreen,

                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),

                          ),

                          child: Text(

                            "Pilih (${newlySelected.length} Produk)",

                            style: GoogleFonts.plusJakartaSans(

                              fontWeight: FontWeight.w700,

                              color: Colors.white,

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



  Future<double?> _showInputPriceDialog(double current) async {

    final ctrl = TextEditingController(text: current > 0 ? current.toStringAsFixed(0) : '');

    return showDialog<double>(

      context: context,

      builder: (ctx) => AlertDialog(

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),

        title: Text(

          "Harga Beli / Pasok (Rp)",

          style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700),

        ),

        content: Column(

          mainAxisSize: MainAxisSize.min,

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            Text(

              "Masukkan harga modal per unit yang Anda beli dari supplier ini:",

              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey),

            ),

            const SizedBox(height: 10),

            TextField(

              controller: ctrl,

              keyboardType: TextInputType.number,

              autofocus: true,

              decoration: InputDecoration(

                prefixText: "Rp ",

                hintText: "Contoh: 15000",

                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),

                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),

              ),

            ),

          ],

        ),

        actions: [

          TextButton(

            onPressed: () => Navigator.pop(ctx),

            child: const Text("Batal"),

          ),

          ElevatedButton(

            style: ElevatedButton.styleFrom(

              backgroundColor: primaryGreen,

              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),

            ),

            onPressed: () {

              final raw = ctrl.text.replaceAll(RegExp(r'[^0-9]'), '');

              final val = double.tryParse(raw);

              Navigator.pop(ctx, val ?? current);

            },

            child: const Text("Simpan", style: TextStyle(color: Colors.white)),

          ),

        ],

      ),

    );

  }



  // Helper input number dialog

  Future<int?> _showInputQuantityDialog(int currentVal) async {

    final ctrl = TextEditingController(text: currentVal.toString());

    return showDialog<int>(

      context: context,

      builder: (ctx) => AlertDialog(

        title: Text("Jumlah Stok Biasa", style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700)),

        content: TextField(

          controller: ctrl,

          keyboardType: TextInputType.number,

          autofocus: true,

          decoration: const InputDecoration(

            labelText: "Jumlah (Pcs)",

            border: OutlineInputBorder(),

          ),

        ),

        actions: [

          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),

          ElevatedButton(

            onPressed: () {

              final val = int.tryParse(ctrl.text.trim());

              if (val != null && val > 0) {

                Navigator.pop(ctx, val);

              }

            },

            style: ElevatedButton.styleFrom(backgroundColor: primaryGreen),

            child: const Text("Setel", style: TextStyle(color: Colors.white)),

          ),

        ],

      ),

    );

  }



  Widget _buildFieldLabel(String label) {

    return Padding(

      padding: const EdgeInsets.only(bottom: 6),

      child: Text(

        label,

        style: GoogleFonts.plusJakartaSans(

          fontSize: 13,

          fontWeight: FontWeight.w700,

        ),

      ),

    );

  }



  Widget _buildTextField(

    TextEditingController controller,

    String hint,

    bool isDark, {

    TextInputType keyboardType = TextInputType.text,

    int maxLines = 1,

  }) {

    return Container(

      decoration: BoxDecoration(

        color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF1F5F9),

        borderRadius: BorderRadius.circular(12),

        border: Border.all(color: isDark ? Colors.white12 : Colors.grey[200]!),

      ),

      child: TextField(

        controller: controller,

        keyboardType: keyboardType,

        maxLines: maxLines,

        scrollPadding: const EdgeInsets.only(bottom: 120),

        style: GoogleFonts.plusJakartaSans(fontSize: 13.5),

        decoration: InputDecoration(

          hintText: hint,

          hintStyle: GoogleFonts.plusJakartaSans(color: Colors.grey, fontSize: 13),

          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),

          border: InputBorder.none,

        ),

      ),

    );

  }

}

