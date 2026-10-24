import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../services/app_database.dart';
import '../../../services/customer_service.dart';
import '../../../controllers/admin_controller.dart';
import '../../../widgets/kasir_dialog.dart';
import '../../../controllers/settings_controller.dart';

class CustomerPage extends StatefulWidget {
  final VoidCallback? onMenuPressed;
  final VoidCallback? onBack;
  final Function(int)? onNavigateToIndex;
  const CustomerPage({
    super.key,
    this.onMenuPressed,
    this.onBack,
    this.onNavigateToIndex,
  });

  @override
  State<CustomerPage> createState() => _CustomerPageState();
}

class _CustomerPageState extends State<CustomerPage>
    with SingleTickerProviderStateMixin {
  static const primaryColor = Color(0xFFC0392B); // Steak Asri Red
  bool _isLoading = true;
  List<Customer> _customers = [];
  late CustomerService _customerService;

  // Member promotions state
  List<Map<String, dynamic>> _memberPromos = [];
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  // Search state
  String _searchQuery = '';

  // Multi-select state
  bool _isSelecting = false;
  final Set<String> _selectedIds = {};

  late AnimationController _fabAnimController;
  late Animation<double> _fabScaleAnim;

  @override
  void initState() {
    super.initState();
    final db = context.read<AppDatabase>();
    _customerService = CustomerService(db);
    _fetchCustomers();
    _fetchMemberPromos();

    _fabAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _fabScaleAnim = CurvedAnimation(
      parent: _fabAnimController,
      curve: Curves.easeOutBack,
    );
  }

  @override
  void dispose() {
    _fabAnimController.dispose();
    super.dispose();
  }

  Future<void> _fetchCustomers() async {
    setState(() => _isLoading = true);
    try {
      final admin = context.read<AdminController>();
      if (admin.storeId != null) {
        final data = await _customerService.getCustomers(admin.storeId!);
        setState(() {
          _customers = data..sort((a, b) => (b.points).compareTo(a.points));
        });
      }
      await _fetchMemberPromos();
    } catch (e) {
      debugPrint("Error fetching customers: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchMemberPromos() async {
    try {
      final admin = context.read<AdminController>();
      if (admin.storeId != null) {
        final promos = await admin.promotionService.getMemberPromotions(admin.storeId!);
        if (mounted) {
          setState(() {
            _memberPromos = promos;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching member promos: $e");
    }
  }

  Map<String, dynamic>? _getPromoForCustomer(Customer c) {
    // 1. Cek promo khusus pelanggan ini
    for (var mp in _memberPromos) {
      final promo = mp['promo'] as Promotion;
      if (!promo.isActive) continue;
      final ids = mp['customerIds'] as List<String>;
      if (ids.contains(c.id)) {
        return mp;
      }
    }
    // 2. Cek promo untuk semua member (isAllMembers)
    for (var mp in _memberPromos) {
      final promo = mp['promo'] as Promotion;
      if (!promo.isActive) continue;
      if (mp['isAllMembers'] == true) {
        return mp;
      }
    }
    return null;
  }

  String _formatPromoValue(Promotion p) {
    final val = p.value ?? 0;
    if (p.discountType == 'percentage') {
      return "Diskon ${val.toStringAsFixed(val.truncateToDouble() == val ? 0 : 1)}%";
    } else {
      return "Diskon ${_currencyFormat.format(val)}";
    }
  }

  void _toggleSelectMode() {
    setState(() {
      _isSelecting = !_isSelecting;
      _selectedIds.clear();
    });
    if (_isSelecting) {
      _fabAnimController.forward();
    } else {
      _fabAnimController.reverse();
    }
  }

  void _toggleSelect(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _selectAll() {
    setState(() {
      if (_selectedIds.length == _filteredCustomers.length) {
        _selectedIds.clear();
      } else {
        _selectedIds.addAll(_filteredCustomers.map((c) => c.id));
      }
    });
  }

  List<Customer> get _filteredCustomers {
    if (_searchQuery.trim().isEmpty) return _customers;
    final q = _searchQuery.toLowerCase().trim();
    return _customers.where((c) {
      final name = (c.name ?? '').toLowerCase();
      final phone = (c.phoneNumber ?? '').toLowerCase();
      final email = (c.email ?? '').toLowerCase();
      return name.contains(q) || phone.contains(q) || email.contains(q);
    }).toList();
  }

  Future<void> _deleteSingle(Customer c) async {
    final confirmed = await _showDeleteConfirm(
      title: 'Hapus Pelanggan?',
      message:
          'Hapus "${c.name ?? 'pelanggan ini'}" dari daftar secara permanen?',
    );
    if (!confirmed) return;
    await _customerService.deleteCustomer(c.id);
    if (mounted) {
      _fetchCustomers();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${c.name ?? 'Pelanggan'} dihapus'),
          backgroundColor: primaryColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) return;
    final count = _selectedIds.length;
    final confirmed = await _showDeleteConfirm(
      title: 'Hapus $count Pelanggan?',
      message:
          'Tindakan ini tidak bisa dibatalkan. $count pelanggan akan dihapus secara permanen.',
    );
    if (!confirmed) return;
    await _customerService.deleteMultipleCustomers(_selectedIds.toList());
    if (mounted) {
      setState(() {
        _isSelecting = false;
        _selectedIds.clear();
        _fabAnimController.reverse();
      });
      _fetchCustomers();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$count pelanggan dihapus'),
          backgroundColor: primaryColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<bool> _showDeleteConfirm({
    required String title,
    required String message,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return KasirDialog(
          title: title,
          message: message,
          icon: Icons.delete_outline_rounded,
          iconColor: primaryColor,
          isDestructive: true,
          primaryActionLabel: "Hapus",
          onPrimaryAction: () => Navigator.pop(ctx, true),
          secondaryActionLabel: "Batal",
          onSecondaryAction: () => Navigator.pop(ctx, false),
        );
      },
    );
    return result == true;
  }

  void _showAddCustomerDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return KasirDialog(
          title: "Tambah Pelanggan Baru",
          icon: Icons.person_add_rounded,
          iconColor: primaryColor,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogTextField(
                controller: nameController,
                label: "Nama Lengkap",
                icon: Icons.person_outline_rounded,
                isDark: isDark,
              ),
              const SizedBox(height: 14),
              _buildDialogTextField(
                controller: phoneController,
                label: "No. HP",
                icon: Icons.phone_outlined,
                isDark: isDark,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 14),
              _buildDialogTextField(
                controller: emailController,
                label: "Email",
                icon: Icons.mail_outline_rounded,
                isDark: isDark,
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
          primaryActionLabel: "Simpan Pelanggan",
          onPrimaryAction: () async {
            if (nameController.text.trim().isNotEmpty) {
              final admin = context.read<AdminController>();
              await _customerService.addCustomer(
                storeId: admin.storeId!,
                name: nameController.text.trim(),
                phoneNumber: phoneController.text.trim(),
                email: emailController.text.trim(),
              );
              if (!context.mounted) return;
              Navigator.pop(context);
              _fetchCustomers();
            }
          },
          secondaryActionLabel: "Batal",
        );
      },
    );
  }

  Widget _buildDialogTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            fontSize: 12,
            color: isDark ? Colors.white70 : const Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
          decoration: InputDecoration(
            hintText: "Masukkan $label",
            hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.grey),
            prefixIcon: Icon(icon, color: primaryColor, size: 18),
            filled: true,
            fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                width: 1.2,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                width: 1.2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: primaryColor, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  void _showMemberDiscountDialog({
    Map<String, dynamic>? existingPromoData,
    Customer? preselectedCustomer,
  }) {
    final isEditing = existingPromoData != null;
    final Promotion? p = isEditing ? existingPromoData['promo'] as Promotion : null;

    final nameController = TextEditingController(
      text: p?.name ??
          (preselectedCustomer != null
              ? "Diskon Khusus ${preselectedCustomer.name ?? 'Member'}"
              : "Diskon Khusus Member"),
    );
    final valueController = TextEditingController(
      text: p?.value != null
          ? (p!.value!.truncateToDouble() == p.value!
              ? p.value!.toInt().toString()
              : p.value!.toString())
          : "10",
    );

    String discountType = p?.discountType ?? 'percentage';
    bool applyToAll = isEditing
        ? (existingPromoData['isAllMembers'] == true)
        : (preselectedCustomer == null);

    final Set<String> targetCustomerIds = {};
    if (isEditing) {
      final ids = (existingPromoData['customerIds'] as List<String>?) ?? [];
      targetCustomerIds.addAll(ids);
    } else if (preselectedCustomer != null) {
      targetCustomerIds.add(preselectedCustomer.id);
    }

    bool isActive = p?.isActive ?? true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        final isDark = Theme.of(sheetCtx).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(sheetCtx).size.height * 0.88,
                ),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle Bar
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.loyalty_rounded,
                              color: Color(0xFF10B981),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isEditing ? "Ubah Diskon Member" : "Pasang Diskon Member",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 17,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "Otomatis diterapkan saat kasir memilih member ini",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.pop(sheetCtx),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 24),

                    // Content
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Nama Program Diskon
                            _buildDialogTextField(
                              controller: nameController,
                              label: "Nama Program / Promo",
                              icon: Icons.title_rounded,
                              isDark: isDark,
                            ),
                            const SizedBox(height: 16),

                            // Nilai Diskon + Unit Switcher
                            Text(
                              "Besaran Diskon",
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                color: isDark ? Colors.white70 : const Color(0xFF475569),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: TextField(
                                    controller: valueController,
                                    keyboardType: TextInputType.number,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                    decoration: InputDecoration(
                                      hintText: discountType == 'percentage' ? "Contoh: 10" : "Contoh: 5000",
                                      prefixIcon: Icon(
                                        discountType == 'percentage'
                                            ? Icons.percent_rounded
                                            : Icons.attach_money_rounded,
                                        color: primaryColor,
                                        size: 18,
                                      ),
                                      filled: true,
                                      fillColor: isDark
                                          ? Colors.white.withValues(alpha: 0.05)
                                          : const Color(0xFFF8FAFC),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: primaryColor, width: 1.5),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  child: Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () => setModalState(() => discountType = 'percentage'),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: discountType == 'percentage'
                                                ? primaryColor
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            "%",
                                            style: GoogleFonts.plusJakartaSans(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                              color: discountType == 'percentage'
                                                  ? Colors.white
                                                  : (isDark ? Colors.white70 : Colors.black87),
                                            ),
                                          ),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () => setModalState(() => discountType = 'fixed'),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: discountType == 'fixed'
                                                ? primaryColor
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            "Rp",
                                            style: GoogleFonts.plusJakartaSans(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                              color: discountType == 'fixed'
                                                  ? Colors.white
                                                  : (isDark ? Colors.white70 : Colors.black87),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),

                            // Pilihan Target Pelanggan
                            Text(
                              "Berlaku Untuk",
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                color: isDark ? Colors.white70 : const Color(0xFF475569),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () => setModalState(() => applyToAll = true),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                                      decoration: BoxDecoration(
                                        color: applyToAll
                                            ? const Color(0xFF10B981).withValues(alpha: 0.12)
                                            : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: applyToAll ? const Color(0xFF10B981) : Colors.transparent,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.groups_rounded,
                                            size: 20,
                                            color: applyToAll ? const Color(0xFF10B981) : Colors.grey,
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            "Semua Member",
                                            style: GoogleFonts.plusJakartaSans(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12,
                                              color: applyToAll
                                                  ? const Color(0xFF10B981)
                                                  : (isDark ? Colors.white70 : const Color(0xFF475569)),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            "Semua pelanggan setia",
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 10,
                                              color: isDark ? Colors.white38 : Colors.grey[500],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: InkWell(
                                    onTap: () => setModalState(() => applyToAll = false),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                                      decoration: BoxDecoration(
                                        color: !applyToAll
                                            ? const Color(0xFF10B981).withValues(alpha: 0.12)
                                            : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: !applyToAll ? const Color(0xFF10B981) : Colors.transparent,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.person_rounded,
                                            size: 20,
                                            color: !applyToAll ? const Color(0xFF10B981) : Colors.grey,
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            "Member Tertentu",
                                            style: GoogleFonts.plusJakartaSans(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12,
                                              color: !applyToAll
                                                  ? const Color(0xFF10B981)
                                                  : (isDark ? Colors.white70 : const Color(0xFF475569)),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            "${targetCustomerIds.length} dipilih",
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 10,
                                              color: isDark ? Colors.white38 : Colors.grey[500],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            // Jika Member Tertentu dipilih: Daftar Checklist Pelanggan
                            if (!applyToAll) ...[
                              const SizedBox(height: 14),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Pilih Pelanggan (${targetCustomerIds.length}/${_customers.length})",
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white70 : const Color(0xFF475569),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      setModalState(() {
                                        if (targetCustomerIds.length == _customers.length) {
                                          targetCustomerIds.clear();
                                        } else {
                                          targetCustomerIds.addAll(_customers.map((c) => c.id));
                                        }
                                      });
                                    },
                                    child: Text(
                                      targetCustomerIds.length == _customers.length
                                          ? "Batal Semua"
                                          : "Pilih Semua",
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: primaryColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                constraints: const BoxConstraints(maxHeight: 180),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: _customers.isEmpty
                                    ? const Padding(
                                        padding: EdgeInsets.all(16),
                                        child: Center(child: Text("Belum ada pelanggan terdaftar")),
                                      )
                                    : ListView.builder(
                                        shrinkWrap: true,
                                        itemCount: _customers.length,
                                        itemBuilder: (ctx, idx) {
                                          final c = _customers[idx];
                                          final isChecked = targetCustomerIds.contains(c.id);
                                          return CheckboxListTile(
                                            value: isChecked,
                                            activeColor: primaryColor,
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                                            title: Text(
                                              c.name ?? "Pelanggan #${idx + 1}",
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                              ),
                                            ),
                                            subtitle: Text(
                                              c.phoneNumber ?? "Tanpa nomor HP",
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 11,
                                                color: isDark ? Colors.white38 : Colors.grey,
                                              ),
                                            ),
                                            onChanged: (val) {
                                              setModalState(() {
                                                if (val == true) {
                                                  targetCustomerIds.add(c.id);
                                                } else {
                                                  targetCustomerIds.remove(c.id);
                                                }
                                              });
                                            },
                                          );
                                        },
                                      ),
                              ),
                            ],

                            const SizedBox(height: 18),

                            // Switch Status Aktif
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Status Promosi",
                                        style: GoogleFonts.plusJakartaSans(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        ),
                                      ),
                                      Text(
                                        isActive ? "Diskon aktif digunakan" : "Diskon dinonaktifkan sementara",
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          color: isActive ? Colors.green : Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Switch.adaptive(
                                    value: isActive,
                                    activeTrackColor: const Color(0xFF10B981),
                                    onChanged: (val) => setModalState(() => isActive = val),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Actions Footer
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          if (isEditing) ...[
                            OutlinedButton.icon(
                              onPressed: () async {
                                final confirmed = await _showDeleteConfirm(
                                  title: "Hapus Promo Diskon?",
                                  message: "Promo diskon ini akan dihapus permanen.",
                                );
                                if (!confirmed) return;
                                if (!sheetCtx.mounted) return;
                                final admin = sheetCtx.read<AdminController>();
                                final messenger = ScaffoldMessenger.of(sheetCtx);
                                await admin.promotionService.deletePromotion(p!.id);
                                if (sheetCtx.mounted) {
                                  Navigator.pop(sheetCtx);
                                  _fetchMemberPromos();
                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content: Text("Promo diskon member dihapus"),
                                      backgroundColor: primaryColor,
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                              label: Text(
                                "Hapus",
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.redAccent),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            const SizedBox(width: 10),
                          ],
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                final val = double.tryParse(valueController.text.trim()) ?? 0;
                                if (val <= 0) {
                                  ScaffoldMessenger.of(sheetCtx).showSnackBar(
                                    const SnackBar(content: Text("Masukkan nilai diskon yang valid")),
                                  );
                                  return;
                                }
                                if (discountType == 'percentage' && val > 100) {
                                  ScaffoldMessenger.of(sheetCtx).showSnackBar(
                                    const SnackBar(content: Text("Diskon persen maksimal 100%")),
                                  );
                                  return;
                                }
                                if (!applyToAll && targetCustomerIds.isEmpty) {
                                  ScaffoldMessenger.of(sheetCtx).showSnackBar(
                                    const SnackBar(content: Text("Pilih minimal satu pelanggan")),
                                  );
                                  return;
                                }

                                final admin = sheetCtx.read<AdminController>();
                                if (admin.storeId == null) return;
                                final messenger = ScaffoldMessenger.of(sheetCtx);

                                await admin.promotionService.saveMemberDiscountPromotion(
                                  storeId: admin.storeId!,
                                  name: nameController.text.trim().isNotEmpty
                                      ? nameController.text.trim()
                                      : "Diskon Member",
                                  discountType: discountType,
                                  value: val,
                                  applyToAllMembers: applyToAll,
                                  selectedCustomerIds: targetCustomerIds.toList(),
                                  existingPromoId: p?.id,
                                  isActive: isActive,
                                );

                                if (sheetCtx.mounted) {
                                  Navigator.pop(sheetCtx);
                                  _fetchMemberPromos();
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        isEditing
                                            ? "Diskon member berhasil diperbarui!"
                                            : "Diskon member berhasil dibuat dan aktif!",
                                      ),
                                      backgroundColor: const Color(0xFF10B981),
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              child: Text(
                                isEditing ? "Simpan Perubahan" : "Terapkan Diskon Member",
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMemberDiscountCard(bool isDark) {
    final activeMemberPromos = _memberPromos.where((mp) {
      final p = mp['promo'] as Promotion;
      return p.isActive;
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: activeMemberPromos.isNotEmpty
              ? const Color(0xFF10B981).withValues(alpha: 0.4)
              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: activeMemberPromos.isNotEmpty
                ? const Color(0xFF10B981).withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.discount_rounded,
                  color: Color(0xFF10B981),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Diskon Khusus Member",
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      "Integrasi promo otomatis di struk",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: isDark ? Colors.white54 : const Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: activeMemberPromos.isNotEmpty
                      ? const Color(0xFF10B981).withValues(alpha: 0.12)
                      : (isDark ? Colors.white10 : Colors.grey[200]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: activeMemberPromos.isNotEmpty
                            ? const Color(0xFF10B981)
                            : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      activeMemberPromos.isNotEmpty ? "Aktif" : "Nonaktif",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: activeMemberPromos.isNotEmpty
                            ? const Color(0xFF059669)
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (activeMemberPromos.isNotEmpty) ...[
            // List promo member yang sedang aktif
            ...activeMemberPromos.map((mp) {
              final promo = mp['promo'] as Promotion;
              final bool isAll = mp['isAllMembers'] == true;
              final customerIds = mp['customerIds'] as List<String>;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _formatPromoValue(promo),
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            promo.name ?? "Diskon Member",
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            isAll
                                ? "Semua pelanggan terdaftar"
                                : "${customerIds.length} pelanggan terpilih",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: isDark ? Colors.white60 : const Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      color: const Color(0xFF10B981),
                      tooltip: "Edit Diskon",
                      onPressed: () => _showMemberDiscountDialog(existingPromoData: mp),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showMemberDiscountDialog(),
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                  label: Text(
                    "Tambah Diskon Member Lain",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          ] else ...[
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 420;
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.03)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: isNarrow
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Belum ada diskon member aktif",
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              "Atur diskon khusus (misal 5% atau 10%) otomatis di struk saat pelanggan belanja.",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _showMemberDiscountDialog(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  elevation: 0,
                                ),
                                icon: const Icon(Icons.add_rounded, size: 16),
                                label: Text(
                                  "Pasang Diskon Member",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Belum ada diskon member aktif",
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Atur diskon khusus otomatis di struk saat member belanja.",
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: () => _showMemberDiscountDialog(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                elevation: 0,
                              ),
                              child: Text(
                                "+ Pasang Diskon",
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allSelected = _filteredCustomers.isNotEmpty &&
        _selectedIds.length == _filteredCustomers.length;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: _isSelecting
            ? Text(
                '${_selectedIds.length} dipilih',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 18),
              )
            : Text(
                "Manajemen Pelanggan",
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
        centerTitle: true,
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            height: 1,
          ),
        ),
        leading: _isSelecting
            ? IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: _toggleSelectMode,
                tooltip: 'Batal',
              )
            : (widget.onBack != null
                ? IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                    onPressed: widget.onBack,
                    tooltip: 'Kembali',
                  )
                : (widget.onMenuPressed != null
                    ? IconButton(
                        icon: const Icon(Icons.menu_rounded),
                        onPressed: widget.onMenuPressed,
                      )
                    : null)),
        actions: _isSelecting
            ? [
                IconButton(
                  icon: Icon(
                    allSelected
                        ? Icons.check_box_rounded
                        : Icons.check_box_outline_blank_rounded,
                    color: primaryColor,
                  ),
                  onPressed: _selectAll,
                  tooltip: allSelected ? 'Batalkan semua' : 'Pilih semua',
                ),
                const SizedBox(width: 4),
              ]
            : [
                IconButton(
                  onPressed: _showAddCustomerDialog,
                  icon: const Icon(Icons.person_add_alt_1_rounded),
                  tooltip: "Tambah Pelanggan",
                ),
                IconButton(
                  onPressed: _toggleSelectMode,
                  icon: const Icon(Icons.checklist_rounded),
                  tooltip: 'Pilih Banyak',
                ),
                const SizedBox(width: 4),
              ],
      ),
      floatingActionButton: _isSelecting
          ? ScaleTransition(
              scale: _fabScaleAnim,
              child: FloatingActionButton.extended(
                onPressed: _selectedIds.isEmpty ? null : _deleteSelected,
                backgroundColor: _selectedIds.isEmpty ? Colors.grey : primaryColor,
                foregroundColor: Colors.white,
                elevation: 2,
                icon: const Icon(Icons.delete_outline_rounded),
                label: Text(
                  _selectedIds.isEmpty
                      ? 'Pilih pelanggan'
                      : 'Hapus ${_selectedIds.length}',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                ),
              ),
            )
          : null,
      body: _isLoading
          ? const Center(child: CupertinoActivityIndicator())
          : RefreshIndicator(
              onRefresh: _fetchCustomers,
              color: primaryColor,
              child: ListView(
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width < 500 ? 12 : 20,
                  vertical: 16,
                ),
                children: [
                  ValueListenableBuilder<bool>(
                    valueListenable: SettingsController.instance.featureLoyaltyEnabled,
                    builder: (context, loyaltyEnabled, _) {
                      if (!loyaltyEnabled) return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLoyaltyHeader(isDark),
                          const SizedBox(height: 16),
                          _buildMemberDiscountCard(isDark),
                          const SizedBox(height: 16),
                        ],
                      );
                    },
                  ),
                  ValueListenableBuilder<bool>(
                    valueListenable: SettingsController.instance.featureLoyaltyEnabled,
                    builder: (context, loyaltyEnabled, _) {
                      return _buildStatsRow(isDark, showLoyalty: loyaltyEnabled);
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Search Bar langsung (Pintasan Cepat ditiadakan)
                  _buildSearchBar(isDark),
                  const SizedBox(height: 16),

                  // Header List
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Daftar Pelanggan",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          "${_filteredCustomers.length} Pelanggan",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  ValueListenableBuilder<bool>(
                    valueListenable: SettingsController.instance.featureLoyaltyEnabled,
                    builder: (context, loyaltyEnabled, _) {
                      if (_filteredCustomers.isEmpty) {
                        return _buildEmptyState(isDark);
                      }
                      return Column(
                        children: _filteredCustomers
                            .map((c) => _buildCustomerCard(c, isDark, showLoyalty: loyaltyEnabled))
                            .toList(),
                      );
                    },
                  ),

                  if (_isSelecting) const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }

  Widget _buildLoyaltyHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: primaryColor.withValues(alpha: 0.25), width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.stars_rounded, size: 14, color: primaryColor),
                          const SizedBox(width: 4),
                          Text(
                            "Program Loyalitas",
                            style: GoogleFonts.plusJakartaSans(
                              color: primaryColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  "Ranking Poin Pelanggan",
                  style: GoogleFonts.plusJakartaSans(
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Gunakan akumulasi poin untuk memberikan apresiasi atau diskon khusus kepada pelanggan setia Anda.",
                  style: GoogleFonts.plusJakartaSans(
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: primaryColor.withValues(alpha: 0.2), width: 1),
            ),
            child: const Icon(
              Icons.military_tech_rounded,
              color: primaryColor,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(bool isDark, {bool showLoyalty = true}) {
    final totalCustomers = _customers.length;
    final totalPoints = _customers.fold<int>(0, (sum, c) => sum + (c.points));

    if (!showLoyalty) {
      return _buildOutlineStatCard(
        title: "Total Pelanggan",
        value: "$totalCustomers",
        icon: Icons.people_alt_rounded,
        accentColor: primaryColor,
        isDark: isDark,
      );
    }

    return Row(
      children: [
        Expanded(
          child: _buildOutlineStatCard(
            title: "Total Pelanggan",
            value: "$totalCustomers",
            icon: Icons.people_alt_rounded,
            accentColor: primaryColor,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildOutlineStatCard(
            title: "Total Poin",
            value: "$totalPoints",
            icon: Icons.star_rounded,
            accentColor: const Color(0xFFD97706),
            isDark: isDark,
          ),
        ),
      ],
    );
  }


  Widget _buildOutlineStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color accentColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: accentColor.withValues(alpha: 0.2), width: 1),
            ),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white60 : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
      ),
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white : const Color(0xFF0F172A),
        ),
        decoration: InputDecoration(
          hintText: "Cari pelanggan berdasarkan nama, nomor HP...",
          hintStyle: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
          ),
          prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Colors.grey),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: () => setState(() => _searchQuery = ''),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildCustomerCard(Customer c, bool isDark, {bool showLoyalty = true}) {
    final isSelected = _selectedIds.contains(c.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: ValueKey(c.id),
        direction: _isSelecting
            ? DismissDirection.none
            : DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 22),
              const SizedBox(height: 4),
              Text(
                'Hapus',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        confirmDismiss: (_) async {
          return await _showDeleteConfirm(
            title: 'Hapus Pelanggan?',
            message:
                'Hapus "${c.name ?? 'pelanggan ini'}" dari daftar secara permanen?',
          );
        },
        onDismissed: (_) async {
          await _customerService.deleteCustomer(c.id);
          setState(() => _customers.remove(c));
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${c.name ?? 'Pelanggan'} dihapus'),
                backgroundColor: primaryColor,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: GestureDetector(
          onTap: _isSelecting ? () => _toggleSelect(c.id) : null,
          onLongPress: !_isSelecting
              ? () {
                  _toggleSelectMode();
                  _toggleSelect(c.id);
                }
              : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? primaryColor
                    : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                width: isSelected ? 1.5 : 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                // Checkbox / Avatar
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _isSelecting
                      ? Container(
                          key: const ValueKey('checkbox'),
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected ? primaryColor : Colors.transparent,
                            border: Border.all(
                              color: isSelected
                                  ? primaryColor
                                  : (isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                              width: 1.5,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 18,
                                )
                              : null,
                        )
                      : Container(
                          key: const ValueKey('avatar'),
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: primaryColor.withValues(alpha: 0.1),
                            border: Border.all(
                              color: primaryColor.withValues(alpha: 0.25),
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              (c.name?.isNotEmpty == true)
                                  ? c.name!.substring(0, 1).toUpperCase()
                                  : "P",
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: primaryColor,
                              ),
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 14),

                // Name + phone
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.name ?? "Tanpa Nama",
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.phone_outlined,
                            size: 12,
                            color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            (c.phoneNumber?.isNotEmpty == true)
                                ? c.phoneNumber!
                                : "Belum ada no. HP",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: isDark ? Colors.white60 : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                      Builder(
                        builder: (_) {
                          final promoData = _getPromoForCustomer(c);
                          if (promoData == null) return const SizedBox.shrink();
                          final promo = promoData['promo'] as Promotion;
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.25),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.loyalty_rounded,
                                    size: 11,
                                    color: Color(0xFF10B981),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatPromoValue(promo),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF059669),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // Points & Actions
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showLoyalty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD97706).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFFD97706).withValues(alpha: 0.25),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 14,
                              color: Color(0xFFD97706),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "${c.points} Poin",
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFD97706),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (!_isSelecting) ...[
                      const SizedBox(width: 8),
                      Builder(
                        builder: (_) {
                          final promoData = _getPromoForCustomer(c);
                          return GestureDetector(
                            onTap: () => _showMemberDiscountDialog(
                              existingPromoData: promoData,
                              preselectedCustomer: c,
                            ),
                            child: Tooltip(
                              message: "Atur Diskon Member",
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.25),
                                    width: 1,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.loyalty_rounded,
                                  size: 16,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => _deleteSingle(c),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: primaryColor.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.delete_outline_rounded,
                            size: 16,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                width: 1.2,
              ),
            ),
            child: Icon(
              Icons.people_outline_rounded,
              size: 48,
              color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? "Tidak ada pelanggan ditemukan"
                : "Belum ada pelanggan",
            style: GoogleFonts.plusJakartaSans(
              color: isDark ? Colors.white70 : const Color(0xFF475569),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _searchQuery.isNotEmpty
                ? "Coba gunakan kata kunci pencarian yang lain."
                : "Tambahkan pelanggan untuk memulai program loyalitas.",
            style: GoogleFonts.plusJakartaSans(
              color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          if (_searchQuery.isEmpty)
            ElevatedButton.icon(
              onPressed: _showAddCustomerDialog,
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
              label: const Text("Tambah Pelanggan Sekarang"),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
        ],
      ),
    );
  }
}

