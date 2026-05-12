import 'package:erad/core/di/services_locator.dart' as sl;
import 'package:erad/core/utils/number_formatter.dart';
import 'package:erad/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:erad/features/auth/presentation/pages/login_page.dart';
import 'package:erad/features/dashboard/presentation/pages/dashboard_overview.dart';
import 'package:erad/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await sl.initServicesLocator();
  NumberFormatter.initialize();
  await NumberFormatter.setArabicFormat(true);
  await initializeDateFormatting('en');

  runApp(const ERADApp());
}

class ERADApp extends StatelessWidget {
  const ERADApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme.copyWith(
        textTheme: GoogleFonts.changaTextTheme(),
      ),
      locale: const Locale('ar'),
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child!,
      ),
      home: const DashboardOverview(),
    );
  }
}

class MainWrapper extends StatelessWidget {
  const MainWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl.sl<AuthCubit>()..getCurrentUser(),
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          if (authState is AuthLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (authState is Authenticated) {
            return AppStatusWrapper(user: authState.user);
          }

          return const LoginPage();
        },
      ),
    );
  }
}