import 'package:erad/core/constants/app_constants.dart';
import 'package:erad/core/di/services_locator.dart' as sl;
import 'package:erad/core/notifications/data_change_notifier.dart';
import 'package:erad/features/customers/data/repositories/customer_repository.dart';
import 'package:erad/features/customers/presentation/bloc/customer_cubit.dart';
import 'package:erad/features/invoices/data/repositories/invoice_repository.dart';
import 'package:erad/features/invoices/presentation/bloc/invoice_cubit.dart';
import 'package:erad/features/invoices/presentation/widgets/combined_invoice_info_widget.dart';
import 'package:erad/features/invoices/presentation/widgets/invoice_actions_widget.dart';
import 'package:erad/features/invoices/presentation/widgets/invoice_summary_widget.dart';
import 'package:erad/features/invoices/presentation/widgets/product_add_widget.dart';
import 'package:erad/features/products/data/repositories/product_repository.dart';
import 'package:erad/features/products/presentation/bloc/product_cubit.dart';
import 'package:erad/features/suppliers/data/repositories/supplier_repository.dart';
import 'package:erad/features/suppliers/presentation/bloc/supplier_cubit.dart';
import 'package:erad/features/voice_invoice/presentation/widgets/voice_invoice_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;

class CreateInvoicePage extends StatefulWidget {
  const CreateInvoicePage({super.key});

  @override
  State<CreateInvoicePage> createState() => _CreateInvoicePageState();
}

class _CreateInvoicePageState extends State<CreateInvoicePage> {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => InvoiceCubit(
            sl.sl<InvoiceRepository>(),
            sl.sl<DataChangeNotifier>(),
          ),
        ),
        BlocProvider(
          create: (context) => ProductCubit(
            productRepository: sl.sl<ProductRepository>(),
            dataChanges: sl.sl<DataChangeNotifier>(),
          ),
        ),
        BlocProvider(
          create: (context) => CustomerCubit(
            customerRepository: sl.sl<CustomerRepository>(),
            dataChanges: sl.sl<DataChangeNotifier>(),
          ),
        ),
        BlocProvider(
          create: (context) => SupplierCubit(
            supplierRepository: sl.sl<SupplierRepository>(),
            dataChanges: sl.sl<DataChangeNotifier>(),
          ),
        ),
      ],
      child: const _CreateInvoicePageContent(),
    );
  }
}

class _CreateInvoicePageContent extends StatefulWidget {
  const _CreateInvoicePageContent();

  @override
  State<_CreateInvoicePageContent> createState() =>
      _CreateInvoicePageContentState();
}

class _CreateInvoicePageContentState extends State<_CreateInvoicePageContent> {
  final _partySearchFocus = FocusNode();
  final _productSearchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _partySearchFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _partySearchFocus.dispose();
    _productSearchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return sc.Scaffold(
      headers: [
        sc.AppBar(
          title: const Text('فاتورة جديدة'),
          leading: [
            sc.IconButton(
              variance: sc.ButtonStyle.ghost(),
              onPressed: () => Navigator.pop(context),
              icon: const Icon(sc.LucideIcons.arrowRight, size: 22),
            ),
          ],
        ),
      ],
      child: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'voiceInvoiceFab',
          onPressed: () {
            FocusScope.of(context).unfocus();
            VoiceInvoiceSheet.show(
              context,
              invoiceCubit: context.read<InvoiceCubit>(),
            );
          },
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          icon: const Icon(sc.LucideIcons.mic, size: 20),
          label: const Text(
            'فاتورة بالصوت',
            style: TextStyle(
              color: AppColors.onPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CombinedInvoiceInfoWidget(
                partySearchFocusNode: _partySearchFocus,
                onPartySelected: _productSearchFocus.requestFocus,
              ),
              const SizedBox(height: 16),
              ProductAddWidget(searchFocusNode: _productSearchFocus),
              const SizedBox(height: 16),
              const InvoiceSummaryWidget(),
              const SizedBox(height: 16),
              const InvoiceActionsWidget(),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}
