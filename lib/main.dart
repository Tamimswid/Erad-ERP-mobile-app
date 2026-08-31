import 'package:erad/core/constants/app_constants.dart';
import 'package:erad/core/di/services_locator.dart' as sl;
import 'package:erad/core/utils/number_formatter.dart';
import 'package:erad/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:erad/features/auth/presentation/pages/login_page.dart';
import 'package:erad/features/customers/presentation/pages/customers_page.dart';
import 'package:erad/features/customer_debts/presentation/pages/customer_debts_page.dart';
import 'package:erad/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:erad/features/expenses/presentation/pages/expenses_page.dart';
import 'package:erad/features/invoices/presentation/bloc/invoice_cubit.dart';
import 'package:erad/features/invoices/presentation/pages/invoices_page.dart';
import 'package:erad/features/products/presentation/pages/products_page.dart';
import 'package:erad/features/settings/presentation/pages/settings_page.dart';
import 'package:erad/features/reports/presentation/pages/takrirler_page.dart';
import 'package:erad/features/suppliers/presentation/pages/suppliers_page.dart';
import 'package:erad/features/withdrawals/presentation/pages/withdrawals_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await sl.initServicesLocator();
  await NumberFormatter.initialize();
  await NumberFormatter.setArabicFormat(true);
  await initializeDateFormatting('en');

  runApp(
    BlocProvider(
      create: (_) => sl.sl<AuthCubit>()..getCurrentUser(),
      child: const ERADApp(),
    ),
  );
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
      builder: (context, child) {
        final MediaQueryData data = MediaQuery.of(context);

        // 1. Önce font ölçeğini güncelliyoruz
        final MediaQuery updatedMediaQuery = MediaQuery(
          data: data.copyWith(
            textScaler: data.textScaler.clamp(
              minScaleFactor: 0.8,
              maxScaleFactor: 1.0,
            ),
          ),
          child: child!,
        );

        return Directionality(
          textDirection: TextDirection.rtl,
          child: updatedMediaQuery,
        );
      },

      home: const MainWrapper(),
      onGenerateRoute: _generateRoute,
    );
  }

  Route<dynamic>? _generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.products:
        return MaterialPageRoute(builder: (_) => const ProductsPage());
      case AppRoutes.customers:
        return MaterialPageRoute(builder: (_) => const CustomersPage());
      case AppRoutes.invoices:
        return MaterialPageRoute(
          builder: (context) => BlocProvider(
            create: (_) => sl.sl<InvoiceCubit>(),
            child: const InvoicesPage(),
          ),
        );
      case AppRoutes.suppliers:
        return MaterialPageRoute(builder: (_) => const SuppliersPage());
      case AppRoutes.expenses:
        return MaterialPageRoute(builder: (_) => const ExpensesPage());
      case AppRoutes.withdrawals:
        return MaterialPageRoute(builder: (_) => const WithdrawalsPage());
      case AppRoutes.settings:
        return MaterialPageRoute(
          builder: (context) => BlocProvider.value(
            value: context.read<AuthCubit>(),
            child: const SettingsPage(),
          ),
        );
      case AppRoutes.customerDebts:
        return MaterialPageRoute(builder: (_) => const CustomerDebtsPage());
      case AppRoutes.takrirler:
        return MaterialPageRoute(builder: (_) => const TakrirlerPage());
      default:
        return MaterialPageRoute(builder: (_) => const DashboardPage());
    }
  }
}

class MainWrapper extends StatelessWidget {
  const MainWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        if (authState is AuthLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (authState is Authenticated) {
          return const DashboardPage();
        }

        return const LoginPage();
      },
    );
  }
}
