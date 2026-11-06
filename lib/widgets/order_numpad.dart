import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum OrderNumpadMode { qty, disc, price }

class OrderNumpad extends StatelessWidget {
  final OrderNumpadMode mode;
  final Function(OrderNumpadMode) onModeChanged;
  final Function(String) onTap;
  final VoidCallback onBackspace;
  final VoidCallback onToggleSign;
  final VoidCallback? onConfirm; // Added for flexibility
  final bool showConfirm; // Added to toggle confirm button visibility

  const OrderNumpad({
    super.key,
    required this.mode,
    required this.onModeChanged,
    required this.onTap,
    required this.onBackspace,
    required this.onToggleSign,
    this.onConfirm,
    this.showConfirm = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBtnColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.grey[100]!;
    const activeBtnColor = Color(0xFF00BF63);
    final defaultTextColor = isDark ? Colors.white : Colors.black87;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double slotWidth = constraints.maxWidth / 4;
        final double slotHeight = (constraints.maxHeight / 4).clamp(35, 55);
        final double fontSize = (slotWidth * 0.22).clamp(14, 18);
        final double totalHeight = slotHeight * 4;

        return SizedBox(
          height: totalHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Numbers Grid (3 columns)
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    _buildRow([
                      _buildBtn(
                        "7",
                        defaultBtnColor,
                        defaultTextColor,
                        fontSize,
                      ),
                      _buildBtn(
                        "8",
                        defaultBtnColor,
                        defaultTextColor,
                        fontSize,
                      ),
                      _buildBtn(
                        "9",
                        defaultBtnColor,
                        defaultTextColor,
                        fontSize,
                      ),
                    ]),
                    _buildRow([
                      _buildBtn(
                        "4",
                        defaultBtnColor,
                        defaultTextColor,
                        fontSize,
                      ),
                      _buildBtn(
                        "5",
                        defaultBtnColor,
                        defaultTextColor,
                        fontSize,
                      ),
                      _buildBtn(
                        "6",
                        defaultBtnColor,
                        defaultTextColor,
                        fontSize,
                      ),
                    ]),
                    _buildRow([
                      _buildBtn(
                        "1",
                        defaultBtnColor,
                        defaultTextColor,
                        fontSize,
                      ),
                      _buildBtn(
                        "2",
                        defaultBtnColor,
                        defaultTextColor,
                        fontSize,
                      ),
                      _buildBtn(
                        "3",
                        defaultBtnColor,
                        defaultTextColor,
                        fontSize,
                      ),
                    ]),
                    _buildRow([
                      _buildBtn(
                        "0",
                        defaultBtnColor,
                        defaultTextColor,
                        fontSize,
                      ),
                      _buildBtn(
                        "000",
                        defaultBtnColor,
                        defaultTextColor,
                        fontSize,
                      ),
                      _buildBtn(
                        ".",
                        defaultBtnColor,
                        defaultTextColor,
                        fontSize,
                      ),
                    ]),
                  ],
                ),
              ),
              // Actions Column (1 column)
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    if (showConfirm) ...[
                      _buildBtn(
                        "C",
                        Colors.red.withValues(alpha: 0.05),
                        Colors.red,
                        fontSize,
                        onTap: () => onTap("C"),
                      ),
                      _buildBtn(
                        "",
                        defaultBtnColor,
                        defaultTextColor,
                        fontSize,
                      ),
                      _buildBtn(
                        "",
                        defaultBtnColor,
                        defaultTextColor,
                        fontSize,
                      ),
                      _buildBtn(
                        "backspace",
                        defaultBtnColor,
                        defaultTextColor,
                        fontSize,
                        icon: Icons.backspace_outlined,
                        onTap: onBackspace,
                      ),
                    ] else ...[
                      _buildModeBtn(
                        "Qty",
                        OrderNumpadMode.qty,
                        activeBtnColor,
                        defaultTextColor,
                        fontSize,
                      ),
                      _buildModeBtn(
                        "%",
                        OrderNumpadMode.disc,
                        activeBtnColor,
                        defaultTextColor,
                        fontSize,
                      ),
                      _buildModeBtn(
                        "Price",
                        OrderNumpadMode.price,
                        activeBtnColor,
                        defaultTextColor,
                        fontSize,
                      ),
                      _buildBtn(
                        "backspace",
                        defaultBtnColor,
                        defaultTextColor,
                        fontSize,
                        icon: Icons.backspace_outlined,
                        onTap: onBackspace,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRow(List<Widget> children) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _buildBtn(
    String value,
    Color color,
    Color tColor,
    double fSize, {
    IconData? icon,
    Function()? onTap,
  }) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: tColor.withValues(alpha: 0.05), width: 0.5),
        ),
        child: Material(
          color: color,
          child: InkWell(
            onTap: onTap ?? () => this.onTap(value),
            child: Center(
              child: icon != null
                  ? Icon(icon, color: tColor, size: fSize * 1.2)
                  : Text(
                      value,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: fSize,
                        fontWeight: FontWeight.w600,
                        color: tColor,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeBtn(
    String label,
    OrderNumpadMode targetMode,
    Color activeColor,
    Color tColor,
    double fSize,
  ) {
    final isActive = mode == targetMode;
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: tColor.withValues(alpha: 0.05), width: 0.5),
        ),
        child: Material(
          color: isActive
              ? activeColor
              : Colors.blueGrey.withValues(alpha: 0.1),
          child: InkWell(
            onTap: () => onModeChanged(targetMode),
            child: Center(
              child: Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: fSize * 0.9,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.white : tColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

