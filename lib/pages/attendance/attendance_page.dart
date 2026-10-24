import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../services/app_database.dart';
import '../../services/employee_service.dart';
import '../../controllers/admin_controller.dart';
import '../../widgets/kasir_dialog.dart';
import '../../widgets/kasir_drawer.dart';
import '../admin/employee/employee_management_page.dart';

class AttendancePage extends StatefulWidget {
  final bool showSidebar;
  final VoidCallback? onMenuPressed;
  final VoidCallback? onBack;

  const AttendancePage({
    super.key,
    this.showSidebar = true,
    this.onMenuPressed,
    this.onBack,
  });

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  static const primaryColor = Color(0xFFC0392B);
  late EmployeeService _employeeService;

  String? _storeId;
  List<Map<String, dynamic>> _employees = [];
  bool _isLoading = true;
  String _searchQuery = '';

  Timer? _timer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _startClock();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final db = context.read<AppDatabase>();
      _employeeService = EmployeeService(db);
      _loadData();
    });
  }

  void _startClock() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _currentTime = DateTime.now());
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final admin = context.read<AdminController>();
      _storeId = admin.storeId;

      if (_storeId == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final empList = await _employeeService.getEmployeesWithStats(_storeId!);

      if (mounted) {
        setState(() {
          _employees = empList;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading attendance data: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredEmployees {
    if (_searchQuery.trim().isEmpty) return _employees;
    final query = _searchQuery.trim().toLowerCase();
    return _employees.where((e) {
      final name = (e['fullName'] ?? e['name'] ?? '').toString().toLowerCase();
      final role = (e['roleTitle'] ?? e['role'] ?? '').toString().toLowerCase();
      return name.contains(query) || role.contains(query);
    }).toList();
  }

  Future<void> _markHadir(Map<String, dynamic> emp) async {
    final empId = emp['id'] as String;
    final name = emp['fullName'] ?? emp['name'] ?? 'Karyawan';
    if (_storeId == null) return;

    setState(() => _isLoading = true);
    try {
      await _employeeService.deleteTodayAttendance(empId, _storeId!);
      await _employeeService.clockInForEmployee(empId, _storeId!, notes: 'Hadir');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✓ $name berhasil diabsen Hadir!"),
            backgroundColor: const Color(0xFF10B981),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      await _loadData();
    } catch (e) {
      debugPrint("Error marking attendance: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal mencatat absensi: $e"), backgroundColor: Colors.red),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _showIzinDialog(Map<String, dynamic> emp, bool isDark) {
    final empId = emp['id'] as String;
    final name = emp['fullName'] ?? emp['name'] ?? 'Karyawan';
    final reasonController = TextEditingController(text: "Izin");

    showDialog(
      context: context,
      builder: (ctx) => KasirDialog(
        title: "Catat Izin / Tidak Hadir",
        icon: Icons.event_busy_rounded,
        iconColor: Colors.orange.shade800,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Catat keterangan tidak hadir untuk $name:",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: isDark ? Colors.white70 : const Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                hintText: "Contoh: Sakit, Izin Keperluan Keluarga, dll.",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ],
        ),
        primaryActionLabel: "Simpan Izin",
        onPrimaryAction: () async {
          final reason = reasonController.text.trim().isNotEmpty
              ? reasonController.text.trim()
              : "Izin / Tidak Hadir";
          Navigator.pop(ctx);
          if (_storeId == null) return;

          setState(() => _isLoading = true);
          try {
            await _employeeService.deleteTodayAttendance(empId, _storeId!);
            await _employeeService.markAbsenceForEmployee(empId, _storeId!, reason: reason);

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("$name dicatat Izin / Tidak Hadir ($reason)"),
                  backgroundColor: Colors.orange.shade800,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
            await _loadData();
          } catch (e) {
            debugPrint("Error marking absence: $e");
            if (mounted) setState(() => _isLoading = false);
          }
        },
        secondaryActionLabel: "Batal",
        onSecondaryAction: () => Navigator.pop(ctx),
      ),
    );
  }

  void _showChangeOrResetDialog(Map<String, dynamic> emp, bool isDark) {
    final empId = emp['id'] as String;
    final name = emp['fullName'] ?? emp['name'] ?? 'Karyawan';
    final todayStatus = emp['todayStatus'] ?? 'Belum Absen';

    showDialog(
      context: context,
      builder: (ctx) => KasirDialog(
        title: "Ubah Status Presensi $name",
        message: "Status saat ini: $todayStatus. Pilih aksi yang ingin dilakukan:",
        icon: Icons.edit_calendar_rounded,
        iconColor: primaryColor,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (todayStatus != 'Hadir') ...[
              ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                tileColor: const Color(0xFF10B981).withValues(alpha: 0.1),
                leading: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981)),
                title: Text(
                  "Ubah Menjadi Hadir",
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _markHadir(emp);
                },
              ),
              const SizedBox(height: 8),
            ],
            if (todayStatus != 'Izin / Tidak Hadir') ...[
              ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                tileColor: Colors.orange.withValues(alpha: 0.1),
                leading: const Icon(Icons.event_busy_rounded, color: Colors.orangeAccent),
                title: Text(
                  "Ubah Menjadi Izin / Sakit",
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _showIzinDialog(emp, isDark);
                },
              ),
              const SizedBox(height: 8),
            ],
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              tileColor: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
              leading: const Icon(Icons.restart_alt_rounded, color: Colors.grey),
              title: Text(
                "Reset (Tandai Belum Absen)",
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              subtitle: Text(
                "Hapus catatan absensi hari ini",
                style: GoogleFonts.openSans(fontSize: 11),
              ),
              onTap: () async {
                Navigator.pop(ctx);
                if (_storeId == null) return;
                setState(() => _isLoading = true);
                try {
                  await _employeeService.deleteTodayAttendance(empId, _storeId!);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Absensi $name berhasil direset!"), backgroundColor: Colors.grey.shade700),
                    );
                  }
                  await _loadData();
                } catch (e) {
                  debugPrint("Error resetting attendance: $e");
                  if (mounted) setState(() => _isLoading = false);
                }
              },
            ),
          ],
        ),
        secondaryActionLabel: "Tutup",
        onSecondaryAction: () => Navigator.pop(ctx),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF374151) : const Color(0xFFE2E8F0);

    // KPI Counts
    final totalEmployees = _employees.length;
    final totalHadir = _employees.where((e) => e['todayStatus'] == 'Hadir').length;
    final totalIzin = _employees.where((e) => e['todayStatus'] == 'Izin / Tidak Hadir').length;
    final totalBelumAbsen = (totalEmployees - totalHadir - totalIzin).clamp(0, totalEmployees);

    final formattedDate = DateFormat('EEEE, d MMMM yyyy', 'id').format(_currentTime);
    final formattedTime = DateFormat('HH:mm:ss').format(_currentTime);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
      drawer: widget.showSidebar ? const KasirDrawer(currentRoute: '/attendance') : null,
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
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "Presensi & Kehadiran Tim",
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: widget.onBack != null
            ? IconButton(
                icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black87),
                tooltip: "Kembali",
                onPressed: widget.onBack,
              )
            : (Navigator.canPop(context)
                ? IconButton(
                    icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black87),
                    tooltip: "Kembali",
                    onPressed: () => Navigator.pop(context),
                  )
                : (widget.showSidebar ? null : const SizedBox.shrink())),
        actions: [
          IconButton(
            icon: Icon(
              Icons.payments_outlined,
              color: isDark ? Colors.white : primaryColor,
              size: 24,
            ),
            tooltip: "Kelola Pegawai & Gaji",
            onPressed: () {
              final storeId = _storeId ?? context.read<AdminController>().storeId;
              if (storeId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EmployeeManagementPage(storeId: storeId),
                  ),
                ).then((_) => _loadData());
              }
            },
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: borderColor,
            height: 1,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: primaryColor,
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width < 500 ? 12 : 20,
                  vertical: 16,
                ),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 960),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Header: Date, Time & Mode
                        _buildTopHeaderBanner(isDark, borderColor, formattedDate, formattedTime),
                        const SizedBox(height: 16),

                        // 4 KPI Summary Cards (Perhitungan Pegawai Hadir / Tidak Hadir)
                        _buildKpiSummarySection(
                          isDark,
                          totalEmployees,
                          totalHadir,
                          totalBelumAbsen,
                          totalIzin,
                        ),
                        const SizedBox(height: 20),

                        // Section Header & Search Box
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              "Daftar Kehadiran Pegawai (${_filteredEmployees.length})",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              "Tinggal tekan [Hadir] untuk absen",
                              style: GoogleFonts.openSans(
                                fontSize: 12,
                                color: isDark ? Colors.white54 : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Search Field
                        _buildSearchBox(isDark, borderColor),
                        const SizedBox(height: 16),

                        // Employee List / Grid (Jajarkan Pegawai)
                        if (_filteredEmployees.isEmpty)
                          _buildEmptyState(isDark)
                        else
                          _buildEmployeesGrid(isDark, borderColor),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  // ─── TOP HEADER BANNER ─────────────────────────────────────────────────────
  Widget _buildTopHeaderBanner(
    bool isDark,
    Color borderColor,
    String formattedDate,
    String formattedTime,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 620;

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 14 : 18,
            vertical: isCompact ? 12 : 14,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: isCompact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.today_rounded, color: primaryColor, size: 22),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                formattedDate,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Pukul: $formattedTime WIB",
                                style: GoogleFonts.openSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildQuickBadge(),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.groups_rounded,
                            size: 14,
                            color: isDark ? Colors.white60 : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              "1 Akun untuk Semua Tim • Tap langsung Hadir",
                              style: GoogleFonts.openSans(
                                fontSize: 11,
                                color: isDark ? Colors.white60 : const Color(0xFF64748B),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.today_rounded, color: primaryColor, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  formattedDate,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "Pukul: $formattedTime WIB • 1 Akun untuk Semua Tim",
                                  style: GoogleFonts.openSans(
                                    fontSize: 12,
                                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildQuickBadge(),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildQuickBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bolt_rounded, size: 15, color: Color(0xFF10B981)),
          const SizedBox(width: 4),
          Text(
            "Absensi Cepat",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF059669),
            ),
          ),
        ],
      ),
    );
  }

  // ─── 4 KPI SUMMARY CARDS (PERHITUNGAN HADIR & TIDAK HADIR) ─────────────────
  Widget _buildKpiSummarySection(
    bool isDark,
    int totalEmployees,
    int totalHadir,
    int totalBelumAbsen,
    int totalIzin,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 650;
        final kpiTotal = _buildKpiCard(
          "Total Pegawai",
          "$totalEmployees Orang",
          Icons.people_alt_outlined,
          const Color(0xFF2563EB),
          isDark,
        );
        final kpiHadir = _buildKpiCard(
          "Hadir Hari Ini",
          "$totalHadir Orang",
          Icons.check_circle_outline_rounded,
          const Color(0xFF10B981),
          isDark,
        );
        final kpiBelum = _buildKpiCard(
          "Belum Absen",
          "$totalBelumAbsen Orang",
          Icons.schedule_outlined,
          totalBelumAbsen > 0 ? const Color(0xFFEF4444) : Colors.grey,
          isDark,
        );
        final kpiIzin = _buildKpiCard(
          "Izin / Sakit",
          "$totalIzin Orang",
          Icons.event_busy_outlined,
          const Color(0xFFD97706),
          isDark,
        );

        if (isSmall) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: kpiTotal),
                  const SizedBox(width: 10),
                  Expanded(child: kpiHadir),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: kpiBelum),
                  const SizedBox(width: 10),
                  Expanded(child: kpiIzin),
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: kpiTotal),
            const SizedBox(width: 12),
            Expanded(child: kpiHadir),
            const SizedBox(width: 12),
            Expanded(child: kpiBelum),
            const SizedBox(width: 12),
            Expanded(child: kpiIzin),
          ],
        );
      },
    );
  }

  Widget _buildKpiCard(
    String title,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF374151) : const Color(0xFFE2E8F0),
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
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: color, size: 15),
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
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── SEARCH BOX ────────────────────────────────────────────────────────────
  Widget _buildSearchBox(bool isDark, Color borderColor) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: TextField(
        onChanged: (val) => setState(() => _searchQuery = val),
        style: GoogleFonts.openSans(
          fontSize: 13,
          color: isDark ? Colors.white : Colors.black87,
        ),
        decoration: InputDecoration(
          hintText: "Cari nama pegawai atau jabatan...",
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

  // ─── EMPLOYEES GRID (JAJARKAN PEGAWAI) ────────────────────────────────────
  Widget _buildEmployeesGrid(bool isDark, Color borderColor) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 700 ? 2 : 1;

        if (crossAxisCount == 1) {
          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _filteredEmployees.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final emp = _filteredEmployees[index];
              return _buildEmployeeCard(emp, isDark, borderColor);
            },
          );
        }

        // 2 Columns Grid for wide screen
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _filteredEmployees.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            mainAxisExtent: 175,
          ),
          itemBuilder: (context, index) {
            final emp = _filteredEmployees[index];
            return _buildEmployeeCard(emp, isDark, borderColor);
          },
        );
      },
    );
  }

  // ─── SINGLE EMPLOYEE CARD (MUDAH: TINGGAL PENCET HADIR) ────────────────────
  Widget _buildEmployeeCard(Map<String, dynamic> emp, bool isDark, Color borderColor) {
    // 1. Tampilkan nama asli pegawai secara konsisten
    final name = (emp['fullName'] ?? emp['name'] ?? 'Karyawan').toString();
    final roleTitle = emp['roleTitle'] ?? (emp['role'] == 'cashier' ? 'Kasir' : 'Staff');
    final shiftCount = emp['shiftCount'] as int? ?? 0;
    final todayStatus = (emp['todayStatus'] ?? 'Belum Absen').toString();

    final isHadir = todayStatus == 'Hadir';
    final isIzin = todayStatus == 'Izin / Tidak Hadir';

    Color statusBadgeColor = Colors.grey;
    String statusLabel = "Belum Absen";
    IconData statusIcon = Icons.schedule_rounded;

    if (isHadir) {
      statusBadgeColor = const Color(0xFF10B981);
      statusLabel = "Hadir";
      statusIcon = Icons.check_circle_rounded;
    } else if (isIzin) {
      statusBadgeColor = const Color(0xFFD97706);
      statusLabel = "Izin / Sakit";
      statusIcon = Icons.event_busy_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isHadir
              ? const Color(0xFF10B981).withValues(alpha: 0.5)
              : (isDark ? const Color(0xFF374151) : const Color(0xFFE2E8F0)),
          width: isHadir ? 1.5 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Header: Avatar, Name & Role, Status Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 19,
                backgroundColor: isHadir
                    ? const Color(0xFF10B981).withValues(alpha: 0.15)
                    : primaryColor.withValues(alpha: 0.12),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'K',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    color: isHadir ? const Color(0xFF10B981) : primaryColor,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white10 : const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              roleTitle,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF2563EB),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Kehadiran Bulan Ini: $shiftCount Hari",
                      style: GoogleFonts.openSans(
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
              // Status Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBadgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: statusBadgeColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 12, color: statusBadgeColor),
                    const SizedBox(width: 4),
                    Text(
                      statusLabel,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: statusBadgeColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Action Buttons: Praktis & Mudah (Tinggal Pencet Hadir)
          Row(
            children: [
              // Main button: Hadir
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isHadir
                          ? const Color(0xFF10B981)
                          : const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    onPressed: () {
                      if (!isHadir) {
                        _markHadir(emp);
                      } else {
                        _showChangeOrResetDialog(emp, isDark);
                      }
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isHadir ? Icons.check_circle_rounded : Icons.check_rounded,
                          size: 15,
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            isHadir ? "Sudah Hadir" : "Pencet Hadir",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Secondary button: Izin / Ubah
              SizedBox(
                height: 38,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isIzin ? Colors.orange.shade800 : (isDark ? Colors.white70 : Colors.black87),
                    side: BorderSide(
                      color: isIzin
                          ? Colors.orangeAccent
                          : (isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  onPressed: () {
                    if (!isIzin) {
                      _showIzinDialog(emp, isDark);
                    } else {
                      _showChangeOrResetDialog(emp, isDark);
                    }
                  },
                  child: Text(
                    isIzin ? "Ubah Izin" : "Izin",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                  ),
                ),
              ),
              if (isHadir || isIzin) ...[
                const SizedBox(width: 4),
                IconButton(
                  tooltip: "Reset / Ubah Status",
                  icon: const Icon(Icons.more_vert_rounded, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 38),
                  onPressed: () => _showChangeOrResetDialog(emp, isDark),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF374151) : const Color(0xFFCBD5E1),
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.people_outline_rounded, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            "Belum Ada Karyawan Terdaftar",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Daftarkan pegawai di menu Pengaturan / Kelola Pegawai untuk mulai absensi.",
            style: GoogleFonts.openSans(
              fontSize: 12,
              color: isDark ? Colors.white54 : const Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
