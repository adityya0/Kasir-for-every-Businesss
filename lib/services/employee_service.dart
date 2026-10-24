import 'dart:convert';
import 'app_database.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'platform/file_manager.dart';
import 'package:path/path.dart' as p;

class EmployeeService {
  final AppDatabase db;

  EmployeeService(this.db);

  /// Fetch all employees (cashiers and staff) for a specific store
  Future<List<Map<String, dynamic>>> getEmployees(String storeId) async {
    final results = await (db.select(db.profiles)
          ..where((t) => t.storeId.equals(storeId) & (t.role.equals('cashier') | t.role.equals('staff')))
          ..orderBy([(t) => OrderingTerm.asc(t.fullName)]))
        .get();

    return results.map((e) {
      final map = e.toJson();
      final nameVal = (e.fullName != null && e.fullName!.isNotEmpty) ? e.fullName! : 'Karyawan';
      map['name'] = nameVal;
      map['fullName'] = nameVal;
      if (map['permissions'] != null && map['permissions'] is String) {
        try {
          map['permissions'] = jsonDecode(map['permissions']);
        } catch (_) {
          map['permissions'] = {};
        }
      }
      return map;
    }).toList();
  }

  /// Watch employees for real-time updates
  Stream<List<Map<String, dynamic>>> watchEmployees(String storeId) {
    return (db.select(db.profiles)
          ..where((t) => t.storeId.equals(storeId) & (t.role.equals('cashier') | t.role.equals('staff')))
          ..orderBy([(t) => OrderingTerm.asc(t.fullName)]))
        .watch()
        .map((results) {
          return results.map((e) {
            final map = e.toJson();
            final nameVal = (e.fullName != null && e.fullName!.isNotEmpty) ? e.fullName! : 'Karyawan';
            map['name'] = nameVal;
            map['fullName'] = nameVal;
            if (map['permissions'] != null && map['permissions'] is String) {
              try {
                map['permissions'] = jsonDecode(map['permissions']);
              } catch (_) {
                map['permissions'] = {};
              }
            }
            return map;
          }).toList();
        });
  }

  /// Fetch employees with comprehensive statistics (shifts, absences, salary, kasbon)
  Future<List<Map<String, dynamic>>> getEmployeesWithStats(
    String storeId, {
    DateTime? month,
  }) async {
    final targetMonth = month ?? DateTime.now();
    final startOfMonth = DateTime(targetMonth.year, targetMonth.month, 1);
    final endOfMonth = DateTime(targetMonth.year, targetMonth.month + 1, 0, 23, 59, 59);

    final employees = await getEmployees(storeId);
    final List<Map<String, dynamic>> enrichedList = [];

    // Get today boundaries
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);

    for (final emp in employees) {
      final userId = emp['id'] as String;

      // Fetch logs for this month
      final logsQuery = db.select(db.attendanceLogs)
        ..where(
          (t) =>
              t.userId.equals(userId) &
              t.storeId.equals(storeId) &
              t.clockIn.isBiggerOrEqualValue(startOfMonth) &
              t.clockIn.isSmallerOrEqualValue(endOfMonth),
        );
      final logs = await logsQuery.get();

      int shiftCount = 0;
      int absentCount = 0;
      for (final log in logs) {
        if (log.status == 'absent') {
          absentCount++;
        } else if (log.clockIn != null) {
          shiftCount++;
        }
      }

      // Check today's status
      final todayLog = await (db.select(db.attendanceLogs)
            ..where(
              (t) =>
                  t.userId.equals(userId) &
                  t.storeId.equals(storeId) &
                  t.clockIn.isBiggerOrEqualValue(startOfToday) &
                  t.clockIn.isSmallerOrEqualValue(endOfToday),
            )
            ..limit(1))
          .getSingleOrNull();

      String todayStatus = 'Belum Absen';
      DateTime? todayClockIn;
      DateTime? todayClockOut;
      String? todayLogId;

      if (todayLog != null) {
        todayLogId = todayLog.id;
        todayClockIn = todayLog.clockIn;
        todayClockOut = todayLog.clockOut;
        if (todayLog.status == 'absent') {
          todayStatus = 'Izin / Tidak Hadir';
        } else {
          todayStatus = 'Hadir';
        }
      }

      // Read salary & kasbon config from permissions JSON
      final permissions = emp['permissions'] is Map ? emp['permissions'] as Map : {};
      final salaryType = permissions['salary_type']?.toString() ?? 'monthly'; // default to monthly
      final ratePerShift = (permissions['rate_per_shift'] is num)
          ? (permissions['rate_per_shift'] as num).toDouble()
          : 75000.0;
      final monthlySalary = (permissions['monthly_salary'] is num)
          ? (permissions['monthly_salary'] as num).toDouble()
          : 2000000.0;
      final kasbonTotal = (permissions['kasbon_total'] is num)
          ? (permissions['kasbon_total'] as num).toDouble()
          : 0.0;
      final kasbonList = permissions['kasbon_history'] is List
          ? List<Map<String, dynamic>>.from(permissions['kasbon_history'])
          : <Map<String, dynamic>>[];
      final roleTitle = permissions['role_title']?.toString() ??
          (emp['role'] == 'cashier' ? 'Kasir' : 'Staff');
      final hasLoginAccount = permissions['has_login_account'] as bool? ??
          (emp['email'] != null && emp['email'].toString().isNotEmpty && emp['email'] != '-');

      // Calculate base salary
      final double calculatedSalary = salaryType == 'shift'
          ? (shiftCount * ratePerShift)
          : monthlySalary;
      final double netSalary = (calculatedSalary - kasbonTotal).clamp(0, double.infinity);

      // Check if salary for targetMonth is already marked/paid
      final String monthKey = "${targetMonth.year}-${targetMonth.month.toString().padLeft(2, '0')}";
      final paidMonths = permissions['paid_months'] is List ? List<dynamic>.from(permissions['paid_months']) : [];
      final salaryHistory = permissions['salary_history'] is List
          ? List<Map<String, dynamic>>.from(permissions['salary_history'].map((e) => Map<String, dynamic>.from(e as Map)))
          : <Map<String, dynamic>>[];

      bool isSalaryPaid = paidMonths.contains(monthKey);
      Map<String, dynamic>? lastPaymentForMonth;

      for (final item in salaryHistory) {
        if (item['monthKey'] == monthKey) {
          isSalaryPaid = true;
          lastPaymentForMonth = item;
          break;
        }
        final itemDateStr = item['date'] as String?;
        if (itemDateStr != null) {
          final itemDate = DateTime.tryParse(itemDateStr);
          if (itemDate != null && itemDate.year == targetMonth.year && itemDate.month == targetMonth.month) {
            isSalaryPaid = true;
            lastPaymentForMonth = item;
            break;
          }
        }
      }

      enrichedList.add({
        ...emp,
        'roleTitle': roleTitle,
        'hasLoginAccount': hasLoginAccount,
        'shiftCount': shiftCount,
        'absentCount': absentCount,
        'todayStatus': todayStatus,
        'todayClockIn': todayClockIn,
        'todayClockOut': todayClockOut,
        'todayLogId': todayLogId,
        'salaryType': salaryType,
        'ratePerShift': ratePerShift,
        'monthlySalary': monthlySalary,
        'kasbonTotal': kasbonTotal,
        'kasbonHistory': kasbonList,
        'calculatedSalary': calculatedSalary,
        'netSalary': netSalary,
        'isSalaryPaid': isSalaryPaid,
        'salaryHistory': salaryHistory,
        'lastPaymentForMonth': lastPaymentForMonth,
        'monthKey': monthKey,
      });
    }

    return enrichedList;
  }

  /// Create a new employee/cashier account locally
  Future<void> createCashierAccount({
    required String id,
    required String email,
    required String password,
    required String fullName,
    required String storeId,
    String salaryType = 'shift',
    double ratePerShift = 75000,
    double monthlySalary = 2000000,
    Map<String, dynamic>? permissions,
  }) async {
    final defaultPermissions = <String, dynamic>{
      'manage_inventory': false,
      'manage_categories': false,
      'pos_access': true,
      'view_history': true,
      'view_reports': false,
      'manage_printer': true,
      'manage_promotions': false,
      'manage_customers': false,
      'salary_type': salaryType,
      'rate_per_shift': ratePerShift,
      'monthly_salary': monthlySalary,
      'kasbon_total': 0.0,
      'kasbon_history': [],
    };

    if (permissions != null) {
      defaultPermissions.addAll(permissions);
    }

    await db.into(db.profiles).insert(
      ProfilesCompanion.insert(
        id: id,
        email: Value(email),
        password: Value(password),
        fullName: Value(fullName),
        role: const Value('cashier'),
        storeId: Value(storeId),
        permissions: Value(jsonEncode(defaultPermissions)),
        lastUpdated: Value(DateTime.now()),
        createdAt: Value(DateTime.now()),
      ),
    );
  }

  /// Update employee salary configuration
  Future<void> updateSalarySettings(
    String userId, {
    required String salaryType,
    required double ratePerShift,
    required double monthlySalary,
  }) async {
    final profile = await (db.select(db.profiles)..where((t) => t.id.equals(userId))).getSingleOrNull();
    if (profile == null) return;

    Map<String, dynamic> perms = {};
    if (profile.permissions != null && profile.permissions!.isNotEmpty) {
      try {
        perms = jsonDecode(profile.permissions!) as Map<String, dynamic>;
      } catch (_) {}
    }

    perms['salary_type'] = salaryType;
    perms['rate_per_shift'] = ratePerShift;
    perms['monthly_salary'] = monthlySalary;

    await (db.update(db.profiles)..where((t) => t.id.equals(userId))).write(
      ProfilesCompanion(
        permissions: Value(jsonEncode(perms)),
        lastUpdated: Value(DateTime.now()),
      ),
    );
  }

  /// Add a kasbon (loan / cash advance) for an employee
  Future<void> addKasbon(
    String userId,
    String storeId, {
    required double amount,
    required String notes,
  }) async {
    final profile = await (db.select(db.profiles)..where((t) => t.id.equals(userId))).getSingleOrNull();
    if (profile == null) return;

    Map<String, dynamic> perms = {};
    if (profile.permissions != null && profile.permissions!.isNotEmpty) {
      try {
        perms = jsonDecode(profile.permissions!) as Map<String, dynamic>;
      } catch (_) {}
    }

    final double currentKasbon = (perms['kasbon_total'] is num)
        ? (perms['kasbon_total'] as num).toDouble()
        : 0.0;
    final List<dynamic> history = perms['kasbon_history'] is List ? List.from(perms['kasbon_history']) : [];

    history.add({
      'id': const Uuid().v4(),
      'amount': amount,
      'date': DateTime.now().toIso8601String(),
      'notes': notes,
      'type': 'add',
    });

    perms['kasbon_total'] = currentKasbon + amount;
    perms['kasbon_history'] = history;

    await (db.update(db.profiles)..where((t) => t.id.equals(userId))).write(
      ProfilesCompanion(
        permissions: Value(jsonEncode(perms)),
        lastUpdated: Value(DateTime.now()),
      ),
    );
  }

  /// Update Monthly Salary directly when tapping the monthly salary column
  Future<void> updateMonthlySalary(String userId, double newMonthlySalary) async {
    final profile = await (db.select(db.profiles)..where((t) => t.id.equals(userId))).getSingleOrNull();
    if (profile == null) return;

    Map<String, dynamic> perms = {};
    if (profile.permissions != null && profile.permissions!.isNotEmpty) {
      try {
        perms = jsonDecode(profile.permissions!) as Map<String, dynamic>;
      } catch (_) {}
    }

    perms['salary_type'] = 'monthly';
    perms['monthly_salary'] = newMonthlySalary;

    await (db.update(db.profiles)..where((t) => t.id.equals(userId))).write(
      ProfilesCompanion(
        permissions: Value(jsonEncode(perms)),
        lastUpdated: Value(DateTime.now()),
      ),
    );
  }

  /// Set Kasbon Total directly when tapping the kasbon column
  Future<void> setKasbonTotal(String userId, double newTotal, {String? notes}) async {
    final profile = await (db.select(db.profiles)..where((t) => t.id.equals(userId))).getSingleOrNull();
    if (profile == null) return;

    Map<String, dynamic> perms = {};
    if (profile.permissions != null && profile.permissions!.isNotEmpty) {
      try {
        perms = jsonDecode(profile.permissions!) as Map<String, dynamic>;
      } catch (_) {}
    }

    final double currentKasbon = (perms['kasbon_total'] is num)
        ? (perms['kasbon_total'] as num).toDouble()
        : 0.0;
    final List<dynamic> history = perms['kasbon_history'] is List ? List.from(perms['kasbon_history']) : [];

    final diff = newTotal - currentKasbon;
    if (diff != 0) {
      history.add({
        'id': const Uuid().v4(),
        'amount': diff.abs(),
        'date': DateTime.now().toIso8601String(),
        'notes': notes ?? (diff > 0 ? 'Penyesuaian Tambah Kasbon' : 'Pelunasan/Pengurangan Kasbon'),
        'type': diff > 0 ? 'add' : 'deduct',
      });
    }

    perms['kasbon_total'] = newTotal.clamp(0, double.infinity);
    perms['kasbon_history'] = history;

    await (db.update(db.profiles)..where((t) => t.id.equals(userId))).write(
      ProfilesCompanion(
        permissions: Value(jsonEncode(perms)),
        lastUpdated: Value(DateTime.now()),
      ),
    );
  }

  /// Create a new employee record (login account is optional)
  Future<void> createEmployeeRecord({
    required String fullName,
    required String storeId,
    String? roleTitle,
    String? email,
    String? password,
    String salaryType = 'monthly',
    double monthlySalary = 2000000,
    double ratePerShift = 75000,
    double initialKasbon = 0.0,
  }) async {
    final id = const Uuid().v4();
    final isAccount = email != null && email.trim().isNotEmpty && password != null && password.trim().isNotEmpty;

    final defaultPermissions = <String, dynamic>{
      'role_title': roleTitle ?? (isAccount ? 'Kasir' : 'Karyawan'),
      'manage_inventory': false,
      'manage_categories': false,
      'pos_access': true,
      'view_history': true,
      'view_reports': false,
      'manage_printer': true,
      'manage_promotions': false,
      'manage_customers': false,
      'salary_type': salaryType,
      'rate_per_shift': ratePerShift,
      'monthly_salary': monthlySalary,
      'kasbon_total': initialKasbon,
      'kasbon_history': initialKasbon > 0
          ? [
              {
                'id': const Uuid().v4(),
                'amount': initialKasbon,
                'date': DateTime.now().toIso8601String(),
                'notes': 'Kasbon Awal',
                'type': 'add',
              }
            ]
          : [],
      'has_login_account': isAccount,
    };

    await db.into(db.profiles).insert(
      ProfilesCompanion.insert(
        id: id,
        email: Value(isAccount ? email.trim() : null),
        password: Value(isAccount ? password.trim() : null),
        fullName: Value(fullName.trim()),
        role: Value(isAccount ? 'cashier' : 'staff'),
        storeId: Value(storeId),
        permissions: Value(jsonEncode(defaultPermissions)),
        lastUpdated: Value(DateTime.now()),
        createdAt: Value(DateTime.now()),
      ),
    );
  }

  /// Pay salary and automatically record it as an expense in the Expenses table
  Future<void> paySalary(
    String userId,
    String storeId, {
    required double netAmountPaid,
    required double kasbonDeducted,
    required String employeeName,
    required String periodNote,
    String? monthKey,
    bool recordAsExpense = true,
  }) async {
    final profile = await (db.select(db.profiles)..where((t) => t.id.equals(userId))).getSingleOrNull();
    if (profile == null) return;

    Map<String, dynamic> perms = {};
    if (profile.permissions != null && profile.permissions!.isNotEmpty) {
      try {
        perms = jsonDecode(profile.permissions!) as Map<String, dynamic>;
      } catch (_) {}
    }

    final double currentKasbon = (perms['kasbon_total'] is num)
        ? (perms['kasbon_total'] as num).toDouble()
        : 0.0;
    final List<dynamic> history = perms['kasbon_history'] is List ? List.from(perms['kasbon_history']) : [];

    if (kasbonDeducted > 0) {
      history.add({
        'id': const Uuid().v4(),
        'amount': kasbonDeducted,
        'date': DateTime.now().toIso8601String(),
        'notes': 'Potongan Kasbon saat Gaji $periodNote',
        'type': 'deduct',
      });
    }

    final newKasbon = (currentKasbon - kasbonDeducted).clamp(0, double.infinity);
    perms['kasbon_total'] = newKasbon;
    perms['kasbon_history'] = history;

    // Record in expense if enabled
    String? expenseId;
    if (recordAsExpense) {
      expenseId = const Uuid().v4();
      await db.into(db.expenses).insert(
        ExpensesCompanion.insert(
          id: expenseId,
          storeId: Value(storeId),
          category: 'Gaji & Upah',
          amount: Value(netAmountPaid),
          date: Value(DateTime.now()),
          notes: Value('Gaji $employeeName - $periodNote'),
        ),
      );
    }

    // Record in employee's salary_history
    final String paymentId = const Uuid().v4();
    final List<dynamic> salaryHistory = perms['salary_history'] is List
        ? List.from(perms['salary_history'])
        : [];
    final List<dynamic> paidMonths = perms['paid_months'] is List
        ? List.from(perms['paid_months'])
        : [];

    final resolvedMonthKey = monthKey ?? "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}";

    salaryHistory.add({
      'id': paymentId,
      'expenseId': expenseId,
      'userId': userId,
      'employeeName': employeeName,
      'netAmountPaid': netAmountPaid,
      'kasbonDeducted': kasbonDeducted,
      'date': DateTime.now().toIso8601String(),
      'periodNote': periodNote,
      'monthKey': resolvedMonthKey,
      'recordAsExpense': recordAsExpense,
      'notes': 'Gaji $employeeName - $periodNote',
    });
    perms['salary_history'] = salaryHistory;

    if (!paidMonths.contains(resolvedMonthKey)) {
      paidMonths.add(resolvedMonthKey);
    }
    perms['paid_months'] = paidMonths;

    // Update employee profile
    await (db.update(db.profiles)..where((t) => t.id.equals(userId))).write(
      ProfilesCompanion(
        permissions: Value(jsonEncode(perms)),
        lastUpdated: Value(DateTime.now()),
      ),
    );
  }

  /// Toggle or set salary checklist status for an employee in a specific month
  Future<void> setSalaryPaidStatus(
    String userId,
    String storeId, {
    required String monthKey,
    required bool isPaid,
    String? employeeName,
    double? netSalary,
    String? periodNote,
    bool recordAsExpense = false,
  }) async {
    final profile = await (db.select(db.profiles)..where((t) => t.id.equals(userId))).getSingleOrNull();
    if (profile == null) return;

    Map<String, dynamic> perms = {};
    if (profile.permissions != null && profile.permissions!.isNotEmpty) {
      try {
        perms = jsonDecode(profile.permissions!) as Map<String, dynamic>;
      } catch (_) {}
    }

    final List<dynamic> paidMonths = perms['paid_months'] is List
        ? List.from(perms['paid_months'])
        : [];
    final List<dynamic> salaryHistory = perms['salary_history'] is List
        ? List.from(perms['salary_history'])
        : [];

    if (isPaid) {
      if (!paidMonths.contains(monthKey)) {
        paidMonths.add(monthKey);
      }
      // Check if already in salaryHistory for this month
      final exists = salaryHistory.any((item) => item['monthKey'] == monthKey);
      if (!exists && netSalary != null) {
        String? expenseId;
        if (recordAsExpense) {
          expenseId = const Uuid().v4();
          await db.into(db.expenses).insert(
            ExpensesCompanion.insert(
              id: expenseId,
              storeId: Value(storeId),
              category: 'Gaji & Upah',
              amount: Value(netSalary),
              date: Value(DateTime.now()),
              notes: Value('Gaji ${employeeName ?? profile.fullName} - ${periodNote ?? monthKey}'),
            ),
          );
        }

        salaryHistory.add({
          'id': const Uuid().v4(),
          'expenseId': expenseId,
          'userId': userId,
          'employeeName': employeeName ?? profile.fullName,
          'netAmountPaid': netSalary,
          'kasbonDeducted': 0.0,
          'date': DateTime.now().toIso8601String(),
          'periodNote': periodNote ?? monthKey,
          'monthKey': monthKey,
          'recordAsExpense': recordAsExpense,
          'notes': 'Tandai Lunas Ceklis Gaji ($monthKey)',
        });
      }
    } else {
      paidMonths.remove(monthKey);
      // Remove or mark un-paid from salaryHistory
      salaryHistory.removeWhere((item) => item['monthKey'] == monthKey);
    }

    perms['paid_months'] = paidMonths;
    perms['salary_history'] = salaryHistory;

    await (db.update(db.profiles)..where((t) => t.id.equals(userId))).write(
      ProfilesCompanion(
        permissions: Value(jsonEncode(perms)),
        lastUpdated: Value(DateTime.now()),
      ),
    );
  }

  /// Get comprehensive salary payment history for a store (optionally filtered by month)
  Future<List<Map<String, dynamic>>> getStoreSalaryHistory(
    String storeId, {
    DateTime? month,
  }) async {
    // 1. Fetch expenses with category 'Gaji & Upah' or containing 'Gaji'
    var expensesQuery = db.select(db.expenses)
      ..where((t) => t.storeId.equals(storeId) & t.category.like('%Gaji%'));

    if (month != null) {
      final start = DateTime(month.year, month.month, 1);
      final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
      expensesQuery = expensesQuery
        ..where((t) => t.date.isBiggerOrEqualValue(start) & t.date.isSmallerOrEqualValue(end));
    }
    expensesQuery = expensesQuery..orderBy([(t) => OrderingTerm.desc(t.date)]);
    final expenses = await expensesQuery.get();

    // 2. Fetch employee records to retrieve extra metadata from permissions['salary_history']
    final employees = await getEmployees(storeId);
    final Map<String, Map<String, dynamic>> historyByExpenseId = {};
    final List<Map<String, dynamic>> allEmployeeHistories = [];

    for (final emp in employees) {
      final permissions = emp['permissions'] is Map ? emp['permissions'] as Map : {};
      final salaryHistory = permissions['salary_history'] is List ? List.from(permissions['salary_history']) : [];
      for (final item in salaryHistory) {
        if (item is Map) {
          final m = Map<String, dynamic>.from(item);
          m['employeeName'] ??= emp['fullName'];
          m['userId'] ??= emp['id'];
          if (m['expenseId'] != null && m['expenseId'].toString().isNotEmpty) {
            historyByExpenseId[m['expenseId'].toString()] = m;
          }
          allEmployeeHistories.add(m);
        }
      }
    }

    final List<Map<String, dynamic>> combined = [];
    final Set<String> processedExpenseIds = {};

    for (final exp in expenses) {
      processedExpenseIds.add(exp.id);
      final matched = historyByExpenseId[exp.id];
      if (matched != null) {
        combined.add({
          'id': matched['id'] ?? exp.id,
          'expenseId': exp.id,
          'userId': matched['userId'],
          'employeeName': matched['employeeName'] ?? 'Karyawan',
          'amount': exp.amount ?? (matched['netAmountPaid'] as num?)?.toDouble() ?? 0.0,
          'kasbonDeducted': (matched['kasbonDeducted'] as num?)?.toDouble() ?? 0.0,
          'date': exp.date ?? DateTime.now(),
          'periodNote': matched['periodNote'] ?? exp.notes ?? '',
          'monthKey': matched['monthKey'],
          'notes': exp.notes ?? '',
          'isSyncedToExpense': true,
        });
      } else {
        String empName = 'Karyawan';
        String periodNote = '';
        if (exp.notes != null) {
          final parts = exp.notes!.replaceFirst(RegExp(r'^Gaji\s+'), '').split(' - ');
          if (parts.isNotEmpty) empName = parts[0];
          if (parts.length > 1) periodNote = parts[1];
        }
        combined.add({
          'id': exp.id,
          'expenseId': exp.id,
          'userId': null,
          'employeeName': empName,
          'amount': exp.amount ?? 0.0,
          'kasbonDeducted': 0.0,
          'date': exp.date ?? DateTime.now(),
          'periodNote': periodNote.isNotEmpty ? periodNote : (exp.notes ?? 'Gaji'),
          'monthKey': null,
          'notes': exp.notes ?? '',
          'isSyncedToExpense': true,
        });
      }
    }

    // Add employee salaryHistory items that were recorded without expense insertion (e.g. manual checklist)
    for (final sh in allEmployeeHistories) {
      final expId = sh['expenseId']?.toString();
      if (expId == null || !processedExpenseIds.contains(expId)) {
        final d = sh['date'] != null
            ? (DateTime.tryParse(sh['date'].toString()) ?? DateTime.now())
            : DateTime.now();

        if (month == null || (d.year == month.year && d.month == month.month)) {
          combined.add({
            'id': sh['id'] ?? const Uuid().v4(),
            'expenseId': null,
            'userId': sh['userId'],
            'employeeName': sh['employeeName'] ?? 'Karyawan',
            'amount': (sh['netAmountPaid'] as num?)?.toDouble() ?? 0.0,
            'kasbonDeducted': (sh['kasbonDeducted'] as num?)?.toDouble() ?? 0.0,
            'date': d,
            'periodNote': sh['periodNote'] ?? '',
            'monthKey': sh['monthKey'],
            'notes': sh['notes'] ?? '',
            'isSyncedToExpense': false,
          });
        }
      }
    }

    // Sort descending by date
    combined.sort((a, b) {
      final da = a['date'] is DateTime ? a['date'] as DateTime : (DateTime.tryParse(a['date'].toString()) ?? DateTime.now());
      final db = b['date'] is DateTime ? b['date'] as DateTime : (DateTime.tryParse(b['date'].toString()) ?? DateTime.now());
      return db.compareTo(da);
    });

    return combined;
  }

  /// Delete / cancel a salary payment record
  Future<void> cancelSalaryPayment(
    String storeId, {
    required String? userId,
    required String? expenseId,
    required String? paymentId,
    String? monthKey,
    double kasbonToRestore = 0.0,
  }) async {
    // 1. Delete from expenses if exists
    if (expenseId != null && expenseId.isNotEmpty) {
      await (db.delete(db.expenses)..where((t) => t.id.equals(expenseId))).go();
    }

    // 2. Remove from employee permissions
    if (userId != null && userId.isNotEmpty) {
      final profile = await (db.select(db.profiles)..where((t) => t.id.equals(userId))).getSingleOrNull();
      if (profile != null) {
        Map<String, dynamic> perms = {};
        if (profile.permissions != null && profile.permissions!.isNotEmpty) {
          try {
            perms = jsonDecode(profile.permissions!) as Map<String, dynamic>;
          } catch (_) {}
        }

        if (perms['salary_history'] is List) {
          final list = List<dynamic>.from(perms['salary_history']);
          list.removeWhere((item) =>
              (paymentId != null && item['id'] == paymentId) ||
              (expenseId != null && item['expenseId'] == expenseId));
          perms['salary_history'] = list;
        }

        if (monthKey != null && perms['paid_months'] is List) {
          final paidMonths = List<dynamic>.from(perms['paid_months']);
          paidMonths.remove(monthKey);
          perms['paid_months'] = paidMonths;
        }

        if (kasbonToRestore > 0) {
          final double curKasbon = (perms['kasbon_total'] is num) ? (perms['kasbon_total'] as num).toDouble() : 0.0;
          perms['kasbon_total'] = curKasbon + kasbonToRestore;
          final List<dynamic> history = perms['kasbon_history'] is List ? List.from(perms['kasbon_history']) : [];
          history.add({
            'id': const Uuid().v4(),
            'amount': kasbonToRestore,
            'date': DateTime.now().toIso8601String(),
            'notes': 'Pengembalian potongan kasbon (Batal bayar gaji)',
            'type': 'add',
          });
          perms['kasbon_history'] = history;
        }

        await (db.update(db.profiles)..where((t) => t.id.equals(userId))).write(
          ProfilesCompanion(
            permissions: Value(jsonEncode(perms)),
            lastUpdated: Value(DateTime.now()),
          ),
        );
      }
    }
  }

  /// Clock in for a specific employee
  Future<void> clockInForEmployee(
    String userId,
    String storeId, {
    String? notes,
    XFile? imageFile,
  }) async {
    String? photoUrl;
    if (imageFile != null) {
      final fileName =
          'attendance_${userId}_${DateTime.now().millisecondsSinceEpoch}${p.extension(imageFile.path)}';
      photoUrl = await FileManager().saveFile(imageFile, fileName);
    }

    final id = const Uuid().v4();
    await db.into(db.attendanceLogs).insert(
      AttendanceLogsCompanion.insert(
        id: id,
        userId: Value(userId),
        storeId: Value(storeId),
        clockIn: Value(DateTime.now()),
        photoUrl: Value(photoUrl),
        notes: Value(notes ?? 'Clock In'),
        status: const Value('working'),
      ),
    );
  }

  /// Clock out for a specific employee log
  Future<void> clockOutForEmployee(
    String logId, {
    String? notes,
  }) async {
    await (db.update(db.attendanceLogs)..where((t) => t.id.equals(logId))).write(
      AttendanceLogsCompanion(
        clockOut: Value(DateTime.now()),
        status: const Value('finished'),
        notes: notes != null ? Value(notes) : const Value.absent(),
      ),
    );
  }

  /// Mark absence for an employee
  Future<void> markAbsenceForEmployee(
    String userId,
    String storeId, {
    String? reason,
  }) async {
    final id = const Uuid().v4();
    final now = DateTime.now();
    await db.into(db.attendanceLogs).insert(
      AttendanceLogsCompanion.insert(
        id: id,
        userId: Value(userId),
        storeId: Value(storeId),
        clockIn: Value(now),
        clockOut: Value(now),
        notes: Value(reason ?? 'Izin / Tidak Hadir'),
        status: const Value('absent'),
      ),
    );
  }

  /// Fetch history of attendance logs for an employee
  Future<List<Map<String, dynamic>>> getAttendanceLogsForEmployee(String userId) async {
    final results = await (db.select(db.attendanceLogs)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([(t) => OrderingTerm.desc(t.clockIn)])
          ..limit(100))
        .get();

    return results.map((e) => e.toJson()).toList();
  }

  /// Delete today's attendance log for a specific employee (to reset/toggle attendance)
  Future<void> deleteTodayAttendance(String userId, String storeId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    await (db.delete(db.attendanceLogs)
          ..where((t) =>
              t.userId.equals(userId) &
              t.storeId.equals(storeId) &
              t.clockIn.isBiggerOrEqualValue(startOfDay) &
              t.clockIn.isSmallerOrEqualValue(endOfDay)))
        .go();
  }

  /// Remove an employee from the local database
  Future<void> removeEmployee(String userId) async {
    await (db.delete(db.profiles)..where((t) => t.id.equals(userId))).go();
  }
}
