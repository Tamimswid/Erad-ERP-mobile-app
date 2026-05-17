import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../../auth/data/models/user.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _selectedCurrency = NumberFormatter.selectedCurrency;
  bool _useShortFormat = NumberFormatter.useShortFormat;
  final _companyNameController = TextEditingController();
  bool _isLoadingCompany = false;

  User? get _currentUser {
    final authState = context.read<AuthCubit>().state;
    if (authState is Authenticated) {
      return authState.user;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    final user = _currentUser;
    _companyNameController.text = user?.businessName ?? '';
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  IconButton(
                    color: Colors.black,
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.navigate_before, size: 30),
                  ),
                  const Text(
                    'الإعدادات',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.normal,
                      color: AppColors.text,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Company Name Card
              _buildCompanyNameCard(),
              const SizedBox(height: 16),
              // Settings cards
              _buildCurrencyCard(),
              const SizedBox(height: 16),
              _buildNumberFormatCard(),
              const SizedBox(height: 16),
              _buildLogoutCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompanyNameCard() {
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
          const Text(
            'معلومات الشركة',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'اسم الشركة المعروض في الفواتير',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _companyNameController,
                  decoration: InputDecoration(
                    hintText: 'اسم الشركة',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.divider),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.divider),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _isLoadingCompany ? null : _updateCompanyName,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoadingCompany
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'حفظ',
                        style: TextStyle(color: Colors.white),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _updateCompanyName() async {
    final user = _currentUser;
    if (user == null) return;

    final newCompanyName = _companyNameController.text.trim();
    if (newCompanyName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال اسم الشركة')),
      );
      return;
    }

    setState(() {
      _isLoadingCompany = true;
    });

    try {
      await context.read<AuthCubit>().updateProfile(
            user.copyWith(businessName: newCompanyName),
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحديث اسم الشركة بنجاح'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في التحديث: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingCompany = false;
        });
      }
    }
  }

  Widget _buildCurrencyCard() {
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
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'العملة',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'اختر العملة الافتراضية',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Currency selector
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: NumberFormatter.availableCurrencies.map((currency) {
              final isSelected = _selectedCurrency == currency;
              return InkWell(
                onTap: () async {
                  await NumberFormatter.setCurrency(currency);
                  setState(() {
                    _selectedCurrency = currency;
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.divider,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    currency,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: isSelected ? Colors.white : AppColors.text,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberFormatCard() {
    return InkWell(
      onTap: () async {
        final newValue = !_useShortFormat;
        await NumberFormatter.setUseShortFormat(newValue);
        setState(() {
          _useShortFormat = newValue;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.divider),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'تنسيق الأرقام',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'استخدام K/M للأرقام الكبيرة',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: _useShortFormat,
              onChanged: (value) async {
                await NumberFormatter.setUseShortFormat(value);
                setState(() {
                  _useShortFormat = value;
                });
              },
              activeColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutCard() {
    return InkWell(
      onTap: () => _showLogoutConfirmation(logout: () {
            Navigator.pop(context);
              context.read<AuthCubit>().logout();
      },),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.divider),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(Icons.logout, color: AppColors.error, size: 20),
            const SizedBox(width: 20),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'تسجيل الخروج',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'تسجيل الخروج من الحساب',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_back_ios,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutConfirmation({required Function() logout}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_outlined, color: Colors.orange[600]),
            const SizedBox(width: 8),
            const Text('تأكيد تسجيل الخروج'),
          ],
        ),
        content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => logout(),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );
  }
}
