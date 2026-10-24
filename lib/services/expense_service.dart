import 'package:drift/drift.dart';
import 'app_database.dart';
import 'package:uuid/uuid.dart';

class ExpenseService {
  final AppDatabase db;

  ExpenseService(this.db);

  // Get all expenses for a store
  Stream<List<Expense>> watchExpenses(String storeId) {
    return (db.select(db.expenses)
          ..where((t) => t.storeId.equals(storeId))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .watch();
  }

  // Get expenses for a specific date range
  Future<List<Expense>> getExpensesForPeriod(
    String storeId,
    DateTime start,
    DateTime end,
  ) {
    return (db.select(db.expenses)..where(
          (t) => t.storeId.equals(storeId) & t.date.isBetweenValues(start, end),
        ))
        .get();
  }

  // Create new expense
  Future<String> createExpense({
    required String storeId,
    required String category,
    required double amount,
    required DateTime date,
    String? notes,
    String? recurrenceType,       // 'sekali', 'bulanan', 'tahunan', 'kustom'
    int? recurrenceDurationMonths, // total duration in months
  }) async {
    final id = const Uuid().v4();
    await db
        .into(db.expenses)
        .insert(
          ExpensesCompanion.insert(
            id: id,
            storeId: Value(storeId),
            category: category,
            amount: Value(amount),
            date: Value(date),
            notes: Value(notes),
            recurrenceType: Value(recurrenceType),
            recurrenceDurationMonths: Value(recurrenceDurationMonths),
          ),
        );
    return id;
  }

  // Delete expense
  Future<void> deleteExpense(String id) {
    return (db.delete(db.expenses)..where((t) => t.id.equals(id))).go();
  }

  // Update expense
  Future<void> updateExpense({
    required String id,
    double? amount,
    String? category,
    String? notes,
    DateTime? date,
  }) {
    return (db.update(db.expenses)..where((t) => t.id.equals(id))).write(
      ExpensesCompanion(
        amount: amount != null ? Value(amount) : const Value.absent(),
        category: category != null ? Value(category) : const Value.absent(),
        notes: notes != null ? Value(notes) : const Value.absent(),
        date: date != null ? Value(date) : const Value.absent(),
      ),
    );
  }

  // Get total expenses for a period
  Future<double> getTotalExpenses(
    String storeId,
    DateTime start,
    DateTime end,
  ) async {
    final expenses = await getExpensesForPeriod(storeId, start, end);
    return expenses.fold<double>(0.0, (sum, e) => sum + (e.amount ?? 0));
  }
}
