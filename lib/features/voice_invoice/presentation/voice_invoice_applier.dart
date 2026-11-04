import 'package:erad/features/invoices/data/models/invoice_item.dart';
import 'package:erad/features/invoices/presentation/bloc/invoice_cubit.dart';
import 'package:erad/features/voice_invoice/data/models/voice_invoice_draft.dart';

class VoiceInvoiceApplier {
  const VoiceInvoiceApplier._();

  static void apply(VoiceInvoiceDraft draft, InvoiceCubit invoiceCubit) {
    invoiceCubit.setInvoiceType(draft.isPurchase ? 'purchase' : 'sale');

    final partyId = draft.party.id;
    if (partyId != null) {
      if (draft.isPurchase) {
        invoiceCubit.setSupplier(partyId);
      } else {
        invoiceCubit.setCustomer(partyId);
      }
    }

    for (final item in draft.matchedItems.reversed) {
      invoiceCubit.addInvoiceItem(
        InvoiceItem(
          productId: item.productId,
          productName: item.name,
          quantity: item.quantity,
          unitPrice: item.unitPrice,
          purchasePrice: item.purchasePrice,
          totalPrice: item.unitPrice * item.quantity,
          unit: item.unit,
          measurement: item.measurement,
        ),
      );
    }

    invoiceCubit.setPaymentType(draft.paymentType);
  }
}
