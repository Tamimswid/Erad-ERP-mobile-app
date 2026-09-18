import 'package:erad/features/invoices/data/models/invoice.dart';
import 'package:erad/features/invoices/data/models/invoice_status.dart' as status_models;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class InvoicePdfService {
  static Future<void> generateAndPrintInvoice(Invoice invoice) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        invoice.type == InvoiceType.sale ? 'فاتورة بيع' : 'فاتورة شراء',
                        style:  pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        invoice.invoiceNumber,
                        style:  pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      color: _getStatusColor(invoice.status),
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Text(
                      _getStatusText(invoice.status),
                      style:  pw.TextStyle(
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 24),
              
              // Customer/Supplier Information
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      invoice.type == InvoiceType.sale ? 'معلومات العميل' : 'معلومات المورد',
                      style:  pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      invoice.type == InvoiceType.sale 
                          ? 'العميل: ${invoice.customerName ?? "غير محدد"}'
                          : 'المورد: ${invoice.supplierName ?? "غير محدد"}',
                    ),
                    pw.Text(
                      'تاريخ الإصدار: ${DateFormat('yyyy-MM-dd').format(invoice.issueDate)}',
                    ),
                    if (invoice.dueDate != null)
                      pw.Text(
                        'تاريخ الاستحقاق: ${DateFormat('yyyy-MM-dd').format(invoice.dueDate!)}',
                      ),
                  ],
                ),
              ),
              pw.SizedBox(height: 24),
              
              // Items Table
              pw.Text(
                'بنود الفاتورة',
                style:  pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 12),
              
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(1),
                  2: const pw.FlexColumnWidth(1),
                  3: const pw.FlexColumnWidth(1),
                  4: const pw.FlexColumnWidth(1),
                },
                children: [
                  // Header
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      _buildTableCell('المنتج', isBold: true),
                      _buildTableCell('الكمية', isBold: true),
                      _buildTableCell('السعر', isBold: true),
                      _buildTableCell('الخصم', isBold: true),
                      _buildTableCell('الإجمالي', isBold: true),
                    ],
                  ),
                  // Items
                  ...invoice.items.map((item) => pw.TableRow(
                    children: [
                       _buildTableCell(item.productName ?? 'null_data'),
                       _buildTableCell((item.quantity ?? 0).toString()),
                       _buildTableCell('${(item.unitPrice ?? 0.0).toStringAsFixed(2)}'),
                       _buildTableCell('${(item.totalPrice ?? 0.0).toStringAsFixed(2)}'),
                    ],
                  ))
                ],
              ),
              pw.SizedBox(height: 24),
              
              // Totals
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  children: [
                    _buildTotalRow('المجموع الفرعي:', invoice.subtotal),
                    _buildTotalRow('الضريبة (${invoice.taxRate}%):', invoice.taxAmount),
                    _buildTotalRow('الخصم:', invoice.discountAmount),
                    pw.Divider(color: PdfColors.grey300),
                    _buildTotalRow('الإجمالي:', invoice.totalAmount, isBold: true),
                    if (invoice.paidAmount != null)
                      _buildTotalRow('المدفوع:', invoice.paidAmount!),
                    if (invoice.remainingAmount != null)
                      _buildTotalRow('المتبقي:', invoice.remainingAmount!),
                  ],
                ),
              ),
              
              // Notes and Terms
              if (invoice.notes != null || invoice.terms != null) ...[
                pw.SizedBox(height: 24),
                if (invoice.notes != null) ...[
                  pw.Text(
                    'ملاحظات:',
                    style:  pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(invoice.notes!),
                  pw.SizedBox(height: 12),
                ],
                if (invoice.terms != null) ...[
                  pw.Text(
                    'الشروط والأحكام:',
                    style:  pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(invoice.terms!),
                ],
              ],
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: '${invoice.invoiceNumber}.pdf',
    );
  }

  static pw.Widget _buildTableCell(String text, {bool isBold = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _buildTotalRow(String label, double amount, {bool isBold = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            '${amount.toStringAsFixed(2)} ل.س',
            style: pw.TextStyle(
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  static PdfColor _getStatusColor(InvoiceStatus status) {
    final statusModel = status_models.InvoiceStatus.fromString(status.name);
    final color = statusModel.getColor;
    // Convert Flutter Color to PdfColor
    return PdfColor.fromInt(color.value);
  }

  static String _getStatusText(InvoiceStatus status) {
    final statusModel = status_models.InvoiceStatus.fromString(status.name);
    return statusModel.getArabicName;
  }
}
