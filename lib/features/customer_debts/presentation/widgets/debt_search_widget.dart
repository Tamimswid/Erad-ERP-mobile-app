import 'dart:async';
import 'package:erad/core/constants/app_constants.dart';
import 'package:flutter/material.dart';

class DebtSearchWidget extends StatefulWidget {
  final Function(String query) onSearchChanged;

  const DebtSearchWidget({
    super.key,
    required this.onSearchChanged,
  });

  @override
  State<DebtSearchWidget> createState() => _DebtSearchWidgetState();
}

class _DebtSearchWidgetState extends State<DebtSearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      widget.onSearchChanged(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLg),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'البحث بالاسم أو رقم الهاتف...',
                hintStyle: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: AppFonts.fontSizeMedium,
                ),
                prefixIcon: Icon(
                  Icons.search_outlined,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                  borderSide: BorderSide(color: AppColors.primary),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          if (_searchController.text.isNotEmpty) ...[
            const SizedBox(width: 12),
            IconButton(
              onPressed: () {
                _searchController.clear();
                _onSearchChanged('');
              },
              icon: Icon(
                Icons.clear,
                color: AppColors.textSecondary,
              ),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.background,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
