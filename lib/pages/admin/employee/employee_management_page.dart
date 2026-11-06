import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' as drift;
import '../../../services/app_database.dart';
import '../../../services/employee_service.dart';
import '../../../widgets/kasir_dialog.dart';
import '../../../controllers/analytics_controller.dart';
import '../../attendance/attendance_page.dart';

class EmployeeManagementPage extends StatefulWidget {
  final String storeId;
  final VoidCallback? onBack;

  const EmployeeManagementPage({
    super.key,
    required this.storeId,
    this.onBack,
  });

  @override
  State<EmployeeManagementPage> createState() => _EmployeeManagementPageState();
}

class _EmployeeManagementPageState extends State<EmployeeManagementPage> {
  static const primaryColor = Color(0xFF00BF63);
  late EmployeeService _employeeService;
  bool _isLoading = true;
  List<Map<String, dynamic>> _employees = [];
  String _searchQuery = '';
  DateTime _selectedMonth = DateTime.now();

  final _currencyFormat = NumberFormat.currency(
    locale: 'id',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    final db = context.read<AppDatabase>();
    _employeeService = EmployeeService(db);
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    setState(() => _isLoading = true);
    try {
      final list = await _employeeService.getEmployeesWithStats(
        widget.storeId,
        month: _selectedMonth,
      );
      if (mounted) {
        setState(() {
          _employees = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading employees: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredEmployees {
    if (_searchQuery.trim().isEmpty) return _employees;
    return _employees.where((e) {
      final name = (e['fullName'] ?? '').toString().toLowerCase();
      final email = (e['email'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase()) || email.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final monthName = DateFormat('MMMM yyyy', 'id').format(_selectedMonth);

    // Summary calculations
    final totalShift = _employees.fold<int>(0, (sum, e) => sum + (e['shiftCount'] as int? ?? 0));
    final totalKasbon = _employees.fold<double>(0, (sum, e) => sum + (e['kasbonTotal'] as double? ?? 0));
    final totalEstimatedSalary = _employees.fold<double>(0, (sum, e) => sum + (e['calculatedSalary'] as double? ?? 0));

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          "Kelola Pegawai & Gaji",
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 17,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: widget.onBack != null
            ? IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                onPressed: widget.onBack,
              )
            : (Navigator.canPop(context)
                ? IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    onPressed: () => Navigator.pop(context),
                  )
                : null),
        actions: [
          IconButton(
            icon: Icon(
              Icons.fingerprint_rounded,
              color: isDark ? Colors.white : primaryColor,
              size: 24,
            ),
            tooltip: "Presensi & Kehadiran Pegawai",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AttendancePage(showSidebar: false),
                ),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: isDark ? const Color(0xFF374151) : const Color(0xFFE2E8F0),
            height: 1,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CupertinoActivityIndicator())
          : RefreshIndicator(
              onRefresh: _loadEmployees,
              color: primaryColor,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width < 500 ? 12 : 20,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Month selector & Quick Summary
                    _buildMonthAndSummaryHeader(isDark, monthName, totalShift, totalKasbon, totalEstimatedSalary),
                    const SizedBox(height: 20),

                    // Search box
                    _buildSearchBox(isDark),
                    const SizedBox(height: 20),

                    // Employee List Section Header
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isSmall = constraints.maxWidth < 600;
                        if (isSmall) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Daftar Karyawan (${_filteredEmployees.length})",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () => _showAllSalaryHistoryDialog(isDark),
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(
                                        color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                                        width: 1.1,
                                      ),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      backgroundColor: isDark ? Colors.white10 : Colors.white,
                                    ),
                                    icon: const Icon(Icons.receipt_long_rounded, size: 15, color: Color(0xFF2563EB)),
                                    label: Text(
                                      "Riwayat Gaji",
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                                      ),
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () => _showAddEmployeeDialog(context, isDark),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryColor,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    ),
                                    icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                                    label: Text(
                                      "Tambah Karyawan",
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        }
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Daftar Karyawan (${_filteredEmployees.length})",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            Wrap(
                              spacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () => _showAllSalaryHistoryDialog(isDark),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                      color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                                      width: 1.1,
                                    ),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    backgroundColor: isDark ? Colors.white10 : Colors.white,
                                  ),
                                  icon: const Icon(Icons.receipt_long_rounded, size: 15, color: Color(0xFF2563EB)),
                                  label: Text(
                                    "Riwayat Bayar Gaji",
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                                    ),
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () => _showAddEmployeeDialog(context, isDark),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  ),
                                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                                  label: Text(
                                    "Tambah Karyawan",
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    if (_filteredEmployees.isEmpty)
                      _buildEmptyState(isDark)
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _filteredEmployees.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final emp = _filteredEmployees[index];
                          return _buildEmployeeCard(emp, isDark);
                        },
                      ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMonthAndSummaryHeader(
    bool isDark,
    String monthName,
    int totalShift,
    double totalKasbon,
    double totalEstimatedSalary,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Month Selector Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? const Color(0xFF374151) : const Color(0xFFCBD5E1),
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_month_rounded, size: 18, color: primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    "Periode: $monthName",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      setState(() {
                        _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1);
                      });
                      _loadEmployees();
                    },
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      setState(() {
                        _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
                      });
                      _loadEmployees();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 4 KPI Cards
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: "Total Pegawai",
                value: "${_employees.length} Orang",
                icon: Icons.people_outline_rounded,
                color: const Color(0xFF2563EB),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricCard(
                title: "Total Shift",
                value: "$totalShift Shift",
                icon: Icons.access_time_rounded,
                color: const Color(0xFF10B981),
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: "Beban Gaji",
                value: _currencyFormat.format(totalEstimatedSalary),
                icon: Icons.payments_outlined,
                color: primaryColor,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricCard(
                title: "Kasbon Aktif",
                value: _currencyFormat.format(totalKasbon),
                icon: Icons.receipt_long_outlined,
                color: const Color(0xFFD97706),
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF374151) : const Color(0xFFCBD5E1),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: color, size: 14),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.openSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBox(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF374151) : const Color(0xFFCBD5E1),
          width: 1.2,
        ),
      ),
      child: TextField(
        onChanged: (val) => setState(() => _searchQuery = val),
        style: GoogleFonts.openSans(
          fontSize: 13,
          color: isDark ? Colors.white : Colors.black87,
        ),
        decoration: InputDecoration(
          hintText: "Cari nama karyawan...",
          hintStyle: GoogleFonts.openSans(
            fontSize: 13,
            color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
          ),
          prefixIcon: const Icon(Icons.search, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildEmployeeCard(Map<String, dynamic> emp, bool isDark) {
    final name = emp['fullName'] ?? 'Karyawan';
    final email = emp['email'] ?? '';
    final role = emp['role'] ?? 'staff';
    final roleTitle = emp['roleTitle'] ?? (role == 'cashier' ? 'Kasir' : 'Staff');
    final hasLoginAccount = emp['hasLoginAccount'] as bool? ?? (email.isNotEmpty && email != '-');
    final shiftCount = emp['shiftCount'] as int? ?? 0;
    final absentCount = emp['absentCount'] as int? ?? 0;
    final salaryType = emp['salaryType'] as String? ?? 'monthly';
    final ratePerShift = emp['ratePerShift'] as double? ?? 75000.0;
    final monthlySalary = emp['monthlySalary'] as double? ?? 2000000.0;
    final kasbonTotal = emp['kasbonTotal'] as double? ?? 0.0;
    final calculatedSalary = emp['calculatedSalary'] as double? ?? monthlySalary;
    final netSalary = emp['netSalary'] as double? ?? (calculatedSalary - kasbonTotal).clamp(0, double.infinity);
    final todayStatus = emp['todayStatus'] as String? ?? 'Belum Absen';
    final isSalaryPaid = emp['isSalaryPaid'] as bool? ?? false;
    final monthName = DateFormat('MMMM yyyy', 'id').format(_selectedMonth);

    Color statusBadgeColor = Colors.grey;
    if (todayStatus == 'Sedang Bekerja') {
      statusBadgeColor = Colors.green;
    } else if (todayStatus == 'Selesai Shift') {
      statusBadgeColor = Colors.blue;
    } else if (todayStatus == 'Izin / Tidak Hadir') {
      statusBadgeColor = Colors.redAccent;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF374151) : const Color(0xFFE2E8F0),
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
          // Header: Avatar, Name & Role, Today Status, and Menu
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: primaryColor.withValues(alpha: 0.12),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'K',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Role Title Badge & Subtitle diletakkan rapi di bawah nama
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.3) : const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                              color: const Color(0xFF3B82F6).withValues(alpha: 0.25),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            roleTitle,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF2563EB),
                            ),
                          ),
                        ),
                        if (hasLoginAccount && email.isNotEmpty && email != '-') ...[
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              email,
                              style: GoogleFonts.openSans(
                                fontSize: 11,
                                color: isDark ? Colors.white54 : const Color(0xFF64748B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Today status pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBadgeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: statusBadgeColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: statusBadgeColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      todayStatus,
                      style: GoogleFonts.openSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusBadgeColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              // Premium Redesigned Dropdown Menu (Positioned cleanly right below icon, not bottom screen)
              Theme(
                data: Theme.of(context).copyWith(
                  hoverColor: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                ),
                child: PopupMenuButton<String>(
                  offset: const Offset(0, 36),
                  elevation: 12,
                  shadowColor: Colors.black.withValues(alpha: isDark ? 0.6 : 0.15),
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  surfaceTintColor: Colors.transparent,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 230),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      width: 1,
                    ),
                  ),
                  icon: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.more_vert_rounded,
                      size: 18,
                      color: isDark ? Colors.white70 : const Color(0xFF64748B),
                    ),
                  ),
                  tooltip: "Menu Karyawan",
                  onSelected: (val) {
                    if (val == 'salary_settings') {
                      _showSalaryConfigDialog(emp, isDark);
                    } else if (val == 'kasbon_history') {
                      _showKasbonHistoryDialog(emp, isDark);
                    } else if (val == 'salary_history') {
                      _showEmployeeSalaryHistoryDialog(emp, isDark);
                    } else if (val == 'account') {
                      _showManageAccountDialog(emp, isDark);
                    } else if (val == 'delete') {
                      _confirmDeleteEmployee(emp);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'salary_settings',
                      height: 42,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.tune_rounded, size: 15, color: Color(0xFF2563EB)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Sistem Gaji (${salaryType == 'shift' ? 'Per Shift' : 'Bulanan'})",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : const Color(0xFF1E293B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'salary_history',
                      height: 42,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.receipt_long_rounded, size: 15, color: Color(0xFF10B981)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Riwayat Gaji Karyawan Ini",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : const Color(0xFF1E293B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'kasbon_history',
                      height: 42,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD97706).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.history_rounded, size: 15, color: Color(0xFFD97706)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Riwayat Kasbon Lengkap",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : const Color(0xFF1E293B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'account',
                      height: 42,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.purple.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              hasLoginAccount ? Icons.key_rounded : Icons.person_add_alt_rounded,
                              size: 15,
                              color: Colors.purple.shade600,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              hasLoginAccount ? "Ganti Password Akun" : "Buatkan Akun Login Kasir",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : const Color(0xFF1E293B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(
                      height: 12,
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      height: 42,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.delete_outline_rounded, size: 15, color: Colors.redAccent),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Hapus Karyawan",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.redAccent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ─── STATUS CEKLIS GAJI TERBAYAR (HANYA MUNCUL JIKA SUDAH DIBAYAR) ───
          if (isSalaryPaid) ...[
            _buildSalaryChecklistBar(emp, monthName, isDark),
            const SizedBox(height: 12),
          ],

          // ─── 3 INTERACTIVE COLUMNS (Gaji Bulanan, Kasbon, Terima Bersih) ───
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxWidth < 520;
              final colSalary = _buildInteractiveCol(
                title: "Gaji Per Bulan",
                value: _currencyFormat.format(monthlySalary),
                icon: Icons.payments_outlined,
                color: const Color(0xFF2563EB),
                isDark: isDark,
                hint: "Tekan untuk edit",
                isEditable: true,
                onTap: () => _showQuickSalaryEditDialog(emp, isDark),
              );

              final colKasbon = _buildInteractiveCol(
                title: "Kasbon Aktif",
                value: _currencyFormat.format(kasbonTotal),
                icon: Icons.receipt_long_outlined,
                color: const Color(0xFFD97706),
                isDark: isDark,
                hint: kasbonTotal > 0 ? "Memotong gaji" : "Tekan untuk isi",
                isEditable: true,
                onTap: () => _showQuickKasbonEditDialog(emp, isDark),
              );

              final colNet = _buildInteractiveCol(
                title: "Terima Bersih",
                value: _currencyFormat.format(netSalary),
                icon: Icons.account_balance_wallet_outlined,
                color: primaryColor,
                isDark: isDark,
                hint: "(Gaji - Kasbon)",
                isHighlighted: true,
                onTap: null,
              );

              if (isSmall) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: colSalary),
                        const SizedBox(width: 8),
                        Expanded(child: colKasbon),
                      ],
                    ),
                    const SizedBox(height: 8),
                    colNet,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: colSalary),
                  const SizedBox(width: 10),
                  Expanded(child: colKasbon),
                  const SizedBox(width: 10),
                  Expanded(child: colNet),
                ],
              );
            },
          ),

          const SizedBox(height: 10),

          // Info bar: Shifts & Attendance
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF262626) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isDark ? const Color(0xFF374151) : const Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
            child: Wrap(
              spacing: 12,
              runSpacing: 6,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.event_available_rounded, size: 14, color: Color(0xFF10B981)),
                    const SizedBox(width: 5),
                    Text(
                      "Shift Bulan Ini: $shiftCount",
                      style: GoogleFonts.openSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : const Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.event_busy_rounded,
                      size: 14,
                      color: absentCount > 0 ? Colors.redAccent : Colors.grey,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      "Izin/Absen: $absentCount Hari",
                      style: GoogleFonts.openSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: absentCount > 0 ? Colors.redAccent : (isDark ? Colors.white60 : Colors.grey),
                      ),
                    ),
                  ],
                ),
                Text(
                  salaryType == 'shift'
                      ? "Sistem: ${_currencyFormat.format(ratePerShift)}/shift"
                      : "Sistem: Bulanan",
                  style: GoogleFonts.openSans(
                    fontSize: 11,
                    color: isDark ? Colors.white54 : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Actions Row: Only 2 clean & practical buttons (Bayar Gaji & Absensi)
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSalaryPaid ? const Color(0xFF10B981) : primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  icon: Icon(
                    isSalaryPaid ? Icons.check_circle_rounded : Icons.payments_rounded,
                    size: 16,
                  ),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      isSalaryPaid ? "Sudah Dibayar" : "Bayar Gaji",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  onPressed: () {
                    if (isSalaryPaid) {
                      _showEmployeeSalaryHistoryDialog(emp, isDark);
                    } else {
                      _showPaySalaryDialog(emp, isDark);
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D9488),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.access_time_filled_rounded, size: 16),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      "Absensi",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  onPressed: () => _showAttendanceDialog(emp, isDark),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveCol({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
    required String hint,
    required VoidCallback? onTap,
    bool isEditable = false,
    bool isHighlighted = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.12 : 0.06),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: color.withValues(alpha: isDark ? 0.35 : 0.25),
              width: isHighlighted ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 14, color: color),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.openSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : const Color(0xFF475569),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isEditable) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit_rounded, size: 9, color: color),
                          const SizedBox(width: 2),
                          Text(
                            "Edit",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: isHighlighted ? color : (isDark ? Colors.white : const Color(0xFF0F172A)),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                hint,
                style: GoogleFonts.openSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: isEditable
                      ? color.withValues(alpha: 0.8)
                      : (isDark ? Colors.white38 : const Color(0xFF94A3B8)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF374151) : const Color(0xFFCBD5E1),
          width: 1.2,
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.badge_outlined, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            "Belum ada data karyawan",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Tambah karyawan untuk mengelola shift, absen, kasbon & gaji.",
            style: GoogleFonts.openSans(
              fontSize: 12,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ─── DIALOGS ─────────────────────────────────────────────────────────────

  /// Edit Cepat Gaji Bulanan (Tap to edit pada kolom gaji)
  void _showQuickSalaryEditDialog(Map<String, dynamic> emp, bool isDark) {
    final userId = emp['id'] as String;
    final name = emp['fullName'] ?? 'Karyawan';
    final currentSalary = (emp['monthlySalary'] as num?)?.toDouble() ?? 2000000.0;
    final salaryCtrl = TextEditingController(text: currentSalary.toInt().toString());

    showDialog(
      context: context,
      builder: (ctx) => KasirDialog(
        title: "Edit Gaji Bulanan",
        message: "Atur jumlah gaji pokok bulanan untuk $name. Kolom Terima Bersih akan otomatis menyesuaikan.",
        icon: Icons.payments_rounded,
        iconColor: const Color(0xFF2563EB),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: TextField(
            controller: salaryCtrl,
            keyboardType: TextInputType.number,
            autofocus: true,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              labelText: "Gaji Per Bulan (Rp)",
              prefixText: "Rp ",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ),
        primaryActionLabel: "Simpan Gaji",
        onPrimaryAction: () async {
          final val = double.tryParse(salaryCtrl.text.trim()) ?? currentSalary;
          Navigator.pop(ctx);
          setState(() => _isLoading = true);
          try {
            await _employeeService.updateMonthlySalary(userId, val);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Gaji bulanan $name diperbarui menjadi ${_currencyFormat.format(val)}!"),
                  backgroundColor: Colors.green,
                ),
              );
            }
            _loadEmployees();
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Gagal memperbarui gaji: $e"), backgroundColor: Colors.red),
              );
            }
            setState(() => _isLoading = false);
          }
        },
        secondaryActionLabel: "Batal",
        onSecondaryAction: () => Navigator.pop(ctx),
      ),
    );
  }

  /// Edit Cepat Kasbon (Tap to edit pada kolom kasbon, otomatis memotong gaji)
  void _showQuickKasbonEditDialog(Map<String, dynamic> emp, bool isDark) {
    final userId = emp['id'] as String;
    final name = emp['fullName'] ?? 'Karyawan';
    final currentKasbon = (emp['kasbonTotal'] as num?)?.toDouble() ?? 0.0;
    final kasbonCtrl = TextEditingController(text: currentKasbon.toInt().toString());
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => KasirDialog(
        title: "Edit Kasbon Karyawan",
        message: "Kasbon yang diisi akan otomatis memotong total gaji yang diterima oleh $name.",
        icon: Icons.receipt_long_rounded,
        iconColor: const Color(0xFFD97706),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFD97706).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFD97706).withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Kasbon Saat Ini:", style: GoogleFonts.openSans(fontSize: 12)),
                  Text(
                    _currencyFormat.format(currentKasbon),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFD97706),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: kasbonCtrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                labelText: "Total Kasbon Aktif (Rp)",
                prefixText: "Rp ",
                hintText: "0 jika lunas",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: notesCtrl,
              decoration: InputDecoration(
                labelText: "Keterangan / Catatan (Opsional)",
                hintText: "Contoh: Pinjaman kasbon / pelunasan",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ],
        ),
        primaryActionLabel: "Simpan Kasbon",
        onPrimaryAction: () async {
          final val = double.tryParse(kasbonCtrl.text.trim()) ?? 0.0;
          final notes = notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : null;
          Navigator.pop(ctx);
          setState(() => _isLoading = true);
          try {
            await _employeeService.setKasbonTotal(userId, val, notes: notes);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Kasbon $name disetel menjadi ${_currencyFormat.format(val)} (otomatis memotong gaji)!"),
                  backgroundColor: Colors.green,
                ),
              );
            }
            _loadEmployees();
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Gagal memperbarui kasbon: $e"), backgroundColor: Colors.red),
              );
            }
            setState(() => _isLoading = false);
          }
        },
        secondaryActionLabel: "Batal",
        onSecondaryAction: () => Navigator.pop(ctx),
      ),
    );
  }

  /// Riwayat Transaksi Kasbon Lengkap
  void _showKasbonHistoryDialog(Map<String, dynamic> emp, bool isDark) {
    final name = emp['fullName'] ?? 'Karyawan';
    final history = emp['kasbonHistory'] as List<Map<String, dynamic>>? ?? [];

    showDialog(
      context: context,
      builder: (ctx) => KasirDialog(
        title: "Riwayat Kasbon - $name",
        icon: Icons.history_rounded,
        iconColor: const Color(0xFFD97706),
        content: history.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    "Belum ada riwayat transaksi kasbon.",
                    style: GoogleFonts.openSans(fontSize: 12, color: Colors.grey),
                  ),
                ),
              )
            : Container(
                constraints: const BoxConstraints(maxHeight: 250),
                decoration: BoxDecoration(
                  border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: history.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final item = history[i];
                    final amt = (item['amount'] is num) ? (item['amount'] as num).toDouble() : 0.0;
                    final dt = item['date'] != null
                        ? DateFormat('dd MMM yyyy, HH:mm').format(DateTime.tryParse(item['date'].toString()) ?? DateTime.now())
                        : '';
                    final nts = item['notes'] ?? '';
                    final isAdd = item['type'] == 'add';

                    return ListTile(
                      dense: true,
                      title: Text(
                        isAdd ? "+ ${_currencyFormat.format(amt)}" : "- ${_currencyFormat.format(amt)}",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isAdd ? Colors.redAccent : Colors.green,
                        ),
                      ),
                      subtitle: Text("$dt\n$nts", style: const TextStyle(fontSize: 11)),
                    );
                  },
                ),
              ),
        primaryActionLabel: "Tutup",
        onPrimaryAction: () => Navigator.pop(ctx),
      ),
    );
  }

  /// Kelola Akun Login Kasir (Buat atau Ganti Password)
  void _showManageAccountDialog(Map<String, dynamic> emp, bool isDark) {
    final userId = emp['id'] as String;
    final name = emp['fullName'] ?? 'Karyawan';
    final currentEmail = emp['email'] as String? ?? '';
    final hasLogin = emp['hasLoginAccount'] as bool? ?? (currentEmail.isNotEmpty && currentEmail != '-');

    final emailCtrl = TextEditingController(text: currentEmail == '-' ? '' : currentEmail);
    final passCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => KasirDialog(
        title: hasLogin ? "Ganti Password - $name" : "Buatkan Akun Login - $name",
        message: hasLogin
            ? "Masukkan password/PIN baru untuk akun kasir $name:"
            : "Buatkan email & password agar karyawan ini dapat login sebagai kasir:",
        icon: Icons.key_rounded,
        iconColor: Colors.purple.shade700,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!hasLogin) ...[
              TextField(
                controller: emailCtrl,
                decoration: InputDecoration(
                  labelText: "Email / Username Login",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 10),
            ],
            TextField(
              controller: passCtrl,
              obscureText: true,
              decoration: InputDecoration(
                labelText: hasLogin ? "Password / PIN Baru" : "Password / PIN",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ],
        ),
        primaryActionLabel: "Simpan",
        onPrimaryAction: () async {
          final pass = passCtrl.text.trim();
          final email = emailCtrl.text.trim();
          if (pass.isEmpty || (!hasLogin && email.isEmpty)) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Semua kolom wajib diisi!"), backgroundColor: Colors.red),
            );
            return;
          }
          Navigator.pop(ctx);
          setState(() => _isLoading = true);
          try {
            final db = context.read<AppDatabase>();
            if (hasLogin) {
              await (db.update(db.profiles)..where((t) => t.id.equals(userId))).write(
                ProfilesCompanion(
                  password: drift.Value(pass),
                  lastUpdated: drift.Value(DateTime.now()),
                ),
              );
            } else {
              await (db.update(db.profiles)..where((t) => t.id.equals(userId))).write(
                ProfilesCompanion(
                  email: drift.Value(email),
                  password: drift.Value(pass),
                  role: const drift.Value('cashier'),
                  lastUpdated: drift.Value(DateTime.now()),
                ),
              );
            }
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Akun login untuk $name berhasil diperbarui!"), backgroundColor: Colors.green),
              );
            }
            _loadEmployees();
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
              );
            }
            setState(() => _isLoading = false);
          }
        },
        secondaryActionLabel: "Batal",
        onSecondaryAction: () => Navigator.pop(ctx),
      ),
    );
  }

  // ─── DIALOGS ─────────────────────────────────────────────────────────────

  /// Bayar Gaji & Catat ke Pengeluaran Toko
  void _showPaySalaryDialog(Map<String, dynamic> emp, bool isDark) {
    final userId = emp['id'] as String;
    final name = emp['fullName'] ?? 'Karyawan';
    final netSalary = emp['netSalary'] as double? ?? 0.0;
    final kasbonTotal = emp['kasbonTotal'] as double? ?? 0.0;
    final calculatedSalary = emp['calculatedSalary'] as double? ?? 0.0;
    final monthName = DateFormat('MMMM yyyy', 'id').format(_selectedMonth);

    final amountController = TextEditingController(text: netSalary.toInt().toString());
    final kasbonDeductController = TextEditingController(text: kasbonTotal.toInt().toString());
    final noteController = TextEditingController(text: "Gaji $monthName");
    bool recordAsExpense = true;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return KasirDialog(
              title: "Bayar Gaji $name",
              icon: Icons.payments_rounded,
              iconColor: primaryColor,
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Gaji Dihitung:", style: GoogleFonts.openSans(fontSize: 12)),
                              Text(_currencyFormat.format(calculatedSalary), style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Kasbon Aktif:", style: GoogleFonts.openSans(fontSize: 12, color: Colors.amber.shade800)),
                              Text("- ${_currencyFormat.format(kasbonTotal)}", style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber.shade800)),
                            ],
                          ),
                          const Divider(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Bersih Diterima:", style: GoogleFonts.openSans(fontSize: 13, fontWeight: FontWeight.bold)),
                              Text(_currencyFormat.format(netSalary), style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: primaryColor)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Amount input
                    Text("Nominal Gaji Dibayar (Rp)", style: GoogleFonts.openSans(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        prefixText: "Rp ",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Kasbon deduction input
                    Text("Potong Kasbon (Rp)", style: GoogleFonts.openSans(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: kasbonDeductController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        prefixText: "Rp ",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Notes input
                    Text("Keterangan", style: GoogleFonts.openSans(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: noteController,
                      decoration: InputDecoration(
                        hintText: "Contoh: Gaji Oktober 2026",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Checkbox record as expense
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: recordAsExpense,
                      title: Text(
                        "Catat Otomatis ke Pengeluaran Toko",
                        style: GoogleFonts.openSans(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        "Otomatis masuk ke laporan keuangan kategori 'Gaji'",
                        style: GoogleFonts.openSans(fontSize: 11, color: Colors.grey),
                      ),
                      onChanged: (val) => setModalState(() => recordAsExpense = val ?? true),
                      activeColor: primaryColor,
                    ),
                  ],
                ),
              ),
              primaryActionLabel: "Bayar & Catat",
              onPrimaryAction: () async {
                final netPaid = double.tryParse(amountController.text.trim()) ?? netSalary;
                final kasbonDeducted = double.tryParse(kasbonDeductController.text.trim()) ?? 0.0;
                final period = noteController.text.trim().isNotEmpty ? noteController.text.trim() : monthName;

                Navigator.pop(ctx);
                setState(() => _isLoading = true);

                try {
                  final monthKey = "${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2, '0')}";
                  await _employeeService.paySalary(
                    userId,
                    widget.storeId,
                    netAmountPaid: netPaid,
                    kasbonDeducted: kasbonDeducted,
                    employeeName: name,
                    periodNote: period,
                    monthKey: monthKey,
                    recordAsExpense: recordAsExpense,
                  );
                  if (context.mounted) {
                    context.read<AnalyticsController>().refreshData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Berhasil membayar gaji $name dan dicatat ke Pengeluaran!"),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                  _loadEmployees();
                } catch (e) {
                  debugPrint("Error paying salary: $e");
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
                    );
                  }
                  setState(() => _isLoading = false);
                }
              },
              secondaryActionLabel: "Batal",
              onSecondaryAction: () => Navigator.pop(ctx),
            );
          },
        );
      },
    );
  }

  /// Kelola Absensi Karyawan Langsung (Clock In / Clock Out / Izin)
  void _showAttendanceDialog(Map<String, dynamic> emp, bool isDark) async {
    final userId = emp['id'] as String;
    final name = emp['fullName'] ?? 'Karyawan';
    final todayStatus = emp['todayStatus'] as String? ?? 'Belum Absen';
    final todayLogId = emp['todayLogId'] as String?;

    // Load full logs
    final logs = await _employeeService.getAttendanceLogsForEmployee(userId);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) {
        return KasirDialog(
          title: "Absensi $name",
          icon: Icons.access_time_rounded,
          iconColor: const Color(0xFF10B981),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Status Hari Ini:", style: GoogleFonts.openSans(fontSize: 12, fontWeight: FontWeight.w600)),
                      Text(todayStatus, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF10B981))),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                Text("Aksi Cepat Absensi:", style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),

                Row(
                  children: [
                    if (todayStatus == 'Belum Absen') ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
                          icon: const Icon(Icons.login_rounded, size: 16),
                          label: const Text("Clock In"),
                          onPressed: () async {
                            Navigator.pop(ctx);
                            await _employeeService.clockInForEmployee(userId, widget.storeId);
                            _loadEmployees();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.event_busy_rounded, size: 16, color: Colors.orange),
                          label: const Text("Izin / Sakit", style: TextStyle(color: Colors.orange)),
                          onPressed: () async {
                            Navigator.pop(ctx);
                            await _employeeService.markAbsenceForEmployee(userId, widget.storeId);
                            _loadEmployees();
                          },
                        ),
                      ),
                    ] else if (todayStatus == 'Sedang Bekerja' && todayLogId != null) ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white),
                          icon: const Icon(Icons.logout_rounded, size: 16),
                          label: const Text("Clock Out"),
                          onPressed: () async {
                            Navigator.pop(ctx);
                            await _employeeService.clockOutForEmployee(todayLogId);
                            _loadEmployees();
                          },
                        ),
                      ),
                    ] else ...[
                      const Text("Karyawan sudah menyelesaikan shift hari ini.", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ],
                ),
                const SizedBox(height: 16),

                Text("Log Absensi Terakhir:", style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Container(
                  constraints: const BoxConstraints(maxHeight: 150),
                  decoration: BoxDecoration(
                    border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: logs.isEmpty
                      ? const Center(child: Padding(padding: EdgeInsets.all(12), child: Text("Belum ada riwayat absensi", style: TextStyle(fontSize: 11, color: Colors.grey))))
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: logs.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final log = logs[i];
                            final inTime = log['clockIn'] != null ? DateFormat('dd/MM HH:mm').format(DateTime.tryParse(log['clockIn'].toString()) ?? DateTime.now()) : '-';
                            final outTime = log['clockOut'] != null ? DateFormat('HH:mm').format(DateTime.tryParse(log['clockOut'].toString()) ?? DateTime.now()) : 'Aktif';
                            final st = log['status'] ?? '';

                            return ListTile(
                              dense: true,
                              title: Text("$inTime - $outTime", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              subtitle: Text("Status: $st • ${log['notes'] ?? ''}", style: const TextStyle(fontSize: 10)),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          primaryActionLabel: "Tutup",
          onPrimaryAction: () => Navigator.pop(ctx),
        );
      },
    );
  }

  /// Atur Sistem Gaji (Per Shift atau Bulanan)
  void _showSalaryConfigDialog(Map<String, dynamic> emp, bool isDark) {
    final userId = emp['id'] as String;
    final name = emp['fullName'] ?? 'Karyawan';
    final currentSalaryType = emp['salaryType'] as String? ?? 'shift';
    final ratePerShift = emp['ratePerShift'] as double? ?? 75000.0;
    final monthlySalary = emp['monthlySalary'] as double? ?? 2000000.0;

    String selectedType = currentSalaryType;
    final rateController = TextEditingController(text: ratePerShift.toInt().toString());
    final monthlyController = TextEditingController(text: monthlySalary.toInt().toString());

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return KasirDialog(
              title: "Atur Gaji $name",
              icon: Icons.tune_rounded,
              iconColor: const Color(0xFF2563EB),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Tipe Gaji:", style: GoogleFonts.openSans(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text("Per Shift"),
                          selected: selectedType == 'shift',
                          onSelected: (val) => setModalState(() => selectedType = 'shift'),
                          selectedColor: const Color(0xFF2563EB),
                          labelStyle: TextStyle(color: selectedType == 'shift' ? Colors.white : null),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text("Bulanan Tetap"),
                          selected: selectedType == 'monthly',
                          onSelected: (val) => setModalState(() => selectedType = 'monthly'),
                          selectedColor: const Color(0xFF2563EB),
                          labelStyle: TextStyle(color: selectedType == 'monthly' ? Colors.white : null),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  if (selectedType == 'shift') ...[
                    Text("Nominal per Shift (Rp)", style: GoogleFonts.openSans(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: rateController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        prefixText: "Rp ",
                        hintText: "75000",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ] else ...[
                    Text("Gaji Pokok Bulanan (Rp)", style: GoogleFonts.openSans(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: monthlyController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        prefixText: "Rp ",
                        hintText: "2000000",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ],
                ],
              ),
              primaryActionLabel: "Simpan Pengaturan",
              onPrimaryAction: () async {
                final rate = double.tryParse(rateController.text.trim()) ?? ratePerShift;
                final monthly = double.tryParse(monthlyController.text.trim()) ?? monthlySalary;

                Navigator.pop(ctx);
                setState(() => _isLoading = true);

                try {
                  await _employeeService.updateSalarySettings(
                    userId,
                    salaryType: selectedType,
                    ratePerShift: rate,
                    monthlySalary: monthly,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Pengaturan gaji $name berhasil disimpan!"), backgroundColor: Colors.green),
                    );
                  }
                  _loadEmployees();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
                  }
                  setState(() => _isLoading = false);
                }
              },
              secondaryActionLabel: "Batal",
              onSecondaryAction: () => Navigator.pop(ctx),
            );
          },
        );
      },
    );
  }

  /// Tambah Karyawan Baru (Akun login kasir bersifat opsional)
  void _showAddEmployeeDialog(BuildContext context, bool isDark) {
    final nameController = TextEditingController();
    final roleTitleController = TextEditingController(text: "Staff");
    final salaryController = TextEditingController(text: "2000000");
    final kasbonController = TextEditingController(text: "0");
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    bool createLoginAccount = false;

    final presetRoles = ["Kasir", "Koki", "Pelayan", "Barista", "Staff"];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return KasirDialog(
              title: "Tambah Karyawan Baru",
              icon: Icons.person_add_rounded,
              iconColor: primaryColor,
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: "Nama Lengkap Karyawan *",
                        hintText: "Contoh: Budi Santoso",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Role / Jabatan
                    Text("Jabatan / Peran:", style: GoogleFonts.openSans(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: presetRoles.map((r) {
                        final isSelected = roleTitleController.text == r;
                        return ChoiceChip(
                          label: Text(r),
                          selected: isSelected,
                          onSelected: (val) {
                            if (val) {
                              setModalState(() {
                                roleTitleController.text = r;
                                if (r == "Kasir") createLoginAccount = true;
                              });
                            }
                          },
                          selectedColor: primaryColor,
                          labelStyle: TextStyle(
                            fontSize: 11,
                            color: isSelected ? Colors.white : null,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: roleTitleController,
                      decoration: InputDecoration(
                        labelText: "Nama Jabatan / Posisi",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Gaji Per Bulan & Kasbon Awal
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: salaryController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: "Gaji Per Bulan (Rp)",
                              prefixText: "Rp ",
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: kasbonController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: "Kasbon Awal (Rp)",
                              prefixText: "Rp ",
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Toggle: Buatkan Akun Login Kasir?
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: createLoginAccount
                            ? const Color(0xFF2563EB).withValues(alpha: 0.08)
                            : (isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: createLoginAccount
                              ? const Color(0xFF2563EB).withValues(alpha: 0.3)
                              : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Buatkan Akun Login Kasir?",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                                Text(
                                  "Aktifkan hanya jika karyawan butuh login kasir",
                                  style: GoogleFonts.openSans(
                                    fontSize: 10.5,
                                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: createLoginAccount,
                            activeThumbColor: const Color(0xFF2563EB),
                            onChanged: (val) => setModalState(() => createLoginAccount = val),
                          ),
                        ],
                      ),
                    ),

                    if (createLoginAccount) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: emailController,
                        decoration: InputDecoration(
                          labelText: "Email / Username Login *",
                          hintText: "budi@kasir.com",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: "Password / PIN Login *",
                          hintText: "Minimal 4 karakter",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              primaryActionLabel: "Simpan Karyawan",
              onPrimaryAction: () async {
                final name = nameController.text.trim();
                final roleTitle = roleTitleController.text.trim().isNotEmpty
                    ? roleTitleController.text.trim()
                    : "Staff";
                final salary = double.tryParse(salaryController.text.trim()) ?? 2000000.0;
                final kasbon = double.tryParse(kasbonController.text.trim()) ?? 0.0;
                final email = emailController.text.trim();
                final pass = passwordController.text.trim();

                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Nama karyawan wajib diisi!"), backgroundColor: Colors.red),
                  );
                  return;
                }

                if (createLoginAccount && (email.isEmpty || pass.isEmpty)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Email dan password akun kasir wajib diisi!"), backgroundColor: Colors.red),
                  );
                  return;
                }

                Navigator.pop(ctx);
                setState(() => _isLoading = true);

                try {
                  await _employeeService.createEmployeeRecord(
                    fullName: name,
                    storeId: widget.storeId,
                    roleTitle: roleTitle,
                    email: createLoginAccount ? email : null,
                    password: createLoginAccount ? pass : null,
                    salaryType: 'monthly',
                    monthlySalary: salary,
                    initialKasbon: kasbon,
                  );

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Karyawan $name berhasil didaftarkan!"), backgroundColor: Colors.green),
                    );
                  }
                  _loadEmployees();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
                  }
                  setState(() => _isLoading = false);
                }
              },
              secondaryActionLabel: "Batal",
              onSecondaryAction: () => Navigator.pop(ctx),
            );
          },
        );
      },
    );
  }

  void _confirmDeleteEmployee(Map<String, dynamic> emp) {
    final userId = emp['id'] as String;
    final name = emp['fullName'] ?? 'Karyawan';
    final role = emp['role'] as String?;

    if (role == 'admin' || role == 'owner') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Akun Admin Utama tidak dapat dihapus di sini."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => KasirDialog(
        title: "Hapus Karyawan?",
        message: "Apakah Anda yakin ingin menghapus $name dari daftar karyawan toko?",
        icon: Icons.delete_outline_rounded,
        iconColor: Colors.redAccent,
        isDestructive: true,
        primaryActionLabel: "Hapus",
        onPrimaryAction: () async {
          Navigator.pop(ctx);
          setState(() => _isLoading = true);
          try {
            await _employeeService.removeEmployee(userId);
            _loadEmployees();
          } catch (e) {
            setState(() => _isLoading = false);
          }
        },
        secondaryActionLabel: "Batal",
        onSecondaryAction: () => Navigator.pop(ctx),
      ),
    );
  }

  // ─── SALARY CHECKLIST & HISTORY COMPONENTS ─────────────────────────────────

  /// Ceklis status bar di kartu karyawan (hanya muncul setelah gaji dibayar)
  Widget _buildSalaryChecklistBar(
    Map<String, dynamic> emp,
    String monthName,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF10B981).withValues(alpha: 0.35),
          width: 1.1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => _toggleSalaryChecklist(emp, isDark),
              borderRadius: BorderRadius.circular(6),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                "Gaji Sudah Lunas",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF059669),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                "Diceklis",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF059669),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Periode $monthName • Ketuk untuk kelola",
                          style: GoogleFonts.openSans(
                            fontSize: 10.5,
                            color: isDark ? Colors.white54 : const Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => _showEmployeeSalaryHistoryDialog(emp, isDark),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.history_rounded,
                    size: 14,
                    color: Color(0xFF059669),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "Riwayat",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF059669),
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

  /// Toggle or manage checklist status
  void _toggleSalaryChecklist(Map<String, dynamic> emp, bool isDark) {
    final userId = emp['id'] as String;
    final name = emp['fullName'] ?? 'Karyawan';
    final isSalaryPaid = emp['isSalaryPaid'] as bool? ?? false;
    final netSalary = emp['netSalary'] as double? ?? 0.0;
    final monthName = DateFormat('MMMM yyyy', 'id').format(_selectedMonth);
    final monthKey = "${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2, '0')}";

    if (!isSalaryPaid) {
      // Prompt to pay or quick check
      showDialog(
        context: context,
        builder: (ctx) => KasirDialog(
          title: "Ceklis Pembayaran Gaji?",
          message: "Tandai gaji $name untuk periode $monthName (${_currencyFormat.format(netSalary)}) sebagai sudah dibayar?",
          icon: Icons.check_circle_outline_rounded,
          iconColor: const Color(0xFF10B981),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: primaryColor.withValues(alpha: 0.3)),
                ),
                tileColor: primaryColor.withValues(alpha: 0.06),
                leading: const Icon(Icons.payments_rounded, color: primaryColor),
                title: Text(
                  "Bayar & Catat ke Pengeluaran",
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                subtitle: Text(
                  "Otomatis masuk ke laporan pengeluaran toko & memotong laba rugi",
                  style: GoogleFonts.openSans(fontSize: 11),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _showPaySalaryDialog(emp, isDark);
                },
              ),
              const SizedBox(height: 10),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                ),
                tileColor: isDark ? Colors.white10 : const Color(0xFFF8FAFC),
                leading: const Icon(Icons.check_box_outlined, color: Color(0xFF10B981)),
                title: Text(
                  "Tandai Ceklis Saja (Lunas)",
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                subtitle: Text(
                  "Sudah dibayar tunai/transfer di luar aplikasi (tidak mencatat ke pengeluaran lagi)",
                  style: GoogleFonts.openSans(fontSize: 11),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  setState(() => _isLoading = true);
                  await _employeeService.setSalaryPaidStatus(
                    userId,
                    widget.storeId,
                    monthKey: monthKey,
                    isPaid: true,
                    employeeName: name,
                    netSalary: netSalary,
                    periodNote: "Gaji $monthName",
                    recordAsExpense: false,
                  );
                  _loadEmployees();
                },
              ),
            ],
          ),
          secondaryActionLabel: "Tutup",
          onSecondaryAction: () => Navigator.pop(ctx),
        ),
      );
    } else {
      // Already paid: offer to cancel checklist or see details
      showDialog(
        context: context,
        builder: (ctx) => KasirDialog(
          title: "Status Gaji: Sudah Dibayar",
          message: "Gaji $name periode $monthName saat ini berstatus SUDAH DIBAYAR (Diceklis).",
          icon: Icons.check_circle_rounded,
          iconColor: const Color(0xFF10B981),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                tileColor: const Color(0xFF2563EB).withValues(alpha: 0.08),
                leading: const Icon(Icons.receipt_long_rounded, color: Color(0xFF2563EB)),
                title: Text(
                  "Lihat Riwayat & Bukti Pembayaran",
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                subtitle: Text("Cek detail tanggal, nominal, dan slip gaji", style: GoogleFonts.openSans(fontSize: 11)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showEmployeeSalaryHistoryDialog(emp, isDark);
                },
              ),
              const SizedBox(height: 10),
              ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                tileColor: Colors.redAccent.withValues(alpha: 0.08),
                leading: const Icon(Icons.remove_circle_outline_rounded, color: Colors.redAccent),
                title: Text(
                  "Batalkan Ceklis (Tandai Belum Dibayar)",
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.redAccent),
                ),
                subtitle: Text("Kembalikan status gaji karyawan ini menjadi belum lunas", style: GoogleFonts.openSans(fontSize: 11)),
                onTap: () async {
                  Navigator.pop(ctx);
                  setState(() => _isLoading = true);
                  await _employeeService.setSalaryPaidStatus(
                    userId,
                    widget.storeId,
                    monthKey: monthKey,
                    isPaid: false,
                  );
                  _loadEmployees();
                },
              ),
            ],
          ),
          secondaryActionLabel: "Tutup",
          onSecondaryAction: () => Navigator.pop(ctx),
        ),
      );
    }
  }

  /// Dialog riwayat seluruh pembayaran gaji di toko
  void _showAllSalaryHistoryDialog(bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) {
        bool filterThisMonth = false;
        return StatefulBuilder(
          builder: (context, setModalState) {
            final monthName = DateFormat('MMMM yyyy', 'id').format(_selectedMonth);
            return Dialog(
              backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              insetPadding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620, maxHeight: 680),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF2563EB), size: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Riwayat Bayar Gaji",
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        "Bukti dan pencatatan penggajian karyawan",
                                        style: GoogleFonts.openSans(
                                          fontSize: 11.5,
                                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 20),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Filter chips
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilterChip(
                            label: const Text("Semua Riwayat"),
                            selected: !filterThisMonth,
                            onSelected: (val) => setModalState(() => filterThisMonth = false),
                            selectedColor: const Color(0xFF2563EB).withValues(alpha: 0.15),
                            checkmarkColor: const Color(0xFF2563EB),
                            labelStyle: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: !filterThisMonth ? FontWeight.bold : FontWeight.w500,
                              color: !filterThisMonth ? const Color(0xFF2563EB) : (isDark ? Colors.white70 : Colors.black87),
                            ),
                          ),
                          FilterChip(
                            label: Text("Periode: $monthName"),
                            selected: filterThisMonth,
                            onSelected: (val) => setModalState(() => filterThisMonth = true),
                            selectedColor: const Color(0xFF2563EB).withValues(alpha: 0.15),
                            checkmarkColor: const Color(0xFF2563EB),
                            labelStyle: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: filterThisMonth ? FontWeight.bold : FontWeight.w500,
                              color: filterThisMonth ? const Color(0xFF2563EB) : (isDark ? Colors.white70 : Colors.black87),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),

                      // List data
                      Expanded(
                        child: FutureBuilder<List<Map<String, dynamic>>>(
                          future: _employeeService.getStoreSalaryHistory(
                            widget.storeId,
                            month: filterThisMonth ? _selectedMonth : null,
                          ),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CupertinoActivityIndicator());
                            }
                            final list = snapshot.data ?? [];
                            if (list.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.receipt_outlined,
                                      size: 48,
                                      color: isDark ? Colors.white24 : Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      "Belum Ada Riwayat Pembayaran Gaji",
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white70 : const Color(0xFF334155),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      filterThisMonth
                                          ? "Belum ada gaji yang dibayarkan pada periode $monthName."
                                          : "Pembayaran gaji yang dicatat akan muncul di sini.",
                                      style: GoogleFonts.openSans(
                                        fontSize: 12,
                                        color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              );
                            }

                            final totalPaid = list.fold<double>(
                              0.0,
                              (sum, item) => sum + ((item['amount'] as num?)?.toDouble() ?? 0.0),
                            );

                            return Column(
                              children: [
                                // Total banner
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFF10B981).withValues(alpha: 0.25),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Total Gaji Terbayar (${list.length}x):",
                                        style: GoogleFonts.openSans(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? Colors.white70 : const Color(0xFF334155),
                                        ),
                                      ),
                                      Text(
                                        _currencyFormat.format(totalPaid),
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF059669),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Scrollable list
                                Expanded(
                                  child: ListView.separated(
                                    itemCount: list.length,
                                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                                    itemBuilder: (context, index) {
                                      final item = list[index];
                                      final date = item['date'] is DateTime
                                          ? item['date'] as DateTime
                                          : (DateTime.tryParse(item['date'].toString()) ?? DateTime.now());
                                      final dateStr = DateFormat('dd MMM yyyy, HH:mm', 'id').format(date);
                                      final empName = item['employeeName'] ?? 'Karyawan';
                                      final amount = (item['amount'] as num?)?.toDouble() ?? 0.0;
                                      final kasbonDeducted = (item['kasbonDeducted'] as num?)?.toDouble() ?? 0.0;
                                      final notes = item['notes'] ?? '';
                                      final isSynced = item['isSyncedToExpense'] as bool? ?? false;

                                      return Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFF262626) : const Color(0xFFF8FAFC),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: isDark ? const Color(0xFF374151) : const Color(0xFFE2E8F0),
                                          ),
                                        ),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            CircleAvatar(
                                              radius: 18,
                                              backgroundColor: primaryColor.withValues(alpha: 0.12),
                                              child: Text(
                                                empName.isNotEmpty ? empName[0].toUpperCase() : 'K',
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontWeight: FontWeight.bold,
                                                  color: primaryColor,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                    Expanded(
                                                      child: Text(
                                                        empName,
                                                        style: GoogleFonts.plusJakartaSans(
                                                          fontSize: 13.5,
                                                          fontWeight: FontWeight.w700,
                                                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                      Text(
                                                        _currencyFormat.format(amount),
                                                        style: GoogleFonts.plusJakartaSans(
                                                          fontSize: 14,
                                                          fontWeight: FontWeight.w800,
                                                          color: primaryColor,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    dateStr,
                                                    style: GoogleFonts.openSans(
                                                      fontSize: 11,
                                                      color: isDark ? Colors.white54 : const Color(0xFF64748B),
                                                    ),
                                                  ),
                                                  if (kasbonDeducted > 0) ...[
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      "Potongan Kasbon: ${_currencyFormat.format(kasbonDeducted)}",
                                                      style: GoogleFonts.openSans(
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.w600,
                                                        color: Colors.amber.shade800,
                                                      ),
                                                    ),
                                                  ],
                                                  if (notes.isNotEmpty) ...[
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      notes,
                                                      style: GoogleFonts.openSans(
                                                        fontSize: 11,
                                                        color: isDark ? Colors.white60 : const Color(0xFF475569),
                                                      ),
                                                    ),
                                                  ],
                                                  const SizedBox(height: 6),
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                        decoration: BoxDecoration(
                                                          color: isSynced
                                                              ? const Color(0xFF10B981).withValues(alpha: 0.12)
                                                              : Colors.grey.withValues(alpha: 0.12),
                                                          borderRadius: BorderRadius.circular(4),
                                                        ),
                                                        child: Text(
                                                          isSynced ? "✓ Masuk Pengeluaran Toko" : "Ceklis Mandiri",
                                                          style: GoogleFonts.plusJakartaSans(
                                                            fontSize: 9.5,
                                                            fontWeight: FontWeight.bold,
                                                            color: isSynced ? const Color(0xFF10B981) : Colors.grey,
                                                          ),
                                                        ),
                                                      ),
                                                      InkWell(
                                                        onTap: () {
                                                          _confirmCancelSalaryPayment(
                                                            item,
                                                            isDark,
                                                            onDeleted: () {
                                                              setModalState(() {});
                                                              _loadEmployees();
                                                              context.read<AnalyticsController>().refreshData();
                                                            },
                                                          );
                                                        },
                                                        child: Padding(
                                                          padding: const EdgeInsets.all(4),
                                                          child: Row(
                                                            mainAxisSize: MainAxisSize.min,
                                                            children: [
                                                              const Icon(Icons.delete_outline, size: 14, color: Colors.redAccent),
                                                              const SizedBox(width: 4),
                                                              Text(
                                                                "Batalkan",
                                                                style: GoogleFonts.openSans(
                                                                  fontSize: 11,
                                                                  color: Colors.redAccent,
                                                                  fontWeight: FontWeight.w600,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Dialog riwayat gaji untuk 1 karyawan tertentu
  void _showEmployeeSalaryHistoryDialog(Map<String, dynamic> emp, bool isDark) {
    final userId = emp['id'] as String;
    final name = emp['fullName'] ?? 'Karyawan';
    final rawHistory = emp['salaryHistory'] is List ? emp['salaryHistory'] as List : [];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Dialog(
            backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            insetPadding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540, maxHeight: 600),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.badge_outlined, color: primaryColor, size: 20),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Riwayat Gaji: $name",
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      "Catatan slip gaji terbayar",
                                      style: GoogleFonts.openSans(
                                        fontSize: 11.5,
                                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const Divider(height: 20),

                    if (rawHistory.isEmpty)
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.history_toggle_off_rounded, size: 44, color: isDark ? Colors.white24 : Colors.grey.shade400),
                              const SizedBox(height: 10),
                              Text(
                                "Belum Ada Catatan Gaji",
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white70 : const Color(0xFF334155),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Pembayaran gaji karyawan $name akan terekam di sini.",
                                style: GoogleFonts.openSans(fontSize: 11.5, color: isDark ? Colors.white38 : const Color(0xFF94A3B8)),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.separated(
                          itemCount: rawHistory.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final item = rawHistory[index] is Map ? rawHistory[index] as Map : {};
                            final amount = (item['netAmountPaid'] as num?)?.toDouble() ?? 0.0;
                            final kasbonDeducted = (item['kasbonDeducted'] as num?)?.toDouble() ?? 0.0;
                            final periodNote = item['periodNote'] ?? item['notes'] ?? 'Gaji';
                            final dateStr = item['date'] != null
                                ? DateFormat('dd MMM yyyy, HH:mm', 'id').format(
                                    DateTime.tryParse(item['date'].toString()) ?? DateTime.now(),
                                  )
                                : '';

                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF262626) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF374151) : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          periodNote,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _currencyFormat.format(amount),
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w800,
                                          color: primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    dateStr,
                                    style: GoogleFonts.openSans(
                                      fontSize: 11,
                                      color: isDark ? Colors.white54 : const Color(0xFF64748B),
                                    ),
                                  ),
                                  if (kasbonDeducted > 0) ...[
                                    const SizedBox(height: 3),
                                    Text(
                                      "Potongan Kasbon: ${_currencyFormat.format(kasbonDeducted)}",
                                      style: GoogleFonts.openSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.amber.shade800,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          "✓ Lunas Terbayar",
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF10B981),
                                          ),
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () {
                                          _confirmCancelSalaryPayment(
                                            {
                                              'userId': userId,
                                              'expenseId': item['expenseId'],
                                              'id': item['id'],
                                              'monthKey': item['monthKey'],
                                              'kasbonDeducted': kasbonDeducted,
                                              'employeeName': name,
                                            },
                                            isDark,
                                            onDeleted: () {
                                              Navigator.pop(ctx);
                                              _loadEmployees();
                                              context.read<AnalyticsController>().refreshData();
                                            },
                                          );
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.all(4),
                                          child: Text(
                                            "Hapus Catatan",
                                            style: GoogleFonts.openSans(
                                              fontSize: 11,
                                              color: Colors.redAccent,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Konfirmasi pembatalan/penghapusan pembayaran gaji
  void _confirmCancelSalaryPayment(
    Map<String, dynamic> item,
    bool isDark, {
    required VoidCallback onDeleted,
  }) {
    final empName = item['employeeName'] ?? 'Karyawan';
    final expenseId = item['expenseId'] as String?;
    final paymentId = item['id'] as String?;
    final userId = item['userId'] as String?;
    final monthKey = item['monthKey'] as String?;
    final kasbonDeducted = (item['kasbonDeducted'] as num?)?.toDouble() ?? 0.0;

    showDialog(
      context: context,
      builder: (ctx) => KasirDialog(
        title: "Batalkan Pembayaran Gaji?",
        message: "Yakin ingin membatalkan pembayaran gaji $empName? Data pengeluaran toko dan potongan kasbon akan dikembalikan.",
        icon: Icons.delete_outline_rounded,
        iconColor: Colors.redAccent,
        isDestructive: true,
        primaryActionLabel: "Batalkan Pembayaran",
        onPrimaryAction: () async {
          Navigator.pop(ctx);
          setState(() => _isLoading = true);
          try {
            await _employeeService.cancelSalaryPayment(
              widget.storeId,
              userId: userId,
              expenseId: expenseId,
              paymentId: paymentId,
              monthKey: monthKey,
              kasbonToRestore: kasbonDeducted,
            );
            onDeleted();
          } catch (e) {
            debugPrint("Error canceling salary payment: $e");
            setState(() => _isLoading = false);
          }
        },
        secondaryActionLabel: "Kembali",
        onSecondaryAction: () => Navigator.pop(ctx),
      ),
    );
  }
}
