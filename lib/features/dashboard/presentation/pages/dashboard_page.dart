import 'dart:async';
import 'package:erad/core/constants/app_constants.dart';
import 'package:erad/features/customer_debts/presentation/pages/customer_debts_page.dart';
import 'package:erad/features/dashboard/presentation/pages/more_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/di/services_locator.dart' as sl;
import '../../../../core/network/network_info.dart';
import '../../../customers/presentation/bloc/customer_cubit.dart';
import '../../../invoices/presentation/bloc/invoice_cubit.dart';
import '../../../invoices/presentation/pages/invoices_page.dart';
import '../../../products/presentation/bloc/product_cubit.dart';
import '../../../suppliers/presentation/bloc/supplier_cubit.dart';
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
  bool _isConnected = true;
  StreamSubscription? _connectionSubscription;

  List<MenuItem> get _menuItems {
    if (_isConnected) {
      return [
        const MenuItem(icon: Iconsax.home, title: 'الرئيسية', index: 0),
        const MenuItem(icon: Iconsax.document, title: 'الفواتير', index: 1),
        const MenuItem(icon: Iconsax.wallet, title: 'ديون', index: 2),
        const MenuItem(icon: Iconsax.more, title: 'المزيد', index: 4),
      ];
    }
    return [
      const MenuItem(icon: Iconsax.document, title: 'الفواتير', index: 0),
      const MenuItem(icon: Iconsax.wallet, title: 'ديون', index: 1),
    ];
  }

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    final networkInfo = sl.sl<NetworkInfo>();
    final connected = await networkInfo.isConnected;
    if (mounted) {
      setState(() => _isConnected = connected);
    }
    _connectionSubscription = networkInfo.connectionStream.listen((connected) {
      if (mounted) {
        setState(() {
          _isConnected = connected;
          if (!connected && _selectedIndex > 1) {
            _selectedIndex = 0;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    super.dispose();
  }

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
        body: Stack(
          children: [
            _buildContent(),
            Positioned(
              bottom: 10,
              left: 10,
              right: 10,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(
                    AppConstants.borderRadiusLg,
                  ),
                ),
                padding: EdgeInsets.all(10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ...List.generate(
                      _menuItems.length,
                      (index) => GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedIndex = index;
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: index == _selectedIndex
                                ? AppColors.surface
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(
                              AppConstants.borderRadiusLg,
                            ),
                          ),
                          child: Text(
                            _menuItems[index].title,
                            style: TextStyle(
                              color: index == _selectedIndex
                                  ? AppColors.primary
                                  : AppColors.surface,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // _menuItems.map((e) => Text(e.title),)
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isConnected) {
      switch (_selectedIndex) {
        case 0:
          return const DashboardOverview();
        case 1:
          return const InvoicesPage();
        case 2:
          return const CustomerDebtsPage();
        case 4:
          return MorePage();
        default:
          return const DashboardOverview();
      }
    }
    switch (_selectedIndex) {
      case 0:
        return const InvoicesPage();
      case 1:
        return const CustomerDebtsPage();
      default:
        return const InvoicesPage();
    }
  }
}
