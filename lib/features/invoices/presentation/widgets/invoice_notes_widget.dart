import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../bloc/invoice_cubit.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;

class InvoiceNotesWidget extends StatefulWidget {
  const InvoiceNotesWidget({super.key});

  @override
  State<InvoiceNotesWidget> createState() => _InvoiceNotesWidgetState();
}

class _InvoiceNotesWidgetState extends State<InvoiceNotesWidget> {
  final _notesController = TextEditingController();
  final _referenceController = TextEditingController();
  final _projectController = TextEditingController();
  String _paymentMethod = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _referenceController.dispose();
    _projectController.dispose();
    super.dispose();
  }

  void _loadData() {
    final cubit = context.read<InvoiceCubit>();
    _notesController.text = cubit.notes;
    _referenceController.text = cubit.reference;
    _projectController.text = cubit.project;
    _paymentMethod = cubit.paymentMethod;
  }

  void _onNotesChanged(String? value) {
    if (value != null) {
      context.read<InvoiceCubit>().setNotes(value);
    }
  }

  void _onReferenceChanged(String? value) {
    if (value != null) {
      context.read<InvoiceCubit>().setReference(value);
    }
  }

  void _onProjectChanged(String? value) {
    if (value != null) {
      context.read<InvoiceCubit>().setProject(value);
    }
  }

  void _onPaymentMethodChanged(String? value) {
    if (value != null) {
      setState(() {
        _paymentMethod = value;
      });
      context.read<InvoiceCubit>().setPaymentMethod(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
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
            _buildSectionTitle(sc.LucideIcons.alignLeft, 'Ek Bilgiler'),
            const SizedBox(height: AppConstants.spacingMd),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Notes Field
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notlar',
                      style: const TextStyle(
                        fontSize: AppFonts.fontSizeSmall,
                        fontWeight: AppFonts.fontWeightMedium,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        hintText: 'Fatura notları...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppConstants.borderRadius,
                          ),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppConstants.borderRadius,
                          ),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppConstants.borderRadius,
                          ),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: AppColors.surface,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                      ),
                      maxLines: 2,
                      onChanged: _onNotesChanged,
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.spacingMd),

                // Additional Fields Row
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        _referenceController,
                        'Referans No',
                        'PO numarası...',
                        _onReferenceChanged,
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacingMd),
                    Expanded(
                      child: _buildTextField(
                        _projectController,
                        'Proje',
                        'Proje adı...',
                        _onProjectChanged,
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacingMd),
                    Expanded(child: _buildPaymentMethodDropdown()),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: AppFonts.fontSizeSmall,
            fontWeight: AppFonts.fontWeightSemiBold,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String hintText,
    ValueChanged<String?> onChanged,
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
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hintText,
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
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildPaymentMethodDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ödeme Yöntemi',
          style: const TextStyle(
            fontSize: AppFonts.fontSizeSmall,
            fontWeight: AppFonts.fontWeightMedium,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _paymentMethod.isEmpty ? null : _paymentMethod,
          decoration: InputDecoration(
            hintText: 'Seçiniz',
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
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
          ),
          items: const [
            DropdownMenuItem(value: 'cash', child: Text('Nakit')),
            DropdownMenuItem(value: 'card', child: Text('Kredi Kartı')),
            DropdownMenuItem(value: 'transfer', child: Text('Havale/EFT')),
            DropdownMenuItem(
              value: 'electronic',
              child: Text('Elektronik Ödeme'),
            ),
          ],
          onChanged: _onPaymentMethodChanged,
        ),
      ],
    );
  }
}
