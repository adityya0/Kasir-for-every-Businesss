import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_theme.dart';

class TermsConditionsPage extends StatelessWidget {
  final VoidCallback onBack;

  const TermsConditionsPage({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          "Syarat & Ketentuan",
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black87),
          onPressed: onBack,
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              "Ringkasan Teknis Aplikasi",
              "Kasir Asri adalah aplikasi Point of Sale (POS) yang dirancang dengan arsitektur 'Offline-First'. Semua data transaksi, stok, dan pelanggan disimpan secara lokal di dalam perangkat Anda menggunakan database SQLite (Drift) yang terenkripsi. Hal ini memastikan aplikasi tetap dapat berfungsi tanpa koneksi internet dan memberikan performa yang sangat cepat.",
              isDark,
            ),
            _buildSection(
              "Pengolahan Data",
              "Aplikasi mengolah data secara real-time untuk perhitungan Laba/Rugi, analisis tren penjualan, dan manajemen stok otomatis. Kami menyarankan pengguna untuk mencadangkan data secara berkala melalui menu 'Pencadangan & Pemulihan' untuk menghindari kehilangan data akibat kerusakan perangkat fisik.",
              isDark,
            ),
            _buildSection(
              "Kebijakan Privasi",
              "Kami sangat menghargai privasi Anda. Kasir Asri tidak mengumpulkan, mengirim, atau memproses data bisnis Anda ke server pihak ketiga mana pun tanpa izin eksplisit dari Anda (seperti saat menggunakan fitur pencadangan cloud opsional). Data Anda adalah milik Anda sepenuhnya.",
              isDark,
            ),
            _buildSection(
              "Tanggung Jawab Pengguna",
              "Pengguna bertanggung jawab penuh atas akurasi data yang dimasukkan ke dalam sistem. Pengembang Kasir Asri tidak bertanggung jawab atas kerugian materi yang disebabkan oleh kesalahan input, penyalahgunaan aplikasi, atau kehilangan perangkat penyimpanan lokal.",
              isDark,
            ),
            _buildSection(
              "Pembaruan Perangkat Lunak",
              "Kami terus berupaya memperbarui Kasir Asri untuk fitur yang lebih baik dan perbaikan bug. Pembaruan akan tersedia melalui portal resmi dan disarankan untuk segera diinstal demi keamanan sistem.",
              isDark,
            ),
            const SizedBox(height: 40),
            Center(
              child: Text(
                "Terakhir diperbarui: April 2026",
                style: GoogleFonts.openSans(
                  fontSize: 12,
                  color: isDark ? Colors.white38 : Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
          ),
          child: Text(
            content,
            style: GoogleFonts.openSans(
              fontSize: 14,
              height: 1.6,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

