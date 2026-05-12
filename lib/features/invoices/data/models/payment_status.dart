import 'package:flutter/material.dart';

enum PaymentStatus {
  cash,
  debt;

  String get getArabicName {
    switch (this) {
      case PaymentStatus.cash:
        return 'مدفوعة نقدا';
      case PaymentStatus.debt:
        return 'مديون';
    }
  }

  Color get getColor {
    switch (this) {
      case PaymentStatus.cash:
        return Colors.green;
      case PaymentStatus.debt:
        return Colors.red;
    }
  }

  static PaymentStatus fromString(String value) {
    return PaymentStatus.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => PaymentStatus.cash,
    );
  }
}
