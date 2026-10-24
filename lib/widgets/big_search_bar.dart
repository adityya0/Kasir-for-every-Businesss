import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BigSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final bool autoFocus;

  const BigSearchBar({
    super.key,
    required this.controller,
    this.hintText = "Cari...",
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.autoFocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: isDark ? const Color(0xFF374151) : const Color(0xFFCBD5E1),
          width: 1.2,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.center,
      child: TextField(
        controller: controller,
        autofocus: autoFocus,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        textAlignVertical: TextAlignVertical.center,
        style: GoogleFonts.openSans(
          fontSize: 16,
          color: isDark ? Colors.white : Colors.black87,
        ),
        decoration: InputDecoration(
          isDense: true,
          hintText: hintText,
          hintStyle: GoogleFonts.openSans(
            color: isDark ? Colors.white38 : Colors.grey[400],
            fontSize: 15,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Icon(
              Icons.search,
              size: 24,
              color: isDark ? Colors.white38 : Colors.grey[400],
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 24,
            minHeight: 24,
          ),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.cancel,
                    size: 20,
                    color: Colors.grey[400],
                  ),
                  onPressed: onClear ?? controller.clear,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 20,
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}