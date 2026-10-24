import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'app_database.dart';

class ExportService {
  final _currencyFormat = NumberFormat.currency(
    locale: 'id',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  /// Generates a PDF document for a list of transactions
  Future<Uint8List> generateTransactionsPdf(
    String storeName,
    List<Transaction> transactions,
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                "Laporan Transaksi",
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                storeName,
                style: const pw.TextStyle(
                  fontSize: 14,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            "Dicetak pada: ${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now())}",
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
          ),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            headers: ['Tanggal', 'ID Transaksi', 'Metode', 'Total'],
            data: transactions.map((tx) {
              return [
                DateFormat(
                  'dd MMM yyyy, HH:mm',
                ).format(tx.createdAt ?? DateTime.now()),
                (tx.id).substring(0, 8), // Short ID for table
                (tx.paymentMethod ?? 'Unknown').toUpperCase(),
                _currencyFormat.format(tx.totalAmount ?? 0),
              ];
            }).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellAlignment: pw.Alignment.centerLeft,
            cellAlignments: {3: pw.Alignment.centerRight},
          ),
          pw.SizedBox(height: 20),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Text(
                "Total Omzet: ",
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                _currencyFormat.format(
                  transactions.fold(
                    0.0,
                    (sum, tx) => sum + (tx.totalAmount ?? 0),
                  ),
                ),
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );

    return pdf.save();
  }

  /// Generates an Excel document for a list of transactions
  Future<Uint8List> generateTransactionsExcel(
    String storeName,
    List<Transaction> transactions,
  ) async {
    var excel = Excel.createExcel();
    var sheetName = "Transaksi";
    excel.rename("Sheet1", sheetName);
    var sheet = excel[sheetName];

    // Header Info
    sheet.appendRow([TextCellValue("Laporan Transaksi - $storeName")]);
    sheet.appendRow([
      TextCellValue(
        "Dicetak pada: ${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now())}",
      ),
    ]);
    sheet.appendRow([]); // Spacer

    // Table Header
    sheet.appendRow([
      TextCellValue("Tanggal"),
      TextCellValue("ID Transaksi"),
      TextCellValue("Metode Pembayaran"),
      TextCellValue("Total Amount"),
    ]);

    // Data
    for (var tx in transactions) {
      sheet.appendRow([
        TextCellValue(
          DateFormat('yyyy-MM-dd HH:mm').format(tx.createdAt ?? DateTime.now()),
        ),
        TextCellValue(tx.id),
        TextCellValue((tx.paymentMethod ?? 'Unknown').toUpperCase()),
        DoubleCellValue(tx.totalAmount ?? 0.0),
      ]);
    }

    // Total
    sheet.appendRow([]);
    double total = transactions.fold(
      0.0,
      (sum, tx) => sum + (tx.totalAmount ?? 0),
    );
    sheet.appendRow([
      TextCellValue(""),
      TextCellValue(""),
      TextCellValue("TOTAL OMZET"),
      DoubleCellValue(total),
    ]);

    return Uint8List.fromList(excel.encode()!);
  }

  /// Generates a PDF summary for Profit & Loss data
  Future<Uint8List> generateProfitLossPdf(
    String storeName,
    int year,
    Map<int, double> weeklyProfit,
    double totalProfit,
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              "Laporan Laba Rugi $year",
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Text(storeName),
            pw.Divider(),
            pw.SizedBox(height: 20),
            pw.Text(
              "Ringkasan Mingguan",
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              headers: ['Minggu Ke-', 'Profit / Laba'],
              data: weeklyProfit.entries
                  .map(
                    (e) => ["Minggu ${e.key}", _currencyFormat.format(e.value)],
                  )
                  .toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellAlignments: {1: pw.Alignment.centerRight},
            ),
            pw.SizedBox(height: 20),
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  "TOTAL LABA BERSIH TAHUN $year",
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  _currencyFormat.format(totalProfit),
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  /// Generates an Excel summary for Profit & Loss data
  Future<Uint8List> generateProfitLossExcel(
    String storeName,
    int year,
    Map<int, double> weeklyProfit,
    double totalProfit,
  ) async {
    var excel = Excel.createExcel();
    var sheetName = "Profit Loss $year";
    excel.rename("Sheet1", sheetName);
    var sheet = excel[sheetName];

    sheet.appendRow([TextCellValue("Laporan Laba Rugi $year - $storeName")]);
    sheet.appendRow([]);
    sheet.appendRow([
      TextCellValue("Minggu Ke-"),
      TextCellValue("Profit / Laba"),
    ]);

    weeklyProfit.forEach((week, profit) {
      sheet.appendRow([TextCellValue("Minggu $week"), DoubleCellValue(profit)]);
    });

    sheet.appendRow([]);
    sheet.appendRow([
      TextCellValue("TOTAL LABA"),
      DoubleCellValue(totalProfit),
    ]);

    return Uint8List.fromList(excel.encode()!);
  }

  /// Generates an Excel document for a list of products
  Future<Uint8List> generateProductsExcel(
    String storeName,
    List<Product> products,
  ) async {
    var excel = Excel.createExcel();
    var sheetName = "Produk";
    excel.rename("Sheet1", sheetName);
    var sheet = excel[sheetName];

    // Header Info
    sheet.appendRow([TextCellValue("Daftar Produk - $storeName")]);
    sheet.appendRow([
      TextCellValue(
        "Dicetak pada: ${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now())}",
      ),
    ]);
    sheet.appendRow([]); // Spacer

    // Table Header
    sheet.appendRow([
      TextCellValue("Nama Produk"),
      TextCellValue("Kategori"),
      TextCellValue("Harga Beli (Base)"),
      TextCellValue("Harga Jual"),
      TextCellValue("Stok"),
      TextCellValue("Satuan"),
    ]);

    // Data
    for (var p in products) {
      sheet.appendRow([
        TextCellValue(p.name ?? '-'),
        TextCellValue(p.categoryId ?? '-'),
        DoubleCellValue(p.basePrice ?? 0.0),
        DoubleCellValue(p.salePrice ?? 0.0),
        DoubleCellValue(p.stockQuantity ?? 0.0),
        TextCellValue('pcs'), // Default unit
      ]);
    }

    return Uint8List.fromList(excel.encode()!);
  }

  /// Generates a comprehensive financial report
  Future<Uint8List> generateFinancialReportExcel({
    required String storeName,
    required List<Transaction> transactions,
    required List<Expense> expenses,
  }) async {
    var excel = Excel.createExcel();

    // 1. Summary Sheet
    var summarySheetName = "Ringkasan";
    excel.rename("Sheet1", summarySheetName);
    var summary = excel[summarySheetName];

    double totalSales = transactions.fold(
      0,
      (sum, tx) => sum + (tx.totalAmount ?? 0),
    );
    double totalExpenses = expenses.fold(
      0,
      (sum, ex) => sum + (ex.amount ?? 0),
    );

    summary.appendRow([
      TextCellValue("Laporan Keuangan Komprehensif - $storeName"),
    ]);
    summary.appendRow([TextCellValue("Periode: Semua Waktu")]);
    summary.appendRow([]);
    summary.appendRow([TextCellValue("RINGKASAN"), TextCellValue("TOTAL")]);
    summary.appendRow([
      TextCellValue("Total Pemasukan"),
      DoubleCellValue(totalSales),
    ]);
    summary.appendRow([
      TextCellValue("Total Pengeluaran"),
      DoubleCellValue(totalExpenses),
    ]);
    summary.appendRow([
      TextCellValue("Laba Bersih"),
      DoubleCellValue(totalSales - totalExpenses),
    ]);

    // 2. Transactions Sheet
    var txSheetName = "Transaksi_Detail";
    var txSheet = excel[txSheetName];
    txSheet.appendRow([
      TextCellValue("Tanggal"),
      TextCellValue("ID"),
      TextCellValue("Metode"),
      TextCellValue("Total"),
    ]);
    for (var tx in transactions) {
      txSheet.appendRow([
        TextCellValue(
          DateFormat('yyyy-MM-dd HH:mm').format(tx.createdAt ?? DateTime.now()),
        ),
        TextCellValue(tx.id),
        TextCellValue(tx.paymentMethod ?? '-'),
        DoubleCellValue(tx.totalAmount ?? 0),
      ]);
    }

    // 3. Expenses Sheet
    var expSheetName = "Pengeluaran_Detail";
    var expSheet = excel[expSheetName];
    expSheet.appendRow([
      TextCellValue("Tanggal"),
      TextCellValue("Kategori"),
      TextCellValue("Keterangan"),
      TextCellValue("Jumlah"),
    ]);
    for (var ex in expenses) {
      expSheet.appendRow([
        TextCellValue(
          DateFormat('yyyy-MM-dd HH:mm').format(ex.date ?? DateTime.now()),
        ),
        TextCellValue(ex.category),
        TextCellValue(ex.notes ?? '-'),
        DoubleCellValue(ex.amount ?? 0),
      ]);
    }

    return Uint8List.fromList(excel.encode()!);
  }

  /// Generates a comprehensive financial report in PDF
  Future<Uint8List> generateFinancialReportPdf({
    required String storeName,
    required List<Transaction> transactions,
    required List<Expense> expenses,
  }) async {
    final pdf = pw.Document();

    double totalSales = transactions.fold(
      0,
      (sum, tx) => sum + (tx.totalAmount ?? 0),
    );
    double totalExpenses = expenses.fold(
      0,
      (sum, ex) => sum + (ex.amount ?? 0),
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  "Laporan Keuangan Keseluruhan",
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(storeName, style: const pw.TextStyle(fontSize: 12)),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // summary section
          pw.Text(
            "RINGKASAN",
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.Divider(),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text("Total Pemasukan (Omzet)"),
              pw.Text(
                _currencyFormat.format(totalSales),
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text("Total Pengeluaran"),
              pw.Text(
                _currencyFormat.format(totalExpenses),
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.red,
                ),
              ),
            ],
          ),
          pw.Divider(),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text("LABA BERSIH"),
              pw.Text(
                _currencyFormat.format(totalSales - totalExpenses),
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 14,
                  color: (totalSales - totalExpenses) >= 0
                      ? PdfColors.green
                      : PdfColors.red,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 30),

          // Transactions List
          pw.Text(
            "DETAIL PEMASUKAN",
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            headers: ['Tanggal', 'ID', 'Metode', 'Total'],
            data: transactions.map((tx) {
              return [
                DateFormat(
                  'dd/MM/yy HH:mm',
                ).format(tx.createdAt ?? DateTime.now()),
                tx.id.substring(0, 8),
                (tx.paymentMethod ?? '-').toUpperCase(),
                _currencyFormat.format(tx.totalAmount ?? 0),
              ];
            }).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.centerLeft,
            cellAlignments: {3: pw.Alignment.centerRight},
          ),
          pw.SizedBox(height: 30),

          // Expenses List
          pw.Text(
            "DETAIL PENGELUARAN",
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            headers: ['Tanggal', 'Kategori', 'Keterangan', 'Jumlah'],
            data: expenses.map((ex) {
              return [
                DateFormat('dd/MM/yy HH:mm').format(ex.date ?? DateTime.now()),
                ex.category,
                ex.notes ?? '-',
                _currencyFormat.format(ex.amount ?? 0),
              ];
            }).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.centerLeft,
            cellAlignments: {3: pw.Alignment.centerRight},
          ),
          pw.Footer(
            margin: const pw.EdgeInsets.only(top: 20),
            padding: const pw.EdgeInsets.only(top: 10),
            decoration: const pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300)),
            ),
            trailing: pw.Text(
              "Dicetak pada: ${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now())}",
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }
}
