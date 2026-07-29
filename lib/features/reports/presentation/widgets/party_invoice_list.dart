import 'package:flutter/material.dart';
import '../../../../core/widgets/invoice_card_widget.dart';

class PartyInvoiceList extends StatelessWidget {
  final List<dynamic> invoices;
  final String type;

  const PartyInvoiceList({
    super.key,
    required this.invoices,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: invoices.length,
      itemBuilder: (context, index) {
        final invoice = invoices[index];
        return InvoiceCardWidget(
          invoice: invoice,
          type: type,
          onTap: () {},
        );
      },
    );
  }
}
