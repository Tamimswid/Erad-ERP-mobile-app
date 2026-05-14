import 'package:erad/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';

class CustomAppDrawer extends StatelessWidget {
  const CustomAppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.72,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildHeader(context),
                _buildMenuItem(
                  context,
                  icon: Iconsax.home,
                  title: 'لوحة المعلومات',
                  route: AppRoutes.dashboard,
                ),
                _buildDivider(),
                _buildMenuItem(
                  context,
                  icon: Iconsax.receipt,
                  title: 'الفواتير',
                  route: AppRoutes.invoices,
                ),
                _buildMenuItem(
                  context,
                  icon: Iconsax.box,
                  title: 'المنتجات',
                  route: AppRoutes.products,
                ),
                _buildMenuItem(
                  context,
                  icon: Iconsax.profile_2user,
                  title: 'العملاء',
                  route: AppRoutes.customers,
                ),
                _buildMenuItem(
                  context,
                  icon: Iconsax.shop,
                  title: 'الموردون',
                  route: AppRoutes.suppliers,
                ),
                _buildDivider(),
                _buildMenuItem(
                  context,
                  icon: Iconsax.money_recive,
                  title: 'الانسحابات',
                  route: AppRoutes.withdrawals,
                ),
                _buildMenuItem(
                  context,
                  icon: Iconsax.money_send,
                  title: 'النفقات',
                  route: AppRoutes.expenses,
                ),
                _buildMenuItem(
                  context,
                  icon: Iconsax.money,
                  title: 'ديون العملاء',
                  route: AppRoutes.customerDebts,
                ),
                _buildDivider(),
                _buildMenuItem(
                  context,
                  icon: Iconsax.setting_2,
                  title: 'الإعدادات',
                  route: AppRoutes.settings,
                ),
              ],
            ),
          ),
          _buildLogoutButton(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, Color(0xFF2563EB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 20,
            bottom: 24,
            left: 20,
            right: 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        'E',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.appName,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        AppStrings.appSubtitle,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (state is Authenticated) ...[
                const SizedBox(height: 20),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      child: Text(
                        state.user.email.isNotEmpty
                            ? state.user.email[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            state.user.fullName ?? state.user.email,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            state.user.email,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 11,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
  }) {
    final isActive = ModalRoute.of(context)?.settings.name == route;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary.withValues(alpha: 0.1) : null,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          size: 22,
          color: isActive ? AppColors.primary : AppColors.textSecondary,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isActive ? AppColors.primary : AppColors.text,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            fontSize: 15,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        dense: true,
        horizontalTitleGap: 8,
        onTap: () {
          Navigator.pop(context);
          if (route != AppRoutes.dashboard) {
            Navigator.pushNamed(context, route);
          }
        },
      ),
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Divider(color: AppColors.divider, height: 1),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(color: AppColors.divider),
        ),
      ),
      child: ListTile(
        leading: const Icon(Iconsax.logout, size: 22, color: AppColors.error),
        title: const Text(
          AppStrings.logout,
          style: TextStyle(
            color: AppColors.error,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        dense: true,
        horizontalTitleGap: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        onTap: () {
          Navigator.pop(context);
          context.read<AuthCubit>().logout();
        },
      ),
    );
  }
}
