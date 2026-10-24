import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'app_database.dart';

class CustomerService {
  final AppDatabase db;
  final _uuid = const Uuid();

  CustomerService(this.db);

  Future<List<Customer>> getCustomers(String storeId) async {
    return (db.select(
      db.customers,
    )..where((t) => t.storeId.equals(storeId))).get();
  }

  Future<void> addCustomer({
    required String storeId,
    required String name,
    String? phoneNumber,
    String? email,
  }) async {
    await db
        .into(db.customers)
        .insert(
          CustomersCompanion.insert(
            id: _uuid.v4(),
            storeId: Value(storeId),
            name: Value(name),
            phoneNumber: Value(phoneNumber),
            email: Value(email),
            createdAt: Value(DateTime.now()),
          ),
        );
  }

  Future<void> updateCustomer(Customer customer) async {
    await db.update(db.customers).replace(customer);
  }

  Future<void> deleteCustomer(String id) async {
    await (db.delete(db.customers)..where((t) => t.id.equals(id))).go();
  }

  Future<void> deleteMultipleCustomers(List<String> ids) async {
    await (db.delete(db.customers)..where((t) => t.id.isIn(ids))).go();
  }

  Future<void> addPoints(String customerId, int pointsToAdd) async {
    final customer = await (db.select(
      db.customers,
    )..where((t) => t.id.equals(customerId))).getSingle();
    await db
        .update(db.customers)
        .replace(customer.copyWith(points: customer.points + pointsToAdd));
  }
}
