import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';
import '../../../services/bluetooth_printer_service.dart';
import 'package:provider/provider.dart';
import '../../../controllers/settings_controller.dart';
import '../../../controllers/admin_controller.dart';

class ReceiptPreviewPage extends StatelessWidget {
  final Uint8List pdfData;
  final String fileName;

  // Added for Bluetooth Printing
  final String? storeName;
  final String? transactionId;
  final DateTime? createdAt;
  final List<Map<String, dynamic>>? items;
  final double? totalAmount;
  final double? cashReceived;
  final double? change;
  final String? paymentMethod;
  final String? tableNumber;
  final double? subtotal;
  final double? discount;
  final double? pajakAmount;
  final String? pajakName;

  const ReceiptPreviewPage({
    super.key,
    required this.pdfData,
    required this.fileName,
    this.storeName,
    this.transactionId,
    this.createdAt,
    this.items,
    this.totalAmount,
    this.cashReceived,
    this.change,
    this.paymentMethod,
    this.tableNumber,
    this.subtotal,
    this.discount,
    this.pajakAmount,
    this.pajakName,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1C1E) : Colors.grey[50],
      appBar: AppBar(
        title: Text(
          "Struk Belanja",
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Placeholder for Print UI
          IconButton(
            icon: const Icon(Icons.print_rounded),
            onPressed: () async {
              final printerService = BluetoothPrinterService();
              final settings = SettingsController.instance;
              final adminCtrl = context.read<AdminController>();
              if (printerService.isConnected) {
                await printerService.printReceipt(
                  storeName: storeName ?? adminCtrl.storeName ?? "OMNI POS",
                  transactionId: transactionId ?? "TXN",
                  createdAt: createdAt ?? DateTime.now(),
                  items: items ?? [],
                  totalAmount: totalAmount ?? 0,
                  cashReceived: cashReceived ?? 0,
                  change: change ?? 0,
                  paymentMethod: paymentMethod ?? "Tunai",
                  tableNumber: tableNumber,
                  subtotal: subtotal,
                  discount: discount,
                  pajakAmount: pajakAmount,
                  pajakName: pajakName,
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Mencetak struk...")),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Printer Bluetooth belum terhubung!"),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            tooltip: "Cetak ke Printer Bluetooth",
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 310),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: PdfPreview(
                  build: (format) => pdfData,
                  allowPrinting: true,
                  allowSharing: true,
                  canChangePageFormat: false,
                  canChangeOrientation: false,
                  canDebug: false,
                  maxPageWidth: 310,
                  loadingWidget: const Center(child: CircularProgressIndicator()),
                  pdfFileName: fileName,
                  actions: const [],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.check_circle_outline_rounded,
                  color: Colors.white,
                ),
                label: Text(
                  "Selesai",
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00BF63),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

