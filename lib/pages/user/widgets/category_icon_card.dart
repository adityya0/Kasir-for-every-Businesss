import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CategoryIconCard extends StatelessWidget {
  final String label;
  final String? icon; // Can be an emoji for now as requested
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryIconCard({
    super.key,
    required this.label,
    this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryColor = Color(0xFF00BF63);

    // Smart mapping for common categories if icon is null
    String displayIcon = icon ?? _getSmartIcon(label);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 120,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withValues(alpha: 0.1)
              : (isDark ? const Color(0xFF2C2C2E) : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? primaryColor
                    : (isDark ? Colors.white10 : Colors.grey[100]),
                shape: BoxShape.circle,
              ),
              child: Text(displayIcon, style: const TextStyle(fontSize: 24)),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? primaryColor
                    : (isDark ? Colors.white70 : Colors.black87),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  String _getSmartIcon(String categoryName) {
    final name = categoryName.toLowerCase();
    if (name.contains('burger')) return '🍔';
    if (name.contains('pizza')) return '🍕';
    if (name.contains('donut')) return '🍩';
    if (name.contains('ice')) return '🍦';
    if (name.contains('drink') || name.contains('minum')) return '🥤';
    if (name.contains('coffee') || name.contains('kopi')) return '☕';
    if (name.contains('chicken') || name.contains('ayam')) return '🍗';
    if (name.contains('potato') || name.contains('kentang')) return '🍟';
    if (name.contains('noodle') || name.contains('mi')) return '🍜';
    if (name.contains('snack')) return '🍿';
    if (name.contains('bread') || name.contains('roti')) return '🍞';
    return '🍱'; // Default
  }
}

