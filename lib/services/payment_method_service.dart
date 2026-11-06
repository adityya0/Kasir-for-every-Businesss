import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'app_database.dart';

class PaymentMethodService {
  final AppDatabase _db;
  final _uuid = const Uuid();

  PaymentMethodService(this._db);

  Stream<List<PaymentMethod>> watchActivePaymentMethods(String storeId) {
    return (_db.select(_db.paymentMethods)
          ..where((t) => t.storeId.equals(storeId))
          ..where((t) => t.isActive.equals(true))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.asc),
          ]))
        .watch();
  }

  Future<List<PaymentMethod>> getPaymentMethods(String storeId) async {
    await ensureDefaultPaymentMethods(storeId);
    return (_db.select(_db.paymentMethods)
          ..where((t) => t.storeId.equals(storeId))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.asc),
          ]))
        .get();
  }

  Future<void> ensureDefaultPaymentMethods(String storeId) async {
    final prefs = await SharedPreferences.getInstance();
    final initializedKey = 'default_payment_methods_initialized_$storeId';
    final alreadyInitialized = prefs.getBool(initializedKey) ?? false;

    final existing = await (_db.select(_db.paymentMethods)
          ..where((t) => t.storeId.equals(storeId)))
        .get();

    if (!alreadyInitialized) {
      final hasCash = existing.any((m) {
        final name = m.name.toLowerCase();
        final type = m.type.toLowerCase();
        return type == 'cash' || name.contains('kas') || name.contains('tunai') || name.contains('cash');
      });

      if (!hasCash) {
        await createPaymentMethod(
          storeId: storeId,
          name: "Kas",
          type: "cash",
        );
      }

      final hasQris = existing.any((m) {
        final name = m.name.toLowerCase();
        final type = m.type.toLowerCase();
        return type == 'qris' || name.contains('qris');
      });

      if (!hasQris) {
        await createPaymentMethod(
          storeId: storeId,
          name: "QRIS",
          type: "qris",
        );
      }

      await prefs.setBool(initializedKey, true);
    } else {
      if (existing.isEmpty) {
        await createPaymentMethod(
          storeId: storeId,
          name: "Kas",
          type: "cash",
        );
      }
    }
  }

  Future<double> getInitialBalance(String storeId, PaymentMethod method) async {
    final prefs = await SharedPreferences.getInstance();
    final val = prefs.getDouble('payment_method_initial_balance_${storeId}_${method.id}');
    if (val != null) return val;

    final name = method.name.toLowerCase();
    if (name.contains('kas') || method.type == 'cash') {
      return prefs.getDouble('drawer_base_cash_$storeId') ?? 0.0;
    }
    if (name.contains('qris') || method.type == 'qris') {
      return prefs.getDouble('bank_base_balance_$storeId') ?? 0.0;
    }
    return 0.0;
  }

  Future<void> setInitialBalance(String storeId, PaymentMethod method, double balance) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('payment_method_initial_balance_${storeId}_${method.id}', balance);

    final name = method.name.toLowerCase();
    if (name.contains('kas') || method.type == 'cash') {
      await prefs.setDouble('drawer_base_cash_$storeId', balance);
    }
    if (name.contains('qris') || method.type == 'qris') {
      await prefs.setDouble('bank_base_balance_$storeId', balance);
    }
  }

  Future<PaymentMethod> createPaymentMethod({
    required String storeId,
    required String name,
    required String type,
    String? details,
    String? username,
    String? qrisUrl,
    double initialBalance = 0.0,
  }) async {
    final id = _uuid.v4();
    final row = PaymentMethodsCompanion.insert(
      id: id,
      storeId: Value(storeId),
      name: name,
      type: type,
      details: Value(details),
      username: Value(username),
      qrisUrl: Value(qrisUrl),
      createdAt: Value(DateTime.now()),
    );
    await _db.into(_db.paymentMethods).insert(row);
    if (initialBalance > 0) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('payment_method_initial_balance_${storeId}_$id', initialBalance);
      final n = name.toLowerCase();
      if (n.contains('kas') || type == 'cash') {
        await prefs.setDouble('drawer_base_cash_$storeId', initialBalance);
      } else if (n.contains('qris') || type == 'qris') {
        await prefs.setDouble('bank_base_balance_$storeId', initialBalance);
      }
    }
    return (_db.select(_db.paymentMethods)..where((t) => t.id.equals(id))).getSingle();
  }

  Future<void> updatePaymentMethod(PaymentMethod method, {double? initialBalance}) async {
    await _db.update(_db.paymentMethods).replace(method);
    if (initialBalance != null && method.storeId != null) {
      await setInitialBalance(method.storeId!, method, initialBalance);
    }
  }

  Future<void> togglePaymentMethodActive(String id, bool isActive) async {
    await (_db.update(_db.paymentMethods)..where((t) => t.id.equals(id))).write(
      PaymentMethodsCompanion(isActive: Value(isActive)),
    );
  }

  Future<void> deletePaymentMethod(String id, {String? storeId}) async {
    await (_db.delete(_db.paymentMethods)..where((t) => t.id.equals(id))).go();
    if (storeId != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('payment_method_initial_balance_${storeId}_$id');
      await prefs.remove('payment_method_inflow_${storeId}_$id');
      await prefs.remove('payment_method_outflow_${storeId}_$id');
    }
  }

  Future<double> getOutflow(String storeId, PaymentMethod method) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('payment_method_outflow_${storeId}_${method.id}') ?? 0.0;
  }

  Future<double> getInflow(String storeId, PaymentMethod method) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('payment_method_inflow_${storeId}_${method.id}') ?? 0.0;
  }

  Future<void> addOutflow(String storeId, PaymentMethod method, double amount, {String? notes}) async {
    final prefs = await SharedPreferences.getInstance();
    final cur = prefs.getDouble('payment_method_outflow_${storeId}_${method.id}') ?? 0.0;
    await prefs.setDouble('payment_method_outflow_${storeId}_${method.id}', cur + amount);

    await _db.into(_db.expenses).insert(
      ExpensesCompanion.insert(
        id: _uuid.v4(),
        storeId: Value(storeId),
        category: 'Prive / Tarik Saldo',
        amount: Value(amount),
        date: Value(DateTime.now()),
        notes: Value(notes ?? 'Tarik saldo dari ${method.name}'),
      ),
    );
  }

  Future<void> addInflow(String storeId, PaymentMethod method, double amount, {String? notes}) async {
    final prefs = await SharedPreferences.getInstance();
    final cur = prefs.getDouble('payment_method_inflow_${storeId}_${method.id}') ?? 0.0;
    await prefs.setDouble('payment_method_inflow_${storeId}_${method.id}', cur + amount);
  }

  Future<void> clearBalance(String storeId, PaymentMethod method, double currentBalance, {String? notes}) async {
    if (currentBalance > 0) {
      await addOutflow(storeId, method, currentBalance, notes: notes ?? 'Kosongkan saldo ${method.name} (tarik ke Rp 0)');
    } else if (currentBalance < 0) {
      await addInflow(storeId, method, currentBalance.abs(), notes: notes ?? 'Penyesuaian saldo ${method.name} ke Rp 0');
    }
  }

  Future<void> transferBalance({
    required String storeId,
    required PaymentMethod fromMethod,
    required PaymentMethod toMethod,
    required double amount,
    String? notes,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final curOut = prefs.getDouble('payment_method_outflow_${storeId}_${fromMethod.id}') ?? 0.0;
    await prefs.setDouble('payment_method_outflow_${storeId}_${fromMethod.id}', curOut + amount);

    final curIn = prefs.getDouble('payment_method_inflow_${storeId}_${toMethod.id}') ?? 0.0;
    await prefs.setDouble('payment_method_inflow_${storeId}_${toMethod.id}', curIn + amount);

    final transferDesc = 'Transfer saldo dari ${fromMethod.name} ke ${toMethod.name}${notes != null && notes.isNotEmpty ? " ($notes)" : ""}';
    await _db.into(_db.expenses).insert(
      ExpensesCompanion.insert(
        id: _uuid.v4(),
        storeId: Value(storeId),
        category: 'Transfer Saldo',
        amount: Value(amount),
        date: Value(DateTime.now()),
        notes: Value(transferDesc),
      ),
    );
  }

  Future<void> recordExpense({
    required String storeId,
    required PaymentMethod method,
    required String category,
    required double amount,
    String? notes,
    DateTime? date,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final cur = prefs.getDouble('payment_method_outflow_${storeId}_${method.id}') ?? 0.0;
    await prefs.setDouble('payment_method_outflow_${storeId}_${method.id}', cur + amount);

    final cleanNotes = notes != null && notes.trim().isNotEmpty ? notes.trim() : category;
    final fullNotes = '$cleanNotes [${method.name}]';

    await _db.into(_db.expenses).insert(
      ExpensesCompanion.insert(
        id: _uuid.v4(),
        storeId: Value(storeId),
        category: category,
        amount: Value(amount),
        date: Value(date ?? DateTime.now()),
        notes: Value(fullNotes),
      ),
    );
  }

  Future<void> recordInflow({
    required String storeId,
    required PaymentMethod method,
    required String category,
    required double amount,
    String? notes,
    DateTime? date,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final cur = prefs.getDouble('payment_method_inflow_${storeId}_${method.id}') ?? 0.0;
    await prefs.setDouble('payment_method_inflow_${storeId}_${method.id}', cur + amount);

    final cleanNotes = notes != null && notes.trim().isNotEmpty ? notes.trim() : category;
    final fullNotes = '$cleanNotes [${method.name}] [INFLOW]';

    await _db.into(_db.expenses).insert(
      ExpensesCompanion.insert(
        id: _uuid.v4(),
        storeId: Value(storeId),
        category: category,
        amount: Value(amount),
        date: Value(date ?? DateTime.now()),
        notes: Value(fullNotes),
      ),
    );
  }

  Future<void> deleteFinancialRecord(String storeId, Expense expense) async {
    final prefs = await SharedPreferences.getInstance();
    final methods = await getPaymentMethods(storeId);
    final notes = expense.notes ?? '';
    final amount = expense.amount ?? 0.0;

    PaymentMethod? targetMethod;
    for (final m in methods) {
      if (notes.contains('[${m.name}]') ||
          notes.toLowerCase().contains(m.name.toLowerCase()) ||
          notes.contains(m.id)) {
        targetMethod = m;
        break;
      }
    }

    final isInflow = expense.category == 'Pemasukan Lain' ||
        expense.category == 'Setor Modal' ||
        notes.contains('[INFLOW]') ||
        expense.category.toLowerCase().contains('pemasukan') ||
        expense.category.toLowerCase().contains('modal');

    if (isInflow) {
      if (targetMethod != null) {
        final cur = prefs.getDouble('payment_method_inflow_${storeId}_${targetMethod.id}') ?? 0.0;
        final next = (cur - amount).clamp(0.0, double.infinity);
        await prefs.setDouble('payment_method_inflow_${storeId}_${targetMethod.id}', next);
      }
    } else if (expense.category == 'Transfer Saldo') {
      for (final m in methods) {
        if (notes.contains('dari ${m.name}')) {
          final cur = prefs.getDouble('payment_method_outflow_${storeId}_${m.id}') ?? 0.0;
          final next = (cur - amount).clamp(0.0, double.infinity);
          await prefs.setDouble('payment_method_outflow_${storeId}_${m.id}', next);
        }
        if (notes.contains('ke ${m.name}')) {
          final cur = prefs.getDouble('payment_method_inflow_${storeId}_${m.id}') ?? 0.0;
          final next = (cur - amount).clamp(0.0, double.infinity);
          await prefs.setDouble('payment_method_inflow_${storeId}_${m.id}', next);
        }
      }
    } else {
      if (targetMethod != null) {
        final cur = prefs.getDouble('payment_method_outflow_${storeId}_${targetMethod.id}') ?? 0.0;
        final next = (cur - amount).clamp(0.0, double.infinity);
        await prefs.setDouble('payment_method_outflow_${storeId}_${targetMethod.id}', next);
      }
    }

    await (_db.delete(_db.expenses)..where((t) => t.id.equals(expense.id))).go();
  }

  Future<void> updateFinancialRecord({
    required String storeId,
    required Expense oldExpense,
    required PaymentMethod newMethod,
    required String newCategory,
    required double newAmount,
    String? newNotes,
    DateTime? newDate,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final methods = await getPaymentMethods(storeId);
    final oldNotes = oldExpense.notes ?? '';
    final oldAmount = oldExpense.amount ?? 0.0;

    PaymentMethod? oldMethod;
    for (final m in methods) {
      if (oldNotes.contains('[${m.name}]') ||
          oldNotes.toLowerCase().contains(m.name.toLowerCase()) ||
          oldNotes.contains(m.id)) {
        oldMethod = m;
        break;
      }
    }

    final wasInflow = oldExpense.category == 'Pemasukan Lain' ||
        oldExpense.category == 'Setor Modal' ||
        oldNotes.contains('[INFLOW]') ||
        oldExpense.category.toLowerCase().contains('pemasukan') ||
        oldExpense.category.toLowerCase().contains('modal');

    // 1. Revert previous balance impact
    if (wasInflow) {
      if (oldMethod != null) {
        final cur = prefs.getDouble('payment_method_inflow_${storeId}_${oldMethod.id}') ?? 0.0;
        await prefs.setDouble('payment_method_inflow_${storeId}_${oldMethod.id}', (cur - oldAmount).clamp(0.0, double.infinity));
      }
    } else if (oldExpense.category != 'Transfer Saldo') {
      if (oldMethod != null) {
        final cur = prefs.getDouble('payment_method_outflow_${storeId}_${oldMethod.id}') ?? 0.0;
        await prefs.setDouble('payment_method_outflow_${storeId}_${oldMethod.id}', (cur - oldAmount).clamp(0.0, double.infinity));
      }
    }

    // 2. Apply new balance impact
    final isNewInflow = newCategory == 'Pemasukan Lain' ||
        newCategory == 'Setor Modal' ||
        newCategory.toLowerCase().contains('pemasukan') ||
        newCategory.toLowerCase().contains('modal') ||
        wasInflow;

    if (isNewInflow) {
      final cur = prefs.getDouble('payment_method_inflow_${storeId}_${newMethod.id}') ?? 0.0;
      await prefs.setDouble('payment_method_inflow_${storeId}_${newMethod.id}', cur + newAmount);
    } else {
      final cur = prefs.getDouble('payment_method_outflow_${storeId}_${newMethod.id}') ?? 0.0;
      await prefs.setDouble('payment_method_outflow_${storeId}_${newMethod.id}', cur + newAmount);
    }

    // 3. Update database row
    final cleanNotes = (newNotes != null && newNotes.trim().isNotEmpty) ? newNotes.trim() : newCategory;
    final inflowTag = isNewInflow ? ' [INFLOW]' : '';
    final fullNotes = '$cleanNotes [${newMethod.name}]$inflowTag';

    await (_db.update(_db.expenses)..where((t) => t.id.equals(oldExpense.id))).write(
      ExpensesCompanion(
        category: Value(newCategory),
        amount: Value(newAmount),
        date: Value(newDate ?? oldExpense.date ?? DateTime.now()),
        notes: Value(fullNotes),
      ),
    );
  }

  Future<void> deleteWithdrawal(String storeId, Expense expense) =>
      deleteFinancialRecord(storeId, expense);

  Future<Map<String, double>> calculateCurrentBalances(String storeId) async {
    final summaries = await calculateMethodSummaries(storeId);
    return summaries.map((k, v) => MapEntry(k, v.currentBalance));
  }

  Future<Map<String, MethodBalanceSummary>> calculateMethodSummaries(String storeId) async {
    await ensureDefaultPaymentMethods(storeId);
    final methods = await getPaymentMethods(storeId);

    // Fetch all store transactions
    final allTxs = await (_db.select(_db.transactions)).get();

    final validTxs = allTxs.where((t) {
      final s = t.status.toLowerCase().trim();
      final isStore = t.storeId == null || t.storeId == storeId || t.storeId == 'default_store';
      return isStore && s != 'cancelled' && s != 'batal';
    }).toList();

    final result = <String, MethodBalanceSummary>{};

    for (final m in methods) {
      final initBal = await getInitialBalance(storeId, m);
      final inf = await getInflow(storeId, m);
      final out = await getOutflow(storeId, m);

      double salesInc = 0.0;
      final mName = m.name.toLowerCase().trim();
      final mType = m.type.toLowerCase().trim();
      final isCashMethod = mType == 'cash' ||
          mType == 'kas' ||
          mName.contains('kas') ||
          mName.contains('tunai') ||
          mName.contains('cash') ||
          mName.contains('laci');
      final isQrisMethod = mType == 'qris' || mName.contains('qris');

      for (final tx in validTxs) {
        // 1. Check if transaction has split_payments
        bool handledBySplit = false;
        if (tx.notes != null && tx.notes!.contains('split_payments')) {
          try {
            final decoded = jsonDecode(tx.notes!);
            if (decoded is Map && decoded['split_payments'] is List) {
              for (final sp in decoded['split_payments']) {
                final spMethod = (sp['method'] ?? '').toString().toLowerCase().trim();
                final spAmt = (sp['amount'] as num?)?.toDouble() ?? 0.0;
                if (_matchesMethod(spMethod, isCashMethod, isQrisMethod, mName, mType)) {
                  salesInc += spAmt;
                  handledBySplit = true;
                }
              }
            }
          } catch (_) {}
        }

        if (handledBySplit) continue;

        // 2. Normal transaction
        final txStatus = tx.status.toLowerCase().trim();
        final double effectiveAmt = (txStatus == 'debt')
            ? ((tx.cashReceived ?? 0.0).clamp(0.0, tx.totalAmount ?? 0.0))
            : (tx.totalAmount ?? 0.0);

        if (effectiveAmt <= 0) continue;

        final txMethod = (tx.paymentMethod ?? 'tunai').toLowerCase().trim();
        if (_matchesMethod(txMethod, isCashMethod, isQrisMethod, mName, mType)) {
          salesInc += effectiveAmt;
        }
      }

      final curBal = initBal + salesInc + inf - out;
      result[m.id] = MethodBalanceSummary(
        initialBalance: initBal,
        salesIncome: salesInc,
        otherInflow: inf,
        totalOutflow: out,
        currentBalance: curBal,
      );
    }

    return result;
  }

  bool _matchesMethod(
    String txMethod,
    bool isCashMethod,
    bool isQrisMethod,
    String mName,
    String mType,
  ) {
    if (isCashMethod) {
      return txMethod.contains('tunai') ||
          txMethod.contains('cash') ||
          txMethod.contains('kas') ||
          txMethod.isEmpty;
    }
    if (isQrisMethod) {
      return txMethod.contains('qris') || txMethod.contains('digital');
    }
    return txMethod == mName ||
        txMethod.contains(mName) ||
        mName.contains(txMethod);
  }

}

class MethodBalanceSummary {
  final double initialBalance;
  final double salesIncome;
  final double otherInflow;
  final double totalOutflow;
  final double currentBalance;

  MethodBalanceSummary({
    required this.initialBalance,
    required this.salesIncome,
    required this.otherInflow,
    required this.totalOutflow,
    required this.currentBalance,
  });
}
