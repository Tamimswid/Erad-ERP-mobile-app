import 'dart:async';

import 'package:erad/features/dashboard/presentation/pages/more_page.dart';
import 'package:erad/features/debts/presentation/pages/debts_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;

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
  final IconData icon;
  final int index;

  const MenuItem({required this.title, required this.icon, required this.index});
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
      return const [
        MenuItem(title: 'الرئيسية', icon: sc.LucideIcons.house, index: 0),
        MenuItem(title: 'الفواتير', icon: sc.LucideIcons.fileText, index: 1),
        MenuItem(title: 'الديون', icon: sc.LucideIcons.wallet, index: 2),
        MenuItem(title: 'المزيد', icon: sc.LucideIcons.ellipsis, index: 3),
      ];
    }
    return const [
      MenuItem(title: 'الرئيسية', icon: sc.LucideIcons.house, index: 0),
      MenuItem(title: 'الفواتير', icon: sc.LucideIcons.fileText, index: 1),
      MenuItem(title: 'الديون', icon: sc.LucideIcons.wallet, index: 2),
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
          if (!connected && _selectedIndex > 2) {
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
    final colors = sc.Theme.of(context).colorScheme;
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => sl.sl<InvoiceCubit>(), lazy: true),
        BlocProvider(create: (context) => sl.sl<ProductCubit>(), lazy: true),
        BlocProvider(create: (context) => sl.sl<CustomerCubit>(), lazy: true),
        BlocProvider(create: (context) => sl.sl<SupplierCubit>(), lazy: true),
      ],
      child: _isKeyboardVisible
          ? _buildContent()
          : Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: BottomBar(
                // body: const SizedBox.shrink(),
                showIcon: false,
                layout: const BottomBarLayout(
                  width: double.infinity,
                  offset: 12,
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
                theme: BottomBarThemeData(
                  barDecoration: BoxDecoration(
                    color: colors.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: colors.border),
                  ),
                ),
                body: IndexedStack(index: _selectedIndex, children: [for (final item in _menuItems) _buildContent()]),
                child: SizedBox(
                  height: 64,
                  child: BottomBarItems(
                    children: [
                      for (final item in _menuItems)
                        BottomBarItem(
                          icon: Icon(item.icon, size: 20),
                          label: Text(item.title),
                          selected: item.index == _selectedIndex,
                          selectedColor: colors.primary,
                          color: colors.mutedForeground,
                          onTap: () => setState(() => _selectedIndex = item.index),
                        ),
                    ],
                  ),
                ),
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
          return const InvoicesPage(isLocal: false);
        case 2:
          return const DebtsPage(isLocal: false);
        case 3:
          return MorePage();
        default:
          return const DashboardOverview();
      }
    }
    switch (_selectedIndex) {
      case 0:
        return const DashboardOverview();
      case 1:
        return const InvoicesPage(isLocal: true);
      case 2:
        return const DebtsPage(isLocal: true);
      default:
        return const DashboardOverview();
    }
  }
}
