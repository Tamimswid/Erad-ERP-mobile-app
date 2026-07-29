# ERAD Flutter Project - Frontend Rules & Conventions

> Bu dosya, yeni bir Flutter feature geliştirirken veya mevcut feature'ları düzenlerken uyulması gereken tüm kuralları, kalıpları ve yapılandırma standartlarını tanımlar. Bu kurallar AI skill olarak kullanıldığında tutarlı ve projeye uygun kod üretmek için referans olarak kullanılır.

---

## 1. PROJE YAPISI (Project Structure)

### 1.1 Üst Dizin Yapısı
```
lib/
├── core/                    # Tüm projede paylaşılan kodlar
│   ├── constants/           # Sabit değerler (renkler, metinler, yollar, fontlar, API)
│   ├── database/            # Yerel veritabanı (Drift)
│   ├── di/                  # Bağımlılık enjeksiyonu (GetIt)
│   ├── errors/              # Hata sınıfları (Failure hierarchy)
│   ├── network/             # Ağ bilgisi kontrolü
│   ├── services/            # Paylaşılan servisler (PDF, User, vb.)
│   ├── theme/               # Tema tanımları (light/dark)
│   ├── utils/               # Yardımcı araçlar (tarih, sayı, grafik, loading)
│   └── widgets/             # Paylaşılan widget'lar (dialog, buton, kart, arama)
├── features/                # Feature modülleri (her biri bağımsız modül)
│   ├── auth/                # Kimlik doğrulama
│   ├── customer_debts/      # Müşteri borçları
│   ├── customers/           # Müşteriler
│   ├── dashboard/           # Ana sayfa / kontrol paneli
│   ├── expenses/            # Giderler
│   ├── invoices/            # Faturalar
│   ├── products/            # Ürünler
│   ├── reports/             # Raporlar
│   ├── settings/            # Ayarlar
│   ├── stock/               # Stok
│   ├── suppliers/           # Tedarikçiler
│   ├── suppliers_debts/     # Tedarikçi borçları
│   └── withdrawals/         # Çekimler / Para çekme
└── main.dart                # Uygulama giriş noktası
```

### 1.2 Feature İç Yapı Kalıbı
Her feature modülü aşağıdaki Clean Architecture yapısını takip eder:
```
features/
└── feature_name/
    ├── data/
    │   ├── datasource/           # Uzak/yakın veri kaynakları
    │   │   ├── feature_remote_datasource.dart
    │   │   └── feature_local_datasource.dart  (opsiyonel)
    │   ├── models/               # Veri modelleri
    │   │   ├── feature_model.dart
    │   │   └── feature_totals_model.dart  (opsiyonel)
    │   └── repositories/         # Repository arayüzleri ve implementasyonları
    │       ├── feature_repository.dart       (abstract)
    │       └── feature_repository_impl.dart  (implementasyon)
    └── presentation/
        ├── bloc/                 # Cubit ve State tanımları
        │   ├── feature_cubit.dart
        │   └── feature_state.dart  (part dosyası)
        ├── pages/                # Sayfa widget'ları
        │   └── feature_page.dart
        └── widgets/              # Sayfaya özel widget'lar
            ├── feature_card_widget.dart
            ├── feature_dialog.dart
            └── feature_header_widget.dart
```

---

## 2. CORE YAPISI DETAYLARI

### 2.1 Constants (`core/constants/`)

#### app_constants.dart
Tüm sabit değerler tek dosyada tanımlanır:

```dart
// RENKLER - AppColors sınıfı
class AppColors {
  // BASE PALETTE
  static const background = Color(0xFFFFFFFF);      // Açık gri beyaz
  static const surface = Color(0xFFFFFFFF);          // Saf beyaz
  static const text = Color(0xFF1A1A2E);             // Koyu gri-siyah
  
  // ACCENT - Tek vurgu rengi
  static const primary = Color(0xFF0F1B3D);          // Ana renk
  
  // SEMANTIC - Durum renkleri (minimum kullanım)
  static const success = Color(0xFF10B981);           // Yeşil
  static const warning = Color(0xFFF59E0B);          // Turuncu
  static const error = Color(0xFFEF4444);             // Kırmızı
  
  // NEUTRAL - Ara tonlar
  static const textSecondary = Color(0xFF6B7280);    // Gri
  static const divider = Color(0xFFE5E7EB);          // Açık gri
  static const border = Color(0xFFD1D5DB);           // Kenar grisi
  
  // Aliases
  static const secondary = textSecondary;
  static const info = Color(0xFF1E3A5F);
  static const accent = primary;
}
```

#### SPACING Sistemi
```dart
class AppConstants {
  // SPACING - Tutarlı padding sistemi
  static const double spacing = 8.0;
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;
  
  // BORDERS - Minimal radius
  static const double borderRadius = 8.0;
  static const double borderRadiusSm = 4.0;
  static const double borderRadiusMd = 8.0;
  static const double borderRadiusLg = 12.0;
  
  // SHADOW - Çok hafif veya yok
  static const double cardElevation = 0.0;
  
  // LAYOUT
  static const double sidebarWidth = 200.0;
  static const double contentPadding = 24.0;
  static const double cardPadding = 20.0;
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
}
```

#### Font Sistemi
```dart
class AppFonts {
  static const String arabicFont = 'Cairo';
  static const String latinFont = 'Inter';
  
  // TYPOGRAPHY - Net ve okunabilir
  static const double fontSizeSmall = 12.0;
  static const double fontSizeMedium = 14.0;
  static const double fontSizeLarge = 16.0;
  static const double fontSizeXLarge = 18.0;
  static const double fontSizeXXLarge = 20.0;
  static const double fontSizeXXXLarge = 24.0;
  static const double fontSizeDisplay = 32.0;
  
  // Font Weights
  static const FontWeight fontWeightRegular = FontWeight.w400;
  static const FontWeight fontWeightMedium = FontWeight.w500;
  static const FontWeight fontWeightSemiBold = FontWeight.w600;
  static const FontWeight fontWeightBold = FontWeight.w700;
}
```

#### Route Sabitleri
```dart
class AppRoutes {
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String customers = '/customers';
  static const String products = '/products';
  static const String invoices = '/invoices';
  static const String suppliers = '/suppliers';
  static const String expenses = '/expenses';
  static const String withdrawals = '/withdrawals';
  static const String settings = '/settings';
  static const String customerDebts = '/customer-debts';
  // ... diğer rotalar
}
```

#### String Sabitleri
```dart
class AppStrings {
  static const appName = 'ERAD';
  static const appSubtitle = 'نظام المحاسبة والمخزون';
  
  // Navigation
  static const dashboard = 'لوحة التحكم';
  static const customers = 'العملاء';
  static const products = 'المنتجات';
  static const invoices = 'الفواتير';
  static const suppliers = 'الموردون';
  static const expenses = 'المصروفات';
  static const settings = 'الإعدادات';
  
  // Auth
  static const login = 'تسجيل الدخول';
  static const logout = 'تسجيل الخروج';
  static const email = 'البريد الإلكتروني';
  static const password = 'كلمة المرور';
  
  // Common
  static const save = 'حفظ';
  static const cancel = 'إلغاء';
  static const delete = 'حذف';
  static const edit = 'تعديل';
  static const add = 'إضافة';
  static const search = 'بحث';
  static const filter = 'فلتر';
  static const confirm = 'تأكيد';
  static const loading = 'جاري التحميل...';
  static const error = 'خطأ';
  static const success = 'نجاح';
}
```

#### API Sabitleri
```dart
// api_constans.dart
class ApiConstants {
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
}
```

### 2.2 Theme (`core/theme/`)

#### app_theme.dart
```dart
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: _buildTextTheme(Brightness.light),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.text,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.cairo(
          fontSize: AppFonts.fontSizeXLarge,
          fontWeight: AppFonts.fontWeightSemiBold,
          color: AppColors.text,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: AppConstants.cardElevation,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMd),
          side: BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusMd),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: AppConstants.spacingLg,
            vertical: AppConstants.spacingMd,
          ),
          textStyle: GoogleFonts.cairo(
            fontSize: AppFonts.fontSizeMedium,
            fontWeight: AppFonts.fontWeightMedium,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMd),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMd),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMd),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
        filled: true,
        fillColor: AppColors.surface,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.text,
        contentTextStyle: GoogleFonts.cairo(
          fontSize: AppFonts.fontSizeMedium,
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMd),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusLg),
        ),
      ),
    );
  }
  
  // Dark mode için ayrı tema
  // static ThemeData get darkTheme { ... }
  
  // Latin yazı stilleri (sayılar için)
  static TextStyle get latinTextStyle {
    return GoogleFonts.inter(
      fontSize: AppFonts.fontSizeMedium,
      fontWeight: AppFonts.fontWeightRegular,
      color: AppColors.text,
    );
  }
  
  static TextStyle get latinNumberStyle {
    return GoogleFonts.inter(
      fontSize: AppFonts.fontSizeMedium,
      fontWeight: AppFonts.fontWeightMedium,
      color: AppColors.text,
    );
  }
}
```

### 2.3 Widgets (`core/widgets/`)

#### Ortak Widget Kütüphanesi (`common_widgets.dart`)
```dart
// CustomButton - Yüklenme durumlu buton
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isOutlined;
  final IconData? icon;
  final Color? color;
  final double? width;
  final double? height;
  // ...
}

// CustomTextField - Özelleştirilmiş metin alanı
class CustomTextField extends StatelessWidget {
  final String? label;
  final String? hint;
  final String? initialValue;
  final bool obscureText;
  final TextInputType keyboardType;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  // ...
}

// CustomCard - Özelleştirilmiş kart
class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  // ...
}

// EmptyStateWidget - Boş durum gösterimi
class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? action;
  // ...
}

// LoadingWidget - Yüklenme göstergesi
class LoadingWidget extends StatelessWidget {
  final String? message;
  final Color? color;
  // ...
}

// StatusBadge - Durum rozeti
class StatusBadge extends StatelessWidget {
  final String text;
  final Color color;
  // ...
}

// SearchField - Arama alanı
class SearchField extends StatefulWidget {
  final String? hint;
  final void Function(String) onChanged;
  // ...
}
```

#### Dialog Sistemi (`app_dialog.dart`)
```dart
class AppDialog {
  // Onay dialogu
  static Future<T?> showConfirmation<T>({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'تأكيد',
    String cancelText = 'إلغاء',
    bool isDangerous = false,
  }) { ... }
  
  // Bilgi dialogu
  static Future<T?> showInfo<T>({...}) { ... }
  
  // Başarı dialogu
  static Future<T?> showSuccess<T>({...}) { ... }
  
  // Hata dialogu
  static Future<T?> showError<T>({...}) { ... }
  
  // Özel dialog
  static Future<T?> showCustom<T>({
    required BuildContext context,
    required String title,
    required Widget content,
    List<Widget>? actions,
    bool barrierDismissible = true,
  }) { ... }
  
  // Yüklenme dialogu
  static void showLoading(BuildContext context, {String message = 'جاري التحميل...'}) { ... }
  
  // Dialogu kapat
  static void hideLoading(BuildContext context) { ... }
}
```

#### Tarih Filtreleme (`date_filter_sheet.dart`)
```dart
class DateFilterSheet {
  static Future<void> show({
    required BuildContext context,
    required String? selectedYear,
    required List<String> availableYears,
    required DateTimeRange? customDateRange,
    required bool isCustomDateRange,
    required ValueChanged<String> onYearSelected,
    required ValueChanged<DateTimeRange> onDateRangeSelected,
    required VoidCallback onClearFilter,
    required VoidCallback onDateRangePickerTap,
  }) { ... }
}
```

### 2.4 Utils (`core/utils/`)

#### Sayı Formatlama (`number_formatter.dart`)
```dart
class NumberFormatter {
  // Başlatma
  static Future<void> initialize() async { ... }
  
  // Arabik format açma/kapama
  static Future<void> setArabicFormat(bool useArabic) async { ... }
  
  // Para birimi değiştirme
  static Future<void> setCurrency(String currencyCode) async { ... }
  
  // Kısa format açma/kapama (1K, 1M)
  static Future<void> setUseShortFormat(bool useShort) async { ... }
  
  // Sayı formatlama
  static String format(num number) { ... }
  
  // Para birimi ile formatlama
  static String formatCurrency(num number) { ... }
  
  // Kısa gösterim (grafikler için)
  static String formatShort(num number) { ... }
  
  // Para birimi simgesi
  static String getCurrencySymbol() { ... }
}
```

#### Tarih ve Yardımcı Fonksiyonlar (`app_utils.dart`)
```dart
class AppUtils {
  // Tarih formatlama
  static String formatDate(DateTime date, {String format = 'yyyy-MM-dd'}) { ... }
  static String formatDateTime(DateTime dateTime, {String format = 'yyyy-MM-dd HH:mm:ss'}) { ... }
  static DateTime? parseDate(String dateString, {String format = 'yyyy-MM-dd'}) { ... }
  
  // Sayı formatlama
  static String formatCurrency(double amount, {String currency = 'SAR'}) { ... }
  static String formatNumber(double number, {int decimalDigits = 2}) { ... }
  static double? parseNumber(String numberString) { ... }
  
  // Doğrulama
  static bool isValidEmail(String email) { ... }
  static bool isValidPhone(String phone) { ... }
  static bool isValidPassword(String password) { ... }
  static bool isValidAmount(String amount) { ... }
  
  // Dosya boyutu
  static String formatFileSize(int bytes) { ... }
  
  // Zaman
  static String formatDuration(Duration duration) { ... }
  static String getRelativeTime(DateTime dateTime) { ... }
  
  // Arapça sayı dönüşümleri
  static String convertToArabicNumbers(String input) { ... }
  static String convertToLatinNumbers(String input) { ... }
}
```

### 2.5 Services (`core/services/`)

#### Kullanıcı Servisi (`user_service.dart`)
```dart
class UserService {
  static Future<void> saveUserInfo({
    required String userId,
    String? userName,
    String? userEmail,
  }) async { ... }
  
  static Future<String?> getUserId() async { ... }
  static Future<String?> getUserName() async { ... }
  static Future<String?> getUserEmail() async { ... }
  static Future<void> clearUserInfo() async { ... }
  static Future<bool> isLoggedIn() async { ... }
}
```

#### PDF Servisleri
```dart
// invoice_pdf_service.dart - Fatura PDF oluşturma
class InvoicePdfService {
  static Future<void> generateAndPrintInvoice(Invoice invoice) async { ... }
}

// pdf_invoice_service.dart - Alternatif PDF servisi
class PdfInvoiceService {
  // ...
}
```

### 2.6 Database (`core/database/`)

#### Drift Veritabanı (`app_database.dart`)
```dart
class AppDatabase extends GeneratedDatabase {
  static Future<AppDatabase> create() async { ... }
  
  // JSON verilerini önbelleğe alma
  Future<void> upsertJson(String table, String id, String userId, Map<String, dynamic> data) async { ... }
  Future<List<Map<String, dynamic>>> getAllJson(String table, String userId) async { ... }
  Future<void> upsertJsonList(String table, String userId, List<Map<String, dynamic>> items, String Function(Map<String, dynamic>) idExtractor) async { ... }
  Future<void> clearTable(String table, String userId) async { ... }
  
  // Müşteri verileri
  Future<void> upsertCustomerData(String table, String customerId, String userId, List<Map<String, dynamic>> data) async { ... }
  Future<List<Map<String, dynamic>>> getCustomerData(String table, String customerId, String userId) async { ... }
  
  // Bekleyen ödemeler
  Future<void> insertPendingPayment(Map<String, dynamic> payment) async { ... }
  Future<List<Map<String, dynamic>>> getPendingPayments(String userId) async { ... }
  Future<void> deletePendingPayment(String id) async { ... }
}
```

### 2.7 Network (`core/network/`)

```dart
abstract class NetworkInfo {
  Future<bool> get isConnected;
  Stream<bool> get connectionStream;
}

class NetworkInfoImpl implements NetworkInfo {
  final InternetConnectionChecker connectionChecker;
  
  NetworkInfoImpl(this.connectionChecker);
  
  @override
  Future<bool> get isConnected => connectionChecker.hasConnection;
  
  @override
  Stream<bool> get connectionStream => connectionChecker.onStatusChange
      .map((status) => status == InternetConnectionStatus.connected);
}
```

### 2.8 Errors (`core/errors/`)

#### Hata Hiyerarşisi
```dart
// Temel hata sınıfı
abstract class Failure {
  final String message;
  final String? code;
  const Failure(this.message, {this.code});
}

// Ağ hataları
class NetworkFailure extends Failure {
  factory NetworkFailure.noConnection() { ... }
  factory NetworkFailure.timeout() { ... }
  factory NetworkFailure.serverError() { ... }
  factory NetworkFailure.unauthorized() { ... }
}

// Sunucu hataları
class ServerFailure extends Failure {
  factory ServerFailure.databaseError() { ... }
  factory ServerFailure.internalServerError() { ... }
}

// Önbellek hataları
class CacheFailure extends Failure {
  factory CacheFailure.notFound() { ... }
  factory CacheFailure.writeError() { ... }
}

// Doğrulama hataları
class ValidationFailure extends Failure {
  factory ValidationFailure.emptyField(String fieldName) { ... }
  factory ValidationFailure.invalidEmail() { ... }
  factory ValidationFailure.invalidNumber(String fieldName) { ... }
}

// İş mantığı hataları
class BusinessFailure extends Failure {
  factory BusinessFailure.insufficientStock() { ... }
  factory BusinessFailure.productNotFound() { ... }
  factory BusinessFailure.invoiceAlreadyPaid() { ... }
}

// Kimlik doğrulama hataları
class AuthFailure extends Failure {
  factory AuthFailure.invalidCredentials() { ... }
  factory AuthFailure.userNotFound() { ... }
  factory AuthFailure.sessionExpired() { ... }
}

// İstisna dönüştürücü
Failure exceptionToFailure(dynamic exception) { ... }
```

---

## 3. STATE YÖNETİMİ (State Management)

### 3.1 Kullanılan Teknoloji: flutter_bloc (Cubit)
- **Cubit** kullanılır (BLoC değil)
- **Equatable** tüm state ve model sınıflarında kullanılır
- **part** direktifi ile state dosyası bağlanır

### 3.2 Cubit Kalıbı
```dart
// feature_cubit.dart
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'feature_state.dart';

class FeatureCubit extends Cubit<FeatureState> {
  final FeatureRepository repository;
  
  FeatureCubit({required this.repository}) : super(FeatureInitial());
  
  // Verileri yükle
  Future<void> loadData() async {
    if (isClosed) return;
    emit(FeatureLoading());
    
    final result = await repository.getData();
    if (isClosed) return;
    
    result.fold(
      (failure) => emit(FeatureError(failure.message)),
      (data) => emit(FeatureLoaded(data: data)),
    );
  }
  
  // Arama
  Future<void> searchData(String query) async {
    if (isClosed) return;
    // Arama mantığı
  }
  
  // Hata temizleme
  void clearError() {
    if (isClosed) return;
    emit(FeatureInitial());
  }
  
  // Real-time dinleyici (opsiyonel)
  StreamSubscription? _subscription;
  
  void _startRealtimeListener() {
    _subscription = repository.watchData().listen((result) {
      if (isClosed) return;
      result.fold(
        (failure) => log('Stream error: ${failure.message}'),
        (data) => _updateData(data),
      );
    });
  }
  
  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
```

### 3.3 State Kalıbı
```dart
// feature_state.dart (part dosyası)
part of 'feature_cubit.dart';

abstract class FeatureState extends Equatable {
  const FeatureState();
  @override
  List<Object?> get props => [];
}

class FeatureInitial extends FeatureState {}

class FeatureLoading extends FeatureState {}

class FeatureLoaded extends FeatureState {
  final List<FeatureModel> data;
  final List<FeatureModel> filteredData;
  
  const FeatureLoaded({
    required this.data,
    this.filteredData = const [],
  });
  
  @override
  List<Object?> get props => [data, filteredData];
  
  FeatureLoaded copyWith({
    List<FeatureModel>? data,
    List<FeatureModel>? filteredData,
  }) {
    return FeatureLoaded(
      data: data ?? this.data,
      filteredData: filteredData ?? this.filteredData,
    );
  }
}

class FeatureError extends FeatureState {
  final String message;
  const FeatureError(this.message);
  @override
  List<Object?> get props => [message];
}

class FeatureSuccess extends FeatureState {
  final String message;
  const FeatureSuccess(this.message);
  @override
  List<Object?> get props => [message];
}
```

### 3.4 Provider Kullanım Kuralları
- **Uygulama başlangıcında**: Sadece `AuthCubit` root seviyede açılır
- **Diğer Cubit'ler**: İlgili sayfada `BlocProvider` ile açılır
- **Root seviyede**: Boşuna Cubit açılmaz
- **Route seviyesinde**: `BlocProvider` route'un içinde tanımlanır

```dart
// main.dart - Sadece AuthCubit root'ta
runApp(
  BlocProvider(
    create: (_) => sl.sl<AuthCubit>()..getCurrentUser(),
    child: const ERADApp(),
  ),
);

// Route seviyesinde Cubit açma
case AppRoutes.invoices:
  return MaterialPageRoute(
    builder: (context) => BlocProvider(
      create: (_) => sl.sl<InvoiceCubit>(),
      child: const InvoicesPage(),
    ),
  );

// Mevcut Cubit'i paylaşma
case AppRoutes.settings:
  return MaterialPageRoute(
    builder: (context) => BlocProvider.value(
      value: context.read<AuthCubit>(),
      child: const SettingsPage(),
    ),
  );
```

---

## 4. DEPENDENCY INJECTION (Bağımlılık Enjeksiyonu)

### 4.1 Kullanılan Paket: get_it
```dart
// core/di/services_locator.dart
import 'package:get_it/get_it.dart';

final GetIt sl = GetIt.instance;

Future<void> initServicesLocator() async {
  // External dependencies
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
  sl.registerLazySingleton(() => InternetConnectionChecker.createInstance());
  
  // Supabase başlatma
  await Supabase.initialize(
    url: ApiConstants.supabaseUrl,
    anonKey: ApiConstants.supabaseAnonKey,
  );
  sl.registerLazySingleton(() => Supabase.instance.client);
  
  // Core utilities
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));
  sl.registerLazySingleton(() => AppUtils());
  sl.registerLazySingleton(() => UserService());
  
  // Database
  final db = await AppDatabase.create();
  sl.registerSingleton<AppDatabase>(db);
  
  // Local datasources
  sl.registerLazySingleton<InvoiceLocalDataSource>(() => InvoiceLocalDataSourceImpl(sl()));
  
  // Feature: Auth
  sl.registerLazySingleton<AuthRemoteDataSource>(() => AuthRemoteDataSourceImpl(sl()));
  sl.registerLazySingleton<AuthLocalDataSource>(() => AuthLocalDataSourceImpl(sl()));
  sl.registerLazySingleton<AuthRepository>(() => AuthRepository(sl(), sl(), sl()));
  sl.registerFactory(() => AuthCubit(authRepository: sl()));
  
  // Feature: Products
  sl.registerLazySingleton<ProductRemoteDataSource>(() => ProductRemoteDataSourceImpl(sl()));
  sl.registerLazySingleton<ProductRepository>(() => ProductRepository(sl(), sl()));
  sl.registerFactory(() => ProductCubit(productRepository: sl()));
  
  // ... diğer feature'lar için benzer kayıtlar
}
```

### 4.2 Kayıt Kuralları
- **External deps**: `registerLazySingleton` - İlk erişimde oluşturulur
- **Database**: `registerSingleton` - Hemen oluşturulur
- **DataSources**: `registerLazySingleton` - Tek instance
- **Repositories**: `registerLazySingleton` - Tek instance
- **Cubits**: `registerFactory` - Her seferinde yeni instance

---

## 5. DATA LAYER (Veri Katmanı)

### 5.1 Model Kalıbı

#### Equatable ile Model
```dart
import 'package:equatable/equatable.dart';

class FeatureModel extends Equatable {
  final String id;
  final String userId;
  final String name;
  // ... diğer alanlar

  const FeatureModel({
    required this.id,
    required this.userId,
    required this.name,
  });

  @override
  List<Object?> get props => [id, userId, name];

  // Kopyalama
  FeatureModel copyWith({
    String? id,
    String? userId,
    String? name,
  }) {
    return FeatureModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
    );
  }

  // Map'e dönüştürme (Supabase için)
  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'name': name,
    };
  }

  // Map'ten oluşturma (Supabase'den)
  factory FeatureModel.fromMap(Map<String, dynamic> map) {
    return FeatureModel(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      name: map['name'] ?? '',
    );
  }

  // JSON destekli (opsiyonel)
  Map<String, dynamic> toJson() => toMap();
  factory FeatureModel.fromJson(Map<String, dynamic> json) => FeatureModel.fromMap(json);

  // Yardımcı getter'lar
  bool get isActive => /* mantık */;
}
```

#### Sayı Parse Yardımcısı
```dart
// Her modelde tekrar eden yardımcı fonksiyon
static double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}
```

### 5.2 Repository Kalıbı

#### Abstract Repository
```dart
import 'package:dartz/dartz.dart';
import 'package:erad/core/errors/failures.dart';

abstract class FeatureRepository {
  Future<Either<Failure, List<FeatureModel>>> getData();
  Future<Either<Failure, FeatureModel>> getById(String id);
  Future<Either<Failure, void>> add(FeatureModel item);
  Future<Either<Failure, void>> update(FeatureModel item);
  Future<Either<Failure, void>> delete(String id);
  
  // Real-time stream (opsiyonel)
  Stream<Either<Failure, List<FeatureModel>>> watchData();
}
```

#### Repository Implementasyonu
```dart
import 'package:dartz/dartz.dart';
import 'package:erad/core/errors/failures.dart';
import 'package:erad/core/network/network_info.dart';

class FeatureRepositoryImpl implements FeatureRepository {
  final FeatureRemoteDataSource remoteDataSource;
  final FeatureLocalDataSource localDataSource;  // opsiyonel
  final NetworkInfo networkInfo;

  FeatureRepositoryImpl(this.remoteDataSource, this.localDataSource, this.networkInfo);

  @override
  Future<Either<Failure, List<FeatureModel>>> getData() async {
    if (await networkInfo.isConnected) {
      try {
        final data = await remoteDataSource.getData();
        // Önbelleğe alma
        final userId = await UserService.getUserId();
        if (userId != null) {
          await localDataSource.cacheData(userId, data);
        }
        return Right(data);
      } catch (e) {
        return Left(exceptionToFailure(e));
      }
    } else {
      // Offline modda önbellekten okuma
      try {
        final userId = await UserService.getUserId();
        if (userId == null) return Left(CacheFailure.notFound());
        final cached = await localDataSource.getCachedData(userId);
        if (cached.isNotEmpty) return Right(cached);
        return Left(NetworkFailure.noConnection());
      } catch (e) {
        return Left(NetworkFailure.noConnection());
      }
    }
  }
  
  // ... diğer metodlar
}
```

### 5.3 DataSource Kalıbı

#### Remote DataSource
```dart
import 'package:supabase_flutter/supabase_flutter.dart';

class FeatureRemoteDataSource {
  final SupabaseClient supabaseClient;

  FeatureRemoteDataSource(this.supabaseClient);

  Future<List<FeatureModel>> getData() async {
    try {
      final userId = await UserService.getUserId();
      if (userId == null) throw const AuthFailure('User not authenticated');
      
      final response = await supabaseClient
          .from('table_name')
          .select('*')
          .eq('user_id', userId);
      
      return (response as List)
          .map((json) => FeatureModel.fromMap(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw exceptionToFailure(e);
    }
  }

  // Real-time stream
  Stream<List<FeatureModel>> watchData() {
    final controller = StreamController<List<FeatureModel>>();
    List<StreamSubscription> subscriptions = [];

    _fetchAndEmitData(controller);

    final userId = UserService.getUserId();
    userId.then((uid) {
      if (uid == null) return;
      
      final stream = supabaseClient
          .from('table_name')
          .stream(primaryKey: ['id'])
          .eq('user_id', uid);
      
      subscriptions.add(
        stream.listen((_) => _fetchAndEmitData(controller)),
      );
    });

    controller.onCancel = () {
      for (final sub in subscriptions) {
        sub.cancel();
      }
      controller.close();
    };

    return controller.stream;
  }

  Future<void> _fetchAndEmitData(StreamController<List<FeatureModel>> controller) async {
    try {
      final userId = await UserService.getUserId();
      if (userId == null) return;
      
      final response = await supabaseClient
          .from('table_name')
          .select('*')
          .eq('user_id', userId);
      
      final data = (response as List)
          .map((json) => FeatureModel.fromMap(json as Map<String, dynamic>))
          .toList();
      
      if (!controller.isClosed) {
        controller.add(data);
      }
    } catch (e) {
      log('Error in _fetchAndEmitData: $e');
    }
  }
}
```

#### Local DataSource (Opsiyonel)
```dart
import 'package:erad/core/database/app_database.dart';

class FeatureLocalDataSource {
  final AppDatabase database;

  FeatureLocalDataSource(this.database);

  Future<void> cacheData(String userId, List<FeatureModel> data) async {
    await database.upsertJsonList(
      'feature_cache',
      userId,
      data.map((item) => item.toMap()).toList(),
      (item) => item['id'] as String,
    );
  }

  Future<List<FeatureModel>> getCachedData(String userId) async {
    final rows = await database.getAllJson('feature_cache', userId);
    return rows.map((json) => FeatureModel.fromMap(json)).toList();
  }

  Future<void> clearCache(String userId) async {
    await database.clearTable('feature_cache', userId);
  }
}
```

---

## 6. UI KURALLARI

### 6.1 Tasarım Prensipleri
- **Flat & Minimalist**: Maksimum 3 renk + 1 accent
- **Card elevation**: `AppConstants.cardElevation` (0.0) - Gölge yok veya çok hafif
- **Border radius**: `AppConstants.borderRadiusMd` (8.0)
- **Padding/Spacing**: `AppConstants.spacing*` sabitleri kullanılacak
- **Renkler**: `AppColors.*` sabitleri kullanılacak
- **Font**: Google Fonts - Cairo (Arapça), Inter (Latin/Numaralar)

### 6.2 Widget Kullanım Kuralları
- **core/widgets/common_widgets.dart**: `CustomButton`, `CustomTextField`, `CustomCard`, `EmptyStateWidget`, `LoadingWidget`, `StatusBadge`, `SearchField`
- **core/widgets/app_dialog.dart**: Tüm dialoglar `AppDialog` sınıfından
- **core/widgets/date_filter_sheet.dart**: Tarih filtresi için `DateFilterSheet.show()`
- **Feature-specific widgets**: `features/*/presentation/widgets/` içinde

### 6.3 Icon Kullanımı
- **Paket**: `iconsax` (`package:iconsax/iconsax.dart`)
- **Kullanım**: `Iconsax.home`, `Iconsax.add`, `Iconsax.search`, vb.
- **Material Icons**: Sadece `Icons` class'ından temel ikonlar (warning, info, error, vb.)

### 6.4 RTL Desteği
```dart
// main.dart - RTL yapılandırma
builder: (context, child) {
  return Directionality(
    textDirection: TextDirection.rtl,
    child: updatedMediaQuery,
  );
},
locale: const Locale('ar'),
```

### 6.5 Sayfa Yapısı Kalıbı
```dart
class FeaturePage extends StatefulWidget {
  const FeaturePage({super.key});

  @override
  State<FeaturePage> createState() => _FeaturePageState();
}

class _FeaturePageState extends State<FeaturePage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Cubit'i başlat
    context.read<FeatureCubit>().loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            // Arama
            _buildSearchBar(),
            // Filtreler
            _buildFilters(),
            // İçerik
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.navigate_before, size: 30),
          ),
          Text(
            'Feature Title',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingMd),
      child: SearchField(
        hint: 'بحث...',
        onChanged: (query) {
          context.read<FeatureCubit>().searchData(query);
        },
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      child: Row(
        children: [
          // Filtre butonları
        ],
      ),
    );
  }

  Widget _buildContent() {
    return BlocBuilder<FeatureCubit, FeatureState>(
      builder: (context, state) {
        if (state is FeatureLoading) {
          return const LoadingWidget();
        }
        
        if (state is FeatureError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(state.message),
                const SizedBox(height: AppConstants.spacingMd),
                ElevatedButton(
                  onPressed: () => context.read<FeatureCubit>().loadData(),
                  child: Text(AppStrings.retry),
                ),
              ],
            ),
          );
        }
        
        if (state is FeatureLoaded) {
          if (state.filteredData.isEmpty) {
            return EmptyStateWidget(
              title: 'لا توجد بيانات',
              icon: Iconsax.document,
            );
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(AppConstants.spacingMd),
            itemCount: state.filteredData.length,
            itemBuilder: (context, index) {
              final item = state.filteredData[index];
              return FeatureCardWidget(
                item: item,
                onTap: () => _navigateToDetail(item),
              );
            },
          );
        }
        
        return const SizedBox.shrink();
      },
    );
  }

  void _navigateToDetail(FeatureModel item) {
    // Navigation mantığı
  }
}
```

### 6.6 Card Widget Kalıbı
```dart
class FeatureCardWidget extends StatelessWidget {
  final FeatureModel item;
  final VoidCallback? onTap;

  const FeatureCardWidget({
    super.key,
    required this.item,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: AppConstants.spacingSm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // İkon veya avatar
              Container(
                padding: const EdgeInsets.all(AppConstants.spacingSm),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusSm),
                ),
                child: const Icon(
                  Iconsax.box,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppConstants.spacingMd),
              // Başlık ve açıklama
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppConstants.spacingXs),
                    Text(
                      item.description ?? '',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              // Durum rozeti
              StatusBadge(
                text: item.status,
                color: AppColors.success,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

### 6.7 Dialog Kullanım Kalıbı
```dart
// Onay dialogu
final confirmed = await AppDialog.showConfirmation(
  context: context,
  title: 'حذف العنصر',
  message: 'هل أنت متأكد من حذف هذا العنصر؟',
  confirmText: 'حذف',
  cancelText: 'إلغاء',
  isDangerous: true,
);

if (confirmed == true) {
  // Silme işlemi
}

// Özel dialog
await AppDialog.showCustom(
  context: context,
  title: 'إضافة عنصر',
  content: Form(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomTextField(
          label: 'الاسم',
          onChanged: (value) => name = value,
        ),
      ],
    ),
  ),
  actions: [
    OutlinedButton(
      onPressed: () => Navigator.pop(context),
      child: Text(AppStrings.cancel),
    ),
    ElevatedButton(
      onPressed: () {
        // Kaydetme işlemi
        Navigator.pop(context);
      },
      child: Text(AppStrings.save),
    ),
  ],
);
```

---

## 7. DEPENDENCY INJECTION DETAYLARI

### 7.1 Dosya Yapısı
```
core/di/
└── services_locator.dart
```

### 7.2 Kayıt Sırası
1. External dependencies (SharedPreferences, InternetConnectionChecker)
2. Supabase başlatma
3. Core utilities (NetworkInfo, AppUtils, UserService)
4. Database (AppDatabase)
5. Local datasources
6. Remote datasources
7. Repositories
8. Cubits

---

## 8. SUPABASE ENTEGRASYONU

### 8.1 Başlatma
```dart
await Supabase.initialize(
  url: ApiConstants.supabaseUrl,
  anonKey: ApiConstants.supabaseAnonKey,
);
sl.registerLazySingleton(() => Supabase.instance.client);
```

### 8.2 Kullanım Kalıbı
```dart
// Select
final response = await supabaseClient
    .from('table_name')
    .select('*')
    .eq('user_id', userId);

// Insert
await supabaseClient.from('table_name').insert({
  'user_id': userId,
  'field': value,
});

// Update
await supabaseClient
    .from('table_name')
    .update({'field': newValue})
    .eq('id', id);

// Delete
await supabaseClient
    .from('table_name')
    .delete()
    .eq('id', id);

// RPC (Remote Procedure Call)
await supabaseClient.rpc(
  'function_name',
  params: {'param1': value1, 'param2': value2},
);

// Real-time stream
final stream = supabaseClient
    .from('table_name')
    .stream(primaryKey: ['id'])
    .eq('user_id', userId);
```

### 8.3 Güvenlik Kuralları
- **API Key**: `core/constants/api_constans.dart` içinde tanımlı
- **Kullanıcı ID**: Her sorguda `user_id` filtresi zorunlu
- **RLS (Row Level Security)**: Supabase tarafında aktif olmalı
- **Hassas bilgiler**: Git'e commit edilmemeli

---

## 9. ÇEVIRI VE YERELLEŞTIRME

### 9.1 Dil Desteği
- **Varsayılan dil**: Arapça (ar)
- **Font**: Cairo (Arapça), Inter (Latin/Numaralar)
- **RTL**: direction: TextDirection.rtl

### 9.2 Metin Sabitleri
Tüm kullanıcıya dönük metinler `AppStrings` sınıfında tanımlanır:
```dart
class AppStrings {
  static const save = 'حفظ';
  static const cancel = 'إلغاء';
  static const delete = 'حذف';
  // ...
}
```

---

## 10. HATA YÖNETİMİ

### 10.1 Hata Akışı
```
Exception → exceptionToFailure() → Failure → Cubit → State → UI
```

### 10.2 Kullanım
```dart
// DataSource'da
try {
  final response = await supabaseClient.from('table').select('*');
  return response;
} catch (e) {
  throw exceptionToFailure(e);
}

// Repository'de
final result = await remoteDataSource.getData();
result.fold(
  (failure) => Left(failure),
  (data) => Right(data),
);

// Cubit'te
result.fold(
  (failure) => emit(FeatureError(failure.message)),
  (data) => emit(FeatureLoaded(data: data)),
);
```

---

## 11. REAL-TIME VERİ AKIŞI

### 11.1 Akış Kalıbı
```
Supabase Stream → DataSource → Repository → Cubit → UI
```

### 11.2 Uygulama
```dart
// DataSource
Stream<List<FeatureModel>> watchData() {
  final controller = StreamController<List<FeatureModel>>();
  // Stream'i başlat ve controller'a ekle
  return controller.stream;
}

// Repository
Stream<Either<Failure, List<FeatureModel>>> watchData() {
  return remoteDataSource.watchData().map(
    (data) => Right<Failure, List<FeatureModel>>(data),
  );
}

// Cubit
void _startRealtimeListener() {
  _subscription = repository.watchData().listen((result) {
    if (isClosed) return;
    result.fold(
      (failure) => log('Stream error: ${failure.message}'),
      (data) => _updateData(data),
    );
  });
}
```

---

## 12. OFFLINE DESTEK

### 12.1 Önbellek Stratejisi
```
1. Online: Remote'dan al → Önbelleğe kaydet → UI'a göster
2. Offline: Önbellekten oku → UI'a göster
3. Bağlantı geri geldiğinde: Bekleyen işlemleri senkronize et
```

### 12.2 Uygulama
```dart
// Repository'de
if (await networkInfo.isConnected) {
  // Online: Remote'dan al
  final data = await remoteDataSource.getData();
  await localDataSource.cacheData(userId, data);
  return Right(data);
} else {
  // Offline: Önbellekten oku
  final cached = await localDataSource.getCachedData(userId);
  if (cached.isNotEmpty) return Right(cached);
  return Left(NetworkFailure.noConnection());
}
```

---

## 13. PDF OLUŞTURMA

### 13.1 Kullanılan Paketler
- `pdf`: PDF oluşturma
- `printing`: PDF yazdırma/gösterme

### 13.2 Kullanım
```dart
final pdf = pw.Document();

pdf.addPage(
  pw.Page(
    pageFormat: PdfPageFormat.a4,
    build: (pw.Context context) {
      return pw.Column(
        children: [
          // PDF içeriği
        ],
      );
    },
  ),
);

await Printing.layoutPdf(
  onLayout: (PdfPageFormat format) async => pdf.save(),
  name: 'document.pdf',
);
```

---

## 14. KOD STİLİ VE İSİMLENDİRME

### 14.1 Dosya İsimlendirme
- **Feature klasörü**: `snake_case` (örn: `customer_debts`)
- **Dosyalar**: `snake_case` (örn: `customer_debt_model.dart`)
- **Sınıflar**: `PascalCase` (örn: `CustomerDebtModel`)
- **Değişkenler/fonksiyonlar**: `camelCase` (örn: `getCustomerDebts`)

### 14.2 Import Sırası
```dart
// 1. Dart core
import 'dart:async';

// 2. Flutter
import 'package:flutter/material.dart';

// 3. Third party
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:iconsax/iconsax.dart';

// 4. Core
import 'package:erad/core/constants/app_constants.dart';
import 'package:erad/core/widgets/common_widgets.dart';

// 5. Features
import 'package:erad/features/feature_name/data/models/feature_model.dart';
```

### 14.3 Yorum Kuralları
- Gereksiz yorum yazılmaz
- Kodun ne yaptığı anlaşılırsa yorum eklenmez
- Yalnızca "NEDEN" açık değilse yorum eklenir
- Çok satırlı docstring'ler yazılmaz
- Tek satırlık yorum (gerekirse)

---

## 15. TESTING

### 15.1 Dosya Yapısı
```
test/
├── features/
│   └── feature_name/
│       ├── data/
│       │   ├── datasources/
│       │   ├── models/
│       │   └── repositories/
│       └── presentation/
│           └── bloc/
└── core/
    └── utils/
```

### 15.2 Test Kalıbı
```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FeatureModel', () {
    test('should create from map correctly', () {
      final map = {'id': '1', 'name': 'Test'};
      final model = FeatureModel.fromMap(map);
      expect(model.id, '1');
      expect(model.name, 'Test');
    });

    test('should convert to map correctly', () {
      const model = FeatureModel(id: '1', name: 'Test');
      final map = model.toMap();
      expect(map['id'], '1');
      expect(map['name'], 'Test');
    });
  });
}
```

---

## 16. PERFORMANS

### 16.1 Optimize Edilecek Alanlar
- **ListView.builder**: Uzun listelerde `ListView.builder` kullanılacak
- **const constructor**: Mümkün olan her yerde `const` kullanılacak
- **Equatable**: State ve model karşılaştırmaları için
- **isClosed kontrolü**: Cubit'te `emit`调用前 `isClosed` kontrolü
- **Stream abonelikleri**: `close()` metodunda iptal edilecek
- **Lazy loading**: Veriler gerektiğinde yüklenecek

---

## 17. GÜVENLİK

### 17.1 Kurallar
- **API Key'ler**: Kod içinde açık metin olarak storedlmaz (opsiyonel: .env dosyası)
- **Kullanıcı verisi**: Yalnızca `user_id` filtresi ile erişim
- **RLS**: Supabase tarafında Row Level Security aktif
- **Hassas veriler**: Log'larda yazdırılmaz
- **Input doğrulama**: Kullanıcı girişleri doğrulanır

---

## 18. YENİ FEATURE OLUŞTURMA ADIMLARI

Yeni bir feature eklerken şu adımlar izlenir:

1. **Klasör yapısını oluştur**
   ```
   features/new_feature/
   ├── data/
   │   ├── datasource/
   │   ├── models/
   │   └── repositories/
   └── presentation/
       ├── bloc/
       ├── pages/
       └── widgets/
   ```

2. **Model oluştur** (`data/models/feature_model.dart`)
   - Equatable ile
   - `toMap()` / `fromMap()` metotları
   - `copyWith()` metodu
   - Gerekirse `toJson()` / `fromJson()`

3. **DataSource oluştur** (`data/datasource/feature_remote_datasource.dart`)
   - Supabase client kullanımı
   - `user_id` filtresi
   - Hata yakalama ve `exceptionToFailure` kullanımı

4. **Repository oluştur** (`data/repositories/`)
   - Abstract sınıf
   - Implementasyon: Online/Offline mantığı
   - `Either<Failure, T>` dönüş tipi

5. **Cubit ve State oluştur** (`presentation/bloc/`)
   - Cubit: İş mantığı
   - State: Equatable ile, part dosyası

6. **Sayfa oluştur** (`presentation/pages/`)
   - `BlocProvider` ile Cubit bağlama
   - `BlocBuilder` ile state yönetimi
   - `AppColors`, `AppConstants`, `AppStrings` kullanımı
   - Custom widget'lar (`CustomButton`, `CustomCard`, vb.)

7. **Widget'ları oluştur** (`presentation/widgets/`)
   - Her widget ayrı dosyada
   - `CustomCard`, `StatusBadge`, vb. kullanımı

8. **DI'ye kayıt et** (`core/di/services_locator.dart`)
   - DataSource kaydı
   - Repository kaydı
   - Cubit kaydı (`registerFactory`)

9. **Route ekle** (`core/constants/app_constants.dart`)
   - `AppRoutes` sabitlerine ekle

10. **main.dart'a route ekle**
    - `_generateRoute` metoduna case ekle

---

## 19. SIK KULLANILAN WIDGET'LAR

### Core Widgets
| Widget | Dosya | Kullanım |
|--------|-------|----------|
| `CustomButton` | `common_widgets.dart` | Yüklenme durumlu buton |
| `CustomTextField` | `common_widgets.dart` | Özelleştirilmiş metin alanı |
| `CustomCard` | `common_widgets.dart` | Tutarlı kart görünümü |
| `EmptyStateWidget` | `common_widgets.dart` | Boş durum gösterimi |
| `LoadingWidget` | `common_widgets.dart` | Yüklenme göstergesi |
| `StatusBadge` | `common_widgets.dart` | Durum rozeti |
| `SearchField` | `common_widgets.dart` | Arama alanı |
| `AppDialog` | `app_dialog.dart` | Tüm dialog türleri |
| `DateFilterSheet` | `date_filter_sheet.dart` | Tarih filtresi |

### Iconsax İkonları
| İkon | Kullanım |
|------|----------|
| `Iconsax.home` | Ana sayfa |
| `Iconsax.add` | Ekleme |
| `Iconsax.search` | Arama |
| `Iconsax.edit` | Düzenleme |
| `Iconsax.trash` | Silme |
| `Iconsax.eye` | Görüntüleme |
| `Iconsax.box` | Ürün/Envanter |
| `Iconsax.user` | Kullanıcı |
| `Iconsax.document` | Belge |
| `Iconsax.chart` | Grafik/İstatistik |

---

## 20. REFERANS DOSYALAR

Bu kurallar şu mevcut dosyalardan türetilmiştir:

| Dosya | Açıklama |
|-------|----------|
| `lib/core/constants/app_constants.dart` | Tüm sabit değerler |
| `lib/core/theme/app_theme.dart` | Tema tanımları |
| `lib/core/widgets/common_widgets.dart` | Ortak widget'lar |
| `lib/core/widgets/app_dialog.dart` | Dialog sistemi |
| `lib/core/di/services_locator.dart` | Bağımlılık enjeksiyonu |
| `lib/core/errors/failures.dart` | Hata hiyerarşisi |
| `lib/core/network/network_info.dart` | Ağ bilgisi |
| `lib/core/services/user_service.dart` | Kullanıcı servisi |
| `lib/core/utils/number_formatter.dart` | Sayı formatlama |
| `lib/core/utils/app_utils.dart` | Yardımcı fonksiyonlar |
| `lib/core/database/app_database.dart` | Drift veritabanı |
| `lib/features/*/data/models/*.dart` | Model kalıpları |
| `lib/features/*/data/repositories/*.dart` | Repository kalıpları |
| `lib/features/*/data/datasource*/*.dart` | DataSource kalıpları |
| `lib/features/*/presentation/bloc/*.dart` | Cubit/State kalıpları |
| `lib/features/*/presentation/pages/*.dart` | Sayfa kalıpları |
| `lib/features/*/presentation/widgets/*.dart` | Widget kalıpları |
| `lib/main.dart` | Uygulama giriş noktası |

---

> **NOT**: Bu dosya AI skill olarak kullanıldığında, verilen görevin bu kurallara uygun olmasını sağlamak için referans olarak kullanılır. Herhangi bir çelişki durumunda bu dosyadaki kurallar geçerlidir.
