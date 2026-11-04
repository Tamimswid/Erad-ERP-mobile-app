import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;
import '../../../../core/constants/app_constants.dart';
import '../../data/models/partner.dart';

class UserSelectorWidget extends StatefulWidget {
  final Partner? selectedPartner;
  final VoidCallback onAddNew;
  final VoidCallback? onClearSelection;
  final List<Partner> partners;
  final Function(Partner) onSelectPartner;

  const UserSelectorWidget({
    super.key,
    this.selectedPartner,
    required this.onAddNew,
    this.onClearSelection,
    required this.partners,
    required this.onSelectPartner,
  });

  @override
  State<UserSelectorWidget> createState() => _UserSelectorWidgetState();
}

class _UserSelectorWidgetState extends State<UserSelectorWidget> {
  final _searchController = TextEditingController();
  bool _isDropdownOpen = false;
  List<Partner> _filteredPartners = [];

  @override
  void initState() {
    super.initState();
    _filteredPartners = widget.partners;
  }

  @override
  void didUpdateWidget(UserSelectorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.partners != oldWidget.partners) {
      _filterPartners(_searchController.text);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterPartners(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredPartners = widget.partners;
      } else {
        _filteredPartners = widget.partners.where((p) {
          final name = p.name.toLowerCase();
          final phone = p.phone?.toLowerCase() ?? '';
          return name.contains(query.toLowerCase()) ||
              phone.contains(query.toLowerCase());
        }).toList();
      }
      _isDropdownOpen = true;
    });
  }

  void _selectPartner(Partner partner) {
    widget.onSelectPartner(partner);
    _searchController.text = partner.name;
    setState(() => _isDropdownOpen = false);
  }

  void _clearSelection() {
    widget.onClearSelection?.call();
    _searchController.clear();
    setState(() => _isDropdownOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    return sc.Card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'إضافة / اختيار مستخدم',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: _buildSearchField()),
              const SizedBox(width: 10),
              _buildAddButton(),
            ],
          ),
          if (widget.selectedPartner != null) ...[
            const SizedBox(height: 14),
            _buildSelectedPartner(),
          ],
          if (_isDropdownOpen && _filteredPartners.isNotEmpty) ...[
            const SizedBox(height: 4),
            _buildDropdown(),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: constraints.maxWidth < 300 ? constraints.maxWidth : 280,
          child: TextField(
            controller: _searchController,
            onChanged: _filterPartners,
            decoration: InputDecoration(
              hintText: 'بحث...',
              prefixIcon: const Icon(
                sc.LucideIcons.search,
                color: AppColors.textSecondary,
                size: 18,
              ),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddButton() {
    return sc.Button(
      alignment: Alignment.center,
      style: sc.ButtonStyle.primary(),
      onPressed: widget.onAddNew,
      leading: const Icon(sc.LucideIcons.plus, size: 16),
      child: const Text(
        'إضافة جديد',
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildSelectedPartner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.selectedPartner!.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.selectedPartner!.phone ?? '-',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (widget.onClearSelection != null)
            IconButton(
              onPressed: _clearSelection,
              icon: const Icon(
                sc.LucideIcons.x,
                color: AppColors.textSecondary,
                size: 18,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  Widget _buildDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: AppColors.text.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      constraints: const BoxConstraints(maxHeight: 220),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _filteredPartners.length,
        itemBuilder: (context, index) {
          final partner = _filteredPartners[index];
          return InkWell(
            onTap: () => _selectPartner(partner),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                border: index < _filteredPartners.length - 1
                    ? const Border(bottom: BorderSide(color: AppColors.divider))
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          partner.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.text,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          partner.phone ?? '-',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    sc.LucideIcons.chevronRight,
                    color: AppColors.textSecondary,
                    size: 16,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
