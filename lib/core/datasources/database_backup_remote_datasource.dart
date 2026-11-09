import 'dart:convert';
import 'dart:math' as math;

import 'package:supabase_flutter/supabase_flutter.dart';

import 'database_backup_config.dart';

abstract class DatabaseBackupRemoteDataSource {
  Future<String> buildBackupJson();
}

class DatabaseBackupRemoteDataSourceImpl
    implements DatabaseBackupRemoteDataSource {
  DatabaseBackupRemoteDataSourceImpl(
    this._client, {
    this.config = const DatabaseBackupConfig(),
  });

  final SupabaseClient _client;
  final DatabaseBackupConfig config;

  /// Kullanıcıya ait satırları `user_id` ile taşıyan tablolar.
  static const _userTables = <String>[
    'customers',
    'suppliers',
    'categories',
    'products',
    'expense_categories',
    'partners',
    'sales_invoices',
    'purchase_invoices',
    'payments',
    'expenses',
    'withdrawals',
  ];

  @override
  Future<String> buildBackupJson() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      throw StateError('Yedek almak için oturum açık olmalı');
    }

    final profiles = await _fetchPages('profiles', 'id', userId);
    final userTableRows = await Future.wait(
      _userTables.map((table) => _fetchPages(table, 'user_id', userId)),
    );

    final tables = <String, List<Map<String, dynamic>>>{
      'profiles': profiles,
      for (var i = 0; i < _userTables.length; i++)
        _userTables[i]: userTableRows[i],
    };

    final invoiceItems = await Future.wait([
      _fetchByInvoiceIds(
        'sales_invoice_items',
        _idsOf(tables['sales_invoices'] ?? const []),
      ),
      _fetchByInvoiceIds(
        'purchase_invoice_items',
        _idsOf(tables['purchase_invoices'] ?? const []),
      ),
    ]);
    tables['sales_invoice_items'] = invoiceItems[0];
    tables['purchase_invoice_items'] = invoiceItems[1];

    return jsonEncode({
      'generated_at': DateTime.now().toUtc().toIso8601String(),
      'user_id': userId,
      'tables': tables,
    });
  }

  List<String> _idsOf(List<Map<String, dynamic>> rows) {
    return rows
        .map((row) => row['id'])
        .whereType<String>()
        .toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> _fetchPages(
    String table,
    String column,
    String value,
  ) async {
    final rows = <Map<String, dynamic>>[];
    var offset = 0;

    while (true) {
      final response = await _client
          .from(table)
          .select()
          .eq(column, value)
          .order('id')
          .range(offset, offset + config.rowsPerRequest - 1)
          .count(CountOption.exact);

      final page = _toRows(response.data);
      rows.addAll(page);

      if (page.isEmpty || rows.length >= response.count) break;
      offset += page.length;
    }

    return rows;
  }

  Future<List<Map<String, dynamic>>> _fetchByInvoiceIds(
    String table,
    List<String> invoiceIds,
  ) async {
    final rows = <Map<String, dynamic>>[];

    for (
      var start = 0;
      start < invoiceIds.length;
      start += config.invoiceIdChunkSize
    ) {
      final chunk = invoiceIds.sublist(
        start,
        math.min(start + config.invoiceIdChunkSize, invoiceIds.length),
      );
      var offset = 0;
      var fetched = 0;

      while (true) {
        final response = await _client
            .from(table)
            .select()
            .inFilter('invoice_id', chunk)
            .order('id')
            .range(offset, offset + config.rowsPerRequest - 1)
            .count(CountOption.exact);

        final page = _toRows(response.data);
        rows.addAll(page);
        fetched += page.length;

        if (page.isEmpty || fetched >= response.count) break;
        offset += page.length;
      }
    }

    return rows;
  }

  List<Map<String, dynamic>> _toRows(PostgrestList data) {
    return data
        .map((row) => Map<String, dynamic>.from(row))
        .toList(growable: false);
  }
}
