import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../controllers/admin_controller.dart';
import '../../../services/app_database.dart';
import '../../../services/customer_service.dart';
import '../../../widgets/kasir_dialog.dart';

class PromotionFormSheet extends StatefulWidget {
  final Promotion? existingPromo;
  const PromotionFormSheet({super.key, this.existingPromo});

  @override
  State<PromotionFormSheet> createState() => _PromotionFormSheetState();
}

class _PromotionFormSheetState extends State<PromotionFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _valueController = TextEditingController();
  final _durationController = TextEditingController();

  String _promoType = 'discount'; // discount, buy_x_get_y, bundle
  String _discountUnit = 'percentage'; // percentage, fixed

  // Target: 'all' | 'category' | 'customer'
  String _targetMode = 'all';

  List<String> _selectedCategoryIds = [];
  List<String> _selectedCustomerIds = [];

  List<Customer> _allCustomers = [];
  bool _customersLoaded = false;

  bool _isLoading = false;
  bool _hasDuration = false;

  final Map<String, String> _categoryNames = {};
  final Map<String, String> _customerNames = {};

  @override
  void initState() {
    super.initState();
    if (widget.existingPromo != null) {
      final p = widget.existingPromo!;
      _nameController.text = p.name ?? '';
      _descController.text = p.description ?? '';
      _valueController.text = p.value?.toString() ?? '';
      _promoType = p.type;
      _discountUnit = p.discountType;

      if (p.endDate != null) {
        _hasDuration = true;
        final daysLeft = p.endDate!.difference(DateTime.now()).inDays;
        _durationController.text = daysLeft > 0 ? daysLeft.toString() : '0';
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCustomers());
  }

  Future<void> _loadCustomers() async {
    final db = context.read<AppDatabase>();
    final admin = context.read<AdminController>();
    if (admin.storeId == null) return;
    final service = CustomerService(db);
    final list = await service.getCustomers(admin.storeId!);
    if (mounted) {
      setState(() {
        _allCustomers = list
          ..sort((a, b) => (a.name ?? '').compareTo(b.name ?? ''));
        _customersLoaded = true;
        for (var c in list) {
          _customerNames[c.id] = c.name ?? 'Tanpa Nama';
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _valueController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<AdminController>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  _buildTextField(
                    controller: _nameController,
                    label: 'Nama Promosi',
                    hint: 'Contoh: Diskon Ramadhan',
                    validator: (v) => v!.isEmpty ? 'Nama wajib diisi' : null,
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    controller: _descController,
                    label: 'Deskripsi (Opsional)',
                    hint: 'Keterangan lengkap promosi...',
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Tipe Promosi',
                    style: GoogleFonts.openSans(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildTypeSelector(),
                  const SizedBox(height: 24),

                  if (_promoType == 'discount') ...[
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: _buildTextField(
                            controller: _valueController,
                            label: 'Nilai Diskon',
                            hint: _discountUnit == 'percentage'
                                ? 'Contoh: 10'
                                : 'Contoh: 5000',
                            keyboardType: TextInputType.number,
                            prefixIcon: Icon(
                              _discountUnit == 'percentage'
                                  ? Icons.percent
                                  : Icons.money_off_csred_rounded,
                              size: 18,
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Nilai diskon wajib diisi';
                              }
                              final parsed = double.tryParse(v.trim());
                              if (parsed == null || parsed <= 0) {
                                return 'Masukkan angka yang valid';
                              }
                              if (_discountUnit == 'percentage' &&
                                  parsed > 100) {
                                return 'Max 100%';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Unit',
                                style: GoogleFonts.openSans(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                height: 52,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    _buildUnitBtn('%', 'percentage'),
                                    _buildUnitBtn('Rp', 'fixed'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildTargetSelector(controller),
                  ],

                  if (_promoType == 'buy_x_get_y') ...[
                    _buildInfoBox(
                      'Fitur Beli X Gratis Y akan segera hadir dalam update berikutnya.',
                    ),
                  ],

                  if (_promoType == 'bundle') ...[
                    _buildInfoBox(
                      'Fitur Paket (Bundling) akan segera hadir dalam update berikutnya.',
                    ),
                  ],

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // --- Duration Section ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Durasi Promosi',
                            style: GoogleFonts.openSans(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Promosi akan otomatis berakhir',
                            style: GoogleFonts.openSans(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                      Switch.adaptive(
                        value: _hasDuration,
                        onChanged: (v) => setState(() {
                          _hasDuration = v;
                          if (!v) _durationController.clear();
                        }),
                        activeTrackColor: Theme.of(context).primaryColor,
                      ),
                    ],
                  ),

                  if (_hasDuration) ...[
                    const SizedBox(height: 16),
                    _buildDurationField(),
                  ],

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          _buildFooter(context, controller),
        ],
      ),
    );
  }

  // ───────────────────────── Target Selector ─────────────────────────

  Widget _buildTargetSelector(AdminController controller) {
    final hasCategories = controller.categories.isNotEmpty;
    final hasCustomers = _allCustomers.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Terapkan Pada',
          style: GoogleFonts.openSans(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 6),
        Text(
          'Pilih siapa yang mendapatkan promosi ini',
          style: GoogleFonts.openSans(fontSize: 11, color: Colors.grey[500]),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildSelectionChip(
              'Semua Produk',
              Icons.all_inclusive_rounded,
              _targetMode == 'all',
              () => setState(() {
                _targetMode = 'all';
                _selectedCategoryIds = [];
                _selectedCustomerIds = [];
              }),
            ),
            if (hasCategories)
              _buildSelectionChip(
                'Kategori',
                Icons.category_rounded,
                _targetMode == 'category',
                () {
                  setState(() {
                    _targetMode = 'category';
                    _selectedCustomerIds = [];
                  });
                  _showCategoryPicker(controller);
                },
              ),
            if (hasCustomers || !_customersLoaded)
              _buildSelectionChip(
                'Pelanggan',
                Icons.people,
                _targetMode == 'customer',
                () {
                  setState(() {
                    _targetMode = 'customer';
                    _selectedCategoryIds = [];
                  });
                  _showCustomerPicker();
                },
              ),
          ],
        ),

        // Selected category tags
        if (_targetMode == 'category' && _selectedCategoryIds.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildSelectedTags(
            _selectedCategoryIds,
            _categoryNames,
            (id) => setState(() => _selectedCategoryIds.remove(id)),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => _showCategoryPicker(controller),
            icon: const Icon(Icons.edit, size: 14),
            label: Text(
              'Ubah kategori',
              style: GoogleFonts.openSans(fontSize: 12),
            ),
          ),
        ],

        // Selected customer tags
        if (_targetMode == 'customer' && _selectedCustomerIds.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildCustomerSummary(),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _showCustomerPicker,
            icon: const Icon(Icons.edit, size: 14),
            label: Text(
              'Ubah pelanggan',
              style: GoogleFonts.openSans(fontSize: 12),
            ),
          ),
        ],

        // Prompt if customer mode but none selected yet
        if (_targetMode == 'customer' && _selectedCustomerIds.isEmpty) ...[
          const SizedBox(height: 8),
          _buildInfoBox(
            'Ketuk chip "Pelanggan" untuk memilih pelanggan yang mendapatkan promo ini.',
          ),
        ],
      ],
    );
  }

  Widget _buildCustomerSummary() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.primaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.primaryColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.people,
                size: 14,
                color: theme.primaryColor,
              ),
              const SizedBox(width: 6),
              Text(
                '${_selectedCustomerIds.length} pelanggan dipilih',
                style: GoogleFonts.openSans(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: theme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: _selectedCustomerIds.map((id) {
              final name = _customerNames[id] ?? id.substring(0, 6);
              return Chip(
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                label: Text(name, style: GoogleFonts.openSans(fontSize: 10)),
                onDeleted: () =>
                    setState(() => _selectedCustomerIds.remove(id)),
                deleteIcon: const Icon(Icons.close, size: 12),
                backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
                padding: const EdgeInsets.symmetric(horizontal: 4),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionChip(
    String label,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    final color = Theme.of(context).primaryColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? color : Colors.grey[300]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.openSans(
                fontSize: 12,
                color: isSelected ? Colors.white : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedTags(
    List<String> ids,
    Map<String, String> names,
    Function(String) onRemove,
  ) {
    if (ids.isEmpty) return const SizedBox();
    return Wrap(
      spacing: 8,
      children: ids.map((id) {
        final name = names[id] ?? id.substring(0, 8);
        return Chip(
          label: Text(name, style: const TextStyle(fontSize: 10)),
          onDeleted: () => onRemove(id),
          deleteIcon: const Icon(Icons.close, size: 14),
          backgroundColor: Theme.of(
            context,
          ).primaryColor.withValues(alpha: 0.1),
        );
      }).toList(),
    );
  }

  void _showCategoryPicker(AdminController controller) async {
    final categories = controller.categories;
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return KasirDialog(
              title: 'Pilih Kategori',
              icon: Icons.category_rounded,
              iconColor: Theme.of(context).primaryColor,
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Divider(),
                    SizedBox(
                      height: 250,
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: categories.length,
                        separatorBuilder: (c, i) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final cat = categories[index];
                          final isSelected = _selectedCategoryIds.contains(
                            cat.id,
                          );
                          return CheckboxListTile(
                            title: Text(
                              cat.name ?? 'Tanpa Nama',
                              style: GoogleFonts.openSans(fontSize: 14),
                            ),
                            value: isSelected,
                            activeColor: Theme.of(context).primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            onChanged: (val) {
                              setDialogState(() {
                                if (val == true) {
                                  _selectedCategoryIds.add(cat.id);
                                  _categoryNames[cat.id] = cat.name ?? 'Cat';
                                } else {
                                  _selectedCategoryIds.remove(cat.id);
                                }
                              });
                              setState(() {});
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              primaryActionLabel: 'Selesai',
              onPrimaryAction: () => Navigator.pop(context),
            );
          },
        );
      },
    );
  }

  void _showCustomerPicker() {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final allSelected =
                _allCustomers.isNotEmpty &&
                _selectedCustomerIds.length == _allCustomers.length;

            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(ctx).primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.people,
                      color: Theme.of(ctx).primaryColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Pilih Pelanggan',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: !_customersLoaded
                    ? const SizedBox(
                        height: 80,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : _allCustomers.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Belum ada pelanggan terdaftar.',
                          style: GoogleFonts.openSans(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Select all row
                          CheckboxListTile(
                            title: Text(
                              allSelected ? 'Batalkan Semua' : 'Pilih Semua',
                              style: GoogleFonts.openSans(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            value: allSelected,
                            activeColor: Theme.of(ctx).primaryColor,
                            onChanged: (val) {
                              setDialogState(() {
                                if (val == true) {
                                  _selectedCustomerIds = _allCustomers
                                      .map((c) => c.id)
                                      .toList();
                                } else {
                                  _selectedCustomerIds = [];
                                }
                              });
                              setState(() {});
                            },
                          ),
                          const Divider(height: 1),
                          SizedBox(
                            height: 260,
                            child: ListView.separated(
                              shrinkWrap: true,
                              itemCount: _allCustomers.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (ctx2, i) {
                                final c = _allCustomers[i];
                                final isSelected = _selectedCustomerIds
                                    .contains(c.id);
                                return CheckboxListTile(
                                  secondary: CircleAvatar(
                                    backgroundColor: Theme.of(
                                      ctx,
                                    ).primaryColor.withValues(alpha: 0.1),
                                    child: Text(
                                      c.name?.substring(0, 1).toUpperCase() ??
                                          'P',
                                      style: TextStyle(
                                        color: Theme.of(ctx).primaryColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    c.name ?? 'Tanpa Nama',
                                    style: GoogleFonts.openSans(fontSize: 14),
                                  ),
                                  subtitle: Text(
                                    c.phoneNumber ?? '',
                                    style: GoogleFonts.openSans(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  value: isSelected,
                                  activeColor: Theme.of(ctx).primaryColor,
                                  onChanged: (val) {
                                    setDialogState(() {
                                      if (val == true) {
                                        _selectedCustomerIds.add(c.id);
                                        _customerNames[c.id] =
                                            c.name ?? 'Pelanggan';
                                      } else {
                                        _selectedCustomerIds.remove(c.id);
                                      }
                                    });
                                    setState(() {});
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Batal',
                    style: GoogleFonts.openSans(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(ctx).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Selesai (${_selectedCustomerIds.length})',
                    style: GoogleFonts.openSans(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ───────────────────────── Duration Field ─────────────────────────

  Widget _buildDurationField() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Berapa hari promosi berlangsung?',
          style: GoogleFonts.openSans(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _durationController,
          keyboardType: TextInputType.number,
          validator: _hasDuration
              ? (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Masukkan jumlah hari';
                  }
                  final days = int.tryParse(v.trim());
                  if (days == null || days <= 0) return 'Minimal 1 hari';
                  return null;
                }
              : null,
          decoration: InputDecoration(
            hintText: 'Contoh: 30',
            suffixText: 'hari',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [7, 14, 30, 60, 90].map((days) {
            return ActionChip(
              label: Text('$days hari', style: GoogleFonts.openSans(fontSize: 12)),
              backgroundColor: isDark
                  ? Colors.white10
                  : Theme.of(context).primaryColor.withValues(alpha: 0.08),
              onPressed: () =>
                  setState(() => _durationController.text = '$days'),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        if (_durationController.text.isNotEmpty) ...[
          Builder(
            builder: (context) {
              final days = int.tryParse(_durationController.text) ?? 0;
              if (days <= 0) return const SizedBox();
              final endDate = DateTime.now().add(Duration(days: days));
              final formatted =
                  '${endDate.day}/${endDate.month}/${endDate.year}';
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.event_available,
                      color: Colors.green,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Berakhir pada: $formatted',
                      style: GoogleFonts.openSans(
                        fontSize: 12,
                        color: Colors.green[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  // ───────────────────────── Helpers ─────────────────────────

  Widget _buildUnitBtn(String label, String unit) {
    final isSelected = _discountUnit == unit;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _discountUnit = unit),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: GoogleFonts.openSans(
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: GoogleFonts.openSans(color: Colors.grey)),
          ),
          Text(
            widget.existingPromo == null ? 'Tambah Promosi' : 'Edit Promosi',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 60),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    Widget? prefixIcon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.openSans(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeSelector() {
    return Row(
      children: [
        _typeItem('discount', Icons.percent, 'Diskon'),
        const SizedBox(width: 12),
        _typeItem('buy_x_get_y', Icons.repeat, 'B1G1'),
        const SizedBox(width: 12),
        _typeItem('bundle', Icons.inventory_2, 'Paket'),
      ],
    );
  }

  Widget _typeItem(String type, IconData icon, String label) {
    final isSelected = _promoType == type;
    final color = isSelected ? Theme.of(context).primaryColor : Colors.grey;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _promoType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.1)
                : Colors.transparent,
            border: Border.all(color: isSelected ? color : Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.openSans(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBox(String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.blue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.openSans(fontSize: 13, color: Colors.blue[800]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, AdminController controller) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : () => _handleSave(controller),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                'Simpan Promosi',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
      ),
    );
  }

  Future<void> _handleSave(AdminController controller) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final value = double.tryParse(_valueController.text.trim());

      DateTime? startDate;
      DateTime? endDate;
      if (_hasDuration) {
        final days = int.tryParse(_durationController.text.trim()) ?? 0;
        if (days > 0) {
          startDate = DateTime.now();
          endDate = startDate.add(Duration(days: days));
        }
      }

      List<Map<String, dynamic>> items = [];

      if (_targetMode == 'category') {
        for (var id in _selectedCategoryIds) {
          items.add({'categoryId': id, 'role': 'TARGET'});
        }
      } else if (_targetMode == 'customer') {
        for (var customerId in _selectedCustomerIds) {
          // Store customer ID in productId column with CUSTOMER role
          items.add({'productId': customerId, 'role': 'CUSTOMER'});
        }
      }
      // 'all' → items stays empty → applies to all products

      await controller.promotionService.createPromotion(
        name: _nameController.text,
        type: _promoType,
        discountType: _discountUnit,
        description: _descController.text,
        value: value,
        storeId: controller.storeId!,
        items: items,
        startDate: startDate,
        endDate: endDate,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Promosi berhasil disimpan')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

