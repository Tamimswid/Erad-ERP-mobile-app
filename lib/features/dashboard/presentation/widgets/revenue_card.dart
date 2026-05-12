import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../../invoices/presentation/bloc/invoice_cubit.dart';
import '../../../invoices/data/models/sales_invoice.dart';
import '../../../invoices/data/models/purchase_invoice.dart';

class RevenueCard extends StatefulWidget {
  final DateTimeRange? dateRange;
  const RevenueCard({super.key, this.dateRange});

  @override
  State<RevenueCard> createState() => _RevenueCardState();
}

class _RevenueCardState extends State<RevenueCard> {
  double _preservedTotalPurchase = 0;
  double _preservedTotalRevenue = 0;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InvoiceCubit, InvoiceState>(
      builder: (context, state) {
        log('DEBUG: RevenueCard received state: ${state.runtimeType}');

        // Start with preserved values
        double totalRevenue = _preservedTotalRevenue;
        double totalPurchase = _preservedTotalPurchase;
        List<SalesInvoice> salesInvoices = [];
        List<PurchaseInvoice> purchaseInvoices = [];

        // Handle new InvoiceFiltered state
        if (state is InvoiceFiltered) {
          salesInvoices = state.salesInvoices
              .where((i) => i.paymentStatus.toString() != 'SalesInvoiceStatus.cancelled')
              .toList();
          purchaseInvoices = state.purchaseInvoices
              .where((i) => i.paymentStatus.toString() != 'PurchaseInvoiceStatus.cancelled')
              .toList();
          
          totalRevenue = salesInvoices.fold(0, (sum, i) => sum + i.totalAmount);
          totalPurchase = purchaseInvoices.fold(0, (sum, i) => sum + i.totalAmount);
          _preservedTotalRevenue = totalRevenue;
          _preservedTotalPurchase = totalPurchase;
          
          log('DEBUG: InvoiceFiltered - Revenue: $totalRevenue, Purchase: $totalPurchase');
        }
        // Handle legacy states for backward compatibility
        else if (state is FilteredSalesInvoicesLoaded) {
          salesInvoices = state.invoices
              .where((i) => i.paymentStatus.toString() != 'SalesInvoiceStatus.cancelled')
              .toList();
          final filteredSalesInvoices = _filterInvoices(
            salesInvoices,
            widget.dateRange,
          );
          totalRevenue = salesInvoices.fold(0, (sum, i) => sum + i.totalAmount);
          _preservedTotalRevenue = totalRevenue;
          log('DEBUG: FilteredSalesInvoicesLoaded - Total Revenue: $totalRevenue');
          salesInvoices = filteredSalesInvoices;
        } else if (state is SalesInvoicesLoaded) {
          salesInvoices = state.invoices
              .where((i) => i.paymentStatus.toString() != 'SalesInvoiceStatus.cancelled')
              .toList();
          totalRevenue = salesInvoices.fold(0, (sum, i) => sum + i.totalAmount);
          _preservedTotalRevenue = totalRevenue;
          salesInvoices = _filterInvoices(salesInvoices, widget.dateRange);
        }
        // Handle purchase invoices separately
        else if (state is FilteredPurchaseInvoicesLoaded) {
          purchaseInvoices = state.invoices
              .where((i) => i.paymentStatus.toString() != 'PurchaseInvoiceStatus.cancelled')
              .toList();
          totalPurchase = purchaseInvoices.fold(0, (sum, i) => sum + i.totalAmount);
          log('DEBUG: FilteredPurchaseInvoicesLoaded - Total Purchase: $totalPurchase');
        } else if (state is PurchaseInvoicesLoaded) {
          purchaseInvoices = state.invoices
              .where((i) => i.paymentStatus.toString() != 'PurchaseInvoiceStatus.cancelled')
              .toList();
          totalPurchase = purchaseInvoices.fold(0, (sum, i) => sum + i.totalAmount);
          _preservedTotalPurchase = totalPurchase;
          log('DEBUG: PurchaseInvoicesLoaded - Total Purchase: $totalPurchase, Count: ${purchaseInvoices.length}');
        }

        log(
          'DEBUG: Final values - TotalRevenue: $totalRevenue, TotalPurchase: $totalPurchase, Profit: ${totalRevenue - totalPurchase}',
        );

        // Use preserved values for display
        final displayRevenue = _preservedTotalRevenue;
        final displayPurchase = _preservedTotalPurchase;
        final profit = displayRevenue - displayPurchase;
        final chartData = _getChartData(salesInvoices, widget.dateRange);
        final monthlyValues = chartData.map((d) => d.amount).toList();
        final chartLabels = chartData.map((d) => d.label).toList();

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.divider),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              const Text(
                'إجمالي المبيعات',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 16),
              // Total amount row
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    NumberFormatter.formatShort(totalRevenue),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    NumberFormatter.getCurrencySymbol(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Purchase info
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'المشتريات:',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    NumberFormatter.format(displayPurchase),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Chart
              SizedBox(
                height: 200,
                child: monthlyValues.isNotEmpty
                    ? _buildChart(monthlyValues, chartLabels)
                    : Center(
                        child: Text(
                          'لا توجد بيانات مبيعات',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<SalesInvoice> _filterInvoices(
    List<SalesInvoice> invoices,
    DateTimeRange? dateRange,
  ) {
    if (dateRange == null) {
      // Default: current year
      final now = DateTime.now();
      return invoices.where((invoice) => invoice.invoiceDate.year == now.year).toList();
    }
    return invoices.where((invoice) {
      final invoiceDate = invoice.invoiceDate;
      return (invoiceDate.isAfter(dateRange.start) || invoiceDate.isAtSameMomentAs(dateRange.start)) &&
             (invoiceDate.isBefore(dateRange.end) || invoiceDate.isAtSameMomentAs(dateRange.end));
    }).toList();
  }

  List<SalesData> _getChartData(
    List<SalesInvoice> invoices,
    DateTimeRange? dateRange,
  ) {
    // Group invoices by date based on dateRange
    Map<String, double> groupedData = {};

    DateTime now = DateTime.now();
    DateFormat dateFormat;

    if (dateRange == null) {
      // Default: this year - show months
      dateFormat = DateFormat('MMM', 'ar');
      for (int i = 1; i <= 12; i++) {
        final date = DateTime(now.year, i, 1);
        groupedData[dateFormat.format(date)] = 0;
      }
      // Sum up invoice amounts for current year
      for (final invoice in invoices) {
        if (invoice.invoiceDate.year == now.year) {
          final key = dateFormat.format(invoice.invoiceDate);
          groupedData[key] = (groupedData[key] ?? 0) + invoice.totalAmount;
        }
      }
    } else {
      // Check if range is within a single month
      final isSingleMonth = dateRange.start.year == dateRange.end.year && 
                           dateRange.start.month == dateRange.end.month;
      
      if (isSingleMonth) {
        // Show days
        dateFormat = DateFormat('d', 'ar');
        final daysInMonth = DateTime(dateRange.start.year, dateRange.start.month + 1, 0).day;
        for (int i = 1; i <= daysInMonth; i++) {
          groupedData[i.toString()] = 0;
        }
        // Sum up invoice amounts within range
        for (final invoice in invoices) {
          if (invoice.invoiceDate.isBefore(dateRange.start) || 
              invoice.invoiceDate.isAfter(dateRange.end)) continue;
          final key = dateFormat.format(invoice.invoiceDate);
          groupedData[key] = (groupedData[key] ?? 0) + invoice.totalAmount;
        }
      } else {
        // Show months
        dateFormat = DateFormat('MMM', 'ar');
        // Create data for months in range
        var current = DateTime(dateRange.start.year, dateRange.start.month, 1);
        final end = DateTime(dateRange.end.year, dateRange.end.month, 1);
        
        while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
          groupedData[dateFormat.format(current)] = 0;
          current = DateTime(current.year, current.month + 1, 1);
        }
        // Sum up invoice amounts within range
        for (final invoice in invoices) {
          if (invoice.invoiceDate.isBefore(dateRange.start) || 
              invoice.invoiceDate.isAfter(dateRange.end)) continue;
          final key = dateFormat.format(invoice.invoiceDate);
          groupedData[key] = (groupedData[key] ?? 0) + invoice.totalAmount;
        }
      }
    }

    // Convert to chart data and sort
    var sortedEntries = groupedData.entries.toList()
      ..sort((a, b) {
        // Try to parse as int for day sorting
        final aInt = int.tryParse(a.key);
        final bInt = int.tryParse(b.key);
        if (aInt != null && bInt != null) {
          return aInt.compareTo(bInt);
        }
        return a.key.compareTo(b.key);
      });

    return sortedEntries.map((e) => SalesData(e.key, e.value)).toList();
  }

  Widget _buildChart(List<double> values, List<String> labels) {
    final maxY = _calculateMaxY(values);
    
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipPadding: const EdgeInsets.all(8),
            tooltipMargin: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                NumberFormatter.format(rod.toY),
                const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= labels.length) return const SizedBox();
                return Text(
                  labels[index],
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                );
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox();
                final formatted = _formatCompactNumber(value);
                return Text(
                  formatted,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                );
              },
              reservedSize: 40,
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawHorizontalLine: true,
          horizontalInterval: maxY / 5,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: AppColors.divider,
              strokeWidth: 1,
            );
          },
          drawVerticalLine: false,
        ),
        borderData: FlBorderData(show: false),
        barGroups: values.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value,
                color: AppColors.primary,
                width: 16,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
            ],
            showingTooltipIndicators: entry.value > 0 ? [0] : [],
          );
        }).toList(),
      ),
    );
  }

  double _calculateMaxY(List<double> values) {
    if (values.isEmpty) return 100;
    final max = values.reduce((a, b) => a > b ? a : b);
    if (max <= 0) return 100;
    return max * 1.2;
  }

  String _formatCompactNumber(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toStringAsFixed(0);
  }
}

class SalesData {
  final String label;
  final double amount;

  SalesData(this.label, this.amount);
}
