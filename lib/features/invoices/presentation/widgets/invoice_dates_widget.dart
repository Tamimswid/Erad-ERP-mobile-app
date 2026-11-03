import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;
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

  @override
  void initState() {
    super.initState();
    _initializeDates();
  }

  @override
  void dispose() {
    _invoiceDateController.dispose();
    _dueDateController.dispose();
    super.dispose();
  }

  void _initializeDates() {
    final now = DateTime.now();
    final cubit = context.read<InvoiceCubit>();

    final existingInvoiceDate = cubit.invoiceDate;
    final existingDueDate = cubit.dueDate;

    // Initialize invoice date - if no existing date, set today's date in cubit
    if (existingInvoiceDate != null) {
      _invoiceDateController.text = _formatDate(existingInvoiceDate);
    } else {
      _invoiceDateController.text = _formatDate(now);
      cubit.setInvoiceDate(now);
    }
    
    // Initialize due date - default to same as invoice date
    if (existingDueDate != null) {
      _dueDateController.text = _formatDate(existingDueDate);
    } else {
      _dueDateController.text = _invoiceDateController.text;
      cubit.setDueDate(existingInvoiceDate ?? now);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _selectDate(
    TextEditingController controller,
    String field,
  ) async {
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
      setState(() {});

      switch (field) {
        case 'invoice':
          cubit.setInvoiceDate(picked);
          // Also update due date to match if they were the same
          if (_dueDateController.text == _invoiceDateController.text || cubit.dueDate == cubit.invoiceDate) {
            _dueDateController.text = _formatDate(picked);
            cubit.setDueDate(picked);
          }
          break;
        case 'due':
          cubit.setDueDate(picked);
          break;
      }
    } 
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<InvoiceCubit, InvoiceState>(
      listener: (context, state) {
        if (state is InvoiceFormUpdated && state.updateType == 'clearAll') {
          _initializeDates();
        }
      },
      child: BlocBuilder<InvoiceCubit, InvoiceState>(
        builder: (context, state) {
          return sc.Card(
            padding: const EdgeInsets.all(AppConstants.cardPadding),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(sc.LucideIcons.calendar, 'التواريخ'),
                  const SizedBox(height: 16),
                  _buildDateField(
                    _invoiceDateController,
                    'تاريخ الفاتورة',
                    sc.LucideIcons.calendar,
                    'invoice',
                  ),
                  const SizedBox(height: 12),
                  _buildDateField(
                    _dueDateController,
                    'تاريخ الاستحقاق',
                    sc.LucideIcons.calendar,
                    'due',
                  ),
                ],
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
              icon: const Icon(sc.LucideIcons.calendar, size: 18),
              onPressed: () {
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
            _selectDate(controller, field);
          },
        ),
      ],
    );
  }
}
