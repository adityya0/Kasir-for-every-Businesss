import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class TransactionItem extends StatelessWidget {
  final Map<String, dynamic> transaction;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final int index;
  final bool isLast;

  const TransactionItem({
    super.key,
    required this.transaction,
    required this.onTap,
    this.onDelete,
    required this.index,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final total = (transaction['totalAmount'] ?? 0 as num).toDouble();
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
    final txId = transaction['id'].toString().substring(0, 8).toUpperCase();

    final List items = transaction['transaction_items'] ?? [];
    String displayTitle = "#$txId";
    if (items.isNotEmpty) {
      final firstName = items[0]['productName'] ?? 'Item';
      if (items.length > 1) {
        displayTitle = "$firstName + ${items.length - 1} item";
      } else {
        displayTitle = firstName;
      }
    }

    final currencyFormat = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(
                  bottom: BorderSide(
                    color: isDark
                        ? const Color(0xFF374151)
                        : const Color(0xFFF1F5F9),
                    width: 1,
                  ),
                ),
        ),
        child: Row(
          children: [
            // Index Number Badge
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFC0392B).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: Text(
                index.toString(),
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: const Color(0xFFC0392B),
                ),
              ),
            ),

            // Product Name & ID/Time
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayTitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        "#$txId",
                        style: GoogleFonts.openSans(
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                          color: isDark ? Colors.white54 : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('HH:mm').format(date),
                        style: GoogleFonts.openSans(
                          fontWeight: FontWeight.w500,
                          fontSize: 11,
                          color: isDark ? Colors.white54 : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Cashier
            Expanded(
              flex: 2,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  cashierName,
                  style: GoogleFonts.openSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : const Color(0xFF334155),
                  ),
                  maxLines: 1,
                ),
              ),
            ),

            // Amount
            Expanded(
              flex: 2,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  currencyFormat.format(total),
                  textAlign: TextAlign.right,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: const Color(0xFFC0392B),
                  ),
                ),
              ),
            ),

            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                tooltip: "Hapus Transaksi",
                padding: const EdgeInsets.only(left: 6),
                constraints: const BoxConstraints(),
                onPressed: onDelete,
              )
            else ...[
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                size: 16,
                color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

