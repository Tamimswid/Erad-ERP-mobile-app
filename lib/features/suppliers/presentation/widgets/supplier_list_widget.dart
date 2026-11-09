import 'package:erad/core/constants/app_constants.dart';
import 'package:erad/core/widgets/app_pagination_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;
import '../../data/models/supplier.dart';
import '../bloc/supplier_cubit.dart';
import 'supplier_form_widget.dart';

class SupplierListWidget extends StatelessWidget {
  const SupplierListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SupplierCubit, SupplierState>(
      builder: (context, state) {
        if (state is SupplierLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is SuppliersLoaded) {
          if (state.suppliers.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    sc.LucideIcons.building2,
                    size: 64,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(height: 16),
                  Text('لا يوجد موردون'),
                  SizedBox(height: 8),
                  Text('اضف مورد جديد للبدء'),
                ],
              ),
            );
          }

          return AppPaginationGrid(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 1,
              childAspectRatio: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
            ),
            itemCount: state.suppliers.length,
            hasMore: state.hasMore,
            isLoadingMore: state.isLoadingMore,
            onLoadMore: context.read<SupplierCubit>().loadMore,
            itemBuilder: (context, index) {
              final supplier = state.suppliers[index];
              return SupplierCard(
                supplier: supplier,
                onSupplierDeleted: (supplierId) =>
                    context.read<SupplierCubit>().deleteSupplier(supplierId),
                onSupplierEdit: (supplier) =>
                    context.read<SupplierCubit>().updateSupplier(supplier),
              );
            },
          );
        } else if (state is SupplierError) {
          return Center(child: Text(state.message));
        } else if (state is SupplierInitial) {
          return const Center(child: CircularProgressIndicator());
        }

        return const Center(child: Text('Unknown state'));
      },
    );
  }
}

class SupplierCard extends StatelessWidget {
  final SupplierModel supplier;
  final Function(String id) onSupplierDeleted;
  final Function(SupplierModel updatedSupplier) onSupplierEdit;

  const SupplierCard({
    super.key,
    required this.supplier,
    required this.onSupplierDeleted,
    required this.onSupplierEdit,
  });

  @override
  Widget build(BuildContext context) {
    final cityLabel = supplier.cityName ?? supplier.city;
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
                  supplier.name.isNotEmpty
                      ? supplier.name[0].toUpperCase()
                      : 'S',
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
                      supplier.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (supplier.phone != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        supplier.phone!,
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
                    onPressed: () => _showEditSupplierDialog(
                      context,
                      supplier,
                      (updatedSupplier) => onSupplierEdit(updatedSupplier),
                    ),
                    tooltip: 'Düzenle',
                  ),
                  IconButton(
                    icon: const Icon(sc.LucideIcons.trash2, size: 20),
                    onPressed: () => _showDeleteConfirmation(
                      context: context,
                      supplier: supplier,
                      onSupplierDeleted: (id) => onSupplierDeleted(id),
                    ),
                    tooltip: 'Sil',
                  ),
                ],
              ),
            ],
          ),
          if (cityLabel != null) ...[
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
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showEditSupplierDialog(
    BuildContext context,
    SupplierModel supplier,
    Function(SupplierModel updatedSupplier) onSupplierUpdated,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل المورد'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 500,
                child: SupplierFormWidget(
                  supplier: supplier,
                  onSubmit: (updatedSupplier) {
                    onSupplierUpdated(updatedSupplier);
                    Navigator.pop(context);
                  },
                ),
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
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation({
    required BuildContext context,
    required SupplierModel supplier,
    required Function(String id) onSupplierDeleted,
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
              Text('هل أنت متأكد من حذف المورد ${supplier.name}؟'),
              const SizedBox(height: 12),
              const Text(
                'سيتم حذف جميع البيانات المرتبطة بهذا المورد:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('• فواتير الشراء'),
              const Text('• عناصر فواتير الشراء'),
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
                      onSupplierDeleted(supplier.id);
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
