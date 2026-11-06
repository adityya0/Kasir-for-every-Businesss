import 'dart:convert';
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
    List<Transaction> transactions, {
    String? periodLabel,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final pdf = pw.Document();

    String periodText = periodLabel ?? "Semua Transaksi";
    if (startDate != null && endDate != null) {
      final s = DateFormat('dd/MM/yyyy').format(startDate);
      final e = DateFormat('dd/MM/yyyy').format(endDate);
      if (s == e) {
        periodText = "Hari Ini ($s)";
      } else {
        periodText = "$periodText ($s - $e)";
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    "Laporan Transaksi",
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    "Periode: $periodText",
                    style: const pw.TextStyle(
                      fontSize: 11,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
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
    List<Transaction> transactions, {
    String? periodLabel,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var excel = Excel.createExcel();
    var sheetName = "Transaksi";
    excel.rename("Sheet1", sheetName);
    var sheet = excel[sheetName];

    String periodText = periodLabel ?? "Semua Transaksi";
    if (startDate != null && endDate != null) {
      final s = DateFormat('dd/MM/yyyy').format(startDate);
      final e = DateFormat('dd/MM/yyyy').format(endDate);
      if (s == e) {
        periodText = "Hari Ini ($s)";
      } else {
        periodText = "$periodText ($s - $e)";
      }
    }

    // Header Info
    sheet.appendRow([TextCellValue("Laporan Transaksi - $storeName")]);
    sheet.appendRow([TextCellValue("Periode: $periodText")]);
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
    List<Map<String, dynamic>>? supplierReports,
    String? periodLabel,
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

    // 4. Supplier Sheet (if available)
    if (supplierReports != null && supplierReports.isNotEmpty) {
      var supSheet = excel["Supplier_Pasokan"];
      supSheet.appendRow([
        TextCellValue("Nama Supplier"),
        TextCellValue("Kontak"),
        TextCellValue("Barang Dipasok"),
        TextCellValue("Qty Terjual (Pcs)"),
        TextCellValue("Biaya Modal/Pasok"),
        TextCellValue("Omset Penjualan"),
        TextCellValue("Laba Bersih"),
      ]);
      for (var s in supplierReports) {
        final cost = (s['totalCost'] as num?)?.toDouble() ?? 0.0;
        final gross = (s['totalGross'] as num?)?.toDouble() ?? 0.0;
        final profit = (s['netProfit'] as num?)?.toDouble() ?? (gross - cost);
        supSheet.appendRow([
          TextCellValue(s['supplierName']?.toString() ?? ''),
          TextCellValue(s['phone']?.toString() ?? '-'),
          TextCellValue(s['productNames']?.toString() ?? '-'),
          IntCellValue((s['totalQtySold'] as num?)?.toInt() ?? 0),
          DoubleCellValue(cost),
          DoubleCellValue(gross),
          DoubleCellValue(profit),
        ]);
      }
    }

    return Uint8List.fromList(excel.encode()!);
  }

  /// Generates a comprehensive financial report in PDF
  Future<Uint8List> generateFinancialReportPdf({
    required String storeName,
    required List<Transaction> transactions,
    required List<Expense> expenses,
    List<Map<String, dynamic>>? supplierReports,
    String? periodLabel,
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
                  periodLabel != null
                      ? "Laporan Keuangan ($periodLabel)"
                      : "Laporan Keuangan Keseluruhan",
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
          if (supplierReports != null && supplierReports.isNotEmpty) ...[
            pw.SizedBox(height: 30),
            pw.Text(
              "DETAIL PASOKAN & BIAYA SUPPLIER",
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              headers: ['Supplier', 'Barang Dipasok', 'Terjual', 'Modal', 'Omset', 'Laba Bersih'],
              data: supplierReports.map((s) {
                final cost = (s['totalCost'] as num?)?.toDouble() ?? 0.0;
                final gross = (s['totalGross'] as num?)?.toDouble() ?? 0.0;
                final profit = (s['netProfit'] as num?)?.toDouble() ?? (gross - cost);
                return [
                  s['supplierName']?.toString() ?? '',
                  s['productNames']?.toString() ?? '-',
                  "${s['totalQtySold'] ?? 0} pcs",
                  _currencyFormat.format(cost),
                  _currencyFormat.format(gross),
                  _currencyFormat.format(profit),
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellAlignment: pw.Alignment.centerLeft,
              cellAlignments: {
                2: pw.Alignment.centerRight,
                3: pw.Alignment.centerRight,
                4: pw.Alignment.centerRight,
                5: pw.Alignment.centerRight,
              },
            ),
          ],
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

  /// Generates a CSV for Profit & Loss data
  Uint8List generateProfitLossCsv({
    required String storeName,
    required DateTime startDate,
    required DateTime endDate,
    required double sales,
    required double cogs,
    required double grossProfit,
    required Map<String, double> expensesByCategory,
    required double totalExpenses,
    required double netProfit,
    required int txCount,
  }) {
    final fmt = DateFormat('yyyy-MM-dd');
    final sb = StringBuffer();
    sb.writeln('"Laporan Laba Rugi - $storeName"');
    sb.writeln('"Periode:","${fmt.format(startDate)} s/d ${fmt.format(endDate)}"');
    sb.writeln('');
    sb.writeln('"RINGKASAN","Jumlah (Rp)"');
    sb.writeln('"Total Penjualan / Omzet",$sales');
    sb.writeln('"Harga Pokok Penjualan (HPP)",-$cogs');
    sb.writeln('"Laba Kotor",$grossProfit');
    sb.writeln('');
    sb.writeln('"BEBAN PENGELUARAN","Jumlah (Rp)"');
    expensesByCategory.forEach((cat, amt) {
      sb.writeln('"$cat",-$amt');
    });
    sb.writeln('"Total Pengeluaran",-$totalExpenses');
    sb.writeln('');
    sb.writeln('"LABA BERSIH",$netProfit');
    sb.writeln('"Total Transaksi Selesai",$txCount');
    return Uint8List.fromList(utf8.encode(sb.toString()));
  }

  Uint8List generateCashFlowCsv({
    required String storeName,
    required DateTime startDate,
    required DateTime endDate,
    double? penjualanTunaiDP,
    double? terimaPiutang,
    double? setorModal,
    double? pemasukanLain,
    double? biaya,
    double? prive,
    double? pembelianTunaiDP,
    double? bayarHutang,
    double cashSales = 0.0,
    double digitalSales = 0.0,
    double operationalExpenses = 0.0,
    double salaryExpenses = 0.0,
    required double totalCashIn,
    required double totalCashOut,
    required double netCashFlow,
    String? accountBalancesNote,
  }) {
    final fmt = DateFormat('yyyy-MM-dd');
    final sb = StringBuffer();
    sb.writeln('"Laporan Arus Kas - $storeName"');
    sb.writeln('"Periode:","${fmt.format(startDate)} s/d ${fmt.format(endDate)}"');
    sb.writeln('');
    sb.writeln('"Pos Arus Kas","Jumlah (Rp)"');
    if (penjualanTunaiDP != null) {
      if (penjualanTunaiDP > 0) {
        sb.writeln('"Penjualan tunai/DP",+$penjualanTunaiDP');
      }
      if (terimaPiutang != null && terimaPiutang > 0) {
        sb.writeln('"Terima Piutang",+$terimaPiutang');
      }
      if (setorModal != null && setorModal > 0) {
        sb.writeln('"Setor Modal",+$setorModal');
      }
      if (pemasukanLain != null && pemasukanLain > 0) {
        sb.writeln('"Pemasukan Lain",+$pemasukanLain');
      }
      if (biaya != null && biaya > 0) {
        sb.writeln('"Biaya",-$biaya');
      }
      if (prive != null && prive > 0) {
        sb.writeln('"Prive / Pribadi",-$prive');
      }
      if (pembelianTunaiDP != null && pembelianTunaiDP > 0) {
        sb.writeln('"Pembelian tunai/DP",-$pembelianTunaiDP');
      }
      if (bayarHutang != null && bayarHutang > 0) {
        sb.writeln('"Bayar Hutang",-$bayarHutang');
      }
    } else {
      sb.writeln('"Penjualan Kas / Tunai",+$cashSales');
      sb.writeln('"Penjualan Non-Tunai / Digital",+$digitalSales');
      sb.writeln('"Biaya Operasional",-$operationalExpenses');
      if (salaryExpenses > 0) {
        sb.writeln('"Gaji & Upah Pegawai",-$salaryExpenses');
      }
    }
    sb.writeln('');
    sb.writeln('"Kas Masuk",$totalCashIn');
    sb.writeln('"Kas Keluar",-$totalCashOut');
    sb.writeln('"Arus Kas Bersih",$netCashFlow');
    if (accountBalancesNote != null && accountBalancesNote.isNotEmpty) {
      sb.writeln('');
      sb.writeln('"$accountBalancesNote"');
    }
    return Uint8List.fromList(utf8.encode(sb.toString()));
  }

  /// Generates a PDF for Cash Flow (Arus Kas) data
  Future<Uint8List> generateCashFlowPdf({
    required String storeName,
    required DateTime startDate,
    required DateTime endDate,
    double? penjualanTunaiDP,
    double? terimaPiutang,
    double? setorModal,
    double? pemasukanLain,
    double? biaya,
    double? prive,
    double? pembelianTunaiDP,
    double? bayarHutang,
    required double totalCashIn,
    required double totalCashOut,
    required double netCashFlow,
    String? accountBalancesNote,
  }) async {
    final pdf = pw.Document();
    final fmt = DateFormat('yyyy-MM-dd');

    final tableData = <List<String>>[];
    if (penjualanTunaiDP != null && penjualanTunaiDP > 0) {
      tableData.add(["Penjualan tunai/DP", "+ ${_currencyFormat.format(penjualanTunaiDP)}"]);
    }
    if (terimaPiutang != null && terimaPiutang > 0) {
      tableData.add(["Terima Piutang", "+ ${_currencyFormat.format(terimaPiutang)}"]);
    }
    if (setorModal != null && setorModal > 0) {
      tableData.add(["Setor Modal", "+ ${_currencyFormat.format(setorModal)}"]);
    }
    if (pemasukanLain != null && pemasukanLain > 0) {
      tableData.add(["Pemasukan Lain", "+ ${_currencyFormat.format(pemasukanLain)}"]);
    }
    if (biaya != null && biaya > 0) {
      tableData.add(["Biaya Operasional", "- ${_currencyFormat.format(biaya)}"]);
    }
    if (prive != null && prive > 0) {
      tableData.add(["Prive / Pribadi", "- ${_currencyFormat.format(prive)}"]);
    }
    if (pembelianTunaiDP != null && pembelianTunaiDP > 0) {
      tableData.add(["Pembelian tunai/DP", "- ${_currencyFormat.format(pembelianTunaiDP)}"]);
    }
    if (bayarHutang != null && bayarHutang > 0) {
      tableData.add(["Bayar Hutang", "- ${_currencyFormat.format(bayarHutang)}"]);
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              "Laporan Arus Kas",
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Text(storeName, style: const pw.TextStyle(fontSize: 14)),
            pw.Text(
              "Periode: ${fmt.format(startDate)} s/d ${fmt.format(endDate)}",
              style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
            ),
            pw.Divider(),
            pw.SizedBox(height: 12),
            if (tableData.isNotEmpty) ...[
              pw.TableHelper.fromTextArray(
                headers: ['Pos Arus Kas', 'Jumlah'],
                data: tableData,
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerRight,
                },
              ),
              pw.SizedBox(height: 12),
            ],
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("Kas Masuk", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
                pw.Text(_currencyFormat.format(totalCashIn), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
              ],
            ),
            pw.SizedBox(height: 6),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("Kas Keluar", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.red800)),
                pw.Text(_currencyFormat.format(totalCashOut), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.red800)),
              ],
            ),
            pw.SizedBox(height: 6),
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("Arus Kas Bersih", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                pw.Text(
                  _currencyFormat.format(netCashFlow),
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 14,
                    color: netCashFlow >= 0 ? PdfColors.green800 : PdfColors.red800,
                  ),
                ),
              ],
            ),
            if (accountBalancesNote != null && accountBalancesNote.isNotEmpty) ...[
              pw.SizedBox(height: 16),
              pw.Text(
                accountBalancesNote,
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
              ),
            ],
          ],
        ),
      ),
    );

    return pdf.save();
  }

  /// Generates an Excel summary for Cash Flow (Arus Kas) data
  Future<Uint8List> generateCashFlowExcel({
    required String storeName,
    required DateTime startDate,
    required DateTime endDate,
    double? penjualanTunaiDP,
    double? terimaPiutang,
    double? setorModal,
    double? pemasukanLain,
    double? biaya,
    double? prive,
    double? pembelianTunaiDP,
    double? bayarHutang,
    required double totalCashIn,
    required double totalCashOut,
    required double netCashFlow,
    String? accountBalancesNote,
  }) async {
    var excel = Excel.createExcel();
    var sheet = excel["Arus_Kas"];
    excel.delete("Sheet1");

    final fmt = DateFormat('yyyy-MM-dd');
    sheet.appendRow([TextCellValue("Laporan Arus Kas - $storeName")]);
    sheet.appendRow([TextCellValue("Periode: ${fmt.format(startDate)} s/d ${fmt.format(endDate)}")]);
    sheet.appendRow([]);
    sheet.appendRow([TextCellValue("Pos Arus Kas"), TextCellValue("Jumlah (Rp)")]);

    if (penjualanTunaiDP != null && penjualanTunaiDP > 0) {
      sheet.appendRow([TextCellValue("Penjualan tunai/DP"), DoubleCellValue(penjualanTunaiDP)]);
    }
    if (terimaPiutang != null && terimaPiutang > 0) {
      sheet.appendRow([TextCellValue("Terima Piutang"), DoubleCellValue(terimaPiutang)]);
    }
    if (setorModal != null && setorModal > 0) {
      sheet.appendRow([TextCellValue("Setor Modal"), DoubleCellValue(setorModal)]);
    }
    if (pemasukanLain != null && pemasukanLain > 0) {
      sheet.appendRow([TextCellValue("Pemasukan Lain"), DoubleCellValue(pemasukanLain)]);
    }
    if (biaya != null && biaya > 0) {
      sheet.appendRow([TextCellValue("Biaya Operasional"), DoubleCellValue(-biaya)]);
    }
    if (prive != null && prive > 0) {
      sheet.appendRow([TextCellValue("Prive / Pribadi"), DoubleCellValue(-prive)]);
    }
    if (pembelianTunaiDP != null && pembelianTunaiDP > 0) {
      sheet.appendRow([TextCellValue("Pembelian tunai/DP"), DoubleCellValue(-pembelianTunaiDP)]);
    }
    if (bayarHutang != null && bayarHutang > 0) {
      sheet.appendRow([TextCellValue("Bayar Hutang"), DoubleCellValue(-bayarHutang)]);
    }

    sheet.appendRow([]);
    sheet.appendRow([TextCellValue("Kas Masuk"), DoubleCellValue(totalCashIn)]);
    sheet.appendRow([TextCellValue("Kas Keluar"), DoubleCellValue(-totalCashOut)]);
    sheet.appendRow([TextCellValue("Arus Kas Bersih"), DoubleCellValue(netCashFlow)]);

    if (accountBalancesNote != null && accountBalancesNote.isNotEmpty) {
      sheet.appendRow([]);
      sheet.appendRow([TextCellValue(accountBalancesNote)]);
    }

    return Uint8List.fromList(excel.encode()!);
  }

  /// Generates a CSV for Transactions data
  Uint8List generateTransactionsCsv({
    required String storeName,
    required DateTime startDate,
    required DateTime endDate,
    required List<Transaction> transactions,
  }) {
    final fmt = DateFormat('yyyy-MM-dd HH:mm');
    final sb = StringBuffer();
    sb.writeln('"Laporan Transaksi - $storeName"');
    sb.writeln('"Periode:","${DateFormat('yyyy-MM-dd').format(startDate)} s/d ${DateFormat('yyyy-MM-dd').format(endDate)}"');
    sb.writeln('');
    sb.writeln('"Tanggal","ID Transaksi","Metode","Total (Rp)"');
    for (var tx in transactions) {
      final dt = tx.createdAt != null ? fmt.format(tx.createdAt!) : '-';
      final pMethod = (tx.paymentMethod ?? '-').toUpperCase();
      final totalStr = (tx.totalAmount ?? 0).toStringAsFixed(0);
      sb.writeln('"$dt","${tx.id}","$pMethod",$totalStr');
    }
    final total = transactions.fold(0.0, (sum, tx) => sum + (tx.totalAmount ?? 0));
    sb.writeln('');
    sb.writeln('"TOTAL","","",$total');
    return Uint8List.fromList(utf8.encode(sb.toString()));
  }

  Uint8List generateFinancialReportCsv({
    required String storeName,
    required List<Transaction> transactions,
    required List<Expense> expenses,
    List<Map<String, dynamic>>? supplierReports,
    String? periodLabel,
  }) {
    final sb = StringBuffer();
    final totalSales = transactions.fold(0.0, (sum, tx) => sum + (tx.totalAmount ?? 0.0));
    final totalExpenses = expenses.fold(0.0, (sum, ex) => sum + (ex.amount ?? 0.0));
    final netProfit = totalSales - totalExpenses;

    sb.writeln('"LAPORAN KEUANGAN KESELURUHAN (ALL TIME) - $storeName"');
    sb.writeln('"Dicetak Pada: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}"');
    sb.writeln('');
    sb.writeln('"RINGKASAN KEUANGAN"');
    sb.writeln('"Total Pemasukan (Omzet)",${totalSales.toStringAsFixed(0)}');
    sb.writeln('"Total Pengeluaran",-${totalExpenses.toStringAsFixed(0)}');
    sb.writeln('"LABA BERSIH",${netProfit.toStringAsFixed(0)}');
    sb.writeln('');
    sb.writeln('"DETAIL PENGELUARAN (${expenses.length} Transaksi)"');
    sb.writeln('"Tanggal","Kategori","Keterangan","Jumlah"');
    for (var ex in expenses) {
      final date = DateFormat('yyyy-MM-dd HH:mm').format(ex.date ?? DateTime.now());
      final cat = ex.category.replaceAll('"', '""');
      final note = (ex.notes ?? '-').replaceAll('"', '""');
      final amt = ex.amount ?? 0;
      sb.writeln('"$date","$cat","$note",-$amt');
    }
    sb.writeln('');
    sb.writeln('"DETAIL PEMASUKAN / PENJUALAN (${transactions.length} Transaksi)"');
    sb.writeln('"Tanggal","ID Transaksi","Metode Pembayaran","Total"');
    for (var tx in transactions) {
      final date = DateFormat('yyyy-MM-dd HH:mm').format(tx.createdAt ?? DateTime.now());
      final id = tx.id;
      final method = (tx.paymentMethod ?? '-').toUpperCase();
      final amt = tx.totalAmount ?? 0;
      sb.writeln('"$date","$id","$method",$amt');
    }

    if (supplierReports != null && supplierReports.isNotEmpty) {
      sb.writeln('');
      sb.writeln('"DETAIL PASOKAN & BIAYA SUPPLIER (${supplierReports.length} Supplier)"');
      sb.writeln('"Supplier","Kontak","Barang Dipasok","Qty Terjual","Total Biaya Modal","Total Omset","Laba Bersih"');
      for (var s in supplierReports) {
        final supName = (s['supplierName']?.toString() ?? '').replaceAll('"', '""');
        final phone = (s['phone']?.toString() ?? '-').replaceAll('"', '""');
        final prods = (s['productNames']?.toString() ?? '-').replaceAll('"', '""');
        final qty = s['totalQtySold'] ?? 0;
        final cost = (s['totalCost'] as num?)?.toDouble() ?? 0.0;
        final gross = (s['totalGross'] as num?)?.toDouble() ?? 0.0;
        final profit = (s['netProfit'] as num?)?.toDouble() ?? (gross - cost);
        sb.writeln('"$supName","$phone","$prods",$qty,$cost,$gross,$profit');
      }
    }

    return Uint8List.fromList(utf8.encode(sb.toString()));
  }

  /// Generates Supplier Settlements History Report in Excel
  Future<Uint8List> generateSupplierSettlementsExcel({
    required String storeName,
    required List<Map<String, dynamic>> settlements,
    String? periodLabel,
  }) async {
    var excel = Excel.createExcel();
    var sheetName = "Riwayat_Pelunasan";
    excel.rename("Sheet1", sheetName);
    var sheet = excel[sheetName];

    sheet.appendRow([
      TextCellValue("LAPORAN RIWAYAT PELUNASAN SUPPLIER - $storeName"),
    ]);
    if (periodLabel != null) {
      sheet.appendRow([TextCellValue("Periode: $periodLabel")]);
    }
    sheet.appendRow([
      TextCellValue("Dicetak: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}"),
    ]);
    sheet.appendRow([]);

    // Header Tabel
    sheet.appendRow([
      TextCellValue("No"),
      TextCellValue("Tanggal & Jam"),
      TextCellValue("Nama Supplier"),
      TextCellValue("Metode Pembayaran"),
      TextCellValue("Catatan / Ref"),
      TextCellValue("Nominal Pelunasan (Rp)"),
    ]);

    double total = 0.0;
    int no = 1;
    for (var s in settlements) {
      final amt = (s['amount'] as num?)?.toDouble() ?? 0.0;
      total += amt;
      sheet.appendRow([
        IntCellValue(no++),
        TextCellValue(s['date']?.toString() ?? '-'),
        TextCellValue(s['supplierName']?.toString() ?? '-'),
        TextCellValue(s['paymentMethod']?.toString() ?? '-'),
        TextCellValue(s['notes']?.toString() ?? '-'),
        DoubleCellValue(amt),
      ]);
    }

    sheet.appendRow([]);
    sheet.appendRow([
      TextCellValue("TOTAL PELUNASAN"),
      TextCellValue(""),
      TextCellValue(""),
      TextCellValue(""),
      TextCellValue(""),
      DoubleCellValue(total),
    ]);

    return Uint8List.fromList(excel.encode()!);
  }

  /// Generates Supplier Settlements History Report in PDF
  Future<Uint8List> generateSupplierSettlementsPdf({
    required String storeName,
    required List<Map<String, dynamic>> settlements,
    String? periodLabel,
  }) async {
    final pdf = pw.Document();
    final double totalAmount = settlements.fold(
      0.0,
      (sum, s) => sum + ((s['amount'] as num?)?.toDouble() ?? 0.0),
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
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      "Laporan Riwayat Pelunasan Supplier",
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    if (periodLabel != null)
                      pw.Text(
                        "Periode: $periodLabel",
                        style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
                      ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(storeName, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                    pw.Text(
                      DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 12),

          // Total Summary Banner
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.green50,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: PdfColors.green200),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  "Total Pembayaran Pelunasan:",
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  _currencyFormat.format(totalAmount),
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green800,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          // Table
          pw.TableHelper.fromTextArray(
            headers: ["No", "Tanggal", "Supplier", "Metode", "Catatan", "Nominal (Rp)"],
            data: List<List<String>>.generate(
              settlements.length,
              (index) {
                final item = settlements[index];
                final amt = (item['amount'] as num?)?.toDouble() ?? 0.0;
                return [
                  (index + 1).toString(),
                  item['date']?.toString() ?? '-',
                  item['supplierName']?.toString() ?? '-',
                  item['paymentMethod']?.toString() ?? '-',
                  item['notes']?.toString() ?? '-',
                  _currencyFormat.format(amt),
                ];
              },
            ),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.green700),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellAlignment: pw.Alignment.centerLeft,
            cellAlignments: {
              0: pw.Alignment.center,
              5: pw.Alignment.centerRight,
            },
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          ),
        ],
      ),
    );

    return pdf.save();
  }
}
