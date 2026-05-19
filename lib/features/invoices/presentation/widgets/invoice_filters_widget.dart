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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          _buildSearchField(),
          const SizedBox(height: 10),
          _buildSecondRow(),
        ],
      ),
    );
  }

  Widget _buildFirstRow() {
    return Column(
      children: [
        _buildSearchField(),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildSecondRow() {
    return Row(
      children: [
        Expanded(
          child: _buildTypeFilter(),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatusFilter(),
        ),
      ],
    );
  }

  Widget _buildTypeFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: widget.selectedType,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 18),
          style: const TextStyle(fontSize: 13),
          items: const [
            DropdownMenuItem(value: 'all', child: Text('الكل')),
            DropdownMenuItem(value: 'sale', child: Text('بيع')),
            DropdownMenuItem(value: 'purchase', child: Text('شراء')),
          ],
          onChanged: (value) {
            if (value != null) {
              widget.onTypeChanged(value);
            }
          },
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'بحث عن فاتورة أو عميل أو مورد...',
        hintStyle: const TextStyle(fontSize: 13),
        prefixIcon: const Icon(Icons.search, color: Color(0xFF9CA3AF), size: 20),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        isDense: true,
      ),
      style: const TextStyle(fontSize: 13),
    );
  }

  Widget _buildStatusFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: widget.selectedStatus,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 18),
          style: const TextStyle(fontSize: 13),
          items: const [
            DropdownMenuItem(value: 'all', child: Text('الكل')),
            DropdownMenuItem(value: 'paid', child: Text('مدفوع')),
            DropdownMenuItem(value: 'pending', child: Text('قيد الانتظار')),
            DropdownMenuItem(value: 'draft', child: Text('مسودة')),
            DropdownMenuItem(value: 'cancelled', child: Text('ملغي')),
          ],
          onChanged: (value) {
            if (value != null) {
              widget.onStatusChanged(value);
            }
          },
        ),
      ),
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

  
  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? initialRange = widget.dateFrom != null && widget.dateTo != null
        ? DateTimeRange(start: widget.dateFrom!, end: widget.dateTo!)
        : null;

    // await CustomDateRangePicker.showDateRangePicker(
    //   context: context,
    //   onDateRangeChanged: (dateRange) {
    //     widget.onDateRangeChanged(dateRange.start, dateRange.end);
    //   },
    //   initialDateRange: initialRange,
    //   firstDate: DateTime(2026),
    //   lastDate: DateTime.now(),
    //   startDateText: 'start_date',
    //   endDateText: 'end_date',
    //   confirmText: 'confirm',
    //   cancelText: 'cancel',
    // );
  }
}
