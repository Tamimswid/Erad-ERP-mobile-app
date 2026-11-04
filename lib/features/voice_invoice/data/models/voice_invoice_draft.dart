class VoiceInvoiceDraft {
  const VoiceInvoiceDraft({
    required this.transcript,
    required this.invoiceType,
    required this.paymentType,
    required this.confidence,
    required this.party,
    required this.items,
    required this.unmatchedItems,
    required this.warnings,
  });

  final String transcript;
  final String invoiceType;
  final String paymentType;
  final double confidence;
  final VoiceInvoicePartyResult party;
  final List<VoiceInvoiceItem> items;
  final List<VoiceUnmatchedItem> unmatchedItems;
  final List<String> warnings;

  bool get isPurchase => invoiceType == 'purchase';
  bool get isCash => paymentType == 'cash';

  List<VoiceInvoiceItem> get matchedItems =>
      items.where((item) => item.matched && item.productId != null).toList();

  bool get canApply => matchedItems.isNotEmpty;

  factory VoiceInvoiceDraft.fromJson(Map<String, dynamic> json) {
    return VoiceInvoiceDraft(
      transcript: _asString(json['transcript']) ?? '',
      invoiceType: _asString(json['invoice_type']) == 'purchase'
          ? 'purchase'
          : 'sale',
      paymentType: _asString(json['payment_type']) == 'cash' ? 'cash' : 'debt',
      confidence: _asDouble(json['confidence']),
      party: VoiceInvoicePartyResult.fromJson(_asMap(json['party'])),
      items: _asMapList(json['items']).map(VoiceInvoiceItem.fromJson).toList(),
      unmatchedItems: _asMapList(
        json['unmatched_items'],
      ).map(VoiceUnmatchedItem.fromJson).toList(),
      warnings: _asStringList(json['warnings']),
    );
  }
}

class VoiceInvoicePartyResult {
  const VoiceInvoicePartyResult({
    required this.partyType,
    required this.id,
    required this.name,
    required this.phone,
    required this.matched,
  });

  final String partyType;
  final String? id;
  final String name;
  final String? phone;
  final bool matched;

  factory VoiceInvoicePartyResult.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const VoiceInvoicePartyResult(
        partyType: 'customer',
        id: null,
        name: '',
        phone: null,
        matched: false,
      );
    }
    return VoiceInvoicePartyResult(
      partyType: _asString(json['party_type']) == 'supplier'
          ? 'supplier'
          : 'customer',
      id: _asString(json['id']),
      name: _asString(json['name']) ?? '',
      phone: _asString(json['phone']),
      matched: json['matched'] == true && _asString(json['id']) != null,
    );
  }
}

class VoiceInvoiceItem {
  const VoiceInvoiceItem({
    required this.productId,
    required this.name,
    required this.spokenName,
    required this.quantity,
    required this.unit,
    required this.measurement,
    required this.unitPrice,
    required this.salePrice,
    required this.purchasePrice,
    required this.totalPrice,
    required this.matched,
  });

  final String? productId;
  final String name;
  final String spokenName;
  final int quantity;
  final String unit;
  final String measurement;
  final double unitPrice;
  final double salePrice;
  final double purchasePrice;
  final double totalPrice;
  final bool matched;

  factory VoiceInvoiceItem.fromJson(Map<String, dynamic> json) {
    return VoiceInvoiceItem(
      productId: _asString(json['product_id']),
      name: _asString(json['name']) ?? '',
      spokenName: _asString(json['spoken_name']) ?? '',
      quantity: _asInt(json['quantity']),
      unit: _asString(json['unit']) ?? '',
      measurement: _asString(json['measurement']) ?? '',
      unitPrice: _asDouble(json['unit_price']),
      salePrice: _asDouble(json['sale_price']),
      purchasePrice: _asDouble(json['purchase_price']),
      totalPrice: _asDouble(json['total_price']),
      matched: json['matched'] == true && _asString(json['product_id']) != null,
    );
  }
}

class VoiceUnmatchedItem {
  const VoiceUnmatchedItem({required this.spokenName, required this.quantity});

  final String spokenName;
  final int quantity;

  factory VoiceUnmatchedItem.fromJson(Map<String, dynamic> json) {
    return VoiceUnmatchedItem(
      spokenName: _asString(json['spoken_name']) ?? '',
      quantity: _asInt(json['quantity']),
    );
  }
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map) return Map<String, dynamic>.from(value);
  return const {};
}

List<Map<String, dynamic>> _asMapList(dynamic value) {
  if (value is List) {
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
  return const [];
}

List<String> _asStringList(dynamic value) {
  if (value is List) {
    return value
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList();
  }
  return const [];
}

String? _asString(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

double _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0.0;
}

int _asInt(dynamic value) {
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
