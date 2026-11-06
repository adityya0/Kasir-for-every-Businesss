import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'platform/file_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:printing/printing.dart';

class ReceiptService {
  final _currencyFormat = NumberFormat.currency(
    locale: 'id',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  Future<void> shareReceiptPdf({
    required String storeName,
    String? storeLogoUrl,
    required String transactionId,
    required DateTime createdAt,
    required List<Map<String, dynamic>> items,
    required double subtotal,
    required double discount,
    required double pajakAmount,
    required String pajakName,
    double? pajakRate,
    required double totalAmount,
    required double cashReceived,
    required double change,
    required String paymentMethod,
    bool showStoreName = true,
    bool showAddress = true,
    bool showDate = true,
    bool showDetails = true,
    bool showThankYou = true,
    bool showLogo = true,
    bool showEmail = true,
    bool showTable = true,
    String? storeAddress,
    String? storeEmail,
    String? thankYouMessage,
    String? tableNumber,
    String? customerName,
    String? discountLabel,
    bool isDebt = false,
  }) async {
    try {
      debugPrint("Generating PDF for transaction: $transactionId");
      final pdfBytes = await generateReceiptPdf(
        storeName: storeName,
        storeLogoUrl: storeLogoUrl,
        transactionId: transactionId,
        createdAt: createdAt,
        items: items,
        subtotal: subtotal,
        discount: discount,
        discountLabel: discountLabel,
        customerName: customerName,
        pajakAmount: pajakAmount,
        pajakName: pajakName,
        pajakRate: pajakRate,
        totalAmount: totalAmount,
        cashReceived: cashReceived,
        change: change,
        paymentMethod: paymentMethod,
        showStoreName: showStoreName,
        showAddress: showAddress,
        showDate: showDate,
        showDetails: showDetails,
        showThankYou: showThankYou,
        showLogo: showLogo,
        showEmail: showEmail,
        showTable: showTable,
        storeAddress: storeAddress,
        storeEmail: storeEmail,
        thankYouMessage: thankYouMessage,
        tableNumber: tableNumber,
        isDebt: isDebt,
      );

      debugPrint("PDF Generated, size: ${pdfBytes.length} bytes. Triggering Share...");
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'Receipt_$transactionId.pdf',
      );
      debugPrint("Share process finished.");
    } catch (e) {
      debugPrint("Error sharing receipt: $e");
      rethrow;
    }
  }

  Future<Uint8List> generateReceiptPdf({
    required String storeName,
    String? storeLogoUrl,
    required String transactionId,
    required DateTime createdAt,
    required List<Map<String, dynamic>> items,
    required double subtotal,
    required double discount,
    required double pajakAmount,
    required String pajakName,
    double? pajakRate,
    required double totalAmount,
    required double cashReceived,
    required double change,
    required String paymentMethod,
    bool showStoreName = true,
    bool showAddress = true,
    bool showDate = true,
    bool showDetails = true,
    bool showThankYou = true,
    bool showLogo = true,
    bool showEmail = true,
    bool showTable = true,
    String? storeAddress,
    String? storeEmail,
    String? thankYouMessage,
    String? tableNumber,
    String? customerName,
    String? discountLabel,
    bool isDebt = false,
  }) async {
    final robotoMono = await PdfGoogleFonts.robotoMonoRegular();
    final robotoMonoBold = await PdfGoogleFonts.robotoMonoMedium();
    final robotoMonoItalic = await PdfGoogleFonts.robotoMonoItalic();

    final displayId = (transactionId.length > 8)
        ? transactionId.substring(0, 8).toUpperCase()
        : transactionId.toUpperCase();

    final pdf = pw.Document();

    // 1. Load logo if requested with full fallback support
    pw.ImageProvider? logoImage;
    if (showLogo) {
      if (storeLogoUrl != null && storeLogoUrl.trim().isNotEmpty) {
        final path = storeLogoUrl.trim();
        try {
          if (path.startsWith('http://') || path.startsWith('https://')) {
            final response = await http.get(Uri.parse(path));
            if (response.statusCode == 200) {
              logoImage = pw.MemoryImage(response.bodyBytes);
            }
          } else if (path.startsWith('assets/')) {
            final byteData = await rootBundle.load(path);
            logoImage = pw.MemoryImage(byteData.buffer.asUint8List());
          } else {
            // Local file system
            final file = File(path);
            if (await file.exists()) {
              final bytes = await file.readAsBytes();
              logoImage = pw.MemoryImage(bytes);
            } else {
              final bytes = await FileManager().readBytes(path);
              if (bytes != null) {
                logoImage = pw.MemoryImage(bytes);
              }
            }
          }
        } catch (e) {
          debugPrint("Error loading store logo ($path): $e");
        }
      }

      // Default fallback to OMNI POS app logo
      if (logoImage == null) {
        try {
          final byteData = await rootBundle.load('assets/logo/logo.png');
          logoImage = pw.MemoryImage(byteData.buffer.asUint8List());
        } catch (e) {
          debugPrint("Error loading fallback asset logo: $e");
        }
      }
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80, // Classic 80mm roll width
        margin: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        theme: pw.ThemeData.withFont(
          base: robotoMono,
          bold: robotoMonoBold,
          italic: robotoMonoItalic,
        ),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // 1. HEADER (LOGO & STORE INFO)
              if (showLogo && logoImage != null)
                pw.Container(
                  width: 36,
                  height: 36,
                  margin: const pw.EdgeInsets.only(bottom: 6),
                  child: pw.ClipOval(
                    child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                  ),
                ),

              if (showStoreName)
                pw.Text(
                  storeName.toUpperCase(),
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 10.5,
                  ),
                ),

              if (showAddress && storeAddress != null && storeAddress.trim().isNotEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 2),
                  child: pw.Text(
                    storeAddress.trim(),
                    textAlign: pw.TextAlign.center,
                    style: const pw.TextStyle(fontSize: 7.5),
                  ),
                ),

              if (showEmail && storeEmail != null && storeEmail.trim().isNotEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 1),
                  child: pw.Text(
                    storeEmail.trim(),
                    textAlign: pw.TextAlign.center,
                    style: const pw.TextStyle(fontSize: 7.5),
                  ),
                ),

              _dashedDivider(isBold: false),

              // 2. TRANSACTION INFO
              _infoRow("ID Trans", "#$displayId"),
              if (showDate) ...[
                _infoRow("Tanggal", DateFormat('dd/MM/yyyy').format(createdAt)),
                _infoRow("Waktu", DateFormat('HH:mm').format(createdAt)),
              ],

              if (showTable && tableNumber != null && tableNumber.isNotEmpty) ...[
                _infoRow("Meja", tableNumber),
              ],
              if (customerName != null && customerName.trim().isNotEmpty) ...[
                _infoRow("Pelanggan", customerName.trim()),
              ],

              _dashedDivider(isBold: false),

              // 3. ITEMS LIST
              if (showDetails) ...[
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("ITEM", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                    pw.Text("TOTAL", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                  ],
                ),
                pw.SizedBox(height: 3),
                for (var item in items) ...[
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 5),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          (item['name'] ?? item['productName'] ?? 'Item').toString().toUpperCase(),
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
                        ),
                        if (item['notes'] != null && item['notes'].toString().trim().isNotEmpty)
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(bottom: 1),
                            child: pw.Text(
                              "(${item['notes'].toString().trim()})",
                              style: pw.TextStyle(fontSize: 7, fontStyle: pw.FontStyle.italic),
                            ),
                          ),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              "${item['quantity']} x ${_currencyFormat.format(item['unit_price'] ?? item['base_price'] ?? (item['total_price'] / item['quantity']))}",
                              style: const pw.TextStyle(fontSize: 7.5),
                            ),
                            pw.Text(
                              _currencyFormat.format(item['total_price'] ?? 0),
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
                _dashedDivider(isBold: false),
              ],

              // 4. FINANCIAL SUMMARY
              _summaryRow("Subtotal", subtotal, fontSize: 8),
              if (discount > 0)
                _summaryRow(
                  discountLabel != null && discountLabel.trim().isNotEmpty
                      ? discountLabel.trim()
                      : "Diskon",
                  "-${_currencyFormat.format(discount)}",
                  fontSize: 8,
                  isValueOnly: true,
                ),
              if (pajakAmount > 0) ...[
                _summaryRow(
                  pajakRate != null && pajakRate > 0
                      ? "${pajakName.isNotEmpty ? pajakName : "Pajak"} (${pajakRate.toStringAsFixed(0)}%)"
                      : (pajakName.isNotEmpty ? pajakName : "Pajak"),
                  pajakAmount,
                  fontSize: 8,
                ),
              ],

              pw.SizedBox(height: 3),
              _summaryRow("TOTAL", totalAmount, isBold: true, fontSize: 10),

              _dashedDivider(isBold: true),

              // 5. PAYMENT DETAILS
              _summaryRow("Metode Pembayaran", paymentMethod, fontSize: 8, isValueOnly: true),
              _summaryRow("Dibayar", cashReceived, fontSize: 8),
              if (isDebt)
                _summaryRow("Hutang", totalAmount - cashReceived, fontSize: 8)
              else if (change > 0)
                _summaryRow("Kembali", change, fontSize: 8),

              _dashedDivider(isBold: false),

              // 6. FOOTER
              if (showThankYou) ...[
                pw.SizedBox(height: 6),
                pw.Text(
                  "TERIMA KASIH",
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9.5),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  (thankYouMessage != null && thankYouMessage.trim().isNotEmpty
                          ? thankYouMessage.trim()
                          : "ATAS KUNJUNGAN ANDA")
                      .toUpperCase(),
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 6),
              ],

              if (showTable && tableNumber != null && tableNumber.isNotEmpty) ...[
                pw.SizedBox(height: 8),
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.black, width: 1.5),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        "NOMOR MEJA",
                        style: pw.TextStyle(
                          fontSize: 8.5,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        tableNumber.toUpperCase(),
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 4),
              ],

              pw.SizedBox(height: 6),
              pw.Text(
                "DIHASILKAN OLEH SISTEM OMNI POS",
                style: pw.TextStyle(
                  fontSize: 6,
                  fontStyle: pw.FontStyle.italic,
                  color: PdfColors.grey700,
                ),
              ),
              pw.SizedBox(height: 8),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _dashedDivider({bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6),
      child: pw.Divider(
        thickness: isBold ? 1.0 : 0.6,
        borderStyle: pw.BorderStyle.dashed,
        color: PdfColors.black,
      ),
    );
  }

  pw.Widget _infoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
          pw.Text(value, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  pw.Widget _summaryRow(
    String label,
    dynamic value, {
    bool isBold = false,
    double fontSize = 8,
    bool isValueOnly = false,
  }) {
    final String valueStr = isValueOnly ? value.toString() : _currencyFormat.format(value);
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: isBold ? 10 : fontSize,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: isBold ? PdfColors.black : PdfColors.grey700,
            ),
          ),
          pw.Text(
            valueStr,
            style: pw.TextStyle(
              fontSize: isBold ? 10 : fontSize,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
