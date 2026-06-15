import 'dart:async';
import 'package:erad/core/constants/app_constants.dart';
import 'package:erad/features/customer_debts/presentation/pages/customer_debts_page.dart';
import 'package:erad/features/dashboard/presentation/pages/more_page.dart';
import 'package:erad/features/suppliers_debts/presentation/pages/suppliers_debts_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/services_locator.dart' as sl;
import '../../../../core/network/network_info.dart';
import '../../../customers/presentation/bloc/customer_cubit.dart';
import '../../../invoices/presentation/bloc/invoice_cubit.dart';
import '../../../invoices/presentation/pages/invoices_page.dart';
import '../../../products/presentation/bloc/product_cubit.dart';
import '../../../suppliers/presentation/bloc/supplier_cubit.dart';
import 'dashboard_overview.dart';

class MenuItem {
  final String title;
  final int index;

  const MenuItem({
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

class _DashboardPageState extends State<DashboardPage> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  bool _isConnected = true;
  bool _isKeyboardVisible = false;
  StreamSubscription? _connectionSubscription;

  List<MenuItem> get _menuItems {
    if (_isConnected) {
      return [
        const MenuItem(title: 'الرئيسية', index: 0),
        const MenuItem(title: 'الفواتير', index: 1),
        const MenuItem(title: 'د.عملاء', index: 2),
        const MenuItem(title: 'د.موردين', index: 3),
        const MenuItem(title: 'المزيد', index: 4),
      ];
    }
    return [
      const MenuItem(title: 'الفواتير', index: 0),
      const MenuItem(title: 'ديون', index: 1),
    ];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkConnectivity();
  }

  @override
  void didChangeMetrics() {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final visible = bottom > 100;
    if (visible != _isKeyboardVisible) {
      setState(() => _isKeyboardVisible = visible);
    }
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
    WidgetsBinding.instance.removeObserver(this);
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
            if (!_isKeyboardVisible)
              Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                margin: EdgeInsets.fromLTRB(12, 0, 12, MediaQuery.of(context).padding.bottom > 0 ? 8 : 12),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusLg),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  child: Row(
                    children: List.generate(_menuItems.length, (index) {
                      final isSelected = index == _selectedIndex;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedIndex = index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.surface : Colors.transparent,
                              borderRadius: BorderRadius.circular(AppConstants.borderRadiusMd),
                            ),
                            child: Text(
                              _menuItems[index].title,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isSelected ? AppColors.primary : AppColors.surface,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
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
        case 3:
          return SuppliersDebtsPage();
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
