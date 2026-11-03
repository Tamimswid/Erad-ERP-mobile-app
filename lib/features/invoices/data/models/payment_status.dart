import 'package:flutter/material.dart';
import 'package:erad/core/constants/app_constants.dart';

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
        return AppColors.primary;
      case PaymentStatus.debt:
        return AppColors.error;
    }
  }

  static PaymentStatus fromString(String value) {
    return PaymentStatus.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => PaymentStatus.cash,
    );
  }
}
