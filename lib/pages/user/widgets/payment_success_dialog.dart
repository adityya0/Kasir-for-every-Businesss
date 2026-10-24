import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart'; // For sharing PDF
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
  final String? tableNumber; // Added
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
    this.tableNumber, // Added
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

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480), // Modern dialog width
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(32), // Increased padding
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Success Icon
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.green,
                    size: 56,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  "Pembayaran Berhasil!",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  "Transaksi #$transactionId telah tersimpan.",
                  style: GoogleFonts.openSans(fontSize: 15, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                if (tableNumber != null && tableNumber!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primaryColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.table_restaurant_rounded,
                          size: 18,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "MEJA: ${tableNumber!.toUpperCase()}",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 32),

                // Summary
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black26 : Colors.grey[50],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? Colors.white10 : Colors.grey[200]!,
                    ),
                  ),
                  child: Column(
                    children: [
                      if (customerName != null && customerName!.trim().isNotEmpty) ...[
                        _row("Pelanggan", customerName!.trim()),
                        const SizedBox(height: 8),
                      ],
                      if (subtotal != null &&
                          discount != null &&
                          discount! > 0) ...[
                        _row("Subtotal", currencyFormat.format(subtotal!)),
                        const SizedBox(height: 8),
                        _row(
                          discountLabel != null && discountLabel!.trim().isNotEmpty
                              ? discountLabel!.trim()
                              : "Diskon",
                          "-${currencyFormat.format(discount!)}",
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (pajakAmount != null && pajakAmount! > 0) ...[
                        _row(pajakName ?? "Pajak", currencyFormat.format(pajakAmount!)),
                        const SizedBox(height: 8),
                      ],
                      Divider(color: Colors.grey.withValues(alpha: 0.1)),
                      const SizedBox(height: 8),
                      _row(
                        "Total Tagihan",
                        currencyFormat.format(totalAmount),
                        isBold: true,
                        fontSize: 16,
                      ),
                      const SizedBox(height: 12),
                      _row("Tunai", currencyFormat.format(cashReceived)),
                      const SizedBox(height: 12),
                      Divider(color: Colors.grey.withValues(alpha: 0.2)),
                      const SizedBox(height: 12),
                      _row(
                        isDebt ? "Kekurangan (Hutang)" : "Kembalian",
                        currencyFormat.format(isDebt ? (totalAmount - cashReceived) : change),
                        isBold: true,
                        color: isDebt ? Colors.redAccent : Colors.green,
                        fontSize: 16,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: () => _handlePrint(context),
                          icon: const Icon(Icons.print_rounded, size: 20),
                          label: const Text("Cetak"),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            side: BorderSide(
                              color: isDark
                                  ? Colors.white24
                                  : Colors.grey[300]!,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: () => _handleDownload(context),
                          icon: const Icon(Icons.download_rounded, size: 20),
                          label: const Text("Unduh"),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            side: BorderSide(
                              color: isDark
                                  ? Colors.white24
                                  : Colors.grey[300]!,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Close dialog effectively first
                      Navigator.of(context, rootNavigator: true).pop();
                      // Then reset state
                      onNewTransaction();
                    },
                    icon: const Icon(
                      Icons.add_shopping_cart_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                    label: Text(
                      "Transaksi Baru",
                      style: GoogleFonts.openSans(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                      shadowColor: AppTheme.primaryColor.withValues(alpha: 0.4),
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

  Widget _row(
    String label,
    String value, {
    bool isBold = false,
    Color? color,
    double fontSize = 14,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.robotoMono(
              fontSize: fontSize,
              color: Colors.grey[600],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: GoogleFonts.robotoMono(
                fontSize: fontSize,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                color: color,
              ),
            ),
          ),
        ),
      ],
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
