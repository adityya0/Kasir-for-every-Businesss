import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomNumpad extends StatelessWidget {
  final Function(String) onTap;
  final VoidCallback onConfirm;
  final Color? backgroundColor;
  final Color? buttonColor;
  final Color? textColor;

  const CustomNumpad({
    super.key,
    required this.onTap,
    required this.onConfirm,
    this.backgroundColor,
    this.buttonColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBtnColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.grey[100]!;
    final defaultTextColor = isDark ? Colors.white : Colors.black87;

    return LayoutBuilder(
      builder: (context, constraints) {
        // To achieve a 3:4 (width:height) ratio for EACH button:
        // Width of one button = slotWidth
        // Height of one button = slotWidth * (4 / 3)
        final double slotWidth = constraints.maxWidth / 4;
        final double rowHeight = slotWidth * (4 / 3);
        final double fontSize = (slotWidth * 0.25).clamp(16, 22);
        final double iconSize = (slotWidth * 0.3).clamp(20, 28);
        final double confirmIconSize = (slotWidth * 0.4).clamp(28, 40);

        return SizedBox(
          height: rowHeight * 4,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left Side: Numeric Grid (3 columns, 4 rows)
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    _buildSquareRow([
                      _buildGridButton(
                        "7",
                        defaultBtnColor,
                        defaultTextColor,
                        fontSize,
                        iconSize,
                      ),
                      _buildGridButton(
                        "8",
                        defaultBtnColor,
                        defaultTextColor,
                        fontSize,
                        iconSize,
                      ),
                      _buildGridButton(
                        "9",
                        defaultBtnColor,
                        defaultTextColor,
                        fontSize,
                        iconSize,
                      ),
                    ], rowHeight),
                    _buildSquareRow([
                      _buildGridButton(
                        "4",
                        defaultBtnColor,
                        defaultTextColor,
                        fontSize,
                        iconSize,
                      ),
                      _buildGridButton(
                        "5",
                        defaultBtnColor,
                        defaultTextColor,
                        fontSize,
                        iconSize,
                      ),
                      _buildGridButton(
                        "6",
                        defaultBtnColor,
                        defaultTextColor,
                        fontSize,
                        iconSize,
                      ),
                    ], rowHeight),
                    _buildSquareRow([
                      _buildGridButton(
                        "1",
                        defaultBtnColor,
                        defaultTextColor,
                        fontSize,
                        iconSize,
                      ),
                      _buildGridButton(
                        "2",
                        defaultBtnColor,
                        defaultTextColor,
                        fontSize,
                        iconSize,
                      ),
                      _buildGridButton(
                        "3",
                        defaultBtnColor,
                        defaultTextColor,
                        fontSize,
                        iconSize,
                      ),
                    ], rowHeight),
                    _buildSquareRow([
                      _buildGridButton(
                        "0",
                        defaultBtnColor,
                        defaultTextColor,
                        fontSize,
                        iconSize,
                      ),
                      _buildGridButton(
                        "000",
                        defaultBtnColor,
                        defaultTextColor,
                        fontSize,
                        iconSize,
                      ),
                      _buildGridButton(
                        ".",
                        defaultBtnColor,
                        defaultTextColor,
                        fontSize,
                        iconSize,
                      ),
                    ], rowHeight),
                  ],
                ),
              ),
              // Right Side: Action Column (C, Backspace, Confirm)
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    _buildGridButton(
                      "C",
                      Colors.red.withValues(alpha: 0.1),
                      Colors.red,
                      fontSize,
                      iconSize,
                    ),
                    _buildGridButton(
                      "backspace",
                      defaultBtnColor,
                      defaultTextColor,
                      fontSize,
                      iconSize,
                      icon: Icons.backspace_outlined,
                    ),
                    _buildConfirmButton(context, confirmIconSize),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSquareRow(List<Widget> children, double height) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _buildGridButton(
    String value,
    Color color,
    Color tColor,
    double fSize,
    double iSize, {
    IconData? icon,
  }) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: tColor.withValues(alpha: 0.08), width: 1.0),
        ),
        child: Material(
          color: color,
          child: InkWell(
            onTap: () => onTap(value),
            child: Center(
              child: icon != null
                  ? Icon(icon, color: tColor, size: iSize)
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

  Widget _buildConfirmButton(BuildContext context, double iSize) {
    const primaryColor = Color(0xFFC0392B);
    return Expanded(
      flex: 2,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1.0,
          ),
        ),
        child: Material(
          color: primaryColor,
          elevation: 0,
          child: InkWell(
            onTap: onConfirm,
            child: Center(
              child: Icon(
                Icons.check_circle_outline,
                color: Colors.white,
                size: iSize,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

