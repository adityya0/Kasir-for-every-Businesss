import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' hide Column;
import '../../../services/app_database.dart';
import '../history/transaction_detail_page.dart';

class DebtManagementPage extends StatefulWidget {
  final String storeId;
  const DebtManagementPage({super.key, required this.storeId});

  @override
  State<DebtManagementPage> createState() => _DebtManagementPageState();
}

class _DebtManagementPageState extends State<DebtManagementPage> {
  final _currencyFormat = NumberFormat.currency(
    locale: 'id',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final db = context.read<AppDatabase>();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          "Manajemen Hutang",
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
      ),
      body: StreamBuilder<List<TransactionWithCustomer>>(
        stream: _watchDebtTransactions(db),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final debts = snapshot.data ?? [];

          if (debts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.find_in_page,
                    size: 80,
                    color: Colors.grey.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Tidak ada data hutang",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: debts.length,
            itemBuilder: (context, index) {
              final debt = debts[index];
              final tx = debt.transaction;
              final cust = debt.customer;
              final remaining = (tx.totalAmount ?? 0) - (tx.cashReceived ?? 0);

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: isDark ? Colors.white10 : Colors.grey.shade200,
                  ),
                ),
                child: InkWell(
                  onTap: () async {
                    final items = await (db.select(db.transactionItems)..where((t) => t.transactionId.equals(tx.id))).get();
                    final txMap = tx.toJson();
                    txMap['transaction_items'] = items.map((e) => e.toJson()).toList();
                    
                    if (context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TransactionDetailPage(transaction: txMap),
                        ),
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cust?.name ?? "Pelanggan Umum",
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    DateFormat('dd MMM yyyy, HH:mm').format(tx.createdAt ?? DateTime.now()),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "HUTANG",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.orange,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(height: 1),
                        ),
                        Row(
                          children: [
                            _buildInfoItem(
                              "Total",
                              _currencyFormat.format(tx.totalAmount ?? 0),
                              isDark,
                            ),
                            _buildInfoItem(
                              "Dibayar",
                              _currencyFormat.format(tx.cashReceived ?? 0),
                              isDark,
                            ),
                            _buildInfoItem(
                              "Sisa",
                              _currencyFormat.format(remaining),
                              isDark,
                              valueColor: Colors.redAccent,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _showPaymentDialog(tx, remaining),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFC0392B),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 0,
                            ),
                            child: const Text("Pelunasan"),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, bool isDark, {Color? valueColor}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: valueColor ?? (isDark ? Colors.white : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Stream<List<TransactionWithCustomer>> _watchDebtTransactions(AppDatabase db) {
    return (db.select(db.transactions)
          ..where((t) => t.storeId.equals(widget.storeId))
          ..where((t) => t.status.equals('debt'))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .join([
          leftOuterJoin(db.customers, db.customers.id.equalsExp(db.transactions.customerId)),
        ])
        .watch()
        .map((rows) {
          return rows.map((row) {
            return TransactionWithCustomer(
              transaction: row.readTable(db.transactions),
              customer: row.readTableOrNull(db.customers),
            );
          }).toList();
        });
  }

  void _showPaymentDialog(Transaction tx, double remaining) {
    final controller = TextEditingController(text: remaining.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Pelunasan Hutang"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Sisa hutang: ${_currencyFormat.format(remaining)}"),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: "Jumlah Bayar",
                prefixText: "Rp ",
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(controller.text) ?? 0;
              if (amount <= 0) return;

              final db = context.read<AppDatabase>();
              final newCashReceived = (tx.cashReceived ?? 0) + amount;
              final newStatus = newCashReceived >= (tx.totalAmount ?? 0) ? 'completed' : 'debt';

              await (db.update(db.transactions)..where((t) => t.id.equals(tx.id))).write(
                TransactionsCompanion(
                  cashReceived: Value(newCashReceived),
                  status: Value(newStatus),
                ),
              );

              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC0392B),
              foregroundColor: Colors.white,
            ),
            child: const Text("Bayar"),
          ),
        ],
      ),
    );
  }
}

class TransactionWithCustomer {
  final Transaction transaction;
  final Customer? customer;
  TransactionWithCustomer({required this.transaction, this.customer});
}
