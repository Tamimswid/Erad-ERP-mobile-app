import 'package:flutter/material.dart';
import '../../../../core/utils/custom_date_range_picker.dart';

class InvoiceFiltersWidget extends StatefulWidget {
  final String selectedType;
  final String selectedStatus;
  final String searchQuery;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final Function(String) onTypeChanged;
  final Function(String) onStatusChanged;
  final Function(String) onSearchChanged;
  final Function(DateTime?, DateTime?) onDateRangeChanged;

  const InvoiceFiltersWidget({
    super.key,
    required this.selectedType,
    required this.selectedStatus,
    required this.searchQuery,
    this.dateFrom,
    this.dateTo,
    required this.onTypeChanged,
    required this.onStatusChanged,
    required this.onSearchChanged,
    required this.onDateRangeChanged,
  });

  @override
  State<InvoiceFiltersWidget> createState() => _InvoiceFiltersWidgetState();
}

class _InvoiceFiltersWidgetState extends State<InvoiceFiltersWidget> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.searchQuery;
    _searchController.addListener(() {
      widget.onSearchChanged(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          _buildFirstRow(),
          const SizedBox(height: 16),
          _buildSecondRow(),
        ],
      ),
    );
  }

  Widget _buildFirstRow() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: _buildTypeFilter(),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 3,
          child: _buildSearchField(),
        ),
      ],
    );
  }

  Widget _buildSecondRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatusFilter(),
        ),
        const SizedBox(width: 16),
        _buildDateFilter(),
      ],
    );
  }

  Widget _buildTypeFilter() {
    return Row(
      children: [
        Text(
          'ألنوع:',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: const Color(0xFF6B7280),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Row(
            children: [
              _buildFilterButton(
                'الكل',
                widget.selectedType == 'all',
                () => widget.onTypeChanged('all'),
              ),
              const SizedBox(width: 8),
              _buildFilterButton(
                'بيع',
                widget.selectedType == 'sale',
                () => widget.onTypeChanged('sale'),
                icon: Icons.trending_up,
              ),
              const SizedBox(width: 8),
              _buildFilterButton(
                'شراء',
                widget.selectedType == 'purchase',
                () => widget.onTypeChanged('purchase'),
                icon: Icons.trending_down,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'بحث عن فاتورة أو عميل أو مورد...',
        prefixIcon: const Icon(Icons.search, color: Color(0xFF9CA3AF)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF3B82F6)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      ),
    );
  }

  Widget _buildStatusFilter() {
    return Row(
      children: [
        Text(
          'الحالة:',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: const Color(0xFF6B7280),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFilterButton(
                'الكل',
                widget.selectedStatus == 'all',
                () => widget.onStatusChanged('all'),
              ),
              _buildFilterButton(
                'مدفوع',
                widget.selectedStatus == 'paid',
                () => widget.onStatusChanged('paid'),
              ),
              _buildFilterButton(
                'قيد الانتظار',
                widget.selectedStatus == 'pending',
                () => widget.onStatusChanged('pending'),
              ),
              _buildFilterButton(
                'مسودة',
                widget.selectedStatus == 'draft',
                () => widget.onStatusChanged('draft'),
              ),
              _buildFilterButton(
                'متأخر',
                widget.selectedStatus == 'overdue',
                () => widget.onStatusChanged('overdue'),
              ),
              _buildFilterButton(
                'ملغي',
                widget.selectedStatus == 'cancelled',
                () => widget.onStatusChanged('cancelled'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateFilter() {
    return Row(
      children: [
        Text(
          'التاريخ:',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: const Color(0xFF6B7280),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 120,
          child: TextField(
            readOnly: true,
            onTap: () => _selectDateRange(context),
            decoration: InputDecoration(
              hintText: widget.dateFrom != null
                  ? '${widget.dateFrom!.day}/${widget.dateFrom!.month}/${widget.dateFrom!.year}'
                  : 'البداية',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text('—', style: TextStyle(color: Color(0xFF9CA3AF))),
        ),
        SizedBox(
          width: 120,
          child: TextField(
            readOnly: true,
            onTap: () => _selectDateRange(context),
            decoration: InputDecoration(
              hintText: widget.dateTo != null
                  ? '${widget.dateTo!.day}/${widget.dateTo!.month}/${widget.dateTo!.year}'
                  : 'نهاية',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () => widget.onDateRangeChanged(null, null),
          icon: const Icon(Icons.close, color: Color(0xFF9CA3AF), size: 20),
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFFF3F4F6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterButton(String text, bool isActive, VoidCallback onPressed, {IconData? icon}) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: isActive ? const Color(0xFFEFF6FF) : Colors.white,
        foregroundColor: isActive ? const Color(0xFF1D4ED8) : const Color(0xFF4B5563),
        side: BorderSide(
          color: isActive ? const Color(0xFF2563EB) : const Color(0xFFE5E7EB),
          width: 1.5,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        minimumSize: const Size(0, 32),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? initialRange = widget.dateFrom != null && widget.dateTo != null
        ? DateTimeRange(start: widget.dateFrom!, end: widget.dateTo!)
        : null;

    await CustomDateRangePicker.showDateRangePicker(
      context: context,
      onDateRangeChanged: (dateRange) {
        widget.onDateRangeChanged(dateRange.start, dateRange.end);
      },
      initialDateRange: initialRange,
      firstDate: DateTime(2026),
      lastDate: DateTime.now(),
      startDateText: 'start_date',
      endDateText: 'end_date',
      confirmText: 'confirm',
      cancelText: 'cancel',
    );
  }
}
