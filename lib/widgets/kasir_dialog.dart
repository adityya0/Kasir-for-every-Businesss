import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class KasirDialog extends StatelessWidget {
  final String title;
  final String? message;
  final Widget? content;
  final IconData? icon;
  final Color? iconColor;
  final List<Widget>? actions;
  final String? primaryActionLabel;
  final VoidCallback? onPrimaryAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final bool isDestructive;

  const KasirDialog({
    super.key,
    required this.title,
    this.message,
    this.content,
    this.icon,
    this.iconColor,
    this.actions,
    this.primaryActionLabel,
    this.onPrimaryAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = iconColor ?? theme.primaryColor;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Icon/Illustration
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 36, color: primaryColor),
                ),
                const SizedBox(height: 24),
              ],

              // Title
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF2D3436),
                  height: 1.2,
                ),
              ),

              // Message or Content
              if (message != null || content != null) ...[
                const SizedBox(height: 16),
                content ??
                    Text(
                      message!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.openSans(
                        fontSize: 15,
                        color: isDark ? Colors.white60 : Colors.grey[600],
                        height: 1.5,
                      ),
                    ),
              ],

              const SizedBox(height: 32),

              // Actions
              if (actions != null)
                Row(
                  children: actions!
                      .map(
                        (a) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: a,
                          ),
                        ),
                      )
                      .toList(),
                )
              else if (primaryActionLabel != null)
                Row(
                  children: [
                    if (secondaryActionLabel != null)
                      Expanded(
                        child: TextButton(
                          onPressed:
                              onSecondaryAction ?? () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: Text(
                            secondaryActionLabel!,
                            style: GoogleFonts.openSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                    if (secondaryActionLabel != null) const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onPrimaryAction,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDestructive
                              ? Colors.redAccent
                              : primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          shadowColor:
                              (isDestructive ? Colors.redAccent : primaryColor)
                                  .withValues(alpha: 0.3),
                        ),
                        child: Text(
                          primaryActionLabel!,
                          style: GoogleFonts.openSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
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
}

