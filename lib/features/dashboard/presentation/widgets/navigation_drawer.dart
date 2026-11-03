import 'package:flutter/material.dart' as material;
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import 'package:erad/core/constants/app_constants.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;

class AppNavigationDrawer extends StatelessWidget {
  const AppNavigationDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return material.Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          BlocBuilder<AuthCubit, AuthState>(
            builder: (context, state) {
              if (state is Authenticated) {
                return material.UserAccountsDrawerHeader(
                  accountName: material.Text(state.user.fullName ?? state.user.email),
                  accountEmail: material.Text(state.user.email),
                  currentAccountPicture: material.CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor,
                    child: material.Text(
                      state.user.email.isNotEmpty
                          ? state.user.email[0].toUpperCase()
                          : 'U',
                      style: const material.TextStyle(
                        color: AppColors.surface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }
              return const material.DrawerHeader(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                ),
                child: Text(
                  'ERAD',
                  style: TextStyle(
                    color: AppColors.surface,
                    fontSize: 24,
                  ),
                ),
              );
            },
          ),
          material.ListTile(
            leading: const material.Icon(material.Icons.dashboard),
            title: const material.Text('لوحة التحكم'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          material.ListTile(
            leading: const material.Icon(material.Icons.people),
            title: const material.Text('العملاء'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/customers');
            },
          ),
          ListTile(
            leading: const Icon(sc.LucideIcons.package),
            title: const Text('المنتجات'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/products');
            },
          ),
          ListTile(
            leading: const Icon(sc.LucideIcons.receipt),
            title: const Text('الفواتير'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/invoices');
            },
            subtitle: const Text('المبيعات والشراء'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(sc.LucideIcons.chartColumn),
            title: const Text('التحليلات'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/analytics');
            },
          ),
          ListTile(
            leading: const Icon(sc.LucideIcons.building2),
            title: const Text('الموردون'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/suppliers');
            },
          ),
          ListTile(
            leading: const Icon(sc.LucideIcons.banknote),
            title: const Text('المصروفات'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/expenses');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(sc.LucideIcons.settings),
            title: const Text('الإعدادات'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/settings');
            },
          ),
          ListTile(
            leading: const Icon(sc.LucideIcons.logOut),
            title: const Text('تسجيل الخروج'),
            onTap: () {
              Navigator.pop(context);
              context.read<AuthCubit>().logout();
            },
          ),
        ],
      ),
    );
  }
}
