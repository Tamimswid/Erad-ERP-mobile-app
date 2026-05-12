import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
                  Icon(Icons.business, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('لا يوجد موردون'),
                  SizedBox(height: 8),
                  Text('اضف مورد جديد للبدء'),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 1.5,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
            ),
            itemCount: state.suppliers.length,
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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  radius: 24,
                  child: Text(
                    supplier.name.isNotEmpty ? supplier.name[0].toUpperCase() : 'S',
                    style: const TextStyle(
                      color: Colors.white,
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
                            color: Colors.grey[600],
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
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () => _showEditSupplierDialog(context, supplier, (updatedSupplier) => onSupplierEdit(updatedSupplier)),
                      tooltip: 'Düzenle',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20),
                      onPressed: () => _showDeleteConfirmation(context: context, supplier: supplier, onSupplierDeleted:(id) =>  onSupplierDeleted(id)),
                      tooltip: 'Sil',
                    ),
                  ],
                ),
              ],
            ),
            if (supplier.city != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (supplier.city != null)
                      Row(
                        children: [
                          Icon(Icons.location_city, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Text(
                            supplier.city!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
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
      ),
    );
  }

  
  void _showEditSupplierDialog(BuildContext context, SupplierModel supplier, Function(SupplierModel updatedSupplier) onSupplierUpdated) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل المورد'),
        content: SizedBox(
          width: 500,
          child: SupplierFormWidget(
            supplier: supplier,
            onSubmit: (updatedSupplier) {
              onSupplierUpdated(updatedSupplier);
              Navigator.pop(context);
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation({required BuildContext context,required SupplierModel supplier , required Function(String id) onSupplierDeleted}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_outlined, color: Colors.orange[600]),
            const SizedBox(width: 8),
            const Text('تأكيد الحذف'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
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
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onSupplierDeleted(supplier.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}
