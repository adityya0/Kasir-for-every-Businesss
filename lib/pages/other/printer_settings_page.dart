import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/bluetooth_printer_service.dart';
import '../../widgets/kasir_drawer.dart';

class PrinterSettingsPage extends StatefulWidget {
  final bool showSidebar;
  final VoidCallback? onMenuPressed;
  final VoidCallback? onBack;
  final VoidCallback? onNavigateToStruk;

  const PrinterSettingsPage({
    super.key,
    this.showSidebar = true,
    this.onMenuPressed,
    this.onBack,
    this.onNavigateToStruk,
  });

  @override
  State<PrinterSettingsPage> createState() => _PrinterSettingsPageState();
}

class _PrinterSettingsPageState extends State<PrinterSettingsPage> {
  final BluetoothPrinterService _printerService = BluetoothPrinterService();
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _selectedDevice;
  bool _connected = false;
  bool _isScanning = false;
  bool _isConnecting = false;

  static const Color primaryColor = Color(0xFFC0392B);

  @override
  void initState() {
    super.initState();
    _initBluetooth();
  }

  void _initBluetooth() async {
    try {
      bool? isConnected = await _printerService.isConnectedStatus;
      if (mounted) setState(() => _connected = isConnected ?? false);
    } catch (e) {
      debugPrint("Bluetooth check error: $e");
    }
    _getDevices();
  }

  void _getDevices() async {
    setState(() => _isScanning = true);
    try {
      List<BluetoothDevice> devices = await _printerService.getBondedDevices();
      if (mounted) {
        setState(() {
          _devices = devices;
          _isScanning = false;
          if (_selectedDevice == null && devices.isNotEmpty) {
            _selectedDevice = devices.first;
          }
        });
      }
    } catch (e) {
      debugPrint("Bluetooth scan failed: $e");
      if (mounted) setState(() => _isScanning = false);
    }
  }

  void _connect() async {
    if (_selectedDevice == null) return;
    setState(() => _isConnecting = true);

    try {
      final success = await _printerService.connect(_selectedDevice!);
      if (mounted) {
        setState(() {
          _connected = success;
          _isConnecting = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? "✓ Berhasil terhubung ke ${_selectedDevice!.name ?? 'Printer'}!"
                  : "Gagal terhubung ke printer. Pastikan printer menyala.",
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
            ),
            backgroundColor: success ? const Color(0xFF10B981) : Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isConnecting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error koneksi: $e"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _disconnect() async {
    setState(() => _isConnecting = true);
    try {
      await _printerService.disconnect();
      if (mounted) {
        setState(() {
          _connected = false;
          _isConnecting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Koneksi printer diputuskan."),
            backgroundColor: Colors.grey.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _isConnecting = false);
    }
  }

  void _testPrint() async {
    try {
      await _printerService.testPrint();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("✓ Perintah test print telah dikirim."),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal mencetak: $e"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF374151) : const Color(0xFFCBD5E1);
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
      drawer: widget.showSidebar ? const KasirDrawer(currentRoute: '/printer-settings') : null,
      appBar: AppBar(
        title: Text(
          "Pengaturan Printer",
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
        leading: widget.onBack != null
            ? IconButton(
                icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                onPressed: widget.onBack,
              )
            : (Navigator.canPop(context)
                ? IconButton(
                    icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                    onPressed: () => Navigator.pop(context),
                  )
                : (widget.onMenuPressed != null
                    ? IconButton(
                        icon: Icon(Icons.menu, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                        onPressed: widget.onMenuPressed,
                      )
                    : null)),
        actions: [
          IconButton(
            icon: _isScanning
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor),
                  )
                : const Icon(Icons.refresh_rounded),
            tooltip: "Pindai Ulang Perangkat",
            onPressed: _isScanning ? null : _getDevices,
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: borderColor, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── 1. Status Koneksi Banner (Outline Style) ─────────────────
                _buildStatusBanner(isDark, borderColor),
                const SizedBox(height: 20),

                // ── 2. Pilih Perangkat (Outline Dropdown Card) ────────────────
                _buildSectionHeader("PILIH PERANGKAT PRINTER", isDark),
                const SizedBox(height: 10),
                _buildDeviceCard(isDark, borderColor, cardBg),
                const SizedBox(height: 24),

                // ── 3. Aksi & Kontrol Praktikal (Outline Card) ───────────────
                _buildSectionHeader("AKSI & KONTROL", isDark),
                const SizedBox(height: 10),
                _buildActionControlCard(isDark, borderColor, cardBg),
                const SizedBox(height: 24),

                // ── 4. Panduan & Tips Praktis (Outline Card) ─────────────────
                _buildSectionHeader("PANDUAN KONEKSI", isDark),
                const SizedBox(height: 10),
                _buildGuideCard(isDark, borderColor, cardBg),
                const SizedBox(height: 36),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Status Banner ─────────────────────────────────────────────────────────
  Widget _buildStatusBanner(bool isDark, Color borderColor) {
    if (_connected) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0xFF10B981).withValues(alpha: 0.35),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF10B981),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Printer Terhubung & Siap",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF047857),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _selectedDevice?.name ?? "Printer Thermal Aktif",
                    style: GoogleFonts.openSans(
                      fontSize: 12,
                      color: isDark ? Colors.white70 : const Color(0xFF065F46),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                "Online",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFEF4444).withValues(alpha: 0.3),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.print_disabled_rounded,
              color: Color(0xFFEF4444),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Printer Belum Terhubung",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFB91C1C),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Pilih perangkat printer di bawah lalu tekan Hubungkan",
                  style: GoogleFonts.openSans(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : const Color(0xFF7F1D1D),
                  ),
                ),
              ],
            ),
          ),
          if (_isScanning)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFEF4444)),
            ),
        ],
      ),
    );
  }

  // ─── Device Selector Card ──────────────────────────────────────────────────
  Widget _buildDeviceCard(bool isDark, Color borderColor, Color cardBg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Daftar Printer Bluetooth (${_devices.length})",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                ),
              ),
              InkWell(
                onTap: _isScanning ? null : _getDevices,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(
                    children: [
                      Icon(Icons.sync_rounded, size: 14, color: isDark ? Colors.white60 : primaryColor),
                      const SizedBox(width: 4),
                      Text(
                        _isScanning ? "Memindai..." : "Pindai Ulang",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white60 : primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Dropdown Input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<BluetoothDevice>(
                isExpanded: true,
                value: _selectedDevice,
                hint: Row(
                  children: [
                    const Icon(Icons.print_outlined, size: 18, color: Colors.grey),
                    const SizedBox(width: 10),
                    Text(
                      _devices.isEmpty
                          ? (_isScanning ? "Sedang memindai bluetooth..." : "Tidak ada printer bluetooth terdeteksi")
                          : "Pilih Printer Thermal...",
                      style: GoogleFonts.openSans(
                        fontSize: 13,
                        color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
                dropdownColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                items: _devices.map((device) {
                  return DropdownMenuItem<BluetoothDevice>(
                    value: device,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.print_rounded, size: 16, color: primaryColor),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                device.name ?? "Perangkat Tanpa Nama",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                device.address ?? "",
                                style: GoogleFonts.openSans(
                                  fontSize: 11,
                                  color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() => _selectedDevice = val);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Action & Control Card ─────────────────────────────────────────────────
  Widget _buildActionControlCard(bool isDark, Color borderColor, Color cardBg) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Action 1: Connect / Disconnect
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            leading: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: _connected
                    ? const Color(0xFFEF4444).withValues(alpha: 0.1)
                    : primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _connected ? Icons.bluetooth_disabled_rounded : Icons.bluetooth_connected_rounded,
                color: _connected ? const Color(0xFFEF4444) : primaryColor,
                size: 20,
              ),
            ),
            title: Text(
              _connected ? "Putuskan Koneksi Printer" : "Hubungkan Printer",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _connected
                    ? const Color(0xFFEF4444)
                    : (isDark ? Colors.white : const Color(0xFF0F172A)),
              ),
            ),
            subtitle: Text(
              _connected
                  ? "Saat ini terhubung ke ${_selectedDevice?.name ?? 'printer'}"
                  : (_selectedDevice != null
                      ? "Sambungkan ke ${_selectedDevice!.name ?? 'printer'}"
                      : "Pilih perangkat terlebih dahulu"),
              style: GoogleFonts.openSans(
                fontSize: 12,
                color: isDark ? Colors.white54 : const Color(0xFF64748B),
              ),
            ),
            trailing: _isConnecting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor),
                  )
                : ElevatedButton(
                    onPressed: _connected
                        ? _disconnect
                        : (_selectedDevice != null ? _connect : null),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _connected ? const Color(0xFFEF4444) : primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      _connected ? "Putuskan" : "Hubungkan",
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                  ),
          ),
          Divider(height: 1, indent: 56, color: borderColor),

          // Action 2: Test Print
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            leading: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                color: Color(0xFF10B981),
                size: 20,
              ),
            ),
            title: Text(
              "Cetak Test Struk",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            subtitle: Text(
              "Kirim perintah cetak uji coba untuk mengecek koneksi printer",
              style: GoogleFonts.openSans(
                fontSize: 12,
                color: isDark ? Colors.white54 : const Color(0xFF64748B),
              ),
            ),
            trailing: OutlinedButton.icon(
              onPressed: _connected ? _testPrint : null,
              icon: const Icon(Icons.print_rounded, size: 16),
              label: Text(
                "Test Print",
                style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF10B981),
                side: BorderSide(
                  color: _connected
                      ? const Color(0xFF10B981)
                      : (isDark ? Colors.white24 : Colors.grey.shade300),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          Divider(height: 1, indent: 56, color: borderColor),

          // Action 3: Template Struk Navigation
          ListTile(
            onTap: widget.onNavigateToStruk,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            leading: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.tune_rounded,
                color: Color(0xFFF59E0B),
                size: 20,
              ),
            ),
            title: Text(
              "Pengaturan Format & Template Struk",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            subtitle: Text(
              "Atur logo, header, footer, ukuran kertas, dan teks struk kasir",
              style: GoogleFonts.openSans(
                fontSize: 12,
                color: isDark ? Colors.white54 : const Color(0xFF64748B),
              ),
            ),
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: isDark ? Colors.white38 : Colors.grey.shade400,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Guide Card ────────────────────────────────────────────────────────────
  Widget _buildGuideCard(bool isDark, Color borderColor, Color cardBg) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFFF59E0B), size: 18),
              const SizedBox(width: 8),
              Text(
                "Tips & Petunjuk Koneksi Printer",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildGuideStep("1", "Hidupkan Bluetooth perangkat Anda dan printer thermal."),
          const SizedBox(height: 6),
          _buildGuideStep("2", "Pastikan printer sudah di-pairing di menu Bluetooth perangkat (PIN biasanya 0000 atau 1234)."),
          const SizedBox(height: 6),
          _buildGuideStep("3", "Pilih nama printer di dropdown atas lalu tekan tombol [Hubungkan]."),
        ],
      ),
    );
  }

  Widget _buildGuideStep(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          margin: const EdgeInsets.only(top: 1),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFB45309),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.openSans(
              fontSize: 12,
              color: const Color(0xFF64748B),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: isDark ? Colors.white60 : const Color(0xFF64748B),
        ),
      ),
    );
  }
}
