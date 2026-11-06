import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/settings_controller.dart';

class FeatureSettingsPage extends StatefulWidget {
  const FeatureSettingsPage({super.key});

  @override
  State<FeatureSettingsPage> createState() => _FeatureSettingsPageState();
}

class _FeatureSettingsPageState extends State<FeatureSettingsPage> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          "Pusat Kendali Fitur",
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 18,
          ),
        ),
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: isDark ? const Color(0xFF374151) : const Color(0xFFE2E8F0),
            height: 1,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : Colors.black87,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? const Color(0xFF374151) : const Color(0xFFCBD5E1),
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    children: [
                      // 1. Manajemen Stok
                      ValueListenableBuilder<bool>(
                        valueListenable: SettingsController.instance.featureStokEnabled,
                        builder: (context, enabled, _) {
                          return _buildFeatureToggle(
                            title: "Manajemen Stok",
                            subtitle: "Pantau ketersediaan barang & peringatan stok rendah",
                            value: enabled,
                            onChanged: (v) => SettingsController.instance.setFeatureStokEnabled(v),
                            isDark: isDark,
                            showDivider: true,
                          );
                        },
                      ),
                      // 2. Manajemen Meja
                      ValueListenableBuilder<bool>(
                        valueListenable: SettingsController.instance.featureMejaEnabled,
                        builder: (context, enabled, _) {
                          return _buildFeatureToggle(
                            title: "Manajemen Meja",
                            subtitle: "Atur posisi & status pesanan per meja",
                            value: enabled,
                            onChanged: (v) => SettingsController.instance.setFeatureMejaEnabled(v),
                            isDark: isDark,
                            showDivider: true,
                          );
                        },
                      ),
                      // 3. Pajak & Biaya Layanan
                      ValueListenableBuilder<bool>(
                        valueListenable: SettingsController.instance.pajakEnabled,
                        builder: (context, enabled, _) {
                          return _buildFeatureToggle(
                            title: "Pajak & Biaya Layanan",
                            subtitle: "PPN 11% & service charge otomatis",
                            value: enabled,
                            onChanged: (v) => SettingsController.instance.setPajakEnabled(v),
                            isDark: isDark,
                            showDivider: true,
                          );
                        },
                      ),
                      // 4. Loyalitas & Poin
                      ValueListenableBuilder<bool>(
                        valueListenable: SettingsController.instance.featureLoyaltyEnabled,
                        builder: (context, enabled, _) {
                          return _buildFeatureToggle(
                            title: "Loyalitas & Poin",
                            subtitle: "Pelanggan mendapatkan poin setiap belanja",
                            value: enabled,
                            onChanged: (v) => SettingsController.instance.setFeatureLoyaltyEnabled(v),
                            isDark: isDark,
                            showDivider: true,
                          );
                        },
                      ),
                      // 5. Fitur Pelanggan (Kasir)
                      ValueListenableBuilder<bool>(
                        valueListenable: SettingsController.instance.featurePelangganEnabled,
                        builder: (context, enabled, _) {
                          return _buildFeatureToggle(
                            title: "Fitur Pelanggan (Kasir)",
                            subtitle: "Tampilkan tombol pilihan pelanggan saat transaksi kasir",
                            value: enabled,
                            onChanged: (v) => SettingsController.instance.setFeaturePelangganEnabled(v),
                            isDark: isDark,
                            showDivider: true,
                          );
                        },
                      ),
                      // 6. Pisah Bill (Split Bill)
                      ValueListenableBuilder<bool>(
                        valueListenable: SettingsController.instance.featurePisahBillEnabled,
                        builder: (context, enabled, _) {
                          return _buildFeatureToggle(
                            title: "Pisah Bill (Split Bill)",
                            subtitle: "Tampilkan tombol pisah tagihan/item pesanan di kasir",
                            value: enabled,
                            onChanged: (v) => SettingsController.instance.setFeaturePisahBillEnabled(v),
                            isDark: isDark,
                            showDivider: true,
                          );
                        },
                      ),
                      // 7. Split Pay (Multi Pembayaran)
                      ValueListenableBuilder<bool>(
                        valueListenable: SettingsController.instance.featureSplitPayEnabled,
                        builder: (context, enabled, _) {
                          return _buildFeatureToggle(
                            title: "Split Pay (Multi Pembayaran)",
                            subtitle: "Tampilkan opsi bayar campuran (misal: tunai + transfer/QRIS)",
                            value: enabled,
                            onChanged: (v) => SettingsController.instance.setFeatureSplitPayEnabled(v),
                            isDark: isDark,
                            showDivider: true,
                          );
                        },
                      ),
                      // 8. Pegawai, Gaji & Absensi
                      ValueListenableBuilder<bool>(
                        valueListenable: SettingsController.instance.featureKaryawanEnabled,
                        builder: (context, enabled, _) {
                          return _buildFeatureToggle(
                            title: "Pegawai, Gaji & Absensi",
                            subtitle: "Kelola data staf/karyawan, pencatatan gaji, dan presensi absensi",
                            value: enabled,
                            onChanged: (v) => SettingsController.instance.setFeatureKaryawanEnabled(v),
                            isDark: isDark,
                            showDivider: true,
                          );
                        },
                      ),
                      // 9. Antrean Pesanan (Kasir)
                      ValueListenableBuilder<bool>(
                        valueListenable: SettingsController.instance.featureAntreanPesananEnabled,
                        builder: (context, enabled, _) {
                          return _buildFeatureToggle(
                            title: "Antrean Pesanan (Kasir)",
                            subtitle: "Simpan sementara & panggil antrean transaksi di kasir",
                            value: enabled,
                            onChanged: (v) => SettingsController.instance.setFeatureAntreanPesananEnabled(v),
                            isDark: isDark,
                            showDivider: true,
                          );
                        },
                      ),
                      // 5. Tampilkan Numpad Kasir
                      ValueListenableBuilder<bool>(
                        valueListenable: SettingsController.instance.showNumpad,
                        builder: (context, showNumpad, child) {
                          return _buildFeatureToggle(
                            title: "Tampilkan Numpad Kasir",
                            subtitle: "Tampilkan keyboard angka virtual (matikan jika pakai mouse/keyboard fisik)",
                            value: showNumpad,
                            onChanged: (v) => SettingsController.instance.setShowNumpad(v),
                            isDark: isDark,
                            showDivider: true,
                          );
                        },
                      ),
                      // 6. Otomatis Buka Keyboard Kasir
                      ValueListenableBuilder<bool>(
                        valueListenable: SettingsController.instance.autoFocusKasirSearch,
                        builder: (context, autoFocus, child) {
                          return _buildFeatureToggle(
                            title: "Otomatis Buka Keyboard Kasir",
                            subtitle: "Otomatis fokus & buka keyboard pada kolom pencarian saat membuka halaman kasir (matikan jika ingin keyboard hanya muncul saat kolom diketuk)",
                            value: autoFocus,
                            onChanged: (v) => SettingsController.instance.setAutoFocusKasirSearch(v),
                            isDark: isDark,
                            showDivider: false,
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Center(
                  child: Text(
                    "Fitur yang dinonaktifkan akan disembunyikan dari menu utama agar aplikasi lebih ringan.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.openSans(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureToggle({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDark,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.openSans(
                        fontSize: 11,
                        color: isDark ? Colors.white54 : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              CupertinoSwitch(
                value: value,
                activeTrackColor: const Color(0xFF00BF63),
                onChanged: onChanged,
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1, 
            indent: 16, 
            endIndent: 16, 
            color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
          ),
      ],
    );
  }
}

