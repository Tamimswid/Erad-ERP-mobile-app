import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:arabic_reshaper/arabic_reshaper.dart';
import 'package:bidi/bidi.dart' as bidi;
import '../../features/invoices/data/models/sales_invoice.dart';
import '../../features/invoices/data/models/purchase_invoice.dart';
import '../../features/invoices/data/models/payment_status.dart';

class PdfInvoiceService {
  Future<pw.Document> generateInvoicePdf(dynamic invoice, String type) async {
    final pdf = pw.Document();
    
    // Use Amiri font which has full Arabic shaping support (connected letters)
    final arabicFont = await PdfGoogleFonts.amiriRegular();
    final arabicBoldFont = await PdfGoogleFonts.amiriBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return [
            _buildHeader(invoice, type, arabicBoldFont, arabicFont),
            pw.SizedBox(height: 10),
            _buildInvoiceItems(invoice, arabicBoldFont, arabicFont),
            pw.SizedBox(height: 10),
            _buildTotals(invoice, arabicBoldFont, arabicFont),
            if (_getNotes(invoice) != null) ...[
              pw.SizedBox(height: 10),
              _buildNotes(invoice, arabicBoldFont, arabicFont),
            ],
            if (_getTerms(invoice) != null) ...[
              pw.SizedBox(height: 10),
              _buildTerms(invoice, arabicBoldFont, arabicFont),
            ],
          ];
        },
      ),
    );

    return pdf;
  }

  pw.Widget _buildHeader(dynamic invoice, String type, pw.Font boldFont, pw.Font font) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  _processArabicText(type == 'sale' ? 'فاتورة بيع' : 'فاتورة شراء'),
                  style: pw.TextStyle(font: boldFont, fontSize: 18),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  _processArabicText('رقم الفاتورة: #${_getInvoiceNumber(invoice)}'),
                  style: pw.TextStyle(font: font, fontSize: 14),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  _processArabicText(type == 'sale' ? 'العميل: ${_getCustomerOrSupplierName(invoice, type)}' : 'المورد: ${_getCustomerOrSupplierName(invoice, type)}'),
                  style: pw.TextStyle(font: font, fontSize: 12),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  _processArabicText('حالة الدفع: ${_getPaymentStatusName(_getPaymentStatus(invoice))}'),
                  style: pw.TextStyle(font: font, fontSize: 12),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  _processArabicText('التاريخ: ${DateFormat('yyyy-MM-dd').format(_getInvoiceDate(invoice))}'),
                  style: pw.TextStyle(font: font, fontSize: 12),
                ),
                if (_getDueDate(invoice) != null)
                  pw.Text(
                    _processArabicText('تاريخ الاستحقاق: ${DateFormat('yyyy-MM-dd').format(_getDueDate(invoice)!)}'),
                    style: pw.TextStyle(font: font, fontSize: 12),
                  ),
              ],
            ),
          ],
        ),
        pw.Divider(thickness: 1),
      ],
    );
  }

  pw.Widget _buildInvoiceItems(dynamic invoice, pw.Font boldFont, pw.Font font) {
    final items = _getItems(invoice);
    
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(3), // Product name
        1: const pw.FlexColumnWidth(1), // Quantity
        2: const pw.FlexColumnWidth(1), // Unit price
        3: const pw.FlexColumnWidth(1), // Total
      },
      children: [
        // Header row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _buildTableCell(_processArabicText('الإجمالي'), boldFont, isHeader: true),
            _buildTableCell(_processArabicText('السعر'), boldFont, isHeader: true),
            _buildTableCell(_processArabicText('الكمية'), boldFont, isHeader: true),
            _buildTableCell(_processArabicText('الصنف'), boldFont, isHeader: true),
          ],
        ),
        // Data rows
        ...items.map((item) => pw.TableRow(
          children: [
            _buildTableCell('${item.totalPrice ?? 0.0}', font),
            _buildTableCell('${item.unitPrice ?? 0.0}', font),
            _buildTableCell('${item.quantity ?? 0}', font),
            _buildTableCell(_processArabicText(item.productName ?? 'صنف غير محدد'), font),
          ],
        )).toList(),
      ],
    );
  }

  pw.Widget _buildTableCell(String text, pw.Font font, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontSize: 12,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: isHeader ? pw.TextAlign.center : pw.TextAlign.right,
      ),
    );
  }

  pw.Widget _buildTotals(dynamic invoice, pw.Font boldFont, pw.Font font) {
    final subtotal = _getSubtotal(invoice);
    final discount = _getDiscountAmount(invoice);
    final total = _getTotalAmount(invoice);

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildTotalRow(
            _processArabicText('المجموع الفرعي'),
            '${subtotal.toStringAsFixed(2)} ل.س',
            font,
          ),
          pw.SizedBox(height: 4),
          if (discount > 0) ...[
            _buildTotalRow(
              _processArabicText('الخصم'),
              '- ${discount.toStringAsFixed(2)} ل.س',
              font,
              valueColor: PdfColors.red,
            ),
            pw.SizedBox(height: 4),
          ],
          pw.Divider(thickness: 1),
          pw.SizedBox(height: 4),
          _buildTotalRow(
            _processArabicText('المجموع الكلي'),
            '${total.toStringAsFixed(2)} ل.س',
            boldFont,
            isBold: true,
            valueColor: PdfColors.blue,
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTotalRow(String label, String value, pw.Font font, {bool isBold = false, PdfColor? valueColor}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            font: font,
            fontSize: 13,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            font: font,
            fontSize: isBold ? 14 : 13,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildNotes(dynamic invoice, pw.Font boldFont, pw.Font font) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _processArabicText('ملاحظات'),
            style: pw.TextStyle(font: boldFont, fontSize: 16),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            _processArabicText(_getNotes(invoice)!),
            style: pw.TextStyle(font: font, fontSize: 12),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTerms(dynamic invoice, pw.Font boldFont, pw.Font font) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _processArabicText('الشروط والأحكام'),
            style: pw.TextStyle(font: boldFont, fontSize: 16),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            _processArabicText(_getTerms(invoice)!),
            style: pw.TextStyle(font: font, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // Helper methods
  String _getInvoiceNumber(dynamic invoice) {
    if (invoice is SalesInvoice) {
      return invoice.invoiceNumber;
    } else if (invoice is PurchaseInvoice) {
      return invoice.invoiceNumber;
    }
    return '';
  }

  String _getCustomerOrSupplierName(dynamic invoice, String type) {
    if (invoice is SalesInvoice) {
      return invoice.customerName ?? 'غير محدد';
    } else if (invoice is PurchaseInvoice) {
      return invoice.supplierName ?? 'غير محدد';
    }
    return '';
  }

  DateTime _getInvoiceDate(dynamic invoice) {
    if (invoice is SalesInvoice) {
      return invoice.invoiceDate;
    } else if (invoice is PurchaseInvoice) {
      return invoice.invoiceDate;
    }
    return DateTime.now();
  }

  DateTime? _getDueDate(dynamic invoice) {
    if (invoice is SalesInvoice) {
      return invoice.dueDate;
    } else if (invoice is PurchaseInvoice) {
      return invoice.dueDate;
    }
    return null;
  }

  String _getPaymentStatus(dynamic invoice) {
    if (invoice is SalesInvoice) {
      return invoice.paymentStatus.name;
    } else if (invoice is PurchaseInvoice) {
      return invoice.paymentStatus.name;
    }
    return '';
  }

  List _getItems(dynamic invoice) {
    if (invoice is SalesInvoice) {
      return invoice.items;
    } else if (invoice is PurchaseInvoice) {
      return invoice.items;
    }
    return [];
  }

  double _getTotalAmount(dynamic invoice) {
    if (invoice is SalesInvoice) {
      return invoice.totalAmount;
    } else if (invoice is PurchaseInvoice) {
      return invoice.totalAmount;
    }
    return 0.0;
  }

  String? _getNotes(dynamic invoice) {
    if (invoice is SalesInvoice) {
      return invoice.notes;
    } else if (invoice is PurchaseInvoice) {
      return invoice.notes;
    }
    return null;
  }

  String? _getTerms(dynamic invoice) {
    // The existing models don't have a terms field
    // This can be added in the future
    return null;
  }

  String _getPaymentStatusName(String status) {
    // Use PaymentStatus model's Arabic translation helper
    try {
      final paymentStatus = PaymentStatus.fromString(status);
      return paymentStatus.getArabicName;
    } catch (e) {
      // Fallback for unknown status
      return status;
    }
  }



  String _processArabicText(String text) {
    // Apply Arabic reshaping to connect letters properly
    final reshapedText = ArabicReshaper.instance.reshape(text);
    // Convert to visual order for RTL text
    final visualText = bidi.logicalToVisual(reshapedText);
    return String.fromCharCodes(visualText);
  }
}
