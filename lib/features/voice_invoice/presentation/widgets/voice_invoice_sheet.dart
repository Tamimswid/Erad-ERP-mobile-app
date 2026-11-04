import 'package:erad/core/constants/app_constants.dart';
import 'package:erad/core/di/services_locator.dart' as sl;
import 'package:erad/core/utils/app_utils.dart';
import 'package:erad/core/utils/number_formatter.dart';
import 'package:erad/features/invoices/presentation/bloc/invoice_cubit.dart';
import 'package:erad/features/voice_invoice/data/models/voice_invoice_draft.dart';
import 'package:erad/features/voice_invoice/presentation/bloc/voice_invoice_cubit.dart';
import 'package:erad/features/voice_invoice/presentation/bloc/voice_invoice_state.dart';
import 'package:erad/features/voice_invoice/presentation/voice_invoice_applier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;

class VoiceInvoiceSheet extends StatelessWidget {
  const VoiceInvoiceSheet({super.key});

  static Future<void> show(
    BuildContext context, {
    required InvoiceCubit invoiceCubit,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.borderRadiusLg),
        ),
      ),
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: invoiceCubit),
          BlocProvider(create: (_) => sl.sl<VoiceInvoiceCubit>()),
        ],
        child: const VoiceInvoiceSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.78,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return BlocBuilder<VoiceInvoiceCubit, VoiceInvoiceState>(
          builder: (context, state) {
            final draft = state.draft;

            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
              children: [
                _buildGrabber(),
                _buildHeader(context),
                const SizedBox(height: 20),
                _buildTranscript(state),
                const SizedBox(height: 24),
                if (state.status == VoiceInvoiceStatus.ready &&
                    draft != null) ...[
                  _buildDraft(draft),
                  const SizedBox(height: 22),
                ],
                _buildControls(context, state),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildGrabber() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.divider,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        const Icon(sc.LucideIcons.mic, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'فاتورة بالصوت',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
        ),
        sc.IconButton(
          variance: sc.ButtonStyle.ghost(),
          onPressed: () => Navigator.pop(context),
          icon: const Icon(sc.LucideIcons.x, size: 20),
        ),
      ],
    );
  }

  Widget _buildTranscript(VoiceInvoiceState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'النص المسموع',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            if (state.isListening) ...[
              const SizedBox(width: 8),
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'يستمع...',
                style: TextStyle(fontSize: 12, color: AppColors.error),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Text(
          state.hasTranscript
              ? state.transcript
              : 'اضغط على الميكروفون وقل الطلب، مثلاً: «فاتورة بيع للعميل أحمد، خمسة كيلو سكر، دين»',
          style: TextStyle(
            fontSize: 15,
            height: 1.6,
            color: state.hasTranscript
                ? AppColors.text
                : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildControls(BuildContext context, VoiceInvoiceState state) {
    switch (state.status) {
      case VoiceInvoiceStatus.analyzing:
        return _buildAnalyzing();
      case VoiceInvoiceStatus.ready:
        return _buildReadyActions(context, state.draft!);
      case VoiceInvoiceStatus.error:
        return _buildError(context, state);
      default:
        return _buildMicControl(context, state);
    }
  }

  Widget _buildMicControl(BuildContext context, VoiceInvoiceState state) {
    final cubit = context.read<VoiceInvoiceCubit>();
    final listening = state.isListening;

    return Column(
      children: [
        Material(
          color: listening ? AppColors.error : AppColors.primary,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {
              if (listening) {
                cubit.stopListening();
              } else {
                cubit.startListening(
                  typeHint: context.read<InvoiceCubit>().invoiceType,
                );
              }
            },
            child: SizedBox(
              width: 72,
              height: 72,
              child: Icon(
                listening ? sc.LucideIcons.circleStop : sc.LucideIcons.mic,
                color: AppColors.onPrimary,
                size: 30,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          listening ? 'اضغط للإيقاف والتحليل' : 'اضغط للتسجيل',
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildAnalyzing() {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          padding: const EdgeInsets.all(22),
          decoration: const BoxDecoration(
            color: AppColors.muted,
            shape: BoxShape.circle,
          ),
          child: const CircularProgressIndicator(
            strokeWidth: 3,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'جارٍ تحليل الطلب...',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildError(BuildContext context, VoiceInvoiceState state) {
    return Column(
      children: [
        Text(
          state.message ?? 'تعذر تحليل الطلب، حاول مرة أخرى',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: AppColors.error),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: sc.Button(
            alignment: Alignment.center,
            style: sc.ButtonStyle.primary(),
            onPressed: context.read<VoiceInvoiceCubit>().retry,
            leading: const Icon(sc.LucideIcons.rotateCcw, size: 16),
            child: const Text('إعادة المحاولة'),
          ),
        ),
      ],
    );
  }

  Widget _buildReadyActions(BuildContext context, VoiceInvoiceDraft draft) {
    final canApply = draft.canApply;

    return Column(
      children: [
        if (draft.matchedItems.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'لم يتم التعرف على أي منتج، أعد التسجيل مع ذكر المنتجات والكميات',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.warning),
            ),
          )
        else if (!draft.party.matched)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'لم يتم العثور على الطرف، سيتم تطبيق المنتجات ويمكنك اختياره يدوياً',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.warning),
            ),
          ),
        SizedBox(
          width: double.infinity,
          child: sc.Button(
            alignment: Alignment.center,
            style: sc.ButtonStyle.primary(),
            onPressed: canApply ? () => _apply(context, draft) : null,
            leading: const Icon(sc.LucideIcons.check, size: 16),
            child: Text(
              draft.isPurchase
                  ? 'تطبيق على فاتورة الشراء'
                  : 'تطبيق على فاتورة البيع',
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: sc.Button(
            alignment: Alignment.center,
            style: sc.ButtonStyle.outline(),
            onPressed: () => context.read<VoiceInvoiceCubit>().startListening(
              typeHint: context.read<InvoiceCubit>().invoiceType,
            ),
            leading: const Icon(sc.LucideIcons.mic, size: 16),
            child: const Text('تسجيل من جديد'),
          ),
        ),
      ],
    );
  }

  Widget _buildDraft(VoiceInvoiceDraft draft) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildMeta(
              draft.isPurchase
                  ? sc.LucideIcons.shoppingCart
                  : sc.LucideIcons.receiptText,
              draft.isPurchase ? 'شراء' : 'بيع',
            ),
            Container(
              width: 1,
              height: 14,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              color: AppColors.divider,
            ),
            _buildMeta(
              draft.isCash ? sc.LucideIcons.wallet : sc.LucideIcons.clock,
              draft.isCash ? 'نقدي' : 'دين',
            ),
            const Spacer(),
            Text(
              'ثقة ${(draft.confidence * 100).round()}%',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _buildLabel('الطرف'),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(
              draft.isPurchase ? sc.LucideIcons.building2 : sc.LucideIcons.user,
              size: 18,
              color: draft.party.matched ? AppColors.primary : AppColors.error,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                draft.party.name.isEmpty ? 'غير محدد' : draft.party.name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.text,
                ),
              ),
            ),
            if (draft.party.matched && draft.party.phone != null)
              Text(
                draft.party.phone!,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              )
            else if (!draft.party.matched)
              const Text(
                'غير موجود',
                style: TextStyle(fontSize: 12, color: AppColors.error),
              ),
          ],
        ),
        if (!draft.party.matched)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text(
              'لم يتم العثور على هذا الاسم في قاعدة البيانات، أضفه أولاً ثم أعد المحاولة',
              style: TextStyle(fontSize: 12, color: AppColors.error),
            ),
          ),
        const SizedBox(height: 18),
        Row(
          children: [
            _buildLabel('المنتجات'),
            const Spacer(),
            Text(
              '${draft.items.length}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ...draft.items.map(_buildItemRow),
        if (draft.unmatchedItems.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...draft.unmatchedItems.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      sc.LucideIcons.circleAlert,
                      size: 14,
                      color: AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${item.spokenName} × ${item.quantity} — غير موجود في المخزون',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (draft.warnings.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...draft.warnings.map(
            (warning) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '• $warning',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildItemRow(VoiceInvoiceItem item) {
    final total = item.unitPrice * item.quantity;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _productLabel(item),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.text,
                  ),
                ),
              ),
              Text(
                '× ${item.quantity}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              Text(
                '${AppUtils.formatNumber(item.unitPrice)} ${NumberFormatter.getCurrencySymbol()}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                '${AppUtils.formatNumber(total)} ${NumberFormatter.getCurrencySymbol()}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.moneyIn,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMeta(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppColors.textSecondary),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.text,
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      ),
    );
  }

  String _productLabel(VoiceInvoiceItem item) {
    return [
      item.name,
      item.measurement,
      item.unit,
    ].where((part) => part.trim().isNotEmpty).join(' ');
  }

  void _apply(BuildContext context, VoiceInvoiceDraft draft) {
    VoiceInvoiceApplier.apply(draft, context.read<InvoiceCubit>());
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger.showSnackBar(
      const SnackBar(
        content: Text('تم تطبيق الفاتورة، راجع الحقول ثم اضغط حفظ'),
      ),
    );
  }
}
