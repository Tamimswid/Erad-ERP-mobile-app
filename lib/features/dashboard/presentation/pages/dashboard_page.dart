import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/services_locator.dart' as sl;
import '../../../auth/data/models/user.dart';
import '../../../customers/presentation/bloc/customer_cubit.dart';
import '../../../customers/presentation/pages/customers_page.dart';
import '../../../expenses/presentation/bloc/expense_cubit.dart';
import '../../../expenses/presentation/pages/expenses_page.dart';
import '../../../invoices/presentation/bloc/invoice_cubit.dart';
import '../../../invoices/presentation/pages/invoices_page.dart';
import '../../../products/presentation/bloc/product_cubit.dart';
import '../../../products/presentation/pages/products_page.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../../../suppliers/presentation/bloc/supplier_cubit.dart';
import '../../../suppliers/presentation/pages/suppliers_page.dart';
import '../../../withdrawals/presentation/bloc/withdrawal_cubit.dart';
import '../../../withdrawals/presentation/pages/withdrawals_page.dart';
import '../../../customer_debts/presentation/pages/customer_debts_page.dart';
import '../widgets/app_sidebar.dart';
import 'dashboard_overview.dart';

class DashboardPage extends StatefulWidget {
  // final User user;

  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  final Map<int, bool> _loadedTabs = {};


  final List<MenuItem> _menuItems = [
    const MenuItem(icon: Icons.dashboard_outlined, title: 'لوحة التحكم', index: 0),
    const MenuItem(icon: Icons.inventory_2_outlined, title: 'المنتجات', index: 1),
    const MenuItem(icon: Icons.people_outline, title: 'العملاء', index: 2),
    const MenuItem(icon: Icons.receipt_long_outlined, title: 'الفواتير', index: 3),
    const MenuItem(icon: Icons.business_outlined, title: 'الموردون', index: 4),
    const MenuItem(icon: Icons.money_off_outlined, title: 'المصروفات', index: 5),
    const MenuItem(icon: Icons.account_balance_wallet_outlined, title: 'السحوبات', index: 6),
    const MenuItem(icon: Icons.account_balance_wallet_outlined, title: 'الديون', index: 7),
    const MenuItem(icon: Icons.settings_outlined, title: 'الإعدادات', index: 8),
  ];

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => sl.sl<InvoiceCubit>(), lazy: true),
        BlocProvider(create: (context) => sl.sl<ProductCubit>(), lazy: true),
        BlocProvider(create: (context) => sl.sl<CustomerCubit>(), lazy: true),
        BlocProvider(create: (context) => sl.sl<SupplierCubit>(), lazy: true),
        BlocProvider(create: (context) => sl.sl<ExpenseCubit>(), lazy: true),
        BlocProvider(create: (context) => sl.sl<WithdrawalCubit>(), lazy: true),
      ],
      child: Scaffold(
        body: Row(
          children: [
            // Sol sidebar
            AppSidebar(
              
              selectedIndex: _selectedIndex,
              menuItems: _menuItems,
              onItemSelected: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
            ),
            // Sağ ana içerik
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return const DashboardOverview();
      case 1:
        return Builder(
          builder: (ctx) {
            if (_loadedTabs[1] != true) {
              _loadedTabs[1] = true;
              ctx.read<ProductCubit>().getProducts();
            }
            return const ProductsPage();
          },
        );
      case 2:
        return Builder(
          builder: (ctx) {
            if (_loadedTabs[2] != true) {
              _loadedTabs[2] = true;
              ctx.read<CustomerCubit>().getCustomers();
            }
            return const CustomersPage();
          },
        );
      case 3:
        return const InvoicesPage();
      case 4:
        return Builder(
          builder: (ctx) {
            if (_loadedTabs[4] != true) {
              _loadedTabs[4] = true;
              ctx.read<SupplierCubit>().getSuppliers();
            }
            return const SuppliersPage();
          },
        );
      case 5:
        return const ExpensesPage();
      case 6:
        return Builder(
          builder: (ctx) {
            if (_loadedTabs[6] != true) {
              _loadedTabs[6] = true;
              ctx.read<WithdrawalCubit>().getWithdrawals();
            }
            return const WithdrawalsPage();
          },
        );
      case 7:
        return const CustomerDebtsPage();
      case 8:
        return const SettingsPage();
      default:
        return const DashboardOverview();
    }
  }
}
