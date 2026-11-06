import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../services/app_database.dart';
import 'package:drift/drift.dart' as drift;

class TableDashboardSheet extends StatefulWidget {
  final StoreTable? selectedTable;
  final Function(StoreTable?) onTableSelected;

  const TableDashboardSheet({
    super.key,
    this.selectedTable,
    required this.onTableSelected,
  });

  @override
  State<TableDashboardSheet> createState() => _TableDashboardSheetState();
}

class _TableDashboardSheetState extends State<TableDashboardSheet> {
  final Color _primaryColor = const Color(0xFF00BF63);

  Future<void> _clearTable(StoreTable table) async {
    final db = Provider.of<AppDatabase>(context, listen: false);
    await (db.update(db.storeTables)..where((t) => t.id.equals(table.id))).write(
      const StoreTablesCompanion(
        status: drift.Value('available'),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _clearAllTables() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Kosongkan Semua Meja?"),
        content: const Text("Semua meja akan diatur ulang menjadi 'Kosong'."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Ya, Reset", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final db = Provider.of<AppDatabase>(context, listen: false);
      await db.update(db.storeTables).write(
            const StoreTablesCompanion(status: drift.Value('available')),
          );
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<AppDatabase>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Denah Meja",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Klik meja untuk memilih atau mereset status",
                        style: GoogleFonts.openSans(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: _clearAllTables,
                  icon: const Icon(Icons.cleaning_services_rounded, size: 18, color: Colors.red),
                  label: const Text("Reset Semua", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          const Divider(),

          // Legend
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildLegendItem(Colors.green, "Kosong"),
                _buildLegendItem(Colors.orange, "Menunggu"),
                _buildLegendItem(Colors.red, "Makan"),
              ],
            ),
          ),

          // Grid
          Expanded(
            child: StreamBuilder<List<StoreTable>>(
              stream: db.select(db.storeTables).watch(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final tables = snapshot.data!;
                if (tables.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.table_restaurant, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        const Text("Belum ada meja yang ditambahkan."),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Atur Meja di Menu Admin"),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: tables.length,
                  itemBuilder: (context, index) {
                    final table = tables[index];
                    final isSelected = widget.selectedTable?.id == table.id;
                    
                    Color statusColor;
                    switch (table.status) {
                      case 'occupied':
                        statusColor = Colors.red;
                        break;
                      case 'waiting':
                        statusColor = Colors.orange;
                        break;
                      default:
                        statusColor = Colors.green;
                    }

                    return GestureDetector(
                      onTap: () {
                        widget.onTableSelected(table);
                        Navigator.pop(context);
                      },
                      onLongPress: () => _showTableActionDialog(table),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? _primaryColor.withValues(alpha: 0.1) : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? _primaryColor : statusColor.withValues(alpha: 0.3),
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: [
                            if (!isSelected)
                              BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            // Status Dot
                            Positioned(
                              top: 12,
                              right: 12,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.table_restaurant,
                                    color: isSelected ? _primaryColor : Colors.grey,
                                    size: 28,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    table.name,
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: isSelected ? _primaryColor : (isDark ? Colors.white : Colors.black87),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  void _showTableActionDialog(StoreTable table) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text("Opsi Meja: ${table.name}"),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _clearTable(table);
            },
            child: const Text("Kosongkan Meja", style: TextStyle(color: Colors.green)),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              final db = Provider.of<AppDatabase>(context, listen: false);
              (db.update(db.storeTables)..where((t) => t.id.equals(table.id))).write(
                const StoreTablesCompanion(status: drift.Value('occupied')),
              );
              Navigator.pop(ctx);
              if (mounted) setState(() {});
            },
            child: const Text("Tandai Sudah Makan"),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: const Text("Kembali"),
        ),
      ),
    );
  }
}
