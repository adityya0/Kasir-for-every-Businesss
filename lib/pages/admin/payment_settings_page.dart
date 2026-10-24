import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../controllers/admin_controller.dart';
import '../../services/app_database.dart';
import '../../services/platform/file_manager.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:drift/drift.dart' show Value;

class PaymentSettingsPage extends StatefulWidget {
  final String storeId;
  const PaymentSettingsPage({super.key, required this.storeId});

  @override
  State<PaymentSettingsPage> createState() => _PaymentSettingsPageState();
}

class _PaymentSettingsPageState extends State<PaymentSettingsPage> {
  final Color _primaryColor = const Color(0xFFC0392B);

  @override
  Widget build(BuildContext context) {
    final adminCtrl = context.read<AdminController>();
    final service = adminCtrl.paymentMethodService;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Metode Pembayaran",
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
      ),
      body: StreamBuilder<List<PaymentMethod>>(
        stream: service.watchActivePaymentMethods(
          widget.storeId,
        ), // Note: The service name for all might be better
        builder: (context, snapshot) {
          // We actually want to see all, not just active, in settings
          return FutureBuilder<List<PaymentMethod>>(
            future: service.getPaymentMethods(widget.storeId),
            builder: (context, futureSnapshot) {
              if (futureSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final methods = futureSnapshot.data ?? [];

              if (methods.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: methods.length,
                itemBuilder: (context, index) {
                  final method = methods[index];
                  return _buildMethodCard(method, isDark);
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditMethodDialog(),
        backgroundColor: _primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          "Tambah Metode",
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.payments_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "Belum ada metode pembayaran",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Klik tombol di bawah untuk menambah",
            style: GoogleFonts.openSans(fontSize: 13, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodCard(PaymentMethod method, bool isDark) {
    IconData iconData;
    switch (method.type) {
      case 'qris':
        iconData = Icons.qr_code_scanner;
        break;
      case 'ewallet':
        iconData = Icons.account_balance_wallet;
        break;
      default:
        iconData = Icons.payments_outlined;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: _primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(iconData, color: _primaryColor),
        ),
        title: Text(
          method.name,
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (method.username != null && method.username!.isNotEmpty)
              Text(
                "User: ${method.username}",
                style: GoogleFonts.openSans(fontSize: 12),
              ),
            if (method.details != null && method.details!.isNotEmpty)
              Text(
                "No: ${method.details}",
                style: GoogleFonts.openSans(fontSize: 12),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: method.isActive,
              activeThumbColor: _primaryColor,
              onChanged: (val) async {
                final service = context
                    .read<AdminController>()
                    .paymentMethodService;
                await service.togglePaymentMethodActive(method.id, val);
                if (mounted) setState(() {});
              },
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _showAddEditMethodDialog(method: method),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _confirmDelete(method),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddEditMethodDialog({PaymentMethod? method}) async {
    final nameCtrl = TextEditingController(text: method?.name);
    final detailsCtrl = TextEditingController(text: method?.details);
    final usernameCtrl = TextEditingController(text: method?.username);
    String type = method?.type ?? 'qris';
    String? qrisUrl = method?.qrisUrl;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          return Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1C1E) : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
              left: 24,
              right: 24,
              top: 32,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _primaryColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          method == null
                              ? Icons.add_rounded
                              : Icons.edit_rounded,
                          color: _primaryColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        method == null ? "Tambah Metode" : "Edit Metode",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Tipe Selector
                  Text(
                    "Tipe Pembayaran",
                    style: GoogleFonts.openSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildTypeCard(
                        ss,
                        'qris',
                        Icons.qr_code_scanner_rounded,
                        'QRIS',
                        type == 'qris',
                        isDark,
                        (val) => ss(() => type = val),
                      ),
                      const SizedBox(width: 12),
                      _buildTypeCard(
                        ss,
                        'ewallet',
                        Icons.account_balance_wallet_rounded,
                        'E-Wallet',
                        type == 'ewallet',
                        isDark,
                        (val) => ss(() => type = val),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  _buildModernField(
                    controller: nameCtrl,
                    label: "Nama Metode",
                    hint: "Contoh: Dana, GoPay, QRIS BCA",
                    icon: Icons.payments_rounded,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                  _buildModernField(
                    controller: detailsCtrl,
                    label: "Nomor Rekening / ID",
                    hint: "Masukkan nomor atau ID anda",
                    icon: Icons.numbers_rounded,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                  _buildModernField(
                    controller: usernameCtrl,
                    label: "Nama Account (Atas Nama)",
                    hint: "Contoh: Aditya Maulana",
                    icon: Icons.person_rounded,
                    isDark: isDark,
                  ),

                  if (type == 'qris') ...[
                    const SizedBox(height: 24),
                    Text(
                      "Foto QRIS",
                      style: GoogleFonts.openSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () async {
                        final picker = ImagePicker();
                        final image = await picker.pickImage(
                          source: ImageSource.gallery,
                        );
                        if (image != null) {
                          final fileName =
                              'qris_${DateTime.now().millisecondsSinceEpoch}${p.extension(image.path)}';
                          final savedPath = await FileManager().saveFile(
                            image,
                            fileName,
                          );
                          ss(() => qrisUrl = savedPath);
                        }
                      },
                      child: Container(
                        height: 180,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.grey[50],
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: qrisUrl != null
                                ? _primaryColor
                                : Colors.grey.withValues(alpha: 0.2),
                            width: 2,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: qrisUrl != null
                            ? Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(22),
                                    child: Center(
                                      child: Image(
                                        image: FileManager().getImageProvider(
                                          qrisUrl!,
                                        ),
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 12,
                                    right: 12,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black12,
                                            blurRadius: 8,
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.edit_rounded,
                                        size: 16,
                                        color: _primaryColor,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: _primaryColor.withValues(
                                        alpha: 0.1,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.add_a_photo_rounded,
                                      size: 32,
                                      color: _primaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    "Tap untuk Upload QRIS",
                                    style: GoogleFonts.openSans(
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (nameCtrl.text.isEmpty) return;
                        final adminCtrl = context.read<AdminController>();
                        final service = adminCtrl.paymentMethodService;

                        if (method == null) {
                          await service.createPaymentMethod(
                            storeId: widget.storeId,
                            name: nameCtrl.text,
                            type: type,
                            details: detailsCtrl.text,
                            username: usernameCtrl.text,
                            qrisUrl: qrisUrl,
                          );
                        } else {
                          final updated = method.copyWith(
                            name: nameCtrl.text,
                            type: type,
                            details: Value(detailsCtrl.text),
                            username: Value(usernameCtrl.text),
                            qrisUrl: Value(qrisUrl),
                          );
                          await service.updatePaymentMethod(updated);
                        }
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          setState(() {});
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Text(
                        method == null ? "Simpan Metode" : "Update Metode",
                        style: GoogleFonts.openSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTypeCard(
    StateSetter ss,
    String value,
    IconData icon,
    String label,
    bool isSelected,
    bool isDark,
    Function(String) onSelect,
  ) {
    return Expanded(
      child: InkWell(
        onTap: () => onSelect(value),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? _primaryColor.withValues(alpha: 0.1)
                : (isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.grey[50]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? _primaryColor : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? _primaryColor : Colors.grey[600],
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.openSans(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? _primaryColor : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.openSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: GoogleFonts.openSans(fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.openSans(color: Colors.grey[400], fontSize: 14),
            prefixIcon: Icon(icon, color: Colors.grey[400], size: 20),
            filled: true,
            fillColor: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFFC0392B),
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(PaymentMethod method) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus Metode?"),
        content: Text("Yakin ingin menghapus '${method.name}'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Hapus", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final service = context.read<AdminController>().paymentMethodService;
      await service.deletePaymentMethod(method.id);
      if (mounted) setState(() {});
    }
  }
}

