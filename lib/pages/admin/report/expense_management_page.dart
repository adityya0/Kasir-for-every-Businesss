import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/app_theme.dart';
import '../../../services/app_database.dart';
import '../../../services/expense_service.dart';
import '../../../services/payment_method_service.dart';
import '../../../widgets/kasir_dialog.dart';
import '../../../widgets/custom_toast.dart';
import '../widgets/green_date_picker_dialog.dart';

enum ExpenseFilterRange { today, thisWeek, thisMonth, custom }

class ExpenseManagementPage extends StatefulWidget {
  final String storeId;

  const ExpenseManagementPage({super.key, required this.storeId});

  @override
  State<ExpenseManagementPage> createState() => _ExpenseManagementPageState();
}

class _ExpenseManagementPageState extends State<ExpenseManagementPage> {
  late ExpenseService _expenseService;
  late PaymentMethodService _paymentMethodService;

  final _currencyFormat = NumberFormat.currency(
    locale: 'id',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

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

  final Map<String, IconData> _categoryIcons = {
    'Listrik & Air': Icons.bolt_rounded,
    'Sewa Tempat': Icons.home_work_rounded,
    'Gaji & Upah': Icons.people_alt_rounded,
    'Makan & Minum': Icons.restaurant_rounded,
    'Transportasi': Icons.directions_car_rounded,
    'Perlengkapan': Icons.build_rounded,
    'Lainnya': Icons.category_rounded,
  };

  final Map<String, Color> _categoryColors = {
    'Listrik & Air': const Color(0xFFD97706),
    'Sewa Tempat': const Color(0xFF2563EB),
    'Gaji & Upah': const Color(0xFF7C3AED),
    'Makan & Minum': const Color(0xFFEA580C),
    'Transportasi': const Color(0xFF059669),
    'Perlengkapan': const Color(0xFF0891B2),
    'Lainnya': const Color(0xFF64748B),
  };

  final Map<String, IconData> _recurrenceIcons = {
    'sekali': Icons.check_circle_outline_rounded,
    'harian': Icons.today_rounded,
    'mingguan': Icons.view_week_rounded,
    'bulanan': Icons.calendar_view_month_rounded,
    'tahunan': Icons.calendar_month_rounded,
    'kustom': Icons.tune_rounded,
  };

  final Map<String, Color> _recurrenceColors = {
    'sekali': const Color(0xFF64748B),
    'harian': const Color(0xFF0D9488),
    'mingguan': const Color(0xFF0284C7),
    'bulanan': const Color(0xFF2563EB),
    'tahunan': const Color(0xFF7C3AED),
    'kustom': const Color(0xFFD97706),
  };

  List<PaymentMethod> _activePaymentMethods = [];

  @override
  void initState() {
    super.initState();
    final db = context.read<AppDatabase>();
    _expenseService = ExpenseService(db);
    _paymentMethodService = PaymentMethodService(db);
    _loadPaymentMethods();
  }

  Future<void> _loadPaymentMethods() async {
    final list = await _paymentMethodService.getPaymentMethods(widget.storeId);
    if (mounted) {
      setState(() {
        _activePaymentMethods = list.where((m) => m.isActive).toList();
      });
    }
  }

  List<Expense> _filterExpenses(List<Expense> all) {
    final now = DateTime.now();
    switch (_selectedFilter) {
      case ExpenseFilterRange.today:
        final start = DateTime(now.year, now.month, now.day);
        final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        return all.where((e) => e.date != null && !e.date!.isBefore(start) && !e.date!.isAfter(end)).toList();

      case ExpenseFilterRange.thisWeek:
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final start = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        final end = start.add(const Duration(days: 7)).subtract(const Duration(seconds: 1));
        return all.where((e) => e.date != null && !e.date!.isBefore(start) && !e.date!.isAfter(end)).toList();

      case ExpenseFilterRange.thisMonth:
        final start = DateTime(now.year, now.month, 1);
        final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        return all.where((e) => e.date != null && !e.date!.isBefore(start) && !e.date!.isAfter(end)).toList();

      case ExpenseFilterRange.custom:
        if (_customStart == null || _customEnd == null) return all;
        final start = DateTime(_customStart!.year, _customStart!.month, _customStart!.day);
        final end = DateTime(_customEnd!.year, _customEnd!.month, _customEnd!.day, 23, 59, 59);
        return all.where((e) => e.date != null && !e.date!.isBefore(start) && !e.date!.isAfter(end)).toList();
    }
  }

  Map<String, List<Expense>> _groupByMonth(List<Expense> expenses) {
    final Map<String, List<Expense>> map = {};
    for (final e in expenses) {
      if (e.date == null) continue;
      final key = DateFormat('MMMM yyyy', 'id_ID').format(e.date!);
      map.putIfAbsent(key, () => []).add(e);
    }
    return map;
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: _customStart != null && _customEnd != null
          ? DateTimeRange(start: _customStart!, end: _customEnd!)
          : DateTimeRange(start: DateTime(now.year, now.month, 1), end: now),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: AppTheme.primaryColor,
            onPrimary: Colors.white,
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

  String _extractMethodName(String? notes) {
    if (notes == null || !notes.contains('[METHOD:')) return 'Kas';
    final reg = RegExp(r'\[METHOD:(.*?)\]');
    final match = reg.firstMatch(notes);
    return match?.group(1) ?? 'Kas';
  }

  String _cleanNotes(String? notes) {
    if (notes == null) return '';
    return notes.replaceAll(RegExp(r'\[METHOD:.*?\]'), '').replaceAll(RegExp(r'\[OUTFLOW.*?\]'), '').trim();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kelola Pengeluaran',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Catatan & Analisis Biaya Operasional',
              style: GoogleFonts.openSans(
                fontWeight: FontWeight.w400,
                fontSize: 11.5,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ],
        ),
        centerTitle: false,
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE2E8F0),
            height: 1,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddExpenseSheet,
        backgroundColor: AppTheme.primaryColor,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        label: Text(
          'Catat Pengeluaran',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 13.5),
        ),
        icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
      ),
      body: StreamBuilder<List<Expense>>(
        stream: _expenseService.watchExpenses(widget.storeId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
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
              _buildFilterBar(isDark),
              _buildSummaryCard(filtered, allExpenses, isDark),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Icon(
                                Icons.receipt_long_rounded,
                                size: 44,
                                color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Belum ada pengeluaran\npada periode ini.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tekan tombol Catat Pengeluaran untuk menambahkan.',
                              style: GoogleFonts.openSans(
                                color: isDark ? Colors.white38 : Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 90, top: 4),
                        itemCount: sortedKeys.length,
                        itemBuilder: (context, i) {
                          final monthKey = sortedKeys[i];
                          final items = grouped[monthKey] ?? [];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildMonthHeader(monthKey, items, isDark),
                              ...items.map((e) => _buildExpenseItem(e, isDark)),
                            ],
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterBar(bool isDark) {
    final filters = [
      (ExpenseFilterRange.today, 'Hari Ini'),
      (ExpenseFilterRange.thisWeek, 'Minggu Ini'),
      (ExpenseFilterRange.thisMonth, 'Bulan Ini'),
    ];

    String customLabel = 'Kustom';
    if (_selectedFilter == ExpenseFilterRange.custom && _customStart != null && _customEnd != null) {
      customLabel = '${DateFormat('dd MMM', 'id_ID').format(_customStart!)} – ${DateFormat('dd MMM', 'id_ID').format(_customEnd!)}';
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
              child: InkWell(
                onTap: () => setState(() => _selectedFilter = f.$1),
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryColor : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? AppTheme.primaryColor : (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE2E8F0)),
                      width: 1.2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      f.$2,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
          InkWell(
            onTap: _pickCustomRange,
            borderRadius: BorderRadius.circular(10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: _selectedFilter == ExpenseFilterRange.custom ? AppTheme.primaryColor : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _selectedFilter == ExpenseFilterRange.custom ? AppTheme.primaryColor : (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE2E8F0)),
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_month_outlined,
                    size: 15,
                    color: _selectedFilter == ExpenseFilterRange.custom ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    customLabel,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: _selectedFilter == ExpenseFilterRange.custom ? FontWeight.w700 : FontWeight.w500,
                      color: _selectedFilter == ExpenseFilterRange.custom ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)),
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

  Widget _buildSummaryCard(List<Expense> filtered, List<Expense> all, bool isDark) {
    final total = filtered.fold<double>(0, (s, e) => s + (e.amount ?? 0));
    final count = filtered.length;
    final avg = count > 0 ? (total / count) : 0.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 14, 20, 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE2E8F0),
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
              Text(
                'TOTAL PENGELUARAN',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$count Transaksi',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFEF4444),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _currencyFormat.format(total),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rata-rata / Pengeluaran',
                      style: GoogleFonts.openSans(fontSize: 11.5, color: isDark ? Colors.white60 : Colors.black54),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _currencyFormat.format(avg),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 28, color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status Akuntansi',
                      style: GoogleFonts.openSans(fontSize: 11.5, color: isDark ? Colors.white60 : Colors.black54),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Beban Operasional',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonthHeader(String monthLabel, List<Expense> items, bool isDark) {
    final subtotal = items.fold<double>(0, (s, e) => s + (e.amount ?? 0));
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 3.5,
                height: 16,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                monthLabel,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          Text(
            _currencyFormat.format(subtotal),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white70 : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseItem(Expense e, bool isDark) {
    final icon = _categoryIcons[e.category] ?? Icons.category_rounded;
    final color = _categoryColors[e.category] ?? AppTheme.primaryColor;
    final hasRecurrence = e.recurrenceType != null && e.recurrenceType != 'sekali';
    final methodName = _extractMethodName(e.notes);
    final cleanNote = _cleanNotes(e.notes);

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 9),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE2E8F0),
          width: 1.1,
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              e.category,
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white10 : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade300, width: 0.8),
                            ),
                            child: Text(
                              methodName,
                              style: GoogleFonts.openSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white70 : const Color(0xFF475569),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Text(
                            e.date != null ? DateFormat('dd MMM yyyy • HH:mm', 'id_ID').format(e.date!) : '-',
                            style: GoogleFonts.openSans(
                              fontSize: 11.5,
                              color: isDark ? Colors.white38 : const Color(0xFF64748B),
                            ),
                          ),
                          if (cleanNote.isNotEmpty) ...[
                            Text(' • ', style: TextStyle(color: isDark ? Colors.white24 : Colors.grey.shade400)),
                            Flexible(
                              child: Text(
                                cleanNote,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.openSans(
                                  fontSize: 11.5,
                                  color: isDark ? Colors.white60 : Colors.black87,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (hasRecurrence) ...[
                        const SizedBox(height: 4),
                        _buildRecurrenceBadge(e, isDark),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '-${_currencyFormat.format(e.amount ?? 0)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                        color: const Color(0xFFE05260),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit_outlined, size: 16, color: isDark ? Colors.white38 : Colors.grey.shade600),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                          onPressed: () => _showEditExpenseDialog(e),
                          tooltip: "Edit",
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFEF4444)),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                          onPressed: () => _confirmDeleteExpense(e),
                          tooltip: "Hapus",
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

  Widget _buildRecurrenceBadge(Expense e, bool isDark) {
    final type = e.recurrenceType;
    if (type == null || type == 'sekali') return const SizedBox.shrink();
    final color = _recurrenceColors[type] ?? const Color(0xFF64748B);
    final icon = _recurrenceIcons[type] ?? Icons.repeat_rounded;

    String label = type.toUpperCase();
    if (type == 'bulanan') label = 'Rutin Bulanan';
    if (type == 'harian') label = 'Rutin Harian';
    if (type == 'mingguan') label = 'Rutin Mingguan';
    if (type == 'tahunan') label = 'Rutin Tahunan';
    if (type == 'kustom') label = 'Rutin ${e.recurrenceDurationMonths ?? 1} Bln';

    final baseDate = e.date ?? DateTime.now();
    final nextDate = _getNextDueDate(baseDate, type, e.recurrenceDurationMonths);
    final countdown = _getDueCountdownText(nextDate);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            '$label • $countdown',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddExpenseSheet() {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    final customCategoryController = TextEditingController();
    String selectedCategory = _categories.first;
    DateTime selectedDate = DateTime.now();
    String selectedRecurrence = 'sekali';
    int customDurationMonths = 3;
    PaymentMethod? selectedMethod = _activePaymentMethods.isNotEmpty ? _activePaymentMethods.first : null;

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
        final sheetBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;

        return StatefulBuilder(
          builder: (context, setSheetState) => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 580),
              child: Container(
                decoration: BoxDecoration(
                  color: sheetBg,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border.all(
                    color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE2E8F0),
                    width: 1.2,
                  ),
                ),
                padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white24 : Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Catat Pengeluaran Baru',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 20),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // NOMINAL
                      Text(
                        'NOMINAL PENGELUARAN (RP)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        autofocus: true,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        decoration: InputDecoration(
                          prefixText: 'Rp ',
                          prefixStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primaryColor,
                          ),
                          hintText: '0',
                          filled: true,
                          fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFCBD5E1),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // KATEGORI & SUMBER AKUN (ROW)
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'KATEGORI',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFCBD5E1)),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: selectedCategory,
                                      isExpanded: true,
                                      dropdownColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                                      items: _categories.map((c) {
                                        final icon = _categoryIcons[c] ?? Icons.category_rounded;
                                        final color = _categoryColors[c] ?? AppTheme.primaryColor;
                                        return DropdownMenuItem(
                                          value: c,
                                          child: Row(
                                            children: [
                                              Icon(icon, size: 16, color: color),
                                              const SizedBox(width: 8),
                                              Flexible(
                                                child: Text(
                                                  c,
                                                  style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
                                                  overflow: TextOverflow.ellipsis,
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
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'SUMBER AKUN KAS',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFCBD5E1)),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<PaymentMethod>(
                                      value: selectedMethod,
                                      isExpanded: true,
                                      dropdownColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                                      hint: const Text("Pilih Akun"),
                                      items: _activePaymentMethods.map((m) {
                                        return DropdownMenuItem(
                                          value: m,
                                          child: Row(
                                            children: [
                                              const Icon(Icons.account_balance_wallet_outlined, size: 16, color: AppTheme.primaryColor),
                                              const SizedBox(width: 8),
                                              Flexible(
                                                child: Text(
                                                  m.name,
                                                  style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        if (val != null) setSheetState(() => selectedMethod = val);
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      if (selectedCategory == 'Lainnya') ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: customCategoryController,
                          decoration: InputDecoration(
                            hintText: 'Tulis nama kategori pengeluaran...',
                            filled: true,
                            fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFCBD5E1)),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),

                      // TANGGAL & WAKTU
                      Text(
                        'TANGGAL & WAKTU',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () async {
                          final pickedDate = await showDialog<DateTime>(
                            context: context,
                            builder: (ctx) => GreenDatePickerDialog(
                              initialDate: selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            ),
                          );
                          if (pickedDate != null) {
                            setSheetState(() => selectedDate = DateTime(
                              pickedDate.year,
                              pickedDate.month,
                              pickedDate.day,
                              selectedDate.hour,
                              selectedDate.minute,
                            ));
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFCBD5E1)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.event_rounded, size: 18, color: AppTheme.primaryColor),
                              const SizedBox(width: 10),
                              Text(
                                DateFormat('EEEE, dd MMMM yyyy • HH:mm', 'id_ID').format(selectedDate),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // JADWAL PENGELUARAN (RECURRENCE)
                      Text(
                        'JADWAL / PENGULANGAN',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: recurrenceOptions.map((opt) {
                            final isSel = selectedRecurrence == opt.$1;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(opt.$3, size: 14, color: isSel ? Colors.white : (isDark ? Colors.white70 : Colors.black87)),
                                    const SizedBox(width: 6),
                                    Text(opt.$2),
                                  ],
                                ),
                                selected: isSel,
                                selectedColor: AppTheme.primaryColor,
                                backgroundColor: isDark ? Colors.white10 : Colors.grey.shade100,
                                labelStyle: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                                  color: isSel ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                                ),
                                onSelected: (val) {
                                  if (val) setSheetState(() => selectedRecurrence = opt.$1);
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // CATATAN
                      Text(
                        'KETERANGAN / CATATAN (OPSIONAL)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: noteController,
                        decoration: InputDecoration(
                          hintText: 'Contoh: Token listrik ruko lantai 1...',
                          filled: true,
                          fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFCBD5E1)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // TOMBOL SIMPAN
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          onPressed: () async {
                            final rawAmt = amountController.text.replaceAll('.', '').replaceAll(',', '');
                            final amount = double.tryParse(rawAmt) ?? 0.0;
                            if (amount <= 0) {
                              CustomToast.show(context, 'Masukkan nominal pengeluaran yang valid', isError: true);
                              return;
                            }

                            final finalCategory = (selectedCategory == 'Lainnya' && customCategoryController.text.trim().isNotEmpty)
                                ? customCategoryController.text.trim()
                                : selectedCategory;

                            int? durationMonths;
                            if (selectedRecurrence == 'bulanan') durationMonths = 1;
                            if (selectedRecurrence == 'tahunan') durationMonths = 12;
                            if (selectedRecurrence == 'kustom') durationMonths = customDurationMonths;

                            final methodName = selectedMethod?.name ?? 'Kas';
                            final noteText = noteController.text.trim();
                            final fullNotes = '[METHOD:$methodName] $noteText'.trim();

                            Navigator.pop(context);

                            await _expenseService.createExpense(
                              storeId: widget.storeId,
                              category: finalCategory,
                              amount: amount,
                              date: selectedDate,
                              notes: fullNotes,
                              recurrenceType: selectedRecurrence,
                              recurrenceDurationMonths: durationMonths,
                            );

                            if (context.mounted) {
                              CustomToast.show(context, 'Pengeluaran sebesar ${_currencyFormat.format(amount)} berhasil dicatat');
                            }
                          },
                          child: Text(
                            'Simpan Pengeluaran',
                            style: GoogleFonts.plusJakartaSans(fontSize: 14.5, fontWeight: FontWeight.w700),
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

  void _showQuickDuplicateExpenseSheet(Expense e) {
    int quantity = 1;
    final double unitPrice = e.amount ?? 0;
    DateTime selectedDate = DateTime.now();
    final noteController = TextEditingController(text: _cleanNotes(e.notes));
    final methodName = _extractMethodName(e.notes);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final sheetBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
        final icon = _categoryIcons[e.category] ?? Icons.category_rounded;
        final color = _categoryColors[e.category] ?? AppTheme.primaryColor;

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
                    border: Border.all(color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE2E8F0)),
                  ),
                  padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white24 : Colors.grey[300],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: color.withValues(alpha: 0.25)),
                              ),
                              child: Icon(icon, color: color, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    e.category,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Duplikasi / Catat Ulang Pengeluaran',
                                    style: GoogleFonts.openSans(
                                      fontSize: 12,
                                      color: isDark ? Colors.white60 : Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 20),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // QUANTITY STEPPER
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Jumlah Frekuensi',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline_rounded),
                                  color: quantity > 1 ? AppTheme.primaryColor : Colors.grey,
                                  onPressed: quantity > 1 ? () => setSheetState(() => quantity--) : null,
                                ),
                                Text(
                                  '$quantity',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline_rounded),
                                  color: AppTheme.primaryColor,
                                  onPressed: () => setSheetState(() => quantity++),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // TOTAL
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white10 : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Total Pengeluaran Baru', style: GoogleFonts.openSans(fontSize: 13)),
                              Text(
                                _currencyFormat.format(totalAmount),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFFEF4444),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            onPressed: () async {
                              final fullNotes = '[METHOD:$methodName] ${noteController.text.trim()}'.trim();
                              Navigator.pop(context);

                              await _expenseService.createExpense(
                                storeId: widget.storeId,
                                category: e.category,
                                amount: totalAmount,
                                date: selectedDate,
                                notes: fullNotes,
                                recurrenceType: e.recurrenceType,
                                recurrenceDurationMonths: e.recurrenceDurationMonths,
                              );

                              if (context.mounted) {
                                CustomToast.show(context, 'Pengeluaran berhasil diduplikasi');
                              }
                            },
                            child: Text(
                              'Konfirmasi Catat Ulang',
                              style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700),
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

  void _showEditExpenseDialog(Expense e) {
    final amountController = TextEditingController(text: (e.amount ?? 0).toInt().toString());
    final noteController = TextEditingController(text: _cleanNotes(e.notes));
    final methodName = _extractMethodName(e.notes);
    String selectedCategory = e.category;
    DateTime selectedDate = e.date ?? DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Edit Pengeluaran",
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Nominal (Rp)", prefixText: "Rp "),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(labelText: "Catatan / Keterangan"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final newAmt = double.tryParse(amountController.text.replaceAll('.', '').replaceAll(',', '')) ?? 0.0;
              if (newAmt <= 0) return;

              final fullNotes = '[METHOD:$methodName] ${noteController.text.trim()}'.trim();
              Navigator.pop(ctx);

              await _expenseService.updateExpense(
                id: e.id,
                amount: newAmt,
                notes: fullNotes,
                category: selectedCategory,
                date: selectedDate,
              );

              if (mounted) {
                CustomToast.show(context, "Pengeluaran berhasil diperbarui");
              }
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteExpense(Expense e) {
    showDialog(
      context: context,
      builder: (ctx) => KasirDialog(
        title: "Hapus Pengeluaran",
        message: "Yakin ingin menghapus catatan pengeluaran ${e.category} sebesar ${_currencyFormat.format(e.amount ?? 0)}?",
        icon: Icons.delete_outline_rounded,
        isDestructive: true,
        primaryActionLabel: "Hapus",
        onPrimaryAction: () async {
          Navigator.pop(ctx);
          await _expenseService.deleteExpense(e.id);
          if (mounted) {
            CustomToast.show(context, "Pengeluaran berhasil dihapus");
          }
        },
        secondaryActionLabel: "Batal",
        onSecondaryAction: () => Navigator.pop(ctx),
      ),
    );
  }
}
