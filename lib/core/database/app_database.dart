import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class AppDatabase extends GeneratedDatabase {
  AppDatabase(super.e);

  static Future<AppDatabase> create() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'erad_cache.db'));
    return AppDatabase(NativeDatabase(file));
  }

  @override
  int get schemaVersion => 1;

  @override
  Iterable<TableInfo<Table, dynamic>> get allTables => [];

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await customInsert(
            'CREATE TABLE IF NOT EXISTS sales_invoices_cache ('
            'id TEXT PRIMARY KEY, user_id TEXT NOT NULL, '
            'data TEXT NOT NULL, updated_at TEXT NOT NULL)',
          );
          await customInsert(
            'CREATE TABLE IF NOT EXISTS purchase_invoices_cache ('
            'id TEXT PRIMARY KEY, user_id TEXT NOT NULL, '
            'data TEXT NOT NULL, updated_at TEXT NOT NULL)',
          );
          await customInsert(
            'CREATE TABLE IF NOT EXISTS customer_debts_cache ('
            'id TEXT PRIMARY KEY, user_id TEXT NOT NULL, '
            'data TEXT NOT NULL, updated_at TEXT NOT NULL)',
          );
          await customInsert(
            'CREATE TABLE IF NOT EXISTS customer_invoices_cache ('
            'customer_id TEXT NOT NULL, user_id TEXT NOT NULL, '
            'data TEXT NOT NULL, updated_at TEXT NOT NULL, '
            'PRIMARY KEY (customer_id, user_id))',
          );
          await customInsert(
            'CREATE TABLE IF NOT EXISTS customer_payments_cache ('
            'customer_id TEXT NOT NULL, user_id TEXT NOT NULL, '
            'data TEXT NOT NULL, updated_at TEXT NOT NULL, '
            'PRIMARY KEY (customer_id, user_id))',
          );
          await customInsert(
            'CREATE TABLE IF NOT EXISTS dashboard_financials_cache ('
            'id TEXT NOT NULL, user_id TEXT NOT NULL, '
            'data TEXT NOT NULL, updated_at TEXT NOT NULL, '
            'PRIMARY KEY (id, user_id))',
          );
          await customInsert(
            'CREATE TABLE IF NOT EXISTS dashboard_product_stock_cache ('
            'id TEXT PRIMARY KEY, user_id TEXT NOT NULL, '
            'data TEXT NOT NULL, updated_at TEXT NOT NULL)',
          );
        },
        beforeOpen: (details) async {
          await customInsert(
            'CREATE TABLE IF NOT EXISTS pending_payments ('
            'id TEXT PRIMARY KEY, user_id TEXT NOT NULL, '
            'customer_id TEXT NOT NULL, amount REAL NOT NULL, '
            'notes TEXT, payment_date TEXT NOT NULL, '
            'created_at TEXT NOT NULL)',
          );
          await customInsert(
            'CREATE TABLE IF NOT EXISTS dashboard_financials_cache ('
            'id TEXT NOT NULL, user_id TEXT NOT NULL, '
            'data TEXT NOT NULL, updated_at TEXT NOT NULL, '
            'PRIMARY KEY (id, user_id))',
          );
          await customInsert(
            'CREATE TABLE IF NOT EXISTS dashboard_product_stock_cache ('
            'id TEXT PRIMARY KEY, user_id TEXT NOT NULL, '
            'data TEXT NOT NULL, updated_at TEXT NOT NULL)',
          );
        },
      );

  Future<void> upsertJson(String table, String id, String userId, Map<String, dynamic> data) async {
    final now = DateTime.now().toIso8601String();
    await customInsert(
      'INSERT OR REPLACE INTO $table (id, user_id, data, updated_at) VALUES (?, ?, ?, ?)',
      variables: [Variable(id), Variable(userId), Variable(jsonEncode(data)), Variable(now)],
    );
  }

  Future<List<Map<String, dynamic>>> getAllJson(String table, String userId) async {
    final rows = await customSelect(
      'SELECT data FROM $table WHERE user_id = ? ORDER BY updated_at DESC',
      variables: [Variable(userId)],
    ).get();
    return rows.map((row) => jsonDecode(row.read<String>('data')) as Map<String, dynamic>).toList();
  }

  Future<void> upsertJsonList(
    String table,
    String userId,
    List<Map<String, dynamic>> items,
    String Function(Map<String, dynamic>) idExtractor,
  ) async {
    for (final item in items) {
      await upsertJson(table, idExtractor(item), userId, item);
    }
  }

  Future<void> clearTable(String table, String userId) async {
    await customUpdate('DELETE FROM $table WHERE user_id = ?', variables: [Variable(userId)]);
  }

  Future<void> upsertCustomerData(
    String table,
    String customerId,
    String userId,
    List<Map<String, dynamic>> data,
  ) async {
    final now = DateTime.now().toIso8601String();
    final jsonStr = jsonEncode(data);
    await customInsert(
      'INSERT OR REPLACE INTO $table (customer_id, user_id, data, updated_at) VALUES (?, ?, ?, ?)',
      variables: [Variable(customerId), Variable(userId), Variable(jsonStr), Variable(now)],
    );
  }

  Future<List<Map<String, dynamic>>> getCustomerData(String table, String customerId, String userId) async {
    final rows = await customSelect(
      'SELECT data FROM $table WHERE customer_id = ? AND user_id = ?',
      variables: [Variable(customerId), Variable(userId)],
    ).get();
    if (rows.isEmpty) return [];
    return (jsonDecode(rows.first.read<String>('data')) as List).cast<Map<String, dynamic>>();
  }

  Future<void> insertPendingPayment(Map<String, dynamic> payment) async {
    await customInsert(
      'CREATE TABLE IF NOT EXISTS pending_payments ('
      'id TEXT PRIMARY KEY, user_id TEXT NOT NULL, '
      'customer_id TEXT NOT NULL, amount REAL NOT NULL, '
      'notes TEXT, payment_date TEXT NOT NULL, '
      'created_at TEXT NOT NULL)',
    );
    await customInsert(
      'INSERT OR REPLACE INTO pending_payments '
      '(id, user_id, customer_id, amount, notes, payment_date, created_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?)',
      variables: [
        Variable(payment['id']),
        Variable(payment['user_id']),
        Variable(payment['customer_id']),
        Variable(payment['amount']),
        Variable(payment['notes']),
        Variable(payment['payment_date']),
        Variable(payment['created_at']),
      ],
    );
  }

  Future<List<Map<String, dynamic>>> getPendingPayments(String userId) async {
    await customInsert(
      'CREATE TABLE IF NOT EXISTS pending_payments ('
      'id TEXT PRIMARY KEY, user_id TEXT NOT NULL, '
      'customer_id TEXT NOT NULL, amount REAL NOT NULL, '
      'notes TEXT, payment_date TEXT NOT NULL, '
      'created_at TEXT NOT NULL)',
    );
    final rows = await customSelect(
      'SELECT * FROM pending_payments WHERE user_id = ? ORDER BY created_at ASC',
      variables: [Variable(userId)],
    ).get();
    return rows.map((row) => {
      'id': row.read<String>('id'),
      'user_id': row.read<String>('user_id'),
      'customer_id': row.read<String>('customer_id'),
      'amount': row.read<double>('amount'),
      'notes': row.read<String?>('notes'),
      'payment_date': row.read<String>('payment_date'),
      'created_at': row.read<String>('created_at'),
    }).toList();
  }

  Future<void> deletePendingPayment(String id) async {
    await customUpdate('DELETE FROM pending_payments WHERE id = ?', variables: [Variable(id)]);
  }

  Future<void> ensurePendingPaymentsTable() async {
    await customInsert(
      'CREATE TABLE IF NOT EXISTS pending_payments ('
      'id TEXT PRIMARY KEY, user_id TEXT NOT NULL, '
      'customer_id TEXT NOT NULL, amount REAL NOT NULL, '
      'notes TEXT, payment_date TEXT NOT NULL, '
      'created_at TEXT NOT NULL)',
    );
  }
}
