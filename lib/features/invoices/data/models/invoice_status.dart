import 'package:flutter/material.dart';

enum InvoiceStatus {
  pending,
  completed,
  cancelled,
  draft,
  sent,
  overdue,
  paid;

  String get getArabicName {
    switch (this) {
      case InvoiceStatus.pending: return 'معلقة';
      case InvoiceStatus.completed: return 'مكتملة';
      case InvoiceStatus.cancelled: return 'ملغاة';
      case InvoiceStatus.draft: return 'مسودة';
      case InvoiceStatus.sent: return 'مرسلة';
      case InvoiceStatus.overdue: return 'متأخرة';
      case InvoiceStatus.paid: return 'مدفوعة';
    }
  }

  Color get getColor {
    switch (this) {
      case InvoiceStatus.pending:
      case InvoiceStatus.draft:
      case InvoiceStatus.sent:
        return Colors.orange;
      case InvoiceStatus.completed:
      case InvoiceStatus.paid:
        return Colors.green;
      case InvoiceStatus.overdue:
        return Colors.red;
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