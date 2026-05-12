import 'package:erad/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/di/services_locator.dart' as sl;
import '../../../customers/presentation/bloc/customer_cubit.dart';
import '../../../customers/presentation/pages/customers_page.dart';
import '../../../invoices/presentation/bloc/invoice_cubit.dart';
import '../../../invoices/presentation/pages/invoices_page.dart';
import '../../../products/presentation/bloc/product_cubit.dart';
import '../../../products/presentation/pages/products_page.dart';
import '../../../suppliers/presentation/bloc/supplier_cubit.dart';
import '../../../suppliers/presentation/pages/suppliers_page.dart';
import 'dashboard_overview.dart';

class MenuItem {
  final IconData icon;
  final String title;
  final int index;

  const MenuItem({
    required this.icon,
    required this.title,
    required this.index,
  });
}

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
    const MenuItem(
      icon: Iconsax.home,
      title: 'لوحة التحكم',
      index: 0,
    ),
    const MenuItem(
      icon: Iconsax.box,
      title: 'المنتجات',
      index: 1,
    ),
    const MenuItem(icon: Iconsax.user, title: 'العملاء', index: 2),
    const MenuItem(
      icon: Iconsax.document,
      title: 'الفواتير',
      index: 3,

    ),
    const MenuItem(icon: Iconsax.shop, title: 'الموردون', index: 4),
  ];

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => sl.sl<InvoiceCubit>(), lazy: true),
        BlocProvider(create: (context) => sl.sl<ProductCubit>(), lazy: true),
        BlocProvider(create: (context) => sl.sl<CustomerCubit>(), lazy: true),
        BlocProvider(create: (context) => sl.sl<SupplierCubit>(), lazy: true),
      ],
      child: Scaffold(
        bottomNavigationBar: NavigationBar(
          backgroundColor: AppColors.background,
          indicatorColor: AppColors.primary.withValues(alpha: 0.3),
          height: 70,
          overlayColor: WidgetStatePropertyAll<Color>(AppColors.primary.withValues(alpha: 0.5),),
          selectedIndex: _selectedIndex,
          shadowColor: AppColors.textSecondary,
          onDestinationSelected: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          destinations: _menuItems.map((item) => 
            NavigationDestination(
              
              icon: Icon(item.icon),
              label: item.title,
            ),
          ).toList(),
        ),
        body: _buildContent(),
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
      default:
        return const DashboardOverview();
    }
  }
}
