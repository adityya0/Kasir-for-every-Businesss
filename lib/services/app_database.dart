import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';

import 'database/connection/connection.dart';

part 'app_database.g.dart';

// --- TABLES ---

class Stores extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().nullable()();
  TextColumn get address => text().nullable()(); // Added
  TextColumn get email => text().nullable()(); // Added for receipt
  TextColumn get phoneNumber => text().nullable()(); // Added
  TextColumn get logoUrl => text().nullable()();
  TextColumn get description => text().nullable()(); // Added
  TextColumn get operationalHours => text().nullable()(); // Added (JSON)
  IntColumn get shiftDurationHours =>
      integer().withDefault(const Constant(9))(); // Added
  TextColumn get shiftStartTime =>
      text().withDefault(const Constant('09:00:00'))(); // Added
  BoolColumn get isAttendanceEnabled =>
      boolean().withDefault(const Constant(true))(); // Added
  TextColumn get adminName => text().nullable()();
  TextColumn get adminAvatar => text().nullable()();
  DateTimeColumn get createdAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Profiles extends Table {
  TextColumn get id => text()();
  TextColumn get email => text().nullable().unique()(); // Added
  TextColumn get password => text().nullable()(); // Added
  TextColumn get fullName => text().nullable()();
  TextColumn get role => text().withDefault(const Constant('staff'))();
  TextColumn get storeId => text().nullable()();
  DateTimeColumn get createdAt => dateTime().nullable()(); // Added
  DateTimeColumn get lastUpdated => dateTime().nullable()();
  TextColumn get avatarUrl => text().nullable()(); // Added
  TextColumn get permissions => text().nullable()(); // Added (JSON)

  @override
  Set<Column> get primaryKey => {id};
}

class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().nullable()();
  TextColumn get iconUrl => text().nullable()();
  TextColumn get storeId => text().nullable()();
  DateTimeColumn get createdAt => dateTime().nullable()(); // Added
  DateTimeColumn get lastUpdated => dateTime().nullable()(); // Keep for sync

  @override
  Set<Column> get primaryKey => {id};
}

class Units extends Table {
  TextColumn get id => text()();
  TextColumn get storeId => text().nullable()();
  TextColumn get name => text()(); // e.g. Kilogram
  TextColumn get code => text()(); // e.g. Kg
  BoolColumn get isFractional => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Products extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().nullable()();
  RealColumn get buyPrice => real().nullable()(); // Added match SQL
  RealColumn get basePrice => real().nullable()(); // Keep for backward compat
  RealColumn get salePrice => real().nullable()();
  TextColumn get wholesalePricesJson => text().nullable()(); // Added for Wholesale Pricing (JSON)
  RealColumn get stockQuantity => real().nullable()(); // Changed to Real for fractional stock (0.5 kg)
  BoolColumn get isStockManaged =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get isAvailable => boolean().withDefault(const Constant(true))();
  TextColumn get sku => text().nullable()();
  TextColumn get unitId => text().nullable()(); // Added for UoM
  TextColumn get description => text().nullable()();
  TextColumn get imageUrl => text().nullable()();
  TextColumn get categoryId => text().nullable()();
  TextColumn get storeId => text().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().nullable()(); // Added
  DateTimeColumn get lastUpdated => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class StoreTables extends Table {
  TextColumn get id => text()();
  TextColumn get storeId => text().nullable()();
  TextColumn get name => text()(); // e.g., Meja 1, VIP A
  TextColumn get status => text().withDefault(const Constant('available'))(); // available, occupied, reserved
  DateTimeColumn get createdAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class ProductOptions extends Table {
  TextColumn get id => text()();
  TextColumn get productId => text().nullable()();
  TextColumn get storeId => text().nullable()();
  TextColumn get optionName => text().nullable()();
  BoolColumn get isRequired => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().nullable()(); // Added
  DateTimeColumn get lastUpdated => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class ProductOptionValues extends Table {
  TextColumn get id => text()();
  TextColumn get optionId => text().nullable()();
  TextColumn get valueName => text().nullable()();
  RealColumn get priceAdjustment => real().nullable()();
  RealColumn get stockMultiplier => real().withDefault(const Constant(1.0))(); // Added to allow variant stock deduction (e.g., 0.5)
  DateTimeColumn get createdAt => dateTime().nullable()(); // Added

  @override
  Set<Column> get primaryKey => {id};
}

class Customers extends Table {
  TextColumn get id => text()();
  TextColumn get storeId => text().nullable()();
  TextColumn get name => text().nullable()();
  TextColumn get phoneNumber => text().nullable()();
  TextColumn get email => text().nullable()();
  IntColumn get points => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Transactions extends Table {
  TextColumn get id => text()();
  RealColumn get totalAmount => real().nullable()();
  RealColumn get cashReceived => real().nullable()(); // Not in SQL but useful
  RealColumn get change => real().nullable()(); // Not in SQL but useful
  TextColumn get paymentMethod => text().nullable()();
  TextColumn get cashierId => text().nullable()();
  TextColumn get storeId => text().nullable()();
  TextColumn get status =>
      text().withDefault(const Constant('completed'))(); // Added
  TextColumn get source =>
      text().withDefault(const Constant('pos_offline'))(); // Added
  TextColumn get customerName => text().nullable()(); // Added
  TextColumn get customerId => text().nullable()(); // Added for loyalty link
  TextColumn get tableNumber => text().nullable()(); // Added
  TextColumn get notes => text().nullable()(); // Added
  DateTimeColumn get createdAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class TransactionItems extends Table {
  TextColumn get id => text()();
  TextColumn get transactionId => text().nullable()();
  TextColumn get productId => text().nullable()();
  TextColumn get productName => text().nullable()(); // Not in SQL?
  IntColumn get quantity => integer().nullable()(); // Keep as Int for variants
  RealColumn get unitPrice => real().nullable()();
  RealColumn get priceAtTime => real().nullable()(); // Added match SQL
  RealColumn get totalPrice => real().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get selectedOptionsJson => text().nullable()();
  DateTimeColumn get createdAt => dateTime().nullable()(); // Added

  @override
  Set<Column> get primaryKey => {id};
}

class AttendanceLogs extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().nullable()();
  TextColumn get storeId => text().nullable()();
  DateTimeColumn get clockIn => dateTime().nullable()();
  DateTimeColumn get clockOut => dateTime().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get photoUrl => text().nullable()();
  TextColumn get status => text().nullable()(); // working, break, finished
  BoolColumn get isOvertime => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class Promotions extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().nullable()();
  TextColumn get type => text()(); // discount, buy_x_get_y, bundle
  TextColumn get discountType =>
      text().withDefault(const Constant('percentage'))(); // percentage, fixed
  TextColumn get description => text().nullable()();
  RealColumn get value => real().nullable()(); // % or fixed amount
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  TextColumn get storeId => text().nullable()();
  DateTimeColumn get startDate => dateTime().nullable()();
  DateTimeColumn get endDate => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class PromotionItems extends Table {
  TextColumn get id => text()();
  TextColumn get promotionId => text().nullable()();
  TextColumn get productId => text().nullable()();
  TextColumn get categoryId => text().nullable()();
  TextColumn get role => text()(); // BUY, GET, TARGET
  IntColumn get quantity => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};
}

class Expenses extends Table {
  TextColumn get id => text()();
  TextColumn get storeId => text().nullable()();
  TextColumn get category => text()(); // Listrik, Sewa, Gaji, Makan, Lainnya
  RealColumn get amount => real().nullable()();
  DateTimeColumn get date => dateTime().nullable()();
  TextColumn get notes => text().nullable()();
  // Recurrence fields
  TextColumn get recurrenceType => text().nullable()(); // sekali, bulanan, tahunan, kustom
  IntColumn get recurrenceDurationMonths => integer().nullable()(); // in months, e.g. 12 = 1 year

  @override
  Set<Column> get primaryKey => {id};
}

class PaymentMethods extends Table {
  TextColumn get id => text()();
  TextColumn get storeId => text().nullable()();
  TextColumn get name => text()();
  TextColumn get type => text()(); // cash, qris, ewallet
  TextColumn get details => text().nullable()(); // number
  TextColumn get username => text().nullable()();
  TextColumn get qrisUrl => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// --- DATABASE CLASS ---

@DriftDatabase(
  tables: [
    Stores,
    Profiles,
    Categories,
    Products,
    ProductOptions,
    ProductOptionValues,
    Transactions,
    TransactionItems,
    AttendanceLogs,
    Promotions,
    PromotionItems,
    Expenses,
    Customers,
    PaymentMethods,
    Units,
    StoreTables,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 10;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(promotions);
        await m.createTable(promotionItems);
      }
      if (from < 3) {
        // Only add column if table was already created in version 2
        await m.addColumn(promotions, promotions.discountType);
      }
      if (from < 4) {
        await m.createTable(expenses);
      }
      if (from < 5) {
        try {
          await m.createTable(customers);
        } catch (e) {
          debugPrint(
            "Migration: 'customers' table already exists, skipping...",
          );
        }
        try {
          await m.addColumn(transactions, transactions.customerId);
        } catch (e) {
          if (e.toString().contains('duplicate column name')) {
            debugPrint("Migration: 'customer_id' already exists, skipping...");
          } else {
            rethrow;
          }
        }
      }
      if (from < 6) {
        await m.createTable(paymentMethods);
      }
      if (from < 7) {
        try {
          // Use m.addColumn with the specific column definition
          await m.addColumn(stores, stores.email);
        } catch (e) {
          debugPrint("Migration: 'email' already exists in 'stores', skipping...");
        }
      }
      if (from < 8) {
        try {
          await m.addColumn(expenses, expenses.recurrenceType);
        } catch (e) {
          debugPrint("Migration: 'recurrence_type' already exists, skipping...");
        }
        try {
          await m.addColumn(expenses, expenses.recurrenceDurationMonths);
        } catch (e) {
          debugPrint("Migration: 'recurrence_duration_months' already exists, skipping...");
        }
      }
      if (from < 9) {
        await m.createTable(units);
        try { await m.addColumn(products, products.unitId); } catch (_) {}
        try { await m.addColumn(productOptionValues, productOptionValues.stockMultiplier); } catch (_) {}
        
        // Populate dummy units immediately during migration
        try {
          await into(units).insert(UnitsCompanion.insert(id: 'uKg', name: 'Kilogram', code: 'Kg'));
          await into(units).insert(UnitsCompanion.insert(id: 'uGram', name: 'Gram', code: 'Gr'));
          await into(units).insert(UnitsCompanion.insert(id: 'uLiter', name: 'Liter', code: 'L'));
          await into(units).insert(UnitsCompanion.insert(id: 'uPcs', name: 'Pieces', code: 'Pcs', isFractional: const Value(false)));
          await into(units).insert(UnitsCompanion.insert(id: 'uPack', name: 'Pack', code: 'Pack', isFractional: const Value(false)));
        } catch (_) {}
      }
      if (from < 10) {
        await m.createTable(storeTables);
        try {
          await m.addColumn(products, products.wholesalePricesJson);
        } catch (_) {}
        try {
          await m.addColumn(products, products.buyPrice);
        } catch (_) {}
        try {
          await m.addColumn(transactions, transactions.tableNumber);
        } catch (_) {}
        try {
          await m.addColumn(transactionItems, transactionItems.priceAtTime);
        } catch (_) {}
      }
    },
  );
}

QueryExecutor _openConnection() {
  return connect();
}
