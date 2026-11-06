import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../widgets/floating_card.dart';
import '../../../services/receipt_service.dart';
import '../../../controllers/admin_controller.dart';
import '../../../controllers/settings_controller.dart';
import '../../user/widgets/payment_success_dialog.dart';
import '../../../widgets/kasir_dialog.dart';
import '../../../services/bluetooth_printer_service.dart';
import '../../../services/order_service.dart';
import '../../../services/app_database.dart';
import '../../../controllers/analytics_controller.dart';

class TransactionDetailPage extends StatelessWidget {
  final Map<String, dynamic> transaction;

  const TransactionDetailPage({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final total = (transaction['totalAmount'] ?? 0 as num).toDouble();
    final items = List<Map<String, dynamic>>.from(
      transaction['transaction_items'] ?? [],
    );
    final rawDate = transaction['createdAt'];
    DateTime date;
    if (rawDate is DateTime) {
      date = rawDate.toLocal();
    } else if (rawDate != null) {
      final str = rawDate.toString();
      final asInt = int.tryParse(str);
      if (asInt != null) {
        date = DateTime.fromMillisecondsSinceEpoch(asInt).toLocal();
      } else {
        date = DateTime.tryParse(str)?.toLocal() ?? DateTime.now();
      }
    } else {
      date = DateTime.now();
    }
    final cashierName = transaction['profiles']?['fullName'] ?? 'System';
    final String? tableNumber = (transaction['tableNumber'] ?? transaction['table_number'])?.toString();

    double? savedDiscount;
    double? savedSubtotal;
    double? savedTax;
    String? savedDiscountLabel;
    String? savedCustomerName;
    final rawNotes = transaction['notes']?.toString();
    if (rawNotes != null && rawNotes.trim().startsWith('{') && rawNotes.trim().endsWith('}')) {
      try {
        final decoded = jsonDecode(rawNotes.trim()) as Map<String, dynamic>;
        savedDiscount = (decoded['discount'] as num?)?.toDouble();
        savedSubtotal = (decoded['subtotal'] as num?)?.toDouble();
        savedTax = (decoded['tax'] as num?)?.toDouble();
        savedDiscountLabel = decoded['discount_label']?.toString();
        savedCustomerName = decoded['customer_name']?.toString();
      } catch (_) {}
    }
    final effectiveCustomerName = savedCustomerName ?? transaction['customers']?['name']?.toString();

    final double calculatedSubtotal = items.fold(0.0, (sum, it) {
      return sum +
          ((it['unitPrice'] ?? 0 as num).toDouble() *
              (it['quantity'] as num).toDouble());
    });
    final double subtotal = savedSubtotal ?? (calculatedSubtotal > 0 ? calculatedSubtotal : total);
    
    // Infer tax and discount if not explicitly saved
    final double difference = total - subtotal;
    final double discount = savedDiscount ?? (difference < 0 ? -difference : 0.0);
    final double pajakAmount = savedTax ?? (difference > 0 ? difference : 0.0);
    final String pajakName = SettingsController.instance.pajakName.value;

    final currencyFormat = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Detail Transaksi",
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF2D3436),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : const Color(0xFF2D3436),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
            tooltip: "Hapus Transaksi",
            onPressed: () => _confirmDeleteTransaction(context, currencyFormat, total),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Receipt Header Card
            FloatingCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00BF63).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shopping_bag,
                      color: Color(0xFF00BF63),
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    currencyFormat.format(total),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF00BF63),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "ID: #${transaction['id'].toString().substring(0, 8).toUpperCase()}",
                    style: GoogleFonts.openSans(
                      color: isDark ? Colors.white54 : Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Transaction Info
            FloatingCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildInfoRow(
                    context,
                    "Waktu",
                    DateFormat('d MMM yyyy, HH:mm').format(date),
                    Icons.access_time,
                  ),
                  const Divider(height: 32),
                  _buildInfoRow(
                    context,
                    "Kasir",
                    cashierName,
                    Icons.person_outline,
                  ),
                  const Divider(height: 32),
                  _buildInfoRow(
                    context,
                    "Metode Bayar",
                    transaction['paymentMethod']?.toString().toUpperCase() ??
                        "TUNAI",
                    Icons.credit_card,
                  ),
                  if (tableNumber != null && tableNumber.isNotEmpty) ...[
                    const Divider(height: 32),
                    _buildInfoRow(
                      context,
                      "Nomor Meja",
                      tableNumber.toUpperCase(),
                      Icons.table_restaurant_outlined,
                    ),
                  ],
                  if (discount > 0) ...[
                    const Divider(height: 32),
                    _buildInfoRow(
                      context,
                      "Diskon",
                      "-${currencyFormat.format(discount)}",
                      Icons.discount_outlined,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Items List
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 12),
                child: Text(
                  "DAFTAR BELANJA",
                  style: GoogleFonts.robotoMono(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
            FloatingCard(
              padding: const EdgeInsets.all(20),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (context, index) => const Divider(height: 24),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final productName = item['productName'] ?? 'Produk';
                  final qty = item['quantity'] ?? 1;
                  final price = (item['unitPrice'] ?? 0 as num).toDouble();

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              productName,
                              style: GoogleFonts.robotoMono(
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF2D3436),
                              ),
                            ),
                            Text(
                              "$qty x ${currencyFormat.format(price)}",
                              style: GoogleFonts.robotoMono(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        currencyFormat.format(qty * price),
                        style: GoogleFonts.robotoMono(
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF2D3436),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
            // Print Action
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final adminCtrl = context.read<AdminController>();
                  final receiptService = ReceiptService();
                  final printerService = BluetoothPrinterService();

                  // Check printer connection before proceeding
                  final isConnected = await printerService.isConnectedStatus;
                  if (isConnected != true) {
                    if (context.mounted) {
                      showDialog(
                        context: context,
                        builder: (ctx) => KasirDialog(
                          title: "Printer Tidak Terhubung",
                          message:
                              "Printer bluetooth Anda belum terhubung. Silakan hubungkan printer melalui menu Pengaturan Printer.",
                          icon: Icons.print_disabled_rounded,
                          iconColor: Colors.orange,
                          primaryActionLabel: "TUTUP",
                          onPrimaryAction: () => Navigator.pop(ctx),
                        ),
                      );
                    }
                    return;
                  }

                    final pdfData = await receiptService.generateReceiptPdf(
                      storeName: adminCtrl.storeName ?? "Kakilima Pos",
                      storeLogoUrl: adminCtrl.storeLogo,
                      transactionId: transaction['id'].toString().substring(0, 8).toUpperCase(),
                      createdAt: date,
                      items: items.map((it) {
                        return {
                          'name': it['productName'] ?? 'Produk',
                          'quantity': it['quantity'],
                          'unit_price': (it['unitPrice'] ?? 0 as num).toDouble(),
                          'total_price':
                              (it['unitPrice'] ?? 0 as num).toDouble() *
                              (it['quantity'] as num).toDouble(),
                        };
                      }).toList(),
                      subtotal: subtotal,
                      discount: discount,
                      pajakAmount: pajakAmount,
                      pajakName: pajakName,
                      pajakRate: SettingsController.instance.pajakRate.value,
                      totalAmount: total,
                      cashReceived:
                          (transaction['cashReceived'] as num?)?.toDouble() ??
                          total,
                      change: (transaction['change'] as num?)?.toDouble() ?? 0,
                      paymentMethod:
                          transaction['paymentMethod']?.toString() ?? "TUNAI",
                      showStoreName: SettingsController.instance.receiptShowStoreName.value,
                      showAddress: SettingsController.instance.receiptShowAddress.value,
                      showDate: SettingsController.instance.receiptShowDate.value,
                      showDetails: SettingsController.instance.receiptShowDetails.value,
                      showThankYou: SettingsController.instance.receiptShowThankYou.value,
                      showLogo: SettingsController.instance.receiptShowLogo.value,
                      showEmail: SettingsController.instance.receiptShowEmail.value,
                      showTable: SettingsController.instance.receiptShowTable.value,
                      storeAddress: adminCtrl.storeAddress,
                      storeEmail: adminCtrl.storeEmail,
                      thankYouMessage: SettingsController.instance.receiptThankYouMessage.value,
                      tableNumber: tableNumber,
                      customerName: effectiveCustomerName,
                      discountLabel: savedDiscountLabel,
                    );

                  if (context.mounted) {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (ctx) => PaymentSuccessDialog(
                        pdfData: pdfData,
                        transactionId: transaction['id']
                            .toString()
                            .substring(0, 8)
                            .toUpperCase(),
                        subtotal: subtotal,
                        discount: discount,
                        discountLabel: savedDiscountLabel,
                        customerName: effectiveCustomerName,
                        pajakAmount: pajakAmount,
                        pajakName: pajakName,
                        totalAmount: total,
                        cashReceived:
                            (transaction['cashReceived'] as num?)?.toDouble() ??
                            total,
                        change:
                            (transaction['change'] as num?)?.toDouble() ?? 0,
                        storeName: adminCtrl.storeName ?? "Kakilima Pos",
                        createdAt: date,
                        items: items.map((it) {
                          return {
                            'name': it['productName'] ?? 'Produk',
                            'quantity': it['quantity'],
                            'total_price':
                                (it['unitPrice'] ?? 0 as num).toDouble() *
                                (it['quantity'] as num).toDouble(),
                          };
                        }).toList(),
                        paymentMethod:
                            transaction['paymentMethod']?.toString() ?? "TUNAI",
                        tableNumber: tableNumber,
                        onNewTransaction: () {
                          // Just close the dialog
                        },
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.print),
                label: Text(
                  "CETAK STRUK",
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.1,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00BF63),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final adminCtrl = context.read<AdminController>();
                  final receiptService = ReceiptService();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Menyiapkan struk digital..."), duration: Duration(seconds: 1)),
                  );
                  try {
                    await receiptService.shareReceiptPdf(
                      storeName: adminCtrl.storeName ?? "Kakilima Pos",
                      storeLogoUrl: adminCtrl.storeLogo,
                      transactionId: transaction['id'].toString().substring(0, 8).toUpperCase(),
                      createdAt: date,
                      items: items.map((it) {
                        return {
                          'name': it['productName'] ?? 'Produk',
                          'quantity': it['quantity'],
                          'unit_price': (it['unitPrice'] ?? 0 as num).toDouble(),
                          'total_price':
                              (it['unitPrice'] ?? 0 as num).toDouble() *
                              (it['quantity'] as num).toDouble(),
                        };
                      }).toList(),
                      subtotal: subtotal,
                      discount: discount,
                      pajakAmount: pajakAmount,
                      pajakName: pajakName,
                      pajakRate: SettingsController.instance.pajakRate.value,
                      totalAmount: total,
                      cashReceived:
                          (transaction['cashReceived'] as num?)?.toDouble() ??
                          total,
                      change: (transaction['change'] as num?)?.toDouble() ?? 0,
                      paymentMethod:
                          transaction['paymentMethod']?.toString() ?? "TUNAI",
                      showStoreName: SettingsController.instance.receiptShowStoreName.value,
                      showAddress: SettingsController.instance.receiptShowAddress.value,
                      showDate: SettingsController.instance.receiptShowDate.value,
                      showDetails: SettingsController.instance.receiptShowDetails.value,
                      showThankYou: SettingsController.instance.receiptShowThankYou.value,
                      showLogo: SettingsController.instance.receiptShowLogo.value,
                      showEmail: SettingsController.instance.receiptShowEmail.value,
                      storeAddress: adminCtrl.storeAddress,
                      storeEmail: adminCtrl.storeEmail,
                      thankYouMessage: SettingsController.instance.receiptThankYouMessage.value,
                      tableNumber: tableNumber,
                      customerName: effectiveCustomerName,
                      discountLabel: savedDiscountLabel,
                    );
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Gagal bagikan: $e"), backgroundColor: Colors.red),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.share),
                label: Text(
                  "BAGIKAN STRUK DIGITAL",
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.1,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF00BF63),
                  side: const BorderSide(color: Color(0xFF00BF63), width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () => _confirmDeleteTransaction(context, currencyFormat, total),
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                label: Text(
                  "HAPUS TRANSAKSI INI",
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF00BF63)),
        const SizedBox(width: 16),
        Text(
          label,
          style: GoogleFonts.openSans(
            color: isDark ? Colors.white54 : Colors.grey[600],
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF2D3436),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDeleteTransaction(
    BuildContext context,
    NumberFormat currencyFormat,
    double total,
  ) async {
    final txIdRaw = transaction['id']?.toString() ?? '';
    final shortId = txIdRaw.length >= 8 ? txIdRaw.substring(0, 8).toUpperCase() : txIdRaw.toUpperCase();

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => KasirDialog(
        title: "Hapus Transaksi?",
        message: "Transaksi #$shortId sebesar ${currencyFormat.format(total)} akan dihapus permanen.\n\nStok produk yang terjual akan otomatis dikembalikan ke inventaris, dan kalkulasi laporan omset/keuangan akan diperbarui.",
        icon: Icons.delete_forever_rounded,
        iconColor: Colors.red,
        isDestructive: true,
        primaryActionLabel: "Hapus Transaksi",
        onPrimaryAction: () => Navigator.pop(ctx, true),
        secondaryActionLabel: "Batal",
        onSecondaryAction: () => Navigator.pop(ctx, false),
      ),
    );

    if (shouldDelete == true && context.mounted) {
      try {
        final db = context.read<AppDatabase>();
        final orderService = OrderService(db);
        await orderService.deleteTransaction(txIdRaw, restoreStock: true);

        if (context.mounted) {
          try {
            context.read<AnalyticsController>().refreshData();
            context.read<AdminController>().loadInitialData();
          } catch (_) {}

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("✓ Transaksi berhasil dihapus dan stok telah dikembalikan"),
              backgroundColor: Color(0xFF10B981),
              duration: Duration(seconds: 2),
            ),
          );

          Navigator.pop(context, true);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Gagal menghapus transaksi: $e"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

