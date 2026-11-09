import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/services_locator.dart';
import '../../../../core/services/pdf_invoice_service.dart';
import '../../../../core/services/user_service.dart';
import '../../../../core/widgets/app_pagination_list.dart';
import '../../../../core/widgets/date_range_filter_sheet.dart';
import '../../../../core/widgets/invoice_card_widget.dart';
import '../bloc/party_invoice_cubit.dart';

class CustomerInvoiceDetailPage extends StatelessWidget {
  final String partyId;
  final String partyName;
  final bool isSupplier;

  const CustomerInvoiceDetailPage({
    super.key,
    required this.partyId,
    required this.partyName,
    this.isSupplier = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PartyInvoiceCubit>(
      create: (_) => sl<PartyInvoiceCubit>()..loadInvoices(partyId, isSupplier),
      child: _DetailPageBody(
        partyName: partyName,
        isSupplier: isSupplier,
        partyId: partyId,
      ),
    );
  }
}

class _DetailPageBody extends StatefulWidget {
  final String partyName;
  final bool isSupplier;
  final String partyId;

  const _DetailPageBody({
    required this.partyName,
    required this.isSupplier,
    required this.partyId,
  });

  @override
  State<_DetailPageBody> createState() => _DetailPageBodyState();
}

class _DetailPageBodyState extends State<_DetailPageBody> {
  bool _isGeneratingPdf = false;

  Future<void> _showDateFilter() async {
    final cubit = context.read<PartyInvoiceCubit>();

    final result = await AppDateRangeSheet.show(
      context,
      initialRange: cubit.customDateRange,
      title: 'تصفية حسب التاريخ',
    );
    if (result == null || !mounted) return;

    final range = result.range;
    if (range == null) {
      await cubit.clearFilter();
    } else {
      await cubit.setCustomDateRange(range);
    }
  }

  Future<void> _generatePdf() async {
    final cubit = context.read<PartyInvoiceCubit>();
    final state = cubit.state;
    if (state is! PartyInvoiceLoaded || state.invoices.isEmpty) return;

    setState(() => _isGeneratingPdf = true);
    try {
      final exportResult = await cubit.getInvoicesForPdf();
      final invoices = exportResult.getOrElse(() => <dynamic>[]);
      if (invoices.isEmpty) return;

      String companyName = '';
      final userId = await UserService.getUserId();
      if (userId != null) {
        final profile = await Supabase.instance.client
            .from('profiles')
            .select('business_name')
            .eq('id', userId)
            .maybeSingle();
        if (profile != null) {
          companyName = (profile['business_name'] as String?) ?? '';
        }
      }

      final dateRangeLabel =
          cubit.isCustomDateRange && cubit.customDateRange != null
          ? 'من ${cubit.customDateRange!.start.day}/${cubit.customDateRange!.start.month}/${cubit.customDateRange!.start.year} إلى ${cubit.customDateRange!.end.day}/${cubit.customDateRange!.end.month}/${cubit.customDateRange!.end.year}'
          : cubit.selectedYear != null
          ? 'السنة: ${cubit.selectedYear}'
          : '';

      final pdfService = PdfInvoiceService();
      final pdf = await pdfService.generateInvoiceListPdf(
        companyName: companyName,
        partyName: widget.partyName,
        dateRangeLabel: dateRangeLabel,
        invoices: invoices,
        type: widget.isSupplier ? 'purchase' : 'sale',
      );

      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'invoices_${widget.partyId}.pdf',
      );
    } catch (e) {
      log('PDF generation failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('فشل إنشاء PDF: $e')));
      }
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<PartyInvoiceCubit>();
    final state = cubit.state;
    final type = widget.isSupplier ? 'purchase' : 'sale';

    return sc.Scaffold(
      headers: [
        sc.AppBar(
          title: Text(widget.partyName),
          leading: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(sc.LucideIcons.arrowRight, size: 22),
            ),
          ],
          trailing: [
            if (_isGeneratingPdf)
              const Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else ...[
              IconButton(
                icon: const Icon(sc.LucideIcons.fileDown),
                onPressed:
                    state is PartyInvoiceLoaded && state.invoices.isNotEmpty
                    ? _generatePdf
                    : null,
              ),
              AppDateRangeFilterButton(
                compact: true,
                range: cubit.customDateRange,
                onPressed: _showDateFilter,
              ),
            ],
          ],
        ),
      ],
      child: _buildBody(context, state, type),
    );
  }

  Widget _buildBody(
    BuildContext context,
    PartyInvoiceState state,
    String type,
  ) {
    if (state is PartyInvoiceLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is PartyInvoiceError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              sc.LucideIcons.receiptText,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              state.message,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (state is PartyInvoiceLoaded) {
      if (state.invoices.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                sc.LucideIcons.receiptText,
                size: 64,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 16),
              const Text(
                'لا توجد فواتير',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
              ),
            ],
          ),
        );
      }

      final cubit = context.read<PartyInvoiceCubit>();
      return RefreshIndicator(
        onRefresh: () => cubit.loadFirstPage(showLoading: false),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            AppPaginationSliverList(
              itemCount: state.invoices.length,
              hasMore: state.hasMore,
              isLoadingMore: state.isLoadingMore,
              onLoadMore: cubit.loadMore,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              separator: const SizedBox.shrink(),
              bottomSpace: 24,
              itemBuilder: (context, index) {
                final invoice = state.invoices[index];
                return InvoiceCardWidget(
                  invoice: invoice,
                  type: type,
                  onTap: () {},
                );
              },
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
