import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;
import '../../../../core/constants/app_constants.dart';
import '../bloc/party_invoice_cubit.dart';

class PartyInvoiceAppBarActions extends StatelessWidget {
  final bool isGeneratingPdf;
  final bool hasInvoices;
  final VoidCallback onPdfTap;
  final VoidCallback onDateFilterTap;

  const PartyInvoiceAppBarActions({
    super.key,
    required this.isGeneratingPdf,
    required this.hasInvoices,
    required this.onPdfTap,
    required this.onDateFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<PartyInvoiceCubit>();
    final state = cubit.state;
    final hasFilter = state is PartyInvoiceLoaded && _hasActiveFilter(cubit);

    if (isGeneratingPdf) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(sc.LucideIcons.fileDown),
          onPressed: hasInvoices ? onPdfTap : null,
        ),
        Stack(
          children: [
            IconButton(
              icon: const Icon(sc.LucideIcons.calendar),
              onPressed: onDateFilterTap,
            ),
            if (hasFilter)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  bool _hasActiveFilter(PartyInvoiceCubit cubit) {
    return cubit.selectedYear != null ||
        (cubit.isCustomDateRange && cubit.customDateRange != null);
  }
}
