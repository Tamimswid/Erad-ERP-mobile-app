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

  // Widget _buildFirstRow() {
  //   return Column(
  //     children: [
  //       _buildSearchField(),
  //       const SizedBox(height: 10),
  //     ],
  //   );
  // }

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
            DropdownMenuItem(value: 'all', child: Text('الكل',style: TextStyle(color: Colors.black ,fontSize: 14),)),
            DropdownMenuItem(value: 'sale', child: Text('بيع',style: TextStyle(color: Colors.black,fontSize: 14),)),
            DropdownMenuItem(value: 'purchase', child: Text('شراء',style: TextStyle(color: Colors.black,fontSize: 14),)),
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
            DropdownMenuItem(value: 'all', child: Text('الكل',style: TextStyle(fontSize: 13,color: Colors.black))),
            DropdownMenuItem(value: 'debt', child: Text('دين',style: TextStyle(fontSize: 13,color: Colors.black))),
            DropdownMenuItem(value: 'cash', child: Text(  'نقدي',style: TextStyle(fontSize: 13,color: Colors.black))),

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




}
