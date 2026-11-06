import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../controllers/admin_controller.dart';
import '../../services/app_database.dart';
import '../../services/export_service.dart';
import '../../services/platform/file_manager.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';
import 'report/expense_management_page.dart';
import 'feature_settings_page.dart';
import 'table_management_page.dart';
import 'unit_page.dart';
import '../attendance/attendance_page.dart';
import '../../../controllers/settings_controller.dart';

class ActionMenuPage extends StatelessWidget {
  final Function(int) onIndexSelected;
  final VoidCallback? onMenuPressed;

  const ActionMenuPage({
    super.key,
    required this.onIndexSelected,
    this.onMenuPressed,
  });
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: Text(
          "Menu Aksi",
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(
              Icons.info_outline_rounded,
              color: isDark ? Colors.white38 : Colors.black26,
              size: 20,
            ),
            onPressed: () => _showAksiInfo(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                // ── Manajemen Produk & Stok ──────────────────────────────
                ValueListenableBuilder<bool>(
                  valueListenable: SettingsController.instance.featureStokEnabled,
                  builder: (context, stokEnabled, _) {
                    return _buildSectionTitle(
                      stokEnabled ? "Manajemen Produk & Stok" : "Manajemen Produk",
                      isDark,
                    );
                  },
                ),
                _buildGroupedSection(
                  isDark: isDark,
                  items: [
                    _buildSettingsActionItem(
                      label: "Produk",
                      icon: Icons.inventory_2_outlined,
                      color: Colors.blue,
                      onTap: () => onIndexSelected(1),
                      isDark: isDark,
                    ),
                    _buildSettingsActionItem(
                      label: "Kategori",
                      icon: Icons.grid_view_rounded,
                      color: Colors.teal,
                      onTap: () => onIndexSelected(2),
                      isDark: isDark,
                    ),
                    _buildSettingsActionItem(
                      label: "Pelanggan & Supplier",
                      icon: Icons.people_outline_rounded,
                      color: const Color(0xFF0D9488),
                      onTap: () => onIndexSelected(12),
                      isDark: isDark,
                    ),
                    _buildSettingsActionItem(
                      label: "Kelola Satuan",
                      icon: Icons.straighten_rounded,
                      color: const Color(0xFFD97706),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const UnitManagementPage(),
                          ),
                        );
                      },
                      isDark: isDark,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // ── Penjualan & Promosi ──────────────────────────────────
                _buildSectionTitle("Penjualan & Promosi", isDark),
                ValueListenableBuilder<bool>(
                  valueListenable: SettingsController.instance.featureLoyaltyEnabled,
                  builder: (context, loyaltyEnabled, _) {
                    return _buildGroupedSection(
                      isDark: isDark,
                      items: [
                        _buildSettingsActionItem(
                          label: "Promosi",
                          icon: Icons.discount_outlined,
                          color: Colors.orange,
                          onTap: () => onIndexSelected(17),
                          isDark: isDark,
                        ),
                        if (loyaltyEnabled)
                          _buildSettingsActionItem(
                            label: "Pelanggan",
                            icon: Icons.people_outline_rounded,
                            color: Colors.indigo,
                            onTap: () => onIndexSelected(12),
                            isDark: isDark,
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                // ── Keuangan & Laporan ───────────────────────────────────
                _buildSectionTitle("Keuangan & Laporan", isDark),
                _buildGroupedSection(
                  isDark: isDark,
                  items: [
                    _buildSettingsActionItem(
                      label: "Pengeluaran",
                      icon: Icons.payments_outlined,
                      color: Colors.red,
                      onTap: () {
                        final storeId =
                            context.read<AdminController>().storeId;
                        if (storeId != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ExpenseManagementPage(storeId: storeId),
                            ),
                          );
                        }
                      },
                      isDark: isDark,
                    ),
                    _buildSettingsActionItem(
                      label: "Riwayat Transaksi",
                      icon: Icons.description_outlined,
                      color: Colors.deepPurple,
                      onTap: () => onIndexSelected(4),
                      isDark: isDark,
                    ),
                    _buildSettingsActionItem(
                      label: "Export Keuangan All-Time",
                      icon: Icons.note_add_outlined,
                      color: const Color(0xFF00BF63),
                      onTap: () => _handleComprehensiveExport(context),
                      isDark: isDark,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ValueListenableBuilder<bool>(
                  valueListenable: SettingsController.instance.featureKaryawanEnabled,
                  builder: (context, karyawanEnabled, _) {
                    if (!karyawanEnabled) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle("Karyawan & Penggajian", isDark),
                        _buildGroupedSection(
                          isDark: isDark,
                          items: [
                            _buildSettingsActionItem(
                              label: "Kelola Pegawai & Gaji",
                              icon: Icons.badge_outlined,
                              color: const Color(0xFF0D9488),
                              onTap: () => onIndexSelected(5),
                              isDark: isDark,
                            ),
                            _buildSettingsActionItem(
                              label: "Absensi Pegawai",
                              icon: Icons.fingerprint_rounded,
                              color: const Color(0xFFE11D48),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const AttendancePage(showSidebar: false),
                                  ),
                                );
                              },
                              isDark: isDark,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                    );
                  },
                ),
                    ValueListenableBuilder<bool>(
                      valueListenable: SettingsController.instance.featureMejaEnabled,
                      builder: (context, enabled, _) {
                        if (!enabled) return const SizedBox.shrink();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 24),
                            _buildSectionTitle("F&B / Restoran", isDark),
                            _buildGroupedSection(
                              isDark: isDark,
                              items: [
                                _buildSettingsActionItem(
                                  label: "Manajemen Meja",
                                  icon: Icons.table_restaurant_outlined,
                                  color: Colors.orange,
                                  onTap: () {
                                    final storeId = context.read<AdminController>().storeId;
                                    if (storeId != null) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => TableManagementPage(storeId: storeId),
                                        ),
                                      );
                                    }
                                  },
                                  isDark: isDark,
                                ),
                              ],
                            ),
                          ],
                        );
                      }
                    ),
                    const SizedBox(height: 24),
                    // ── Manajemen Data & Sistem ──────────────────────────────
                    _buildSectionTitle("Manajemen Data & Sistem", isDark),
                    _buildGroupedSection(
                      isDark: isDark,
                      items: [
                        _buildSettingsActionItem(
                          label: "Pusat Fitur Aplikasi",
                          icon: Icons.rocket_launch_rounded,
                          color: Colors.teal,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const FeatureSettingsPage(),
                              ),
                            );
                          },
                          isDark: isDark,
                        ),
                        _buildSettingsActionItem(
                          label: "Manajemen Data (CSV/Excel)",
                          icon: Icons.folder_outlined,
                          color: Colors.green,
                          onTap: () => onIndexSelected(10),
                          isDark: isDark,
                        ),
                      ],
                    ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
  // ── Grouped section container ─────────────────────────────────────────────
  Widget _buildGroupedSection({
    required bool isDark,
    required List<Widget> items,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: List.generate(items.length * 2 - 1, (i) {
          if (i.isOdd) {
            return Divider(
              height: 1,
              indent: 60,
              color: isDark ? Colors.white10 : Colors.grey.shade200,
            );
          }
          return items[i ~/ 2];
        }),
      ),
    );
  }

  // ── Settings-style list item (Unified style) ─────────────────────────────
  Widget _buildSettingsActionItem({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        label,
        style: GoogleFonts.openSans(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: isDark ? Colors.white24 : Colors.grey.shade400,
        size: 20,
      ),
    );
  }

  // ── Section title ─────────────────────────────────────────────────────────
  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white70 : Colors.black54,
          letterSpacing: 0.5,
        ),
      ),
    );
  }


  Future<void> _handleComprehensiveExport(BuildContext context) async {
    final format = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Pilih Format Laporan",
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
        content: const Text(
          "Pilih format file untuk laporan keuangan keseluruhan (all-time).",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'pdf'),
            child: Text(
              "PDF Document",
              style: GoogleFonts.openSans(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'excel'),
            child: Text(
              "Excel (.xlsx)",
              style: GoogleFonts.openSans(
                color: Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (format == null || !context.mounted) return;

    final db = context.read<AppDatabase>();
    final admin = context.read<AdminController>();
    final export = ExportService();

    // Show loading logic (minimal)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Menghasilkan laporan ${format.toUpperCase()}..."),
      ),
    );

    try {
      final transactions = await (db.select(
        db.transactions,
      )..where((t) => t.storeId.equals(admin.storeId!))).get();
      final expenses = await (db.select(
        db.expenses,
      )..where((t) => t.storeId.equals(admin.storeId!))).get();

      Uint8List bytes;
      String filename;

      if (format == 'pdf') {
        bytes = await export.generateFinancialReportPdf(
          storeName: admin.storeName ?? "Toko Saya",
          transactions: transactions,
          expenses: expenses,
        );
        filename =
            "Laporan_Keuangan_AllTime_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf";
      } else {
        bytes = await export.generateFinancialReportExcel(
          storeName: admin.storeName ?? "Toko Saya",
          transactions: transactions,
          expenses: expenses,
        );
        filename =
            "Laporan_Keuangan_AllTime_${DateFormat('yyyyMMdd').format(DateTime.now())}.xlsx";
      }

      final savedPath = await FileManager().saveBytes(filename, bytes);
      if (context.mounted) {
        if (savedPath != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "File berhasil disimpan!",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          savedPath,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white70,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF16A34A),
              duration: const Duration(seconds: 5),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal export: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAksiInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Menu Aksi"),
        content: const Text(
          "Pusat kendali untuk fitur promosi, pengelolaan data, dan laporan keuangan komprehensif Anda.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Tutup"),
          ),
        ],
      ),
    );
  }
}

