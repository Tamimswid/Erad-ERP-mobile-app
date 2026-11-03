import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;
import '../../../../core/constants/app_constants.dart';
import '../bloc/edit_invoice_cubit.dart';

class EditInvoiceDatesWidget extends StatefulWidget {
  const EditInvoiceDatesWidget({super.key});

  @override
  State<EditInvoiceDatesWidget> createState() => _EditInvoiceDatesWidgetState();
}

class _EditInvoiceDatesWidgetState extends State<EditInvoiceDatesWidget> {
  final _invoiceDateController = TextEditingController();
  final _dueDateController = TextEditingController();

  @override
  void dispose() {
    _invoiceDateController.dispose();
    _dueDateController.dispose();
    super.dispose();
  }

  void _initControllers(EditInvoiceCubit cubit) {
    if (cubit.invoiceDate != null && _invoiceDateController.text.isEmpty) {
      _invoiceDateController.text = _formatDate(cubit.invoiceDate!);
    }
    if (cubit.dueDate != null && _dueDateController.text.isEmpty) {
      _dueDateController.text = _formatDate(cubit.dueDate!);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _selectDate(
    TextEditingController controller,
    String field,
  ) async {
    final cubit = context.read<EditInvoiceCubit>();
    DateTime initialDate = DateTime.now();
    
    if (controller.text.isNotEmpty) {
      final parts = controller.text.split('-');
      if (parts.length == 3) {
        initialDate = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
      }
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
              onPrimary: AppColors.onPrimary,
              surface: AppColors.surface,
              onSurface: AppColors.text,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      controller.text = _formatDate(picked);
      if (field == 'invoice') {
        cubit.setInvoiceDate(picked);
      } else {
        cubit.setDueDate(picked);
      }
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EditInvoiceCubit, EditInvoiceState>(
      builder: (context, state) {
        if (state is EditInvoiceLoaded) {
          _initControllers(context.read<EditInvoiceCubit>());
        }
        
        return SizedBox(
          height: 140,
          child: sc.Card(
            padding: const EdgeInsets.all(AppConstants.cardPadding),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(sc.LucideIcons.calendar, 'التواريخ'),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateField(
                          _invoiceDateController,
                          'تاريخ الفاتورة',
                          sc.LucideIcons.calendar,
                          'invoice',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDateField(
                          _dueDateController,
                          'تاريخ الاستحقاق',
                          sc.LucideIcons.calendarCheck,
                          'due',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
          ),
        );
      },
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
              icon: const Icon(sc.LucideIcons.calendar, size: 18),
              onPressed: () => _selectDate(controller, field),
            ),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            isDense: true,
          ),
          style: const TextStyle(fontSize: AppFonts.fontSizeSmall),
          readOnly: true,
          enableInteractiveSelection: false,
          onTap: () => _selectDate(controller, field),
        ),
      ],
    );
  }
}