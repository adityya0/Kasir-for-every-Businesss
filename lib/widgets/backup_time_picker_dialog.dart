import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BackupTimePickerDialog extends StatefulWidget {
  final TimeOfDay initialTime;

  const BackupTimePickerDialog({
    super.key,
    required this.initialTime,
  });

  static Future<TimeOfDay?> show(BuildContext context, {required TimeOfDay initialTime}) {
    return showDialog<TimeOfDay>(
      context: context,
      barrierDismissible: true,
      builder: (context) => BackupTimePickerDialog(initialTime: initialTime),
    );
  }

  @override
  State<BackupTimePickerDialog> createState() => _BackupTimePickerDialogState();
}

class _BackupTimePickerDialogState extends State<BackupTimePickerDialog> {
  late int _hour;
  late int _minute;

  @override
  void initState() {
    super.initState();
    _hour = widget.initialTime.hour;
    _minute = widget.initialTime.minute;
  }

  void _setPreset(int hour, int minute) {
    setState(() {
      _hour = hour;
      _minute = minute;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const accentColor = Color(0xFF00897B); // Teal elegan

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.alarm_rounded, size: 32, color: accentColor),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                "Atur Jam Pencadangan",
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF2D3436),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Pilih jam otomatisasi backup harian ke Google Drive",
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
              const SizedBox(height: 28),

              // Digital Time Controls (Jam & Menit)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildTimeBox(
                    label: "JAM",
                    value: _hour,
                    isDark: isDark,
                    accentColor: accentColor,
                    onIncrement: () => setState(() => _hour = (_hour + 1) % 24),
                    onDecrement: () => setState(() => _hour = (_hour - 1 + 24) % 24),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          ":",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white38 : Colors.grey.shade400,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                  _buildTimeBox(
                    label: "MENIT",
                    value: _minute,
                    isDark: isDark,
                    accentColor: accentColor,
                    onIncrement: () => setState(() => _minute = (_minute + 1) % 60),
                    onDecrement: () => setState(() => _minute = (_minute - 1 + 60) % 60),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Pilihan Cepat (Presets)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Pilihan Cepat",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white54 : Colors.grey.shade600,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildPresetChip("23:59 (Tengah Malam)", 23, 59, isDark, accentColor),
                  _buildPresetChip("23:00", 23, 0, isDark, accentColor),
                  _buildPresetChip("22:00", 22, 0, isDark, accentColor),
                  _buildPresetChip("21:00", 21, 0, isDark, accentColor),
                  _buildPresetChip("00:00", 0, 0, isDark, accentColor),
                ],
              ),

              const SizedBox(height: 32),

              // Actions Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        "Batal",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(
                          context,
                          TimeOfDay(hour: _hour, minute: _minute),
                        );
                      },
                      icon: const Icon(Icons.check_rounded, size: 20),
                      label: Text(
                        "Simpan Jadwal",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
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
    );
  }

  Widget _buildTimeBox({
    required String label,
    required int value,
    required bool isDark,
    required Color accentColor,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
  }) {
    return Container(
      width: 110,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF7F9FB),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade200,
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onIncrement,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                alignment: Alignment.center,
                child: Icon(
                  Icons.keyboard_arrow_up_rounded,
                  size: 28,
                  color: isDark ? Colors.white70 : Colors.grey.shade700,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              value.toString().padLeft(2, '0'),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 46,
                fontWeight: FontWeight.w800,
                color: accentColor,
                letterSpacing: -1,
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onDecrement,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                alignment: Alignment.center,
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 28,
                  color: isDark ? Colors.white70 : Colors.grey.shade700,
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: isDark ? Colors.white38 : Colors.grey.shade500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetChip(
    String label,
    int hour,
    int minute,
    bool isDark,
    Color accentColor,
  ) {
    final isSelected = _hour == hour && _minute == minute;

    return InkWell(
      onTap: () => _setPreset(hour, minute),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withValues(alpha: 0.15)
              : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? accentColor : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? accentColor
                : (isDark ? Colors.white70 : Colors.grey.shade700),
          ),
        ),
      ),
    );
  }
}
