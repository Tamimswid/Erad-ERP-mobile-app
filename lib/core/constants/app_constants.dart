import 'package:flutter/material.dart';

// Tokens mirror the shadcn "natural" (taupe) dark palette.
// success/warning keep readable data accents; error uses the destructive token.
class AppColors {
  static const background = Color(0xFF272727);
  static const surface = Color(0xFF171717);
  static const text = Color(0xFFFBFAF9);

  static const primary = Color(0xFFE5E5E5);
  static const onPrimary = Color(0xFF171717);
  static const onPrimaryMuted = Color(0xB3171717);

  static const success = Color(0xFF2EB88A);
  static const warning = Color(0xFFE88C30);
  static const error = Color(0xFFFF6467);

  static const textSecondary = Color(0xFFABA09C);
  static const divider = Color(0xFF1E1E1E);
  static const border = Color(0xFF1E1E1E);
  static const muted = Color(0xFF1E1E1E);
  static const ring = Color(0xFF7C6D67);

  // Aliases
  static const secondary = textSecondary;
  static const info = textSecondary;
  static const accent = primary;
}

class AppStrings {
  // App Info
  static const appName = 'ERAD';
  static const appSubtitle = 'نظام المحاسبة والمخزون';

  // Navigation
  static const dashboard = 'لوحة التحكم';
  static const customers = 'العملاء';
  static const products = 'المنتجات';
  static const invoices = 'الفواتير';
  static const analytics = 'التحليلات';
  static const suppliers = 'الموردون';
  static const expenses = 'المصروفات';
  static const settings = 'الإعدادات';

  // Auth
  static const login = 'تسجيل الدخول';
  static const logout = 'تسجيل الخروج';
  static const email = 'البريد الإلكتروني';
  static const password = 'كلمة المرور';
  static const forgotPassword = 'نسيت كلمة المرور؟';
  static const rememberMe = 'تذكرني';

  // Common
  static const save = 'حفظ';
  static const cancel = 'إلغاء';
  static const delete = 'حذف';
  static const edit = 'تعديل';
  static const add = 'إضافة';
  static const search = 'بحث';
  static const filter = 'فلتر';
  static const export = 'تصدير';
  static const print = 'طباعة';
  static const close = 'إغلاق';
  static const confirm = 'تأكيد';
  static const yes = 'نعم';
  static const no = 'لا';
  static const loading = 'جاري التحميل...';
  static const error = 'خطأ';
  static const success = 'نجاح';
  static const warning = 'تحذير';

  // Stock Status
  static const stockSufficient = 'مخزون كافٍ';
  static const stockLow = 'مخزون منخفض';
  static const stockCritical = 'مخزون حرج';

  // Payment Status
  static const paid = 'مدفوع';
  static const pending = 'معلق';
  static const overdue = 'متأخر';

  // Invoice Types
  static const salesInvoice = 'فاتورة بيع';
  static const purchaseInvoice = 'فاتورة شراء';
}

class AppConstants {
  // LAYOUT
  static const double sidebarWidth = 200.0;
  static const double contentPadding = 24.0;
  static const double cardPadding = 20.0;
  static const double gap = 16.0;
  static const double gapSmall = 8.0;
  static const double gapLarge = 32.0;

  // SPACING - Tutarlı padding sistemi
  static const double spacing = 8.0;
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;

  // BORDERS - shadcn radius scale (radius 0.5)
  static const double borderRadius = 8.0;
  static const double borderRadiusSm = 4.0;
  static const double borderRadiusMd = 6.0;
  static const double borderRadiusLg = 12.0;

  // SHADOW - Flat surfaces, border carries the separation
  static const double cardElevation = 0.0;
  static List<BoxShadow> get cardShadow => const [];

  // Window Size
  static const double minWindowWidth = 1024.0;
  static const double minWindowHeight = 768.0;

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Number Formats
  static const String currencyFormat = '###,###.##';
  static const String dateFormat = 'yyyy-MM-dd';

  // Stock Thresholds
  static const double lowStockThreshold = 0.2;
  static const double criticalStockThreshold = 0.1;
}

class AppRoutes {
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String customers = '/customers';
  static const String customerDetails = '/customers/:id';
  static const String products = '/products';
  static const String productDetails = '/products/:id';
  static const String invoices = '/invoices';
  static const String invoiceDetails = '/invoices/:id';
  static const String createInvoice = '/invoices/create';
  static const String analytics = '/analytics';
  static const String suppliers = '/suppliers';
  static const String supplierDetails = '/suppliers/:id';
  static const String expenses = '/expenses';
  static const String expenseDetails = '/expenses/:id';
  static const String withdrawals = '/withdrawals';
  static const String settings = '/settings';
  static const String profile = '/profile';
  static const String debts = '/debts';
  static const String takrirler = '/takrirler';
}

class AppFonts {
  static const String arabicFont = 'Tajawal';
  static const String latinFont = 'Tajawal';

  // TYPOGRAPHY - shadcn type scale
  static const double fontSizeSmall = 12.0;
  static const double fontSizeMedium = 14.0;
  static const double fontSizeLarge = 16.0;
  static const double fontSizeXLarge = 18.0;
  static const double fontSizeXXLarge = 20.0;
  static const double fontSizeXXXLarge = 30.0;
  static const double fontSizeDisplay = 36.0;

  // Font Weights
  static const FontWeight fontWeightRegular = FontWeight.w400;
  static const FontWeight fontWeightMedium = FontWeight.w500;
  static const FontWeight fontWeightSemiBold = FontWeight.w600;
  static const FontWeight fontWeightBold = FontWeight.w700;
}

class AppAssets {
  static const String logo = 'assets/images/logo.png';
  static const String loadingAnimation = 'assets/images/loading.gif';
}
