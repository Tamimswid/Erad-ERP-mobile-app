import 'package:erad/features/invoices/data/repositories/invoice_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/services_locator.dart' as sl;
import '../../../../core/constants/app_constants.dart';
import '../bloc/invoice_cubit.dart';
import '../widgets/combined_invoice_info_widget.dart';
import '../widgets/invoice_dates_widget.dart';
import '../widgets/product_add_widget.dart';
import '../widgets/invoice_summary_widget.dart';
import '../widgets/invoice_actions_widget.dart';
import '../../../products/presentation/bloc/product_cubit.dart';
import '../../../products/data/repositories/product_repository.dart';
import '../../../customers/presentation/bloc/customer_cubit.dart';
import '../../../customers/data/repositories/customer_repository.dart';
import '../../../suppliers/presentation/bloc/supplier_cubit.dart';
import '../../../suppliers/data/repositories/supplier_repository.dart';

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
          create: (context) => InvoiceCubit(sl.sl<InvoiceRepository>()),
        ),
        BlocProvider(
          create: (context) =>
              ProductCubit(productRepository: sl.sl<ProductRepository>()),
        ),
        BlocProvider(
          create: (context) =>
              CustomerCubit(customerRepository: sl.sl<CustomerRepository>()),
        ),
        BlocProvider(
          create: (context) =>
              SupplierCubit(supplierRepository: sl.sl<SupplierRepository>()),
        ),
      ],
      child: const _CreateInvoicePageContent(),
    );
  }
}

class _CreateInvoicePageContent extends StatefulWidget {
  const _CreateInvoicePageContent();

  @override
  State<_CreateInvoicePageContent> createState() => _CreateInvoicePageContentState();
}

class _CreateInvoicePageContentState extends State<_CreateInvoicePageContent> {
  @override
  Widget build(BuildContext context) {
    
    return BlocListener<InvoiceCubit, InvoiceState>(
      listener: (context, state) {
        if (state is InvoiceFormUpdated) {
          setState(() {});
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text(
            'إنشاء فاتورة جديدة',
            style: TextStyle(
              fontWeight: AppFonts.fontWeightBold,
              color: AppColors.text,
            ),
          ),
          backgroundColor: AppColors.background,
          elevation: 0,
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: AppConstants.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CombinedInvoiceInfoWidget(),
              const SizedBox(height: 16),

              InvoiceDatesWidget(),
              const SizedBox(height: 16),
              const ProductAddWidget(),
              const SizedBox(height: 16),
              const InvoiceSummaryWidget(),
              const SizedBox(height: 16),
              const InvoiceActionsWidget(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}