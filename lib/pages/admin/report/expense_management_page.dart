import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../services/app_database.dart';
import '../../../services/expense_service.dart';
import '../../../widgets/kasir_dialog.dart';

enum ExpenseFilterRange { today, thisWeek, thisMonth, custom }

class ExpenseManagementPage extends StatefulWidget {
  final String storeId;
  const ExpenseManagementPage({super.key, required this.storeId});

  @override
  State<ExpenseManagementPage> createState() => _ExpenseManagementPageState();
}

class _ExpenseManagementPageState extends State<ExpenseManagementPage> {
  late ExpenseService _expenseService;
  static const primaryColor = Color(0xFFC0392B); // Steak Asri Red
  
  final _currencyFormat = NumberFormat.currency(
    locale: 'id',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  // --- Filter State ---
  ExpenseFilterRange _selectedFilter = ExpenseFilterRange.thisMonth;
  DateTime? _customStart;
  DateTime? _customEnd;

  final List<String> _categories = [
    'Listrik & Air',
    'Sewa Tempat',
    'Gaji & Upah',
    'Makan & Minum',
    'Transportasi',
    'Perlengkapan',
    'Lainnya',
  ];

  // Category icon mapping
  static final Map<String, IconData> _categoryIcons = {
    'Listrik & Air': Icons.bolt_rounded,
    'Sewa Tempat': Icons.home_work_rounded,
    'Gaji & Upah': Icons.people_alt_rounded,
    'Makan & Minum': Icons.restaurant_rounded,
    'Transportasi': Icons.directions_car_rounded,
    'Perlengkapan': Icons.build_rounded,
    'Lainnya': Icons.category_rounded,
  };

  static final Map<String, Color> _categoryColors = {
    'Listrik & Air': const Color(0xFFD97706),
    'Sewa Tempat': const Color(0xFF2563EB),
    'Gaji & Upah': const Color(0xFF7C3AED),
    'Makan & Minum': const Color(0xFFEA580C),
    'Transportasi': const Color(0xFF059669),
    'Perlengkapan': const Color(0xFF0891B2),
    'Lainnya': const Color(0xFF64748B),
  };

  @override
  void initState() {
    super.initState();
    _expenseService = ExpenseService(context.read<AppDatabase>());
  }

  // --- Date Range Logic ---
  DateTimeRange _getDateRange() {
    final now = DateTime.now();
    switch (_selectedFilter) {
      case ExpenseFilterRange.today:
        final start = DateTime(now.year, now.month, now.day);
        return DateTimeRange(start: start, end: now);
      case ExpenseFilterRange.thisWeek:
        final start = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: now.weekday - 1));
        return DateTimeRange(start: start, end: now);
      case ExpenseFilterRange.thisMonth:
        final start = DateTime(now.year, now.month, 1);
        return DateTimeRange(start: start, end: now);
      case ExpenseFilterRange.custom:
        return DateTimeRange(
          start: _customStart ?? DateTime(now.year, now.month, 1),
          end: _customEnd ?? now,
        );
    }
  }

  List<Expense> _filterExpenses(List<Expense> all) {
    final range = _getDateRange();
    final endOfDay = DateTime(
      range.end.year,
      range.end.month,
      range.end.day,
      23, 59, 59,
    );
    return all.where((e) {
      final d = e.date;
      if (d == null) return false;
      return !d.isBefore(range.start) && !d.isAfter(endOfDay);
    }).toList();
  }

  // --- Grouping Logic ---
  Map<String, List<Expense>> _groupByMonth(List<Expense> expenses) {
    final Map<String, List<Expense>> groups = {};
    for (final e in expenses) {
      final key = DateFormat('MMMM yyyy', 'id_ID').format(e.date ?? DateTime.now());
      groups.putIfAbsent(key, () => []).add(e);
    }
    return groups;
  }

  // --- Custom Range Picker ---
  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: DateTimeRange(
        start: _customStart ?? DateTime(now.year, now.month, 1),
        end: _customEnd ?? now,
      ),
      builder: (context, child) => Theme(
        data: (isDark ? ThemeData.dark() : ThemeData.light()).copyWith(
          colorScheme: ColorScheme.light(
            primary: primaryColor,
            onPrimary: Colors.white,
            surface: isDark ? const Color(0xFF1E293B) : Colors.white,
            onSurface: isDark ? Colors.white : Colors.black87,
          ),
          dialogTheme: DialogThemeData(
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _customStart = picked.start;
        _customEnd = picked.end;
        _selectedFilter = ExpenseFilterRange.custom;
      });
    }
  }

  // --- UI: Period Filter Bar ---
  Widget _buildFilterBar(bool isDark) {
    final filters = [
      (ExpenseFilterRange.today, 'Hari Ini'),
      (ExpenseFilterRange.thisWeek, 'Minggu Ini'),
      (ExpenseFilterRange.thisMonth, 'Bulan Ini'),
    ];

    String customLabel = 'Kustom';
    if (_selectedFilter == ExpenseFilterRange.custom &&
        _customStart != null &&
        _customEnd != null) {
      customLabel =
          '${DateFormat('dd MMM', 'id_ID').format(_customStart!)} – ${DateFormat('dd MMM', 'id_ID').format(_customEnd!)}';
    }

    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          ...filters.map((f) {
            final isSelected = _selectedFilter == f.$1;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _selectedFilter = f.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? primaryColor
                        : (isDark ? const Color(0xFF1E293B) : Colors.white),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? primaryColor
                          : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                      width: 1.2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      f.$2,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.white70 : const Color(0xFF475569)),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
          // Custom button
          GestureDetector(
            onTap: _pickCustomRange,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: _selectedFilter == ExpenseFilterRange.custom
                    ? primaryColor
                    : (isDark ? const Color(0xFF1E293B) : Colors.white),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _selectedFilter == ExpenseFilterRange.custom
                      ? primaryColor
                      : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_month_rounded,
                    size: 15,
                    color: _selectedFilter == ExpenseFilterRange.custom
                        ? Colors.white
                        : primaryColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    customLabel,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: _selectedFilter == ExpenseFilterRange.custom
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: _selectedFilter == ExpenseFilterRange.custom
                          ? Colors.white
                          : (isDark ? Colors.white70 : const Color(0xFF475569)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- UI: Summary Card ---
  Widget _buildSummaryCard(
    List<Expense> filtered,
    List<Expense> all,
    bool isDark,
  ) {
    final total = filtered.fold<double>(0, (s, e) => s + (e.amount ?? 0));
    final mostExpensive = filtered.isEmpty
        ? null
        : filtered.reduce((a, b) => (a.amount ?? 0) >= (b.amount ?? 0) ? a : b);

    final now = DateTime.now();
    final lastMonthStart = DateTime(now.year, now.month - 1, 1);
    final lastMonthEnd = DateTime(now.year, now.month, 0, 23, 59, 59);
    final lastMonthTotal = all
        .where((e) =>
            e.date != null &&
            !e.date!.isBefore(lastMonthStart) &&
            !e.date!.isAfter(lastMonthEnd))
        .fold<double>(0, (s, e) => s + (e.amount ?? 0));

    double? growthPct;
    if (lastMonthTotal > 0 && _selectedFilter == ExpenseFilterRange.thisMonth) {
      growthPct = ((total - lastMonthTotal) / lastMonthTotal) * 100;
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 8),
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
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 16,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Total Pengeluaran',
                    style: GoogleFonts.plusJakartaSans(
                      color: isDark ? Colors.white70 : const Color(0xFF64748B),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (growthPct != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (growthPct >= 0 ? Colors.red : Colors.green)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: (growthPct >= 0 ? Colors.red : Colors.green)
                          .withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        growthPct >= 0
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        size: 12,
                        color: growthPct >= 0 ? Colors.red[600] : Colors.green[700],
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${growthPct.abs().toStringAsFixed(1)}% vs bln lalu',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: growthPct >= 0 ? Colors.red[600] : Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              _currencyFormat.format(total),
              style: GoogleFonts.plusJakartaSans(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSummaryOutlineChip(
                Icons.format_list_bulleted_rounded,
                '${filtered.length} transaksi',
                isDark,
              ),
              if (mostExpensive != null)
                _buildSummaryOutlineChip(
                  Icons.local_fire_department_rounded,
                  'Terbesar: ${mostExpensive.category} (${_currencyFormat.format(mostExpensive.amount ?? 0)})',
                  isDark,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryOutlineChip(IconData icon, String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: isDark ? Colors.white70 : const Color(0xFF64748B)),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: isDark ? Colors.white70 : const Color(0xFF475569),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // --- UI: Month Group Header ---
  Widget _buildMonthHeader(String monthLabel, List<Expense> items, bool isDark) {
    final subTotal = items.fold<double>(0, (s, e) => s + (e.amount ?? 0));
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            monthLabel,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: primaryColor.withValues(alpha: 0.2), width: 1),
            ),
            child: Text(
              _currencyFormat.format(subTotal),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Recurrence Helpers ---
  static const Map<String, IconData> _recurrenceIcons = {
    'sekali': Icons.verified_outlined,
    'harian': Icons.today_rounded,
    'mingguan': Icons.view_week_rounded,
    'bulanan': Icons.calendar_view_month_rounded,
    'tahunan': Icons.calendar_month_rounded,
    'kustom': Icons.tune_rounded,
  };

  static const Map<String, Color> _recurrenceColors = {
    'sekali': Color(0xFF64748B),
    'harian': Color(0xFF0D9488),
    'mingguan': Color(0xFF16A34A),
    'bulanan': Color(0xFF2563EB),
    'tahunan': Color(0xFF7C3AED),
    'kustom': Color(0xFFD97706),
  };

  String _formatDuration(String? type, int? months) {
    if (type == null || type == 'sekali') return 'Sekali Bayar';
    if (type == 'harian') return 'Setiap Hari';
    if (type == 'mingguan') return 'Setiap Minggu';
    if (type == 'bulanan') return 'Setiap Bulan';
    if (type == 'tahunan') return 'Setiap Tahun';
    if (type == 'kustom' && months != null) {
      if (months < 12) return 'Setiap $months Bulan';
      final years = months ~/ 12;
      final remaining = months % 12;
      if (remaining == 0) return 'Setiap $years Tahun';
      return 'Setiap $years Thn $remaining Bln';
    }
    return 'Kustom';
  }

  // --- Recurrence Calculation Helpers ---
  DateTime _getNextDueDate(DateTime baseDate, String recurrenceType, int? durationMonths) {
    switch (recurrenceType) {
      case 'harian':
        return baseDate.add(const Duration(days: 1));
      case 'mingguan':
        return baseDate.add(const Duration(days: 7));
      case 'bulanan':
        int newYear = baseDate.year;
        int newMonth = baseDate.month + 1;
        if (newMonth > 12) {
          newYear += (newMonth - 1) ~/ 12;
          newMonth = ((newMonth - 1) % 12) + 1;
        }
        final lastDayOfMonth = DateTime(newYear, newMonth + 1, 0).day;
        final newDay = baseDate.day > lastDayOfMonth ? lastDayOfMonth : baseDate.day;
        return DateTime(newYear, newMonth, newDay);
      case 'tahunan':
        final newYear = baseDate.year + 1;
        final lastDayOfMonth = DateTime(newYear, baseDate.month + 1, 0).day;
        final newDay = baseDate.day > lastDayOfMonth ? lastDayOfMonth : baseDate.day;
        return DateTime(newYear, baseDate.month, newDay);
      case 'kustom':
        final months = (durationMonths != null && durationMonths > 0) ? durationMonths : 1;
        int newYear = baseDate.year;
        int newMonth = baseDate.month + months;
        if (newMonth > 12) {
          newYear += (newMonth - 1) ~/ 12;
          newMonth = ((newMonth - 1) % 12) + 1;
        }
        final lastDayOfMonth = DateTime(newYear, newMonth + 1, 0).day;
        final newDay = baseDate.day > lastDayOfMonth ? lastDayOfMonth : baseDate.day;
        return DateTime(newYear, newMonth, newDay);
      default:
        return baseDate;
    }
  }

  String _getDueCountdownText(DateTime nextDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(nextDate.year, nextDate.month, nextDate.day);
    final diff = target.difference(today).inDays;

    if (diff < 0) {
      return 'Terlewat ${-diff} hari';
    } else if (diff == 0) {
      return 'Hari ini!';
    } else if (diff == 1) {
      return 'Besok';
    } else {
      return '$diff hari lagi';
    }
  }

  Widget _buildRecurrenceBadge(String? type, int? months, bool isDark) {
    if (type == null || type == 'sekali') return const SizedBox.shrink();
    final color = _recurrenceColors[type] ?? const Color(0xFF64748B);
    final icon = _recurrenceIcons[type] ?? Icons.repeat_rounded;
    final label = _formatDuration(type, months);
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecurrenceScheduleBox(Expense e, bool isDark) {
    if (e.recurrenceType == null || e.recurrenceType == 'sekali') return const SizedBox.shrink();

    final baseDate = e.date ?? DateTime.now();
    final nextDate = _getNextDueDate(baseDate, e.recurrenceType!, e.recurrenceDurationMonths);
    final countdown = _getDueCountdownText(nextDate);
    final isOverdue = nextDate.isBefore(DateTime.now().subtract(const Duration(days: 1)));
    final isToday = DateTime(nextDate.year, nextDate.month, nextDate.day)
        .isAtSameMomentAs(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day));

    final themeColor = _recurrenceColors[e.recurrenceType] ?? const Color(0xFF2563EB);
    final alertColor = isOverdue
        ? const Color(0xFFDC2626)
        : (isToday ? const Color(0xFFD97706) : themeColor);

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: alertColor.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildRecurrenceBadge(e.recurrenceType, e.recurrenceDurationMonths, isDark),
              const SizedBox(width: 6),
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: alertColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: alertColor.withValues(alpha: 0.3), width: 0.8),
                ),
                child: Text(
                  countdown,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: alertColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                size: 13,
                color: isDark ? Colors.white60 : const Color(0xFF64748B),
              ),
              const SizedBox(width: 5),
              Text(
                'Terakhir dibayar: ',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                DateFormat('dd MMMM yyyy', 'id_ID').format(baseDate),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white70 : const Color(0xFF334155),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              Icon(
                Icons.event_repeat_rounded,
                size: 13,
                color: alertColor,
              ),
              const SizedBox(width: 5),
              Text(
                'Akan bayar lagi: ',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: alertColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                DateFormat('dd MMMM yyyy', 'id_ID').format(nextDate),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: alertColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Quick Duplicate Expense Sheet (Plus / Minus) ---
  void _showQuickDuplicateExpenseSheet(Expense e) {
    int quantity = 1;
    final double unitPrice = e.amount ?? 0;
    DateTime selectedDate = DateTime.now();
    final noteController = TextEditingController(text: e.notes ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final sheetBg = isDark ? const Color(0xFF1E293B) : Colors.white;
        final icon = _categoryIcons[e.category] ?? Icons.category_rounded;
        final color = _categoryColors[e.category] ?? primaryColor;

        final hasRecurrence = e.recurrenceType != null && e.recurrenceType != 'sekali';
        final baseDate = e.date ?? DateTime.now();
        final nextDueDate = hasRecurrence
            ? _getNextDueDate(baseDate, e.recurrenceType!, e.recurrenceDurationMonths)
            : null;
        final countdown = nextDueDate != null ? _getDueCountdownText(nextDueDate) : null;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            final double totalAmount = unitPrice * quantity;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 540),
                child: Container(
                  decoration: BoxDecoration(
                    color: sheetBg,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      width: 1.2,
                    ),
                  ),
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Drag handle
                        Center(
                          child: Container(
                            width: 44,
                            height: 4,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white24 : Colors.grey[300],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Title row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Tambah Pengeluaran',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 20),
                              onPressed: () => Navigator.pop(context),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Card Detail Pengeluaran Terpilih
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
                                ),
                                child: Icon(icon, color: color, size: 22),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      e.category,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Harga dasar: ${_currencyFormat.format(unitPrice)}',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Rincian Jadwal Perulangan (Jika Ada)
                        if (hasRecurrence && nextDueDate != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: isDark ? 0.12 : 0.06),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: primaryColor.withValues(alpha: 0.25),
                                width: 1.2,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.event_repeat_rounded, size: 15, color: primaryColor),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Perulangan: ${_formatDuration(e.recurrenceType, e.recurrenceDurationMonths)}',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: primaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (countdown != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: primaryColor.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          countdown,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: primaryColor,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle_outline_rounded,
                                      size: 13,
                                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Terakhir dibayar: ',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                      ),
                                    ),
                                    Text(
                                      DateFormat('dd MMMM yyyy', 'id_ID').format(baseDate),
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.alarm_rounded,
                                      size: 13,
                                      color: primaryColor,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Jadwal bayar lagi: ',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        color: primaryColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      DateFormat('dd MMMM yyyy', 'id_ID').format(nextDueDate),
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                // Shortcut Pilihan Tanggal
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: [
                                    GestureDetector(
                                      onTap: () => setSheetState(() => selectedDate = nextDueDate),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: selectedDate.year == nextDueDate.year &&
                                                  selectedDate.month == nextDueDate.month &&
                                                  selectedDate.day == nextDueDate.day
                                              ? primaryColor
                                              : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: primaryColor.withValues(alpha: 0.35), width: 1),
                                        ),
                                        child: Text(
                                          'Gunakan Jatuh Tempo (${DateFormat('dd MMM', 'id_ID').format(nextDueDate)})',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: selectedDate.year == nextDueDate.year &&
                                                    selectedDate.month == nextDueDate.month &&
                                                    selectedDate.day == nextDueDate.day
                                                ? Colors.white
                                                : primaryColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => setSheetState(() => selectedDate = DateTime.now()),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: selectedDate.year == DateTime.now().year &&
                                                  selectedDate.month == DateTime.now().month &&
                                                  selectedDate.day == DateTime.now().day
                                              ? primaryColor
                                              : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          'Hari Ini (${DateFormat('dd MMM', 'id_ID').format(DateTime.now())})',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: selectedDate.year == DateTime.now().year &&
                                                    selectedDate.month == DateTime.now().month &&
                                                    selectedDate.day == DateTime.now().day
                                                ? Colors.white
                                                : (isDark ? Colors.white70 : const Color(0xFF475569)),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),

                        // Stepper: Plus / Minus Kuantitas
                        Text(
                          'Jumlah / Kuantitas',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : const Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(height: 10),

                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Tombol Minus (-)
                              GestureDetector(
                                onTap: quantity > 1
                                    ? () => setSheetState(() => quantity--)
                                    : null,
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: quantity > 1
                                        ? (isDark ? const Color(0xFF1E293B) : Colors.white)
                                        : (isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFE2E8F0)),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: quantity > 1
                                          ? primaryColor.withValues(alpha: 0.5)
                                          : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.remove_rounded,
                                    size: 22,
                                    color: quantity > 1
                                        ? primaryColor
                                        : (isDark ? Colors.white30 : Colors.grey[400]),
                                  ),
                                ),
                              ),

                              // Text Angka Kuantitas
                              Column(
                                children: [
                                  Text(
                                    '$quantity',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w800,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  Text(
                                    'item / kali',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),

                              // Tombol Plus (+)
                              GestureDetector(
                                onTap: () => setSheetState(() => quantity++),
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: primaryColor,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: primaryColor.withValues(alpha: 0.3),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.add_rounded,
                                    size: 24,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Preset chips (+1, +2, +3, +5)
                        Row(
                          children: [
                            Text(
                              'Cepat:',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: isDark ? Colors.white54 : const Color(0xFF64748B),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            ...[1, 2, 3, 5].map((preset) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: GestureDetector(
                                  onTap: () => setSheetState(() => quantity = preset),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: quantity == preset
                                          ? primaryColor.withValues(alpha: 0.15)
                                          : (isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9)),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: quantity == preset
                                            ? primaryColor
                                            : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      '+$preset',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        fontWeight: quantity == preset ? FontWeight.w700 : FontWeight.w600,
                                        color: quantity == preset
                                            ? primaryColor
                                            : (isDark ? Colors.white70 : const Color(0xFF475569)),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Total Kalkulasi Box
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: primaryColor.withValues(alpha: 0.25),
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total Masuk Pengeluaran',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white70 : const Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$quantity × ${_currencyFormat.format(unitPrice)}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                _currencyFormat.format(totalAmount),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Tanggal Transaksi
                        GestureDetector(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null) {
                              setSheetState(() => selectedDate = picked);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded, size: 14, color: primaryColor),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Tanggal: ${DateFormat('dd MMMM yyyy', 'id_ID').format(selectedDate)}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.edit_calendar_rounded,
                                  size: 14,
                                  color: isDark ? Colors.white54 : const Color(0xFF64748B),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Catatan opsional
                        TextField(
                          controller: noteController,
                          decoration: InputDecoration(
                            hintText: 'Catatan opsional (contoh: beli lagi hari ini)',
                            hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey),
                            filled: true,
                            fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                                width: 1.2,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                                width: 1.2,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: primaryColor, width: 1.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),

                        // Tombol Aksi Utama: Tambah ke Pengeluaran
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final navigator = Navigator.of(context);
                              final messenger = ScaffoldMessenger.of(context);

                              final note = noteController.text.trim();
                              final finalNote = note.isNotEmpty
                                  ? note
                                  : (quantity > 1 ? '${e.category} (x$quantity)' : null);

                              await _expenseService.createExpense(
                                storeId: widget.storeId,
                                category: e.category,
                                amount: totalAmount,
                                date: selectedDate,
                                notes: finalNote,
                                recurrenceType: e.recurrenceType ?? 'sekali',
                                recurrenceDurationMonths: e.recurrenceDurationMonths,
                              );

                              navigator.pop();
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Pengeluaran ${e.category} (${_currencyFormat.format(totalAmount)}) berhasil dicatat!',
                                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                                  ),
                                  backgroundColor: const Color(0xFF16A34A),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              );
                            },
                            icon: const Icon(Icons.add_circle_rounded, size: 20),
                            label: Text(
                              '+ Masukkan ke Pengeluaran (${_currencyFormat.format(totalAmount)})',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Opsi Sekunder: Perbarui transaksi ini saja
                        Center(
                          child: TextButton(
                            onPressed: () async {
                              final navigator = Navigator.of(context);
                              final messenger = ScaffoldMessenger.of(context);

                              await _expenseService.updateExpense(
                                id: e.id,
                                amount: totalAmount,
                                notes: noteController.text.trim().isNotEmpty
                                    ? noteController.text.trim()
                                    : e.notes,
                              );

                              navigator.pop();
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Nominal pengeluaran diperbarui menjadi ${_currencyFormat.format(totalAmount)}',
                                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              );
                            },
                            child: Text(
                              'Atau perbarui nominal pada kartu ini saja',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- UI: Expense Item ---
  Widget _buildExpenseItem(Expense e, bool isDark) {
    final icon = _categoryIcons[e.category] ?? Icons.category_rounded;
    final color = _categoryColors[e.category] ?? const Color(0xFF64748B);
    final hasRecurrence = e.recurrenceType != null && e.recurrenceType != 'sekali';

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _showQuickDuplicateExpenseSheet(e),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.category,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      if (e.notes != null && e.notes!.isNotEmpty)
                        Text(
                          e.notes!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: isDark ? Colors.white60 : const Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (!hasRecurrence) ...[
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('dd MMMM yyyy', 'id_ID').format(e.date ?? DateTime.now()),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                      if (hasRecurrence)
                        _buildRecurrenceScheduleBox(e, isDark),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _currencyFormat.format(e.amount ?? 0),
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Tombol Tambah Cepat (+ Tambah)
                        GestureDetector(
                          onTap: () => _showQuickDuplicateExpenseSheet(e),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: primaryColor.withValues(alpha: 0.25), width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.add_rounded, size: 14, color: primaryColor),
                                const SizedBox(width: 3),
                                Text(
                                  'Tambah',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Tombol Hapus
                        GestureDetector(
                          onTap: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => KasirDialog(
                                title: "Hapus Pengeluaran?",
                                message: "Data pengeluaran ini akan dihapus secara permanen.",
                                icon: Icons.delete_outline_rounded,
                                iconColor: primaryColor,
                                isDestructive: true,
                                primaryActionLabel: "Hapus",
                                onPrimaryAction: () => Navigator.pop(ctx, true),
                                secondaryActionLabel: "Batal",
                                onSecondaryAction: () => Navigator.pop(ctx, false),
                              ),
                            );
                            if (confirm == true) {
                              await _expenseService.deleteExpense(e.id);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: primaryColor.withValues(alpha: 0.2), width: 1),
                            ),
                            child: const Icon(Icons.delete_outline_rounded, size: 16, color: primaryColor),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Add Expense Sheet ---
  void _showAddExpenseSheet() {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    final customCategoryController = TextEditingController();
    String selectedCategory = _categories.first;
    DateTime selectedDate = DateTime.now();
    String selectedRecurrence = 'sekali';   // 'sekali','harian','mingguan','bulanan','tahunan','kustom'
    int customDurationMonths = 3;

    // Recurrence options with Harian and Mingguan added!
    final recurrenceOptions = [
      ('sekali', 'Sekali Bayar', Icons.check_circle_outline_rounded),
      ('harian', 'Harian', Icons.today_rounded),
      ('mingguan', 'Mingguan', Icons.view_week_rounded),
      ('bulanan', 'Bulanan', Icons.calendar_view_month_rounded),
      ('tahunan', 'Tahunan', Icons.calendar_month_rounded),
      ('kustom', 'Kustom', Icons.tune_rounded),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final sheetBg = isDark ? const Color(0xFF1E293B) : Colors.white;

        return StatefulBuilder(
          builder: (context, setSheetState) => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 580),
              child: Container(
                decoration: BoxDecoration(
                  color: sheetBg,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    width: 1.2,
                  ),
                ),
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 44,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white24 : Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Tambah Pengeluaran',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 20),
                            onPressed: () => Navigator.pop(context),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // Kategori
                      Text(
                        'Kategori',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: isDark ? Colors.white70 : const Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                            width: 1.2,
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedCategory,
                            isExpanded: true,
                            dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                            items: _categories.map((c) {
                              final icon = _categoryIcons[c] ?? Icons.category_rounded;
                              final color = _categoryColors[c] ?? const Color(0xFF64748B);
                              return DropdownMenuItem(
                                value: c,
                                child: Row(
                                  children: [
                                    Icon(icon, size: 18, color: color),
                                    const SizedBox(width: 10),
                                    Text(
                                      c,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setSheetState(() => selectedCategory = val);
                            },
                          ),
                        ),
                      ),
                      if (selectedCategory == 'Lainnya') ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: customCategoryController,
                          decoration: InputDecoration(
                            hintText: 'Contoh: Kebersihan, Keamanan, dll',
                            hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.grey),
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
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: primaryColor, width: 1.5),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),

                      // Jumlah (Rp)
                      Text(
                        'Jumlah (Rp)',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: isDark ? Colors.white70 : const Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16),
                        decoration: InputDecoration(
                          prefixIcon: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            child: Text(
                              'Rp',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: primaryColor,
                              ),
                            ),
                          ),
                          hintText: '0',
                          hintStyle: GoogleFonts.plusJakartaSans(fontSize: 15, color: Colors.grey),
                          filled: true,
                          fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
                      const SizedBox(height: 18),

                      // Tanggal
                      Text(
                        'Tanggal',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: isDark ? Colors.white70 : const Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                            builder: (context, child) => Theme(
                              data: (isDark ? ThemeData.dark() : ThemeData.light()).copyWith(
                                colorScheme: ColorScheme.light(
                                  primary: primaryColor,
                                  onPrimary: Colors.white,
                                  surface: isDark ? const Color(0xFF1E293B) : Colors.white,
                                  onSurface: isDark ? Colors.white : Colors.black87,
                                ),
                                dialogTheme: DialogThemeData(
                                  backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                                ),
                              ),
                              child: child!,
                            ),
                          );
                          if (d != null) setSheetState(() => selectedDate = d);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_month_rounded, size: 20, color: primaryColor),
                              const SizedBox(width: 12),
                              Text(
                                DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(selectedDate),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // --- Recurrence Selector ---
                      Text(
                        'Frekuensi Pembayaran',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: isDark ? Colors.white70 : const Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 10),
                      GridView.count(
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 2.3,
                        children: recurrenceOptions.map((opt) {
                          final isSelected = selectedRecurrence == opt.$1;
                          return GestureDetector(
                            onTap: () => setSheetState(() => selectedRecurrence = opt.$1),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? primaryColor.withValues(alpha: 0.1)
                                    : (isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF8FAFC)),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected
                                      ? primaryColor
                                      : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    opt.$3,
                                    size: 15,
                                    color: isSelected ? primaryColor : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      opt.$2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                        color: isSelected ? primaryColor : (isDark ? Colors.white70 : const Color(0xFF475569)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      // Custom duration slider
                      if (selectedRecurrence == 'kustom') ...[
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Interval Pembayaran',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: isDark ? Colors.white70 : const Color(0xFF475569),
                              ),
                            ),
                            Text(
                              customDurationMonths < 12
                                  ? '$customDurationMonths Bulan'
                                  : '${customDurationMonths ~/ 12} Tahun ${customDurationMonths % 12 > 0 ? '${customDurationMonths % 12} Bln' : ''}',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                        SliderTheme(
                          data: SliderThemeData(
                            activeTrackColor: primaryColor,
                            thumbColor: primaryColor,
                            overlayColor: primaryColor.withValues(alpha: 0.15),
                          ),
                          child: Slider(
                            value: customDurationMonths.toDouble(),
                            min: 1,
                            max: 60,
                            divisions: 59,
                            onChanged: (v) =>
                                setSheetState(() => customDurationMonths = v.round()),
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),

                      // Catatan (Opsional)
                      Text(
                        'Catatan (Opsional)',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: isDark ? Colors.white70 : const Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: noteController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Keterangan tambahan...',
                          hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.grey),
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
                      const SizedBox(height: 28),

                      // Button Simpan
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () async {
                            final amount = double.tryParse(amountController.text) ?? 0;
                            if (amount <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Jumlah harus lebih dari 0!')),
                              );
                              return;
                            }
                            final finalCategory = selectedCategory == 'Lainnya'
                                ? customCategoryController.text.trim()
                                : selectedCategory;
                            if (selectedCategory == 'Lainnya' && finalCategory.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Nama kategori tidak boleh kosong!')),
                              );
                              return;
                            }

                            // Determine duration in months
                            int? durationMonths;
                            if (selectedRecurrence == 'bulanan') durationMonths = 1;
                            if (selectedRecurrence == 'tahunan') durationMonths = 12;
                            if (selectedRecurrence == 'kustom') durationMonths = customDurationMonths;

                            final navigator = Navigator.of(context);
                            await _expenseService.createExpense(
                              storeId: widget.storeId,
                              category: finalCategory,
                              amount: amount,
                              date: selectedDate,
                              notes: noteController.text.trim(),
                              recurrenceType: selectedRecurrence,
                              recurrenceDurationMonths: durationMonths,
                            );
                            navigator.pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            'Simpan Pengeluaran',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Kelola Pengeluaran',
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
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddExpenseSheet,
        backgroundColor: primaryColor,
        elevation: 2,
        label: Text(
          'Tambah',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white),
      ),
      body: StreamBuilder<List<Expense>>(
        stream: _expenseService.watchExpenses(widget.storeId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryColor));
          }

          final allExpenses = snapshot.data ?? [];
          final filtered = _filterExpenses(allExpenses);
          final grouped = _groupByMonth(filtered);
          final sortedKeys = grouped.keys.toList()
            ..sort((a, b) {
              try {
                final aDate = DateFormat('MMMM yyyy', 'id_ID').parse(a);
                final bDate = DateFormat('MMMM yyyy', 'id_ID').parse(b);
                return bDate.compareTo(aDate);
              } catch (_) {
                return b.compareTo(a);
              }
            });

          return Column(
            children: [
              const SizedBox(height: 12),
              // --- Filter Bar ---
              _buildFilterBar(isDark),

              // --- Summary Card ---
              _buildSummaryCard(filtered, allExpenses, isDark),

              // --- List ---
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
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
                                Icons.receipt_long_rounded,
                                size: 48,
                                color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Belum ada pengeluaran\npada periode ini.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 100),
                        itemCount: sortedKeys.fold<int>(
                          0,
                          (sum, k) => sum + 1 + (grouped[k]?.length ?? 0),
                        ),
                        itemBuilder: (context, index) {
                          int cursor = 0;
                          for (final key in sortedKeys) {
                            final items = grouped[key]!;
                            if (index == cursor) {
                              return _buildMonthHeader(key, items, isDark);
                            }
                            cursor++;
                            if (index < cursor + items.length) {
                              return _buildExpenseItem(
                                  items[index - cursor], isDark);
                            }
                            cursor += items.length;
                          }
                          return const SizedBox.shrink();
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

