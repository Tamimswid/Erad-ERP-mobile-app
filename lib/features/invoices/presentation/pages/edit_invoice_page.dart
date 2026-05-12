import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/services_locator.dart' as sl;
import '../../../../core/constants/app_constants.dart';
import '../bloc/edit_invoice_cubit.dart';
import '../widgets/edit_invoice_type_widget.dart';
import '../widgets/edit_invoice_dates_widget.dart';
import '../widgets/edit_customer_supplier_widget.dart';
import '../widgets/edit_product_add_widget.dart';
import '../widgets/edit_invoice_summary_widget.dart';
import '../widgets/edit_invoice_actions_widget.dart';
import '../../../products/presentation/bloc/product_cubit.dart';
import '../../../products/data/repositories/product_repository.dart';
import '../../../customers/presentation/bloc/customer_cubit.dart';
import '../../../customers/data/repositories/customer_repository.dart';
import '../../../suppliers/presentation/bloc/supplier_cubit.dart';
import '../../../suppliers/data/repositories/supplier_repository.dart';

class EditInvoicePage extends StatefulWidget {
  final String invoiceId;
  final bool isSales;

  const EditInvoicePage({
    super.key,
    required this.invoiceId,
    required this.isSales,
  });

  @override
  State<EditInvoicePage> createState() => _EditInvoicePageState();
}

class _EditInvoicePageState extends State<EditInvoicePage> {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => sl.sl<EditInvoiceCubit>(),
        ),
        BlocProvider(
          create: (context) => ProductCubit(productRepository: sl.sl<ProductRepository>())..getProducts(),
        ),
        BlocProvider(
          create: (context) => CustomerCubit(customerRepository: sl.sl<CustomerRepository>())..getCustomers(),
        ),
        BlocProvider(
          create: (context) => SupplierCubit(supplierRepository: sl.sl<SupplierRepository>())..getSuppliers(),
        ),
      ],
      child: _EditInvoicePageContent(
        invoiceId: widget.invoiceId,
        isSales: widget.isSales,
      ),
    );
  }
}

class _EditInvoicePageContent extends StatefulWidget {
  final String invoiceId;
  final bool isSales;

  const _EditInvoicePageContent({
    required this.invoiceId,
    required this.isSales,
  });

  @override
  State<_EditInvoicePageContent> createState() => _EditInvoicePageContentState();
}

class _EditInvoicePageContentState extends State<_EditInvoicePageContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.isSales) {
        context.read<EditInvoiceCubit>().loadSalesInvoice(widget.invoiceId);
      } else {
        context.read<EditInvoiceCubit>().loadPurchaseInvoice(widget.invoiceId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final paddingSize = MediaQuery.of(context).size.width > 1200 ? 200.0 : 100.0;
    
    return BlocConsumer<EditInvoiceCubit, EditInvoiceState>(
      listener: (context, state) {
        if (state is EditInvoiceUpdated) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.of(context).pop(true);
        } else if (state is EditInvoiceError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is EditInvoiceLoading) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              title: const Text('تعديل الفاتورة'),
              backgroundColor: AppColors.background,
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (state is EditInvoiceLoaded) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              title: Text(
                widget.isSales ? 'تعديل فاتورة البيع' : 'تعديل فاتورة الشراء',
                style: TextStyle(
                  fontWeight: AppFonts.fontWeightBold,
                  color: AppColors.text,
                ),
              ),
              backgroundColor: AppColors.background,
              elevation: 0,
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: paddingSize),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: EditInvoiceTypeWidget(isSales: widget.isSales),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 1,
                        child: EditInvoiceDatesWidget(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  EditCustomerSupplierWidget(isSales: widget.isSales),
                  const SizedBox(height: 16),
                  const EditProductAddWidget(),
                  const SizedBox(height: 16),
                  const EditInvoiceSummaryWidget(),
                  const SizedBox(height: 16),
                  const EditInvoiceActionsWidget(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('تعديل الفاتورة'),
            backgroundColor: AppColors.background,
          ),
          body: const Center(child: Text('جاري تحميل الفاتورة...')),
        );
      },
    );
  }
}