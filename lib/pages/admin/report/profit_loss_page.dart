import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../controllers/analytics_controller.dart';
import '../widgets/pinterest_card.dart';
import 'expense_management_page.dart';
import '../employee/employee_management_page.dart';
import '../../attendance/attendance_page.dart';
import '../history/history_page.dart';

class ProfitLossPage extends StatefulWidget {
  final String storeId;
  final VoidCallback? onMenuPressed;
  final Function(int)? onNavigateToIndex;
  const ProfitLossPage({
    super.key,
    required this.storeId,
    this.onMenuPressed,
    this.onNavigateToIndex,
  });

  @override
  State<ProfitLossPage> createState() => _ProfitLossPageState();
}

class _ProfitLossPageState extends State<ProfitLossPage> {
  final _currencyFormat = NumberFormat.currency(
    locale: 'id',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnalyticsController>().init(widget.storeId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : Colors.white,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Image.asset(
                'assets/logo/logo.png',
                height: 24,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              "Uang",
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 18,
              ),
            ),
          ],
        ),
        centerTitle: false,
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: isDark ? const Color(0xFF374151) : const Color(0xFFE2E8F0),
            height: 1,
          ),
        ),
        actions: const [],
      ),
      body: Consumer<AnalyticsController>(
        builder: (context, controller, child) {
          if (controller.isLoading) {
            return const Center(child: CupertinoActivityIndicator());
          }

          double sales = 0;
          double costs = 0;
          double expenses = 0;
          int txCount = 0;
          int expCount = 0;
          String periodLabel = "";

          switch (controller.selectedRange) {
            case ChartRange.today:
              sales = controller.todaySales;
              costs = controller.todayCOGS;
              expenses = controller.todayExpenses;
              txCount = controller.todayTransactionCount;
              expCount = controller.todayExpenseCount;
              periodLabel = "Hari Ini";
              break;
            case ChartRange.sevenDays:
              sales = controller.sevenDaysSales;
              costs = controller.sevenDaysCOGS;
              expenses = controller.sevenDaysExpenses;
              txCount = controller.sevenDaysTransactionCount;
              expCount = controller.sevenDaysExpenseCount;
              periodLabel = "Minggu Ini";
              break;
            case ChartRange.thirtyDays:
              sales = controller.thirtyDaysSales;
              costs = controller.thirtyDaysCOGS;
              expenses = controller.thirtyDaysExpenses;
              txCount = controller.thirtyDaysTransactionCount;
              expCount = controller.thirtyDaysExpenseCount;
              periodLabel = "30 Hari";
              break;
            case ChartRange.month:
              sales = controller.thisMonthSales;
              costs = controller.thisMonthCOGS;
              expenses = controller.thisMonthExpenses;
              txCount = controller.totalTransactionCount;
              expCount = 0;
              periodLabel = "Bulan Ini";
              break;
            case ChartRange.allTime:
              sales = controller.allTimeSales;
              costs = controller.allTimeCOGS;
              expenses = controller.allTimeExpenses;
              txCount = controller.allTimeTransactionCount;
              expCount = controller.allTimeExpenseCount;
              periodLabel = "Semua Waktu";
              break;
            case ChartRange.custom:
              sales = controller.customSales;
              costs = controller.customCOGS;
              expenses = controller.customExpenses;
              txCount = controller.customTransactionCount;
              expCount = controller.customExpenseCount;
              final start = controller.customStartDate;
              final end = controller.customEndDate;
              if (start != null && end != null) {
                final fmt = DateFormat('dd MMM yyyy');
                periodLabel = "${fmt.format(start)} – ${fmt.format(end)}";
              } else {
                periodLabel = "Kustom";
              }
              break;
          }

          final netProfit = sales - costs - expenses;

          return RefreshIndicator(
            onRefresh: () => controller.refreshData(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _buildQuickShortcutsSection(isDark),
                  const SizedBox(height: 24),
                  _buildPeriodSelector(controller, isDark),
                  const SizedBox(height: 30),
                  Text(
                    periodLabel,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF2D3436),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildMainProfitCard(netProfit, isDark),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMiniStatCard(
                          "Pemasukan",
                          sales,
                          CupertinoIcons.graph_circle_fill,
                          const Color(0xFFE8F5E9),
                          const Color(0xFF4CAF50),
                          isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMiniStatCard(
                          "Pengeluaran",
                          expenses,
                          CupertinoIcons.graph_circle,
                          const Color(0xFFFFEBEE),
                          const Color(0xFFEF5350),
                          isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text(
                    "Transaksi",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF2D3436),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTransactionSection(txCount, expCount, isDark),
                  const SizedBox(height: 32),
                  _buildChartSection(controller, isDark),
                  const SizedBox(height: 32),
                  Text(
                    "Pertumbuhan Bisnis",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF2D3436),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildGrowthIndicators(controller, isDark),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Quick Shortcuts ────────────────────────────────────────────────────
  Widget _buildQuickShortcutsSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.bolt_rounded,
                    size: 16,
                    color: Color(0xFF0D9488),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "Pintasan Cepat",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            Text(
              "Akses Cepat Keuangan",
              style: GoogleFonts.openSans(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildShortcutCard(
                icon: Icons.badge_outlined,
                label: "Pegawai & Gaji",
                badgeColor: const Color(0xFF2563EB),
                isDark: isDark,
                onTap: () {
                  if (widget.onNavigateToIndex != null) {
                    widget.onNavigateToIndex!(5);
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EmployeeManagementPage(storeId: widget.storeId),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(width: 10),
              _buildShortcutCard(
                icon: Icons.fingerprint_rounded,
                label: "Absensi",
                badgeColor: const Color(0xFF059669),
                isDark: isDark,
                onTap: () {
                  if (widget.onNavigateToIndex != null) {
                    widget.onNavigateToIndex!(16);
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AttendancePage(showSidebar: false),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(width: 10),
              _buildShortcutCard(
                icon: CupertinoIcons.plus_app,
                label: "Pengeluaran",
                badgeColor: const Color(0xFF0D9488),
                isDark: isDark,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ExpenseManagementPage(storeId: widget.storeId),
                  ),
                ).then((_) {
                  if (mounted) {
                    context.read<AnalyticsController>().refreshData();
                  }
                }),
              ),
              const SizedBox(width: 10),
              _buildShortcutCard(
                icon: Icons.receipt_long_outlined,
                label: "Riwayat",
                badgeColor: const Color(0xFF7C3AED),
                isDark: isDark,
                onTap: () {
                  if (widget.onNavigateToIndex != null) {
                    widget.onNavigateToIndex!(4);
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HistoryPage(
                          storeId: widget.storeId,
                          showSidebar: false,
                        ),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShortcutCard({
    required IconData icon,
    required String label,
    required Color badgeColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 96,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? const Color(0xFF374151) : const Color(0xFFCBD5E1),
              width: 1.2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: badgeColor, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodSelector(AnalyticsController controller, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              CupertinoIcons.calendar,
              size: 18,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
            const SizedBox(width: 8),
            Text(
              "Periode",
              style: GoogleFonts.openSans(
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterBtn(controller, ChartRange.today, "Hari Ini"),
              const SizedBox(width: 8),
              _buildFilterBtn(controller, ChartRange.sevenDays, "Minggu Ini"),
              const SizedBox(width: 8),
              _buildFilterBtn(controller, ChartRange.month, "Bulan Ini"),
              const SizedBox(width: 8),
              _buildFilterBtn(
                controller,
                ChartRange.custom,
                "Kustom",
                isCustom: true,
              ),
              const SizedBox(width: 12),
              _buildExpenseBtn(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExpenseBtn() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ExpenseManagementPage(storeId: widget.storeId),
        ),
      ).then((_) {
        if (context.mounted) {
          context.read<AnalyticsController>().refreshData();
        }
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF0D9488),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF0D9488)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0D9488).withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              CupertinoIcons.plus_app,
              color: Colors.white,
              size: 14,
            ),
            const SizedBox(width: 6),
            Text(
              "Pengeluaran",
              style: GoogleFonts.openSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBtn(
    AnalyticsController controller,
    ChartRange range,
    String label, {
    bool isCustom = false,
  }) {
    final isSelected = controller.selectedRange == range;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        if (isCustom) {
          _showCustomRangePicker(controller);
        } else {
          controller.setRange(range);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFEA5700)
              : (isDark ? Colors.white10 : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFEA5700)
                : (isDark ? Colors.white24 : Colors.grey.shade300),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFEA5700).withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            if (isSelected) ...[
              const Icon(Icons.check, color: Colors.white, size: 14),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: GoogleFonts.openSans(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : Colors.black87),
              ),
            ),
            if (isCustom) ...[
              const SizedBox(width: 6),
              Icon(
                Icons.calendar_month,
                size: 14,
                color: isSelected ? Colors.white : Colors.amber,
              ),
              const SizedBox(width: 4),
              const Icon(Icons.star, size: 12, color: Colors.amber),
            ],
          ],
        ),
      ),
    );
  }

  void _showCustomRangePicker(AnalyticsController controller) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange:
          controller.customStartDate != null && controller.customEndDate != null
          ? DateTimeRange(
              start: controller.customStartDate!,
              end: controller.customEndDate!,
            )
          : DateTimeRange(
              start: DateTime.now().subtract(const Duration(days: 7)),
              end: DateTime.now(),
            ),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFEA5700),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      controller.setRange(
        ChartRange.custom,
        start: picked.start,
        end: picked.end,
      );
    }
  }

  Widget _buildMainProfitCard(double netProfit, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEA5700).withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                CupertinoIcons.graph_square,
                size: 20,
                color: Color(0xFFEA5700),
              ),
              const SizedBox(width: 8),
              Text(
                "Laba Bersih",
                style: GoogleFonts.openSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _currencyFormat.format(netProfit),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 32,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStatCard(
    String title,
    double value,
    IconData icon,
    Color bgColor,
    Color iconColor,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: bgColor.withValues(alpha: isDark ? 0.2 : 1.0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.openSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _currencyFormat.format(value),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionSection(
    int salesCount,
    int expenseCount,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _buildTransactionRow(
            CupertinoIcons.tickets_fill,
            "Penjualan",
            salesCount.toString(),
            isDark,
          ),
          const Divider(height: 24),
          _buildTransactionRow(
            CupertinoIcons.minus,
            "Pengeluaran",
            expenseCount.toString(),
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionRow(
    IconData icon,
    String title,
    String value,
    bool isDark,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: isDark ? Colors.white70 : Colors.black87),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.openSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildChartSection(AnalyticsController controller, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Grafik Pendapatan",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF2D3436),
          ),
        ),
        const SizedBox(height: 16),
        PinterestCard(
          padding: const EdgeInsets.fromLTRB(10, 24, 24, 16),
          child: SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.05),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 45,
                      getTitlesWidget: (value, meta) {
                        return SideTitleWidget(
                          meta: meta,
                          space: 8,
                          child: Text(
                            NumberFormat.compactSimpleCurrency(
                              locale: 'id',
                            ).format(value),
                            style: GoogleFonts.openSans(
                              fontSize: 10,
                              color: Colors.grey[500],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        final interval = controller.chartLabelInterval;
                        if (idx >= 0 && idx < controller.chartData.length) {
                          if (idx % interval == 0) {
                            return SideTitleWidget(
                              meta: meta,
                              space: 8,
                              child: Text(
                                controller.chartData[idx]['label'],
                                style: GoogleFonts.openSans(
                                  fontSize: 10,
                                  color: Colors.grey[500],
                                ),
                              ),
                            );
                          }
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(controller.chartData.length, (i) {
                      return FlSpot(
                        i.toDouble(),
                        controller.chartData[i]['amount'],
                      );
                    }),
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: const Color(0xFFEA5700),
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFEA5700).withValues(alpha: 0.2),
                          const Color(0xFFEA5700).withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGrowthIndicators(AnalyticsController controller, bool isDark) {
    return Column(
      children: [
        _buildGrowthCard("Mingguan", controller.weeklyGrowth, isDark),
        const SizedBox(height: 16),
        _buildGrowthCard("Bulanan", controller.monthlyGrowth, isDark),
      ],
    );
  }

  Widget _buildGrowthCard(String label, double growth, bool isDark) {
    final isPositive = growth >= 0;
    final color = isPositive
        ? const Color(0xFF10B981)
        : const Color(0xFFEF4444);

    return PinterestCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              isPositive
                  ? CupertinoIcons.graph_circle_fill
                  : CupertinoIcons.graph_circle,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                Text(
                  isPositive ? "Kenaikan performa" : "Penurunan performa",
                  style: GoogleFonts.openSans(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          Text(
            "${isPositive ? '+' : ''}${growth.toStringAsFixed(1)}%",
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
