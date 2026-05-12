import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:erad/core/di/services_locator.dart' as sl;
import 'package:erad/features/app_status/presentation/bloc/app_status_cubit.dart';
import 'package:erad/features/app_status/presentation/pages/app_status_page.dart';
import 'package:erad/features/auth/data/models/user.dart';
import 'package:erad/features/auth/presentation/pages/login_page.dart';
import 'package:erad/features/dashboard/presentation/pages/dashboard_page.dart';

class AppStatusWrapper extends StatelessWidget {
  final User user;

  const AppStatusWrapper({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl.sl<AppStatusCubit>()..checkAppStatus(),
      child: BlocBuilder<AppStatusCubit, AppStatusState>(
        builder: (context, state) {
          if (state is AppStatusLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (state is AppStatusError) {
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64),
                    const SizedBox(height: 16),
                    Text('Error: ${state.message}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<AppStatusCubit>().checkAppStatus();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is AppStatusChecked) {
            if (state.isActive) {
              return DashboardPage();
            } else {
              return AppStatusPage();
            }
          }

          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }
}
