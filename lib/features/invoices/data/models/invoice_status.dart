import 'package:flutter/material.dart';
import 'package:erad/core/constants/app_constants.dart';

enum InvoiceStatus {
  draft,
  completed,
  cancelled;

  String get getArabicName {
    switch (this) {
      case InvoiceStatus.draft:
        return 'مسودة';
      case InvoiceStatus.completed:
        return 'مكتملة';
      case InvoiceStatus.cancelled:
        return 'ملغاة';
    }
  }

  Color get getColor {
    switch (this) {
      case InvoiceStatus.draft:
      case InvoiceStatus.completed:
        return AppColors.primary;
      case InvoiceStatus.cancelled:
        return AppColors.textSecondary;
    }
  }

  static InvoiceStatus fromString(String value) {
    return InvoiceStatus.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => InvoiceStatus.draft,
    );
  }
}
