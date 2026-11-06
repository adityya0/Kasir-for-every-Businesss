import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

/// Modern confirmation popup dialog for financial transactions,
/// supplier purchases, debt payments, and accounting entries.
/// Styled symmetrically to the POS PaymentSuccessDialog.
class TransactionResultDialog extends StatelessWidget {
  final bool isSuccess;
  final String title;
  final String subtitle;
  final String? transactionCode;
  final DateTime dateTime;
  final double? totalAmount;
  final double? paidAmount;
  final double? remainingDebt;
  final String? statusBadge;
  final Color? statusBadgeBg;
  final Color? statusBadgeText;
  final String? contactName;
  final String? contactRole;
  final String? contactPhone;
  final String? accountName;
  final String? category;
  final String? notes;
  final List<String>? itemSummaries;
  final String? errorMessage;
  final VoidCallback? onClose;
  final VoidCallback? onShareWhatsApp;

  TransactionResultDialog({
    super.key,
    this.isSuccess = true,
    required this.title,
    required this.subtitle,
    this.transactionCode,
    DateTime? dateTime,
    this.totalAmount,
    this.paidAmount,
    this.remainingDebt,
    this.statusBadge,
    this.statusBadgeBg,
    this.statusBadgeText,
    this.contactName,
    this.contactRole,
    this.contactPhone,
    this.accountName,
    this.category,
    this.notes,
    this.itemSummaries,
    this.errorMessage,
    this.onClose,
    this.onShareWhatsApp,
  }) : dateTime = dateTime ?? DateTime.now();

  static Future<void> show({
    required BuildContext context,
    bool isSuccess = true,
    required String title,
    required String subtitle,
    String? transactionCode,
    DateTime? dateTime,
    double? totalAmount,
    double? paidAmount,
    double? remainingDebt,
    String? statusBadge,
    Color? statusBadgeBg,
    Color? statusBadgeText,
    String? contactName,
    String? contactRole,
    String? contactPhone,
    String? accountName,
    String? category,
    String? notes,
    List<String>? itemSummaries,
    String? errorMessage,
    VoidCallback? onClose,
    VoidCallback? onShareWhatsApp,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => TransactionResultDialog(
        isSuccess: isSuccess,
        title: title,
        subtitle: subtitle,
        transactionCode: transactionCode,
        dateTime: dateTime,
        totalAmount: totalAmount,
        paidAmount: paidAmount,
        remainingDebt: remainingDebt,
        statusBadge: statusBadge,
        statusBadgeBg: statusBadgeBg,
        statusBadgeText: statusBadgeText,
        contactName: contactName,
        contactRole: contactRole,
        contactPhone: contactPhone,
        accountName: accountName,
        category: category,
        notes: notes,
        itemSummaries: itemSummaries,
        errorMessage: errorMessage,
        onClose: onClose,
        onShareWhatsApp: onShareWhatsApp,
      ),
    );
  }

  Future<void> _handleWhatsAppShare(BuildContext context) async {
    if (onShareWhatsApp != null) {
      onShareWhatsApp!();
      return;
    }

    final curFmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final dateStr = DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(dateTime);

    final buffer = StringBuffer();
    buffer.writeln("🧾 *BUKTI TRANSAKSI*");
    buffer.writeln("─────────────────────────");
    if (transactionCode != null && transactionCode!.isNotEmpty) {
      buffer.writeln("🔖 *No Ref:* $transactionCode");
    }
    buffer.writeln("📅 *Tanggal:* $dateStr");
    if (category != null && category!.isNotEmpty) {
      buffer.writeln("🏷️ *Tipe:* $category");
    }
    if (contactName != null && contactName!.isNotEmpty) {
      final role = contactRole ?? "Kontak";
      buffer.writeln("👤 *$role:* $contactName");
    }
    if (accountName != null && accountName!.isNotEmpty) {
      buffer.writeln("💳 *Metode/Akun:* $accountName");
    }
    if (totalAmount != null) {
      buffer.writeln("💵 *Total:* ${curFmt.format(totalAmount)}");
    }
    if (paidAmount != null && paidAmount! > 0) {
      buffer.writeln("💰 *Dibayar:* ${curFmt.format(paidAmount)}");
    }
    if (remainingDebt != null && remainingDebt! > 0) {
      buffer.writeln("⚠️ *Sisa Hutang/Piutang:* ${curFmt.format(remainingDebt)}");
    }
    if (statusBadge != null) {
      buffer.writeln("📌 *Status:* $statusBadge");
    }
    if (itemSummaries != null && itemSummaries!.isNotEmpty) {
      buffer.writeln("─────────────────────────");
      buffer.writeln("📦 *Daftar Barang:*");
      for (final item in itemSummaries!) {
        buffer.writeln(" • $item");
      }
    }
    if (notes != null && notes!.trim().isNotEmpty) {
      buffer.writeln("─────────────────────────");
      buffer.writeln("📝 *Catatan:* ${notes!.trim()}");
    }
    buffer.writeln("─────────────────────────");
    buffer.writeln("Terima kasih! 🙏");

    String targetPhone = (contactPhone ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    if (targetPhone.startsWith('0')) {
      targetPhone = '62${targetPhone.substring(1)}';
    }

    Uri uri;
    if (targetPhone.isNotEmpty) {
      uri = Uri.parse("https://wa.me/$targetPhone?text=${Uri.encodeComponent(buffer.toString())}");
    } else {
      uri = Uri.parse("https://wa.me/?text=${Uri.encodeComponent(buffer.toString())}");
    }

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final curFmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    final effectiveStatusBg = statusBadgeBg ??
        (statusBadge?.toUpperCase() == 'HUTANG'
            ? (isDark ? const Color(0xFF881337).withValues(alpha: 0.35) : const Color(0xFFFFF1F2))
            : (isDark ? const Color(0xFF064E3B).withValues(alpha: 0.35) : const Color(0xFFECFDF5)));

    final effectiveStatusText = statusBadgeText ??
        (statusBadge?.toUpperCase() == 'HUTANG'
            ? const Color(0xFFE05260)
            : const Color(0xFF0D7A4E));

    final bool canShare = (contactPhone != null && contactPhone!.trim().isNotEmpty) ||
        (contactName != null && contactName!.trim().isNotEmpty);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Icon with soft circular background
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: isSuccess
                        ? const Color(0xFF00BF63).withValues(alpha: 0.12)
                        : const Color(0xFFE05260).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isSuccess ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    color: isSuccess ? const Color(0xFF00BF63) : const Color(0xFFE05260),
                    size: 46,
                  ),
                ),
                const SizedBox(height: 14),

                // Main Title
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 5),

                // Subtitle
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),

                // Detail Card / Receipt Box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row: Transaction Code + Date
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (transactionCode != null && transactionCode!.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                transactionCode!,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  letterSpacing: 0.4,
                                ),
                              ),
                            )
                          else
                            const SizedBox.shrink(),
                          Text(
                            DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(dateTime),
                            style: GoogleFonts.openSans(
                              fontSize: 11.5,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Divider(height: 1, color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                      const SizedBox(height: 12),

                      // Error message banner if failure
                      if (!isSuccess && errorMessage != null && errorMessage!.isNotEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF881337).withValues(alpha: 0.35) : const Color(0xFFFFF1F2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE05260).withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            errorMessage!,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFE05260),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Total Amount & Status Badge
                      if (totalAmount != null) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "TOTAL NOMINAL",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.4,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  curFmt.format(totalAmount),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                            if (statusBadge != null && statusBadge!.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: effectiveStatusBg,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: effectiveStatusText.withValues(alpha: 0.35),
                                  ),
                                ),
                                child: Text(
                                  statusBadge!,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: effectiveStatusText,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Divider(height: 1, color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                        const SizedBox(height: 10),
                      ],

                      // Key Value Rows
                      if (category != null && category!.isNotEmpty)
                        _buildRow("Kategori / Tipe", category!, isDark),
                      if (contactName != null && contactName!.isNotEmpty)
                        _buildRow(contactRole ?? "Kontak", contactName!, isDark, isBold: true),
                      if (accountName != null && accountName!.isNotEmpty)
                        _buildRow("Akun Pembayaran", accountName!, isDark),
                      if (paidAmount != null && paidAmount! > 0)
                        _buildRow("Dibayar Sekarang", curFmt.format(paidAmount), isDark, valueColor: const Color(0xFF0D7A4E)),
                      if (remainingDebt != null && remainingDebt! > 0)
                        _buildRow("Sisa Hutang/Piutang", curFmt.format(remainingDebt), isDark, valueColor: const Color(0xFFE05260), isBold: true),
                      if (notes != null && notes!.trim().isNotEmpty)
                        _buildRow("Catatan", notes!.trim(), isDark),

                      // Item list summary
                      if (itemSummaries != null && itemSummaries!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          "Barang (${itemSummaries!.length} item):",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        ...itemSummaries!.map((it) => Padding(
                              padding: const EdgeInsets.only(bottom: 3),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("• ", style: GoogleFonts.openSans(fontSize: 12, color: isDark ? Colors.white70 : const Color(0xFF334155))),
                                  Expanded(
                                    child: Text(
                                      it,
                                      style: GoogleFonts.openSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: isDark ? Colors.white70 : const Color(0xFF334155),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Action Buttons: Selesai + Bagikan WA (jika ada kontak)
                Row(
                  children: [
                    if (isSuccess && canShare) ...[
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: () => _handleWhatsAppShare(context),
                            icon: const Icon(Icons.share_rounded, size: 19),
                            label: Text(
                              "Kirim WA",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF00BF63),
                              side: const BorderSide(color: Color(0xFF00BF63), width: 1.3),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      flex: isSuccess && canShare ? 1 : 2,
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context, rootNavigator: true).pop();
                            if (onClose != null) onClose!();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isSuccess ? const Color(0xFF00BF63) : const Color(0xFFE05260),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text(
                            isSuccess ? "Selesai" : "Tutup",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, bool isDark, {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
                color: valueColor ?? (isDark ? Colors.white : const Color(0xFF0F172A)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

