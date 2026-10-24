import 'package:flutter/material.dart';
import '../../core/app_theme.dart';

class ReceiptSettingsPage extends StatelessWidget {
  const ReceiptSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          "Atur Layout Struk",
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppTheme.defaultGradient),
        ),
        elevation: 0,
      ),
      body: const Center(
        child: Text("Fitur Pengaturan Layout segera hadir!"),
      ),
    );
  }
}
