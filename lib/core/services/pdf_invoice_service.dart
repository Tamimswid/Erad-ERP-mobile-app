import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:arabic_reshaper/arabic_reshaper.dart';
import 'package:bidi/bidi.dart' as bidi;
import '../../features/invoices/data/models/sales_invoice.dart';
import '../../features/invoices/data/models/purchase_invoice.dart';
import '../utils/number_formatter.dart';
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

  Future<pw.Document> generateInvoiceListPdf({
    required String companyName,
    required String partyName,
    required String dateRangeLabel,
    required List<dynamic> invoices,
    required String type,
  }) async {
    final pdf = pw.Document();
    final arabicFont = await PdfGoogleFonts.amiriRegular();
    final arabicBoldFont = await PdfGoogleFonts.amiriBold();
    final total = invoices.fold<double>(0, (sum, inv) => sum + _getTotalAmount(inv));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return [
            _buildReportHeader(companyName, partyName, dateRangeLabel, type, arabicBoldFont, arabicFont),
            pw.SizedBox(height: 16),
            _buildInvoiceTable(invoices, arabicBoldFont, arabicFont),
            pw.SizedBox(height: 16),
            _buildReportTotal(total, arabicBoldFont, arabicFont),
          ];
        },
      ),
    );

    return pdf;
  }

  Future<pw.Document> generateStockPdf({
    required String companyName,
    required String dateRangeLabel,
    required List<Map<String, dynamic>> products,
  }) async {
    final pdf = pw.Document();
    final arabicFont = await PdfGoogleFonts.amiriRegular();
    final arabicBoldFont = await PdfGoogleFonts.amiriBold();
    final totalQty = products.fold<int>(0, (sum, p) => sum + ((p['total_purchased_qty'] ?? 0) as int));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return [
            _buildStockHeader(companyName, dateRangeLabel, arabicBoldFont, arabicFont),
            pw.SizedBox(height: 16),
            _buildStockTable(products, arabicBoldFont, arabicFont),
            pw.SizedBox(height: 16),
            _buildStockTotal(totalQty, arabicBoldFont, arabicFont),
          ];
        },
      ),
    );

    return pdf;
  }

  pw.Widget _buildStockHeader(
    String companyName,
    String dateRangeLabel,
    pw.Font boldFont,
    pw.Font font,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.fromLTRB(0, 0, 0, 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Text(
            _processArabicText(companyName.isNotEmpty ? companyName : 'تقرير تتبع المخزون'),
            style: pw.TextStyle(font: boldFont, fontSize: 14),
          ),
          if (dateRangeLabel.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              _processArabicText(dateRangeLabel),
              style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey600),
            ),
          ],
          pw.Divider(thickness: 0.5),
        ],
      ),
    );
  }

  pw.Widget _buildStockTable(
    List<Map<String, dynamic>> products,
    pw.Font boldFont,
    pw.Font font,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(4),
        1: const pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _buildStockCell(_processArabicText('الكمية المشتراة'), boldFont, isHeader: true),
            _buildStockCell(_processArabicText('اسم المنتج'), boldFont, isHeader: true),
          ],
        ),
        ...products.map((p) => pw.TableRow(
          children: [
            _buildStockCell('${p['total_purchased_qty'] ?? 0}', font),
            _buildStockCell(_processArabicText(p['product_display_name'] ?? ''), font),
          ],
        )),
      ],
    );
  }

  pw.Widget _buildStockCell(String text, pw.Font font, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontSize: 11,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: isHeader ? pw.TextAlign.center : pw.TextAlign.right,
      ),
    );
  }

  pw.Widget _buildStockTotal(int totalQty, pw.Font boldFont, pw.Font font) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            '$totalQty',
            style: pw.TextStyle(font: boldFont, fontSize: 13),
          ),
          pw.Text(
            _processArabicText('الإجمالي'),
            style: pw.TextStyle(font: boldFont, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Future<pw.Document> generateDebtPdf({
    required String companyName,
    required String partyName,
    required String dateRangeLabel,
    required List<Map<String, dynamic>> invoices,
    required List<Map<String, dynamic>> payments,
    required bool isSupplier,
  }) async {
    final pdf = pw.Document();
    final arabicFont = await PdfGoogleFonts.amiriRegular();
    final arabicBoldFont = await PdfGoogleFonts.amiriBold();

    final totalInvoices =
        invoices.fold<double>(0, (sum, inv) => sum + ((inv['total_amount'] ?? 0).toDouble()));
    final totalPayments =
        payments.fold<double>(0, (sum, p) => sum + ((p['amount'] ?? 0).toDouble()));
    final remaining = totalInvoices - totalPayments;
    final rowCount = invoices.length > payments.length ? invoices.length : payments.length;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return [
            _buildDebtHeader(companyName, partyName, dateRangeLabel, isSupplier, arabicBoldFont, arabicFont),
            pw.SizedBox(height: 16),
            _buildDebtTable(invoices, payments, rowCount, arabicBoldFont, arabicFont),
            pw.SizedBox(height: 16),
            _buildDebtTotal(totalInvoices, totalPayments, remaining, arabicBoldFont, arabicFont),
          ];
        },
      ),
    );

    return pdf;
  }

  pw.Widget _buildDebtHeader(
    String companyName,
    String partyName,
    String dateRangeLabel,
    bool isSupplier,
    pw.Font boldFont,
    pw.Font font,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.fromLTRB(0, 0, 0, 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                _processArabicText(isSupplier ? 'تقرير ديون مورد' : 'تقرير ديون مشتري'),
                style: pw.TextStyle(font: font, fontSize: 11, color: PdfColors.grey700),
              ),
              pw.Text(
                _processArabicText(companyName),
                style: pw.TextStyle(font: boldFont, fontSize: 14),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            _processArabicText(partyName),
            style: pw.TextStyle(font: font, fontSize: 11),
          ),
          if (dateRangeLabel.isNotEmpty) ...[
            pw.SizedBox(height: 2),
            pw.Text(
              _processArabicText(dateRangeLabel),
              style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey600),
            ),
          ],
          pw.Divider(thickness: 0.5),
        ],
      ),
    );
  }

  pw.Widget _buildDebtTable(
    List<Map<String, dynamic>> invoices,
    List<Map<String, dynamic>> payments,
    int rowCount,
    pw.Font boldFont,
    pw.Font font,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(2.5),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(2.5),
        4: const pw.FlexColumnWidth(3),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _buildTableCellRtl(_processArabicText('مبلغ الدفع'), boldFont, isHeader: true),
            _buildTableCellRtl(_processArabicText('تاريخ الدفع'), boldFont, isHeader: true),
            _buildTableCellRtl(_processArabicText('مبلغ الفاتورة'), boldFont, isHeader: true),
            _buildTableCellRtl(_processArabicText('تاريخ الفاتورة'), boldFont, isHeader: true),
            _buildTableCellRtl(_processArabicText('رقم الفاتورة'), boldFont, isHeader: true),
          ],
        ),
        ...List.generate(rowCount, (i) {
          final inv = i < invoices.length ? invoices[i] : null;
          final pay = i < payments.length ? payments[i] : null;

          return pw.TableRow(
            children: [
              _buildTableCellRtl(
                pay != null ? (pay['amount'] ?? 0).toDouble().toStringAsFixed(2) : '',
                font,
              ),
              _buildTableCellRtl(
                pay != null ? _formatDateStr('${pay['payment_date'] ?? pay['created_at'] ?? ''}') : '',
                font,
              ),
              _buildTableCellRtl(
                inv != null ? (inv['total_amount'] ?? 0).toDouble().toStringAsFixed(2) : '',
                font,
              ),
              _buildTableCellRtl(
                inv != null ? _formatDateStr('${inv['invoice_date'] ?? ''}') : '',
                font,
              ),
              _buildTableCellRtl(
                inv != null ? '${inv['invoice_number'] ?? ''}' : '',
                font,
              ),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _buildTableCellRtl(String text, pw.Font font, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontSize: 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: isHeader ? pw.TextAlign.center : pw.TextAlign.right,
      ),
    );
  }

  pw.Widget _buildDebtTotal(
    double totalInvoices,
    double totalPayments,
    double remaining,
    pw.Font boldFont,
    pw.Font font,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          _buildDebtTotalRow(
            _processArabicText('إجمالي الفواتير'),
            '${totalInvoices.toStringAsFixed(2)} ${NumberFormatter.getCurrencySymbol()}',
            font,
          ),
          pw.SizedBox(height: 4),
          _buildDebtTotalRow(
            _processArabicText('إجمالي المدفوعات'),
            '${totalPayments.toStringAsFixed(2)} ${NumberFormatter.getCurrencySymbol()}',
            font,
            valueColor: PdfColors.green,
          ),
          pw.Divider(thickness: 0.5),
          pw.SizedBox(height: 4),
          _buildDebtTotalRow(
            _processArabicText('المتبقي'),
            '${remaining.toStringAsFixed(2)} ${NumberFormatter.getCurrencySymbol()}',
            boldFont,
            isBold: true,
            valueColor: remaining > 0 ? PdfColors.red : PdfColors.green,
          ),
        ],
      ),
    );
  }

  pw.Widget _buildDebtTotalRow(
    String label, String value, pw.Font font, {
    bool isBold = false,
    PdfColor? valueColor,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            font: font,
            fontSize: isBold ? 14 : 13,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: valueColor,
          ),
        ),
        pw.Text(
          label,
          style: pw.TextStyle(
            font: font,
            fontSize: 13,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ],
    );
  }

  String _formatDateStr(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('yyyy-MM-dd').format(dt);
    } catch (_) {
      return dateStr.length >= 10 ? dateStr.substring(0, 10) : dateStr;
    }
  }

  pw.Widget _buildReportHeader(
    String companyName,
    String partyName,
    String dateRangeLabel,
    String type,
    pw.Font boldFont,
    pw.Font font,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.fromLTRB(0, 0, 0, 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                _processArabicText(companyName),
                style: pw.TextStyle(font: boldFont, fontSize: 14),
              ),
              pw.Text(
                _processArabicText(type == 'purchase' ? 'تقرير فواتير مورد' : 'تقرير فواتير مشتري'),
                style: pw.TextStyle(font: font, fontSize: 11, color: PdfColors.grey700),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            children: [
              pw.Text(
                _processArabicText(partyName),
                style: pw.TextStyle(font: font, fontSize: 11),
              ),
            ],
          ),
          if (dateRangeLabel.isNotEmpty) ...[
            pw.SizedBox(height: 2),
            pw.Text(
              _processArabicText(dateRangeLabel),
              style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey600),
            ),
          ],
          pw.Divider(thickness: 0.5),
        ],
      ),
    );
  }

  pw.Widget _buildInvoiceTable(List<dynamic> invoices, pw.Font boldFont, pw.Font font) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _buildTableCell(_processArabicText('رقم الفاتورة'), boldFont, isHeader: true),
            _buildTableCell(_processArabicText('تاريخ الفاتورة'), boldFont, isHeader: true),
            _buildTableCell(_processArabicText('إجمالي الفاتورة'), boldFont, isHeader: true),
          ],
        ),
        ...invoices.map((inv) => pw.TableRow(
          children: [
            _buildTableCell(_getInvoiceNumber(inv), font),
            _buildTableCell(DateFormat('yyyy-MM-dd').format(_getInvoiceDate(inv)), font),
            _buildTableCell(_getTotalAmount(inv).toStringAsFixed(2), font),
          ],
        )),
      ],
    );
  }

  pw.Widget _buildReportTotal(double total, pw.Font boldFont, pw.Font font) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            _processArabicText('الإجمالي العام'),
            style: pw.TextStyle(font: boldFont, fontSize: 13),
          ),
          pw.Text(
            '${total.toStringAsFixed(2)} ${NumberFormatter.getCurrencySymbol()}',
            style: pw.TextStyle(font: boldFont, fontSize: 13, color: PdfColors.blue),
          ),
        ],
      ),
    );
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
                  _processArabicText('التاريخ: ${DateFormat('yyyy-MM-dd').format(_getInvoiceDate(invoice))}'),
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
            '${subtotal.toStringAsFixed(2)} ${NumberFormatter.getCurrencySymbol()}',
            font,
          ),
          pw.SizedBox(height: 4),
          if (discount > 0) ...[
            _buildTotalRow(
              _processArabicText('الخصم'),
              '- ${discount.toStringAsFixed(2)} ${NumberFormatter.getCurrencySymbol()}',
              font,
              valueColor: PdfColors.red,
            ),
            pw.SizedBox(height: 4),
          ],
          pw.Divider(thickness: 1),
          pw.SizedBox(height: 4),
          _buildTotalRow(
            _processArabicText('المجموع الكلي'),
            '${total.toStringAsFixed(2)} ${NumberFormatter.getCurrencySymbol()}',
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

  double _getSubtotal(dynamic invoice) {
    if (invoice is SalesInvoice) {
      return invoice.subtotal;
    } else if (invoice is PurchaseInvoice) {
      return invoice.subtotal;
    }
    return 0.0;
  }

  double _getDiscountAmount(dynamic invoice) {
    if (invoice is SalesInvoice) {
      return invoice.discountAmount;
    } else if (invoice is PurchaseInvoice) {
      return invoice.discountAmount;
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
