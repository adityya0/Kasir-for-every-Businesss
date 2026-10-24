import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../controllers/admin_controller.dart';
import '../../services/app_database.dart';
import 'widgets/promotion_form_sheet.dart';
import 'package:intl/intl.dart';
import '../../widgets/kasir_dialog.dart';

class PromotionPage extends StatefulWidget {
  final VoidCallback? onBack;
  const PromotionPage({super.key, this.onBack});

  @override
  State<PromotionPage> createState() => _PromotionPageState();
}

class _PromotionPageState extends State<PromotionPage> {
  final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  List<Promotion> _promos = [];
  // Maps promoId -> list of its items
  Map<String, List<PromotionItem>> _promoItems = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAndCleanPromos());
  }

  Future<void> _loadAndCleanPromos() async {
    if (!mounted) {
      return;
    }
    setState(() => _isLoading = true);
    final controller = Provider.of<AdminController>(context, listen: false);
    if (controller.storeId == null) {
      setState(() => _isLoading = false);
      return;
    }
    final allPromos = await controller.promotionService.getAllPromotions(
      controller.storeId!,
    );
    final now = DateTime.now();
    // Auto-delete expired promos
    for (final p in allPromos) {
      if (p.endDate != null && p.endDate!.isBefore(now)) {
        await controller.promotionService.deletePromotion(p.id);
      }
    }
    // Reload clean list
    final cleaned = await controller.promotionService.getAllPromotions(
      controller.storeId!,
    );

    // Load items for each promo
    final Map<String, List<PromotionItem>> itemsMap = {};
    for (final p in cleaned) {
      final items = await controller.promotionService.getPromotionItems(p.id);
      itemsMap[p.id] = items;
    }

    if (mounted) {
      setState(() {
        _promos = cleaned;
        _promoItems = itemsMap;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<AdminController>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF1A1C1E)
          : const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: Text(
          'Kelola Promosi',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
        leading: widget.onBack != null
            ? IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: isDark ? Colors.white : const Color(0xFF2D3436),
                ),
                onPressed: widget.onBack,
              )
            : const SizedBox.shrink(),
        actions: [
          IconButton(
            onPressed: () => _showInfoHelp(),
            icon: Icon(
              Icons.info_outline,
              color: isDark ? Colors.white70 : Colors.grey[600],
            ),
            tooltip: "Tentang Promosi",
          ),
          IconButton(
            onPressed: () => _showPromotionForm(context),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAndCleanPromos,
              child: _promos.isEmpty
                  ? _buildEmptyState(context, primaryColor)
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _promos.length,
                      itemBuilder: (context, index) {
                        final promo = _promos[index];
                        return _buildPromoCard(
                          context,
                          promo,
                          controller,
                          isDark,
                        );
                      },
                    ),
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context, Color primaryColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.percent, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Belum ada promosi',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Klik tombol + untuk membuat promosi baru',
            style: GoogleFonts.openSans(color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showPromotionForm(context),
            icon: const Icon(Icons.add),
            label: const Text('Buat Promosi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoCard(
    BuildContext context,
    Promotion promo,
    AdminController controller,
    bool isDark,
  ) {
    final items = _promoItems[promo.id] ?? [];
    final hasCustomer = items.any((i) => i.role == 'CUSTOMER');
    final hasCategory = items.any((i) => i.categoryId != null);
    final typeLabel = _getTypeLabel(promo.type);
    final color = _getTypeColor(promo.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: promo.isActive
            ? Border.all(color: color.withValues(alpha: 0.5), width: 1.5)
            : Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showPromotionForm(context), // Option to edit
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon Cluster
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(_getTypeIcon(promo.type), color: color, size: 22),
              ),
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      promo.name ?? 'Tanpa Nama',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      promo.description ?? typeLabel,
                      style: GoogleFonts.openSans(
                        fontSize: 12,
                        color: isDark ? Colors.white54 : Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _buildTargetBadge(items, hasCustomer, hasCategory),
                        if (promo.endDate != null)
                          _buildExpiryBadge(promo.endDate!),
                        if (promo.value != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              promo.discountType == 'percentage'
                                  ? '${promo.value!.toStringAsFixed(0)}% OFF'
                                  : _currencyFormat.format(promo.value!),
                              style: GoogleFonts.openSans(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Toggle & More
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildDotToggle(
                    isActive: promo.isActive,
                    color: color,
                    onTap: () async {
                      await controller.promotionService.updatePromotionStatus(
                        promo.id,
                        !promo.isActive,
                      );
                      if (mounted) _loadAndCleanPromos();
                    },
                  ),
                  const SizedBox(height: 16),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: Colors.grey,
                    ),
                    onPressed: () => _confirmDelete(context, promo, controller),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDotToggle({
    required bool isActive,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isActive ? color : Colors.grey.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: isActive ? 12 : 0,
            height: isActive ? 12 : 0,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
        ),
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'discount':
        return Icons.percent;
      case 'buy_x_get_y':
        return Icons.card_giftcard;
      case 'bundle':
        return Icons.grid_view;
      default:
        return Icons.campaign_rounded;
    }
  }

  Widget _buildExpiryBadge(DateTime endDate) {
    final now = DateTime.now();
    final daysLeft = endDate.difference(now).inDays;
    final formatted = '${endDate.day}/${endDate.month}/${endDate.year}';

    Color badgeColor;
    String label;
    if (daysLeft <= 0) {
      badgeColor = Colors.red;
      label = 'Berakhir hari ini';
    } else if (daysLeft <= 3) {
      badgeColor = Colors.orange;
      label = '$daysLeft hari lagi · Berakhir $formatted';
    } else {
      badgeColor = Colors.green;
      label = '$daysLeft hari lagi · Berakhir $formatted';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 12, color: badgeColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.openSans(
              fontSize: 11,
              color: badgeColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Build a pill showing what the promo targets
  Widget _buildTargetBadge(
    List<PromotionItem> items,
    bool hasCustomer,
    bool hasCategory,
  ) {
    IconData icon;
    String label;
    Color color;

    if (hasCustomer) {
      final count = items.where((i) => i.role == 'CUSTOMER').length;
      icon = Icons.people;
      label = '$count Pelanggan';
      color = Colors.teal;
    } else if (hasCategory) {
      icon = Icons.category_rounded;
      label = 'Kategori Tertentu';
      color = Colors.indigo;
    } else {
      icon = Icons.all_inclusive_rounded;
      label = 'Semua Produk';
      color = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.openSans(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'discount':
        return 'DISKON';
      case 'buy_x_get_y':
        return 'B1G1 / B2G1';
      case 'bundle':
        return 'PAKET';
      default:
        return 'PROMO';
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'discount':
        return Colors.orange;
      case 'buy_x_get_y':
        return Colors.blue;
      case 'bundle':
        return Colors.purple;
      default:
        return Colors.green;
    }
  }

  void _showPromotionForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const PromotionFormSheet(),
    ).then((_) {
      if (mounted) _loadAndCleanPromos();
    });
  }

  Future<void> _confirmDelete(
    BuildContext context,
    Promotion promo,
    AdminController controller,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => KasirDialog(
        title: 'Hapus Promosi',
        message:
            'Apakah Anda yakin ingin menghapus "${promo.name}"? Promosi yang dihapus tidak dapat dipulihkan.',
        icon: Icons.delete,
        iconColor: Colors.redAccent,
        primaryActionLabel: "Hapus",
        isDestructive: true,
        onPrimaryAction: () => Navigator.pop(context, true),
        secondaryActionLabel: "Batal",
      ),
    );

    if (confirm == true) {
      await controller.promotionService.deletePromotion(promo.id);
      if (mounted) _loadAndCleanPromos();
    }
  }

  void _showInfoHelp() {
    showDialog(
      context: context,
      builder: (ctx) => KasirDialog(
        title: "Panduan Promosi",
        icon: Icons.info,
        iconColor: Colors.orange,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoItem(
              "Diskon",
              "Potongan harga langsung dalam bentuk Persen (%) atau Nominal Rupiah (Rp).",
            ),
            const SizedBox(height: 12),
            _buildInfoItem(
              "B1G1 / B2G1",
              "Beli X barang, Gratis Y barang. Sangat efektif untuk cuci gudang atau menaikkan volume penjualan.",
            ),
            const SizedBox(height: 12),
            _buildInfoItem(
              "Paket (Bundle)",
              "Harga khusus untuk pembelian set barang tertentu (Coming Soon).",
            ),
            const SizedBox(height: 12),
            _buildInfoItem(
              "Promosi Pelanggan",
              "Pilih pelanggan spesifik yang berhak mendapatkan diskon ini. Cocok untuk program loyalitas atau penawaran eksklusif.",
            ),
          ],
        ),
        primaryActionLabel: "Saya Mengerti",
        onPrimaryAction: () => Navigator.pop(ctx),
      ),
    );
  }

  Widget _buildInfoItem(String title, String desc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        Text(
          desc,
          style: GoogleFonts.openSans(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }
}

