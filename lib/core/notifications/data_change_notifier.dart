import 'package:flutter/foundation.dart';

enum DataDomain {
  invoices,
  customerDebts,
  supplierDebts,
  products,
  expenses,
  withdrawals,
  customers,
  suppliers,
}

/// Supabase realtime aboneliklerinin yerine yerel değişiklikleri yayar.
class DataChangeNotifier extends ChangeNotifier {
  final Map<DataDomain, int> _versions = {
    for (final domain in DataDomain.values) domain: 0,
  };

  int versionOf(DataDomain domain) => _versions[domain]!;

  void notifyChanged(DataDomain domain) => notifyChangedAll([domain]);

  void notifyChangedAll(Iterable<DataDomain> domains) {
    var hasChange = false;
    for (final domain in domains.toSet()) {
      final version = _versions[domain];
      if (version == null) continue;
      _versions[domain] = version + 1;
      hasChange = true;
    }
    if (hasChange) notifyListeners();
  }
}
