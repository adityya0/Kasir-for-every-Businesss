import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' show Value;
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

import '../services/app_database.dart';
import '../services/order_service.dart';
import '../services/supplier_service.dart';
import '../services/receipt_service.dart';
import '../services/bluetooth_printer_service.dart';
import 'kasir_dialog.dart';
import 'transaction_result_dialog.dart';

enum ActivityDetailType {
  penjualan,
  pembelian,
  bayarHutang,
  biaya,
  terimaPiutang,
  prive,
  setorModal,
  transfer,
  pemasukanLain,
  retur,
}

class ActivityDetailSheet {
  static Future<void> show({
    required BuildContext context,
    required ActivityDetailType type,
    required String code,
    required String title,
    required DateTime date,
    required double amount,
    String? contactName,
    String? accountName,
    String? categoryName,
    String? notes,
    bool isDebt = false,
    double? paidAmount,
    double? remainingDebt,
    Transaction? rawTransaction,
    SupplierTransaction? rawSupplierTx,
    Expense? rawExpense,
    VoidCallback? onRefresh,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ActivityDetailSheetWidget(
        type: type,
        code: code,
        title: title,
        date: date,
        amount: amount,
        contactName: contactName,
        accountName: accountName,
        categoryName: categoryName,
        notes: notes,
        isDebt: isDebt,
        paidAmount: paidAmount,
        remainingDebt: remainingDebt,
        rawTransaction: rawTransaction,
        rawSupplierTx: rawSupplierTx,
        rawExpense: rawExpense,
        onRefresh: onRefresh,
      ),
    );
  }
}

class _ActivityDetailSheetWidget extends StatefulWidget {
  final ActivityDetailType type;
  final String code;
  final String title;
  final DateTime date;
  final double amount;
  final String? contactName;
  final String? accountName;
  final String? categoryName;
  final String? notes;
  final bool isDebt;
  final double? paidAmount;
  final double? remainingDebt;
  final Transaction? rawTransaction;
  final SupplierTransaction? rawSupplierTx;
  final Expense? rawExpense;
  final VoidCallback? onRefresh;

  const _ActivityDetailSheetWidget({
    required this.type,
    required this.code,
    required this.title,
    required this.date,
    required this.amount,
    this.contactName,
    this.accountName,
    this.categoryName,
    this.notes,
    this.isDebt = false,
    this.paidAmount,
    this.remainingDebt,
    this.rawTransaction,
    this.rawSupplierTx,
    this.rawExpense,
    this.onRefresh,
  });

  @override
  State<_ActivityDetailSheetWidget> createState() => _ActivityDetailSheetWidgetState();
}

class _ActivityDetailSheetWidgetState extends State<_ActivityDetailSheetWidget> {
  final NumberFormat _curFmt = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  List<TransactionItem> _saleItems = [];
  bool _isLoadingItems = false;

  @override
  void initState() {
    super.initState();
    if (widget.type == ActivityDetailType.penjualan && widget.rawTransaction != null) {
      _loadSaleItems();
    }
  }

  Future<void> _loadSaleItems() async {
    setState(() => _isLoadingItems = true);
    try {
      final db = context.read<AppDatabase>();
      final items = await (db.select(db.transactionItems)
            ..where((ti) => ti.transactionId.equals(widget.rawTransaction!.id)))
          .get();
      if (mounted) {
        setState(() {
          _saleItems = items;
          _isLoadingItems = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingItems = false);
    }
  }

  String _formatDate(DateTime d) {
    try {
      return DateFormat('EEE, d MMM yyyy', 'id_ID').format(d);
    } catch (_) {
      return DateFormat('dd/MM/yyyy').format(d);
    }
  }

  Future<void> _handleShareToWhatsApp({bool openWhatsApp = true}) async {
    final curFmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final dateStr = DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(widget.date);

    final buffer = StringBuffer();
    buffer.writeln("🧾 *RINCIAN ${widget.title.toUpperCase()}*");
    buffer.writeln("─────────────────────────");
    buffer.writeln("🔖 *No Ref:* ${widget.code}");
    buffer.writeln("📅 *Tanggal:* $dateStr");

    if (widget.categoryName != null && widget.categoryName!.isNotEmpty) {
      buffer.writeln("🏷️ *Kategori:* ${widget.categoryName}");
    }

    if (widget.contactName != null && widget.contactName!.isNotEmpty) {
      final role = (widget.type == ActivityDetailType.pembelian || widget.type == ActivityDetailType.retur)
          ? "Supplier"
          : (widget.type == ActivityDetailType.penjualan ? "Pelanggan" : "Kontak");
      buffer.writeln("👤 *$role:* ${widget.contactName}");
    }

    if (widget.accountName != null && widget.accountName!.isNotEmpty) {
      buffer.writeln("💳 *Akun:* ${widget.accountName}");
    }

    // Daftar Barang (Penjualan / Pembelian / Retur)
    if (widget.type == ActivityDetailType.penjualan && _saleItems.isNotEmpty) {
      buffer.writeln("─────────────────────────");
      buffer.writeln("📦 *Daftar Barang:*");
      for (final item in _saleItems) {
        final q = (item.quantity ?? 1).toInt();
        final p = curFmt.format(item.unitPrice ?? 0);
        final sub = curFmt.format(item.totalPrice ?? 0);
        buffer.writeln(" • ${item.productName} ($q pcs @ $p) = $sub");
      }
    } else if (widget.rawSupplierTx != null && widget.rawSupplierTx!.items.isNotEmpty) {
      buffer.writeln("─────────────────────────");
      buffer.writeln("📦 *Daftar Barang:*");
      for (final item in widget.rawSupplierTx!.items) {
        final q = item.quantity.toInt();
        final p = curFmt.format(item.unitPrice);
        final sub = curFmt.format(item.subtotal);
        buffer.writeln(" • ${item.productName} ($q pcs @ $p) = $sub");
      }
    }

    buffer.writeln("─────────────────────────");
    buffer.writeln("💵 *Total:* ${curFmt.format(widget.amount)}");
    if (widget.paidAmount != null && widget.paidAmount! > 0) {
      buffer.writeln("💰 *Dibayar:* ${curFmt.format(widget.paidAmount!)}");
    }
    if (widget.remainingDebt != null && widget.remainingDebt! > 0) {
      buffer.writeln("⚠️ *Sisa Hutang/Piutang:* ${curFmt.format(widget.remainingDebt!)}");
    }
    if (widget.notes != null && widget.notes!.trim().isNotEmpty) {
      buffer.writeln("📝 *Catatan:* ${widget.notes!.trim()}");
    }
    buffer.writeln("─────────────────────────");
    buffer.writeln("Dikirim melalui *OMNI POS* 🙏");

    final text = buffer.toString();

    // 1. Selalu salin ke Clipboard
    await Clipboard.setData(ClipboardData(text: text));

    if (!openWhatsApp) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text("✓ Rincian berhasil disalin ke clipboard", style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            backgroundColor: Color(0xFF00BF63),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    // 2. Cek nomor kontak (Supplier atau Pelanggan)
    String targetPhone = '';
    try {
      if (mounted) {
        final db = context.read<AppDatabase>();
        if (widget.rawSupplierTx != null) {
          final supService = SupplierService(db);
          final sups = await supService.getSuppliers(widget.rawSupplierTx!.storeId);
          final matched = sups.cast<Supplier?>().firstWhere(
            (s) => s?.id == widget.rawSupplierTx!.supplierId,
            orElse: () => null,
          );
          if (matched != null && matched.phone != null && matched.phone!.isNotEmpty) {
            targetPhone = matched.phone!;
          }
        } else if (widget.rawTransaction != null && widget.rawTransaction!.customerId != null) {
          final cust = await (db.select(db.customers)..where((c) => c.id.equals(widget.rawTransaction!.customerId!))).getSingleOrNull();
          if (cust != null && cust.phoneNumber != null && cust.phoneNumber!.isNotEmpty) {
            targetPhone = cust.phoneNumber!;
          }
        }
      }
    } catch (_) {}

    String cleanPhone = targetPhone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanPhone.startsWith('0')) {
      cleanPhone = '62${cleanPhone.substring(1)}';
    }

    Uri uri;
    if (cleanPhone.isNotEmpty) {
      uri = Uri.parse("https://wa.me/$cleanPhone?text=${Uri.encodeComponent(text)}");
    } else {
      uri = Uri.parse("https://wa.me/?text=${Uri.encodeComponent(text)}");
    }

    bool launched = false;
    try {
      if (await canLaunchUrl(uri)) {
        launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}

    if (!launched) {
      try {
        final waScheme = Uri.parse(cleanPhone.isNotEmpty
            ? "whatsapp://send?phone=$cleanPhone&text=${Uri.encodeComponent(text)}"
            : "whatsapp://send?text=${Uri.encodeComponent(text)}");
        if (await canLaunchUrl(waScheme)) {
          launched = await launchUrl(waScheme, mode: LaunchMode.externalApplication);
        }
      } catch (_) {}
    }

    if (!launched) {
      try {
        await SharePlus.instance.share(ShareParams(text: text));
        launched = true;
      } catch (_) {}
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  launched
                      ? "Membuka WhatsApp / bagikan & teks tersalin ke clipboard"
                      : "✓ Rincian berhasil disalin ke clipboard",
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF00BF63),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _printReceipt() async {
    final receiptService = ReceiptService();
    final bluetoothService = BluetoothPrinterService();

    const storeName = "OMNI POS";
    final transactionId = widget.code;

    List<Map<String, dynamic>> itemsList = [];
    if (widget.type == ActivityDetailType.penjualan) {
      for (final i in _saleItems) {
        itemsList.add({
          'name': i.productName,
          'quantity': i.quantity?.toDouble() ?? 1.0,
          'price': i.unitPrice ?? 0.0,
          'total': i.totalPrice ?? 0.0,
        });
      }
    } else if (widget.type == ActivityDetailType.pembelian && widget.rawSupplierTx != null) {
      for (final i in widget.rawSupplierTx!.items) {
        itemsList.add({
          'name': i.productName,
          'quantity': i.quantity,
          'price': i.unitPrice,
          'total': i.subtotal,
        });
      }
    }

    // Try thermal printer first if connected
    if (bluetoothService.isConnected) {
      try {
        await bluetoothService.printReceipt(
          storeName: storeName,
          transactionId: transactionId,
          createdAt: widget.date,
          items: itemsList,
          subtotal: widget.amount,
          totalAmount: widget.amount,
          cashReceived: widget.paidAmount ?? widget.amount,
          change: ((widget.paidAmount ?? widget.amount) - widget.amount).clamp(0.0, double.infinity),
          paymentMethod: widget.accountName ?? "Kas",
          customerName: widget.contactName,
          isDebt: widget.isDebt,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("✓ Sedang mencetak struk thermal...")),
          );
        }
        return;
      } catch (e) {
        debugPrint("Bluetooth print error: $e");
      }
    }

    // Fallback: PDF sharing
    await receiptService.shareReceiptPdf(
      storeName: storeName,
      transactionId: transactionId,
      createdAt: widget.date,
      items: itemsList,
      subtotal: widget.amount,
      discount: 0.0,
      pajakAmount: 0.0,
      pajakName: 'PPN',
      totalAmount: widget.amount,
      cashReceived: widget.paidAmount ?? widget.amount,
      change: ((widget.paidAmount ?? widget.amount) - widget.amount).clamp(0.0, double.infinity),
      paymentMethod: widget.accountName ?? "Kas",
      customerName: widget.contactName,
      isDebt: widget.isDebt,
    );
  }

  Future<void> _handleCancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => KasirDialog(
        title: "Batalkan ${widget.title}?",
        message: "Apakah Anda yakin ingin membatalkan transaksi ini (${widget.code})? Data dan stok/saldo akan disesuaikan kembali.",
        icon: Icons.delete_outline_rounded,
        iconColor: const Color(0xFFE05260),
        isDestructive: true,
        primaryActionLabel: "Batalkan Transaksi",
        onPrimaryAction: () => Navigator.pop(ctx, true),
        secondaryActionLabel: "Batal",
        onSecondaryAction: () => Navigator.pop(ctx, false),
      ),
    );

    if (confirmed != true || !mounted) return;

    final db = context.read<AppDatabase>();
    final orderService = OrderService(db);
    final supplierService = SupplierService(db);

    try {
      if (widget.type == ActivityDetailType.penjualan && widget.rawTransaction != null) {
        await orderService.deleteTransaction(widget.rawTransaction!.id, restoreStock: true);
      } else if (widget.type == ActivityDetailType.pembelian && widget.rawSupplierTx != null) {
        final stx = widget.rawSupplierTx!;
        // 1. Revert added stock
        for (final item in stx.items) {
          if (item.productId.isEmpty || item.quantity <= 0) continue;
          final p = await (db.select(db.products)..where((t) => t.id.equals(item.productId))).getSingleOrNull();
          if (p != null) {
            final curStock = p.stockQuantity ?? 0.0;
            final updatedStock = (curStock - item.quantity).clamp(0.0, double.infinity);
            await (db.update(db.products)..where((t) => t.id.equals(p.id))).write(
              ProductsCompanion(stockQuantity: Value(updatedStock)),
            );
          }
        }
        // 2. Delete supplier transaction
        await supplierService.deleteSupplierTransaction(stx.id, stx.storeId);
        // 3. Delete any corresponding expense
        try {
          await db.customStatement(
            "DELETE FROM expenses WHERE store_id = ? AND notes LIKE ?",
            [stx.storeId, '%(${stx.transactionNo})%'],
          );
        } catch (_) {}
      } else if (widget.type == ActivityDetailType.bayarHutang) {
        if (widget.rawSupplierTx != null) {
          final stx = widget.rawSupplierTx!;
          await supplierService.deleteSupplierTransaction(stx.id, stx.storeId);
          try {
            await db.customStatement(
              "DELETE FROM expenses WHERE store_id = ? AND notes LIKE ?",
              [stx.storeId, '%(${stx.transactionNo})%'],
            );
          } catch (_) {}
        } else if (widget.rawExpense != null) {
          await (db.delete(db.expenses)..where((t) => t.id.equals(widget.rawExpense!.id))).go();
        }
      } else if (widget.rawExpense != null) {
        await (db.delete(db.expenses)..where((t) => t.id.equals(widget.rawExpense!.id))).go();
      }

      if (mounted) {
        Navigator.pop(context);
        widget.onRefresh?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✓ ${widget.title} ${widget.code} berhasil dibatalkan"),
            backgroundColor: const Color(0xFF00BF63),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal membatalkan: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleRetur() async {
    final db = context.read<AppDatabase>();

    if (widget.type == ActivityDetailType.penjualan) {
      // Retur Penjualan
      if (_saleItems.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Tidak ada barang untuk diretur")),
        );
        return;
      }

      TransactionItem selectedItem = _saleItems.first;
      final qtyCtrl = TextEditingController(text: "1");
      final notesCtrl = TextEditingController();

      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (rctx) {
          final dark = Theme.of(rctx).brightness == Brightness.dark;
          return StatefulBuilder(
            builder: (rctx, setReturState) {
              return Padding(
                padding: EdgeInsets.only(bottom: MediaQuery.of(rctx).viewInsets.bottom),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Container(
                      decoration: BoxDecoration(
                        color: dark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "RETUR PENJUALAN",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: dark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close_rounded),
                                onPressed: () => Navigator.pop(rctx),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 16),
                          Text("PILIH BARANG", style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey)),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<TransactionItem>(
                            initialValue: selectedItem,
                            isExpanded: true,
                            items: _saleItems.map((item) {
                              return DropdownMenuItem(
                                value: item,
                                child: Text("${item.productName} (${(item.quantity ?? 1).toInt()} pcs)"),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setReturState(() => selectedItem = val);
                            },
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text("JUMLAH RETUR (PCS)", style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: qtyCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text("ALASAN RETUR", style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: notesCtrl,
                            decoration: InputDecoration(
                              hintText: "Contoh: Barang rusak / kadaluarsa",
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00BF63),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () async {
                                final qty = double.tryParse(qtyCtrl.text.trim()) ?? 0.0;
                                if (qty <= 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Jumlah retur harus lebih dari 0")),
                                  );
                                  return;
                                }

                                if (selectedItem.productId != null) {
                                  // 1. Restore product stock
                                  final p = await (db.select(db.products)..where((t) => t.id.equals(selectedItem.productId!))).getSingleOrNull();
                                  if (p != null) {
                                    final cur = p.stockQuantity ?? 0.0;
                                    await (db.update(db.products)..where((t) => t.id.equals(p.id))).write(
                                      ProductsCompanion(stockQuantity: Value(cur + qty)),
                                    );
                                  }
                                }

                                // 2. Record Return entry in expenses as an outflow refund or log
                                final refundAmt = (selectedItem.unitPrice ?? 0.0) * qty;
                                final noteReason = notesCtrl.text.trim().isNotEmpty ? " - ${notesCtrl.text.trim()}" : "";
                                await db.into(db.expenses).insert(
                                  ExpensesCompanion.insert(
                                    id: 'retur_${DateTime.now().millisecondsSinceEpoch}',
                                    storeId: Value(widget.rawTransaction?.storeId),
                                    category: 'Retur Penjualan',
                                    amount: Value(refundAmt),
                                    notes: Value("Retur ${widget.code} · ${selectedItem.productName} ($qty pcs)$noteReason"),
                                    date: Value(DateTime.now()),
                                  ),
                                );

                                if (rctx.mounted) Navigator.pop(rctx);
                                if (mounted) {
                                  Navigator.pop(context);
                                  widget.onRefresh?.call();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("✓ Retur $qty pcs ${selectedItem.productName} berhasil dicatat, stok otomatis dikembalikan"),
                                      backgroundColor: const Color(0xFF00BF63),
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.check_rounded, size: 18),
                              label: const Text("Konfirmasi Retur", style: TextStyle(fontWeight: FontWeight.w700)),
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
    } else if (widget.type == ActivityDetailType.pembelian && widget.rawSupplierTx != null) {
      // Retur Pembelian ke Supplier
      final supplierTx = widget.rawSupplierTx!;
      if (supplierTx.items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Tidak ada barang untuk diretur")),
        );
        return;
      }

      final isLunas = supplierTx.paymentStatus.toLowerCase() == 'lunas';
      SupplierTransactionItem selectedItem = supplierTx.items.first;
      final qtyCtrl = TextEditingController(text: "1");
      final notesCtrl = TextEditingController();

      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (rctx) {
          final dark = Theme.of(rctx).brightness == Brightness.dark;
          return StatefulBuilder(
            builder: (rctx, setReturState) {
              return Padding(
                padding: EdgeInsets.only(bottom: MediaQuery.of(rctx).viewInsets.bottom),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Container(
                      decoration: BoxDecoration(
                        color: dark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "RETUR KE SUPPLIER",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: dark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close_rounded),
                                onPressed: () => Navigator.pop(rctx),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 14),

                          // Banner Penjelasan Keuangan (Lunas vs Hutang)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isLunas ? const Color(0xFFECFDF5) : const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isLunas ? const Color(0xFFA7F3D0) : const Color(0xFFFDE68A),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  isLunas ? Icons.account_balance_wallet_outlined : Icons.receipt_long_outlined,
                                  size: 20,
                                  color: isLunas ? const Color(0xFF047857) : const Color(0xFFB45309),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isLunas ? "Pembelian Lunas (Dana Kembali ke Saldo)" : "Pembelian Hutang (Potong Hutang)",
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: isLunas ? const Color(0xFF065F46) : const Color(0xFF92400E),
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        isLunas
                                            ? "Karena pembelian ini sudah lunas, dana retur barang akan otomatis dikembalikan ke saldo akun ${supplierTx.paymentMethod ?? 'Kas'}."
                                            : "Karena pembelian ini belum lunas / tempo, retur barang tidak mengembalikan uang kas melainkan langsung memotong sisa hutang ke supplier.",
                                        style: GoogleFonts.openSans(
                                          fontSize: 11,
                                          color: isLunas ? const Color(0xFF047857) : const Color(0xFFB45309),
                                          height: 1.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          Text("PILIH BARANG", style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey)),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<SupplierTransactionItem>(
                            initialValue: selectedItem,
                            isExpanded: true,
                            items: supplierTx.items.map((item) {
                              return DropdownMenuItem(
                                value: item,
                                child: Text("${item.productName} (${item.quantity.toInt()} pcs)"),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setReturState(() => selectedItem = val);
                            },
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text("JUMLAH RETUR (PCS)", style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: qtyCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text("ALASAN RETUR", style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: notesCtrl,
                            decoration: InputDecoration(
                              hintText: "Contoh: Barang cacat dari pabrik",
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00BF63),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () async {
                                final qty = double.tryParse(qtyCtrl.text.trim()) ?? 0.0;
                                if (qty <= 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Jumlah retur harus lebih dari 0")),
                                  );
                                  return;
                                }
                                if (qty > selectedItem.quantity) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("Jumlah retur tidak boleh melebihi pembelian (${selectedItem.quantity.toInt()} pcs)")),
                                  );
                                  return;
                                }

                                final supplierService = SupplierService(db);
                                final subtotal = selectedItem.unitPrice * qty;
                                final returnItem = SupplierTransactionItem(
                                  productId: selectedItem.productId,
                                  productName: selectedItem.productName,
                                  quantity: qty,
                                  unitPrice: selectedItem.unitPrice,
                                  subtotal: subtotal,
                                );

                                final resultTx = await supplierService.recordReturn(
                                  storeId: supplierTx.storeId,
                                  supplierId: supplierTx.supplierId,
                                  items: [returnItem],
                                  isPurchaseLunas: isLunas,
                                  paymentMethod: supplierTx.paymentMethod,
                                  paymentMethodId: supplierTx.paymentMethodId,
                                  notes: "Retur ${supplierTx.transactionNo} - ${notesCtrl.text.trim()}",
                                );

                                if (rctx.mounted) Navigator.pop(rctx);
                                if (mounted) {
                                  Navigator.pop(context);
                                  widget.onRefresh?.call();

                                  TransactionResultDialog.show(
                                    context: context,
                                    isSuccess: true,
                                    title: 'Retur Berhasil Dicatat',
                                    subtitle: isLunas
                                        ? 'Retur pembelian telah dicatat. Dana sebesar ${_curFmt.format(subtotal)} berhasil dikembalikan ke saldo akun ${supplierTx.paymentMethod ?? "Kas"}.'
                                        : 'Retur pembelian telah dicatat. Saldo hutang ke supplier berhasil dipotong sebesar ${_curFmt.format(subtotal)}.',
                                    transactionCode: resultTx.transactionNo,
                                    totalAmount: subtotal,
                                    paidAmount: isLunas ? subtotal : 0.0,
                                    statusBadge: isLunas ? 'DANA KEMBALI' : 'POTONG HUTANG',
                                    statusBadgeBg: isLunas ? const Color(0xFFECFDF5) : const Color(0xFFFEF3C7),
                                    statusBadgeText: isLunas ? const Color(0xFF047857) : const Color(0xFFB45309),
                                    accountName: isLunas ? (supplierTx.paymentMethod ?? "Kas") : "-",
                                    category: 'Retur Pembelian',
                                    notes: 'Ref: ${supplierTx.transactionNo}${notesCtrl.text.trim().isNotEmpty ? " · ${notesCtrl.text.trim()}" : ""}',
                                    itemSummaries: [
                                      '${selectedItem.productName} (${qty.toInt()} pcs) @ ${_curFmt.format(selectedItem.unitPrice)}'
                                    ],
                                  );
                                }
                              },
                              icon: const Icon(Icons.check_rounded, size: 18),
                              label: const Text("Konfirmasi Retur ke Supplier", style: TextStyle(fontWeight: FontWeight.w700)),
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
  }

  IconData _getHeaderIcon() {
    switch (widget.type) {
      case ActivityDetailType.penjualan:
        return Icons.receipt_long_rounded;
      case ActivityDetailType.pembelian:
        return Icons.shopping_bag_outlined;
      case ActivityDetailType.retur:
        return Icons.keyboard_return_rounded;
      case ActivityDetailType.bayarHutang:
        return Icons.credit_card_rounded;
      case ActivityDetailType.terimaPiutang:
        return Icons.account_balance_wallet_rounded;
      case ActivityDetailType.prive:
        return Icons.person_remove_outlined;
      case ActivityDetailType.setorModal:
        return Icons.savings_outlined;
      case ActivityDetailType.transfer:
        return Icons.swap_horiz_rounded;
      case ActivityDetailType.pemasukanLain:
        return Icons.add_circle_outline_rounded;
      case ActivityDetailType.biaya:
        return Icons.payments_outlined;
    }
  }

  Color _getHeaderColor() {
    switch (widget.type) {
      case ActivityDetailType.penjualan:
      case ActivityDetailType.setorModal:
      case ActivityDetailType.pemasukanLain:
        return const Color(0xFF00BF63);
      case ActivityDetailType.pembelian:
        return const Color(0xFFD97706);
      case ActivityDetailType.retur:
        return const Color(0xFF2563EB);
      case ActivityDetailType.bayarHutang:
      case ActivityDetailType.biaya:
      case ActivityDetailType.prive:
        return const Color(0xFFE05260);
      case ActivityDetailType.terimaPiutang:
        return const Color(0xFF0D9488);
      case ActivityDetailType.transfer:
        return const Color(0xFF0284C7);
    }
  }

  String _getCleanHeaderTitle() {
    final t = widget.title.trim().toUpperCase();
    if (t.contains('PEMBELIAN')) return 'Detail Pembelian';
    if (t.contains('PENJUALAN')) return 'Detail Penjualan';
    if (t.contains('RETUR')) return 'Detail Retur';
    if (t.contains('BAYAR HUTANG')) return 'Bayar Hutang';
    if (t.contains('TERIMA PIUTANG')) return 'Terima Piutang';
    if (t.contains('PRIVE')) return 'Prive / Pribadi';
    if (t.contains('SETOR MODAL')) return 'Setor Modal';
    if (t.contains('TRANSFER')) return 'Transfer Saldo';
    if (t.contains('PEMASUKAN')) return 'Pemasukan Lain';
    if (t.contains('BIAYA')) return 'Detail Biaya';
    return widget.title;
  }

  Widget _buildStatusBadge(bool isDark) {
    if (widget.type == ActivityDetailType.retur) {
      final isLunas = widget.isDebt == false;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isLunas ? const Color(0xFFECFDF5) : const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          isLunas ? 'DANA KEMBALI' : 'POTONG HUTANG',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: isLunas ? const Color(0xFF047857) : const Color(0xFFB45309),
          ),
        ),
      );
    }

    final hasDebt = widget.isDebt || (widget.remainingDebt != null && widget.remainingDebt! > 0);
    if (hasDebt) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFFECACA), width: 0.8),
        ),
        child: Text(
          widget.type == ActivityDetailType.penjualan ? 'PIUTANG' : 'HUTANG',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: const Color(0xFFDC2626),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFA7F3D0), width: 0.8),
      ),
      child: Text(
        'LUNAS',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF059669),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerColor = _getHeaderColor();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 580,
            maxHeight: MediaQuery.of(context).size.height * 0.92,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle pill
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 4),
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // 1. Header Bar (Versi Kita)
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 6, 16, 12),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: headerColor.withValues(alpha: isDark ? 0.2 : 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(_getHeaderIcon(), color: headerColor, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    _getCleanHeaderTitle(),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _buildStatusBadge(isDark),
                              ],
                            ),
                            const SizedBox(height: 3),
                            InkWell(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: widget.code));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("✓ Kode ${widget.code} disalin"),
                                    duration: const Duration(seconds: 1),
                                    backgroundColor: const Color(0xFF00BF63),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(6),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    widget.code,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.copy_rounded,
                                    size: 11,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                            ),
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: isDark ? Colors.white70 : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),

                // 2. Scrollable Body
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Metadata Card (Versi Kita)
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.5) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Column(
                            children: [
                              _buildModernInfoRow(Icons.calendar_today_rounded, "TANGGAL", _formatDate(widget.date), isDark),
                              if (widget.contactName != null && widget.contactName!.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                _buildModernInfoRow(
                                  (widget.type == ActivityDetailType.pembelian || widget.type == ActivityDetailType.retur)
                                      ? Icons.storefront_outlined
                                      : (widget.type == ActivityDetailType.penjualan ? Icons.person_outline_rounded : Icons.contacts_outlined),
                                  (widget.type == ActivityDetailType.pembelian || widget.type == ActivityDetailType.retur)
                                      ? "SUPPLIER"
                                      : (widget.type == ActivityDetailType.penjualan ? "PELANGGAN" : "KONTAK"),
                                  widget.contactName!,
                                  isDark,
                                ),
                              ],
                              if (widget.accountName != null && widget.accountName!.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                _buildModernInfoRow(Icons.account_balance_wallet_outlined, "AKUN", widget.accountName!, isDark),
                              ],
                              if (widget.categoryName != null && widget.categoryName!.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                _buildModernInfoRow(Icons.local_offer_outlined, "KATEGORI", widget.categoryName!, isDark),
                              ],
                              if (widget.notes != null && widget.notes!.trim().isNotEmpty &&
                                  (widget.type == ActivityDetailType.bayarHutang ||
                                   widget.type == ActivityDetailType.biaya ||
                                   widget.type == ActivityDetailType.terimaPiutang ||
                                   widget.type == ActivityDetailType.prive ||
                                   widget.type == ActivityDetailType.setorModal ||
                                   widget.type == ActivityDetailType.transfer ||
                                   widget.type == ActivityDetailType.pemasukanLain)) ...[
                                const SizedBox(height: 10),
                                _buildModernInfoRow(Icons.notes_rounded, "CATATAN", widget.notes!.trim(), isDark),
                              ],
                              if (widget.type == ActivityDetailType.bayarHutang ||
                                  widget.type == ActivityDetailType.biaya ||
                                  widget.type == ActivityDetailType.terimaPiutang ||
                                  widget.type == ActivityDetailType.prive ||
                                  widget.type == ActivityDetailType.setorModal ||
                                  widget.type == ActivityDetailType.transfer ||
                                  widget.type == ActivityDetailType.pemasukanLain) ...[
                                const SizedBox(height: 12),
                                Divider(height: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "JUMLAH",
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                      ),
                                    ),
                                    Text(
                                      _curFmt.format(widget.amount),
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                        color: headerColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),

                        // Action for bayar hutang / terima piutang receipt print
                        if (widget.type == ActivityDetailType.bayarHutang || widget.type == ActivityDetailType.terimaPiutang) ...[
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: _printReceipt,
                            icon: const Icon(Icons.print_outlined, size: 17),
                            label: const Text("Cetak Kuitansi"),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              side: BorderSide(color: isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ],

                        // Items Table (for Penjualan, Pembelian, & Retur)
                        if (widget.type == ActivityDetailType.penjualan ||
                            widget.type == ActivityDetailType.pembelian ||
                            widget.type == ActivityDetailType.retur) ...[
                          const SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.5) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              children: [
                                // Table Header
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                  child: _buildItemsHeader(isDark),
                                ),
                                Divider(height: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),

                                // Item List
                                if (widget.type == ActivityDetailType.penjualan) ...[
                                  if (_isLoadingItems)
                                    const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
                                  else if (_saleItems.isEmpty)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      child: Text("- Tidak ada rincian item -", style: GoogleFonts.openSans(fontSize: 12.5, color: Colors.grey)),
                                    )
                                  else
                                    ListView.separated(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: _saleItems.length,
                                      separatorBuilder: (_, __) => Divider(height: 1, color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                                      itemBuilder: (_, idx) {
                                        final item = _saleItems[idx];
                                        return _buildItemRow(
                                          item.productName ?? 'Barang',
                                          "${(item.quantity ?? 1).toInt()} pcs",
                                          _curFmt.format(item.unitPrice ?? 0),
                                          _curFmt.format(item.totalPrice ?? 0),
                                          isDark,
                                        );
                                      },
                                    ),
                                ] else if (widget.rawSupplierTx != null) ...[
                                  if (widget.rawSupplierTx!.items.isEmpty)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      child: Text("- Tidak ada rincian item -", style: GoogleFonts.openSans(fontSize: 12.5, color: Colors.grey)),
                                    )
                                  else
                                    ListView.separated(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: widget.rawSupplierTx!.items.length,
                                      separatorBuilder: (_, __) => Divider(height: 1, color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                                      itemBuilder: (_, idx) {
                                        final item = widget.rawSupplierTx!.items[idx];
                                        return _buildItemRow(
                                          item.productName,
                                          "${item.quantity.toInt()} pcs",
                                          _curFmt.format(item.unitPrice),
                                          _curFmt.format(item.subtotal),
                                          isDark,
                                        );
                                      },
                                    ),
                                ],
                              ],
                            ),
                          ),

                          // Summary Card (Versi Kita)
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.5) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Column(
                              children: [
                                _buildSummaryRow(
                                  widget.type == ActivityDetailType.retur ? "Total Nilai Retur" : "Total",
                                  _curFmt.format(widget.amount),
                                  isDark,
                                  isBold: true,
                                ),
                                if (widget.type != ActivityDetailType.retur) ...[
                                  const SizedBox(height: 8),
                                  _buildSummaryRow(
                                    "Dibayar",
                                    _curFmt.format(widget.paidAmount ?? (widget.isDebt ? 0 : widget.amount)),
                                    isDark,
                                  ),
                                  if (widget.isDebt || (widget.remainingDebt != null && widget.remainingDebt! > 0)) ...[
                                    const SizedBox(height: 8),
                                    _buildSummaryRow(
                                      widget.type == ActivityDetailType.penjualan ? "Sisa piutang" : "Sisa hutang",
                                      _curFmt.format(widget.remainingDebt ?? widget.amount),
                                      isDark,
                                      isRed: true,
                                    ),
                                  ],
                                ] else ...[
                                  const SizedBox(height: 8),
                                  _buildSummaryRow(
                                    "Perlakuan Saldo",
                                    widget.isDebt ? "Potong Hutang (Tanpa Masuk Kas)" : "Dana Masuk ke Saldo",
                                    isDark,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // 3. Action Buttons Footer (Versi Kita)
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    border: Border(top: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
                  ),
                  child: _buildFooterActions(isDark),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernInfoRow(IconData icon, String label, String value, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 14, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
        const SizedBox(width: 8),
        SizedBox(
          width: 85,
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              letterSpacing: 0.3,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemsHeader(bool isDark) {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Text(
            "BARANG",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white60 : const Color(0xFF64748B),
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
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white60 : const Color(0xFF64748B),
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            "HARGA",
            textAlign: TextAlign.right,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white60 : const Color(0xFF64748B),
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
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white60 : const Color(0xFF64748B),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemRow(String name, String qty, String price, String subtotal, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              name,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              qty,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : const Color(0xFF475569),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              price,
              textAlign: TextAlign.right,
              style: GoogleFonts.openSans(
                fontSize: 12,
                color: isDark ? Colors.white60 : const Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              subtotal,
              textAlign: TextAlign.right,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, bool isDark, {bool isBold = false, bool isRed = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: isBold || isRed ? FontWeight.w700 : FontWeight.w500,
            color: isRed
                ? const Color(0xFFE05260)
                : (isDark ? Colors.white70 : const Color(0xFF475569)),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: isBold ? 15.5 : 14,
            fontWeight: isBold || isRed ? FontWeight.w800 : FontWeight.w600,
            color: isRed
                ? const Color(0xFFE05260)
                : (isDark ? Colors.white : const Color(0xFF0F172A)),
          ),
        ),
      ],
    );
  }

  Widget _buildFooterActions(bool isDark) {
    if (widget.type == ActivityDetailType.retur) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00BF63),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          child: Text(
            "Tutup",
            style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ),
      );
    }
    if (widget.type == ActivityDetailType.penjualan || widget.type == ActivityDetailType.pembelian) {
      return Row(
        children: [
          // 1. Retur Button
          OutlinedButton.icon(
            onPressed: _handleRetur,
            icon: const Icon(Icons.undo_rounded, size: 17),
            label: Text(
              "Retur",
              style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
              side: BorderSide(color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(width: 8),

          // 2. Trash (Cancel) Button
          Tooltip(
            message: "Batalkan Transaksi",
            child: InkWell(
              onTap: _handleCancel,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.35) : const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFE05260).withValues(alpha: 0.3),
                  ),
                ),
                child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFE05260), size: 21),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 3. Share to WhatsApp & Copy Details Button
          Tooltip(
            message: "Kirim ke WhatsApp / Bagikan (Tahan untuk salin)",
            child: InkWell(
              onTap: () => _handleShareToWhatsApp(openWhatsApp: true),
              onLongPress: () => _handleShareToWhatsApp(openWhatsApp: false),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.35) : const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF25D366).withValues(alpha: 0.4),
                  ),
                ),
                child: const Icon(
                  Icons.share_rounded,
                  color: Color(0xFF16A34A),
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 4. Print Button (OMNI POS Signature Green)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _printReceipt,
              icon: const Icon(Icons.print_rounded, size: 18),
              label: Text(
                "Cetak",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00BF63),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
        ],
      );
    } else {
      // Bayar Hutang, Biaya, Terima Piutang, dll.
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton.icon(
            onPressed: _handleCancel,
            icon: const Icon(Icons.delete_outline_rounded, size: 17),
            label: Text(
              "Batalkan",
              style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE05260),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00BF63),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Text(
              "Tutup",
              style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      );
    }
  }
}
