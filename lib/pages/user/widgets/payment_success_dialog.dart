import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../../../services/bluetooth_printer_service.dart';
import '../../../widgets/kasir_dialog.dart';
import '../../../core/app_theme.dart';
import 'package:provider/provider.dart';
import '../../../controllers/settings_controller.dart';
import '../../../controllers/admin_controller.dart';

class PaymentSuccessDialog extends StatelessWidget {
  final Uint8List pdfData;
  final String transactionId;
  final double totalAmount;
  final double? subtotal;
  final double? discount;
  final double? pajakAmount;
  final String? pajakName;
  final double cashReceived;
  final double change;
  final VoidCallback onNewTransaction;

  // Print Data
  final String storeName;
  final DateTime createdAt;
  final List<Map<String, dynamic>> items;
  final String paymentMethod;
  final bool isDebt;
  final String? tableNumber;
  final String? customerName;
  final String? discountLabel;

  const PaymentSuccessDialog({
    super.key,
    required this.pdfData,
    required this.transactionId,
    required this.totalAmount,
    this.subtotal,
    this.discount,
    this.discountLabel,
    this.customerName,
    this.pajakAmount,
    this.pajakName,
    required this.cashReceived,
    required this.change,
    required this.onNewTransaction,
    required this.storeName,
    required this.createdAt,
    required this.items,
    required this.paymentMethod,
    this.isDebt = false,
    this.tableNumber,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currencyFormat = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final settings = SettingsController.instance;
    final adminCtrl = context.watch<AdminController>();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Success Icon
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.green,
                    size: 44,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  "Pembayaran Berhasil!",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  "Transaksi #$transactionId telah tersimpan.",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // Real Printed Thermal Receipt
                _buildRealReceiptCard(context, isDark, currencyFormat, settings, adminCtrl),
                const SizedBox(height: 24),

                // Actions: Print & Download
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: () => _handlePrint(context),
                          icon: const Icon(Icons.print_rounded, size: 20),
                          label: Text(
                            "Cetak",
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark ? Colors.white : Colors.black87,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            side: BorderSide(
                              color: isDark ? Colors.white24 : Colors.grey[300]!,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: () => _handleDownload(context),
                          icon: const Icon(Icons.download_rounded, size: 20),
                          label: Text(
                            "Unduh",
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark ? Colors.white : Colors.black87,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            side: BorderSide(
                              color: isDark ? Colors.white24 : Colors.grey[300]!,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // New Transaction Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context, rootNavigator: true).pop();
                      onNewTransaction();
                    },
                    icon: const Icon(
                      Icons.add_shopping_cart_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    label: Text(
                      "Transaksi Baru",
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Real Thermal Receipt Paper Widget matching the live overview print preview
  Widget _buildRealReceiptCard(
    BuildContext context,
    bool isDark,
    NumberFormat currencyFormat,
    SettingsController settings,
    AdminController adminCtrl,
  ) {
    final effectiveStoreName = (storeName.isNotEmpty
            ? storeName
            : (adminCtrl.storeName ?? "TOKO SAYA"))
        .toUpperCase();
    final effectiveStoreAddress = adminCtrl.storeAddress ?? "";
    final effectiveStoreEmail = adminCtrl.storeEmail ?? "";
    final effectiveLogo = adminCtrl.storeLogo;

    final showLogo = settings.receiptShowLogo.value;
    final showStoreName = settings.receiptShowStoreName.value;
    final showAddress = settings.receiptShowAddress.value && effectiveStoreAddress.isNotEmpty;
    final showEmail = settings.receiptShowEmail.value && effectiveStoreEmail.isNotEmpty;
    final showDate = settings.receiptShowDate.value;
    final showItems = settings.receiptShowDetails.value;
    final showThankYou = settings.receiptShowThankYou.value;
    final showTable = settings.receiptShowTable.value && (tableNumber != null && tableNumber!.isNotEmpty);

    final effectiveSubtotal = subtotal ?? totalAmount;
    final hasDiscount = discount != null && discount! > 0;
    final hasTax = pajakAmount != null && pajakAmount! > 0;
    final thankYouText = settings.receiptThankYouMessage.value.trim().isNotEmpty
        ? settings.receiptThankYouMessage.value.trim().toUpperCase()
        : "ATAS KUNJUNGAN ANDA";

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141414) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey[200]!,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey[300]!, width: 0.8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Logo
            if (showLogo) ...[
              Container(
                width: 44,
                height: 44,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                clipBehavior: Clip.antiAlias,
                child: _buildLogoImage(effectiveLogo),
              ),
            ],

            // Store Name
            if (showStoreName) ...[
              Text(
                effectiveStoreName,
                textAlign: TextAlign.center,
                style: GoogleFonts.robotoMono(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.black87,
                ),
              ),
            ],

            // Store Address
            if (showAddress) ...[
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  effectiveStoreAddress,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.robotoMono(
                    fontSize: 9.5,
                    color: Colors.black54,
                  ),
                ),
              ),
            ],

            // Store Email
            if (showEmail) ...[
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Text(
                  effectiveStoreEmail,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.robotoMono(
                    fontSize: 9.5,
                    color: Colors.black54,
                  ),
                ),
              ),
            ],

            _buildDashedDivider(isBold: false),

            // 2. Transaction Info
            _previewInfoRow("ID Trans", "#$transactionId"),
            if (showDate) ...[
              _previewInfoRow("Tanggal", DateFormat('dd/MM/yyyy').format(createdAt)),
              _previewInfoRow("Waktu", DateFormat('HH:mm').format(createdAt)),
            ],
            if (customerName != null && customerName!.trim().isNotEmpty) ...[
              _previewInfoRow("Pelanggan", customerName!.trim()),
            ],
            if (showTable) ...[
              _previewInfoRow("Meja", "MEJA ${tableNumber!.toUpperCase()}"),
            ],

            _buildDashedDivider(isBold: false),

            // 3. Items Header
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "ITEM",
                    style: GoogleFonts.robotoMono(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    "TOTAL",
                    style: GoogleFonts.robotoMono(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

            // 4. Items List
            if (showItems && items.isNotEmpty) ...[
              ...items.map((item) {
                final name = (item['name'] ?? item['productName'] ?? 'Item').toString();
                final qty = (item['quantity'] ?? item['qty'] ?? 1) as num;
                final price = (item['unit_price'] ?? item['unitPrice'] ?? (item['price'] ?? 0)) as num;
                final total = (item['total_price'] ?? item['totalPrice'] ?? (price * qty)) as num;
                final notes = item['notes']?.toString();

                return _previewItemRow(
                  name: name,
                  price: currencyFormat.format(price),
                  qty: qty.toString(),
                  total: currencyFormat.format(total),
                  notes: notes,
                );
              }),
            ] else if (items.isEmpty) ...[
              _previewItemRow(
                name: "Total Pembelian",
                price: currencyFormat.format(totalAmount),
                qty: "1",
                total: currencyFormat.format(totalAmount),
              ),
            ],

            _buildDashedDivider(isBold: false),

            // 5. Summary (Subtotal, Diskon, Pajak, Total)
            if (hasDiscount || hasTax) ...[
              _previewSummaryRow("Subtotal", currencyFormat.format(effectiveSubtotal)),
            ],
            if (hasDiscount) ...[
              _previewSummaryRow(
                discountLabel != null && discountLabel!.trim().isNotEmpty
                    ? discountLabel!.trim()
                    : "Diskon",
                "-${currencyFormat.format(discount!)}",
                color: Colors.red[700],
              ),
            ],
            if (hasTax) ...[
              _previewSummaryRow(
                pajakName ?? "Pajak",
                currencyFormat.format(pajakAmount!),
              ),
            ],

            _buildDashedDivider(isBold: true),

            // Grand Total
            _previewSummaryRow(
              "TOTAL",
              currencyFormat.format(totalAmount),
              isBold: true,
              fontSize: 14,
            ),

            _buildDashedDivider(isBold: true),

            // 6. Payment Info
            _previewSummaryRow("Metode Pembayaran", paymentMethod),
            _previewSummaryRow("Tunai / Bayar", currencyFormat.format(cashReceived)),
            _previewSummaryRow(
              isDebt ? "Kekurangan (Hutang)" : "Kembalian",
              currencyFormat.format(isDebt ? (totalAmount - cashReceived) : change),
              isBold: true,
              color: isDebt ? Colors.red[700] : Colors.green[800],
            ),

            _buildDashedDivider(isBold: false),

            // 7. Thank You message
            if (showThankYou) ...[
              Text(
                "TERIMA KASIH",
                style: GoogleFonts.robotoMono(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                thankYouText,
                textAlign: TextAlign.center,
                style: GoogleFonts.robotoMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],

            // Table Box
            if (showTable) ...[
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 10, bottom: 4),
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 1.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  children: [
                    Text(
                      "NOMOR MEJA",
                      style: GoogleFonts.robotoMono(
                        fontSize: 8.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tableNumber!.toUpperCase(),
                      style: GoogleFonts.robotoMono(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 10),
            Text(
              "DIHASILKAN OLEH SISTEM KASIR BERSAMA",
              style: GoogleFonts.robotoMono(
                fontSize: 7.5,
                fontStyle: FontStyle.italic,
                color: Colors.black45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoImage(String? path) {
    if (path == null || path.isEmpty) {
      return Image.asset(
        'assets/logo/logo.png',
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Icon(
          Icons.storefront_rounded,
          size: 24,
          color: Colors.grey,
        ),
      );
    }
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Image.asset(
          'assets/logo/logo.png',
          fit: BoxFit.contain,
        ),
      );
    }
    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Image.asset(
          'assets/logo/logo.png',
          fit: BoxFit.contain,
        ),
      );
    }
    if (!kIsWeb) {
      final file = File(path);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Image.asset(
            'assets/logo/logo.png',
            fit: BoxFit.contain,
          ),
        );
      }
    }
    return Image.asset('assets/logo/logo.png', fit: BoxFit.contain);
  }

  Widget _buildDashedDivider({bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: List.generate(
          28,
          (index) => Expanded(
            child: Container(
              height: isBold ? 1.5 : 1.0,
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              color: isBold ? Colors.black87 : Colors.black45,
            ),
          ),
        ),
      ),
    );
  }

  Widget _previewInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.robotoMono(fontSize: 10, color: Colors.black54),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.robotoMono(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _previewItemRow({
    required String name,
    required String price,
    required String qty,
    required String total,
    String? notes,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name.toUpperCase(),
            style: GoogleFonts.robotoMono(
              fontSize: 9.5,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          if (notes != null && notes.trim().isNotEmpty) ...[
            Text(
              "* ${notes.trim()}",
              style: GoogleFonts.robotoMono(
                fontSize: 8.5,
                fontStyle: FontStyle.italic,
                color: Colors.black54,
              ),
            ),
          ],
          const SizedBox(height: 1),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "$qty x $price",
                style: GoogleFonts.robotoMono(fontSize: 9.5, color: Colors.black87),
              ),
              Text(
                total,
                style: GoogleFonts.robotoMono(
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _previewSummaryRow(
    String label,
    String value, {
    bool isBold = false,
    Color? color,
    double fontSize = 10.5,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.robotoMono(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: fontSize,
              color: color ?? (isBold ? Colors.black87 : Colors.black54),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.robotoMono(
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                fontSize: fontSize,
                color: color ?? (isBold ? Colors.black87 : Colors.black87),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePrint(BuildContext context) async {
    final settings = SettingsController.instance;
    final adminCtrl = context.read<AdminController>();
    final printerService = BluetoothPrinterService();

    // Check connection first
    final isConnected = await printerService.isConnectedStatus ?? false;
    if (!isConnected) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => KasirDialog(
            title: "Printer Tidak Terhubung",
            message:
                "Printer bluetooth Anda belum terhubung. Silakan hubungkan printer melalui menu Pengaturan Printer.",
            icon: Icons.print_disabled_rounded,
            iconColor: AppTheme.primaryColor,
            primaryActionLabel: "TUTUP",
            onPrimaryAction: () => Navigator.pop(ctx),
          ),
        );
      }
      return;
    }

    try {
      await printerService.printReceipt(
        storeName: storeName,
        transactionId: transactionId,
        createdAt: createdAt,
        items: items,
        totalAmount: totalAmount,
        cashReceived: cashReceived,
        change: change,
        paymentMethod: paymentMethod,
        subtotal: subtotal,
        discount: discount,
        discountLabel: discountLabel,
        customerName: customerName,
        pajakAmount: pajakAmount,
        pajakName: pajakName,
        tableNumber: tableNumber,
        isDebt: isDebt,
        showStoreName: settings.receiptShowStoreName.value,
        showAddress: settings.receiptShowAddress.value,
        showDate: settings.receiptShowDate.value,
        showDetails: settings.receiptShowDetails.value,
        showThankYou: settings.receiptShowThankYou.value,
        showEmail: settings.receiptShowEmail.value,
        showTable: settings.receiptShowTable.value,
        storeAddress: adminCtrl.storeAddress,
        storeEmail: adminCtrl.storeEmail,
        thankYouMessage: settings.receiptThankYouMessage.value,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Mencetak struk...")));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Gagal mencetak: $e")));
      }
    }
  }

  Future<void> _handleDownload(BuildContext context) async {
    try {
      await Printing.sharePdf(
        bytes: pdfData,
        filename: 'Struk-$transactionId.pdf',
      );
    } catch (e) {
      debugPrint("Error sharing PDF: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Gagal mengunduh PDF")));
      }
    }
  }
}
