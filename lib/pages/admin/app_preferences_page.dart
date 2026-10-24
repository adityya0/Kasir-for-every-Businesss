import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppPreferencesPage extends StatelessWidget {
  final VoidCallback onBack;
  final Function(int) onNavigate;

  const AppPreferencesPage({
    super.key,
    required this.onBack,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          "Preferensi Aplikasi",
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: onBack,
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            _buildSectionTitle("Operasional & Perangkat", isDark),
            Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.grey.shade200,
                ),
              ),
              child: Column(
                children: [
                  _buildActionCard(
                    title: "Pengaturan Printer",
                    icon: Icons.print_outlined,
                    isDark: isDark,
                    onTap: () => onNavigate(7),
                  ),
                  Divider(height: 1, indent: 60, color: isDark ? Colors.white10 : Colors.grey.shade200),
                  _buildActionCard(
                    title: "Pengaturan Transaksi",
                    icon: Icons.receipt_long_rounded,
                    isDark: isDark,
                    onTap: () => onNavigate(19),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

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

  Widget _buildActionCard({
    required String title,
    required IconData icon,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.blue, size: 22),
      ),
      title: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }
}

