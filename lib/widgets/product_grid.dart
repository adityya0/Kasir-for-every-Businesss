import 'package:flutter/material.dart';
import '../services/platform/file_manager.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/app_database.dart';

class ProductGrid extends StatelessWidget {
  final String storeId;
  final String searchQuery;
  final String? categoryFilter;
  final String filterType; // "All", "Popular", "Recent"
  final bool isGridView;
  final Function(Product) onItemTap;
  final Widget Function(BuildContext, Product)? extraInfoBuilder;
  final Widget Function(BuildContext, Product)? actionBuilder;
  final Widget Function(BuildContext, Product)? overlayBuilder;

  /// When non-null, only show products whose ID is in this set
  final Set<String>? promoProductIds;

  /// When non-null, only show products whose categoryId is in this set
  final Set<String>? promoCategoryIds;

  /// productId -> totalUnitsSold; used for accurate Popular sort.
  final Map<String, int>? salesMap;

  /// List of product IDs sold in the current session for "Recent" filter
  final List<String>? recentProductIds;

  const ProductGrid({
    super.key,
    required this.storeId,
    this.searchQuery = "",
    this.categoryFilter,
    this.filterType = "All",
    this.isGridView = true,
    required this.onItemTap,
    this.extraInfoBuilder,
    this.actionBuilder,
    this.overlayBuilder,
    this.promoProductIds,
    this.promoCategoryIds,
    this.salesMap,
    this.recentProductIds,
  });

  @override
  Widget build(BuildContext context) {
    // Determine if Dark Mode
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    final textHeading = isDark ? Colors.white : const Color(0xFF2D3436);

    final db = Provider.of<AppDatabase>(context);

    // Filter using Drift Query DSL
    final query = db.select(db.products)
      ..where((t) => t.storeId.equals(storeId))
      ..where((t) => t.isDeleted.equals(false));

    if (categoryFilter != null && categoryFilter != "Semua") {
      query.where((t) => t.categoryId.equals(categoryFilter!));
    }

    return StreamBuilder<List<Unit>>(
      stream: db.select(db.units).watch(),
      builder: (context, unitSnapshot) {
        final units = unitSnapshot.data ?? [];
        final unitMap = { for (var u in units) u.id: u.code };

        return StreamBuilder<List<Product>>(
      stream: query.watch(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.refresh_rounded, size: 40, color: Colors.grey),
                  const SizedBox(height: 8),
                  Text("Memuat data produk...", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                ],
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator(color: primaryColor));
        }

        var localProducts = snapshot.data!;

        // Client-side promo filter
        if (promoProductIds != null || promoCategoryIds != null) {
          localProducts = localProducts.where((p) {
            if (promoProductIds != null && promoProductIds!.contains(p.id)) {
              return true;
            }
            if (promoCategoryIds != null &&
                p.categoryId != null &&
                promoCategoryIds!.contains(p.categoryId!)) {
              return true;
            }
            return false;
          }).toList();
        }

        // 1. Client-side search
        var filteredProducts = localProducts.where((p) {
          if (searchQuery.isNotEmpty) {
            final q = searchQuery.toLowerCase();
            final name = (p.name ?? '').toLowerCase();
            final sku = (p.sku ?? '').toLowerCase();
            if (!name.contains(q) && !sku.contains(q)) {
              return false;
            }
          }
          return true;
        }).toList();

        // 2. Sort
        if (filterType == "Recent" && recentProductIds != null) {
          // Filter to only show products that were sold in this session
          filteredProducts = filteredProducts
              .where((p) => recentProductIds!.contains(p.id))
              .toList();

          // Sort by the order in recentProductIds (maintains "most recently sold" first)
          filteredProducts.sort((a, b) {
            final indexA = recentProductIds!.indexOf(a.id);
            final indexB = recentProductIds!.indexOf(b.id);
            return indexA.compareTo(indexB);
          });
        } else if (filterType == "Recent") {
          // Fallback to createdAt if no session data (old behavior or just in case)
          filteredProducts.sort((a, b) {
            final da = a.createdAt ?? DateTime(2000);
            final db = b.createdAt ?? DateTime(2000);
            return db.compareTo(da);
          });
        } else if (filterType == "Popular") {
          // Most total units sold first (real sales data)
          filteredProducts.sort((a, b) {
            final soldA = salesMap?[a.id] ?? 0;
            final soldB = salesMap?[b.id] ?? 0;
            return soldB.compareTo(soldA);
          });
        }

        if (filteredProducts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off_rounded,
                  size: 60,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 10),
                Text(
                  searchQuery.isEmpty
                      ? "Belum ada produk."
                      : "Produk tidak ditemukan.",
                  style: GoogleFonts.openSans(color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        final products = filteredProducts;

        if (isGridView) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 500;
              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: isWide ? 140 : 170,
                  childAspectRatio: isWide ? 0.58 : 0.60,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: products.length,
                itemBuilder: (context, i) {
                  final p = products[i];
                  return _buildGridItem(
                    context,
                    p,
                    isDark,
                    textHeading,
                    primaryColor,
                    isWide,
                    unitMap,
                  );
                },
              );
            },
          );
        } else {
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
            itemCount: products.length,
            itemBuilder: (context, i) {
              final p = products[i];
              return _buildListItem(
                context,
                p,
                isDark,
                textHeading,
                primaryColor,
                unitMap,
              );
            },
          );
        }
      },
    );
      },
    );
  }

  Widget _buildGridItem(
    BuildContext context,
    Product p,
    bool isDark,
    Color textHeading,
    Color primaryColor,
    bool isWide,
    Map<String, String?> unitMap,
  ) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    // Stock Logic
    final bool isStockManaged = p.isStockManaged;
    final double stockQty = p.stockQuantity ?? 0.0;
    final bool isOutOfStock = isStockManaged && stockQty <= 0;

    return Opacity(
      opacity: isOutOfStock ? 0.6 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
          borderRadius: BorderRadius.circular(isWide ? 10 : 16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: InkWell(
          onTap: isOutOfStock ? null : () => onItemTap(p),
          borderRadius: BorderRadius.circular(isWide ? 10 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Section
              Expanded(
                flex: 5,
                child: Stack(
                  children: [
                    _buildImage(p, isDark, isWide),
                    _buildPromoBadge(context, p, p.id),
                    if (overlayBuilder != null) overlayBuilder!(context, p),
                  ],
                ),
              ),

              // Info Section
              Expanded(
                flex: 4,
                child: Padding(
                  padding: EdgeInsets.all(isWide ? 6 : 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              p.name ?? 'Tanpa Nama',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: isWide ? 11 : 12,
                                fontWeight: FontWeight.w600,
                                color: textHeading,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              "${currencyFormat.format(p.salePrice ?? 0)}${p.unitId != null && unitMap[p.unitId] != null ? ' / ${unitMap[p.unitId]}' : ''}",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.openSans(
                                fontSize: isWide ? 11 : 12,
                                fontWeight: FontWeight.w700,
                                color: primaryColor,
                              ),
                            ),
                            if (p.isStockManaged)
                              Text(
                                "Stok: ${NumberFormat.decimalPattern('id').format(p.stockQuantity ?? 0)} ${unitMap[p.unitId] ?? ''}",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.openSans(
                                  fontSize: isWide ? 9 : 10,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _buildActionButton(
                            context,
                            p,
                            isOutOfStock,
                            primaryColor,
                            isWide,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListItem(
    BuildContext context,
    Product p,
    bool isDark,
    Color textHeading,
    Color primaryColor,
    Map<String, String?> unitMap,
  ) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final bool isStockManaged = p.isStockManaged;
    final double stockQty = p.stockQuantity ?? 0.0;
    final bool isOutOfStock = isStockManaged && stockQty <= 0;

    return Opacity(
      opacity: isOutOfStock ? 0.6 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          onTap: isOutOfStock ? null : () => onItemTap(p),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Image
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: isDark ? Colors.grey[800] : Colors.grey[50],
                    image: p.imageUrl != null
                        ? DecorationImage(
                            image: FileManager().getImageProvider(p.imageUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: p.imageUrl == null
                      ? Icon(
                          Icons.image_not_supported_outlined,
                          color: Colors.grey[400],
                          size: 30,
                        )
                      : null,
                ),
                const SizedBox(width: 16),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name ?? 'Tanpa Nama',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textHeading,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${currencyFormat.format(p.salePrice ?? 0)}${p.unitId != null && unitMap[p.unitId] != null ? ' / ${unitMap[p.unitId]}' : ''}",
                        style: GoogleFonts.openSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: primaryColor,
                        ),
                      ),
                      if (p.isStockManaged)
                        Text(
                          "Stok: ${NumberFormat.decimalPattern('id').format(p.stockQuantity ?? 0)} ${unitMap[p.unitId] ?? ''}",
                          style: GoogleFonts.openSans(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),

                // Action
                _buildActionButton(
                  context,
                  p,
                  isOutOfStock,
                  primaryColor,
                  false,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage(Product p, bool isDark, bool isWide) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(isWide ? 12 : 20),
        ),
        color: isDark ? Colors.grey[800] : Colors.grey[50],
        image: p.imageUrl != null
            ? DecorationImage(
                image: FileManager().getImageProvider(p.imageUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),
    );
  }

  Widget _buildPromoBadge(BuildContext context, Product p, String productId) {
    final db = Provider.of<AppDatabase>(context);
    return Positioned(
      top: 10,
      left: 10,
      child: StreamBuilder<List<PromotionItem>>(
        stream: (db.select(
          db.promotionItems,
        )..where((t) => t.productId.equals(productId))).watch(),
        builder: (context, promoSnapshot) {
          if (promoSnapshot.hasData && promoSnapshot.data!.isNotEmpty) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Text(
                "PROMO",
                style: GoogleFonts.openSans(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    Product p,
    bool isOutOfStock,
    Color primaryColor,
    bool isWide,
  ) {
    if (actionBuilder != null) return actionBuilder!(context, p);

    return Container(
      width: isWide ? 26 : 32,
      height: isWide ? 26 : 32,
      decoration: BoxDecoration(
        color: isOutOfStock ? Colors.grey[300] : primaryColor,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.add_rounded,
        color: Colors.white,
        size: isWide ? 16 : 20,
      ),
    );
  }
}

