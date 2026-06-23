import 'package:erad/core/database/app_database.dart';
import '../models/dashboard_financials.dart';
import '../models/dashboard_product_stock.dart';

abstract class DashboardLocalDataSource {
  Future<void> cacheFinancials(String userId, DashboardFinancialsModel financials);
  Future<DashboardFinancialsModel?> getCachedFinancials(String userId);
  Future<void> cacheProductStock(String userId, List<DashboardProductStockModel> stock);
  Future<List<DashboardProductStockModel>> getCachedProductStock(String userId);
}

class DashboardLocalDataSourceImpl implements DashboardLocalDataSource {
  final AppDatabase _db;

  DashboardLocalDataSourceImpl(this._db);

  @override
  Future<void> cacheFinancials(String userId, DashboardFinancialsModel financials) async {
    await _db.upsertJson('dashboard_financials_cache', 'financials', userId, financials.toMap());
  }

  @override
  Future<DashboardFinancialsModel?> getCachedFinancials(String userId) async {
    final items = await _db.getAllJson('dashboard_financials_cache', userId);
    if (items.isEmpty) return null;
    return DashboardFinancialsModel.fromMap(items.first);
  }

  @override
  Future<void> cacheProductStock(String userId, List<DashboardProductStockModel> stock) async {
    await _db.clearTable('dashboard_product_stock_cache', userId);
    await _db.upsertJsonList(
      'dashboard_product_stock_cache',
      userId,
      stock.map((s) => s.toMap()).toList(),
      (map) => map['product_id'] as String,
    );
  }

  @override
  Future<List<DashboardProductStockModel>> getCachedProductStock(String userId) async {
    final items = await _db.getAllJson('dashboard_product_stock_cache', userId);
    return items.map((json) => DashboardProductStockModel.fromMap(json)).toList();
  }
}
