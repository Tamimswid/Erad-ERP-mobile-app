import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../bloc/invoice_cubit.dart';

class InvoiceDatesWidget extends StatefulWidget {
  const InvoiceDatesWidget({super.key});

  @override
  State<InvoiceDatesWidget> createState() => _InvoiceDatesWidgetState();
}

class _InvoiceDatesWidgetState extends State<InvoiceDatesWidget> {
  final _invoiceDateController = TextEditingController();
  final _dueDateController = TextEditingController();
  final _deliveryDateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeDates();
  }

  @override
  void dispose() {
    _invoiceDateController.dispose();
    _dueDateController.dispose();
    _deliveryDateController.dispose();
    super.dispose();
  }

  void _initializeDates() {
    print('DEBUG: _initializeDates called');
    final now = DateTime.now();
    final cubit = context.read<InvoiceCubit>();

    final existingInvoiceDate = cubit.invoiceDate;
    final existingDueDate = cubit.dueDate;
    final existingDeliveryDate = cubit.deliveryDate;

    print('DEBUG: Existing invoice date: $existingInvoiceDate');

    // Initialize invoice date - if no existing date, set today's date in cubit
    if (existingInvoiceDate != null) {
      _invoiceDateController.text = _formatDate(existingInvoiceDate);
      print('DEBUG: Using existing invoice date');
    } else {
      _invoiceDateController.text = _formatDate(now);
      print('DEBUG: Setting invoice date to: $now');
      cubit.setInvoiceDate(now); // Set the date in cubit state
      print('DEBUG: Invoice date after setting: ${cubit.invoiceDate}');
    }
    
    // Initialize due date
    if (existingDueDate != null) {
      _dueDateController.text = _formatDate(existingDueDate);
    } else {
      final dueDate = now.add(const Duration(days: 30));
      _dueDateController.text = _formatDate(dueDate);
      cubit.setDueDate(dueDate); // Set the date in cubit state
    }
    
    // Initialize delivery date
    if (existingDeliveryDate != null) {
      _deliveryDateController.text = _formatDate(existingDeliveryDate);
    } else {
      _deliveryDateController.text = '';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _selectDate(
    TextEditingController controller,
    String field,
  ) async {
    print('DEBUG: _selectDate called for field: $field');
    final cubit = context.read<InvoiceCubit>();
    DateTime initialDate;
    
    if (controller.text.isNotEmpty) {
      final parts = controller.text.split('-');
      if (parts.length == 3) {
        initialDate = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
      } else {
        initialDate = DateTime.now();
      }
    } else {
      initialDate = DateTime.now();
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.surface,
              surface: AppColors.surface,
              onSurface: AppColors.text,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      print('DEBUG: Date picked for field: $field, date: $picked');
      controller.text = _formatDate(picked);
      setState(() {});

      switch (field) {
        case 'invoice':
          print('DEBUG: Setting invoice date');
          cubit.setInvoiceDate(picked);
          break;
        case 'due':
          cubit.setDueDate(picked);
          break;
        case 'delivery':
          cubit.setDeliveryDate(picked);
          break;
      }
    } else {
      print('DEBUG: No date picked for field: $field');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<InvoiceCubit, InvoiceState>(
      listener: (context, state) {
        if (state is InvoiceFormUpdated && state.updateType == 'clearAll') {
          print('DEBUG: clearAll detected, updating date fields');
          _initializeDates();
        }
      },
      child: BlocBuilder<InvoiceCubit, InvoiceState>(
        builder: (context, state) {
          return SizedBox(
            height: 230,
            child: Card(
              elevation: AppConstants.cardElevation,
              color: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusLg),
                side: BorderSide(color: AppColors.border, width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.cardPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle(Icons.calendar_today, 'التواريخ'),
                    const SizedBox(height: 16),
                    _buildDateField(
                      _invoiceDateController,
                      'تاريخ الفاتورة',
                      Icons.event_outlined,
                      'invoice',
                    ),
                    // const SizedBox(height: 12),
                    // _buildDateField(
                    //   _dueDateController,
                    //   'تاريخ الاستحقاق',
                    //   Icons.event_available_outlined,
                    //   'due',
                    // ),
                    const SizedBox(height: 12),
                    _buildDateField(
                      _deliveryDateController,
                      'تاريخ التسليم',
                      Icons.local_shipping_outlined,
                      'delivery',
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [

        Text(
          title,
          style: const TextStyle(
            fontSize: AppFonts.fontSizeMedium,
            fontWeight: AppFonts.fontWeightSemiBold,
            color: AppColors.text,
          ),
        ),
      ],
    );
  }

  Widget _buildDateField(
    TextEditingController controller,
    String label,
    IconData icon,
    String field,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: AppFonts.fontSizeSmall,
            fontWeight: AppFonts.fontWeightMedium,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 18),
            suffixIcon: IconButton(
              icon: const Icon(Icons.calendar_today, size: 18),
              onPressed: () {
                print('DEBUG: Calendar icon pressed for field: $field');
                _selectDate(controller, field);
              },
            ),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            isDense: true,
          ),
          style: const TextStyle(
            fontSize: AppFonts.fontSizeSmall,
          ),
          readOnly: true,
          enableInteractiveSelection: false,
          onTap: () {
            print('DEBUG: TextFormField tapped for field: $field');
            _selectDate(controller, field);
          },
        ),
      ],
    );
  }
}