import 'package:erad/core/constants/app_constants.dart';
import 'package:erad/core/widgets/app_pagination_list.dart';
import 'package:erad/features/customers/data/models/customer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;
import '../bloc/customer_cubit.dart';
import 'customer_form_widget.dart';

class CustomerListWidget extends StatelessWidget {
  const CustomerListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CustomerCubit, CustomerState>(
      builder: (context, state) {
        if (state is CustomerLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is CustomerLoaded) {
          if (state.customers.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    sc.LucideIcons.users,
                    size: 64,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(height: 16),
                  Text('لا يوجد عملاء'),
                  SizedBox(height: 8),
                  Text('اضف عميل جديد للبدء'),
                ],
              ),
            );
          }

          return AppPaginationGrid(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 1,
              childAspectRatio: 1.7,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
            ),
            itemCount: state.customers.length,
            hasMore: state.hasMore,
            isLoadingMore: state.isLoadingMore,
            onLoadMore: context.read<CustomerCubit>().loadMore,
            itemBuilder: (context, index) {
              final customer = state.customers[index];
              return CustomerCard(
                customer: customer,
                onCustomerDeleted: (customerId) =>
                    context.read<CustomerCubit>().deleteCustomer(customerId),
                onCustomerEdit: (customerModel) =>
                    context.read<CustomerCubit>().updateCustomer(customerModel),
              );
            },
          );
        } else if (state is CustomerError) {
          return Center(child: Text(state.message));
        } else if (state is CustomerInitial || state is CustomerLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return const Center(child: Text('Unknown state'));
      },
    );
  }
}

class CustomerCard extends StatelessWidget {
  final CustomerModel customer;
  final Function(String customerId) onCustomerDeleted;
  final Function(CustomerModel customerModel) onCustomerEdit;

  const CustomerCard({
    super.key,
    required this.customer,
    required this.onCustomerDeleted,
    required this.onCustomerEdit,
  });

  @override
  Widget build(BuildContext context) {
    final cityLabel = customer.cityName ?? customer.city;
    return sc.Card(
      padding: const EdgeInsets.all(16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor,
                radius: 24,
                child: Text(
                  customer.name.isNotEmpty
                      ? customer.name[0].toUpperCase()
                      : 'C',
                  style: const TextStyle(
                    color: AppColors.onPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (customer.phone != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        customer.phone!,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(sc.LucideIcons.pencil, size: 20),
                    onPressed: () => _showEditCustomerDialog(
                      context: context,
                      customer: customer,
                      onCustomerEdit: (customerModel) =>
                          onCustomerEdit(customerModel),
                    ),
                    tooltip: 'يحرر',
                  ),
                  IconButton(
                    icon: const Icon(sc.LucideIcons.trash2, size: 20),
                    onPressed: () => _showDeleteConfirmation(
                      context: context,
                      customer: customer,
                      onCustomerDeleted: (customerId) =>
                          onCustomerDeleted(customerId),
                    ),
                    tooltip: 'سيل',
                  ),
                ],
              ),
            ],
          ),
          if (cityLabel != null || customer.address != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.muted,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (cityLabel != null)
                    Row(
                      children: [
                        Icon(
                          sc.LucideIcons.building2,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          cityLabel,
                          style: TextStyle(fontSize: 14, color: AppColors.text),
                        ),
                      ],
                    ),
                  if (cityLabel != null && customer.address != null)
                    const SizedBox(height: 4),
                  if (customer.address != null)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          sc.LucideIcons.mapPin,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            customer.address!,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.text,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showEditCustomerDialog({
    required BuildContext context,
    required CustomerModel customer,
    required Function(CustomerModel customerModel) onCustomerEdit,
  }) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: SizedBox(
          width: 500,
          height: MediaQuery.of(context).size.height * 0.45,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'تعديل العميل',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(sc.LucideIcons.x),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  CustomerFormWidget(
                    customerModel: customer,
                    onTap: (customerModel) {
                      onCustomerEdit(customerModel);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation({
    required BuildContext context,
    required CustomerModel customer,
    required Function(String customerId) onCustomerDeleted,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(sc.LucideIcons.triangleAlert, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            const Text('تأكيد الحذف'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('هل أنت متأكد من حذف العميل ${customer.name}؟'),
              const SizedBox(height: 12),
              const Text(
                'سيتم حذف جميع البيانات المرتبطة بهذا العميل:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('• فواتير البيع'),
              const Text('• عناصر فواتير البيع'),
              const Text('• الدفعات'),
              const SizedBox(height: 8),
              const Text(
                'هذا الإجراء لا يمكن التراجع عنه',
                style: TextStyle(color: AppColors.error, fontSize: 12),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  sc.Button(
                    alignment: Alignment.center,
                    style: sc.ButtonStyle.ghost(),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('إلغاء'),
                  ),
                  const SizedBox(width: 8),
                  sc.Button(
                    alignment: Alignment.center,
                    style: sc.ButtonStyle.destructive(),
                    onPressed: () {
                      Navigator.pop(context);
                      onCustomerDeleted(customer.id);
                    },
                    child: const Text('حذف'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
