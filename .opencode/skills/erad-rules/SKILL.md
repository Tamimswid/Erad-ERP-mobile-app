# ERAD Flutter Project Rules

Bu skill, ERAD projesinde kod yazarken uyulması gereken tüm kuralları ve kalıpları tanımlar. Herhangi bir feature eklerken veya düzenlerken bu kurallara uyulmalıdır.

---

## Proje Yapısı

```
lib/
├── core/
│   ├── constants/     # AppColors, AppStrings, AppConstants, AppRoutes, AppFonts, AppAssets, ApiConstants
│   ├── database/      # AppDatabase (Drift)
│   ├── di/            # services_locator.dart (GetIt)
│   ├── errors/        # Failure hierarchy + exceptionToFailure()
│   ├── network/       # NetworkInfo (InternetConnectionChecker)
│   ├── services/      # UserService, InvoicePdfService, PdfInvoiceService
│   ├── theme/         # AppTheme (lightTheme)
│   ├── utils/         # AppUtils, NumberFormatter, CustomLoadingAnimation, FinancialAreaChart
│   └── widgets/       # CommonWidgets, AppDialog, DateFilterSheet
├── features/
│   ├── auth/          # Kimlik doğrulama
│   ├── customer_debts/
│   ├── customers/
│   ├── dashboard/
│   ├── expenses/
│   ├── invoices/
│   ├── products/
│   ├── reports/
│   ├── settings/
│   ├── stock/
│   ├── suppliers/
│   ├── suppliers_debts/
│   └── withdrawals/
└── main.dart
```

Her feature Clean Architecture izler:
```
feature_name/
├── data/
│   ├── datasource/     # Remote + Local DataSource
│   ├── models/         # Equatable modeller (toMap/fromMap, copyWith)
│   └── repositories/   # Abstract + Impl (Either<Failure, T>)
└── presentation/
    ├── bloc/           # Cubit + State (part dosyası)
    ├── pages/          # Sayfalar
    └── widgets/        # Feature'a özel widget'lar
```

---

## Zorunlu Kurallar

### State Yönetimi
- **Cubit** kullanılır (BLoC değil)
- **Equatable** tüm state ve model sınıflarında zorunlu
- **part** direktifi ile state dosyası bağlanır
- Cubit'te `emit`调用前 her zaman `isClosed` kontrolü yapılır
- Stream abonelikleri `close()`'da iptal edilir

### Provider Kullanımı
- Root'ta sadece `AuthCubit` açılır
- Diğer Cubit'ler ilgili sayfada `BlocProvider` ile açılır
- Boşuna Cubit açılmaz, gerektiğinde açılır

### Model Kuralları
- Tüm modeller `extends Equatable`
- `toMap()` / `fromMap()` metotları zorunlu
- `copyWith()` metodu zorunlu
- `_parseDouble(dynamic value)` helper'ı her modelde bulunur
- JSON için `toJson()` / `fromJson()` eklenir

### Repository Kuralları
- Abstract sınıf + Implementasyon
- Dönüş tipi: `Either<Failure, T>`
- Online/Offline mantığı: `networkInfo.isConnected` kontrolü
- Offline'da önbellekten okuma
- Real-time için `Stream<Either<Failure, List<T>>> watchData()`

### DataSource Kuralları
- Supabase client kullanımı
- Her sorguda `user_id` filtresi zorunlu
- Hata yakalama: `throw exceptionToFailure(e)`
- Real-time stream: `StreamController` + `.stream()`

### UI Kuralları
- **Flat & Minimalist**: Maksimum 3 renk + 1 accent
- **Card elevation**: `AppConstants.cardElevation` (0.0)
- **Border radius**: `AppConstants.borderRadiusMd` (8.0)
- **Padding/Spacing**: `AppConstants.spacing*` sabitleri
- **Renkler**: `AppColors.*` sabitleri
- **Font**: Google Fonts - Cairo (Arapça), Inter (Latin)
- **RTL**: `TextDirection.rtl`, `Locale('ar')`

### Widget Kullanımı
- Core widget'ları tercih et: `CustomButton`, `CustomTextField`, `CustomCard`, `EmptyStateWidget`, `LoadingWidget`, `StatusBadge`, `SearchField`
- Dialog'lar: `AppDialog.showConfirmation()`, `AppDialog.showCustom()`, vb.
- Tarih filtresi: `DateFilterSheet.show()`

### Icon Kullanımı
- `iconsax` paketi: `Iconsax.home`, `Iconsax.add`, `Iconsax.search`, vb.
- Material Icons sadece temel ikonlar için (warning, info, error)

### Hata Yönetimi
```
Exception → exceptionToFailure() → Failure → Cubit → State → UI
```

### DI Kuralları
- External deps: `registerLazySingleton`
- Database: `registerSingleton`
- DataSources: `registerLazySingleton`
- Repositories: `registerLazySingleton`
- Cubits: `registerFactory`

### Kod Stili
- Dosyalar: `snake_case`
- Sınıflar: `PascalCase`
- Değişkenler/fonksiyonlar: `camelCase`
- Import sırası: Dart → Flutter → Third party → Core → Features
- Yorum: Gereksiz yorum yazılmaz, sadece "NEDEN" açık değilse

### Güvenlik
- API Key'ler: `core/constants/api_constans.dart`
- Kullanıcı ID: Her sorguda `user_id` filtresi
- Hassas veriler: Log'larda yazdırılmaz

---

## Yeni Feature Oluşturma Adımları

1. Klasör yapısını oluştur (data + presentation)
2. Model oluştur (Equatable, toMap/fromMap, copyWith)
3. DataSource oluştur (Supabase, user_id filtresi)
4. Repository oluştur (Abstract + Impl, Either, Online/Offline)
5. Cubit ve State oluştur (part dosyası, Equatable)
6. Sayfa oluştur (BlocProvider, BlocBuilder, AppColors)
7. Widget'ları oluştur (ayrı dosyalar)
8. DI'ye kayıt et (services_locator.dart)
9. Route ekle (AppRoutes + main.dart)

---

## Sık Kullanılan Sabitler

### AppColors
- `primary`: Color(0xFF0F1B3D)
- `background`: Color(0xFFFFFFFF)
- `surface`: Color(0xFFFFFFFF)
- `text`: Color(0xFF1A1A2E)
- `textSecondary`: Color(0xFF6B7280)
- `success`: Color(0xFF10B981)
- `warning`: Color(0xFFF59E0B)
- `error`: Color(0xFFEF4444)
- `divider`: Color(0xFFE5E7EB)
- `border`: Color(0xFFD1D5DB)

### AppConstants Spacing
- `spacingXs`: 4.0
- `spacingSm`: 8.0
- `spacingMd`: 16.0
- `spacingLg`: 24.0
- `spacingXl`: 32.0

### AppFonts
- `fontSizeSmall`: 12.0
- `fontSizeMedium`: 14.0
- `fontSizeLarge`: 16.0
- `fontSizeXLarge`: 18.0
- `fontSizeXXLarge`: 20.0
- `fontSizeXXXLarge`: 24.0

---

## Referans Dosyalar

| Dosya | Açıklama |
|-------|----------|
| `lib/core/constants/app_constants.dart` | Tüm sabitler |
| `lib/core/theme/app_theme.dart` | Tema |
| `lib/core/widgets/common_widgets.dart` | Ortak widget'lar |
| `lib/core/widgets/app_dialog.dart` | Dialog sistemi |
| `lib/core/di/services_locator.dart` | DI |
| `lib/core/errors/failures.dart` | Hatalar |
| `lib/core/services/user_service.dart` | Kullanıcı servisi |
| `lib/core/utils/number_formatter.dart` | Sayı formatlama |
| `lib/core/database/app_database.dart` | Drift DB |
| `lib/features/*/data/models/*.dart` | Model kalıpları |
| `lib/features/*/data/repositories/*.dart` | Repository kalıpları |
| `lib/features/*/presentation/bloc/*.dart` | Cubit kalıpları |
| `lib/main.dart` | Uygulama giriş noktası |
