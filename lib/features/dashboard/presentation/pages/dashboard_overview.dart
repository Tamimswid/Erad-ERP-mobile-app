import 'package:erad/core/constants/app_constants.dart';
import 'package:erad/core/di/services_locator.dart' as sl;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;

import '../bloc/dashboard_cubit.dart';
import '../widgets/home_charts_card.dart';
import '../widgets/home_quick_actions.dart';
import '../widgets/home_summary_card.dart';

class DashboardOverview extends StatelessWidget {
  const DashboardOverview({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl.sl<DashboardCubit>(),
      child: const _DashboardOverviewView(),
    );
  }
}

class _DashboardOverviewView extends StatelessWidget {
  const _DashboardOverviewView();

  @override
  Widget build(BuildContext context) {
    return sc.Scaffold(
      headers: [
        sc.AppBar(
          title: const Text('الرئيسية'),
          trailing: [
            IconButton(
              tooltip: 'الإعدادات',
              onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
              icon: const Icon(sc.LucideIcons.settings, size: 20),
            ),
          ],
        ),
      ],
      child: BlocBuilder<DashboardCubit, DashboardState>(
        builder: (context, state) {
          if (state is DashboardLoading || state is DashboardInitial) {
            return const Center(child: sc.CircularProgressIndicator());
          }

          if (state is DashboardError) {
            return _ErrorView(message: state.message);
          }

          if (state is! DashboardLoaded) {
            return const SizedBox.shrink();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HomeSummaryCard(state: state),
                const SizedBox(height: 20),
                const HomeQuickActions(),
                const SizedBox(height: 16),
                const HomeChartsCard(),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;

  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    final scheme = sc.Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: scheme.destructive),
            ),
            const SizedBox(height: 12),
            sc.Button(
              style: const sc.ButtonStyle.outline(),
              onPressed: () => context.read<DashboardCubit>().retry(),
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}
