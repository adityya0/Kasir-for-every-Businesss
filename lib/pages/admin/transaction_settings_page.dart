import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../controllers/admin_controller.dart';
import '../../controllers/settings_controller.dart';
import 'payment_settings_page.dart';
import '../../controllers/analytics_controller.dart';
import '../../services/receipt_service.dart';
import '../user/widgets/receipt_preview_page.dart';

class TransactionSettingsPage extends StatefulWidget {
  final VoidCallback onBack;
  const TransactionSettingsPage({super.key, required this.onBack});

  @override
  State<TransactionSettingsPage> createState() => _TransactionSettingsPageState();
}

class _TransactionSettingsPageState extends State<TransactionSettingsPage> {
  static const primaryColor = Color(0xFF00BF63); // Steak Asri Red

  late TextEditingController _nameController;
  late TextEditingController _rateController;
  late TextEditingController _addressController;
  late TextEditingController _emailController;
  late TextEditingController _thankYouController;

  @override
  void initState() {
    super.initState();
    final settings = SettingsController.instance;
    final adminCtrl = context.read<AdminController>();
    _nameController = TextEditingController(text: settings.pajakName.value);
    _rateController = TextEditingController(text: settings.pajakRate.value.toString());
    _addressController = TextEditingController(text: adminCtrl.storeAddress ?? "");
    _emailController = TextEditingController(text: adminCtrl.storeEmail ?? "");
    _thankYouController = TextEditingController(text: settings.receiptThankYouMessage.value);

    // Rebuild preview live as user types
    _nameController.addListener(_onFieldChanged);
    _rateController.addListener(_onFieldChanged);
    _addressController.addListener(_onFieldChanged);
    _emailController.addListener(_onFieldChanged);
    _thankYouController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _nameController.removeListener(_onFieldChanged);
    _rateController.removeListener(_onFieldChanged);
    _addressController.removeListener(_onFieldChanged);
    _emailController.removeListener(_onFieldChanged);
    _thankYouController.removeListener(_onFieldChanged);

    _nameController.dispose();
    _rateController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _thankYouController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = SettingsController.instance;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          "Pengaturan Transaksi",
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: widget.onBack,
          tooltip: 'Kembali',
        ),
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            height: 1,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Metode Pembayaran
            _buildSectionHeader("Metode Pembayaran", Icons.account_balance_wallet_outlined, isDark),
            const SizedBox(height: 10),
            _buildActionCard(
              title: "Kelola Keuangan & Akun Kas",
              subtitle: "Atur QRIS, Transfer Bank, dan Tunai",
              icon: Icons.credit_card_rounded,
              color: primaryColor,
              isDark: isDark,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PaymentSettingsPage(
                      storeId: context.read<AdminController>().storeId!,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // 2. Stok & Inventaris
            ValueListenableBuilder<bool>(
              valueListenable: SettingsController.instance.featureStokEnabled,
              builder: (context, stokEnabled, _) {
                if (!stokEnabled) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader("Stok & Inventaris", Icons.inventory_2_outlined, isDark),
                    const SizedBox(height: 10),
                    _buildStockThresholdCard(isDark),
                    const SizedBox(height: 24),
                  ],
                );
              },
            ),

            // 3. Pengaturan Pajak
            _buildSectionHeader("Pengaturan Pajak / Biaya Layanan", Icons.receipt_outlined, isDark),
            const SizedBox(height: 10),
            _buildTaxSettingsCard(isDark, settings),
            const SizedBox(height: 24),

            // 4. Pengaturan Struk
            _buildSectionHeader("Kustomisasi Struk", Icons.tune_rounded, isDark),
            const SizedBox(height: 10),
            _buildReceiptSettingsCard(isDark, settings),
            const SizedBox(height: 32),

            // 5. Pratinjau Struk
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionHeader("Pratinjau Struk (Live)", Icons.remove_red_eye_outlined, isDark),
                ElevatedButton.icon(
                  onPressed: () => _openRealTestReceipt(context, settings),
                  icon: const Icon(Icons.print_rounded, size: 16),
                  label: Text(
                    "Uji Cetak / PDF",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildReceiptPreview(isDark, settings),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _buildReceiptPreview(bool isDark, SettingsController settings) {
    final adminCtrl = context.watch<AdminController>();

    const subtotal = 51000.0;
    final isTaxEnabled = settings.pajakEnabled.value;
    final taxRate = double.tryParse(_rateController.text) ?? settings.pajakRate.value;
    final taxName = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim().toUpperCase()
        : (settings.pajakName.value.trim().isNotEmpty
            ? settings.pajakName.value.trim().toUpperCase()
            : "PAJAK");
    final taxAmount = isTaxEnabled ? (subtotal * (taxRate / 100)) : 0.0;
    const discount = 0.0;
    final totalAmount = subtotal + taxAmount - discount;
    const cashReceived = 60000.0;
    final change = (cashReceived - totalAmount) > 0 ? (cashReceived - totalAmount) : 0.0;

    final thankYouText = _thankYouController.text.trim().isNotEmpty
        ? _thankYouController.text.trim().toUpperCase()
        : (settings.receiptThankYouMessage.value.trim().isNotEmpty
            ? settings.receiptThankYouMessage.value.trim().toUpperCase()
            : "ATAS KUNJUNGAN ANDA");

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 380),
        decoration: BoxDecoration(
          color: isDark ? Colors.black26 : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Header (Logo & Store)
              ValueListenableBuilder<bool>(
                valueListenable: settings.receiptShowLogo,
                builder: (context, showLogo, _) {
                  if (!showLogo) return const SizedBox.shrink();

                  return Container(
                    width: 40,
                    height: 40,
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _buildLogoImage(adminCtrl.storeLogo),
                  );
                },
              ),

              ValueListenableBuilder<bool>(
                valueListenable: settings.receiptShowStoreName,
                builder: (context, showName, _) {
                  if (!showName) return const SizedBox.shrink();
                  return Text(
                    (adminCtrl.storeName ?? "TOKO SAYA").toUpperCase(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.robotoMono(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.black87,
                    ),
                  );
                },
              ),

              ValueListenableBuilder<bool>(
                valueListenable: settings.receiptShowAddress,
                builder: (context, showAddress, _) {
                  if (!showAddress) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      _addressController.text.isEmpty
                          ? "Alamat Toko Belum Diatur"
                          : _addressController.text,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.robotoMono(
                        fontSize: 9,
                        color: Colors.black54,
                      ),
                    ),
                  );
                },
              ),

              ValueListenableBuilder<bool>(
                valueListenable: settings.receiptShowEmail,
                builder: (context, showEmail, _) {
                  if (!showEmail) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Text(
                      _emailController.text.isEmpty
                          ? "email@toko.com"
                          : _emailController.text,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.robotoMono(
                        fontSize: 9,
                        color: Colors.black54,
                      ),
                    ),
                  );
                },
              ),

              _buildDashedDivider(isBold: false),

              // 2. Transaction Info
              ValueListenableBuilder<bool>(
                valueListenable: settings.receiptShowDate,
                builder: (context, showDate, _) {
                  return ValueListenableBuilder<bool>(
                    valueListenable: settings.receiptShowTable,
                    builder: (context, showTable, _) {
                      return Column(
                        children: [
                          _previewInfoRow("ID Trans", "#TX-88912"),
                          if (showDate) ...[
                            _previewInfoRow("Tanggal", "19/03/2026"),
                            _previewInfoRow("Waktu", "14:20"),
                          ],
                          if (showTable) _previewInfoRow("Meja", "MEJA 03"),
                        ],
                      );
                    },
                  );
                },
              ),

              _buildDashedDivider(isBold: false),

              // 3. Items Header
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
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
              ValueListenableBuilder<bool>(
                valueListenable: settings.receiptShowDetails,
                builder: (context, showItems, _) {
                  if (!showItems) return const SizedBox.shrink();
                  return Column(
                    children: [
                      _previewItemRow("KOPI SUSU GULA AREN", "Rp 18.000", "2", "Rp 36.000"),
                      _previewItemRow("ROTI BAKAR COKELAT", "Rp 15.000", "1", "Rp 15.000"),
                    ],
                  );
                },
              ),

              _buildDashedDivider(isBold: false),

              // 5. Summary
              Column(
                children: [
                  _previewSummaryRow("Subtotal", "Rp 51.000"),
                  ValueListenableBuilder<bool>(
                    valueListenable: settings.pajakEnabled,
                    builder: (context, enabled, _) {
                      if (!enabled) return const SizedBox.shrink();
                      return _previewSummaryRow(
                        taxRate > 0 ? "$taxName (${taxRate.toStringAsFixed(0)}%)" : taxName,
                        _formatRupiah(taxAmount),
                      );
                    },
                  ),
                  _previewSummaryRow("Diskon", "- Rp 0"),
                  const SizedBox(height: 4),
                  _previewSummaryRow("TOTAL", _formatRupiah(totalAmount), isBold: true),
                ],
              ),

              _buildDashedDivider(isBold: true),

              // 6. Payment Info
              _previewSummaryRow("Metode Pembayaran", "Tunai"),
              _previewSummaryRow("Dibayar", "Rp 60.000"),
              _previewSummaryRow("Kembali", _formatRupiah(change > 0 ? change : 3390.0)),

              _buildDashedDivider(isBold: false),

              // 7. Thank You message
              ValueListenableBuilder<bool>(
                valueListenable: settings.receiptShowThankYou,
                builder: (context, showThankYou, _) {
                  if (!showThankYou) return const SizedBox.shrink();
                  return Column(
                    children: [
                      Text(
                        "TERIMA KASIH",
                        style: GoogleFonts.robotoMono(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        thankYouText,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.robotoMono(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  );
                },
              ),

              ValueListenableBuilder<bool>(
                valueListenable: settings.receiptShowTable,
                builder: (context, showTable, _) {
                  if (!showTable) return const SizedBox.shrink();
                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 8, bottom: 4),
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
                          "MEJA 03",
                          style: GoogleFonts.robotoMono(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),
              Text(
                "DIHASILKAN OLEH SISTEM KASIR BERSAMA",
                style: GoogleFonts.robotoMono(
                  fontSize: 7,
                  fontStyle: FontStyle.italic,
                  color: Colors.black45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatRupiah(double amount) {
    final intVal = amount.round();
    final str = intVal.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i > 0) {
        buffer.write('.');
      }
    }
    return "Rp ${buffer.toString().split('').reversed.join('')}";
  }

  Widget _buildLogoImage(String? path) {
    if (path == null || path.isEmpty) {
      return Image.asset(
        'assets/logo/logo.png',
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.storefront_rounded, size: 24, color: Colors.grey),
      );
    }
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Image.asset('assets/logo/logo.png', fit: BoxFit.cover),
      );
    }
    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Image.asset('assets/logo/logo.png', fit: BoxFit.cover),
      );
    }
    if (!kIsWeb) {
      final file = File(path);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Image.asset('assets/logo/logo.png', fit: BoxFit.cover),
        );
      }
    }
    return Image.asset('assets/logo/logo.png', fit: BoxFit.cover);
  }

  Widget _buildDashedDivider({bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: List.generate(
          30,
          (index) => Expanded(
            child: Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              color: isBold ? Colors.black87 : Colors.black54,
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
          Text(label, style: GoogleFonts.robotoMono(fontSize: 10, color: Colors.black54)),
          Text(
            value,
            style: GoogleFonts.robotoMono(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _previewItemRow(String name, String price, String qty, String total) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name.toUpperCase(),
            style: GoogleFonts.robotoMono(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "$qty x $price",
                style: GoogleFonts.robotoMono(fontSize: 9, color: Colors.black87),
              ),
              Text(
                total,
                style: GoogleFonts.robotoMono(
                  fontSize: 9,
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
              fontSize: isBold ? 13 : 10,
              color: isBold ? Colors.black : Colors.black54,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.robotoMono(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 13 : 10,
              color: isBold ? Colors.black : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openRealTestReceipt(BuildContext context, SettingsController settings) async {
    final adminCtrl = context.read<AdminController>();
    final receiptService = ReceiptService();

    const subtotal = 51000.0;
    final isTaxEnabled = settings.pajakEnabled.value;
    final taxRate = double.tryParse(_rateController.text) ?? settings.pajakRate.value;
    final taxName = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : settings.pajakName.value;
    final taxAmount = isTaxEnabled ? (subtotal * (taxRate / 100)) : 0.0;
    final totalAmount = subtotal + taxAmount;

    final items = [
      {
        'name': 'Kopi Susu Gula Aren',
        'quantity': 2,
        'unit_price': 18000.0,
        'total_price': 36000.0,
        'notes': 'Normal Ice',
      },
      {
        'name': 'Roti Bakar Cokelat',
        'quantity': 1,
        'unit_price': 15000.0,
        'total_price': 15000.0,
      },
    ];

    try {
      final pdfBytes = await receiptService.generateReceiptPdf(
        storeName: adminCtrl.storeName ?? "Kakilima Pos",
        storeLogoUrl: adminCtrl.storeLogo ?? 'assets/logo/logo.png',
        transactionId: "TX-88912",
        createdAt: DateTime(2026, 3, 19, 14, 20),
        items: items,
        subtotal: subtotal,
        discount: 0.0,
        pajakAmount: taxAmount,
        pajakName: taxName,
        pajakRate: taxRate,
        totalAmount: totalAmount,
        cashReceived: 60000.0,
        change: 60000.0 - totalAmount,
        paymentMethod: "TUNAI",
        showStoreName: settings.receiptShowStoreName.value,
        showAddress: settings.receiptShowAddress.value,
        showDate: settings.receiptShowDate.value,
        showDetails: settings.receiptShowDetails.value,
        showThankYou: settings.receiptShowThankYou.value,
        showLogo: settings.receiptShowLogo.value,
        showEmail: settings.receiptShowEmail.value,
        showTable: settings.receiptShowTable.value,
        tableNumber: "Meja 05",
        storeAddress: _addressController.text.trim().isNotEmpty
            ? _addressController.text.trim()
            : adminCtrl.storeAddress,
        storeEmail: _emailController.text.trim().isNotEmpty
            ? _emailController.text.trim()
            : adminCtrl.storeEmail,
        thankYouMessage: _thankYouController.text.trim().isNotEmpty
            ? _thankYouController.text.trim()
            : settings.receiptThankYouMessage.value,
      );

      if (!context.mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ReceiptPreviewPage(
            pdfData: pdfBytes,
            fileName: 'Uji_Coba_Struk_TX-88912.pdf',
            storeName: adminCtrl.storeName ?? "Kakilima Pos",
            transactionId: "TX-88912",
            createdAt: DateTime(2026, 3, 19, 14, 20),
            items: items,
            totalAmount: totalAmount,
            cashReceived: 60000.0,
            change: 60000.0 - totalAmount,
            paymentMethod: "TUNAI",
          ),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal membuat pratinjau: $e"),
            backgroundColor: primaryColor,
          ),
        );
      }
    }
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: isDark ? Colors.white60 : const Color(0xFF64748B),
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
        ),
      ),
    );
  }

  Widget _buildTaxSettingsCard(bool isDark, SettingsController settings) {
    return ValueListenableBuilder<bool>(
      valueListenable: settings.pajakEnabled,
      builder: (context, isEnabled, child) {
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (isEnabled ? primaryColor : Colors.grey).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: (isEnabled ? primaryColor : Colors.grey).withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.monetization_on_outlined,
                          color: isEnabled ? primaryColor : Colors.grey,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "Aktifkan Pajak (PPN/Lain)",
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  CupertinoSwitch(
                    value: isEnabled,
                    activeTrackColor: primaryColor,
                    onChanged: (val) {
                      settings.setPajakEnabled(val);
                      setState(() {});
                    },
                  ),
                ],
              ),
              if (isEnabled) ...[
                const SizedBox(height: 16),
                Text(
                  "Nama Pajak / Biaya Layanan",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 6),
                _buildOutlineTextField(
                  controller: _nameController,
                  hintText: "Contoh: PPN, Service Charge, Pajak Resto",
                  isDark: isDark,
                  onChanged: (val) => settings.setPajakName(val),
                ),
                const SizedBox(height: 14),
                Text(
                  "Besar Pajak (%)",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 6),
                _buildOutlineTextField(
                  controller: _rateController,
                  hintText: "10",
                  suffixText: "%",
                  keyboardType: TextInputType.number,
                  isDark: isDark,
                  onChanged: (val) {
                    final rate = double.tryParse(val);
                    if (rate != null) settings.setPajakRate(rate);
                  },
                ),
                const SizedBox(height: 10),
                Text(
                  "* Pajak akan dihitung dan ditampilkan otomatis pada struk dan total checkout.",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: primaryColor,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildReceiptSettingsCard(bool isDark, SettingsController settings) {
    final adminCtrl = context.read<AdminController>();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSettingToggle(
            title: "Tampilkan Logo Toko",
            icon: Icons.photo_size_select_actual_outlined,
            value: settings.receiptShowLogo,
            isDark: isDark,
            onChanged: (val) {
              settings.setReceiptShowLogo(val);
              setState(() {});
            },
          ),
          _buildCardDivider(isDark),
          _buildSettingToggle(
            title: "Tampilkan Nama Toko",
            icon: Icons.storefront_outlined,
            value: settings.receiptShowStoreName,
            isDark: isDark,
            onChanged: (val) {
              settings.setReceiptShowStoreName(val);
              setState(() {});
            },
          ),
          _buildCardDivider(isDark),
          _buildSettingToggle(
            title: "Tampilkan Alamat Toko",
            icon: Icons.location_on_outlined,
            value: settings.receiptShowAddress,
            isDark: isDark,
            onChanged: (val) {
              settings.setReceiptShowAddress(val);
              setState(() {});
            },
          ),
          ValueListenableBuilder<bool>(
            valueListenable: settings.receiptShowAddress,
            builder: (context, show, _) {
              if (!show) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: _buildOutlineTextField(
                  controller: _addressController,
                  hintText: "Alamat Lengkap Toko",
                  isDark: isDark,
                  onChanged: (val) => adminCtrl.updateStoreAddress(val),
                ),
              );
            },
          ),
          _buildCardDivider(isDark),
          _buildSettingToggle(
            title: "Tampilkan Email Toko",
            icon: Icons.mail_outline_rounded,
            value: settings.receiptShowEmail,
            isDark: isDark,
            onChanged: (val) {
              settings.setReceiptShowEmail(val);
              setState(() {});
            },
          ),
          ValueListenableBuilder<bool>(
            valueListenable: settings.receiptShowEmail,
            builder: (context, show, _) {
              if (!show) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: _buildOutlineTextField(
                  controller: _emailController,
                  hintText: "Email Toko (Contoh: contact@steakasri.com)",
                  isDark: isDark,
                  onChanged: (val) => adminCtrl.updateStoreEmail(val),
                ),
              );
            },
          ),
          _buildCardDivider(isDark),
          _buildSettingToggle(
            title: "Tampilkan Tanggal & Waktu",
            icon: Icons.access_time_rounded,
            value: settings.receiptShowDate,
            isDark: isDark,
            onChanged: (val) {
              settings.setReceiptShowDate(val);
              setState(() {});
            },
          ),
          _buildCardDivider(isDark),
          _buildSettingToggle(
            title: "Tampilkan Nomor Meja",
            icon: Icons.table_restaurant_outlined,
            value: settings.receiptShowTable,
            isDark: isDark,
            onChanged: (val) {
              settings.setReceiptShowTable(val);
              setState(() {});
            },
          ),
          _buildCardDivider(isDark),
          _buildSettingToggle(
            title: "Tampilkan Detail Item & Catatan",
            icon: Icons.format_list_bulleted_rounded,
            value: settings.receiptShowDetails,
            isDark: isDark,
            onChanged: (val) {
              settings.setReceiptShowDetails(val);
              setState(() {});
            },
          ),
          _buildCardDivider(isDark),
          _buildSettingToggle(
            title: "Tampilkan Pesan Terima Kasih",
            icon: Icons.chat_bubble_outline_rounded,
            value: settings.receiptShowThankYou,
            isDark: isDark,
            onChanged: (val) {
              settings.setReceiptShowThankYou(val);
              setState(() {});
            },
          ),
          ValueListenableBuilder<bool>(
            valueListenable: settings.receiptShowThankYou,
            builder: (context, show, _) {
              if (!show) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: _buildOutlineTextField(
                  controller: _thankYouController,
                  hintText: "Contoh: Terima Kasih Atas Kunjungan Anda!",
                  isDark: isDark,
                  onChanged: (val) => settings.setReceiptThankYouMessage(val),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStockThresholdCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Consumer<AnalyticsController>(
        builder: (context, controller, child) {
          return Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: primaryColor.withValues(alpha: 0.2), width: 1),
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  color: primaryColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Peringatan Stok Rendah",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Produk di bawah jumlah ini akan ditandai di dasbor",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_rounded, size: 16),
                      onPressed: () {
                        if (controller.stockThreshold > 1) {
                          controller.setStockThreshold(controller.stockThreshold - 1);
                        }
                      },
                      padding: const EdgeInsets.all(6),
                      constraints: const BoxConstraints(),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        "${controller.stockThreshold}",
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_rounded, size: 16),
                      onPressed: () {
                        controller.setStockThreshold(controller.stockThreshold + 1);
                      },
                      padding: const EdgeInsets.all(6),
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSettingToggle({
    required String title,
    required IconData icon,
    required ValueListenable<bool> value,
    required ValueChanged<bool> onChanged,
    required bool isDark,
  }) {
    return ValueListenableBuilder<bool>(
      valueListenable: value,
      builder: (context, isChecked, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    size: 18,
                    color: isChecked ? primaryColor : (isDark ? Colors.white38 : const Color(0xFF94A3B8)),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              CupertinoSwitch(
                value: isChecked,
                activeTrackColor: primaryColor,
                onChanged: onChanged,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCardDivider(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Divider(
        height: 1,
        color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
      ),
    );
  }

  Widget _buildOutlineTextField({
    required TextEditingController controller,
    required String hintText,
    required bool isDark,
    required ValueChanged<String> onChanged,
    String? suffixText,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white : const Color(0xFF0F172A),
      ),
      decoration: InputDecoration(
        hintText: hintText,
        suffixText: suffixText,
        hintStyle: GoogleFonts.plusJakartaSans(
          fontSize: 12.5,
          color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
            width: 1.2,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
            width: 1.2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
      ),
    );
  }
}
