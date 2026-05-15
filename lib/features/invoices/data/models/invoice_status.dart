import 'package:flutter/material.dart';

enum InvoiceStatus {
  pending,
  completed,
  cancelled,
  draft,
  paid;

  String get getArabicName {
    switch (this) {
      case InvoiceStatus.pending: return 'معلقة';
      case InvoiceStatus.completed: return 'مكتملة';
      case InvoiceStatus.cancelled: return 'ملغاة';
      case InvoiceStatus.draft: return 'مسودة';
      case InvoiceStatus.paid: return 'مدفوعة';
    }
  }

  Color get getColor {
    switch (this) {
      case InvoiceStatus.pending:
      case InvoiceStatus.draft:
      case InvoiceStatus.completed:
      case InvoiceStatus.paid:
        return Colors.green;
      case InvoiceStatus.cancelled:
        return Colors.grey;
    }
  }

  static InvoiceStatus fromString(String value) {
    return InvoiceStatus.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => InvoiceStatus.pending,
    );
  }
}