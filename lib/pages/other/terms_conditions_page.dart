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
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          "Syarat & Ketentuan",
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black87, size: 20),
          onPressed: onBack,
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Header Badge
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.verified_user_rounded, color: AppTheme.primaryColor, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "POS Kasir & Integrasi Dropship",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          "Versi Aplikasi: 1.1.1 (Build 12) • November 2026",
                          style: GoogleFonts.openSans(
                            fontSize: 12,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            _buildSection(
              "1. Ketentuan Umum & Arsitektur Sistem",
              "Sistem POS ini dirancang dengan prinsip 'Offline-First' berkecepatan tinggi. Seluruh data transaksi, pelanggan, katalog produk, dan buku kas disimpan secara lokal di perangkat Anda menggunakan SQLite (Drift Engine). Sistem ini dapat digunakan sepenuhnya tanpa koneksi internet, menjamin kelancaran operasional kasir kapan pun dan di mana pun.",
              isDark,
              Icons.devices_other_rounded,
            ),
            _buildSection(
              "2. Integrasi Dropship & Multi-Supplier",
              "Aplikasi dilengkapi fitur pengelolaan dropship yang menghubungkan pencatatan pesanan kasir dengan data pemasok (supplier). Pengguna dapat mengatur harga modal pemasok, harga jual eceran, komisi dropship, serta buku kas hutang-piutang supplier secara terpadu dan otomatis.",
              isDark,
              Icons.local_shipping_outlined,
            ),
            _buildSection(
              "3. Transaksi, Pembayaran & Cetak Struk",
              "Sistem mendukung berbagai metode pembayaran termasuk Tunai, QRIS, Transfer Bank, Split Payment, dan Piutang Pelanggan. Fitur pencetakan struk transaksi kasir dan catatan buku kas mendukung koneksi printer thermal Bluetooth, USB, maupun Network (ESC/POS) dengan pengaturan layout struk yang fleksibel.",
              isDark,
              Icons.receipt_long_rounded,
            ),
            _buildSection(
              "4. Privasi & Keamanan Data Pengguna",
              "Kami menjamin kerahasiaan penuh data bisnis Anda. Seluruh catatan penjualan, omzet keuangan, dan informasi pelanggan tidak dikirimkan atau dibagikan ke pihak ketiga mana pun tanpa persetujuan Anda. Pengguna sangat disarankan melakukan 'Pencadangan Data' berkala melalui menu Sistem guna mencegah kehilangan data fisik perangkat.",
              isDark,
              Icons.security_rounded,
            ),
            _buildSection(
              "5. Tanggung Jawab Operasional",
              "Pemilik toko dan kasir bertanggung jawab penuh terhadap kebenaran data stok barang, penetapan tarif pajak, diskon promosi, dan transaksi kasir harian. Sistem menyediakan perhitungan laba/rugi dan laporan keuangan otomatis berdasarkan data riil yang diinputkan pengguna.",
              isDark,
              Icons.admin_panel_settings_outlined,
            ),
            _buildSection(
              "6. Pembaruan & Dukungan Teknis",
              "Pembaruan perangkat lunak disediakan secara berkelanjutan untuk peningkatan stabilitas, efisiensi memori, dukungan responsif lintas ukuran layar, serta penambahan fitur terbaru demi menunjang pertumbuhan bisnis Anda.",
              isDark,
              Icons.system_update_rounded,
            ),

            const SizedBox(height: 24),
            Center(
              child: Text(
                "Terakhir diperbarui: 14 November 2026",
                style: GoogleFonts.openSans(
                  fontSize: 12,
                  color: isDark ? Colors.white38 : Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content, bool isDark, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
          ),
          child: Text(
            content,
            style: GoogleFonts.openSans(
              fontSize: 13.5,
              height: 1.6,
              color: isDark ? Colors.white70 : const Color(0xFF334155),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
