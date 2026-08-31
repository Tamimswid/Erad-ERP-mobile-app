import 'package:erad/core/constants/api_constans.dart';
import 'package:get_it/get_it.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/app_database.dart';
import '../network/network_info.dart';
import '../utils/app_utils.dart';
import '../services/user_service.dart';
import '../../features/auth/data/datasource/auth_remote_datasource.dart';
import '../../features/auth/data/datasource/auth_local_datasource.dart';
import '../../features/auth/data/repositories/auth_repository.dart';
import '../../features/auth/presentation/bloc/auth_cubit.dart';
import '../../features/customers/data/datasource/customer_remote_datasource.dart';
import '../../features/customers/data/repositories/customer_repository.dart';
import '../../features/customers/presentation/bloc/customer_cubit.dart';
import '../../features/customer_debts/data/datasource/customer_debt_remote_datasource.dart';
import '../../features/customer_debts/data/datasource/customer_debt_local_datasource.dart';
import '../../features/customer_debts/data/repositories/customer_debt_repository.dart';
import '../../features/customer_debts/data/repositories/customer_debt_repository_impl.dart';
import '../../features/customer_debts/presentation/bloc/customer_debt_cubit.dart';
import '../../features/products/data/datasource/product_remote_datasource.dart';
import '../../features/products/data/repositories/product_repository.dart';
import '../../features/products/presentation/bloc/product_cubit.dart';
import '../../features/invoices/data/datasources/invoice_remote_datasource.dart';
import '../../features/invoices/data/datasources/invoice_local_datasource.dart';
import '../../features/invoices/data/datasources/edit_invoice_datasource.dart';
import '../../features/invoices/data/repositories/invoice_repository.dart';
import '../../features/invoices/data/repositories/edit_invoice_repository.dart';
import '../../features/invoices/presentation/bloc/invoice_cubit.dart';
import '../../features/invoices/presentation/bloc/edit_invoice_cubit.dart';
import '../../features/suppliers/data/datasource/supplier_remote_datasource.dart';
import '../../features/suppliers/data/repositories/supplier_repository.dart';
import '../../features/suppliers/presentation/bloc/supplier_cubit.dart';
import '../../features/suppliers_debts/data/datasource/supplier_debt_remote_datasource.dart';
import '../../features/suppliers_debts/data/repositories/supplier_debt_repository.dart';
import '../../features/suppliers_debts/data/repositories/supplier_debt_repository_impl.dart';
import '../../features/suppliers_debts/presentation/bloc/supplier_debt_cubit.dart';
import '../../features/expenses/data/datasource/expense_remote_datasource.dart';
import '../../features/expenses/data/repositories/expense_repository.dart';
import '../../features/expenses/presentation/bloc/expense_cubit.dart';
import '../../features/withdrawals/data/datasource/withdrawal_remote_datasource.dart';
import '../../features/withdrawals/data/repositories/withdrawal_repository.dart';
import '../../features/withdrawals/presentation/bloc/withdrawal_cubit.dart';
import '../../features/dashboard/data/datasource/dashboard_remote_datasource.dart';
import '../../features/dashboard/data/datasource/dashboard_local_datasource.dart';
import '../../features/dashboard/data/repositories/dashboard_repository.dart';
import '../../features/dashboard/presentation/bloc/dashboard_cubit.dart';
import '../../features/reports/data/datasources/report_remote_datasource.dart';
import '../../features/reports/data/repositories/report_repository.dart';
import '../../features/reports/presentation/bloc/party_invoice_cubit.dart';


final GetIt sl = GetIt.instance;

Future<void> initServicesLocator() async {
  // External dependencies
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);

  sl.registerLazySingleton(() => InternetConnectionChecker.createInstance());

  // Initialize Supabase
  await Supabase.initialize(
    url: ApiConstants.supabaseUrl,
    anonKey: ApiConstants.supabaseAnonKey,
  );
  sl.registerLazySingleton(() => Supabase.instance.client);

  // Core utilities
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));
  // sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl());

  sl.registerLazySingleton(() => AppUtils());
  sl.registerLazySingleton(() => UserService());
  // Database
  final db = await AppDatabase.create();
  sl.registerSingleton<AppDatabase>(db);

  // Local datasources
  sl.registerLazySingleton<InvoiceLocalDataSource>(
    () => InvoiceLocalDataSourceImpl(sl()),
  );

  sl.registerLazySingleton<CustomerDebtLocalDataSource>(
    () => CustomerDebtLocalDataSourceImpl(sl()),
  );

  // Auth
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(sl()),
  );

  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(sl()),
  );

  sl.registerLazySingleton<AuthRepository>(() => AuthRepository(sl(), sl(),sl()));

  sl.registerFactory(() => AuthCubit(authRepository: sl()));

  // Products
  sl.registerLazySingleton<ProductRemoteDataSource>(
    () => ProductRemoteDataSourceImpl(sl()),
  );

  sl.registerLazySingleton<ProductRepository>(
    () => ProductRepository(sl(), sl()),
  );

  sl.registerFactory(() => ProductCubit(productRepository: sl()));

  // Invoices
  sl.registerLazySingleton<InvoiceRemoteDataSource>(
    () => InvoiceRemoteDataSourceImpl(sl()),
  );

  sl.registerLazySingleton<EditInvoiceDataSource>(
    () => EditInvoiceDataSourceImpl(sl()),
  );

  sl.registerLazySingleton<InvoiceRepository>(
    () => InvoiceRepositoryImpl(sl(), sl(), sl()),
  );

  sl.registerLazySingleton<EditInvoiceRepository>(
    () => EditInvoiceRepositoryImpl(sl()),
  );

  sl.registerFactory(() => InvoiceCubit(sl()));
  sl.registerFactory(() => EditInvoiceCubit(sl()));

  // Customers
  sl.registerLazySingleton<CustomerRemoteDataSource>(
    () => CustomerRemoteDataSourceImpl(sl()),
  );

  sl.registerLazySingleton<CustomerRepository>(
    () => CustomerRepository(sl(), sl()),
  );

  sl.registerFactory(() => CustomerCubit(customerRepository: sl()));

  // Customer Debts
  sl.registerLazySingleton<CustomerDebtRemoteDataSource>(
    () => CustomerDebtRemoteDataSource(sl()),
  );

  sl.registerLazySingleton<CustomerDebtRepository>(
    () => CustomerDebtRepositoryImpl(sl(), sl(), sl()),
  );

  sl.registerFactory(() => CustomerDebtCubit(repository: sl()));
  // Suppliers
  sl.registerLazySingleton<SupplierRemoteDataSource>(
    () => SupplierRemoteDataSourceImpl(sl()),
  );

  sl.registerLazySingleton<SupplierRepository>(
    () => SupplierRepository(sl(), sl()),
  );

  sl.registerFactory(() => SupplierCubit(supplierRepository: sl()));

  // Supplier Debts
  sl.registerLazySingleton<SupplierDebtRemoteDataSource>(
    () => SupplierDebtRemoteDataSource(sl()),
  );

  sl.registerLazySingleton<SupplierDebtRepository>(
    () => SupplierDebtRepositoryImpl(sl(), sl()),
  );

  sl.registerFactory(() => SupplierDebtCubit(repository: sl()));

  // Expenses
  sl.registerLazySingleton<ExpenseRemoteDataSource>(
    () => ExpenseRemoteDataSourceImpl(sl()),
  );

  sl.registerLazySingleton<ExpenseRepository>(
    () => ExpenseRepository(sl(), sl()),
  );

  sl.registerFactory(() => ExpenseCubit(expenseRepository: sl()));

  // Withdrawals
  sl.registerLazySingleton<WithdrawalRemoteDataSource>(
    () => WithdrawalRemoteDataSourceImpl(sl()),
  );

  sl.registerLazySingleton<WithdrawalRepository>(
    () => WithdrawalRepository(sl(), sl()),
  );

  sl.registerFactory(() => WithdrawalCubit(withdrawalRepository: sl()));

  // Dashboard
  sl.registerLazySingleton<DashboardRemoteDataSource>(
    () => DashboardRemoteDataSourceImpl(sl()),
  );

  sl.registerLazySingleton<DashboardLocalDataSource>(
    () => DashboardLocalDataSourceImpl(sl()),
  );

  sl.registerLazySingleton<DashboardRepository>(
    () => DashboardRepository(sl(), sl(), sl()),
  );

  sl.registerFactory(() => DashboardCubit(
    dashboardRepository: sl(),
  ));

  // Reports
  sl.registerLazySingleton<ReportRemoteDataSource>(
    () => ReportRemoteDataSourceImpl(sl()),
  );

  sl.registerLazySingleton<ReportRepository>(
    () => ReportRepositoryImpl(sl()),
  );

  sl.registerFactory(() => PartyInvoiceCubit(sl()));

}
