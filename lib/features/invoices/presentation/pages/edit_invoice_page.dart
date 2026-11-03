import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;
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
    return BlocConsumer<EditInvoiceCubit, EditInvoiceState>(
      listener: (context, state) {
        if (state is EditInvoiceUpdated) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
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
          return sc.Scaffold(
            headers: [
              sc.AppBar(title: const Text('تعديل الفاتورة')),
            ],
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (state is EditInvoiceLoaded) {
          return sc.Scaffold(
            headers: [
              sc.AppBar(
                title: Text(
                  widget.isSales ? 'تعديل فاتورة البيع' : 'تعديل فاتورة الشراء',
                ),
                leading: [
                  sc.IconButton(
                    variance: sc.ButtonStyle.ghost(),
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(sc.LucideIcons.arrowRight),
                  ),
                ],
              ),
            ],
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
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

        return sc.Scaffold(
          headers: [
            sc.AppBar(title: const Text('تعديل الفاتورة')),
          ],
          child: const Center(child: Text('جاري تحميل الفاتورة...')),
        );
      },
    );
  }
}