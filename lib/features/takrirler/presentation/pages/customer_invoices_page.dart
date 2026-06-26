import 'dart:developer';

import 'package:erad/core/constants/app_constants.dart';
import 'package:erad/core/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'customer_invoice_detail_page.dart';

class CustomerInvoicesPage extends StatefulWidget {
  final bool isSupplier;

  const CustomerInvoicesPage({super.key, this.isSupplier = false});

  @override
  State<CustomerInvoicesPage> createState() => _CustomerInvoicesPageState();
}

class _CustomerInvoicesPageState extends State<CustomerInvoicesPage> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _filteredItems = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    try {
      final userId = await UserService.getUserId();
      if (userId == null) return;

      final String table = widget.isSupplier ? 'suppliers' : 'customers';

      final response = await _supabase
          .from(table)
          .select('id, name, phone')
          .eq('user_id', userId)
          .order('name');

      if (mounted) {
        setState(() {
          _items = List<Map<String, dynamic>>.from(response);
          _filteredItems = _items;
          _isLoading = false;
        });
      }
    } catch (e) {
      log('Failed to load: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query.trim();
      if (_searchQuery.isEmpty) {
        _filteredItems = _items;
      } else {
        _filteredItems = _items.where((item) {
          final name = (item['name'] as String? ?? '').toLowerCase();
          final phone = item['phone'] as String? ?? '';
          return name.contains(_searchQuery.toLowerCase()) ||
              phone.contains(_searchQuery);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.isSupplier ? 'فواتير مورد' : 'فواتير مشتري'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'بحث...',
                prefixIcon: const Icon(Iconsax.search_normal),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: _onSearch,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Iconsax.profile_delete,
                                size: 64, color: AppColors.textSecondary),
                            const SizedBox(height: 16),
                            Text(
                              widget.isSupplier
                                  ? 'لا يوجد موردون'
                                  : 'لا يوجد عملاء',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = _filteredItems[index];
                          final name = item['name'] as String? ?? '';
                          final phone = item['phone'] as String?;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              leading: CircleAvatar(
                                backgroundColor:
                                    AppColors.primary.withValues(alpha: 0.1),
                                child: Text(
                                  name.isNotEmpty ? name[0] : '?',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle:
                                  phone != null ? Text(phone) : null,
                              trailing: const Icon(Iconsax.arrow_left),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        CustomerInvoiceDetailPage(
                                      partyId: item['id'] as String,
                                      partyName: name,
                                      isSupplier: widget.isSupplier,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
