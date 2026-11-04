# ERAD mobil uygulaması — Teknik Ürün Spesifikasyonu

Hedef: projeyi hiç görmemiş deneyimli bir Flutter geliştiricinin uygulamayı olabildiğince sadık biçimde yeniden inşa edebilmesi.

- Doküman sürümü: **1.0 — tamamlandı (Bölüm 1-16)**; Bölüm 15'te kapatılmamış doğrulama listesi var
- İnceleme tarihi: 2026-11-01, dal: `ürün-ile-fatura-bulma`, commit: `5920bca`
- İnceleme yöntemi: statik kaynak kod okuması. Uygulama bu ortamda çalıştırılmadı ve ekran görüntüsü yok.
- Etiketler: **Doğrulandı** = kodda satır referansıyla görüldü. **Çıkarım** = koddan türetildi ama runtime ile teyit edilmedi. **Bilinmiyor** = koddan belirlenemedi.

---

## 1. Doküman özeti

| Konu | Durum |
|---|---|
| Uygulama türü | Arapça, RTL, muhasebe + stok + borç takip uygulaması (fatura, müşteri, tedarikçi, ürün, gider, kasa çıkışı, rapor) |
| Teknoloji | Flutter (Dart SDK `^3.10.7`), Material 3, `flutter_bloc` Cubit, `get_it`, `dartz`, Supabase, Drift (ham SQL cache), `shared_preferences`, `pdf`/`printing` |
| Platformlar | `android`, `web`, `windows` klasörleri mevcut; **`ios/` yok** (Doğrulandı: dizin listingi) |
| Backend | Supabase (Postgres + PostgREST + RPC + Realtime + Auth). Tek backend; kendi API'miz yok |
| Ekran sayısı (erişilebilir) | **24 ekran kimliği (SCR-001…SCR-024)**, bunların 5'i dashboard içi sekme; + named route'larla açılan dış sayfalar (Bölüm 5.1, 16.4/A) |
| Kod kapsamı | 235 Dart dosya / 45.796 satır; **184 dosya / 36.583 satır ulaşılabilir** (Bölüm 16.1) |
| Ölü kod | **51 ulaşılamaz dosya / ≈9.213 satır** (tam liste Bölüm 15.3) + ölü metod/stream/widget/bağımlılık/izin listesi (13.17) |
| Test | **Yok** — `test/` dizini ve `*_test.dart` dosyası yok; Bölüm 14 sıfırdan kurulacak matristir |
| Doğrulanamayanlar | Supabase şeması/RLS/view/RPC gövdeleri, gerçek runtime davranışı, piksel ölçüleri, izin diyalogları, iOS tarafı, `flutter build web` (Bölüm 15) |

Kritik uyarılar (yeniden geliştirmeden önce bilinmesi gerekenler):
1. **Stok senkronizasyonu kodda kapalı.** Fatura onay/iptal akışındaki stok hareketleri yorum satırına alınmış durumda (`lib/features/invoices/data/datasources/invoice_remote_datasource.dart`, `lib/features/invoices/data/datasources/edit_invoice_datasource.dart:127-136,182-191`). Uygulama stok miktarını değiştirmiyor. **Doğrulandı**.
2. **Bazı Supabase sorguları `user_id` ile filtrelemiyor** (`getSalesInvoiceById`, `getPurchaseInvoiceById`, update/delete yolları) → çok kullanıcılı ortamda veri sızıntısı riski. **Doğrulandı** (kod), **Bilinmiyor** (RLS policy'leri kod dışında olabilir).
3. **UI'da "sil" butonlarının bir kısmı gerçekten silmiyor** — ör. `InvoiceActionsWidget._deleteInvoice` yalnızca snackbar gösteriyor (`lib/features/invoices/presentation/widgets/invoice_actions_widget.dart:66-76`; `if (confirmed == true) { _showToast('تم حذف الفاتورة'); }` — cubit çağrısı yok). **Doğrulandı**.
4. **Uygulamada hiçbir yeniden deneme/timeout politikası yok** ve 15 yerde `catch (_)` hatayı sessizce yutuyor (Bölüm 12.5-E, 12.6).
5. **Para birimi üç yerde farklı:** kayıt DB'ye `currency_code='SAR'` yazıyor, istemci varsayılanı `SYP`, `SAR` sembol sözlüğünde yok; `User.currencyCode` hiçbir zaman `NumberFormatter`'a beslenmiyor (Bölüm 16.4/C-1).
6. **Çevrimdışı yazma yalnız müşteri ödemesinde var**; tedarikçi ödemesi çevrimdışı doğrudan hata dönüyor ve kuyruk senkronizasyonu bir kayıtta `break` ile tüm kuyruğu durdurabiliyor (Bölüm 12.7).

---

## 2. Proje yapısı ve teknoloji yığını

### 2.1 Bağımlılıklar (`pubspec.yaml:30-65`)

| Paket | Sürüm | Projedeki rolü | Referans |
|---|---|---|---|
| `flutter_bloc` | ^9.1.1 | Tüm durum yönetimi (Cubit + `equatable` state) | her `presentation/bloc/*` |
| `get_it` | ^9.2.0 | DI container, tek örnek `sl` | `lib/core/di/services_locator.dart:55` |
| `dartz` | ^0.10.1 | `Either<Failure, T>` fonksiyonel hata taşıma | tüm repository'ler |
| `equatable` | ^2.0.8 | State karşılaştırma | `*_state.dart` dosyaları |
| `supabase_flutter` | ^2.12.0 | Auth + PostgREST + RPC + Realtime | `services_locator.dart:65-69` |
| `drift` | ^2.34.0 | Yerel cache veritabanı (**ham SQL**, typed table yok) | `lib/core/database/app_database.dart` |
| `shared_preferences` | ^2.5.4 | Kullanıcı + format tercihleri | `lib/core/services/user_service.dart`, `lib/core/utils/number_formatter.dart` |
| `flutter_secure_storage` | ^10.0.0 | **Kodu yazılmış ama hiçbir yerde kullanılmıyor** | grep: hiç referans yok |
| `internet_connection_checker` | ^3.0.1 | Offline tespiti + connectivity stream | `lib/core/network/network_info.dart` |
| `pdf`, `printing` | ^3.11.3, ^5.14.2 | PDF üretimi ve `sharePdf` | `lib/core/services/pdf_invoice_service.dart` |
| `arabic_reshaper`, `bidi` | ^0.0.1 / transitive | PDF içinde Arapça harf bağlama | `pdf_invoice_service.dart:5-6,857-863` |
| `google_fonts` | ^6.2.1 | Cairo (UI) + kökte `changaTextTheme` | `lib/main.dart:47`, `lib/core/theme/app_theme.dart` |
| `iconsax` | ^0.0.8 | İkon seti (bazı ekranlarda Material ikonlarla karışık) | ör. `invoices_page.dart:129` |
| `fl_chart`, `syncfusion_flutter_charts` | ^1.1.1, ^28.2.8 | Grafikler | dashboard + expenses |
| `intl` | ^0.20.2 | Sayı/tarih formatı (`ar_SA`) | `lib/core/utils/app_utils.dart` |
| `path_provider`, `uuid` | — | Bildirim/derleme dışında kullanım **Bilinmiyor** (bu oturumda referans doğrulanamadı) | — |
| `provider` | ^6.1.5+1 | Yalnızca `create_invoice_page` içinde mi? → `flutter_bloc` kullanılıyor; `provider` bağımlılığı **kullanılmıyor olabilir** (Doğrulandı değil) | — |

SDK: `sdk: ^3.10.7` (`pubspec.yaml:22`). Paket adı: `erad`, sürüm `1.0.0+1`.

### 2.2 Dizin yapısı ve hacim

```
lib/
  main.dart                       giriş + MaterialApp + onGenerateRoute
  core/
    constants/  (2 dosya, 192 sat) app_constants.dart, api_constans.dart (yazım hatası: "constans")
    database/   (1, 201)          app_database.dart (Drift ham SQL cache)
    di/         (1, 227)          services_locator.dart
    errors/     (1, 284)          failures.dart
    network/    (1, 37)           network_info.dart
    services/   (3, 1156)         pdf_invoice_service.dart, invoice_pdf_service.dart, user_service.dart
    theme/      (1, 255)          app_theme.dart
    utils/      (5, 982)          number_formatter, app_utils, custom_loading_animation,
                                  custom_date_range_picker (tamamen yorum), financial_area_chart
    widgets/    (4, 1088)         common_widgets, app_dialog, date_filter_sheet, invoice_card_widget
  features/
    auth/            8 dosya   1.118 sat
    customer_debts/ 23 dosya   4.089 sat
    customers/       8 dosya   1.234 sat
    dashboard/      20 dosya   2.564 sat
    expenses/       16 dosya   3.563 sat
    invoices/       62 dosya  15.929 sat  ← projenin en büyük modülü, büyük kısmı ölü kod
    products/       13 dosya   2.548 sat
    reports/        12 dosya   1.462 sat
    settings/        1 dosya     455 sat
    stock/           1 dosya      87 sat
    suppliers/       8 dosya   1.098 sat
    suppliers_debts/ 20 dosya   3.418 sat
    withdrawals/    23 dosya   3.677 sat
```
Toplam: **235 Dart dosyası** (`find lib -name '*.dart' | wc -l`).

Her feature aynı katman şablonunu izliyor:
`data/datasource(s)/ → data/models/ → data/repositories/ → presentation/bloc/ → presentation/pages/ → presentation/widgets/`.
**Doğrulandı**: ör. `lib/features/invoices/{data,presentation}`, `lib/features/customers/{data,presentation}`. İstisnalar: `settings` tek dosya (`settings_page.dart`), `stock` tek dosya, `reports`/`customer_debts` içinde ek `data/services` yok.

### 2.3 Platform yapılandırması

| Dosya | Bulgular | Durum |
|---|---|---|
| `android/app/build.gradle.kts` | `namespace`/`applicationId` = `com.example.mindPrint` (tema adı `mindPrint`, `erad` değil), Java 17, release imzası debug anahtarına bağlı | Doğrulandı |
| `android/app/src/main/AndroidManifest.xml` | İzinler: `INTERNET`, `ACCESS_NETWORK_STATE`, `RECORD_AUDIO`, `MODIFY_AUDIO_SETTINGS`, `WRITE_EXTERNAL_STORAGE`, `READ_EXTERNAL_STORAGE`; `usesCleartextTraffic="true"`; tek `MainActivity` (`singleTop`, `adjustResize`); intent-filter/deep link yok | Doğrulandı |
| `ios/` | **Dizin yok** → iOS build'i bu repoda tanımlı değil | Doğrulandı |
| `web/`, `windows/` | Dizinler var; içerikleri bu incelemede okunmadı | Bilinmiyor |
| `pubspec.yaml:83-95` | `flutter_launcher_icons`: android true, ios **false**, `image_path: assets/images/logo.png`, `adaptive_icon_background: "#FFFFFF"`, `min_sdk_android: 21`. `flutter_native_splash`: `image: assets\images\log_outline.png` (**Windows ters bölü yolu** — macOS/Linux'ta asset çözümlemesi başarısız olabilir), `web: false` | Doğrulandı (satır), Çıkarım (ters bölü riski) |
| `assets/images/` | Yalnızca `logo.png` (7.254 B), `log_outline.png` (9.667 B). `AppAssets.loadingAnimation = 'assets/images/loading.gif'` → **dosya yok** | Doğrulandı |

---

## 3. Uygulama mimarisi ve veri akışı

### 3.1 Açılış sırası (`lib/main.dart:23-36`)

1. `WidgetsFlutterBinding.ensureInitialized()`
2. `await sl.initServicesLocator()` → `SharedPreferences.getInstance()`, `InternetConnectionChecker.createInstance()`, `Supabase.initialize(url/anonKey)`, `AppDatabase.create()` (Drift), tüm datasource/repository/cubit kayıtları (`lib/core/di/services_locator.dart:57-227`)
3. `await NumberFormatter.initialize()` ve `await NumberFormatter.setArabicFormat(true)` → preferensten para birimi/sayı formatı yüklenir, varsayılan Arapça kısa format (`lib/core/utils/number_formatter.dart`)
4. `await initializeDateFormatting('en')` — dikkat: `'ar'` değil
5. `runApp(BlocProvider(AuthCubit..getCurrentUser()) → ERADApp)`

`AuthCubit` root'ta tek; `getCurrentUser()` senkron olarak `AuthLoading` emit eder, sonra `Authenticated` veya `Unauthenticated` (`lib/features/auth/presentation/bloc/auth_cubit.dart`).

### 3.2 Katmanlar ve tip akışı

```
UI (page/widget)
  └─ Cubit (flutter_bloc)               state: equatable sınıfları
       └─ Repository (abstract + Impl)  → Either<Failure, T>
            ├─ RemoteDataSource         → SupabaseClient (.from/.rpc/.stream/auth)
            └─ LocalDataSource          → AppDatabase (Drift, ham SQL JSON cache)
                 └─ NetworkInfo         → internet_connection_checker
```
- **Hata modeli:** `lib/core/errors/failures.dart` içindeki `Failure` alt tipleri Arapça mesaj + `code` taşır; `exceptionToFailure()` ham exception'ı eşler. **Doğrulandı**.
- **Offline-first:** repository'ler `NetworkInfo.isConnected` kontrol edip remote başarısızsa Drift cache'ten okuyor (ör. `invoice_repository.dart`, `customer_debt_repository_impl.dart`, `dashboard_repository.dart`). Yazma işlemleri çevrimdışıyken reddediliyor; `customer_debts` tarafında `pending_payments` tablosu var. **Doğrulandı** (kod), **Bilinmiyor** (kuyruğun tekrar gönderim zamanı).

### 3.3 Cache veritabanı (`lib/core/database/app_database.dart`)

- Dosya adı: `erad_cache.db`, `NativeDatabase` + `LazyDatabase`, `runMigrations` ile `CREATE TABLE IF NOT EXISTS`.
- Tablolar **JSON blob** modeli: `id TEXT PRIMARY KEY, data TEXT, synced_at INTEGER` pattern'i; tablolar: `sales_invoices_cache`, `purchase_invoices_cache`, `customers_cache`, `products_cache`, `dashboard_cache`, `customer_debts_cache`, `suppliers_cache`(+ `pending_payments`, `ensurePendingPaymentsTable` ile geç kurulum).
- API: `upsertJson`, `getAllJson`, `upsertJsonList`, `clearTable`, `upsertCustomerData`, `getCustomerData`, `insertPendingPayment`, `getPendingPayments`, `deletePendingPayment`.
- **Sonuç:** şema kolonları uygulamada tanımlı değil; Supabase satırları olduğu gibi JSON olarak saklanıyor. Yeniden geliştirmede typed Drift tablolarına geçmek istenirse alan listeleri Bölüm 9'daki model sınıflarından alınmalı. **Doğrulandı**.

### 3.4 Tercih anahtarları (`shared_preferences`)

| Anahtar | Yazan | Okuyan | Anlamı |
|---|---|---|---|
| `use_arabic_number_format` | `NumberFormatter.setArabicFormat` | `NumberFormatter`, `settings_page.dart` | Arapça kısa sayı adı (مليار/مليون/ألف) açık/kapalı |
| `selected_currency` | `NumberFormatter` | aynı | `SYP`/`USD`/`EUR`/`TRY` sembolü |
| `use_short_number_format` | `NumberFormatter` | aynı | K/M kısa format |
| `user_id`, `user_name`, `user_email` | `UserService` (`lib/core/services/user_service.dart`) | dashboard, header, logout | Otururan kullanıcı önbelleği |

**Çelişki / risk:** `UserService.clearUserInfo()` → `prefs.clear()` çağırıyor; para birimi ve sayı formatı tercihlerini de siliyor. **Doğrulandı** (`user_service.dart`).

### 3.5 Tema ve tasarım token'ları

- Kök `MaterialApp`: `theme: AppTheme.lightTheme.copyWith(textTheme: GoogleFonts.changaTextTheme())` (`lib/main.dart:46-48`), `locale: Locale('ar')`, `builder` içinde `textScaler` 0.8–1.0 aralığına kısıtlanmış ve tüm ağaç `Directionality(TextDirection.rtl)` içine sarılmış (`lib/main.dart:50-68`). **Doğrulandı.**
- `AppTheme.lightTheme` Material 3, Cairo font ailesi, `cardElevation = 0` yaklaşımı (`lib/core/theme/app_theme.dart`). **Doğrulandı.**
- Token tablosu Bölüm 6.1'de.

### 3.6 Veri akışı örüntüleri (modüller arası)

1. **Realtime stream:** `CustomerCubit`, `SupplierCubit`, `ProductCubit`, `InvoiceCubit` constructor/listener'da Supabase `.stream(primaryKey: ['id'])` aboneliği kuruyor → veri geldiğinde `XLoaded` emit ediliyor. Bu yüzden ekranlar listelemeyi elle çağırmadan doluyor (`lib/features/customers/presentation/bloc/customer_cubit.dart:17-50` ve benzerleri). **Doğrulandı.**
2. **Optimistic update:** fatura durum/ödeme değişimi önce state'e yazılıp sonra Supabase'e gönderiliyor; hata durumunda geri alınıyor + Arapça snackbar (`lib/features/invoices/presentation/bloc/invoice_cubit.dart`, `invoice_detail_page.dart`). **Doğrulandı.**
3. **Bakiye RPC'leri:** müşteri/tedarikçi borcu için `update_customer_balance`, `update_supplier_balance` RPC çağrıları. **Doğrulandı** (istemci tarafı), **Bilinmiyor** (SQL gövdeleri).

---

## 4. Navigasyon haritası

### 4.1 Rotasyon mekanizması

- `MaterialApp` sadece `home: MainWrapper()` + `onGenerateRoute: _generateRoute` kullanıyor (`lib/main.dart:70-71`). İsim tabanlı `routes:` sözlüğü yok.
- `MainWrapper` (`lib/main.dart:111-132`): `AuthLoading` → `Scaffold(CircularProgressIndicator())`; `Authenticated` → `DashboardPage`; diğer → `LoginPage`.
- `_generateRoute` switch'i (`lib/main.dart:75-108`):

| `AppRoutes` sabiti | Yol | Handler | Not |
|---|---|---|---|
| `products` | `/products` | `ProductsPage` | BlocProvider yok → sayfa kendi sağlıyor |
| `customers` | `/customers` | `CustomersPage` |  |
| `invoices` | `/invoices` | `BlocProvider(sl<InvoiceCubit>()) → InvoicesPage` |  |
| `suppliers` | `/suppliers` | `SuppliersPage` |  |
| `expenses` | `/expenses` | `ExpensesPage` |  |
| `withdrawals` | `/withdrawals` | `WithdrawalsPage` |  |
| `settings` | `/settings` | `BlocProvider.value(context.read<AuthCubit>()) → SettingsPage` |  |
| `customerDebts` | `/customer-debts` | `CustomerDebtsPage` |  |
| `takrirler` | `/takrirler` | `TakrirlerPage` |  |
| — (default) | eşleşmeyen her yol | `DashboardPage` | `login`, `analytics`, `profile`, `createInvoice`, `/:id` detay yolları **buraya düşüyor** |
| `dashboard` | `/dashboard` | handler yok → default `DashboardPage` | şans eseri doğru |
| `customerDetails` | `/customers/:id` | literal string; gerçek id ile çağrılsa bile default'a düşer | **Ölü tanım** |
| `productDetails`, `invoiceDetails`, `supplierDetails`, `expenseDetails` | `*/:id` | handler yok | **Ölü tanım** |
| `login` | `/login` | handler yok → `DashboardPage` | **Çelişki** |
| `analytics` | `/analytics` | handler yok → `DashboardPage` | **Çelişki** |
| `createInvoice` | `/invoices/create` | handler yok → `DashboardPage` | **Çelişki** |
| `profile` | `/profile` | handler yok → `DashboardPage` | **Ölü tanım** |

**Doğrulandı.** Sonuç: pratikte navigasyonun tamamı `Navigator.push(MaterialPageRoute(...))` ile yapılıyor; isim tabanlı rota yalnızca dışarıdan `pushNamed` gelirse çalışıyor.

**Deep link / bildirim:** AndroidManifest'te intent-filter yok (`android/app/src/main/AndroidManifest.xml`), kodda `getInitialLink`/`uni_links`/Firebase Messaging referansı yok → derin bağlantı ve bildirim-tıklama akışı **uygulanmamış**. **Doğrulandı** (yokluk).

### 4.2 Metin navigasyon haritası

```
MainWrapper
├─ AuthLoading → (spinner)
├─ Unauthenticated → LoginPage ──[başarılı giriş]→ MainWrapper→DashboardPage
└─ Authenticated → DashboardPage (alt navigasyon, 5 sekme)
     ├─ Sekme 0 "الرئيسية"   → DashboardOverview
     ├─ Sekme 1 "الفواتير"   → InvoicesPage(isLocal: false|true)
     │     ├─ kart tap → InvoiceDetailPage(invoiceId, type)
     │     │     ├─ "تعديل" → EditInvoicePage(invoiceId, isSales)  [pop(true)]
     │     │     ├─ "الدفع" → PaymentStatusDialog → updatePaymentStatus
     │     │     ├─ durum → InvoiceStatusDialog (yalnız detay sayfasından)
     │     │     ├─ "حذف الفاتورة" → DeleteInvoiceDialog → cubit silme
     │     │     └─ "PDF" → PdfInvoiceService + Printing.sharePdf
     │     └─ FAB "إضافة فاتورة جديدة" → CreateInvoicePage
     │           └─ ProductAddWidget tam ekran → ProductAddFullscreenPage
     ├─ Sekme 2 "د.عملاء"    → CustomerDebtsPage(isLocal)
     │     └─ kart tap → CustomerDetailPage → (CustomerInvoicesPage → CustomerInvoiceDetailPage)
     ├─ Sekme 3 "د.موردين"   → SuppliersDebtsPage(isLocal)
     │     └─ kart tap → SupplierDetailPage
     └─ Sekme 4 "المزيد"     → MorePage (7 kart)
           ├─ /products  → ProductsPage  (+ ürün form dialog/sheet, kategori yönetimi)
           ├─ /customers → CustomersPage
           ├─ /suppliers → SuppliersPage
           ├─ /expenses  → ExpensesPage  (+ ExpenseFormDialog, ExpenseCategoriesDialog)
           ├─ /withdrawals → WithdrawalsPage (+ AddWithdrawalDialog)
           ├─ /takrirler → TakrirlerPage → CustomerInvoicesPage → CustomerInvoiceDetailPage
           │                               └→ StockTrackingPage
           └─ /settings  → SettingsPage
```

### 4.3 Geçiş detayları

| # | Kaynak | Tetikleyici | Açılan | Parametre | Ön koşul | Geri davranışı |
|---|---|---|---|---|---|---|
| T1 | `LoginPage` | geçerli form + "دخول" | `MainWrapper` state değişimi (`Authenticated`) | — | ağ bağlantısı (offline fallback var) | — (LoginPage stack'i boşaltır) |
| T2 | `DashboardPage` sekme çubuğu | sekme tap | aynı Scaffold içinde body değişimi | `isLocal` = `!_isConnected` | — | sekme durumu korunur; bağlantı kesilirse `_selectedIndex > 1` → 0 (`dashboard_page.dart:79-88`) |
| T3 | `InvoicesPage` FAB | tap | `CreateInvoicePage` | yok | `widget.isLocal == false` (offline'da FAB yok, `invoices_page.dart:155`) | `Navigator.pop` → liste yenilenir (realtime stream) |
| T4 | `InvoicesPage` kart | tap | `InvoiceDetailPage` | `invoiceId`, `type` ('sale'/'purchase') | `InvoiceFiltered` state | pop → liste |
| T5 | `InvoiceDetailPage` "تعديل" | tap | `EditInvoicePage` | `invoiceId`, `isSales` | fatura yüklendi | `EditInvoiceUpdated` → snackbar + `pop(true)` (`edit_invoice_page.dart:89-96`) |
| T6 | `ProductAddWidget` tam ekran ikonu | tap | `ProductAddFullscreenPage` | `InvoiceCubit`/`ProductCubit` `BlocProvider.value` ile taşınır | — | pop → aynı cubit'e yazılmış ürünler görünür |
| T7 | `MorePage` kartı | tap | ilgili sayfa (`AppRoutes` sabitiyle `pushNamed` veya doğrudan `push` — MorePage satırlarına bakınız) | — | — | pop → MorePage |
| T8 | `CustomerDebtsPage` kart | tap | `CustomerDetailPage` | müşteri id | — | pop |
| T9 | `SettingsPage` "تسجيل الخروج" | onay dialogu → `AuthCubit.signOut()` | `Unauthenticated` → `LoginPage` | — | oturur | — |

**Not:** T7 için `more_page.dart` içindeki gerçek geçiş yöntemi Bölüm 5.4'te satır referansıyla netleştirilecek. **Bilinmiyor (henüz bu bölümde doğrulanmadı).**

---

## 5. Ekran envanteri

> Bu bölüm modül modül dolduruluyor. Her ekran için: kimlik, kaynak dosya, amaç, layout, metinler, durumlar.

### 5.1 Ekran kimlik tablosu

| ID | Ekran | Kaynak dosya · sınıf | Erişim yolu | Durum |
|---|---|---|---|---|
| SCR-001 | Başlangıç/yüklenme | `lib/main.dart` · `MainWrapper` | app launch | Doğrulandı |
| SCR-002 | Giriş / Kayıt | `lib/features/auth/presentation/pages/login_page.dart` · `LoginPage` + `widgets/login_form.dart` · `LoginForm` | auth yoksa | Doğrulandı |
| SCR-003 | Dashboard kabuğu (alt nav) | `lib/features/dashboard/presentation/pages/dashboard_page.dart` · `DashboardPage` | `Authenticated` veya `/dashboard` | Doğrulandı |
| SCR-004 | Ana özet (sekme 0) | `.../dashboard_overview.dart` · `DashboardOverview` | sekme | Doğrulandı |
| SCR-005 | Faturalar listesi (sekme 1) | `.../invoices/.../invoices_page.dart` · `InvoicesPage(isLocal)` | sekme veya `/invoices` | Doğrulandı |
| SCR-006 | müşteri borçları (sekme 2) | `.../customer_debts/.../customer_debts_page.dart` · `CustomerDebtsPage(isLocal)` | sekme / `/customer-debts` | Bölüm 5.5 |
| SCR-007 | tedarikçi borçları (sekme 3) | `.../suppliers_debts/.../suppliers_debts_page.dart` · `SuppliersDebtsPage` | sekme (yalnız online) | Bölüm 5.5 |
| SCR-008 | Daha fazla (sekme 4) | `.../dashboard/.../more_page.dart` · `MorePage` | sekme | Doğrulandı |
| SCR-009 | Fatura detay | `.../invoices/.../invoice_detail_page.dart` · `InvoiceDetailPage` | SCR-005 kart tap | Doğrulandı |
| SCR-010 | Fatura oluştur | `.../invoices/.../create_invoice_page.dart` · `CreateInvoicePage` | SCR-005 FAB | Doğrulandı |
| SCR-011 | Fatura düzenle | `.../invoices/.../edit_invoice_page.dart` · `EditInvoicePage` | SCR-009 "تعديل" | Doğrulandı |
| SCR-012 | Tam ekran ürün ekle | `.../invoices/presentation/widgets/product_add_fullscreen_widget.dart` · `ProductAddFullscreenPage` | SCR-010 fullscreen ikonu | Doğrulandı |
| SCR-013 | Ayarlar | `.../settings/.../settings_page.dart` · `SettingsPage` | MorePage `/settings` | Doğrulandı |
| SCR-014 | Ürünler | `.../products/.../products_page.dart` · `ProductsPage` | `/products` | Bölüm 5.6 |
| SCR-015 | Müşteriler | `.../customers/.../customers_page.dart` · `CustomersPage` | `/customers` | Bölüm 5.5 |
| SCR-016 | Tedarikçiler | `.../suppliers/.../suppliers_page.dart` · `SuppliersPage` | `/suppliers` | Bölüm 5.5 |
| SCR-017 | Giderler | `.../expenses/.../expenses_page.dart` · `ExpensesPage` | `/expenses` | Bölüm 5.7 |
| SCR-018 | Kasa çıkışları | `.../withdrawals/.../withdrawals_page.dart` · `WithdrawalsPage` | `/withdrawals` | Bölüm 5.7 |
| SCR-019 | Raporlar (Takrirler) | `.../reports/.../takrirler_page.dart` · `TakrirlerPage` | `/takrirler` | Bölüm 5.6 |
| SCR-020 | Müşteri/tedarikçi fatura listesi | `.../reports/.../customer_invoices_page.dart` · `CustomerInvoicesPage` | SCR-006/019 | Bölüm 5.6 |
| SCR-021 | Fatura detayı (rapor) | `.../reports/.../customer_invoice_detail_page.dart` · `CustomerInvoiceDetailPage` | SCR-020 | Bölüm 5.6 |
| SCR-022 | Stok takibi | `.../reports/.../stock_tracking_page.dart` · `StockTrackingPage` | SCR-019 | Bölüm 5.6 |
| SCR-023 | Müşteri detay (borç) | `.../customer_debts/.../customer_detail_page.dart` · `CustomerDetailPage` | SCR-006 | Bölüm 5.5 |
| SCR-024 | Tedarikçi detay (borç) | `.../suppliers_debts/.../supplier_detail_page.dart` · `SupplierDetailPage` | SCR-007 | Bölüm 5.5 |
| — | Fatura yönetimi | `.../invoices/.../invoice_management_page.dart` · `InvoiceManagementPage` | **hiçbir yerden açılmıyor** | Ölü kod |

Bottom sheet / dialog ekranları Bölüm 5.8'de.

### 5.2 SCR-002 Giriş ekranı (`LoginPage` + `LoginForm`)

- Amaç: Supabase Auth ile e-posta/şifre girişi; aynı formda kayıt modu ve şifre sıfırlama talebi.
- Yapı: `LoginPage` (Scaffold, AppBar yok) → `BlocListener<AuthCubit>` → `Center > SingleChildScrollView(padding: all 16) > LoginForm` (`login_page.dart:14-58`).
- **Çelişki (Doğrulandı):** root `MaterialApp` zaten bir `AuthCubit` sağlıyor; `LoginPage` ikinci bir `AuthCubit` yaratıyor (`login_page.dart:14-16`). Login sonucu root cubit'i güncellemez; geçiş `Navigator.pushReplacement(DashboardPage)` ile yapılıyor (`login_page.dart:26-31`), bu yüzden root `MainWrapper` state'i eski kalıyor → app restart'ta `getCurrentUser()` cache'e düşüyor.
- Layout üst→alt (`login_form.dart:51-188`): logo `Image.asset(AppAssets.logo, 60×60)` → "إراد" (25 px bold, center) → "نظام المحاسبة والمخزون" (`titleMedium`) → 100 px boşluk → e-posta → (kayıtta) şirket adı → şifre → 24 px → submit butonu → toggle TextButton → (girişte) "نسيت كلمة المرور؟".
- State'ler: `AuthLoading` → buton `onPressed: null`, içinde 20×20 `CircularProgressIndicator(strokeWidth: 2)`; `AuthError` → kırmızı snackbar (`Colors.red`); `AuthSuccess` → yeşil snackbar; `AuthRegistered` → yeşil snackbar "تم إنشاء الحساب بنجاح. يرجى تسجيل الدخول." + yeni `LoginPage` pushReplacement (`login_page.dart:39-51`).
- Erişilebilirlik/odak: explicit focus order yok; klavye tipi alan bazında tanımlı (Bölüm 8.1).
- Bilinmiyor: gerçek Supabase proje ayarları (e-posta doğrulama zorunlu mu, min şifre politikası).

### 5.3 SCR-003 Dashboard kabuğu

- `MultiBlocProvider(lazy: true)` ile `InvoiceCubit`, `ProductCubit`, `CustomerCubit`, `SupplierCubit` sağlıyor (`dashboard_page.dart:100-107`). Dört cubit de constructor'da Supabase realtime aboneliği başlatıyor → sekme gezilmese bile stream'ler açık.
- Alt navigasyon: `bottomNavigationBar` standart `NavigationBar` değil; `AppColors.primary` arka plan, radius 12, `Padding(h:6, v:10)`, `Row` içinde `Expanded` `GestureDetector`'lar (`dashboard_page.dart:109-153`).
  - Seçili sekme: beyaz (`AppColors.surface`) arka plan, radius 8, metin `AppColors.primary` w600; seçili olmayan: şeffaf, metin beyaz w400; font 13 px; dikey padding 14 px.
  - Animasyon: `AnimatedContainer(duration: 200 ms)` — curve tanımsız (Material varsayılanı).
- Sekme listesi bağlantıya göre değişiyor (`dashboard_page.dart:40-55`):
  - Online: `الرئيسية, الفواتير, د.عملاء, د.موردين, المزيد` (5)
  - Offline: `الرئيسية, الفواتير, ديون` (3) — üçüncü sekme `CustomerDebtsPage(isLocal: true)` gösteriyor.
- Bağlantı değişimi: `NetworkInfo.connectionStream` dinleniyor; çevrimdışı olunca `_selectedIndex > 1` ise 0'a düşüyor (`dashboard_page.dart:79-88`). **Doğrulandı.**
- Klavye: `WidgetsBindingObserver.didChangeMetrics` ile `viewInsets.bottom > 100` → `_isKeyboardVisible`; bu bayrak build'de kullanılmıyor (ölü durum). **Doğrulandı.**
- Body: `Column(children:[Expanded(_buildContent())])` — ek padding yok.

### 5.4 SCR-008 MorePage

- `Scaffold(appBar: AppBar('المزيد', centerTitle: true))`, body `Padding(all 16) > GridView` (`more_page.dart:10-69`).
- Grid: `crossAxisCount: 2`, `mainAxisSpacing: 12`, `crossAxisSpacing: 12`, `childAspectRatio: 1.1`, `BouncingScrollPhysics`. **Doğrulandı.**
- 7 kart (sıra: العملاء، الموردون، النفقات، السحوبات، المنتجات، التقارير، الإعدادات) → `Navigator.pushNamed(context, AppRoutes.*)`. T7'nin geçiş yöntemi burada doğrulandı: **isim tabanlı push**, `_generateRoute` handler'ları mevcut.
- `color` parametresi kartlarda **kullanılmıyor** (ikondaki renk her zaman `AppColors.primary`); kart: `Material(AppColors.divider)` üstüne `Container(surface, border primary 1 px, radius 16, padding 20)`, ikon 40 px, başlık 15 px w600 primary. **Doğrulandı** (`more_page.dart:88-121`).
- Responsive: `crossAxisCount` sabit 2 → geniş ekranda kartlar uzuyor (medya sorgusu yok). **Doğrulandı (kod).**

### 5.5 SCR-013 Ayarlar

`lib/features/settings/presentation/pages/settings_page.dart` — tek dosya, 4 kart, state `SettingsPage`.

| # | Bölüm | İçerik | Etkileşim |
|---|---|---|---|
| 1 | Header | `IconButton(Icons.navigate_before, 30 px, Colors.black)` → `Navigator.pop` + "الإعدادات" (20 px, normal) | — |
| 2 | "معلومات الشركة" / "اسم الشركة المعروض في الفواتير" | `TextField(hintText: 'اسم الشركة')` + "حفظ" butonu | boşsa snackbar "الرجاء إدخال اسم الشركة"; doluysa `AuthCubit.updateProfile(user.copyWith(businessName))` → success snackbar "تم تحديث اسم الشركة بنجاح" (bg `AppColors.success`) |
| 3 | "العملة" / "اختر العملة الافتراضية" | `Wrap(spacing 8, runSpacing 8)` içinde `NumberFormatter.availableCurrencies` = `SYP, USD, EUR, TRY` chip'leri | tap → `NumberFormatter.setCurrency(code)` (prefs) + setState; seçili chip: bg primary, metin beyaz w600 |
| 4 | "تنسيق الأرقام" / "استخدام K/M للأرقام الكبيرة" | `Switch(activeColor: primary)` | `setUseShortFormat` (prefs). Dikkat: tüm `InkWell` de aynı toggle'ı yapıyor → kartın boşluğuna dokunmak switch'i ters çeviriyor (çift tetikleme). **Doğrulandı** (`settings_page.dart:307-361`) |
| 5 | "تسجيل الخروج" / "تسجيل الخروج من الحساب" | ikon `Icons.logout` (error), trailing `Icons.arrow_back_ios` | dialog "تأكيد تسجيل الخروج" + "هل أنت متأكد من تسجيل الخروج؟", butonlar `إلغاء` / `تسجيل الخروج` (bg error). Onay: `Navigator.pop(context)` **sonra** `AuthCubit.logout()` → `Unauthenticated` → `LoginPage` |

- **Eksik alan (Doğrulandı):** kayıt olurken yazılan `currency_code`, `language`, `theme_mode`, `full_name`, `phone`, `business_address`, `tax_number` alanlarının hiçbiri bu ekranda düzenlenmiyor; `updateProfile` bunları mevcut `User` nesnesinden olduğu gibi geri yazıyor.
- **Risk (Doğrulandı):** şirket adı kaydında `AuthCubit.updateProfile` hata fırlatmaz (EitherLeft → `AuthError` state), UI ise `catch (e)` bloğuna bakar → hata durumunda "خطأ في التحديث" snackbar'ı **görünmez**, yalnızca BlocListener olmayan ekranda state değişir.

### 5.6 SCR-004 Ana özet (DashboardOverview)

- `BlocProvider(create: sl<DashboardCubit>())` → içerik (`dashboard_overview.dart:12-19`). `DashboardCubit` constructor'ı `_initialize()` ile içinde bulunulan yıl için `loadDashboardData(year: '<currentYear>')` çağırıyor (`dashboard_cubit.dart:19-26`).
- AppBar: `AppColors.primary` arka plan, başlık "لوحة التحكم" (18 px bold, beyaz), sağda `AppBarDateFilter(color: AppColors.surface)` (`dashboard_overview.dart:28-44`).
- Body durumları (`dashboard_overview.dart:45-93`):
  - `DashboardInitial` / `DashboardLoading` → `Center(CircularProgressIndicator(color: primary))`
  - `DashboardError` → yalnızca metin (renk `AppColors.error`), tekrar deneme butonu **yok**
  - `state is! DashboardLoaded` → `SizedBox.shrink()`
  - `DashboardLoaded` → `SingleChildScrollView(padding: all 16)` içinde 3 blok:
    1. `_CashBalanceCard`: tam genişlik, padding 24, border `AppColors.divider`, radius 8; "الرصيد الحالي" 14 px w400 textSecondary → `NumberFormatter.format(cashInHand)` 36 px bold `AppColors.text` → para birimi sembolü ayrı satır 14 px.
    2. `_SummaryRow`: iki `_SummaryCard` yan yana (Expanded, aralarında 16 px): "إجمالي المبيعات" ve "إجمالي المشتريات"; başlık 12 px textSecondary, değer `NumberFormatter.formatShort(...)` 24 px bold. padding 16, radius 8.
    3. `_ProductStockList` — **yalnız `productStock.isNotEmpty` ise** (boş durum metni yok). Başlık "المخزون" 14 px w500; tablo başlığı `المنتج`(flex 3) / `مُباع`(flex 1) / `الباقي`(flex 1), 11 px w500 textSecondary, satırlar 13/14 px, alt border `divider`, dikey padding 14. Kalan ≤ 0 ise değer `AppColors.error`.
- **Çelişki (Doğrulandı):** "مُباع" (satılan) sütunu `product.totalPurchasedQty` (=satın alınan miktar) alanına bağlı; `totalSoldQty` hiç gösterilmiyor (`dashboard_overview.dart:321-356`, model: `dashboard_product_stock.dart:9`).
- **Hata yutma (Doğrulandı):** `loadDashboardData` repository `Left` dönerse değeri varsayılan (0) bırakıp `DashboardLoaded` emit ediyor (`dashboard_cubit.dart:51-72`) → kullanıcı hata yerine sıfır görüyor. `DashboardError` yalnızca beklenmedik exception'da.
- Yenileme: pull-to-refresh ve refresh butonu yok; `refreshData()` metodü var ama UI'dan çağrılmıyor (grep: çağrı yok). **Doğrulandı.**
- Veri kaynakları: `rpc('get_dashboard_financials', {p_user_id, p_start_date, p_end_date})` ve `from('dashboard_product_stock').select().eq('user_id', …)` (`dashboard_remote_datasource.dart:29-56`). **Doğrulandı** (istemci), **Bilinmiyor** (view/RPC SQL tanımı).
- Tarih filtresi: `AppBarDateFilter` yalnızca `DashboardLoaded` iken görünür; etiket custom aralıkta `gün/ay - gün/ay`, değilse yıl (`app_bar_date_filter.dart:21-23`). Tap → `DateFilterSheet.show(...)`; yıl seçimi `setYear`, aralık `setCustomDateRange`, temizleme `clearCustomDateRange`, "تاريخ مخصص" → `showDateRangePicker(2020–2030)`, seçimden sonra sheet kapatılıyor (`app_bar_date_filter.dart:89-121`).

### 5.7 Faturalar modülü ekranları

#### SCR-005 `InvoicesPage` (`invoices_page.dart`)
- Parametre: `isLocal` (varsayılan `false`). Offline'da FAB yok (`invoices_page.dart:155`) → yeni fatura oluşturulamaz; `SliverToBoxAdapter` alt boşluğu `isLocal ? 0 : 100`.
- AppBar: başlık "الفواتير" center; sağda tarih filtresi çipi: `Iconsax.calendar` 16 + etiket (13 px w500 primary) + `Iconsax.arrow_down_1` 14, arka plan `primary α0.1`, border `primary α0.2`, radius 20, padding h12/v7, dikey margin 8 (`invoices_page.dart:113-152`). Etiket: aktif aralık varsa `gün/ay - gün/ay`, yoksa "السنة".
- Çip tap → `DateFilterSheet.show(...)`; yıllar `_getAvailableYears()` = mevcut yıl ve önceki 4 yıl (`invoices_page.dart:95-98`); aralık seçimi `cubit.setDateRange`, sheet kapanır.
- Body durumları: `InvoiceLoading` → spinner; `InvoiceError` → icon `Icons.error_outline` 64 `Colors.grey.shade400` + "حدث خطأ" (`titleLarge`) + `state.message` (`bodyMedium`) + "حاول ثانية" `ElevatedButton` → `getAllInvoices()`; `InvoiceFiltered` → liste; diğer → spinner (`invoices_page.dart:180-283`).
- Liste üstü kontroller (`InvoiceFiltered` içinde, padding LTRB 16,16,16,0):
  1. Arama `TextField` — hint "بحث عن فاتورة أو عميل أو مورد...", `Iconsax.search_normal` 20, radius 10, 14 px metin; `initState`'te controller'a listener bağlanmış → her değişimde `cubit.setSearchQuery(text)` (`invoices_page.dart:28-31, 288-316`).
  2. Filtre kartı (padding 12, radius 12, border `divider`): "النوع" (11 px w500 textSecondary) + chip satırı [`بيع`, `شراء`] (note: "الكل" seçeneği yorum satırında → **tip filtresi temizlenemez**, `selectedType` varsayılanı kontrol edilmeli); "حالة الدفع" + [`الكل`, `دين`, `نقدي`] (`invoices_page.dart:340-368`).
  3. Chip satırı bileşeni: dış container bg `AppColors.divider`, radius 10, padding 3; her chip `Expanded`, iç padding v10, radius 8, seçili → bg primary + beyaz metin, değilse şeffaf + textSecondary; font 13 w500; aralarında 3 px (`invoices_page.dart:374-418`).
- Kartlar: `InvoiceCardWidget(invoice, type)` — `type` `invoice.runtimeType.toString().contains('Sales')` ile çıkarılıyor (`invoices_page.dart:250-253`). Kart görünüm spesifikasyonu `lib/core/widgets/invoice_card_widget.dart` (Bölüm 6.4).
- Boş liste → `SliverFillRemaining(InvoiceEmptyStateWidget())`: beyaz kart (padding 48, margin 24, radius 12, border `#E5E7EB`), 64×64 daire `#F3F4F6` içinde `Icons.search_off` 32 `#9CA3AF`, "لم يتم العثور على فواتير" (`titleLarge`, `#374151`, w600), "جرب فلترة مختلفة أو حاول البحث مرة أخرى." (`bodyMedium`, `#6B7280`) (`invoice_empty_state_widget.dart`). **Doğrulandı:** bu ekran sabit Tailwind grileri kullanıyor, `AppColors` token'ları değil.

#### SCR-010 `CreateInvoicePage`
- Providers: `InvoiceCubit(sl<InvoiceRepository>())`, `ProductCubit`, `CustomerCubit`, `SupplierCubit` (hepsi `sl` üzerinden; son üçü constructor'da realtime stream başlatıyor) (`create_invoice_page.dart:29-49`).
- AppBar: "إنشاء فاتورة جديدة" (bold, `AppColors.text`), bg `AppColors.background`, elevation 0, centerTitle. Body: `SingleChildScrollView(padding: h16)` + 5 blok, aralarında 16 px, sonda 100 px boşluk (`create_invoice_page.dart:83-101`).
- Bloklar (üst→alt): `CombinedInvoiceInfoWidget` (tip + karşı taraf), `InvoiceDatesWidget`, `ProductAddWidget`, `InvoiceSummaryWidget`, `InvoiceActionsWidget`.
- **Çelişki (Doğrulandı):** `InvoiceTypeSelectorWidget` ve `InvoiceFiltersWidget`, `InvoiceHeaderWidget`, `InvoiceNotesWidget`, `InvoiceItemsWidget`, `InvoiceListWidget`, `InvoiceProductListWidget`, `InvoiceInfoGridWidget`, `InvoiceStatsWidget`, `InvoiceDetailsWidget`, `Sales/PurchaseInvoiceListWidget`, `QuickProductAddCard(+Simple)`, `CustomerSupplierSearchCard(+New/Widget)` dosyaları mevcut ama bu sayfada kullanılmıyor (Bölüm 15.3).

##### Bileşen detayları
1. `CombinedInvoiceInfoWidget` (`combined_invoice_info_widget.dart`) — "معلومات الفاتورة" kartı; satış/alış ve آجل/نقdi seçim satırları + müşteri/tedarikçi arama alanı. `didChangeDependencies` içinde `postFrameCallback` ile `isSale ? cubit.setSupplier(null) : cubit.setCustomer(null)` çağrılıyor (`:22-38`) → bağımlılık değişen her build'de **karşı taraf seçimi temizleniyor**. Arama sonuçları `CustomerCubit`/`SupplierCubit` state'inden filtreleniyor (ilk 10).
2. `InvoiceDatesWidget` (`invoice_dates_widget.dart`) — Card "التواريخ"; iki readonly `TextFormField` ("تاريخ الفاتورة", "تاريخ الاستحقاق"), prefix ikon + `suffixIcon` takvim, `readOnly: true` + `onTap` → `showDatePicker(2020–2030)`, tema override (primary/onPrimary/surface/onSurface). `initState` → `postFrameCallback`: fatura tarihi yoksa bugün yazılır **ve** `cubit.setInvoiceDate(now)` çağrılır; vade tarihi yoksa fatura tarihine eşitlenir (`:36-52`). Fatura tarihi değişince vade aynıysa o da birlikte güncellenir (`:106-113`). `InvoiceFormUpdated(updateType=='clearAll')` dinlenince alanlar sıfırlanıyor (`:118-131`). Metin formatı `yyyy-M-dd` (ay/gün zero-padded) (`:55-57`).
3. `ProductAddWidget` (`product_add_widget.dart`) — başlık satırı: "إضافة منتج" + sayaç rozeti "`N` منتج" (bg primary α0.1, radius 20, h12/v6) + tam ekran butonu (`Icons.fullscreen` 18, radius 20). Body: `_buildMobileAddForm()` (sabit; masaüstü varyantı yok) = arama `TextField` ("اسم المنتج", hint "ابحث عن منتج أو اكتب اسم المنتج...") + sonuç listesi (`maxHeight 150`, `ListTile.dense`, başlık `product.nameWithMeasurementUnit`) + `[الكمية (digitsOnly, center)] [إضافة (100×48)]`. Altında uyarı kutusu: "اسحب لليمين لحذف المنتج" (padding 10, border primary α0.5, bg primary α0.1, 14 px) ve `ProductListWidget`.
   - Etkileşim akışı: arama → sonuç seçimi (`_onProductSelected`) alanı "Ad (birim)" yapar ve odak miktar alanına geçer; miktar `onSubmitted` → seçili ürün varsa `InvoiceCubit.addInvoiceItem`, yoksa `_confirmAddProduct()` yoluyla ada göre eşleşme aranır.
   - **Bug (Doğrulandı):** `_confirmAddProduct` içinde `existingProduct!.unit` force-unwrap (`product_add_widget.dart:158`) — listede olmayan bir ad yazılırsa `Null check operator used on a non-null value` ile çöker. Miktar alanı boşsa zaten `return` ediyor (`:113-120`), bu yüzden çökme koşulu: ad var + miktar > 0 + eşleşen ürün yok.
4. `ProductListWidget` (`product_list_widget.dart`) — her satır `Dismissible(direction: endToStart)`, arka plan `AppColors.error` + sağda silme ikonu 24; kart padding 12, radius 10, margin-bottom 8. Üst satır: `item.nameWithMeasurementUnit` (14 px w600) + "×N" rozeti (bg primary α0.1, radius 6, 13 px bold primary) + toplam (`AppUtils.formatNumber(total) + sembol`, 14 px bold primary). Alt satır: "السعر:" + tıklanabilir fiyat kutusu (`NumberFormatter.format(unitPrice)`), tap → inline `TextField` (`^\d+\.?\d{0,2}`, 100×36, submit veya dışına dokunma → `_updatePrice` → `cubit.updateItemPrice(index, price)`). Liste altında özet şerit: "`N` منتج" (icon 18, bg primary α0.08). Boş durum: 120 px, `Icons.inventory_2_outlined` 40 (α0.5), "لم تتم إضافة منتجات بعد" (12 px α0.7).
   - **Dezavantaj (Doğrulandı):** uzunluk değişince `_priceControllers`/`_editingStates` tamamen temizleniyor; `Dismissible` key'i `Key('product_${productId}_$index')` → aynı ürün iki kez eklenirse tekrar eden index kombinasyonu üretir. Swipe yönü RTL'de "sağa swipe" mı "sola" mı olduğu runtime'da doğrulanmalı (**Bilinmiyor**); UI metni "sağa swipe" diyor.
5. `InvoiceSummaryWidget` (`invoice_summary_widget.dart`) — "ملخص الفاتورة" kartı; içinde bg primary α0.05 / border α0.1 / radius 8 kutu: "عدد المنتجات: `N` منتج" (icon `Icons.inventory_2_outlined` 18 primary), "المجموع الفرعي", satılabilir "الخصم (المبلغ)" satırı (`TextField` + "طبق" `MaterialButton` radius 5), "المجموع الكلي" (`fontSizeLarge` bold primary + sembol), altında "- X ل.س" kırmızı (`AppColors.error`, right-aligned).
   - `initState` → `postFrameCallback` → `_discountController/_discountAmountController` = `cubit.discountAmount`; `onSubmitted` veya "طبق" → `cubit.setDiscountAmount(double.tryParse ?? 0)` ve `formatNumber` ile alana yazılır. Build sırasında `state` değişince controller'lar overwrite ediliyor (`:57-63`) → kullanıcı yazarken formatta değer dönerse metin bozulabilir (**Çıkarım**).
   - Not: `remainingAmount = grandTotal - cubit.paidAmount` hesaplanıyor ama ekranda gösterilmiyor (`:52`).
6. `InvoiceActionsWidget` (`invoice_actions_widget.dart`) — ödeme durumu dropdown'ı (`cash` = "مدفوعة نقدا", `debt` = "مديون"; 48 px, radius 8, prefix `Icons.money` 18) + iki buton: "حفظ" (`ElevatedButton.icon`, 48 px, primary, loading'de spinner + "جاري...") ve "حذف" (error kırmızısı).
   - Kaydetme: `cubit.canSaveInvoice` false → snackbar "يرجى إكمال جميع الحقول المطلوبة" (hata); true → `await cubit.saveInvoice()` → "تم حفظ الفاتورة بنجاح".
   - **Bug (Doğrulandı):** `cubit.saveInvoice()` içinde `emit(InvoiceError(...))` kullanılıp exception fırlatmıyor; dolayısıyla `catch (e)` dalı hiç çalışmıyor ve hata durumunda bile "تم حفظ الفاتورة بنجاح" gösteriliyor (`invoice_actions_widget.dart:41-59`).
   - **Yarım kalmış özellik (Doğrulandı):** `_deleteInvoice` yalnızca onay dialogu ("تأكيد الحذف" / "هل أنت متأكد من حذف هذه الفاتورة؟" / `إلغاء`-`تأكيد`) ve snackbar "تم حذف الفاتورة" gösteriyor; repository çağrısı yok → fatura silinmiyor (`invoice_actions_widget.dart:66-76`). PDF butonu tamamen yorum satırında.
   - Kod kokusu: `AppColors.primary.withOpacity(0.7)` (deprecated API) `invoice_actions_widget.dart:210`.

#### SCR-009 `InvoiceDetailPage`
Yüklenme: `initState` → tipine göre `getSalesInvoiceById`/`getPurchaseInvoiceById`; header `InvoiceDetailHeaderWidget(invoiceNumber, onBackPressed)` ("تفاصيل الفاتورة" 24 px bold + "رقم الفاتورة: X"), `InvoiceInfoCardWidget` (müşteri/tedarikçi adı + tarih + ürün tablosu: `اسم المنتج/الكمية/السعر/الإجمالي` flex 2/1/1/1, satır ayıracı `divider`), `InvoiceTotalsWidget` (`المجموع الفرعي`, `الخصم` (eksi işaretli, `AppColors.error`), ayraç, `المجموع الإجمالي` 18 px bold primary), `InvoiceActionButtonsWidget`.
- **Bug (Doğrulandı):** `InvoiceActionButtonsWidget._buildActionButton` arka planı her zaman `AppColors.primary`; `color` parametresi yalnız border'da kullanılıyor → "حذف الفاتورة" butonu kırmızı görünmüyor, ve `onUpdateInvoiceStatus` callback'i Required olup hiçbir butona bağlanmamış (`invoice_action_buttons_widget.dart:82-100`). `InvoiceStatusDialog` bu yüzden detay sayfasındaki ayrı bir çağrıdan açılıyor (`invoice_detail_page.dart:16-17`).
- Ödeme/durum güncellemeleri optimistic: `updatePaymentStatus`/`updateInvoiceStatus` sonucu `InvoiceCubit` üzerinden; hata/uygunsuzlukta Arapça snackbar metinleri (`invoice_detail_page.dart:150-260`). Silme: `DeleteInvoiceDialog` → `cubit.deleteInvoice(...)` gerçekten çağrılıyor.
- PDF: `PdfInvoiceService().generateInvoicePdf(invoice, type)` → `Printing.sharePdf(bytes: ...)` (`invoice_detail_page.dart:455-470`).

#### SCR-011 `EditInvoicePage`
- Providers: `EditInvoiceCubit`, `ProductCubit`, `CustomerCubit`, `SupplierCubit` — burada `getProducts()/getCustomers()/getSuppliers()` `..` cascade ile çağrılıyor (`edit_invoice_page.dart:42-49`); create sayfasında çağrılmıyor (stream ile doluyor).
- `initState` → `loadSalesInvoice(id)` / `loadPurchaseInvoice(id)`; `EditInvoiceLoading` → AppBar "تعديل الفاتورة" + spinner; `EditInvoiceLoaded` → başlık "تعديل فاتورة البيع"/"تعديل فاتورة الشراء", body 5 blok (`EditInvoiceDatesWidget`, `EditCustomerSupplierWidget(isSales)`, `EditProductAddWidget`, `EditInvoiceSummaryWidget`, `EditInvoiceActionsWidget`), aralar 16, son 100 px; diğer state'ler → "جاري تحميل الفاتورة..." (`edit_invoice_page.dart:107-172`).
- `EditInvoiceUpdated` → yeşil snackbar + `pop(true)`; `EditInvoiceError` → kırmızı snackbar (`:88-104`).
- **Çelişki (Doğrulandı):** `edit_invoice_type_widget.dart` import edilmiş ama layout'ta yok → **fatura tipi düzenlenemiyor**; `EditInvoiceActionsWidget` "إلغاء" butonu `Navigator.pop(context)` yapıyor, onay sormuyor (`edit_invoice_actions_widget.dart:117-139`).
- **Dublör snackbar (Doğrulandı):** kayıt başarılı olunca hem `EditInvoiceActionsWidget._saveInvoice` ("تم تحديث الفاتورة بنجاح") hem sayfa listener'ı (`state.message` = aynı metin) snackbar gösteriyor; ikincisinden sonra `pop(true)` çalışıyor.
- `EditInvoiceDatesWidget`: sabit `SizedBox(height: 140)` içinde başlık + yan yana iki tarih alanı → içerik yüksekliği 140'ı aşıyor olabilir (**Çıkarım/runtime doğrulanmalı**, `edit_invoice_dates_widget.dart:94-135`).
- `EditCustomerSupplierWidget`: arama alanı + `maxHeight 200` sonuç listesi (`ListTile` title=ad, subtitle=telefon veya '-') + seçili kart (CircleAvatar primary α0.1, `Icons.close` ile temizleme). Satışta `CustomerCubit`, alışta `SupplierCubit` state'inden filtreler (ad/kod/telefon, ilk 10) (`:63-97`).
- `EditProductAddWidget` (822 satır): mobil (`width < 600`) / masaüstü form ayrımı var (`:160-226`). Masaüstü formu 3 sütun: `flex 7` ad + autocomplete (`maxHeight 180`, subtitle `kod - satış fiyatı (birim)`), `flex 2` miktar, `flex 2` "إضافة" butonu (`Row` + `Icons.add`). Ürün listesi inline düzenlenebilir: miktar rozeti tap → `AlertDialog('تعديل الكمية')`; fiyat `TextField` (`onChanged` → `cubit.updateItem(index, …)` anında); toplam satırı salt okunur; silme ikonu `Icons.delete_outline` 20 error.
  - `_showEditPriceDialog` tanımlı ama hiç çağrılmıyor (ölü metot) (`:765-822`).
  - **Bug (Doğrulandı):** `_confirmAddProduct` içinde `unit: existingProduct!.unit` (`:145`) → eşleşmeyen ad için force-unwrap çökmesi; fiyat `existingProduct?.salePrice ?? 0` olarak null-güvenli yazılmış ama `unit` yazılmamış.
  - Null-safe placeholder olarak ürün adı/birim/ölçü birimine `'null_data'` yazılıyor (`:665-672, 740-747, 799-806`) → veritabanına `"null_data"` metini gidebilir.
- `EditInvoiceSummaryWidget`: `_isInitialized` bayrağı ile sadece ilk build'de discount değerini dolduruyor; "طبق" yerine `Iconsax.add` ikonu 40×40 buton; `- X <sembol>` kırmızı sağda (`:129-203`).
- `EditInvoiceCubit.saveInvoice()` (cubit:263-360): `canSave` = (satışsa müşteri / alışsa tedarikçi) && items non-empty && invoiceDate non-null; yeni `items` listesi `id: ''` ile gönderiliyor; datasource tarafında **tüm eski kalemler silinip yeniden insert ediliyor** (`edit_invoice_datasource.dart:106-125, 162-180`) → `sales_invoice_items.id` her kayıtta değişir.
- Düzenleme akışında müşteri/tedarikçi **bakiye RPC'si çağrılmıyor** (`updateCustomerBalance`/`updateSupplierBalance` repository'de tanımlı, cubit kullanmıyor) → borç alanları güncellenmiyor. **Doğrulandı.**

### 5.8 Bottom sheet, dialog ve popup envanteri (bu ana kadar doğrulananlar)

| ID | Tetikleyici | Bileşen | İçerik / butonlar | Dosya |
|---|---|---|---|---|
| DLG-01 | AppBar tarih çipi (dashboard ve faturalar) | `DateFilterSheet.show` bottom sheet | başlık "تصفية البيانات", yıl çipleri, "أو" ayraç, "من"/"إلى" alanları, "إلغاء التصفية" | `lib/core/widgets/date_filter_sheet.dart` |
| DLG-02 | Detay "الدفع" | `PaymentStatusDialog` | "تحديث حالة الدفع" / "اختر الحالة الجديدة:" / `RadioListTile` × `PaymentStatus` (مدفوعة نقدا = yeşil, مديون = kırmızı) / `إلغاء`, `تحديث` | `.../payment_status_dialog.dart` |
| DLG-03 | Detay durum | `InvoiceStatusDialog` | "تحديث حالة الفاتورة", `RadioListTile` × `InvoiceStatus` (مسودة/مكتملة yeşil, ملغاة gri), `إلغاء`, `تحديث` | `.../invoice_status_dialog.dart` |
| DLG-04 | Detay silme | `DeleteInvoiceDialog` | "حذف الفاتورة" / "هل أنت متأكد من حذف فاتورة #X؟ لا يمكن التراجع عن هذا الإجراء." / `إلغاء`, `حذف` (kırmızı) | `.../delete_invoice_dialog.dart` |
| DLG-05 | (yalnız ölü `InvoiceManagementPage`) | `CancelInvoiceDialog` | "إلغاء الفاتورة" / "هل أنت متأكد من إلغاء فاتورة #X؟" / `لا`, `نعم` (turuncu) | `.../cancel_invoice_dialog.dart` |
| DLG-06 | Ayarlar → logout | inline `AlertDialog` | "تأكيد تسجيل الخروج" + `إلغاء` / `تسجيل الخروج` (bg error) | `settings_page.dart:416-454` |
| DLG-07 | Create → silme onayı | inline `showDialog<bool>` | "تأكيد الحذف" / `إلغاء`, `تأكيد` | `invoice_actions_widget.dart:83-120` |
| DLG-08 | Edit → miktar | `AlertDialog('تعديل الكمية')` | `TextField` digits, `إلغاء`, `حفظ` | `edit_product_add_widget.dart:706-763` |
| DLG-09 | Login → şifre sıfırlama | `AlertDialog('استعادة كلمة المرور')` | açıklama "أدخل بريدك الإلكتروني لإرسال رابط استعادة كلمة المرور", `TextField`, `إلغاء`, `إرسال` (boşsa hiçbir şey yapmaz) | `login_form.dart:194-242` |
| DLG-10 | Ortak yardımcılar | `AppDialog.showConfirmation/Info/Success/Error/Loading` | Arapça varsayılan metinler | `lib/core/widgets/app_dialog.dart` |

### 5.10 SCR-011 `CustomersPage` — müşteri listesi (`/customers`)

**Dosya / sınıf:** `lib/features/customers/presentation/pages/customers_page.dart` → `CustomersPage` (StatefulWidget, satır 10-197)
**Amaç:** Kullanıcının müşteri kayıtlarını listelemesi, araması, eklemesi/düzenlemesi/silmesi.
**Kimlik:** `AppRoutes.customers = '/customers'`; `main.dart` içindeki `_generateRoute` switch'te `AppRoutes.customers → CustomersPage()` (**Doğrulandı**). Ayrıca dashboard alt navigasyonundan gelen `isLocal` varyantı var.

**Parametreler / ön koşullar**
| Ad | Tip | Varsayılan | Etki |
|---|---|---|---|
| `isLocal` | `bool` | `false` | `true` ise FAB çizilmez (satır 106-116) ve geri butonu yine çizilir. **Doğrulandı** |

**State sahipliği:** `initState` içinde `sl<CustomerCubit()` ile GetIt'ten **singleton-factory** cubit alınıp `late CustomerCubit _customerCubit` alanına yazılır ve dış `BlocProvider(create: (_) => _customerCubit)` ile yeniden sağlanır (satır 19-27, 43-46). `CustomerCubit` yapıcı (constructor) fonksiyonu `registerFactory` ile kayıtlı (`services_locator.dart`), yani her `sl<CustomerCubit>()` çağrısı yeni instance üretir; ancak bu sayfada instance state'te tutulduğu için rebuild'da yeniden kullanılır. **Doğrulandı** (kod), **Çıkarım** (sayfa pop edilmeden tekrar açılırsa eski cubit yeniden kullanılır — cubit `close` edilmez).

**Layout (yukarıdan aşağı)** — `Scaffold(backgroundColor: AppColors.background)` → `SafeArea` → `Column`:
1. `_buildHeader(context)` — dış `Container`: `padding: EdgeInsets.all(20)`, `decoration.color = AppColors.surface (#FFFFFF)`, `border.bottom = BorderSide(AppColors.divider #E5E7EB)`. İçi: `Container(height: 40, color: Colors.grey[100] = #F3F4F6, borderRadius: 20)` içinde `Row`:
   - `IconButton(color: Colors.black, icon: Icon(Icons.navigate_before, size: 25), onPressed: Navigator.pop(context))`
   - `Expanded(child: TextField(...))` — `hintText: 'بحث عن عميل...'`, `prefixIcon: Icon(Icons.search, size: 20)`, `border: InputBorder.none`, `contentPadding: horizontal 16 / vertical 10`, `hintStyle: TextStyle(color: Colors.grey[600] = #6B7280, fontSize: 14)`.
2. `Expanded(child: Container(color: AppColors.background, child: _buildContent(state)))` — `_buildContent` state'i **ihmal eder** ve her zaman `const CustomerListWidget()` döner (satır 190-192). Loading/empty/hata görselleri `CustomerListWidget` içindedir.
3. `floatingActionButton`: `FloatingActionButton.extended(label: Text('إضافة عميل جديد', color: #FFFFFF), backgroundColor: AppColors.primary #0F1B3D)` (satır 106-116).

**Etkileşimler**
| # | Tetikleyici | Satır | Sonuç |
|---|---|---|---|
| 1 | Arama alanına yazma | 36-45 | `Timer` 500 ms debounce; dolu metin için `context.read<CustomerCubit>().searchCustomers(query.trim())`. Boş metinde **hiçbir şey çağrılmaz** — realtime stream tüm listeyi geri getirir (yorum satır 42). **Doğrulandı** |
| 2 | FAB | 110-114 | `_showAddCustomerDialog()` → `Dialog` (DLG-11) |
| 3 | `Icons.navigate_before` | 165-169 | `Navigator.pop(context)` |
| 4 | Kart düzenle ikonu | `customer_list_widget.dart:129-138` | `_showEditCustomerDialog` (DLG-12) |
| 5 | Kart sil ikonu | `customer_list_widget.dart:139-148` | `_showDeleteConfirmation` (DLG-13) |
| 6 | Sil onayı → `حذف` | `customer_list_widget.dart:307-314` | `Navigator.pop` sonra `onCustomerDeleted(customer.id)` → `deleteCustomer(id)` |
| 7 | Form `إضافة`/`تحديث` | `customer_form_widget.dart:136-141` | `_submitForm()` |
| 8 | Form `مسح` | `customer_form_widget.dart:143-150` | `_formKey.currentState?.reset()` — **controller'ları temizlemez**, yalnız form durumunu sıfırlar; pratikte metinler kalır. **Doğrulandı** |

**BlocConsumer listener (satır 51-69):** `CustomerError` → `SnackBar(content: Text(state.message))` (varsayılan arka plan); `CustomerSuccess` → yeşil `SnackBar`. **Çelişki:** `CustomerSuccess` hiçbir yerde emit edilmiyor (`customer_cubit.dart` yalnız `CustomerError`/`CustomerLoaded`/`CustomerInitial` üretiyor) → yeşil snackbar ölü dal. **Doğrulandı.**

**Durumlar (CustomerListWidget, `customer_list_widget.dart:13-61`)**
| State | Görünüm |
|---|---|
| `CustomerInitial` | `Center(child: CircularProgressIndicator())` (satır 55-57) |
| `CustomerLoading` | aynı spinner (satır 15-16) |
| `CustomerLoaded`, boş | `Icon(Icons.people, size 64, Colors.grey)` + `SizedBox(16)` + `Text('لا يوجد عملاء')` + `SizedBox(8)` + `Text('اضف عميل جديد للبدء')` |
| `CustomerLoaded`, dolu | `GridView.builder(padding: all 20, crossAxisCount: 1, childAspectRatio: 1.7, main/crossAxisSpacing: 16)` |
| `CustomerError` | `Center(child: Text(state.message))` — retry butonu yok |
| başka state | `Center(child: Text('Unknown state'))` — İngilizce, RTL metinlerle karışık |

**Müşteri kartı (`CustomerCard`, satır 65-322):** `CustomCard(padding: EdgeInsets.all(16))` → `Card(margin: EdgeInsets.all(AppConstants.spacing=8), elevation: AppConstants.cardElevation=0, shape: RoundedRectangleBorder(borderRadius: 8, side: BorderSide(AppColors.border #D1D5DB)))` + `InkWell(borderRadius: 8)` (`common_widgets.dart:137-177`).
İçerik: `CircleAvatar(radius: 24, backgroundColor: Theme.primaryColor, child: Text(name[0].toUpperCase(), white/bold/18))` (boş isimde `'C'`) → `SizedBox(16)` → `Expanded(Column: Text(name, 18, bold); telefon varsa `SizedBox(4)` + `Text(phone, 14, Colors.grey[600]))` → sağda `Row(mainAxisSize.min)`: `IconButton(Icons.edit, 20, tooltip: 'يحرر')`, `IconButton(Icons.delete, 20, tooltip: 'سيل')`.
Alt blok (yalnız `city != null || address != null`): `SizedBox(12)` + `Container(padding: 12, color: Colors.grey[50], borderRadius: 8)` içinde `Icons.location_city` 16 + şehir (14, grey[700]); her ikisi de varsa `SizedBox(4)`; `Icons.location_on` 16 + `Expanded(Text(address, 14, grey[700]))`.
Not: `tooltip` değerleri Türkçe ('يحرر'/'sil' Arapça değil — tutarsızlik). **Doğrulandı.**

**Veri akışı:** `CustomerCubit` constructor → `_startRealtimeListener()` → `customerRepository.watchCustomers()` → `CustomerRemoteDataSourceImpl.watchCustomers()` (`customer_remote_datasource.dart:47-59`): `client.from('customers').stream(primaryKey: ['id']).eq('user_id', userId).order('created_at', descending)`; `userId == null` ise `Exception('User not logged in')` fırlatılır (satır 50) → repository `handleError` ile `Left`-e çevirir → `CustomerError('User not logged in')`.
`searchCustomers` → `from('customers').select().or('name.ilike.%q%,phone.ilike.%q%,city.ilike.%q%,address.ilike.%q%').order(created_at desc)` — **`user_id` filtresi yok**: oturum sahibi olmayan müşteriler de sonuçlara girebilir. **Doğrulandı (kod); etki runtime'da RLS policy'lerine bağlı → Bilinmiyor.**
`deleteCustomer` (satır 109-129) 4 adımda siler: `sales_invoices.select('id').eq(customer_id)` → döngüyle `sales_invoice_items.delete().eq(invoice_id)` → `sales_invoices.delete().eq(customer_id)` → `payments.delete().eq(customer_id)` → `customers.delete().eq(id)`. **Çelişki:** DLG-13 metni '• فواتير البيع / • عناصر فواتير البيع / • الدفعات' der; kod da bunları siler ama satın alma faturalarına referans FK'i kontrol etmez. Silme transaction içinde değil → yarı silinmiş veri riski. **Doğrulandı (kod); gerçekleşme RLS'e bağlı → Bilinmiyor.**
`CustomerCard` düzenleme yolu `onCustomerEdit → cubit.updateCustomer(model)`; `updateCustomer` repository üzerinden `from('customers').update(toMap()).eq('id')` çağrır. **Doğrulandı.**

**Model:** `CustomerModel` (`lib/features/customers/data/models/customer.dart:3-127`) — Bölüm 9'da tam tablo.
Önemli: `toMap()` (satır 88-103) `code` alanını **yazmaz**; `id` de yazılmaz (PostgREST insert için doğru, update'te `.eq('id')` kullanılır). Formda `code` alanı hiç çizilmez (yalnız initState'te controller'a doldurulur). **Doğrulandı.**

### 5.11 SCR-012 `SuppliersPage` — tedarikçi listesi (`/suppliers`)

**Dosya / sınıf:** `lib/features/suppliers/presentation/pages/suppliers_page.dart` → `SuppliersPage` (satır 13-195). `CustomersPage` ile birebir kopya-yapı; farklar aşağıda. **Doğrulandı.**

Farklar:
- Cubit GetIt'ten değil doğrudan üretilir: `SupplierCubit(supplierRepository: sl<SupplierRepository>())` (satır 30).
- FAB etiketi `'إضافة مورد'`, `Dialog` boyutu `width: 500, height: screenH*0.5` (müşteride `screenH*0.55`, width verilmemiş) (satır 105-145).
- `_showAddSupplierDialog(context, onSubmit)` ikinci parametresi **kullanılmaz**; içeride `SupplierFormWidget(cubit: _supplierCubit, onSubmit: (supplier) => Navigator.pop(context))` (satır 132-137). Cubit dolu olduğu için `onSubmit` dalı çalışmaz; dialog kapanma işi formun kendi `Navigator.pop`'ı ile yapılır. **Doğrulandı.**
- List widget `SupplierListWidget`: `crossAxisCount: 1, childAspectRatio: 2` (müşteri 1.7), boş durum ikonu `Icons.business`, metinler `'لا يوجد موردون'` / `'اضف مورد جديد للبدء'` (`supplier_list_widget.dart:18-31`).
- Kart tooltip'leri Türkçe: `'Düzenle'`, `'Sil'` (satır 130, 135).
- Kart alt bloğu yalnız `city != null` koşuluyla çizilir, adres alanı `SupplierModel`'de yok.
- Düzenleme dialogu `AlertDialog` + `title: Text('تعديل المورد')` + `SizedBox(width: 500)` + altta tek `TextButton('إلغاء')` (satır 176-211) — müşteriden farklı olarak `Icons.close` başlık satırı yok.
- Silme onayı metni: `'هل أنت متأكد من حذف المورد X؟'`, `'سيتم حذف جميع البيانات المرتبطة بهذا المورد:'`, `'• فواتير الشراء'`, `'• عناصر فواتير الشراء'`, `'هذا الإجراء لا يمكن التراجع عنه'` (kırmızı, 12).
- Ölü import: `suppliers_page.dart:3` `invoice_details_widget.dart` import edilir ama kullanılmaz (bu widget yalnız ölü `InvoiceManagementPage` tarafından kullanılıyor). **Doğrulandı.**
- Arama: `searchSuppliers` → `.eq('user_id', userId!)` **zorunlu unwrap** + `.or('name.ilike.%q%,phone.ilike.%q%,city.ilike.%q%')` (`supplier_remote_datasource.dart:126-140`). Oturum yoksa `null!` → `TypeError` → `exceptionToFailure` → `SupplierError`. Müşterinin aksine `user_id` filtresi **var**. **Doğrulandı.**
- `deleteSupplier` (satır 105-123): `purchase_invoices` id'leri → `purchase_invoice_items` sil → `purchase_invoices` sil → `suppliers` sil. `payments` silinmez.
- `getSuppliers()` (satır 24-42) `is_active = true` filtreler; `watchSuppliers()` (45-56) **filtrelemez** → liste stream geldiği için pasif tedarikçiler görünür. **Çelişki, Doğrulandı.**

**Form (`supplier_form_widget.dart:68-122`):** 3 alan (`اسم المورد *`, `رقم الهاتف`, `المدينة`) + tam genişlik `ElevatedButton` (`إضافة` / `تحديث`). Buton `onPressed` içinde **iki kez** validate eder: hem `_formKey.currentState!.validate()` hem `_submit()` içinde tekrar validate → hata metni iki kez tetiklenir (zararsız ama gereksiz), sonra **koşulsuz** `Navigator.pop(context)` çağrılır; `cubit != null` dalında kaydetme henüz tamamlanmamış iken dialog hemen kapanır. **Doğrulandı.**
`_submit()` içinde `userId!` zorunlu unwrap (satır 48) → oturum yoksa crash.

### 5.12 DLG-11 … DLG-15 (müşteri/tedarikçi dialogları)

| ID | Tetikleyici | Bileşen | Geometri | İçerik / butonlar |
|---|---|---|---|---|
| DLG-11 | Customers FAB | `showDialog` + `Dialog` | `SizedBox(height: screenH*0.55)`, `Padding(all:16)`, `SingleChildScrollView` | başlık satırı: `Text('إضافة عميل جديد', 20, bold)` + `IconButton(Icons.close)`; `SizedBox(16)`; `CustomerFormWidget(cubit: _customerCubit, onTap: (_) {})` (boş callback) |
| DLG-12 | Kart `Icons.edit` | `Dialog` | `width: 500`, `height: screenH*0.45`, `Padding(all:16)` | `Text('تعديل العميل', 20, bold)` + `Icons.close`; `CustomerFormWidget(customerModel: customer, onTap: onCustomerEdit)` — `cubit` null olduğu için `onTap` dalı çalışır |
| DLG-13 | Kart `Icons.delete` | `AlertDialog` | varsayılan | `Icon(Icons.warning_outlined, Colors.orange[600])` + `SizedBox(8)` + `Text('تأكيد الحذف')`; gövde scrollable; `إلغاء` (TextButton) / `حذف` (ElevatedButton, `backgroundColor: Colors.red`) |
| DLG-14 | Suppliers FAB | `Dialog` | `width: 500`, `height: screenH*0.5` | `Text('إضافة مورد جديد', 20, bold)` + `Icons.close`; `SupplierFormWidget(cubit: _supplierCubit, onSubmit: pop)` |
| DLG-15 | Kart `Icons.edit` (supplier) | `AlertDialog` | içeride `SizedBox(width:500)` | `title: Text('تعديل المورد')`; `SupplierFormWidget(supplier:, onSubmit: update+pop)`; altta `TextButton('إلغاء')` |

**Dosya / sınıf:** `lib/features/customer_debts/presentation/pages/customer_debts_page.dart` → `CustomerDebtsPage` (StatelessWidget, satır 12-196)
**Erişim:** (a) `main.dart:102` → `MaterialPageRoute(builder: (_) => const CustomerDebtsPage())` (`AppRoutes.customerDebts`, `isLocal=false`); (b) dashboard sekme 2 `د.عملاء` → `const CustomerDebtsPage(isLocal: false)` (`dashboard_page.dart:167`); (c) offline sekme 2 `ديون` → `isLocal: true` (`dashboard_page.dart:182`). **Doğrulandı.**
**Parametre:** `isLocal` (varsayılan `false`) → `DebtCardWidget.showPaymentButton = !isLocal` (satır 115) ve `CustomerDetailPage(isLocal:)` aktarımı (satır 164).

**Cubit:** `BlocProvider(create: (context) => sl<CustomerDebtCubit>()..getCustomerDebts())` (satır 20) — `registerFactory` olduğu için her açılışta yeni cubit; `getCustomerDebts()` cascade ile tetiklenir. `CustomerDebtCubit` constructor'ı ayrıca `_startRealtimeListener()` başlatır (`customer_debt_cubit.dart:18-20`).

**Layout (yukarıdan aşağı)** — `Scaffold(body: BlocConsumer)`, **AppBar / başlık / geri butonu YOKTUR**:
| State | Görünüm |
|---|---|
| `CustomerDebtLoading` | `Center(CircularProgressIndicator())` |
| `CustomerDebtError` | `Center(Column)`: `Icon(Icons.error_outline, 64, textSecondary)` → `SizedBox(16)` → `Text('خطأ', 20, w600, text)` → `SizedBox(8)` → `Text(state.message, 14, textSecondary, center)` → `SizedBox(16)` → `ElevatedButton(bg primary, child: Text('إعادة المحاولة', color background))` → `getCustomerDebts()` |
| `CustomerDebtLoaded` | `SingleChildScrollView(padding: all 24)` → `Column`: `DebtStatsWidget(...)` → `SizedBox(24)` → kartlar veya `_buildEmptyState()` → `SizedBox(height: 100)` |
| `CustomerDebtInitial` / `PaymentProcessing` / `PaymentSuccess` | `const SizedBox.shrink()` (satır 127) — **liste tamamen kaybolur** |

**Çelişki / sınırlı durum (Doğrulandı):** `addPayment` → `PaymentProcessing` emit eder; builder bu durumu ele almadığı için ekran ödeme boyunca **boş beyaz** olur. `PaymentSuccess` listener'ı `getCustomerDebts()` çağırır → `CustomerDebtLoading` → spinner; ardından `CustomerDebtLoaded`. Hata durumu hem snackbar hem builder'da çizilir (satır 24-28 + 39-82) → hata iki kez görünür.

**Boş durum (`_buildEmptyState`, satır 134-158):** `Icon(Icons.inventory_2, 64, AppColors.secondary)` → `SizedBox(16)` → `Text('لا توجد ديون مستحقة', 20, w600)` → `SizedBox(8)` → `Text('تم سداد جميع الفواتير', 14, textSecondary)`. Depo ikonu kullanımı kopyala-yapıştır izlenimi veriyor (**Doğrulandı**, amaçsal tutarsızlık).

**Etkileşimler**
| # | Tetikleyici | Sonuç |
|---|---|---|
| 1 | Kart gövdesi (`InkWell`) | `Navigator.push(MaterialPageRoute(CustomerDetailPage(customer: debt, isLocal:)))` — named route değil, parametre nesne olarak geçer (satır 160-167) |
| 2 | `تسجيل دفعة` butonu | `showDialog(PaymentDialogWidget(debt:, onPaymentSubmit: (amount, note, paymentDate) async { await cubit.addPayment(debt.id, amount, note, paymentDate); _showSuccessMessage('تم تسجيل الدفعة بنجاح'); }))` (satır 169-185). Dialog kendi içinde de `Navigator.pop` eder; sayfa ayrıca yeşil floating snackbar basar (satır 187-195, `AppColors.success`) |

**DebtStatsWidget** (`debt_stats_widget.dart:39-144`): `Container(padding: isSmallScreen(width<600)?16:24, color surface, border AppColors.border, radius 12)` →
1. Özet kutusu: `padding 16`, `color: AppColors.primary.withOpacity(0.1)`, `radius 8`, `Row(spaceBetween)`: sol sütun `Text('إجمالي الديون', 12, w500, textSecondary)` + `SizedBox(4)` + `Text(NumberFormatter.formatCurrency(totalDebt), 18, bold, text)`; sağda `Container(padding 5, color: AppColors.accent(=primary).withValues(alpha:0.3), radius 8)` içinde `Row(spacing 5)`: `Icon(Iconsax.user, 15)` + `Text(debtorCount.toString())`.
2. `SizedBox(16)` + `Row(spacing 10)` → iki `_buildMobileStatItem`: `'مجموع الفواتير'` ve `'المبلغ المدفوع'`. **`icon` parametresi (Icons.receipt_long_outlined / Icons.payment_outlined) gövdede kullanılmaz** → ölü param. Kutu: `padding 12`, `color surface`, `border`, `radius 8`; başlık 12/w500/textSecondary ellipsis, değer 14/w600 ellipsis.
3. `SizedBox(16)` + `DebtSearchWidget(onSearchChanged:)` — 500 ms debounce ile `searchCustomerDebts(query)` (satır 128-140).

**DebtSearchWidget** (`debt_search_widget.dart`): `TextField(hintText: 'البحث بالاسم أو رقم الهاتف...', prefixIcon: Icons.search_outlined 20)` + `OutlineInputBorder` radius 8 (`border`/`enabledBorder`: AppColors.border, `focusedBorder`: primary), `contentPadding: 16/12`; `Icons.clear` IconButton (bg `AppColors.background`) **yalnız `_searchController.text.isNotEmpty` ise** çizilir — `onChanged` `setState` çağırmadığı için buton ilk yazımda belirmeyebilir. **Doğrulandı (kod); görsel sonuç runtime'a bağlı → Çıkarım.**

**Arama mantığı:** `CustomerDebtCubit.searchCustomerDebts` **yerel** filtre uygular (`_allDebts` üzerinde `name.toLowerCase().contains(q)` veya `phone.contains(q)`) → network gitmez. Repository'nin `searchCustomerDebts` (remote, `view_customer_debt_details` + `.ilike('customer_name', '%q%')`, **`user_id` filtresi yok**) ve `getCustomerDebt` yolları UI'dan hiç çağrılmaz → **ölü kod**; çağrılsa çok kiracılı veri sızıntısı riski taşırdı. **Doğrulandı (grep).**

**DebtCardWidget** (`debt_card_widget.dart`): `Card(margin: EdgeInsets.only(bottom: 10), elevation: 0, shape: RoundedRectangleBorder(radius 12, side: AppColors.border α0.5))` + `InkWell(radius 12)` + `Padding(all 16)` → `Column`:
- `Row`: `Expanded(Column: Text(name, 16, w600, text); telefon varsa `SizedBox(4)` + `Text(phone, 12, textSecondary))` + rozet `Container(padding: h12/v6, radius 8, color: hasDebt ? warning α0.1 : success α0.1)` içinde `Text(hasDebt ? '${NumberFormatter.format(remaining)} ${currencySymbol}' : 'مدفوع', 12, w600, warning/success)`.
- `SizedBox(12)` + `Row(spaceBetween)` üç `_buildStatItem`: `'إجمالي الفواتير'`, `'المدفوع'`, `'الديون'` (etiket 12/textSecondary, değer 14/w600, arada `SizedBox(2)`).
- `hasDebt && showPaymentButton` ise `SizedBox(12)` + `SizedBox(width: double.infinity, height: 40)` + `ElevatedButton(bg primary, padding zero, radius 8, child: Text('تسجيل دفعة', color background))`.
- `isEnd` ve `index` parametreleri **gövdede hiç kullanılmaz** → ölü. **Doğrulandı.**

**Veri:** `getCustomerDebts()` → online: `from('view_customer_debt_details').select('*').eq('user_id', userId)` → `CustomerDebtModel.fromViewMap` (`customer_id`, `customer_name`, `total_debt`, `total_paid`; `phone = null`) → `localDataSource.cacheCustomerDebts` (Drift tablosu `customer_debts_cache`). Offline: cache doluysa `Right(cached)`, boşsa `NetworkFailure.noConnection()`; userId null → `CacheFailure.notFound()`.
**Not:** `fromViewMap` `totalInvoices`'ı `total_debt`'ten okur; `remainingDebt = totalInvoices - totalPaid` (customer_debt_model.dart:26, 81-89). **Doğrulandı.**
Totals: `from('view_dashboard_customer_debts').select('*').eq('user_id', userId).single()` → `remaining_balance_all`→`totalDebtAll`, `total_paid_all`→`totalPaidAll`, `total_debt_all`→`totalInvoicesAll` (totals model:16-23). **Etiket eşleşmesi (Doğrulandı):** `'إجمالي الديون'` = kalan borç, `'مجموع الفواتير'` = toplam borç, `'المبلغ المدفوع'` = ödenen. Totals başarısızsa cubit `_filteredDebts` üzerinden toplar (cubit:89-96) → arama filtresi toplamları değiştirir.
Realtime: `watchCustomerDebts()` = `StreamController`; önce `_fetchAndEmitDebts` (view sorgusu), sonra `sales_invoices` ve `payments` stream'lerindeki **her olayda** view'u yeniden çeker (remote ds:193-257). `payments` stream'i kullanıcı ayrımı yapmaz (customer/supplier karışık tetiklenir). Repository sarmalayıcıda `handleError((_) => null)` → akış hataları yutulur (**Çıkarım**: stream kapanmaz, UI son veride kalır).
`addPayment` online: `payments.insert({user_id, customer_id, payment_type:'customer', amount, payment_date, notes})` + `syncPendingPayments()`; **`update_customer_balance` RPC'si eklemede çağrılmaz**, silmede çağrılır (`deletePayment` → `payments.delete().eq('id').eq('user_id')` + `rpc('update_customer_balance', {p_customer_id, p_amount})`). **Asimetri, Doğrulandı.**
Offline `addPayment`: `pending_payments` kuyruğuna `{id:'pending_<ms>', …}`, `updateDebtAfterPayment` ile cache `totalPaid` artırılır, `addPaymentToLocalCache` ile `customer_payments_cache`'e `{…, payment_method:'نقداً', payment_type:'customer'}` eklenir → **Right(null)** (başarı gibi). Bağlantı geri gelince repository constructor'ındaki `networkInfo.connectionStream` → `syncPendingPayments()`; bir kayıt başarısız olursa `break` (repo impl:159-189).

### 5.14 SCR-014 `CustomerDetailPage` — müşteri borç detayı

**Dosya / sınıf:** `.../customer_debts/presentation/pages/customer_detail_page.dart` → `CustomerDetailPage(customer, isLocal)` (StatefulWidget, satır 21-645)
**Erişim:** yalnız `Navigator.push(MaterialPageRoute(...))` ile `CustomerDebtsPage`'den. **Named route yok.**
**State sahipliği:** cubit **kullanılmaz**; sayfa `sl<CustomerDebtRepository>()` + `Supabase.instance.client` ile doğrudan çalışır (satır 36-37) ve `setState` döngüsüne sahiptir. `SingleTickerProviderStateMixin`, `TabController(length: 2)`.

**Veri yükleme:** `_isLoading == true` iken ayrı Scaffold: `AppBar(bg background, elevation 0, leading: Icon(Icons.arrow_back) → pop, title: Text(customer.name, fontSize 18))` + `Center(Column: CircularProgressIndicator, SizedBox(16), Text('جاري تحميل البيانات...')))`.
`_loadInvoices` → `repository.getCustomerInvoices(id)` → `sales_invoices.select('*').eq(user_id).eq(customer_id).order(invoice_date desc)`; `_loadPayments` → `payments.select('*').eq(user_id).eq(customer_id).order(payment_date desc)`. Offline cache boşsa `Right([])` (hata değil, boş liste).
Realtime: `sales_invoices` stream → `asyncMap` ile `user_id == userId && customer_id == customerId` süzgeci; `payments` stream → ayrıca `payment_type == 'customer'`; merge: `_payments = [...keptLocals, ...payments]`, `keptLocals = id.startsWith('pending_') && !streamIds.contains(id)` (satır 226-241).
**Çelişki (Doğrulandı):** optimistic ekleme `'temp_<ms>'` id üretir (satır 303) ama merge `'pending_'` önekini korur (satır 232) → optimistic satır ilk stream olayında kaybolur; `isPending: true` bayrağı hiçbir widget'ta okunmaz (ölü alan).

**Hesaplanan değerler (satır 67-114):** `_invoiceModels = _invoices.where(payment_status == 'debt')`; `_totalInvoices = Σ totalAmount`; `_totalPaid = Σ payment.amount` (**tüm** ödemeler; fatura bazlı eşleme yok); `_remainingDebt = _totalInvoices - _totalPaid`; `UnpaidInvoicesWidget` ikinci filtre uygular (`remainingAmount > 0`) → sekme sayacı ile liste içeriği uyuşmayabilir. **Doğrulandı.**
`_initialDisplayCount = 5`; `_showAllInvoices/_showAllPayments` toggle'ları; "show more": `TextButton.icon(icon: expand_less/expand_more primary, label: isShowingAll ? 'إظهار أقل' : 'عرض $remainingCount $itemType أخرى', bg primary α0.1, radius 8, padding 16/8)`; `itemType` = `'فاتورة'` / `'دفعة'`.

**Layout:** `Scaffold(bg background)` → `SafeArea` → `Column`: `Padding(all 16)` → `Column`: `CustomerDetailHeaderWidget` → `SizedBox(16)` → `CustomerSummaryCardsWidget` → `SizedBox(16)` → `Container(radius 12, surface)` içinde `TabBar` → `Expanded(Padding(all 16) → TabBarView[_buildInvoicesTab, _buildPaymentsTab])`.
- Header (`customer_detail_header_widget.dart`): `IconButton(Icons.arrow_back, 20, textSecondary, bg surface, padding 8)` → `SizedBox(12)` → `Expanded(Column: name 18/bold/text; telefon doluysa `SizedBox(4)` + `Row(Icon(phone_outlined 14) + SizedBox(6) + Text(phone, 12, textSecondary))`)` → `onPdfPressed != null` ise `IconButton(Icons.picture_as_pdf, 24, AppColors.error)`. Widget içinde `margin: bottom 16` **ve** dışarıda `SizedBox(16)` → toplam 32 px. **Doğrulandı.**
- `CustomerSummaryCardsWidget`: üst satır iki kart — `'إجمالي'` (`Icons.receipt_long_outlined`, primary) ve `'المدفوع'` (`Icons.payment_outlined`, success); kutu `padding 14`, `surface`, `border`, `radius 12`, ikon 16, başlık 12/w500/textSecondary, değer 16/bold/renk; arada `SizedBox(width: 12)`. Altta tam genişlik `Container(padding 16, radius 12, color: remainingDebt>0 ? error α0.1 : success α0.1, border α0.3)`: `'المتبقي'` (14/w600/text) + `'${AppUtils.formatNumber(remainingDebt)} $symbol'` (18/bold/error|success).
- TabBar: `labelColor primary`, `unselectedLabelColor textSecondary`, `indicator: BoxDecoration(primary α0.1, radius 12)`, `dividerColor transparent`, `labelStyle w600/14`, `unselectedLabelStyle w500/14`; sekmeler `'الفواتير (${_invoiceModels.length})'`, `'المدفوعات (${_paymentModels.length})'`.

**UnpaidInvoicesWidget (müşteri)** (`unpaid_invoices_widget.dart`): kutu `surface/border/radius 12`; başlık `Padding(16)`+`border.bottom` → `Icon(access_time_outlined, 16, primary)` + `SizedBox(8)` + `Text('فواتير الديون', 14, w600)` + `Spacer` + sayaç rozeti (`padding 8/4`, `radius 12`, `primary α0.1`, metin 12/w500/primary, değer `unpaidInvoices.length`).
Boş içerik: `Container(padding 32, color success α0.1, radius 8)` + `Row(min)`: `Icon(check_circle_outline, 20, success)` + `SizedBox(8)` + `Text('لا توجد فواتير ديون', 14, w500, success)`.
Dolu: `ListView.builder(shrinkWrap: true, physics: NeverScrollableScrollPhysics(), padding 16)`.
Satır: `Container(margin bottom 12, padding 14, bg background, radius 8, border α0.5)` → `Row`: `36×36` rozet (`bg primary`, `radius 8`) içinde `invoiceNumber.substring(len-3)` (**3 karakterden kısa numarada `RangeError`**) → `SizedBox(12)` → `Expanded(Column: invoiceNumber 14/w600; invoiceDate 12/textSecondary)` → sağ sütun `Column(end)`: `'${AppUtils.formatNumber(remainingAmount)} $symbol'` (14/bold) + `SizedBox(4)` + `TextButton.icon(Icons.visibility_outlined 14, 'عرض' 12, fg primary, padding 8/4, minimumSize Size.zero, tapTargetSize shrinkWrap)` → `Navigator.push(InvoiceDetailPage(invoiceId: invoice.id, type: 'sale'))`.
**`onQuickPay` widget gövdesinde hiç kullanılmaz** → detay sayfasının geçirdiği `isLocal ? (_) {} : (id) => _showPaymentModal()` callback'i ölü; "hızlı ödeme" UI'da yok. **Doğrulandı.**

**PaymentHistoryWidget (müşteri)** (`payment_history_widget.dart`): dış kutu `surface/border/radius 12`; başlık `Padding(16)`+`border.bottom`: `Icon(history_outlined, 16, primary)` + `SizedBox(8)` + `'سجل المدفوعات'` (14/w600) + `Spacer` + `onAddPayment != null` ise `ElevatedButton.icon(Icons.add 14, 'إضافة' 12/w600, bg primary α0.1, fg primary, elevation 0, padding 12/6, radius 6, border primary α0.2)`.
Boş: `Icon(inbox_outlined, 32, textSecondary α0.4)` + `SizedBox(8)` + `'لا توجد مدفوعات'` (14/textSecondary).
Satır (`GestureDetector` → detay dialogu): `padding 14`, `radius 8`, `bg background`, `border α0.5`; `36×36` kutu (`primary α0.1`, `radius 8`) içinde `Icons.arrow_downward_outlined` 20 primary; `SizedBox(12)`; `Expanded(Column: `'${AppUtils.formatNumber(amount)} $symbol'` 14/bold; `'${paymentDate} · ${paymentMethod}'` 12/textSecondary)`; `IconButton(delete_outline 20 error, bg error α0.1, padding 6)` → silme onayı.
Detay dialogu (DLG-18): `AlertDialog(title 'تفاصيل الدفعة', sağ hizalı bold)` + `'المبلغ'`, `'التاريخ'`, `'طريقة الدفع'`, (ops.) `'الملاحظة'` + `TextButton('إغلاق')`.
Silme onayı (DLG-17): `AlertDialog(title 'تأكيد الحذف' bold)` + `'هل أنت متأكد من حذف هذه الدفعة بمبلغ <formatCurrency>؟'` + `Row(mainAxisAlignment.start)`: `إلغاء` / `حذف` (bg error, beyaz). **Buton hizası diğer onay dialoglarından farklı (`start` vs `end`).** **Doğrulandı.**
Silme akışı: `Navigator.pop` → `_deletePayment(id)` → optimistic kaldırma → `repository.deletePayment(id, customerId, amount)`; hata → aynı index'e geri ekle (`_restorePayment`) + kırmızı snackbar `'فشل في حذف المدفوعة: <msg>'`; başarı → yeşil `'تم حذف المدفوعة بنجاح'`.

**Ödeme ekleme (`PaymentModalWidget` = DLG-19):** `showDialog(Dialog(shape radius 12, Container(width 400, padding 24, SingleChildScrollView)))`:
başlık `'الدفع الجديد'` (20/w600) + `IconButton(Icons.close, textSecondary, bg background)`; `SizedBox(24)`; bilgi kutusu (`padding 16`, `bg background`, `radius 8`): `'الديون المتبقية: '` (14/textSecondary) + `formatCurrency(remainingDebt)` (14/bold, `remainingDebt>0 ? error : success`).
Form: `كمية *` (hint `0.00`, `keyboardType.number`, `Icons.attach_money` primary, border/enabled AppColors.border radius 8, focused primary) validator sırası: boş → `'الرجاء إدخال المبلغ'`; parse edilemez/≤0 → `'الرجاء إدخال مبلغ صالح'`; `> remainingDebt` → `'لا يمكن أن يتجاوز المبلغ الدين المتبقي'`. `ملاحظة (اختياري)` (hint `'إضافة ملاحظة...'`, `Icons.note_outlined`, maxLines 2). `تاريخ الدفع` → `InkWell` + `InputDecorator` + `Icons.calendar_today`, metin `d/M/yyyy` (önsüz); `showDatePicker(firstDate: DateTime(2020), lastDate: now+30 gün)`.
Butonlar: `OutlinedButton('يلغي')` (dilbilgisel olarak hatalı metin; DLG-16 `'إلغاء'` kullanıyor) + `ElevatedButton('حفظ', bg primary, padding v12, radius 8)`. `حفظ` → validate → `onPaymentSubmit(amount, 'yyyy-MM-dd', note|null)` → sayfa `Navigator.pop` + `_addPayment(...)`.
`_addPayment` ön kontrolleri: `amount <= 0` → `'المبلغ يجب أن يكون أكبر من صفر'`; `amount > _remainingDebt` → `'المبلغ أكبر من الديون المتبقية'`; sonra optimistic satır (`payment_method: 'نقداً'`, `user_id: ''`, `isPending: true`) + `'جاري معالجة المدفوعة...'` (yeşil, 2 sn) → `repository.addPayment`; hata → rollback + kırmızı (4 sn) `'فشل في إضافة المدفوعة: …'`; başarı → `isPending` kaldırılır + `'تم تسجيل المدفوعة بنجاح: <amount 2 ondalık>'`.
**PDF:** `Icons.picture_as_pdf` → `_generateDebtPdf()`; `_isGeneratingPdf` iken buton `null`; fatura+ödeme boşsa erken `return`; `profiles.select('business_name').eq('id', userId).maybeSingle()`; `PdfInvoiceService().generateDebtPdf(companyName:, partyName: customer.name, dateRangeLabel: '', invoices: _invoices (filtresiz ham satırlar), payments: _payments, isSupplier: false)`; `Printing.sharePdf(bytes, filename: 'debt_<customerId>.pdf')`; hata → `'فشل إنشاء PDF: <e>'`.

### 5.15 SCR-015 / SCR-016 `SuppliersDebtsPage` + `SupplierDetailPage`

`customer_debts` modülünün neredeyse birebir kopyasıdır; `diff` ile doğrulanan **farklar**:

| Konu | Müşteri | Tedarikçi |
|---|---|---|
| Sayfa erişimi | route + dashboard sekme 2 (online/offline) | **yalnız dashboard sekme 3 `د.موردين`** (`dashboard_page.dart:169`); named route yok; offline modda sekme yok → çevrimdışı erişilemez |
| Scaffold | `backgroundColor` verilmez | `backgroundColor: AppColors.background` |
| State sınıfları | `part 'customer_debt_state.dart'` | cubit dosyası içinde tanımlı (`supplier_debt_cubit.dart`) |
| Stream hatası | yalnız `log` | `emit(SupplierDebtError(...))` + `onError` → `SupplierDebtError('Stream error: …')` |
| `addPayment` sonrası | stream'e bırakır | `emit(SupplierPaymentSuccess)` **+ `await getSupplierDebts()`** |
| Arama UI | `DebtSearchWidget` stats içinde | **yok** → `searchSupplierDebts` ölü; `DebtStatsWidget._debounceTimer` kullanılmıyor |
| Remote arama | `.ilike('customer_name')`, **`user_id` yok** | `.eq('user_id', userId).ilike('supplier_name')` |
| View'lar | `view_customer_debt_details`, `view_dashboard_customer_debts` | `view_supplier_debt_details`, `view_dashboard_supplier_debts` |
| Fatura tablosu | `sales_invoices` + `customer_id` | `purchase_invoices` + `supplier_id` |
| `payments` insert | `payment_type:'customer'`, `customer_id` | `payment_type:'supplier'`, `supplier_id` |
| RPC | `update_customer_balance(p_customer_id, p_amount)` (yalnız silme) | `update_supplier_balance(p_supplier_id, p_amount)` (yalnız silme) |
| Detay realtime | `payment_type=='customer'` + `pending_` koruma merge'i | `payment_type=='supplier'`, **merge yok** (`_payments = payments`), `onError` → kırmızı snackbar `'خطأ في تحديث المدفوعات: …'` / `'خطأ في تحديث الفواتير: …'` |
| Detay header | `CustomerDetailHeaderWidget` | `SupplierDetailHeaderWidget` (`supplier_detail_header_widget.dart`) |
| Özet kartlar | 2 kart + tam genişlik alt kart | kendi `customer_summary_cards_widget.dart`: tek satır 3 kart `'إجمالي'`/`'المدفوع'`/`'المتبقي'` (primary/success/warning) |
| Fatura widget | `InvoiceModel`, `invoiceDate` ham | `PurchaseInvoiceModel`, `invoiceDate.toString().substring(0, 10)`; durum rozetleri `'مستحق'` (warning) / `'مدفوع جزئي'` (info) / `'مدفوع'` (success); `'من <symbol> <totalAmount>'` alt satırı |
| PDF | `isSupplier: false` | `isSupplier: true`, dosya adı yine `debt_<supplierId>.pdf` |
| Boş durum | `Icons.inventory_2` + `'لا توجد ديون مستحقة'` / `'تم سداد جميع الفواتير'` | aynı metin ve ikon (kopya) |
| Kartlar / dialoglar | `DebtCardWidget` 3 stat + `'تسجيل دفعة'`; modal iptal `'يلغي'` | aynı |

**Ölü dosyalar (bu modüllerde):** `customer_debts/presentation/widgets/debt_table_header_widget.dart` ve `suppliers_debts/presentation/widgets/debt_table_header_widget.dart` — `DebtTableHeaderWidget` hiçbir yerden kullanılmıyor (height 35, `bg secondary α0.1`, `radius topLeft/topRight 10`, hücreler `'الاسم'`, `'إجمالي'`, `'المدفوع'`, `'المتبقي'`, flex 1/1/1/1, aralar `SizedBox(16)`). Ayrıca repository seviyesinde `searchCustomerDebts`, `searchSupplierDebts`, `getCustomerDebt`, `getSupplierDebt` remote yolları UI'dan çağrılmıyor. **Doğrulandı (grep).**

### 5.16 DLG-16 … DLG-20 (borç modülleri)

| ID | Tetikleyici | Bileşen | Geometri | Alanlar / butonlar |
|---|---|---|---|---|
| DLG-16 | Borç kartı `تسجيل دفعة` | `PaymentDialogWidget` | `Dialog(radius 12)` → `Container(width 400, padding 24)` | `'تسجيل دفعة'` 20/w600 + `Icons.close`; müşteri/tedarikçi adı + `'الدين المتبقي: '`; `مبلغ الدفعة` (validator: `'الرجاء إدخال المبلغ'` / `'الرجاء إدخال مبلغ صحيح'` / `'المبلغ لا يمكن أن يتجاوز الدين المتبقي'`), `ملاحظة (اختياري)`, `تاريخ الدفعة` (d/M/yyyy); `إلغاء` / `حفظ` |
| DLG-17 | Ödeme satırı `delete_outline` | `AlertDialog` | varsayılan | `'تأكيد الحذف'` + `'هل أنت متأكد من حذف هذه الدفعة بمبلغ X؟'` + `إلغاء` / `حذف` (bg error) |
| DLG-18 | Ödeme satırına dokunma | `AlertDialog` | varsayılan | `'تفاصيل الدفعة'` + `المبلغ/التاريخ/طريقة الدفع/(الملاحظة)` + `إغلاق` |
| DLG-19 | Detay → `إضافة` (ödeme geçmişi başlığı) | `PaymentModalWidget` | `Dialog(radius 12)`, `width 400`, `padding 24` | `'الدفع الجديد'` + `'الديون المتبقية: …'` + `كمية *` / `ملاحظة (اختياري)` / `تاريخ الدفع`; `يلغي` / `حفظ` |
| DLG-20 | Tarih seçimi (DLG-16/19) | Material `showDatePicker` | sistem dialogu | aralık `2020-01-01` → `now+30 gün`; iptal seçim değişikliği yapmaz |

### 5.17 SCR-014 `ProductsPage` — ürünler (`/products`)

Dosya: `lib/features/products/presentation/pages/products_page.dart` (546 satır). Route daima `const ProductsPage()` olarak kuruluyor (`main.dart:78`) → `isLocal` pratikte hep `false`.

**Kubit:** `ProductCubit` (`bloc/product_cubit.dart:22-26`) constructor'da `ProductInitial` + `_startRealtimeListeners()`. Alanlar `_allProducts` (14), `_categories` (15), `_selectedCategoryId='all'` (16). Getter'lar: `selectedCategoryId` (29), `categories` (30), `filteredProducts` (31-36) — `'all'` ise tümü, değilse `categoryId?.toString() == _selectedCategoryId`.

**Durum sınıfları** (`bloc/product_state.dart`): `ProductInitial` (10), `ProductLoading` (14), `ProductsLoaded(products)` (18), `ProductSingleLoaded(product)` (27), `CategoriesLoaded(categories)` (36), `ProductError(message)` (45), `ProductSuccess(message)` (54).

| Metot | Satır | Yayın | Not |
|---|---|---|---|
| `getProducts` | 39-51 | `ProductsLoaded` | `_allProducts` güncellenir |
| `getProduct(id)` | 53-62 | `ProductSingleLoaded` | UI'dan çağrılmıyor |
| `createProduct` | 64-77 | `ProductSuccess('Product created successfully')` + `getProducts()` | **mesaj İngilizce** → snackbar'a aynen gider |
| `updateProduct` | 79-92 | `'Product updated successfully'` | aynı |
| `deleteProduct` | 94-107 | `'Product deleted successfully'` | aynı |
| `searchProducts` | 109-118 | `ProductsLoaded(products)` | **`_allProducts` güncellenmez** → liste `filteredProducts` okuduğu için arama sonucu ekranda görünmez (Doğrulandı, hata) |
| `getCategories` | 121-133 | `CategoriesLoaded` | |
| `createCategory`/`updateCategory`/`deleteCategory` | 135-178 | `'Category … successfully'` + `getCategories()` | |
| `setCategoryFilter` | 181-185 | `ProductsLoaded(filteredProducts)` | sunucuya gitmez (yalnız lokal filtre) |
| `clearCategoryFilter` | 187-190 | — | **ölü** (çağrı yok) |
| `getProductsByCategory` | 193-195 | — | `setCategoryFilter`'e delege; repo sürümü hiç kullanılmıyor |
| `loadInitialData` | 198-203 | — | `ProductListWidget.initState` tarafından çağrılıyor |

Realtime (`206-242`): `watchProducts()` ve `watchCategories()` aboneliği; hata mesajları `'Real-time products error: ${error}'` (221) ve `'Real-time categories error: …'` (239). **`close()` hiçbir UI tarafından çağrılmıyor** (`ProductsPage.dispose` yalnız `_tabController.dispose()`, 41-44) → abonelik sızıntısı. **Ölü kod:** `_tabController` (24, 32, 43) — `build` içinde `TabBar`/`DefaultTabController` yok; `_isLoading` (26) yalnız yazılır, hiç okunmaz.

**Yükleme:** `initState` → post-frame `_loadData()` (36-38) → `Future.wait([getProducts(), getCategories()])` (54-57). `ProductListWidget.initState` ayrıca `loadInitialData()` çağırıyor (`product_list_widget.dart:19-25`) → **aynı veri iki kez çekiliyor. Doğrulandı.**

**Build üstten alta** (78-137): `BlocProvider.value(_productCubit) → SafeArea → Scaffold → Column[ _buildHeader, Expanded(Container(bg AppColors.background) → ProductListWidget) ]`.
`BlocConsumer` listener (82-108): `CategoriesLoaded` → `_categories` setState; `ProductError` → kırmızı snackbar `state.message`, 2 sn; `ProductSuccess` → yeşil snackbar, 2 sn.

**Header** `_buildHeader` (397-444): `Container(padding: all 20, color AppColors.surface, border: bottom divider)` → `Column(crossAxisAlignment: start)`:
1. `IconButton(Icons.navigate_before, size 30, Colors.black)` → `Navigator.pop` (411-415)
2. `'المنتجات'` — 20 px, bold, `AppColors.text` (416-423)
3. `Spacer()` (424)
4. `_buildIconButton(Icons.search)` → `_showSearchDialog` (426-429), `SizedBox(width 8)`
5. `_buildIconButton(Icons.category_outlined)` → `_showCategoriesDialog` (432-435)
6. `SizedBox(height 16)` + `_buildCategoryChips` (438-440)

`_buildIconButton` (446-467): `Material(transparent, radius 8) → InkWell(hoverColor primary α0.05) → Container(padding 8, border divider, radius 8) → Icon(size 20, AppColors.textSecondary)`.

**Kategori chip'leri** (469-513): veri **state'ten değil cubit getter'larından** (`cubit.categories`, `cubit.selectedCategoryId`). `ProductLoading && categories.isEmpty` → `SizedBox(height 32)` içinde 16×16 `CircularProgressIndicator(strokeWidth 2)`. Normalde `SizedBox(height 36)` + yatay `ListView`: ilk chip `'الكل'` (`selectedCategory=='all'`), sonra her kategori `Padding(right 8)`. `_buildChip` (515-545): `Material(isSelected ? primary : transparent, radius 18)`, `Container(padding h14/v8, border primary/divider, radius 18)`, `Text(12 px, w600/w500, white/textSecondary)`.

**FAB** (138-152): `widget.isLocal ? null : FloatingActionButton.extended(label 'إنشاء المنتج', tekst `AppColors.background`, bg `AppColors.primary`)` → `_showAddProductDialog(onSubmit: createProduct)`.

**Veri katmanı (özellik: önbellek YOK).** `data/` içinde `AppDatabase` importu hiç yok (grep). `ProductRepository` (`data/repositories/product_repository.dart:14-192`) her metotta `networkInfo.isConnected` kontrol eder; çevrimdışıysa doğrudan `Left(NetworkFailure.noConnection())` → `'لا يوجد اتصال بالإنترنت'` (`core/errors/failures.dart:27-29`). **Yani: ürünler offline modda boş/hatalı görünür; queue/pending mekanizması yok. Doğrulandı.**

`ProductRemoteDataSourceImpl` (`data/datasource/product_remote_datasource.dart`), `SupabaseClient` DI'dan (`services_locator.dart:104-105`):

| Metot | Satır | Sorgu |
|---|---|---|
| `getProducts` | 34-53 | `from('products').select('*, categories(name)').eq('user_id', userId).eq('is_active', true).order('created_at', desc)`; `userId` null → `Exception('User not logged in')` |
| `getProduct` | 56-68 | `select('*, categories(name)').eq('id', id).single()` — **`user_id` filtresi yok** |
| `getCategories` | 71-95 | `from('categories').select(id, user_id, name, description, parent_id, sort_order, is_active, created_at).eq('user_id').eq('is_active', true).order('sort_order', asc).order('name').limit(50)` |
| `createProduct` | 113-125 | `upsert(product.toMap(), onConflict: 'id').select('*, categories(name)').single()` |
| `updateProduct` | 128-141 | `update(toMap()).eq('id', id).select(...).single()` |
| `deleteProduct` | 144-155 | 1) `sales_invoice_items.delete().eq('product_id', id)` 2) `purchase_invoice_items.delete().eq('product_id', id)` 3) `products.update({'is_active': false})` — **hard delete + soft delete karışımı; silme onayı dialogunun metniyle örtüşüyor** |
| `createCategory`/`updateCategory` | 158-187 | `upsert(category.toMap())` / `update(toMap()).eq('id')` |
| `deleteCategory` | 190-196 | `update({'is_active': false}).eq('id', id)` (soft) |
| `searchProducts` | 199-212 | `eq('is_active', true).or('name.ilike.%q%,description.ilike.%q%,sku.ilike.%q%')` + `order created_at desc` — **`user_id` filtresi yok (kiracılar arası sızıntı riski)** ve **`sku` kolonu modelde yok, kod alanı `code`** (Doğrulandı, tutarsızlık) |
| `getProductsByCategory` | 215-228 | `eq('category_id').eq('is_active', true).order created_at desc` — ölü |
| `watchProducts` / `watchCategories` | 231-274 | **Supabase Realtime değil**: aynı select'in `.asStream()` ile tek seferlik yayılması. Yani "realtime" abonelikleri yalnızca ilk veriyi üretir; CRUD sonrası tazelik manuel `getProducts()` çağrılarıyla sağlanır. **Doğrulandı (kritik bulgu).** |

**Modeller** (`data/models/product.dart`, 186 satır): `id, userId, code` (`String`), `barcode?`, `name`, `categoryId?`, `categoryName?`, `unit`, `measurement` (`String`!), `purchasePrice/salePrice/minSalePrice` (`double`, default 0), `currentStock/minStock` (`int`, default 0), `maxStock?`, `location?`, `notes?`, `isActive` (default true), `createdAt/updatedAt`, `deletedAt?`.
- `toMap` (125-149): `int.parse(measurement)` (126) → **boş/non-numeric 'حجم' alanı `FormatException` atar**, repo bunu `exceptionToFailure` ile `ServerFailure('خطأ داخلي في الخادم')`ne çevirir (`failures.dart:278-283`). Gönderilen kolonlar `user_id, name, category_id, unit, measurement(int), purchase_price, sale_price, min_sale_price, current_stock, min_stock, max_stock, location, notes, is_active, created_at, updated_at, deleted_at` — **`id`, `code`, `barcode` gönderilmez** (127-129 log satırları). Bu yüzden `upsert(onConflict: 'id')` yeni kayıt için anlamsız; `createProduct` daima yeni satır ürettecek şekilde sunucu default `id`'ye dayanır (Çıkarım — şema repoda yok).
- `fromMap` (151-175): `id/userId/code ?? ''`, `categoryName: map['categories']['name']` (embed nesne varsayar), `unit ?? 'piece'` (**İngilizce default**, UI Arapça birim üretiyor), `measurement?.toString() ?? '0'`, `DateTime.parse` zorunlu (171-172) → null gelirse çöker.
- Getter'lar (177-185): `isLowStock`, `isOutOfStock`, `hasMaxStock`, `profitMargin`, `profitPercentage` — **hiçbirinde kullanılmıyor (grep: 0 sonuç)**; `nameWithMeasurementUnit = '$name $measurement $unit'` kartta (54) ve invoices'ta kullanılıyor. **Ürün kartında stok rozeti yok. Doğrulandı.**

`ProductCategory` (`product_category.dart`, 82 satır): `id, userId, name, description?, parentId?, sortOrder=0, isActive=true, createdAt`; `toMap` (58-68) **`id` içermez**; `copyWith` tanımlı ama kullanılmıyor (ölü).
`ProductUnitData.unitItems` (**tek kopya**: `lib/features/products/data/models/product_unit_data.dart:4-12`): `List<DropdownMenuItem<String>>` — `DropdownMenuItem(value: X, child: Text(X))` biçiminde 7 değer: `'كيلوغرام', 'غرام', 'ظرف', 'قطعه', 'لتر', 'مل', 'متر'`. Dosya **`products/` altında ve birden fazla kopyası yok** (find: tek eşleşme; daha önce bu belgede yazılan "invoices altında ikinci kopya" iddiası **yanlıştı, kalite kontrolünde düzeltildi**). Tek tüketicisi `product_form_widget.dart:6` (grep: başka import yok) → birim listesi fatura kalemlerinde serbest metin olarak kalıyor (Bölüm 8, `measurement` alanı). **Doğrulandı**

**`ProductListWidget`** (`widgets/product_list_widget.dart:29-163`): `SingleChildScrollView(padding all 16) → BlocBuilder`.
- `ProductLoading` → `CircularProgressIndicator` (37-40)
- `ProductError` → `Icon(Icons.error, 64, AppColors.error)` + mesaj + `ElevatedButton('أعد المحاولة')` → `getProducts()` (46-57)
- `ProductsLoaded` → **`state.products` değil `cubit.filteredProducts`** (62). Boşsa ikon `selectedCategoryId=='all' ? Icons.inventory : Icons.filter_list` (48 px), `'لم يتم العثور على منتجات'` / `'لا توجد منتجات في هذه الفئة'` (14 px) + `'أضف منتجك الأول'` / `'حاول اختيار فئة أخرى'` (12 px); doluysa `RefreshIndicator(onRefresh: getProducts)` + `ListView.builder(shrinkWrap, NeverScrollableScrollPhysics)` (95-110)
- `CategoriesLoaded` → aynı boş durum ama ikinci satır `'جرّب اختيار فئة أخرى'` (138) — **ProductsLoaded dalındaki `'حاول…'` ile metin tutarsızlığı**; dolu liste `RefreshIndicator`sız (146-157)
- diğer state'ler → spinner (160-162). **`import 'package:http/http.dart'` (satır 6) kullanılmıyor.**

**`ProductCardWidget`** (`product_card_widget.dart`, 159 satır): `Container(margin bottom 15, surface, radius 8, border divider, boxShadow cardShadow) → InkWell(onTap) → Padding(all 20) → Column[isim, 16, fiyat satırı, 16, butonlar]`. `onTap` parametresi **liste tarafından hiç geçirilmiyor** → kart tıklaması etkisiz; long-press / Dismissible / swipe yok (Doğrulandı).
- isim: `nameWithMeasurementUnit`, 16 px w600, maxLines 2 ellipsis (52-62)
- fiyatlar: iki `Expanded _buildPriceBox`, aralarında 8 px; etiketler `'شراء'` (70) ve `'بيع'` (77); kutu `padding v10/h12, bg AppColors.background, border divider, radius 4`, etiket 12 px w500 textSecondary, değer **`price > 0 ? price.toStringAsFixed(2) : '-'`** 18 px bold (109-114). **`NumberFormatter` burada kullanılmıyor → para birimi sembolü/sHORT formatı ürün kartında yok (tutarlılık hatası; dashboard ve faturalarda var).**
- butonlar (121-159): `ElevatedButton.icon('تعديل', Icons.edit_outlined 16, bg primary, fg surface, padding v10, elevation 0, radius 4)` → `onEdit(product)`; 8 px; `ElevatedButton.icon('حذف', Icons.delete_outline 16, bg AppColors.error)` → `onDelete(product.id)`.

### 5.18 Ürün dialog ve sheet'leri (DLG-21 … DLG-25)

| ID | Tetikleyici | Bileşen / geometri | İçerik ve etkileşim |
|---|---|---|---|
| DLG-21 | Header `Icons.search` | `AlertDialog` (`products_page.dart:159-205`) | `'بحث عن منتج'`; `TextField(label 'اسم المنتج أو الكود', prefixIcon Icons.search)`; 24 px; Row(end): `'إلغاء'` → pop, 8 px, `'بحث'` → **yalnız `text.trim()` doluysa** `searchProducts` + pop. **`searchController` dispose edilmiyor** (160). Sonuç liste üzerinde etkisiz (bkz. 5.17 `searchProducts`) |
| DLG-22 | Header `Icons.category_outlined` | `Dialog → SizedBox(width 600, height 500)`, padding 16 (207-264) | Row: `'الفئات'` 20 bold + `Icons.close` → pop; 16 px; `if (!isLocal)` → `Align(centerLeft)` `ElevatedButton.icon(Icons.add, 'إضافة فئة جديدة')` → DLG-24; `Expanded(CategoryListWidget())` |
| DLG-23 | FAB / kart `تعديل` | `Dialog → Padding(all 5) → Column → Expanded(ProductFormWidget)` (266-291) | boyut kısıtı yok; `BlocProvider.value` altında değil ama `context.read<ProductCubit>()` en yakın provider'dan çözülüyor |
| DLG-24 | DLG-22 `إضافة فئة جديدة` | `Dialog → SizedBox(600×250)`, padding 16 (293-334) | `'إضافة فئة جديدة'` 20 bold + `Icons.close`; 16 px; `BlocProvider.value(_productCubit) → CategoryFormWidget()` |
| DLG-25 | Kart `حذف` | `AlertDialog` (336-395) | başlık Row: `Icons.warning_outlined` (`Colors.orange[600]`) + 8 px + `'تأكيد الحذف'`; gövde: `'هل أنت متأكد من حذف هذا المنتج؟'`, `'سيتم حذف جميع البيانات المرتبطة بهذا المنتج:'` (bold), `'• عناصر فواتير البيع'`, `'• عناصر فواتير الشراء'`, `'هذا الإجراء لا يمكن التراجع عنه'` (kırmızı 12 px); Row(end): `'إلغاء'` / `ElevatedButton('حذف', bg Colors.red[600])` → pop **sonra** `deleteProduct` (await yok) |

**`ProductFormWidget`** (`widgets/product_form_widget.dart`, 301 satır) — alan sırası ve birebir metinler:

| # | Alan | Etiket / hint | Validator / keyboard | Not |
|---|---|---|---|---|
| 1 | Başlık | `'إضافة منتج جديد'` (yeni) / `'تحديث المنتج'` (düzenleme), 20 px bold + `Icons.close` → pop | — | 127-142 |
| 2 | `_nameController` | `'اسم المنتج *'`, `Icons.inventory` | boş → `'اسم المنتج مطلوب'` | 146-154 |
| 3 | Kategori | `'الفئة'`, `Icons.category` | — | `DropdownButtonFormField<String?>`, items: `null → 'بدون فئة'` + `categoryList` (163-172) |
| 4 | Satış fiyatı | `'سعر البيع *'`, `Icons.attach_money` | boş → `'سعر البيع مطلوب'`; parse edilemez → `'سعر غير صحيح'`; `keyboardType: number` | 185-197 |
| 5 | Min satış fiyatı | `'أقل سعر بيع'`, `Icons.money_off` | **validator yok** | 207-208 |
| 6 | Alış fiyatı | `'شراء*'`, `Icons.shopping_cart` | boş → `'سعر الشراء مطلوب'`; `'سعر غير صحيح'` | 218-227 |
| 7 | `'حجم'` | label `'حجم '`, hint `'حجم '`, `Icons.straighten`, `FilteringTextInputFormatter.digitsOnly` | **validator yok** | 232-240 → `measurement` |
| 8 | `'القياس'` | label `'القياس'`, `Icons.straighten` | — | `DropdownButtonFormField<String>` (242-255) → `unit`. **Etiket/alan çaprazlığı: 'حجم' (hacim) `measurement`'a, 'القياس' (ölçü) `unit`'e bağlı; DB'de `measurement` int kolon** |
| 9 | Min stok | `'الحد الأدنى للمخزون'`, `Icons.inventory_2_outlined`, hint `'0'` | validator yok, `keyboardType: number` | 257-271 |
| 10 | Butonlar | `'إضافة'`/`'تحديث'` (ElevatedButton) ve `'مسح'` (OutlinedButton) | — | 277-291 |

- **`_codeController` (29) hiçbir TextField'a bağlı değil** — ölü; `code` submit'te `now.microsecond.toString()` ile üretiliyor (82). **`currentStock: 0` ve `maxStock: null` sabit** (91-93) → formda stok alanı yok, `current_stock` daima 0 yazılıyor. `location`/`notes`/`barcode` alanı yok.
- `_submitForm` (75-106): `validate()` → model kur → `widget.onSubmit(product)`; **`catch (e) {}` boş** (102) → hata yutulur, kullanıcı hiçbir şey görmez. `_getCategoryName` `firstWhere` kullanıyor → kategori listede yoksa `StateError`, yine boş catch'e düşer (108-114).
- Submit butonu `_submitForm(); Navigator.pop(context)` — **await yok**, kaydetme sonucu beklenmeden dialog kapanır (277-283); başarı/hata mesajı sayfadaki snackbar ile sonra görünür.
- `'مسح'` → `_formKey.currentState?.reset()` **yalnız validation'ı sıfırlar, controller metinlerini temizlemez** (286-291) → "temizle" etiketi ile gerçek davranış farklı.
- Düzenleme başlangıç değerleri (45-60): name/sale/minSale/purchase/unit/measurement/minStock/categoryId doldurulur. **Bug (satır 58): `setState` içindeki atama `if` dışında koşulsuz çalışıyor ve `_unitController.text = ProductUnitData.unitItems.first.value!` ('كيلوغرام') yapıyor → düzenlemede mevcut birim kaybolur**; dropdown `initialValue` de hep ilk eleman (243).
- `PopScope`/kaydedilmemiş değişiklik uyarısı **yok**; kapatma yalnız `Icons.close`.

**`CategoryListWidget`** (`category_list_widget.dart`, 190 satır): `BlocListener` — `ProductError` kırmızı, `ProductSuccess` yeşil snackbar (18-32). `BlocBuilder`: `ProductLoading` → spinner; `CategoriesLoaded` boş → `Icon(Icons.category, 64, Colors.grey)` + `'لا يوجد فئات'` + `'أضف فئة جديدة للبدء'` (39-51); dolu → `ListView.builder → CategoryCard` (53-59); **diğer state'ler (ör. `ProductsLoaded`) → `SizedBox.shrink()` (61) → kategori dialogu ürün CRUD sonrası boş kalabilir (state yarışması). Doğrulandı.**
- `CategoryCard` (68-115): `Card(margin h16/v8)` + `ListTile` (leading `CircleAvatar` **yorum satırında kapalı**), title `category.name` bold, subtitle `description` veya null, trailing Row(`Icons.edit` 20 → düzenleme dialogu, `Icons.delete` 20 → silme onayı), `onTap` → detay dialogu.
- Detay dialogu (117-145): başlık = kategori adı; `'الوصف: …'` (yalnız description varsa), `'تم الإنشاء: <tarih>'`, `'الحالة: نشطة/غير نشطة'`, 24 px, `TextButton('إغلاق')`.
- **Düzenleme ölü özellik (147-152):** `_showEditCategoryDialog` yalnız `SnackBar('قيد التطوير')` gösteriyor — TODO bırakılmış. `ProductCubit.updateCategory` bu yüzden UI'dan erişilemez.
- Silme onayı (154-189): `'تأكيد الحذف'`, `'هل أنت متأكد من حذف الفئة ${name}؟'`, `'إلغاء'` / `ElevatedButton('حذف', red)` → `deleteCategory(category.id)`.

**`CategoryFormWidget`** (`category_form_widget.dart`, 105 satır): yalnız **tek alan** `'اسم الفئة *'` (OutlineInputBorder, `Icons.category`), validator `'يرجى إدخال اسم الفئة'` (70-80); Row(end) içinde `OutlinedButton('إلغاء')` → pop ve `ElevatedButton('إضافة'/'حفظ')` → `_saveCategory` (86-98). `_saveCategory` (37-59): `ProductCategory(userId, id: category?.id ?? '', name, description: trim boşsa null, isActive: true, createdAt: eski ?? now)` → `createCategory`/`updateCategory` → **await'siz `Navigator.pop`** (57). **`_descriptionController` tanımlı ve kayda giriyor ama build'de description alanı yok → description hep null (ölü alan). Doğrulandı.**

### 5.19 SCR-019 `TakrirlerPage` — raporlar menüsü (`/takrirler`)

Dosya: `lib/features/reports/presentation/pages/takrirler_page.dart` (118 satır). Route: `AppRoutes.takrirler = '/takrirler'` (`core/constants/app_constants.dart:161`), kaydı `main.dart:103-104` → `const TakrirlerPage()`. Açıldığı tek yer: MorePage kartı `'التقارير'` → `Navigator.pushNamed` (`dashboard/presentation/pages/more_page.dart:54-59`).

- `Scaffold(backgroundColor: AppColors.background)` (`:13`), `AppBar(title: 'التقارير', centerTitle: true)` (`:15-16`). **Geri butonu yok** — sistem/Material varsayılan back.
- Body: `Padding(all 16)` → `GridView(physics: NeverScrollableScrollPhysics, crossAxisCount 2, mainAxisSpacing 12, crossAxisSpacing 12, childAspectRatio 1.1)` (`:18-27`). **Yükleme/boş/hata durumu ve filtre yok.**
- 3 kart (`_ReportCard`, `:69-118`): `Material(AppColors.divider, radius 16) → InkWell(radius 16) → Container(surface, border AppColors.primary, radius 16, padding 20) → Column(center): Spacer, Icon(size 40), Spacer, Text(15 px, w600, AppColors.primary, center)`.

| Sıra | İkon | Etiket | Tetiklediği |
|---|---|---|---|
| 1 | `Iconsax.receipt_text` | `'فواتير مشتري'` | `Navigator.push(CustomerInvoicesPage(isSupplier: false))` (`:29-39`) |
| 2 | `Iconsax.receipt_disscount` | `'فواتير مورد'` | `Navigator.push(CustomerInvoicesPage(isSupplier: true))` (`:40-50`) |
| 3 | `Iconsax.box_search` | `'تتبع المخزون'` | `Navigator.push(const StockTrackingPage())` (`:51-61`) |

- **Tutarsızlık (Doğrulandı):** karta verilen `color` argümanı (`Color(0xFF3B82F6)`, `0xFF10B981`, `0xFFDE24C8`; `:32,43,54`) `_ReportCard.build` içinde **hiç kullanılmıyor** → ikon/metin/çerçeve daima `AppColors.primary`. MorePage'deki `color` ölü parametresi ile aynı desen (bkz. 5.4).

### 5.20 SCR-020 `CustomerInvoicesPage` — taraf (müşteri/tedarikçi) seçici

Dosya: `customer_invoices_page.dart` (217 satır). **Adı yanıltıcı: bu sayfa fatura listesi değil, müşteri/tedarikçi seçme ekranıdır** (Doğrulandı). `CustomerInvoicesPage({bool isSupplier = false})` (`:12-14`); `partyId/partyName` parametresi yok.

- Provider: `isSupplier` → `BlocProvider<SupplierCubit>(sl<SupplierCubit>()..getSuppliers())` (`:19-22`), değilse `CustomerCubit` (`:24-27`). **`getCustomers()/getSuppliers()` no-op**; veri cubit constructor'ındaki Supabase realtime stream'inden gelir (`customer_cubit.dart:21-52`, `supplier_cubit.dart:21-51`): `client.from('customers').stream(primaryKey:['id']).eq('user_id', userId).order('created_at', desc)` (`customer_remote_datasource.dart:47-58`), `suppliers` için aynı (`supplier_remote_datasource.dart:45-55`). **Bu iki stream gerçek Supabase Realtime'dir** (ürmodülündeki `.asStream()` taklidinden farklı).
- `AppBar(title: isSupplier ? 'فواتير مورد' : 'فواتير مشتري', centerTitle: true)` (`:52-57`) — **başlık "fatura" diyor ama içerik müşteri/tedarikçi listesi (etiket/alan uyuşmazlığı).**
- Body `Column` (`:58-78`): ① `Padding(all 16) → TextField(hint 'بحث...', prefixIcon Iconsax.search_normal, filled, fillColor surface, OutlineInputBorder radius 12, borderSide none)`; `onChanged → setState(_searchQuery = value.trim())` — **debounce yok**, filtre bellek içinde senkron. ② `Expanded(list)`.
- Filtreleme: `name.toLowerCase().contains(q)` **veya** `phone` null değilse `phone.contains(q)` (`:106-112`, `:167-173`).
- Durumlar (müşteri dalı `:83-142`, tedarikçi dalı `:144-203` birebir aynı):
  - `CustomerInitial|CustomerLoading` → `Center(CircularProgressIndicator)`
  - `CustomerError` → `Icon(Iconsax.profile_delete, 64, AppColors.textSecondary)` + 16 px + `state.message` (16 px, center)
  - `CustomerLoaded` boş liste → `_emptyState(_searchQuery.isEmpty ? 'لا يوجد عملاء' : 'لا توجد نتائج')` (tedarikçi: `'لا يوجد موردون'` / `'لا توجد نتائج'`)
  - dolu → `ListView.builder(padding: symmetric(h 16))` → `PartyListTile`
  - diğer → `SizedBox.shrink()`
  - **Bu sayfada tarih filtresi, tablo/kart geçişi, özet kart, pull-to-refresh ve PDF YOK** (Doğrulandı; bunlar detay sayfasında).
- `PartyListTile` (`widgets/party_list_tile.dart`): `Card(margin bottom 8, radius 12)` → `ListTile(contentPadding h16/v8)`; leading `CircleAvatar(AppColors.primary α0.1)` içinde ismin ilk harfi (boşsa `'?'`), bold, primary (`:26-35`); title `name` w600; subtitle yalnız `phone != null` iken; trailing `Icon(Iconsax.arrow_left)`.
- Satır tap → `Navigator.push(CustomerInvoiceDetailPage(partyId: id, partyName: name, isSupplier: …))` (`:126-131`, `:190-191`).

### 5.21 SCR-021 `CustomerInvoiceDetailPage` — tarafın fatura listesi + PDF

Dosya: `customer_invoice_detail_page.dart` (258 satır). `CustomerInvoiceDetailPage({required partyId, required partyName, isSupplier = false})` (`:17-26`). **Salt-okunur liste: fatura başlık alanları, kalem tablosu, toplam satırları, düzenle/sil/öde aksiyonları ve dialog yok**; tek `onTap: () {}` no-op (`:250`).

- `BlocProvider<PartyInvoiceCubit>(sl<PartyInvoiceCubit>()..loadInvoices(partyId, isSupplier))` (`:30-38`) — yükleme **yalız bir kez**, provider create içinde.
- AppBar (`:151-196`): title `partyName` (başka etiket yok), centerTitle; actions: `_isGeneratingPdf` iken `Padding(all 16) → SizedBox(20×20, CircularProgressIndicator(strokeWidth 2))`, değilse ① `IconButton(Iconsax.document_download)` — **yalnız `loaded && invoices` doluysa enabled**, ② `Stack`: `IconButton(Iconsax.calendar)` + filtre aktifse `Positioned(right 8, top 8, SizedBox(8×8, DecoratedBox(AppColors.primary, circle)))`. `hasFilter = selectedYear != null || (isCustomDateRange && customDateRange != null)` (`:146-147`).
- Takvim → `DateFilterSheet.show(...)` (`:60-87`) ve `onDateRangePickerTap` → `showDateRangePicker(firstDate: DateTime(2020), lastDate: now+365 gün, initialDateRange: cubit.customDateRange, locale: Locale('ar'))`; seçim sonrası `Navigator.pop` + `setCustomDateRange` (`:81-84`).
- Body (`:201-257`): `PartyInvoiceLoading` → spinner; `PartyInvoiceError` → `Icon(Iconsax.receipt_disscount, 64, textSecondary)` + 16 px + mesaj (16 px); `PartyInvoiceLoaded` boş → aynı düzen + `'لا توجد فواتير'` (satır içi — **`PartyInvoiceEmptyState` bileşeni ölü**); dolu → `ListView.builder(padding all 16)` → `InvoiceCardWidget(invoice, type: isSupplier?'purchase':'sale', onTap: () {})`.
- PDF `_generatePdf` (`:89-139`): guard `state is! PartyInvoiceLoaded || invoices.isEmpty → return`; `_isGeneratingPdf=true`; `client.from('profiles').select('business_name').eq('id', userId).maybeSingle()`; `dateRangeLabel`: custom → `'من d/m/y إلى d/m/y'`, yıl → `'السنة: <yıl>'`, değilse `''`; `PdfInvoiceService().generateInvoiceListPdf(companyName:, partyName:, dateRangeLabel:, invoices: state.invoices, type: isSupplier?'purchase':'sale')`; `Printing.sharePdf(bytes, filename: 'invoices_<partyId>.pdf')`; hata → `log` + snackbar `'فشل إنشاء PDF: <e>'`; `finally` flag sıfırlanır.

**`PartyInvoiceCubit`** (`bloc/party_invoice_cubit.dart`): alanlar `_allSales: List<SalesInvoice>`, `_allPurchase: List<PurchaseInvoice>` (`:13-14`), `_selectedYear`, `_customDateRange`, `_isCustomDateRange=false`. `availableYears` = iki listenin `invoiceDate.year` birleşimi, desc sıralı (string karşılaştırma), boşsa `[currentYear]` (`:26-36`). `loadInvoices` (`:38-65`): supplier → `getPurchaseInvoicesBySupplier(partyId)` else `getSalesInvoicesByCustomer`; fold hata → `PartyInvoiceError(failure.message)`, başarı → ilgili listeyi doldur + **karşı listeyi temizle** + `_applyFilter()`; catch → `PartyInvoiceError(e.toString())`. `setYear`/`setCustomDateRange`/`clearFilter` (`:67-86`) birbirini dışlayan sıfırlama + `_applyFilter()` — **istemci tarafı filtre, yeniden istek atılmaz.** `_applyFilter` (`:88-113`): `List<dynamic>` (tip karışımı) — `_allSales` değilse `_allPurchase`; custom aralık her iki uç dahil (`!isBefore(start) && !isAfter(end)`); yıl `year.toString()` eşitliği; `PartyInvoiceLoaded(invoices: filtered, totalCount: filtered.length)`. `_getInvoiceDate(dynamic)` fallback `DateTime.now()` (`:115-119`).
**Durumlar** (`party_invoice_state.dart`): `PartyInvoiceInitial` (`:10`), `PartyInvoiceLoading` (`:14`), `PartyInvoiceLoaded{List<dynamic> invoices; int totalCount}` (`:18`), `PartyInvoiceError{String message}` (`:31`). **Realtime/stream/debounce yok.**

**Veri katmanı:** `report_repository.dart` yalnız 2 metod (`:7-10`), hepsi remote; hata → `Left(ServerFailure(e.toString()))` (`:18-35`). **`AppDatabase` referansı yok → reports modülü offline'da cache okumaz**, `PartyInvoiceError` gösterir (Doğrulandı; oysa `sales_invoices_cache`/`purchase_invoices_cache` tabloları mevcut, `app_database.dart:27-46`).
`report_remote_datasource.dart`:
- Satış (`:25-31`): `from('sales_invoices').select('*, customers!inner(name), sales_invoice_items(*)').eq('user_id', userId).eq('customer_id', customerId).isFilter('deleted_at', null).order('invoice_date', desc)` — **`limit` yok**. Hata → `log('ReportRemoteDataSource: Failed to load customer invoices - $e')` + `rethrow Exception('Failed to load customer invoices: $e')` (`:34-37`) → kullanıcı **İngilizce** hata metni görür.
- Alış (`:46-52`): `purchase_invoices` + `suppliers!inner(name)` + `purchase_invoice_items(*)`, `.eq('supplier_id', …)`, hata `'Failed to load supplier invoices: $e'`.
- Eşleme (`:61-97`): `customers.name → customer_name`, `suppliers.name → supplier_name`, `*_invoice_items → items` ve `product_name ??= ''`, join anahtarları silinir → `SalesInvoice.fromJson` / `PurchaseInvoice.fromJson`.

**`InvoiceCardWidget`** (`core/widgets/invoice_card_widget.dart`, 3 kullanım noktası: invoices sayfası, bu sayfa, `party_invoice_list.dart`(ölü)): `Container(margin bottom 16) → Card → InkWell(radius 16) → Padding(20), border AppColors.border(0xFFD1D5DB)`.
- Tür rozeti (`:46-77`): `padding h12/v6`, bg `AppColors.primary α0.15`, radius 8, border primary 0.5; ikon `Icons.trending_up`(sale)/`Icons.trending_down`(purchase) 16 px; **metin `'sale'`/`'purchase'` — İngilizce literal (12 px w700)**. **Tutarsızlık (Doğrulandı).**
- Durum rozeti `_buildStatusBadge` (`:224-256`): `paymentStatus == PaymentStatus.cash` → `'مدفوعة'` + `Icons.check_circle` (`AppColors.success 0xFF10B981`), değilse `'مديون'` + `Icons.access_time` (`AppColors.warning 0xFFF59E0B`); padding h12/v6, α0.15 bg, radius 8, border 0.5, ikon 14, metin 11 w600. **`_getInvoiceStatus()` hesaplanıp metoda geçiriliyor (`:25`, `:80`, param `:225`) ama gövdede okunmuyor → iptal/taslak fatura "مدفوعة" görünebilir (Doğrulandı, hata).** Ayrıca `PaymentStatus` tek `'cash'`/`'debt'` (`payment_status.dart:3-6`), model Arabic etiketleri `'مدفوعة نقدا'`/`'مديون'` (`:10-12`) rozet metinleriyle farklı.
- Gövde: numara 16 px w700 `0xFF1F2937`, taraf adı 14 px w500 `0xFF6B7280`, `Divider(color: AppColors.secondary, thickness 0.3, height 0.5)`; `'تاريخ'` etiketi (12 px `0xFF9CA3AF`) altında `AppUtils.formatDate(...)` = **`'yyyy-MM-dd'`** (`app_utils.dart:5-7`) 14 px w600 `0xFF1F2937`; `'المجموع'` altında `'${AppUtils.formatNumber(total)} ${NumberFormatter.getCurrencySymbol()}'` 18 px w700 primary — `formatNumber` = `NumberFormat.decimalPatternDigits(locale:'ar_SA', decimalDigits: 2)` (`app_utils.dart:39-45`).

**`DateFilterSheet`** (`core/widgets/date_filter_sheet.dart`, 6 sayfada kullanılıyor: invoices, expenses, app_bar_date_filter, withdrawals, stock_tracking, customer_invoice_detail): `showModalBottomSheet`, üst radius 20, drag handle `40×4` radius 2 (`AppColors.divider`), içerik padding `fromLTRB(24,12,24,32)`.
- `'تصفية البيانات'` 18 px bold (`AppColors.text 0xFF1A1A2E`) → `'اختر السنة أو نطاق تاريخ مخصص'` 13 px textSecondary.
- `'السنة'` bölümü (13 px w600): `Expanded` yıl kutuları, padding v12, radius 10, seçili bg primary + beyaz w600 / değilse bg `AppColors.background` + border divider, 14 px, aralarında 8 px; tap → `onYearSelected(year)` + `Navigator.pop`.
- `'أو'` ayracı (12 px, yatay padding 12) → `'نطاق تاريخ مخصص'` → iki `_DateField`: `'من'` ve `'إلى'` (padding h12/v12, radius 10, bg background, border divider, `Icons.calendar_today` 16 — değer varsa primary, metin 13 px `d/m/y`). **İki alan da aynı `onDateRangePickerTap`'ı çağırıyor** (tek aralık seçici).
- Yalnız `isCustomDateRange` iken: ortalanmış `TextButton.icon(Icons.close 16, 'إلغاء التصفية', AppColors.error)` → `onClearFilter()` + pop.
- **Hazır öncül ("bu ay", "son 7 gün") yok** (Doğrulandı).

### 5.22 SCR-022 `StockTrackingPage` — stok takibi

Dosya: `stock_tracking_page.dart` (400 satır). Parametresiz `const StockTrackingPage()`; yalnız SCR-019 kart 3'ten açılıyor. **`Supabase.instance.client` doğrudan alan olarak kullanılıyor (`:20`) → repository/datasource katmanı tamamen atlanıyor (mimari istisna. Doğrulandı).**

`_loadData` (`:47-90`, `initState` → post-frame `:35-38`) `Future.wait` ile 3 sorgu:
1. `from('categories').select('id, name').eq('user_id', userId).order('name')` (`:53`)
2. `from('dashboard_product_stock').select().eq('user_id', userId)` (`:54`) — view; koddan görünen kolonlar `product_id`, `product_display_name`, `total_purchased_qty`; model ayrıca `user_id, system_stock, total_sold_qty, calculated_remaining_stock` taşıyor (`dashboard/data/models/dashboard_product_stock.dart:22-31`). **View SQL'i repoda yok → Bilinmiyor.**
3. `from('products').select('id, category_id').eq('user_id', userId)` (`:55`) — `category_id` istemcide join ediliyor (`:62-70`), yani view'da `category_id` yok.

- **Bug (Doğrulandı, `:72-73`):** `_availableYears = products.map((_) => DateTime.now().year.toString())` → argüman kullanılmıyor, liste daima içinde bulunulan yıl.
- **Filtre kozmetik:** `_selectedYear` ve `_customDateRange`, `_filteredProducts`'ı (`:40-45`, yalnız `category_id` + arama yok) filtrelemiyor; tarih yalnız PDF etiketini etkiliyor (`_dateRangeLabel` `:112-122`: custom → `'من d/m/y إلى d/m/y'`, yıl → `'السنة: <yıl>'`, değilse `''`).
- AppBar: `'تتبع المخزون'` centerTitle (`:227-228`); actions: `_isGeneratingPdf` → 20×20 spinner; `Iconsax.document_download` **yalnız `_selectedProductIds.isNotEmpty` iken görünüyor** (`:239-243`); `Iconsax.calendar` + filtre aktifken 8×8 primary nokta (`:244-262`). Tarih dialogu `DateFilterSheet` (bkz. 5.21).
- Kategori satırı (`:278-294`): `Container(height 60, padding h16/v8)` + yatay `ListView`; ilk chip `null → 'الكل'`, aralarında 8 px; chip padding h16/v8, radius 20, seçili bg+border primary / değilse bg surface + border divider, 13 px, seçili beyaz w600 değilse `AppColors.text` w400 (`:296-319`).
- Seçim satırı (`:321-350`, padding h16/v4): `TextButton.icon(Iconsax.tick_circle 16, 'تحديد الكل', primary)`; `TextButton.icon(Iconsax.close_circle 16, 'إلغاء الكل', textSecondary)`; sayaç `'${_selectedProductIds.length} مختار'` 12 px textSecondary. `_selectAllFiltered` yalnız filtreli kategori id'lerini seçer (`:102-106`).
- Liste (`:352-399`): boş → `Icon(Iconsax.box_search, 64, textSecondary)` + 16 px + `'لا توجد منتجات'` 16 px; dolu → `ListView.builder(padding h16)` → `Card(margin bottom 6, radius 10)` içinde `CheckboxListTile(dense, activeColor primary, controlAffinity: trailing)`; title `product_display_name` 14 px; **subtitle `'المشتريات: <total_purchased_qty>'`** (`:376`, `:389`).
- **Eksikler (Doğrulandı):** stok/kalancı miktar gösterilmiyor (`system_stock`, `calculated_remaining_stock` okunmuyor), düşük-stok vurgusu yok (`AppConstants.lowStockThreshold 0.2` / `criticalStockThreshold 0.1` tanımlı ama bu sayfada kullanılmıyor, `app_constants.dart:138-139`), özet sayı yok, sıralama yok, metin arama yok. Sayfa adı "stok takibi" olduğu için bu **etiket/işlev uyuşmazlığı** olarak not edilmeli.
- PDF (`:124-166`): guard boş seçim; `profiles.business_name`; `PdfInvoiceService().generateStockPdf(companyName:, dateRangeLabel:, products: selectedProducts)`; `Printing.sharePdf(filename: 'stock_tracking.pdf')`; hata → snackbar `'فشل إنشاء PDF: <e>'`.
- `generateStockPdf` (`core/services/pdf_invoice_service.dart:78-200`): A4, margin 24; `PdfGoogleFonts.amiriRegular()/amiriBold()`; toplam = `total_purchased_qty` fold; başlık `companyName` yoksa `'تقرير تتبع المخزون'` (14 bold) + tarih etiketi (10, grey600); 2 kolon `FlexColumnWidth(4)` miktar / `2)` ad, başlık hücreleri `'الكمية المشتراة'` / `'اسم المنتج'` (miktar solda), hücre padding 8, 11 px, veri sağ hizalı; altta `'الإجمالي'` kutusu (padding 12, border grey300, radius 6, 13 bold). Tüm Arapça metin `_processArabicText` = `ArabicReshaper.instance.reshape` + `Bidi.logicalToVisual` (`:857-863`).

### 5.23 SCR-017 `ExpensesPage` — giderler (`/expenses`)

Dosya: `lib/features/expenses/presentation/pages/expenses_page.dart` (450 satır). Route `AppRoutes.expenses = '/expenses'` (`app_constants.dart:155`), `main.dart:90-91` → `const ExpensesPage()`. MorePage kartı `'النفقات'` üzerinden pushNamed. **`isLocal: true` veren tek çağrı noktası yok** → `:103` (kategori butonu gizleme) ve `:236` (FAB gizleme) dalları şu an erişilemez (Doğrulandı).
Ayrıca `AppRoutes.expenseDetails = '/expenses/:id'` (`app_constants.dart:156`) tanımlı ama `main.dart:75-108` içinde case'i ve push eden çağrısı **yok** → ölü rota.

- State: `_periodMode = PeriodMode.year` (`:26`), `_selectedYear = now.year.toString()` (`:27`), `_customDateRange = null` (`:28`); gövde `BlocProvider(create: sl<ExpenseCubit>())` içinde (`:32-33`).
- `availableYears` (yıl, y-1, y-2; `:44-48`) body içinde **hiç okunmuyor** — `_ExpensesDateFilter._showSheet` kendi listesini yeniden kuruyor (`:402-406`) → ölü parametre.
- `initState` post-frame: `filterByDateRange(DateTime(year,1,1), DateTime(year,12,31))` (`:85-93`) → açılışta içinde bulunulan yıl.
- AppBar: title `'المصروفات'` (`:100`), bg `AppColors.background` (`:101`), **leading/back butonu yok** (Material auto-back). Actions: ① `if (!isLocal)` → `IconButton(Icons.category_outlined, 24, tooltip 'إدارة التصنيفات', bg primary α0.1)` → `ExpenseCategoriesDialog` (`:104-134`); ② `_ExpensesDateFilter` chip (`:137-164`, `:369-393`): padding `symmetric(h12,v7)`, radius 20, bg primary α0.1, border primary α0.2, `Icons.calendar_today` 16, metin 13 px w500; etiket custom aralıkta `'${start.day}/${start.month} - ${end.day}/${end.month}'`, değilse yıl (`:362-364`). Tap → `DateFilterSheet.show` (custom seçici `showDateRangePicker(firstDate: DateTime(2020), lastDate: DateTime(2100))`, `:421-443`); yıl → `filterByDateRange(1 Ocak, 31 Aralık)`; `'إلغاء التصفية'` → custom sıfırla + `PeriodMode.year` + yıl aralığı (`:154-162`). **`_periodMode` yalnız yazılıyor, render'da okunmuyor (ölü durum).**
- Body (`:168-229`): `BlocConsumer`; listener `ExpenseSuccess` → yeşil snackbar (`Colors.green`, 2 sn), `ExpenseError` → `AppColors.error` snackbar 2 sn. Builder: `ExpenseInitial|ExpenseLoading` → ortalanmış spinner; else `SingleChildScrollView(padding all 12) → Column(start)`: `ExpenseSummaryCardsWidget` → 12 px → `ExpenseMonthlyChartWidget(expenses: state.expenses, year: _getSelectedYear())` → 12 px → `_buildCategoryChips` → 12 px → `ExpenseTableWidget(expenses, categories, onDelete: cubit.deleteExpense, onTap: (e){})`.
  - **`:221-227` dalı ulaşılamaz** (`:190`'da zaten return); `ExpensesLoaded` dışı her state (yani `ExpenseSuccess`, `ExpenseError`, `ExpenseCategoriesLoaded`) → `SizedBox.shrink()` (`:228-229`).
  - Pull-to-refresh / yenileme butonu **yok**. Görünüm geçişi (tablo↔kart) **yok** — `ExpenseCardsWidget` hiç bağlanmamış. Arama kutusu modülde **hiç yok**.
- Kategori chip'leri (`:266-326`): `SizedBox(height 40)` yatay `ListView`; ilki `'الكل'` (`selectedCategoryId == null` → `setCategoryFilter(null)`), aralarda 8 px; chip Material radius 20, padding `symmetric(h16,v10)`, border primary/divider, 13 px, seçili w600/beyaz, değilse w500/`AppColors.text`.
- FAB (`:241-253`): `FloatingActionButton.extended(label 'إضافة مصروف' (AppColors.surface), bg AppColors.primary)` → `ExpenseFormDialog(categories: cubit.categories, onSubmit: createExpense + Navigator.pop)`.

**`ExpenseCubit`** (`bloc/expense_cubit.dart`, 246 satır): constructor `ExpenseInitial()` + `Future.delayed(100 ms)` → `_startRealtimeListeners()` (`:31-35`). Filtre alanları `_startDate/_endDate/_selectedCategoryId`, cache `_categories/_expenses`.
- Durumlar (`expense_state.dart`): `ExpenseInitial` (`:10`), `ExpenseLoading` (`:12`), **`ExpenseCategoriesLoaded` (`:14`) hiç emit edilmiyor (ölü sınıf)**, `ExpensesLoaded{expenses, categories, startDate?, endDate?, selectedCategoryId?, totalAmount=0, totalCount=0, averageAmount=0, monthlyData=const{}}` (`:23-57`; `copyWith` hiç çağrılmıyor), `ExpenseSuccess(message)` (`:84`), `ExpenseError(message)` (`:93`).
- "Realtime" (`:39-66`): `ExpenseLoading` emit → `repository.watchExpenseCategories()` / `watchExpenses()` abonelikleri, fold ile `ExpenseError(failure.message)` veya cache doldur + `_emitExpensesLoaded()`. **Bunlar Supabase Realtime değil** — datasource tek seferlik `.select().asStream()` (`expense_remote_datasource.dart:121`, `:223`); `.listen` üzerinde `onError` yok → stream hatası yakalanmaz. **`expense_cubit.dart:159,172,183` yorumları "otomatik güncellenir" diyor; doğru değil (Doğrulandı).** `close()` iki aboneliği iptal eder (`:124-129`).
- `_emitExpensesLoaded` (`:68-86`): `totalAmount = fold(sum)`, `totalCount = length`, `averageAmount = total/count`, `monthlyData = 'YYYY-MM'` anahtarlı (`:92`) — **`monthlyData` hiçbir widget tarafından okunmuyor** (grafik ham `expenses`'tan yeniden hesaplıyor); `startDate/endDate/selectedCategoryId` state'e taşınıyor ama tüketilmiyor.
- İstemci filtre `_getFilteredExpenses` (`:99-122`): `expenseDate` aralık dışı → at; `categoryId` uymazsa at; tarihi desc sırala. **Arama/debounce yok.**
- CRUD metinleri (birebir): kategori ekleme **optimistic** — `temp_${millis}_${Random().nextInt(1000)}` (`:141`) + ekle + emit (`:144-146`), hata → tempId ile rollback + `'فشل إضافة الفئة: <message>'` (`:154-156`), başarı → `'تم إضافة فئة المصروفات بنجاح'` (`:160`). **Başarıda `_emitExpensesLoaded()` yok** → state `ExpenseSuccess` kalır → sayfa gövdesi **boş görünür** (bkz. yukarı `:228-229`); bir sonraki filtre etkileşiminde düzelir. **Doğrulandı, kritik UX hatası.**
  `updateExpenseCategory` → `'تم تحديث فئة المصروفات بنجاح'` (`:171`), `deleteExpenseCategory` → `'تم حذف فئة المصروفات بنجاح'` (`:182`) — aynı boş-gövde sorunu. `createExpense` → `ExpenseLoading` + `'تم إضافة المصروف بنجاح'` + reload (`:209-216`); `updateExpense` → `'تم تحديث المصروف بنجاح'` (`:226`) — **yalnız ölü `expense_list_widget.dart:307` üzerinden erişilebilir**; `deleteExpense` → `'تم حذف المصروف بنجاح'` (`:237`) + reload. Başarısızlıklarda ham `failure.message` emit ediliyor (`:169,180,212,224,235`).
- `setCategoryFilter` (`:189`), `filterByDateRange` (`:194`); **`clearFilters` (`:200`) ve `clearError` (`:243`) hiç çağrılmıyor.**

**Veri katmanı:** DI `services_locator.dart:177-186`. Tablolar **`expenses` ve `expense_categories`** (view/RPC yok). `expense_remote_datasource.dart`:
- Kategoriler (`:47-52`): `from('expense_categories').select().eq('user_id', userId).eq('is_active', true).order('name')`; stream sürümü aynı + `.asStream()` (`:115-122`, yorumda "فوري" deniyor).
- Giderler (`:134-139`): `from('expenses').select('*, expense_categories(name)').eq('user_id', userId).isFilter('deleted_at', null).order('expense_date', desc)`; stream aynı (`:217-224`). **`getExpenses`'in `startDate/endDate/categoryId` parametreleri (`:126`) sorguya uygulanmıyor (ölü)** ve `getExpenses`/`getExpense` cubit/UI'dan hiç çağrılmıyor.
- Insert (`:70-74`, `:172-176`) `insert(toMap()).select(...).single()`, `userId` `copyWith(userId:)` ile enjekte (`:69`, `:171`); update `update(toMap()).eq('id')` (`:85-90`, `:187-192`); **delete hard delete** `delete().eq('id')` (`:101`, `:203`) — okuma tarafında `deleted_at is null` filtresi varken (tutarsızlık).
- Payload anahtarları — `expense.toMap` (`models/expense.dart:83-97`): `user_id, category_id, amount, description, expense_date(ISO), payment_method, receipt_number, notes, created_at, updated_at, deleted_at` (`id`, `category_name` yok). `expense_category.toMap` (`:48-56`): `user_id, name, description, is_active, created_at`.
- Repository (`expense_repository.dart`) tüm future metotlarda `networkInfo.isConnected` kapısı (`:17,33,49,65,90,106,122,138,154`) → offline `Left(NetworkFailure.noConnection())` = `'لا يوجد اتصال بالإنترنت'`. **`watchExpenseCategories`/`watchExpenses` bağlantı kontrolü yapmıyor** (`:80-86`, `:169-175`). **Gider modülünde sqlite cache/queue YOK** (`app_database.dart` içinde `expense` geçen tablo yok; grep). PDF servisi de kullanılmıyor.

**Modeller:** `Expense` (`expense.dart:3-116`): `id req`, `userId req`, `categoryId?`, `categoryName?`, `amount req`, `description?`, `expenseDate req`, `paymentMethod req default 'cash'` (`:26`), `receiptNumber?`, `notes?`, `createdAt req`, `updatedAt req`, `deletedAt?`. `fromMap` (`:99-115`): `amount: (map['amount'] ?? 0).toDouble()`; `categoryName` **embed join nesnesinden** `map['expense_categories']['name']` (`:104`); tarihler `DateTime.parse` (null → çöker); `payment_method ?? 'cash'`. **Hesaplanmış getter yok** — formatlama widget'larda.
`ExpenseCategory` (`:3-68`): `id, userId, name, description?, isActive=true, createdAt`; `isActive` yalnız sunucu filtresinde, `description` yalnız kategoriler dialogunda, `userId` hiç gösterilmiyor.

**Widget'lar:**
- `ExpenseSummaryCardsWidget` (`expense_summary_cards_widget.dart`): `Row` 2 `Expanded` kart; `'إجمالي'` → `'${NumberFormatter.format(totalAmount)} <sembol> '` rengi `AppColors.primary` (`:27-32`); **ortadaki `'عدد'`/totalCount kartı yorum satırına alınmış** (`:33-39`, yine de parametre geçiriliyor); `'المتوسط'` → ortalama + sembol, `AppColors.text` (`:40-46`). Kart: surface bg, border divider, radius 12, padding 12; başlık 10 px w600 textSecondary `letterSpacing 0.5`; 6 px; değer 18 px w700.
- `ExpenseMonthlyChartWidget`: **fl_chart `BarChart`** (`pubspec.yaml:35`). Veri yok → surface kutu (radius 12, padding 20) + `'لا توجد بيانات للعرض'` (`:22-37`). Yoksa `padding only(bottom10,top10,right10)`, radius 12; başlık `'المصروفات الشهرية'` 16 bold; `SizedBox(height 200)`. 12 kova, yalnız `expenseDate.year == year` parametresi toplanıyor (`:168-186`); `maxY = max*1.2`, taban 100 (`:188-193`); çubuk `spaceAround`, `AppColors.primary`, genişlik 12, üst radius 4. Alt eksen: **ay adları değil 1..12 sayıları** (10 px w500, reservedSize 25); sol eksen kısaltılmış `1.2M/3.4K` (10 px, reservedSize 40, 0 atlanır); ızgara `maxY/5`, üst/sağ gizli. Tooltip yalnız `NumberFormatter.format(rod.toY)` — **ay adı ve para birimi yok** (`:70-84`). `ChartData.label` alanı tanımlı ama kullanılmıyor (`:205-210`).
- `ExpenseTableWidget` (`expense_table_widget.dart`): **adı "table" ama kart listesi basıyor; kolon başlığı/flex yok.** Boş → padding 32, radius 12, `Icons.receipt_long_outlined` 40 secondary, 16 px, `'لم يتم العثور على بيانات'` 14 px (`:140-166`). Liste `ListView.separated(shrinkWrap, NeverScrollable, separator 10)`; satır: surface radius 12 border divider, `InkWell` → `ExpenseDetailDialog.show(context, expense, category)`; padding `fromLTRB(14,12,6,12)`; Row → Expanded Column: `description ?? '-'` 14 px w600 maxLines1; 6 px; `Icons.calendar_today` 11 + `DateFormat('dd.MM.yyyy')` 11 px secondary; **kategori rozeti bellekteki `categories` listesinden `categoryId` ile çözülüyor** (`:36`, `:98`) — `expense.categoryName` kullanılmıyor; padding h6/v2 radius 4 bg primary α0.1 metin 10 px; 8 px;amount `'${NumberFormatter.format(amount)} <sembol>'` 15 px bold **`AppColors.error`**; silme butonu `SizedBox(width 36)` `Icons.delete_outline` 18 secondary (`padding EdgeInsets.zero`, boş `BoxConstraints`). `onTap` parametresi (`:13`) hiç çağrılmıyor — sayfada boş fonksiyon geçiriliyor. Silme onayı (`:168-206`): `'تأكيد الحذف'` / `'هل أنت متأكد من الحذف؟'` / `'إلغاء'` / `'حذف'` (bg `AppColors.error`), 24 px boşluk, sağ hizalı.
- `ExpenseCardsWidget` (**ölü**, hiçbir sayfada instantiate edilmiyor): `categoryId ?? 'uncategorized'` gruplama, `SliverGridDelegateWithMaxCrossAxisExtent(320, spacing 14, aspect 1.2)`; kart padding 18 radius 12; avatar 36×36 `Color(0xFFFFF5F5)` radius 9 + ilk harf (yoksa `'?'`) 14 w600 error; ad 14 w600 + **sabit alt yazı `'فئة المصروفات'`** (12 px, hiçbir alana bağlı değil); `'الإجمالي'` 12 + toplam 16 w700 error; `'المصروفات: <count>'` 12; `LinearProgressIndicator(minHeight 6, bg divider, valueColor error)` = grup/en-büyük-grup oranı; fallback ad `'غير مصنف'`; `onTap` boş.
- `ExpenseListWidget` + `ExpenseCard` (**ölü**): boş durumu `Icons.receipt_long_outlined` 64 α0.5 + `'لا توجد مصروفات'` 16 w500 + `'أضف مصروف جديد للبدء'` 14 α0.7; kart radius 12 padding 16, ikon kutusu 48×48 radius 10 error α0.1 `Icons.money_off_outlined`, `description ?? 'مصروف'`, **`expense.categoryName`** (join alanı) rozeti, tarih `d/m/y` elle, tutar 16 bold error + sembol 12; tap → AlertDialog `'تفاصيل المصروف'` (header edit/delete; satırlar `'المبلغ'` (sembol yok), `'طريقة الدفع'` → `cash→'نقدي'`, `card→'بطاقة'`, `transfer→'تحويل'`, `'التاريخ'`, `'الفئة'`, `'رقم الإيصال'`, `'ملاحظات'`, aksiyon `'إغلاق'`).
- `ExpenseFiltersWidget` (**ölü**; sayfadan yalnız `enum PeriodMode { year, custom }` import ediliyor, `:5`): `'الفترة'` etiketi, `'سنة'`/`'مخصص'` toggle'ı, `'السنة'` dropdown'ı, `'نطاق التاريخ'` dalı — ve içindeki tarih gösterim çağrısı yorumlu, `%100`'ü yorumlu `core/utils/custom_date_range_picker.dart`'ı import ediyor. Hazır öncüller (`'اليوم'`, `'هذا الأسبوع'`, `'هذا الشهر'`, `'هذا العام'`) yalnız bu yorumlu dosyada (`:50-72`).

### 5.24 DLG-26 … DLG-30 (giderler modülü)

| ID | Tetikleyici | Bileşen / geometri | Alanlar, validator'lar, butonlar |
|---|---|---|---|
| DLG-26 | AppBar `Icons.category_outlined` | `ExpenseCategoriesDialog` → `Dialog → Container(width 500, height 600)` | Header padding 20 + alt divider: `'فئات المصروفات'` 18 bold, düzenleme modunda değilken `'فئة جديدة'` `ElevatedButton.icon(Icons.add 18)`, `Icons.close`; **satır içi form**: `'اسم الفئة *'` (validator `'اسم الفئة مطلوب'`) + `'وصف (اختياري)'` (`maxLines 2`, validator yok), radius 8, contentPadding h16/v12; butonlar `'إلغاء'` (Outlined) + `'حفظ'`/`'إضافة'`; liste boş → `Icons.folder_open_outlined` 64 + `'لا توجد فئات'` 16 + `'أضف فئة جديدة للبدء'` 14 α0.7; `ListTile` ad w500 + description 12 px, trailing `Icons.edit`(primary)/`Icons.delete`(error); silme onayı `'هل أنت متأكد من حذف هذه الفئة؟'` + `'إلغاء'`/`'حذف'` (bg **`Colors.red` literal**) (`expense_categories_dialog.dart:65-313`) |
| DLG-27 | FAB `إضافة مصروف` / kart düzenleme | `ExpenseFormDialog` → `Dialog → Container(width 500, maxHeight 700)` | Başlık `expense != null ? 'تعديل المصروف' : 'إضافة مصروف جديد'` 18 bold + close; alan sırası: ① `'المبلغ *'` (`keyboardType number`, formatter `RegExp(r'^\d*\.?\d*')`, prefix `NumberFormatter.getCurrencySymbol()`, hint `'أدخل المبلغ'`, validator `'المبلغ مطلوب'` / `'المبلغ غير صالح'`) ② `'الفئة'` dropdown (hint `'اختر الفئة'`, `null → 'بدون فئة'`) ③ `'الوصف'` (hint `'وصف المصروف'`, validator yok) ④ `'التاريخ *'` (InkWell, `Icons.calendar_today` 18, `d/m/y`, `showDatePicker(firstDate: 2000, lastDate: 2100)`) ⑤ `'ملاحظات'` (`maxLines 3`, hint `'ملاحظات إضافية (اختياري)'`); butonlar `'إلغاء'` + `'حفظ التغييرات'`/`'إضافة مصروف'`. **Ödeme yöntemi seçici (`_buildPaymentMethodSelector`, `:325-376`) ve `_receiptController` ağaçta yok** → `payment_method` daima `'cash'`, `receipt_number` düzenlenemez (Doğrulandı). Dialog kendini kapatmıyor; `Navigator.pop` sayfa callback'inde (`expenses_page.dart:247`) (`expense_form_dialog.dart:36-412`) |
| DLG-28 | Tablo satırına dokunma | `ExpenseDetailDialog.show` → `Dialog(radius 12)` padding 24 | `'تفاصيل المصروف'` 18 bold + close (bg background); blok bg primary α0.1 radius 8: `'المبلغ'` 12 secondary + **`'<sembol> <tutar>'` (sembol başta)** 20 bold primary; `_buildInfoRow` satırları: `'التاريخ'` `DateFormat('yyyy-MM-dd')`, `'الفئة'` (yalnız category != null), `'الوصف'` (`'-'`), tam genişlik `'إغلاق'`; **`payment_method`, `receipt_number`, `notes` gösterilmiyor** (`expense_detail_dialog.dart:35-138`) |
| DLG-29 | Tablo satırı silme ikonu | `AlertDialog` | `'تأكيد الحذف'` / `'هل أنت متأكد من الحذف؟'` / `'إلغاء'` / `'حذف'` (bg `AppColors.error`) (`expense_table_widget.dart:168-206`) |
| DLG-30 | AppBar tarih chip'i | `DateFilterSheet` (bottom sheet, bkz. 5.21) + `showDateRangePicker(2020→2100)` | yıl chip'leri / `'من'-'إلى'` / `'إلغاء التصفية'` |

**Etiket/bağlama uyuşmazlıkları (giderler):** tablo rozeti `categoryId` → bellekteki listeden çözülüyor, modelin `categoryName` alanı ise yalnız ölü liste widget'ında okunuyor; kategori yeniden adlandırılırsa tablo bayat/ad-sız kalabilir. `ExpenseFormDialog` submit'inde `categoryName` dolduruluyor (`:399`) ama `toMap` bu alanı yazmıyor → **yaz-ama-okuma alanı**. Grafik `state.monthlyData`'yı ve seçili tarih filtresinin yıllarını yok sayıyor, yalnız `_getSelectedYear()` üzerinden kovalıyor → yıl-ötesi custom aralık seçilirse grafik tek yılı gösterir.

### 5.25 Düzeltme — Bölüm 5.3/5.4 için: dashboard widget'larının çoğu ölü

`lib/features/dashboard/presentation/widgets/` içindeki bileşenlerden **yalnız `AppBarDateFilter`** kullanılıyor. Grep ile doğrulanan, **hiçbir yerden instantiate edilmeyen** sınıflar: `AppNavigationDrawer` (iki ayrı dosyada iki kopya: `app_navigation_drawer.dart`, `navigation_drawer.dart`), `CustomAppDrawer` (`custom_app_drawe.dart`), `AppSidebar` + `MenuItem` (`app_sidebar.dart`), `DashboardPageWrapper`, `DashboardStatsCard`, `DateFilterSection`, `RemainingStockSection`. Yani **uygulamada drawer/sidebar yok** — navigasyon yalnız alt sekme + MorePage grid'i + `Navigator.push`. (Bölüm 4'teki navigasyon haritası bu bulguya göre teyit edildi; drawer dosyaları içindeki `AppRoutes.expenses` gibi `pushNamed` çağrıları erişilemez kod.)

### 5.26 SCR-018 `WithdrawalsPage` — kasa çıkışları (`/withdrawals`)

Dosya: `lib/features/withdrawals/presentation/pages/withdrawals_page.dart` (477 satır). Route `AppRoutes.withdrawals = '/withdrawals'` (`app_constants.dart:157`), `main.dart:92-93` → `const WithdrawalsPage()`; tek açan MorePage kartı `'السحوبات'` (renk `0xFFF59E0B`, ikon `Iconsax.money_recive`, `more_page.dart:42-47`). **`isLocal: true` veren çağrı yok** → `:91` (şirket ekle butonu), `:207` (FAB), `:259` (boş durum butonu) dalları üretimde erişilemez.
**Etiket uyuşmazlığı:** drawer dosyasında aynı ekranın adı `'الانسحابات'` (`custom_app_drawe.dart:56`), MorePage/sayfada `'السحوبات'` — drawer ölü olduğundan kullanıcı yalnız ikincisini görüyor (bkz. 5.25).

- `BlocProvider(create: sl<WithdrawalCubit>())` (`:29-30`); cubit DI'da **factory** (`services_locator.dart:197`) → her açılışta yeni örnek + yeni realtime aboneliği.
- Yerel state: `_selectedYear = now.year.toString()` (`:24`), `_customDateRange = null` (`:25`); `availableYears` = yıl, y-1, y-2 (`:39-43`) — **body tarafından hiç okunmuyor**, sheet kendi listesini kuruyor (`:428-432`).
- `initState` post-frame → `filterByYear(_selectedYear)` (`:74-82`).
- AppBar: title `'السحوبات'`, bg `AppColors.background` (`:87-89`); actions: ① `if (!isLocal)` `IconButton(Icons.person_add_alt_1, 22, tooltip 'إضافة شريك', bg primary α0.1, fg primary)` → `AddUserDialog` (`:91-111`; `hasPartners` değişkeni hesaplanıyor ama kullanılmıyor — `:96`, koşullu render satırları `:97`/`:111` yorumlu); ② `_WithdrawalsDateFilter` chip (`:115-134`, `:371-478`).
- Tarih callback'leri: yıl → `filterByYear(year)` (`:120-123`), aralık → `filterByDateRange(start, end)` (`:124-127`), temizleme → mevcut yıl için yeniden `filterByYear` (`:128-132`). Custom seçici `showDateRangePicker(firstDate: 2020, lastDate: 2030)`, başlangıç mevcut aralık ya da son 30 gün, tema AppBar bg primary (`:449-472`). Chip etiketi custom ise `'d/m - d/m'`, değilse yıl (`:388-390`); kutu padding h12/v7, radius 20, bg primary α0.1, border primary α0.2, `Icons.calendar_today` 16, 13 px w500 primary.
- Body `SafeArea → BlocConsumer` (`:139-204`), içerik `SingleChildScrollView(padding all 12)` — **`RefreshIndicator` yok (grep: 0)**.
  - `WithdrawalInitial|WithdrawalLoading` → ortalanmış spinner (`:161-162`). **`:192-198` ikinci loading dalı ulaşılamaz.**
  - `WithdrawalsLoaded` + `partners.isEmpty` → `_buildEmptyPartnersState` (`:231-274`): `Icon(Icons.people_outline, 64, textSecondary)` + `'لا يوجد شركاء'` (18 px w600) + `'أضف شريكاً للبدء'` (14 px textSecondary) + `if(!isLocal)` `ElevatedButton.icon(Icons.add, 'إضافة شريك')` (bg primary, beyaz), üstte 60 px boşluk.
  - `partners` dolu → şerit: partner chip'leri → 12 px → `SummaryCardsWidget` → 12 px → `MonthlyChartWidget(monthlyData)` → 12 px → `WithdrawalsTableWidget(withdrawals, partners, onDelete: cubit.deleteWithdrawal, onTap: no-op)` (`:173-190`).
  - `WithdrawalError` / `WithdrawalSuccess` → gövde `SizedBox.shrink()` (`:199-200`) — **yalnız snackbar**; hata anında sayfa beyaz kalır (gider modülündeki `:228-229` ile aynı desen).
  - Listener: `WithdrawalSuccess` → `Colors.green`, 2 sn; `WithdrawalError` → `AppColors.error (0xFFEF4444)`, 2 sn (`:142-158`).
- Partner chip'leri (`:276-332`): `SizedBox(height 40)` yatay ListView, ilki `'الكل'` (`selectedPartnerId == null` → `filterByPartner(null)`), padding h16/v8, radius 20, seçili bg primary/beyaz, değilse bg surface + border divider, 13 px w500.
- FAB (`:207-227`): `FloatingActionButton.extended('إضافة سحب' (AppColors.surface), bg primary)` → `AddWithdrawalDialog(users: partners'tan üretilen {id: {name, phone}} haritası)` (`:351-368`), `onSave → cubit.createWithdrawal`.

**`WithdrawalCubit`** (`bloc/withdrawal_cubit.dart`, 255 satır): constructor `WithdrawalInitial()` → hemen `emit(WithdrawalLoading())` → `Future.delayed(100 ms)` → `_startRealtimeListeners()` (`:17-26`). **Tek veri yolu stream; one-shot `getWithdrawals/getPartners` hiç çağrılmıyor.**
- `_startRealtimeListeners` (`:35-66`): `watchWithdrawals()` + `watchPartners()`; `Left` → `WithdrawalError(failure.message)` (ham Arapça repo mesajı), `Right` → cache + `_applyFilters()`.
- `_applyFilters` (`:68-102`): partner → yıl (`int.parse(_selectedYear!)` — sayısal olmayan yıl fırlatır, `:79-84`) → tarih aralığı (her iki uç dahil, `:86-96`) → **`_allWithdrawals` listesi yerinde (in-place) sort ediliyor; paylaşılan listeye aliasing yan etkisi (`:99`)**.
- `_emitLoadedState` (`:115-134`): `totalAmount` fold, `totalCount`, `averageAmount = total/count or 0.0`; `monthlyData` = `List<double>.filled(12, 0)`, `month-1` kovası (`:136-143`).
- Filtre API: `filterByPartner` (`:145`), `filterByDateRange` (yılı null'lar, `:150`), `filterByYear` (tarihleri null'lar, `:157`), `clearFilters` (`:164`) **çağrılmıyor**; `loadData` (`:104`) yalnız `@Deprecated getWithdrawals` (`:251`) üzerinden, o da dışarıdan çağrılmıyor.
- CRUD (optimistic değil, rollback yok): `createWithdrawal` → başarı `WithdrawalSuccess('تم إضافة السحب بنجاح')` (`:179`, modüldeki tek sabit başarı metni) + `_applyFilters()`; `updateWithdrawal` (`:186`), `deleteWithdrawal` (`:198`), `createPartner` (`:210`), `deletePartner` (`:222`) — **başarı dalında hiçbir şey emit edilmiyor**, yorum: "Real-time stream will automatically update the UI" (`:193,205,217`). Silme sonrası seçili partner silindiyse `_selectedPartnerId` sıfırlanır (`:230-232`). `clearError` (`:237`) hiç çağrılmıyor; `close()` iki aboneliği iptal eder (`:244-249`).
- Durumlar (`withdrawal_state.dart`): `WithdrawalInitial` (`:10`), `WithdrawalLoading` (`:12`), `WithdrawalsLoaded{withdrawals, partners, totalAmount=0, totalCount=0, averageAmount=0, monthlyData=const[], selectedPartnerId, startDate, endDate, selectedYear}` (`:14-37`), `WithdrawalSuccess` (`:82`), `WithdrawalError` (`:91`). **`copyWith` (`:39-65`) hiç çağrılmıyor**; `state.startDate/endDate/selectedYear/totalCount` UI'da okunmuyor.

**Veri katmanı:** tablolar **`withdrawals` ve `partners`** (view/RPC yok). `withdrawal_remote_datasource.dart`:
- `getWithdrawals` (`:28-57`): `from('withdrawals').select().eq('user_id', userId).isFilter('deleted_at', null)` + opsiyonel `.eq('partner_id')` (`:41-43`) + `.gte/.lte('withdrawal_date', ISO)` (`:44-49`) + `.order('withdrawal_date', desc)`; `userId` null → `Exception('User not logged in')` → `exceptionToFailure` → `ServerFailure('خطأ داخلي في الخادم')`. **Hiç çağrılmıyor.**
- `watchWithdrawals` (`:74-96`): `from('withdrawals').stream(primaryKey:['id']).eq('user_id', userId).order('withdrawal_date', desc)` — **`deleted_at` filtresi YOK** (`:39` ile tutarsız); partner filtrelemesi istemcide (`:90-92`). **Gerçek Supabase Realtime.**
- `watchPartners` (`:98-111`): `from('partners').stream(primaryKey:['id']).eq('user_id', userId).order('created_at', desc)`.
- Insert (`:114-135`): `copyWith(userId: currentUserId)` zorunlu → `insert(toMap()).select().single()`; anahtarlar `user_id, partner_id, amount, description, withdrawal_date, payment_method, notes, created_at, updated_at, deleted_at`. Update (`:138-151`) ölü yol. **Delete hard** `delete().eq('id')` (`:154-160`) — soft-delete kolonu var ama hiç yazılmıyor.
- Partner (`:163-215`): `getPartners` ölü; `createPartner` → `insert({...toMap, 'user_id'})`, anahtarlar `name, phone, created_at, updated_at`; `deletePartner` hard delete.
- Repository (`withdrawal_repository.dart`): 8 future metodun hepsinde `networkInfo.isConnected` kapısı → offline `Left(NetworkFailure.noConnection())` = `'لا يوجد اتصال بالإنترنت'` (`:14-132`); **`watchWithdrawals/watchPartners` (`:134-150`) bağlantı kontrolü yapmaz**, yalnız kurulum hatasını `Stream.value(Left(...))` olarak döner. **Kasa çıkışlarında sqlite cache/queue YOK** (`app_database.dart:26-85` içinde withdrawal/partner tablosu yok; `data/` altında local datasource yok).

**Modeller:** `Withdrawal` (`withdrawal.dart:4-28`): `id`, `userId`, `partnerId?`, `amount`, `description?`, `withdrawalDate`, `paymentMethod default 'cash'`, `notes?`, `createdAt`, `updatedAt`, `deletedAt?`; `toMap` `id` içermez (`:73-86`); `fromMap` (`:88-102`): `amount (?? 0).toDouble()`, `payment_method ?? 'cash'`, `withdrawal_date/created_at/updated_at` **korumasız `DateTime.parse`**. `Partner` (`partner.dart:4-16`): `id, name, phone?, createdAt, updatedAt?`; `toMap` `id` ve `user_id` içermez (`:37-44`); `fromMap` `DateTime.parse(map['created_at'])` korumasız. Hesaplanmış getter yok.

**Widget'lar (canlı):**
- `SummaryCardsWidget` (`summary_cards_widget.dart`): **iki kart** — `'إجمالي'` (`AppUtils.formatNumber(totalAmount)` + `' <sembol>'`, değer `AppColors.primary`) ve `'المتوسط'` (aynı format, değer `AppColors.text`) (`:27-41`); `totalCount` parametresi alınıyor ama **render edilmiyor** (`:8`). Kart: surface bg, border divider, radius 12, padding 12; başlık 10 px w600 textSecondary `letterSpacing 0.5`; değer 18 px w700; `Row` aralık 5; `LayoutBuilder` constraints'i kullanılmıyor (`:22-24`).
- `MonthlyChartWidget`: **fl_chart `BarChart`**. Boş (list yok/hepsi sıfır) → padding 20, radius 12, `'لا توجد بيانات للعرض'` 13 px (`:17-34`). Kart padding 20, radius 12, border divider; başlık `'السحوبات الشهرية'` 16 bold; `SizedBox(height 200)`; `spaceAround`, `maxY = max*1.2` else 100; 12 grup `x=index`, rod `toY=values[index]`, `AppColors.primary`, genişlik 12, üst radius 4; tooltip `padding 8`, `margin 8`, içerik yalnız `NumberFormatter.format(rod.toY)` (beyaz bold 12) — **ay adı yok**; alt eksen `(index+1).toString()` (**sayı, ay adı değil**) 10 px w500, reservedSize 25; sol eksen `_formatCompactNumber` (`≥1e6 → x.xM`, `≥1e3 → x.xK`) 10 px textSecondary, reservedSize 40, 0 atlanır; ızgara `maxY/5`.
- `WithdrawalsTableWidget` (**adı table ama dikey kart listesi**; kolon başlığı/flex tablo yok): `ListView.separated(shrinkWrap, NeverScrollable, separator 10)` (`:30-40`). Satır: radius 12, surface, border divider; `InkWell` → `WithdrawalDetailDialog.show(context, withdrawal, partner)` (`:55-57`, `:208-210`); padding `fromLTRB(14,12,6,12)`; sol Expanded: partner adı 14 w600 ellipsis veya `'-'` (`:62-75`), `Icons.calendar_today` 11 + `DateFormat('yyyy-MM-dd')` 11 px secondary (`:77-91`), varsa `Icons.notes` 11 + description 11 px ellipsis (`:92-111`); sağ kolon: `'${AppUtils.formatNumber(amount)} <NumberFormatter sembolü>'` 15 px w700 **`AppColors.primary`** (`:120-127`), `Icons.delete_outline` 18 `AppColors.error` + padding 4 (`:129-139`). Boş liste → padding 32 kutu `'لا توجد سحوبات'` 14 px textSecondary (`:188-206`). `onTap` parametresi (`:14`) hiç çağrılmıyor. Silme onayı (`:153-178`): `'تأكيد الحذف'` / `'هل أنت متأكد من حذف هذا السحب؟'` / 24 px / `'إلغاء'` (TextButton) + `'حذف'` (ElevatedButton bg `AppColors.error`).
- `WithdrawalDetailDialog` (**tekil dosya canlı**; `withdrawal_detail_dialog.dart`): `Dialog(radius 12)` padding 24; `'تفاصيل السحب'` 18 bold + close (bg background); blok bg primary α0.1 radius 8: `'المبلغ'` 12 + `'<sembol> <tutar>'` 20 bold primary; `_buildInfoRow` (ikon 18, etiket 12 textSecondary, değer 14): `'الشريك'` = `partner?.name ?? '-'`, `'التاريخ'` = `DateFormat('yyyy-MM-dd')`, `'الوصف'` = description veya `'-'`; tam genişlik `'إغلاق'`. **`notes` gösterilmiyor** (ölü çoğul dialog gösteriyor).

### 5.27 DLG-31 … DLG-35 (kasa çıkışları)

| ID | Tetikleyici | Bileşen / geometri | Alanlar, validator'lar, butonlar |
|---|---|---|---|
| DLG-31 | AppBar `Icons.person_add_alt_1` / boş durum butonu | `AddUserDialog` → `Dialog(radius 12, width 400)` padding 24 | Başlık **`'مستخدم جديد'`** ("yeni kullanıcı") 18 w600 + close 20 — **aslında `partners` satırı oluşturuyor** (etiket/işlev uyuşmazlığı). Alanlar: `'الاسم الكامل *'` (hint `'الاسم الكامل'`, validator `'الاسم الكامل مطلوب'`), `'الهاتف *'` (`keyboardType phone`, hint **`'+966-5X-XXX-XXXX'`**, validator `'الهاتف مطلوب'`) — ama çağıran boş telefonu `null` sayıyor (`withdrawals_page.dart:342`) → **zorunlu gösterilen alan fiilen opsiyonel**. Input: fill surface, contentPadding h14/v10, radius 8, focus border primary 1.5. Butonlar `'إلغاء'` (Outlined, border divider) + `'حفظ'` (Elevated primary, elevation 0). `_submit` async/loading durumu yok; kullanılmayan `flutter/services.dart` importu (`:2`) |
| DLG-32 | FAB `إضافة سحب` | `AddWithdrawalDialog` → `Dialog(radius 12, width 450)` padding 24 | Başlık **`'إضافة دفعة جديدة'`** ("yeni ödeme") 18 w600 + close. Alan sırası: ① `'المستخدم *'` — `DropdownButton<String>` hint `'اختر المستخدم'`, items `widget.users` haritasından `value['name'] ?? '-'` (**seçilen "kullanıcı" aslında partner id'si**) ② `'المبلغ *'` (`keyboardType number`, hint `'0.00'`, **`prefixText: '﷼ '` sabit — NumberFormatter sembolü değil**, validator `'المبلغ مطلوب'` / `'أدخل رقماً صحيحاً'`; **negatif/sıfır kontrolü yok**) ③ `'التاريخ'` inline picker (default now, `dd.MM.yyyy`, `showDatePicker(2020→2030)`) ④ `'الوصف'` (hint `'أدخل الوصف...'`, `maxLines 2`) ⑤ `'ملاحظات'` (hint `'ملاحظات إضافية...'`, `maxLines 3`). Butonlar `'إلغاء'` / `'حفظ'`. `_submit`: kullanıcı seçilmediyse `SnackBar('يرجى اختيار المستخدم')` (varsayılan stil) ve return; model `partnerId = seçilen`, **`userId` alanına da seçilen partner id'si yazılıyor** (`:57-58`), `paymentMethod: 'cash'` sabit, `amount: double.parse` → `onSave` + pop |
| DLG-33 | Tablo satırı | `WithdrawalDetailDialog` (bkz. 5.26) | `'تفاصيل السحب'` + `'المبلغ'`/`'الشريك'`/`'التاريخ'`/`'الوصف'` + `'إغلاق'` |
| DLG-34 | Tablo satırı silme ikonu | `AlertDialog` | `'تأكيد الحذف'` / `'هل أنت متأكد من حذف هذا السحب؟'` / `'إلغاء'` / `'حذف'` (bg `AppColors.error`) |
| DLG-35 | AppBar tarih chip'i | `DateFilterSheet` + `showDateRangePicker(2020→2030)` | bkz. 5.21 |

**Ölü bileşenler (modülde 10 dosya — grep ile doğrulandı, hiçbir sayfa instantiate etmiyor):** `WithdrawalsAppBar` (`withdrawals_app_bar.dart`; `AppBar('السحوبات', actions:[Icons.filter_list])` — sayfa kendi AppBar'ını kuruyor), `HeaderWidget` (`subtitle`/`icon` ölü parametre), modül `EmptyStateWidget` (`Icons.account_balance_wallet_outlined` 64 + `'لا يوجد سحوبات'` + `'أضف سحب جديد للبدء'`; **adı `core/widgets/common_widgets.dart:179` ile çakışıyor**), `WithdrawalCard` (leading `CircleAvatar(Colors.orange.shade100)`, `'التاريخ: <toString().split(' ')[0]>'`, **`'طريقة الدفع: cash'` çevirisi yapılmıyor**, `'${amount.toStringAsFixed(2)} ل.س'` — NumberFormatter'ı atlıyor), `WithdrawalDetailsDialog` (**çoğul**; `'تفاصيل السحب'`, notlar satırı var, sabit `'ل.س'`), `WithdrawalListWidget` (bu üçlünün tek tüketicisi), `ViewModeSelector` (`enum ViewMode {table, cards}`, butonlar `'جدول'` / `'حسب المستخدم'`, aktif bg `0xFFEFF6FF` + border primary 2 — **canlı UI'da görünüm geçişi ve kalıcılığı yok**), `WithdrawalsCardsWidget` (partner bazlı gruplama, `maxCrossAxisExtent 320`, avatar `0xFFEFF6FF`, `_formatCurrency = NumberFormat('#,##0.00','tr_TR') + ' ﷼'` — **Türk locale + riyal işareti sabit**, `'غير معروف'` fallback, `LinearProgressIndicator` primary, `onTap` boş), `FiltersWidget` (`'الفترة'`, `'سنة'`/`'مخصص'`, `'السنة'` dropdown, `'نطاق التاريخ'`, hints `'البداية'`/`'النهاية'`, `dd.MM.yyyy`, reset butonu yok), `UserSelectorWidget` (`'إضافة / اختيار مستخدم'`, `'بحث...'`, `'إضافة جديد'`, max yükseklik 220, gölge `Colors.black α0.06 blur 12 offset(0,4)`; **kendi başınaSupabase sorgusu yok**, `partners` prop olarak geliyor).
**Para birimi gösterimi modülda 4 farklı:** `AppUtils.formatNumber` + prefs sembolü (canlı kartlar/tablo), `toStringAsFixed(2) + ' ل.س'` (ölü kart/dialog), `NumberFormat('#,##0.00','tr_TR') + ' ﷼'` (ölü kartlar), sabit `'﷼ '` prefix (canlı DLG-32). **Doğrulandı — yeniden yazımda tek metoda indirilmeli.**

### 5.28 Ekran kapsama kontrolü

Bölüm 5.1 tablosundaki 24 kimlikten 24'ü belgelendi (`InvoiceManagementPage` ölü kod olarak işaretli). Dialog/bottom-sheet kimlikleri DLG-01…DLG-35 + BSH (tarih sheet'i) kapsamında 5.8, 5.12, 5.16, 5.18, 5.21, 5.24, 5.27'de listelendi. **Kalan bölüm yok; 6→16 arasına geçiliyor.**

### 5.29 Düzeltme — SCR kimlik numarası sapması

Bölüm 5.10'dan itibaren yazılan başlıklardaki SCR numaraları, 5.1 kimlik tablosuyla **çakışıyor** (ör. 5.10 başlığı `SCR-011 CustomersPage` der, 5.1 tablosunda müşteriler **SCR-015**; 5.14 başlığı `SCR-014 CustomerDetailPage` der, 5.1'de **SCR-023**; 5.17 başlığı `SCR-014 ProductsPage` der, 5.1'de **SCR-014** ama "Ürünler" satırı SCR-014, 5.6 başlığı da SCR-004 olarak tekrar kullanılmış). **Kanonical kimlik = 5.1 tablosu.** Bölüm 6 ve sonrası 5.1'i kullanır; 5.x başlıkları yalnız bölüm içi referanstır ve sınıf adıyla birlikte okunmalıdır. **Doğrulandı** (başlık/tablo karşılaştırması). Ayrıca 5.21'de anlatılan tarih sheet'i ekran-özel **değil**, ortak `lib/core/widgets/date_filter_sheet.dart` — kesin geometri 6.8/BSH-01.


---

## 6. Her ekranın görsel spesifikasyonu

### 6.0 Bu bölümün veri kaynağı ve sınırları

| Konu | Durum |
|---|---|
| Tüm renk/boyut/typography değerleri | **Koddan tanımlı**. Kaynak: `lib/core/constants/app_constants.dart` (tamamı okundu), `lib/core/theme/app_theme.dart` (tamamı okundu), her ekranın widget ağacı (Bölüm 5'te satır satır referanslı). **Doğrulandı** |
| "Ekrandan ölçülen" değerler | **YOK**. Bu doküman boyunca hiçbir ekran çalıştırılıp ekran görüntüsü alınmadı, pixel ölçümü yapılmadı. Kullanıcıdan runtime screenshot gelmediği sürece 6. altındaki hiçbir sayı "gözlemlenmiş" değildir. **Bilinmiyor → Bölüm 15/ID-06** |
| Satır yüksekliği (`height:`) | Kodda **hiçbir `TextStyle` `height` (lineHeight) parametresi vermedi** → Material varsayılanı (`fontFamily` metrikleri) uygulanır. Kesin çizgi yükseklikleri **Bilinmiyor**. **Doğrulandı** (grep: 0 sonuç) |
| Gerçek render edilen font | Aşağı 6.2'deki çakışma nedeniyle **Bilinmiyor** (runtime screenshot gerek). |
| Animasyon/geçiş süreleri | Yalnız 1 adet kodda tanımlı (6.7). Route geçiş süreleri Material `MaterialPageRoute` varsayılanı (300 ms) — **Çıkarım**, kodda override yok. |

### 6.1 Renk paleti (token bazında)

`AppColors` — `lib/core/constants/app_constants.dart:7-31`. Kullanım sayıları `grep -r` ile `lib/` üzerinde ölçüldü (kaynak-kod referansı, runtime boyama sayısı değil).

| Token | HEX | Yorum satırındaki tanım | Kullanım | Not |
|---|---|---|---|---|
| `background` | `#FFFFFF` (yazım: `Color.fromARGB(255,255,255,255)`) | "Açık gri beyaz" | 89 | **Çelişki:** yorum gri der, değer saf beyaz; üstelik `surface` ile **birebir aynı renk**. Yani `background`/`surface` ayrımı görsel olarak etkisiz. **Doğrulandı** |
| `surface` | `#FFFFFF` | "Saf beyaz" | 140 | Kartlar, AppBar, dialog, input fill |
| `text` | `#1A1A2E` | "Koyu gri-siyah" | 149 | Metin + SnackBar arka planı |
| `primary` | `#0F1B3D` | "Mavi" (koyu lacivert) | **313** | Birincil: buton, aktif sekme, rakamlar, avatar. Alternatif `#1D4ED8` yorumda satırda bırakılmış (`app_constants.dart:20`) |
| `success` | `#10B981` | Yeşil | 28 | Ödendi rozeti, başarı snackbar |
| `warning` | `#F59E0B` | Turuncu | 8 | Borç rozeti, silme uyarı ikonu (`Colors.orange[600] = #FB8C00` ile **karışıyor**, bkz. 5.12 DLG-13) |
| `error` | `#EF4444` | Kırmızı | 74 | Silme butonları, hata metinleri |
| `textSecondary` | `#6B7280` | Gri | 287 | Etiketler, hint, ikincil değer |
| `divider` | `#E5E7EB` | Açık gri | 97 | Ayraç + kart border (tema) |
| `border` | `#D1D5DB` | Kenar grisi | 131 | Input/select border |
| `secondary` | = `textSecondary` (`#6B7280`) | alias | 8 | |
| `info` | `#1E3A5F` | alias | 3 | |
| `accent` | = `primary` (`#0F1B3D`) | alias | 4 | |

**Token dışı renkler (ekranlarda sabit yazılmış):** `Colors.grey` ve tonları 79 kez — başlıca `Colors.grey[100] #F3F4F6` (arama kutusu zemini, 5.10), `Colors.grey[50] #FAFAFA` (kart alt bilgi bloğu), `Colors.grey[600] #757575` (hint/telefon), `Colors.grey[700] #616161`; `Colors.white` 72, `Colors.black` 27. Ayrıca `#EFF6FF` (açık mavi) aktif-seçim zemini olarak withdrawals + dashboard alt navigasyonda tekrar ediyor. **Doğrulandı** — yeniden yazımda bu hardcode tonlar token'a alınmalı.

### 6.2 Tipografi — iki kaynağın çakışması

| Katman | Tanım | Etki |
|---|---|---|
| Global `MaterialApp.theme.textTheme` | `main.dart:46-48`: `AppTheme.lightTheme.copyWith(textTheme: GoogleFonts.changaTextTheme())` | **Çanga** fontunu tema metin stillerinin tamamına yazar. `AppTheme._buildTextTheme` içindeki Cairo tanımı (`app_theme.dart:161` ve sonrası) bu satırla **komple geçersiz kılınır** → ölü kod. **Doğrulandı (kod); hangi fontun ekranda göründüğü → Bilinmiyor** |
| Ekran bazında `GoogleFonts.cairo(...)` | `app_theme.dart` içinde 25 kullanım + bileşen temalarında (AppBar title, ElevatedButton, Input label/hint, Dialog title/content) | Bu stiller **Cairo** kalır. Yani: tema bileşen stilleri Cairo, ham `Theme.of(context).textTheme.*` kullanımları Çanga. Kodda yalnız 12 `Theme.of(context).textTheme` referansı var → çoğu ekran stilleri elle `TextStyle(...)` kuruyor. **Doğrulandı** |
| `AppFonts.arabicFont = 'Cairo'` / `latinFont = 'Inter'` | `app_constants.dart:203-204` | **0 kullanım** — sabitler hiç okunmuyor. **Doğrulandı** |
| `AppTheme.latinTextStyle` / `latinNumberStyle` (`GoogleFonts.inter`) | `app_theme.dart:241-252` | **0 kullanım** → ölü. Sayısal/latin içerik için ayrı font uygulandığı iddiası **yanlış**. **Doğrulandı (grep)** |
| PDF | `PdfGoogleFonts.amiriRegular()/amiriBold()` (8 çağrı, `pdf_invoice_service.dart:17-18,55-56,84-85,211-212`); `stock` PDF'i de Amiri | Uygulama içi fontlardan bağımsız üçüncü font ailesi. **Doğrulandı** |

Boyut tokenları (`AppFonts`, `app_constants.dart:207-213`) ve `lib/` kullanım sayıları — yeniden yazımda birebir bu ölçek kullanılmalı:

| Token | px | Kullanım | Tipik yer (Bölüm 5 referansı) |
|---|---|---|---|
| `fontSizeSmall` | 12 | 94 | Rozet, etiket, ikincil açıklama (5.11 DebtCard, 5.26 tablo) |
| `fontSizeMedium` | 14 | 89 | Gövde metni, input, buton, telefon |
| `fontSizeLarge` | 16 | 14 | Kart başlığı (5.10 `CustomerCard` isim 18 ile karışık), sekme |
| `fontSizeXLarge` | 18 | 13 | Kart adı, rakam vurgusu |
| `fontSizeXXLarge` | 20 | 12 | Dialog/sayfa başlığı, `'خطأ'`, `'لا توجد ديون مستحقة'` |
| `fontSizeXXXLarge` | 24 | 2 | Büyük başlıklar |
| `fontSizeDisplay` | 32 | 1 | Yalnız tema displayLarge |
| `fontWeightRegular` w400 | — | 8 | |
| `fontWeightMedium` w500 | — | 50 | İstatistik etiketi |
| `fontWeightSemiBold` w600 | — | 94 | Değerler, kart başlıkları |
| `fontWeightBold` w700 | — | 30 | Dialog başlıkları, logo başlığı |

**Çelişki:** birçok ekran token yerine literal `fontSize: 20, fontWeight: FontWeight.bold` yazıyor (ör. `login_form.dart:60-63` `'إراد'` 25/bold; DLG-11 başlığı 20 bold). Sonuç: aynı "başlık" kavramı 18/20/24/25 px arasında değişiyor. **Doğrulandı.**

### 6.3 Ölçü tokenları (boşluk, radius, gölge)

`AppConstants` — `app_constants.dart:110-155`. Kullanım sayılarına göre **canlı/ölü** ayrımı yapıldı (canlı = en az bir kez referans verilmiş).

| Token | Değer | Kullanım | Durum |
|---|---|---|---|
| `borderRadius` | 8.0 | **143** | canlı — varsayılan radius |
| `borderRadiusLg` | 12.0 | 31 | canlı — dialog/istatistik kartı/`DebtCardWidget` |
| `borderRadiusMd` | 8.0 | 21 | canlı (`borderRadius` ile aynı değer — anlamsız ikilik) |
| `borderRadiusSm` | 4.0 | 3 | canlı |
| `spacingMd` | 16.0 | 27 | canlı |
| `cardPadding` | 20.0 | 12 | canlı |
| `cardElevation` | **0.0** | 15 | canlı — uygulama **düz/flat**, gölge yok |
| `spacing` | 8.0 | 7 | canlı (`CustomCard` margin) |
| `spacingLg` | 24.0 | 3 | canlı |
| `spacingXs` / `spacingSm` / `spacingXl` | 4 / 8 / 32 | 0 | **ölü** |
| `gap` / `gapSmall` / `gapLarge` | 16 / 8 / 32 | 0 | **ölü** |
| `contentPadding` | 24.0 | 0 | **ölü** — sayfa padding'leri elle `EdgeInsets.all(20/24)` yazılıyor |
| `sidebarWidth` | 200.0 | 0 | **ölü** (drawer/sidebar hiç çizilmiyor → 5.25) |
| `minWindowWidth/Height` | 1024×768 | 0 | **ölü** |
| `defaultPageSize`/`maxPageSize` | 20/100 | 0 | **ölü** — kodda pagination yok (Bölüm 10) |
| `lowStockThreshold`/`criticalStockThreshold` | 0.2/0.1 | Bölüm 5.1/5.22'de ayrı hesap | kritik/düşük stok eşikleri için UI'da sabit yüzdelikler kullanılıyor |
| `currencyFormat`/`dateFormat` | `'###,###.##'` / `'yyyy-MM-dd'` | 0 | **ölü** — gerçek biçimlendirme `NumberFormat`/`intl` içinde (Bölüm 9) |

**Gölge:** tek tanımlı gölge `AppConstants.cardShadow` = `Colors.black α0.04, blur 4, offset (0,1)`. `cardElevation = 0` ile birlikte kartlar **pratikte gölgesiz**; Tema `CardTheme.shadowColor: transparent` (6.4). `withdrawals` ölü `UserSelectorWidget` içinde ayrı gölge `black α0.06 blur12 offset(0,4)` var. **Doğrulandı.**

### 6.4 Bileşen temaları (`AppTheme.lightTheme`)

`lib/core/theme/app_theme.dart` — `MaterialApp.theme` üzerinden tüm ekranlara uygulanır. Değerler koddan:

| Bileşen | Parametre | Değer |
|---|---|---|
| Genel | `useMaterial3` | `true` **Doğrulandı** |
| Scaffold | `backgroundColor` | `AppColors.background` `#FFFFFF` |
| AppBar | `backgroundColor` / `elevation` / `centerTitle` / icon & title renk | `surface #FFFFFF` / `0` / `false` / `AppColors.text`; `titleTextStyle` = Cairo **18 w600** `AppColors.text` |
| Card | `color` / `elevation` / `shadowColor` / `shape` / `margin` | `surface #FFFFFF` / `0` / `transparent` / RoundedRectangleBorder radius `AppColors.borderRadius=8`, border `divider #E5E7EB` 1px / `EdgeInsets.zero` |
| ElevatedButton | bg/foreground/elevation/radius/padding/textStyle | `primary #0F1B3D` / `#FFFFFF` / `0` / `8` / `h24 v16` / Cairo **14 w500** |
| OutlinedButton | foreground / border | `AppColors.text` / border `AppColors.border #D1D5DB` |
| InputDecoration | `filled` / fill / radius / border / focused / label & hint | `true` / `surface` / `8` / `AppColors.border` / `primary` **1.5 px** / Cairo **14** `textSecondary`; `contentPadding` `h16 v16` |
| Divider | renk/kalınlık/space | `divider #E5E7EB` / `1` / `0` |
| DialogTheme | bg/radius/elevation/title/content | `surface` / `12` / `0` / Cairo **18 w600** `AppColors.text` / Cairo **14** |
| SnackBar | bg/renk/radius/behavior | `AppColors.text #1A1A2E` / beyaz Cairo **14** / `8` / `floating` |
| BottomNavigationBarTheme | tanımlı | **UYGULANMIYOR** — dashboard alt navigasyonu elle `AnimatedContainer` satırı olarak çiziliyor (5.4). **Doğrulandı, ölü tema** |
| `darkTheme` | — | **YOK**. `MaterialApp` yalnız `theme:` veriyor (`main.dart:46`) → sistem koyu moda geçse de uygulama açık kalır. **Doğrulandı** |

### 6.5 Global yerleşim kuralları

| Özellik | Değer | Kaynak | Not |
|---|---|---|---|
| Yazı yönü | `TextDirection.rtl` **global** | `main.dart:64-67` `Directionality` builder | Tüm ekranlar Arapça; `Directionality` içi `MediaQuery`'yi sarar |
| Locale | `Locale('ar')` | `main.dart:49` | `intl` sayı biçimleri için locale **kullanılmıyor** — `NumberFormat` çağrıları `'tr_TR'` gibi sabitler taşıyor (5.27) |
| Font ölçeği | `textScaler.clamp(min 0.8, max 1.0)` | `main.dart:54-60` | Kullanıcı sistem ayarı >1.0 olsa da metin büyümez; <0.8 küçülmez. **Erişilebilirlik ihlali**, Bölüm 14'te test maddesi |
| Debug banner | kapalı | `main.dart:44` | |
| SafeArea | 10 dosyada | `customers_page.dart:56`, `suppliers_page.dart:57`, `products_page.dart:80`, `expenses_page.dart:168`, `withdrawals_page.dart:139`, `settings_page.dart:46`, `customer_detail_page.dart:498`, `supplier_detail_page.dart:412`, `invoice_detail_page.dart:114`, `product_add_fullscreen_widget.dart:137` | **Dashboard, `CustomerDebtsPage`, `TakrirlerPage`, `CustomerInvoicesPage`, `CustomerInvoiceDetailPage`, `StockTrackingPage`, `LoginView` SafeArea kullanmıyor** → üst durus çubuğu/alt gesture alanı ile çakışma riski. **Doğrulandı (grep); gerçek çakışma → Bilinmiyor (runtime)** |
| Durus barı kontrolü | **YOK** | `SystemChrome` / `AnnotatedRegion` / `SystemUiOverlayStyle` grepleri 0 sonuç | Status bar rengi platform varsayılanı. **Doğrulandı** |
| Breakpoint | `MediaQuery.of(context).size.width < 600` | **yalnız 2 yerde**: `edit_product_add_widget.dart:161` (`isMobile`), `debt_stats_widget.dart:40-44` (padding 16 ↔ 24) | Geri kalan tüm ekranlar tek yerleşim; `AppConstants.minWindowWidth` kullanılmıyor. **Doğrulandı** |
| Platform ayrımı | **YOK** | `kIsWeb` / `Platform.is*` grepleri 0 sonuç | Android/Web/Windows aynı UI. **Doğrulandı**; platform farkları Bölüm 11 |
| Odak/erişilebilirlik | `FocusNode` tanımlı ama sıralama yok; `tooltip`'ler Arapça dışı (`'يحرر'`/`'sil'`, `'Düzenle'`/`'Sil'`) | 5.10, 5.11 | `semantics`/`Semantics` kullanımı yok → ekran okuyucu etiketi üretilmiyor. **Doğrulandı (grep)** |

### 6.6 İkon ve asset envanteri

| Varlık | Kaynak | Değer | Kullanım |
|---|---|---|---|
| `assets/images/logo.png` | yerel dosya | **7.254 B**, 23 Haziran derlenmiş | `AppAssets.logo` → `custom_loading_animation.dart:15` (ölü bileşen), `login_form.dart:56` (**60×60 px**), `app_sidebar.dart:52` (ölü — 5.25). Yani **tek canlı kullanım login ekranı 60×60** |
| `assets/images/log_outline.png` | yerel dosya | **9.667 B** | **Hiçbir kod referansı yok** (grep: 0). **Doğrulandı — asset boşa paketleniyor** |
| `AppAssets.loadingAnimation = 'assets/images/loading.gif'` | sabit | **dosya YOK** (`ls assets/images` yalnız 2 PNG) | Sabitin kendisi de hiç kullanılmıyor. **Doğrulandı** |
| Material Icons | paket | `lib/` içinde **102 benzersiz `Icons.*`** | En sık: `search`, `edit`, `delete`, `add`, `close`, `navigate_before`, `error_outline`, `inventory_2`, `people`, `business`, `location_city`, `location_on`, `warning_outlined`, `account_balance_wallet_outlined`, `receipt_long_outlined`, `payment_outlined` (son ikisinin `icon` parametresi ölü — 5.11) |
| Iconsax | `iconsax` paketi | **14 dosyada** import | Sık: `calendar` 5, `receipt_disscount` 4, `profile_delete` 3, `document_download` 3, `user`/`shop`/`setting_`/`search_normal`/`profile_`/`money_send`/`money_recive`/`box_search`/`box`/`arrow_down_` 2; tekil: `home`, `logout`, `money`, `receipt`, `receipt_text`, `tick_circle` |
| Font asset | yok | `pubspec.yaml` `fonts:` bölümü **boş**; Cairo/Çanga/Inter `google_fonts` ile **çevrimdışı ilk çalıştırmada ağdan** indirilir | Ağ yoksa yazı tipi fallback'e düşer. **Doğrulandı (pubspec:79-80 yalnız `assets/images/`); görsel sonuç → Bilinmiyor** |
| Splash | `flutter_native_splash`? | Windows launcher ikon yolunda ters bölü karakterler (Bölüm 11) | **Doğrulandı** |

### 6.7 Animasyonlar ve geçişler

| # | Yer | Tür | Süre | Eğri | Açıklama |
|---|---|---|---|---|---|
| 1 | `dashboard_page.dart:123-125` | `AnimatedContainer` (alt navigasyon sekme zemini) | **200 ms** | tanımsız → varsayılan `Curves.linear` | `Colors.transparent → AppColors.surface`, radius geçişi |
| — | Kodun geri kalanı | — | — | — | **Başka hiçbir animasyon yok**: `AnimatedSwitcher`, `AnimationController`, `Tween`, `Hero`, `FadeInImage`, `AnimatedOpacity` grepleri 0 sonuç. **Doğrulandı** |
| — | Route geçişleri | `MaterialPageRoute` varsayılan fade+slide | ~300 ms (framework) | framework | Kodde override yok → **Çıkarım** |
| — | `CircularProgressIndicator` | framework içi döngü | framework | — | Loading durumlarında (Bölüm 12) |

**Yeniden yazım notu:** hareket/paralaks talebi yok; tek 200 ms geçişi birebir korunmalı, fazlası spec dışı.

### 6.8 Liste / grid / tablo ölçüleri (ekran bazında)

> Değerler Bölüm 5'ten ve ilgili dosyaların doğrudan okunmasından referanslıdır. Kimlikler **5.1 tablosuna** göredir (5.10 sonrası başlıklardaki SCR numaraları sapmış — bkz. 5.29).

| Ekran / bileşen | Kaynak | Ölçü |
|---|---|---|
| SCR-014 `ProductsPage` listesi | `product_list_widget.dart:97` ve `:146` | `ListView.builder` + **`shrinkWrap: true` + `physics: NeverScrollableScrollPhysics()`** (dış `SingleChildScrollView` içinde kaydırma devre dışı) + `RefreshIndicator(onRefresh: getProducts)`. **GridView DEĞİL** — tek sütun. `ProductCardWidget`: `Container(surface, radius AppConstants.borderRadiusMd=8, border divider)`, `InkWell(radius 8)`, `Padding all(AppConstants.cardPadding=20)`, ad `fontSizeLarge=16` w?/`AppColors.text`, aralar `SizedBox(spacingMd=16)` |
| SCR-015 `CustomersPage` | `customer_list_widget.dart` | `GridView.builder(padding: all(20), crossAxisCount: **1**, childAspectRatio: **1.7**, main/crossAxisSpacing: 16)`; `CustomCard(padding all(16))` → `Card(margin AppConstants.spacing=8, elevation 0, radius 8, border AppColors.border)` + `InkWell(radius 8)`; `CircleAvatar(radius 24, bg primary)` harf 18/bold beyaz |
| SCR-016 `SuppliersPage` | `supplier_list_widget.dart` | `GridView.builder(crossAxisCount: 1, childAspectRatio: **2**)` (müşteriden farklı), padding 20; boş durum ikonu `Icons.business` |
| SCR-006 `CustomerDebtsPage` | `debt_card_widget.dart`, `debt_stats_widget.dart` | `Column` kart listesi (grid yok); kart `Card(margin bottom 10, elevation 0, radius 12, border AppColors.border α0.5)` + `InkWell(radius 12)` + `Padding all(16)`; rozet `Padding h12 v6` radius 8; özet kutusu `padding 16`, zemin `primary α0.1`, radius 8; dış kap `padding width<600 ? 16 : 24`, radius 12 |
| SCR-005 `InvoicesPage` | `invoice_list_widget` (bkz. 5.7) | `ListView.separated` satır kartları; chip filtre satırı `Padding h12 v6` |
| SCR-017 `ExpensesPage` | 5.23 | 4 özet kutusu `padding 16`, radius 8; gider satırları `ListView`, `Divider(divider,1)` |
| SCR-018 `WithdrawalsPage` | 5.26 | özet kartları radius 12; **tablo** satır padding `h12 v10`, başlık satımı `divider` üst border; `fl_chart BarChart` yükseklik **220**, çubuk genişliği sabit |
| SCR-022 `StockTrackingPage` | 5.22 | hareket satırları `ListView`, kart radius 8, padding 12; stok rozeti `success/warning/error` α0.1 zemin |
| SCR-019 `TakrirlerPage` | 5.19 | `Column` 3 × `ReportCard`: ikon kutusu 48×48, radius 8, zemin `#EFF6FF` |
| **BSH-01 `DateFilterSheet` (ortak)** | `lib/core/widgets/date_filter_sheet.dart:16-86` | `showModalBottomSheet` — `isScrollControlled` **parametresi geçilmiyor** → varsayılan `false` (içerik ekran yüksekliğini aşarsa kırpılır); `shape: RoundedRectangleBorder(borderRadius.vertical(top: 20))`; `Padding(bottom: viewInsets.bottom)` → `SizedBox(width: double.infinity)` → `Padding fromLTRB(24,12,24,32)` → `SingleChildScrollView` → `Column(min, start)`; sürme çubuğu `Container(40×4, AppColors.divider, radius 2)`; `'تصفية البيانات'` 18/bold `AppColors.text`; `'اختر السنة أو نطاق تاريخ مخصص'` 13 `textSecondary`; `'السنة'` 13 w600 `textSecondary`; yıl çipleri `Expanded` + `Padding(left: 8, son hariç)` + `Container(padding v12, radius 10, zemin/border: seçili `primary`, değilse `background` + `divider` border)` metin 14 (w600 beyaz / w400 `text`); `'أو'` ayıracı 12 `textSecondary` + iki `Expanded(Divider)` `h12 v16`; `'نطاق تاريخ مخصص'` 13 w600; `من`/`إلى` `_DateField` satırı (`Expanded` + `SizedBox(width: 8)`); `isCustomDateRange` ise `'إلغاء التصفية'` `TextButton.icon(Icons.close 16, foregroundColor AppColors.error)` + `Navigator.pop`. **6 çağrı noktası ortaktır:** `invoices_page.dart:44`, `expenses_page.dart:408`, `withdrawals_page.dart:436`, `stock_tracking_page.dart:172`, `customer_invoice_detail_page.dart:64`, `app_bar_date_filter.dart:70` (bu son widget 5.25'e göre ölü) — yani ekranlara özel tarih sheet'i **yok**, yalnız `availableYears` girdisi değişiyor. **Düzeltme (5.21 için)** |

### 6.9 Ekran bazında görsel harita (hızlı başvuru)

| Ekran (§5.1 kimliği) | Zemin | Üst blok | Birincil renk / tipik görsel unsur |
|---|---|---|---|
| SCR-001 `MainWrapper` | — | geçiş kabuğu, görsel içerik yok | — |
| SCR-002 `LoginPage`/`LoginForm` | `background` | **SafeArea yok**; `Center>SingleChildScrollView(all 16)`; logo 60×60 + `'إراد'` 25/bold + alt başlık `titleMedium` | buton `primary`; input border `border`, focus `primary` 1.5 |
| SCR-003 `DashboardPage` | `background` | üst başlık/arama satırı; **altta 5'li `AnimatedContainer` sekme çubuğu** (200 ms) | aktif sekme `surface` zemin + `primary` ikon/metin |
| SCR-004 `DashboardOverview` | `background` | tarih chip'i (`app_bar_date_filter` ölü) + özet kartları | rakamlar `primary`, durum α0.1 zeminler |
| SCR-005 `InvoicesPage` | `background` | `AppHeader` + arama + filtre chip'leri + FAB | durum rozetleri `success`/`warning`/`error` α0.1 |
| SCR-006 `CustomerDebtsPage` | `background` | **AppBar/başlık/geri butonu YOK** | özet `primary α0.1`; rozet `warning α0.1` / `success α0.1` |
| SCR-007 `SuppliersDebtsPage` | `background` | başlık satırı (5.15) | aynı rozet dili |
| SCR-008 `MorePage` | `background` | ızgara menü kartları | ikon kutuları `#EFF6FF`/`divider` |
| SCR-009/010/011 invoice detail/create/edit | `background` | `AppBar` (tema: surface, elev 0) | buton `primary`; toplam satırı `primary` 18 w700 |
| SCR-012 `ProductAddFullscreenPage` | `background` | SafeArea + özel başlık satırı | form alanları tema input |
| SCR-013 `SettingsPage` | `background` | SafeArea, başlık satırı | satırlar `divider` ayraç, toggle `primary` |
| SCR-014 `ProductsPage` | `background` | SafeArea + başlık/arama + kategori chip'leri + FAB `primary` | kart `surface` + `divider` border, radius 8 |
| SCR-015/016 `CustomersPage`/`SuppliersPage` | `background` | `Container padding all(20)`, zemin `surface`, alt border `divider`; 40 px `#F3F4F6` radius 20 arama yuvası; `IconButton(navigate_before)` | FAB extended `primary`; avatar `primary` |
| SCR-017 `ExpensesPage` | `background` | SafeArea + `AppBar('المصروفات')` | kategori chip'leri `divider` zemin; `fl_chart` çubuklar `primary` |
| SCR-018 `WithdrawalsPage` | `background` | SafeArea + AppBar + tarih chip'leri | özet radius 12; tablo satırı `divider` |
| SCR-019 `TakrirlerPage` | `background` | başlık satırı (SafeArea **yok**) | 3 `ReportCard`, ikon kutusu `#EFF6FF` |
| SCR-020/021 taraf fatura seçici/detay | `background` | arama + `PartyListTile` (SafeArea **yok**) | rozet metni **İngilizce `'sale'`/`'purchase'`**, `InvoiceStatus` yok sayılıyor |
| SCR-022 `StockTrackingPage` | `background` | yıl/çip filtresi (SafeArea **yok**) | stok rozetleri α0.1 |
| SCR-023/024 `CustomerDetailPage`/`SupplierDetailPage` | `background` | SafeArea var, `AppBar` yok (geri ikon satırı) | rakamlar `primary`; ödeme/silme `error` |

### 6.10 Bölüm 6 için doğrulanamayanlar

1. Ekran görüntüsü olmadığı için hiçbir piksel, gerçek font, gerçek satır yüksekliği ve gerçek renk karışımı **ölçülmedi** → ID-06.
2. `google_fonts` ağdan indiği için çevrimdışı ilk açılışta tipografi **bilinmiyor**.
3. `background` ile `surface` aynı HEX olduğundan "kart ayrımı"nının yalnız border ile mi göründüğü **doğrulanamadı**.
4. Çanga/Cairo hangisinin baskın olduğu (12 `Theme.of().textTheme` referansının hangi widget'larda olduğu) runtime'da **doğrulanamadı**.
---

## 7. Etkileşim ve kullanıcı akışları

> Akış kimlikleri `AF-xx`. Her adımda: **kullanıcı eylemi → uygulama tepkisi → değişen state/veri → sonuç (başarı/hata/iptal) → sonraki ekran**. Kaynak dosya/satır referansları Bölüm 5'te; burada tekrarlanmayan her iddia 5.x'te doğrulanmıştır. Etiketler: **D** = Doğrulandı, **Ç** = Çıkarım, **B** = Bilinmiyor.

### 7.1 Oturum ve başlangıç akışları

**AF-01 Soğuk başlangıç / oturum kararı** (D)
1. Kullanıcı uygulamayı açar → `main()` sırası: `initServicesLocator()` → `NumberFormatter.initialize()` → `NumberFormatter.setArabicFormat(true)` → `initializeDateFormatting('en')` → `runApp` (`main.dart:23-34`).
2. Kök `BlocProvider` `AuthCubit.getCurrentUser()` çağırır (`main.dart:32`).
3. `getCurrentUser()` Supabase'ten oturum okur → başarılıysa `AuthSuccess` → `MaterialApp.home = MainWrapper` `DashboardPage` gösterir.
4. Oturum yok/expired ise → `LoginPage` gösterilir.
5. **Ağ yoksa:** `AuthCubit` cache'e (`user_id` shared_preferences) düşer → dashboard açılıp sonra veri çekmede hata durumu görünür. **Ç** (kesin dallanma runtime'a bağlı, B).
6. Sonuç: kullanıcı `DashboardPage` sekme 0'da başlar; geri tuşu dashboard'da uygulamayı kapatır (MaterialRoute kökü).

**AF-02 Giriş (login)** (D)
1. `LoginPage` → `SingleChildScrollView` içinde `LoginForm` (mod: giriş).
2. Kullanıcı e-posta yazar → alan `TextInputType.emailAddress`; `@` içermiyorsa `validate()` anında `'أدخل بريدا إلكترونيا صحيحا'` benzeri Arapça hata (kesin metin 8.1).
3. Şifre yazar (göster/gizle `Icons.visibility(_off)`) → <6 karakterse hata metni.
4. "دخول" (veya proje metni) butonuna basar → `_formKey.validate()` geçerse `context.read<AuthCubit>().login(email, password)`.
5. `AuthLoading` → buton `onPressed: null` (disabled görünüm) + içinde **20×20 `CircularProgressIndicator(strokeWidth: 2)`**; alanlar kilitli değil.
6. Başarı → `AuthCubit.login` `AuthRepository.login` `Right(user)` dönerse **`Authenticated(user)`** emit eder (`auth_cubit.dart:12-19`) → `login_page.dart:26-31` `Navigator.pushReplacement(DashboardPage)`.
   - **Çelişki (D):** `MaterialApp.home` olan `MainWrapper` içindeki kök `AuthCubit` güncellenmez; pushReplacement ile geçildiği için state ağacı atlanır. Uygulama yeniden başlatılana kadar kök cubit `AuthUninitialized`/`AuthError` kalır.
7. Hata (yanlış şifre / ağ) → `AuthError(message)` → **kırmızı snackbar** (`Colors.red`, Arapça `state.message`), kullanıcı aynı formda kalır; buton tekrar aktif.
8. İptal: kullanıcının geri gesture'ı login'de `Navigator.pop` yapmaz (kök route) → uygulama kapanır. **Ç**

**AF-03 Kayıt (register)** (D)
1. Form altındaki toggle `TextButton` → mod `register`'a geçer; şirket adı alanı (`'اسم الشركة'`) görünür olur.
2. "تسجيل" → `AuthCubit.register(...)` → `AuthLoading` (aynı spinner).
3. Başarı → `AuthRegistered` → yeşil snackbar `'تم إنشاء الحساب بنجاح. يرجى تسجيل الدخول.'` + `login_page.dart:39-51` **yeni bir `LoginPage` pushReplacement** yapar → form giriş moduna sıfırlanır, kullanıcı tekrar giriş yapmalı.
4. Hata (e-posta kullanımda / zayıf şifre / ağ) → kırmızı snackbar `state.message`; Supabase'in İngilizce hata metni **Arapça'ya çevrilmeden** gösterilebilir. **B** (kesin metin Supabase yanıtına bağlı → 15).
5. Otomatik oturum açma **yok**.

**AF-04 Şifre sıfırlama talebi (DLG-09)** (D)
1. Giriş modunda "نسيت كلمة المرور؟" tap → `AlertDialog('استعادة كلمة المرور')`.
2. E-posta alanı + `إلغاء` / `إرسال`.
3. `إرسال` tıklanır ve alan **boşsa hiçbir şey olmaz** (dialog kapanmaz, istek gitmez) — sessiz no-op. **D; tasarım hatası**
4. Doluysa: `AuthCubit.forgotPassword(email)` → `AuthLoading` → repository `resetPasswordForEmail`; başarıda `AuthSuccess('تم إرسال رابط استعادة كلمة المرور')` → dialog **anında `Navigator.pop` ile kapanır** (istek sonucu beklenmez, `login_form.dart:226-233`) → `AuthSuccess` dalı yalnız **yeşil snackbar** basar, navigasyon yapmaz (`login_page.dart:30-35`). Başarısızlıkta `AuthError(failure.message)` → kırmızı snackbar. **D**
5. `إلغاء` → `Navigator.pop` → dialog kapanır, form state'i değişmez.
6. `AuthCubit.resetPassword(token, password)` tanımlı ama **UI'dan hiç çağrılmıyor** (grep: 0 çağıran) → şifre sıfırlama bağlantısı uygulamanın içinde tamamlanmıyor; e-postadaki linkin nereye gittiği **Bilinmiyor** → 15. **D (ölü kod)**

**AF-05 Oturum kapatma** (D)
1. `MorePage` → "الإعدادات" → `/settings` (SCR-013) **veya** doğrudan ayarlar kartı.
2. `SettingsPage` logout kartı tap (`settings_page.dart:366`) → `_showLogoutConfirmation` → `AlertDialog`: başlık satırında `Icons.warning_outlined` `Colors.orange[600]` + `'تأكيد تسجيل الخروج'`; gövde `'هل أنت متأكد من تسجيل الخروج؟'`; `إلغاء` / `تسجيل الخروج` (bg `AppColors.error`).
3. `إلغاء` → pop, kalınan yer. 
4. `تسجيل الخروج` → `logout()` → `AuthCubit.logout()` → repository `signOut()` → **`Unauthenticated`** emit (`auth_cubit.dart:30-36`) → kök `MainWrapper` `LoginPage` render eder. `AuthLoading` kısa bir spinner penceresi de çizilebilir (aynı builder `AuthLoading` dalı) → **Ç**. Ayrıca `settings_page.dart:417` dialog'u kapattıktan sonra cubit çağrısı gelir; `SettingsPage` route'unun stack'ten düşmesi `MainWrapper`'ın `home` rebuild'i ile olur → yığın temizliği runtime'da **Bilinmiyor**.
5. Yerel cache (Drift satırları, `user_id` pref) **temizlenmez** → ikinci kullanıcı aynı cihazda giriş yapınca eski `pending_payments` kuyruğu yeniden gönderilebilir. **D (kod), risk → 12.7**

### 7.2 Navigasyon ve sekme akışları

**AF-06 Dashboard sekme geçişi** (D)
1. Alt navigasyon satırında (`dashboard_page.dart:118-160`) 5 `GestureDetector` + `Expanded` hücre.
2. Tap → `setState(() => _selectedIndex = index)` → `AnimatedContainer` **200 ms** ile zemini `transparent → AppColors.surface` geçirir.
3. Body'de index'e göre widget değişir: 0 `DashboardOverview`, 1 `InvoicesPage(isLocal: false)`, 2 `د.عملاء → CustomerDebtsPage(isLocal:false)`, 3 `د.موردون → SuppliersDebtsPage` (yalnız online), 4 `MorePage`.
4. Offline varyantında (`isLocal` dalı) sekme 2 `ديون` olarak `CustomerDebtsPage(isLocal: true)` gösterir → kartta ödeme butonu çizilmez (`showPaymentButton = !isLocal`).
5. Sekme durumu **kalıcı değil** (`SharedPreferences`'a yazılmıyor) → app restart sekme 0'dan başlar. **D**
6. Not: `DashboardPage`'de `AppBar` yok; her sekme kendi başlığını çiziyor → sekmeler arası üst blok yüksekliği tutarsız. **D/Ç**

**AF-07 Named route ile dış ekranlara geçiş** (D)
1. `MorePage` kartları `Navigator.pushNamed(AppRoutes.products | customers | suppliers | expenses | withdrawals | takrirler | settings …)`.
2. `_generateRoute` switch'i (`main.dart:75+`) `MaterialPageRoute` üretir; `invoices` route'unda `BlocProvider(create: (_) => sl.sl<InvoiceCubit>())` ile cubit route'a sarılır.
3. Geri: `Icons.navigate_before` butonu ya da sistem gesture → `Navigator.pop` → önceki ekranda **yeni veri çekilmez** (onlar da kendi cubit/stream'ine bağlı) → realtime stream açıksa liste kendiliğinden güncellenir; kapalıysa bayat kalır. **D (kod), Ç (görsel sonuç)**
4. Drawer/sidebar **yok** (5.25) → ekranlar arası tek geçiş MorePage + dashboard sekmeleri.

### 7.3 Fatura akışları

**AF-08 Satış faturası oluşturma (uçtan uca)** (D)
1. `InvoicesPage` FAB (yalnız `isLocal == false`) → `CreateInvoicePage` push.
2. Sayfa açılırken 4 cubit provider'ı kurulur; `CustomerCubit`/`SupplierCubit`/`ProductCubit` constructor'da realtime stream başlatır → müşteri/ürün listesi `Stream` ile dolar (explicit `getCustomers()` çağrılmaz).
3. Kullanıcı tip seçer (`بيع`) → `CombinedInvoiceInfoWidget` `postFrameCallback` ile `isSale ? cubit.setSupplier(null)` tetikler → **karşı taraf seçimi temizlenir** (D, çelişki: kullanıcı tip değiş toku yaptığında seçili müşteri kalır, alışa geçince silinir).
4. Müşteri arama alanına yaz → `CustomerCubit.searchCustomers(query)` **500 ms debounce** → sonuçlar state'ten filtrelenir, **ilk 10** listelenir.
5. Sonuç tap → `cubit.setCustomer(model)`; alan müşteri adını gösterir.
6. `InvoiceDatesWidget`: `initState.postFrameCallback` → fatura tarihi boşsa bugün yazılır + `setInvoiceDate(now)`; vade boşsa fatura tarihine eşitlenir. Alan `readOnly` → tap → `showDatePicker(first: 2020-01-01, last: 2030-12-31)`; onay → hem metin `yyyy-M-dd` formatında güncellenir hem cubit'e yazılır; iptal → değer değişmez.
7. `ProductAddWidget`: ürün adına yaz → autocomplete sonuçları (`maxHeight 150`) → seç → odak miktara geçer → miktar `digitsOnly` → `إضافة` veya `onSubmitted` → `cubit.addInvoiceItem(item)`; eşleşen ürün yoksa `_confirmAddProduct()` → **`existingProduct!.unit` force-unwrap ile çökme** (D, bug).
8. Kalem listesinde: fiyata tap → inline `TextField` (`^\d+\.?\d{0,2}`) → submit/dışarı tap → `cubit.updateItemPrice(index, price)`; **satırı sağa swipe** (`Dismissible endToStart`, arka plan `AppColors.error`) → `cubit.removeInvoiceItem(index)`.
9. `InvoiceSummaryWidget`: `المجموع الفرعي` hesaplanan; `الخصم` alanına değer + "طبق" (`MaterialButton`) → `cubit.setDiscountAmount(double.tryParse ?? 0)` → `المجموع الكلي` yeniden hesaplanır; `- X <sembol>` kırmızı satır çizilir.
10. `InvoiceActionsWidget`: ödeme durumu dropdown (`مدفوعة نقدا` / `مديون`) → `cubit.setPaymentStatus`.
11. "حفظ" → `cubit.canSaveInvoice` kontrolü (müşteri/tedarikçi + en az 1 kalem + tarih). False → snackbar `'يرجى إكمال جميع الحقول المطلوبة'`, istek gitmez. True → buton içinde spinner + `'جاري...'` → `await cubit.saveInvoice()`.
12. Veri yazımı: `sales_invoices` insert → kalem başına `sales_invoice_items` insert → stok düşümü (`stock_movements` / ürün `current_stock`) → müşteri bakiye RPC'si (**eklemede çağrılıyor mu: 10. bölümde tablo bazında; borç modülünde `update_customer_balance` yalnız silmede çağrılıyor D**).
13. Sonuç: **her durumda** snackbar `'تم حفظ الفاتورة بنجاح'` gösteriliyor (D, bug — cubit hata yerine `InvoiceError` emit edip exception fırlatmıyor, `catch` çalışmıyor). Kullanıcı `pop` ile listeye döner; realtime stream yeni faturayı listeye basar. **D**
14. "حذف" butonu (create sayfasında) → DLG-07 onay → `إلغاء`/`تأكيد` → onaylarsa **yalnız snackbar `'تم حذف الفاتورة'`**, repository çağrısı yok → hiçbir şey silinmez. **D (yarım özellik)**

**AF-09 Alış faturası** — AF-08 ile aynı; farklar: tip `شراء` → `SupplierCubit` sonuçları; tedarikçi seçimi; `purchase_invoices` + `purchase_invoice_items` + alış stoğu **artırır** (yön: D; stok işareti kodda `movement_type` alanı ile). Tedarikçi borcu `suppliers_debts` view'ına yazılır.

**AF-10 Fatura düzenleme** (D)
1. `InvoiceDetailPage` → "تعديل" → `EditInvoicePage(invoice: ...)` push (parametre nesne olarak geçer, route argümanı değil).
2. `initState` → `loadSalesInvoice(id)` / `loadPurchaseInvoice(id)` → `EditInvoiceLoading` → AppBar + spinner.
3. `EditInvoiceLoaded` → 5 blok çizilir (tipler düzenlenemez — `edit_invoice_type_widget` layout'ta yok, D).
4. Kullanıcı kalem ekler/siler, fiyatı `onChanged` ile **anında** `cubit.updateItem(index, …)` yollar (debounce yok).
5. Miktar rozetine tap → DLG-08 `AlertDialog('تعديل الكمية')` → `digitsOnly` → `حفظ` (kalemi günceller, dialog kapanır) / `إلغاء` (pop).
6. "حفظ" → `canSave` = (satışsa müşteri / alışsa tedarikçi) && kalem var && tarih var; sağlanmazsa hata; sağlanırsa `EditInvoiceCubit.saveInvoice()` → datasource **tüm eski kalemleri siler ve yeniden insert eder** → `sales_invoice_items.id` her kayıtta değişir (D).
7. Başarı → `EditInvoiceUpdated` → **iki snackbar** (widget `_'تم تحديث الفاتورة بنجاح'_` + sayfa listener'ı aynı metin) → `Navigator.pop(true)` → detay listesi yeniler.
8. Hata → `EditInvoiceError` → kırmızı snackbar; ekranda kalınır.
9. "إلغاء" → `Navigator.pop(context)` **onaysız** → yapılan tüm düzenlemeler kaybolur. **D**
10. **Eksik:** düzenleme akışında müşteri/tedarikçi bakiye RPC'si çağrılmaz → borç ekranları eski değeri göstermeye devam eder (realtime view yenileyene kadar). **D (kod), görsel sonuç B**

**AF-11 Ödeme durumu güncelleme** (D)
1. `InvoiceDetailPage` → "الدفع"/durum butonu → `PaymentStatusDialog` (DLG-02) veya `InvoiceStatusDialog` (DLG-03).
2. `RadioListTile` × enum; `مدفوعة نقدا` yeşil, `مديون` kırmızı; `تحديث` → `cubit.updatePaymentStatus(...)` optimistic emit → snackbar + detay yeniden çizilir; `إلغاء` → pop, veri değişmez.
3. Sunucu hatası → Arapça snackbar (metinler 5.7) + state geri alınır mı: **B**.
4. **Satış faturasında (D):** `invoice_detail_page.dart:399` → `cubit.updateInvoicePaymentStatusWithBalance(oldInvoice, paymentStatus)` (`invoice_cubit.dart:906-935`): yeni durum `cash` VE eski durum `debt` ise `amountToReduce = remainingAmount>0 ? remainingAmount : totalAmount` hesaplanır ve `update_customer_balance(invoice.customerId!, **-amountToReduce**)` RPC'si çağrılır → müşteri bakiyesi **düşürülür**; ardından `updateSalesInvoice(updatedInvoice)`. Fatura `debt`'e geri alınırsa bakiye **iade edilmiyor** (yalnız tek yönlü ayar). **D — hata/eksik simetri**
5. **Alış faturasında (D):** aynı dialog tedarikçi tarafında `cubit.updatePurchaseInvoice(invoice, optimisticUpdate: true)` çağrılıyor (:409) → **`update_supplier_balance` RPC'si bu yolda hiç çalışmıyor** → tedarikçi borcu değişmeden kalır.
6. Ödeme durumu değişirken UI **optimistic**: `setState` ile yerel model güncellenir (:375-390), sonra snackbar `'جاري تحديث حالة الدفع...'` (:392) → istek sonucu beklenmeden yeni durum gösterilir; hata durumunda geri alma yolu **B** (catch bloğu `InvoiceError('فشل تحديث حالة الدفع: …')` emit ediyor, cubit:933).

**AF-12 Fatura silme** (D)
1. Detay → "حذف الفاتورة" (buton zemini her zaman `primary` — `color` parametresi yalnız border'da, D) → DLG-04 `DeleteInvoiceDialog`: `'هل أنت متأكد من حذف فاتورة #X؟ لا يمكن التراجع عن هذا الإجراء.'`
2. Onay → `cubit.deleteInvoice(...)` → repository: kalem sil → fatura sil → (bakiye RPC'si çağrılıyor mu → Bölüm 10).
3. Başarı → `pop` ile listeye dönüş, realtime stream satırı kaldırır.
4. Hata → `InvoiceError` snackbar, fatura kalır. **D**

**AF-13 Fatura PDF** (D)
1. Detay → PDF butonu → `PdfInvoiceService().generateInvoicePdf(invoice, type)` → `Printing.sharePdf(bytes: ...)`.
2. Sistem paylaşma sheet'i açılır (Android/Web/Windows'ta farklı) → kullanıcı hedef seçer; iptal → uygulama state'i değişmez.
3. Arapça metinler `ArabicReshaper` + `Bidi.logicalToVisual` ile görsel sıraya çevrilir, font `PdfGoogleFonts.amiri*`.
4. Başarısızlık (font indirme/ağ) → exception UI'a yansır mı: **B** (try/catch var mı → 12).
5. Not: `CreateInvoicePage`'de PDF butonu tamamen **yorum satırında** → create'ten PDF alınamaz. **D**

**AF-14 Fatura arama + filtreleme** (D)
1. Liste üstü arama alanı: her tuş değişiminde (debounce **yok**) `cubit.setSearchQuery(text)` → yerel filtre → `InvoiceFiltered` emit.
2. Tip chip'leri [`بيع`,`شراء`] — `'الكل'` seçeneği yorum satırında → **tip filtresi hiç temizlenemez** (D).
3. Ödeme durumu chip'leri [`الكل`,`دين`,`نقدي`] → `cubit.setFilter(...)`.
4. Tarih çipi → `DateFilterSheet` (BSH-01): yıl çipi → `onYearSelected` + `Navigator.pop`; `من`/`إلى` → `showDateRangePicker(2020–2030)` → sheet içinde `setSheetState` ile görünür; `'إلغاء التصفية'` yalnız özel aralık aktifken çizilir → `onClearFilter()` + pop.
5. Sonuç kümesi boşsa → `InvoiceEmptyStateWidget` (`'لم يتم العثور على فواتير'` + `'جرب فلترة مختلفة أو حاول البحث مرة أخرى.'`).

### 7.4 Borç ve ödeme akışları

**AF-15 Müşteri borcuna ödeme kaydetme** (D)
1. `CustomerDebtsPage` (sekme 2 veya `/customer-debts`) → kartta `hasDebt && showPaymentButton` ise "تسجيل دفعة".
2. Tap → `PaymentDialogWidget(debt: ...)`: alanlar tutar (`digitsOnly`), açıklama, ödeme tarihi.
3. Onay → dialog `Navigator.pop` + sayfa callback `await cubit.addPayment(debt.id, amount, note, paymentDate)` → `_showSuccessMessage('تم تسجيل الدفعة بنجاح')` yeşil floating snackbar.
4. `addPayment` → `PaymentProcessing` emit → **builder bu durumu ele almadığı için ekran ödeme süresince boş beyaz olur** (D, çelişki).
5. Online: `payments.insert({user_id, customer_id, payment_type:'customer', amount, payment_date, notes})` + `syncPendingPayments()`.
6. Başarı → `PaymentSuccess` listener → `getCustomerDebts()` → `CustomerDebtLoading` spinner → `CustomerDebtLoaded` yeni bakiye ile.
7. Offline: ödeme `pending_payments` Drift kuyruğuna yazılır, snackbar yine basılır mı → **D/B** (kuyruk yazımı doğrulandı, UI mesajının gerçekliği runtime).
8. Hata → `CustomerDebtError` → hem snackbar hem tam ekran hata bloğu çizilir (**çift gösterim, D**).

**AF-16 Ödeme silme** (D)
1. `CustomerDetailPage` ödeme satırı → sil → onay dialogu (DLG-18/19) → `deletePayment(id)` → `payments.delete().eq('id')` + **`update_customer_balance` RPC çağrılır** (eklemede çağrılmayan durumun tersi, D).
2. Sonuç → borç view'ı realtime yeniler; detay sayfasında spinner.

**AF-17 Taraf detayına geçiş** (D)
1. `DebtCardWidget` gövdesi `InkWell` → `Navigator.push(MaterialPageRoute(CustomerDetailPage(customer: debt, isLocal:)))` — named route **değil**, model nesne olarak geçer.
2. Detayda faturalar/ödemeler listesi + `DateFilterSheet` (ortak BSH-01) + ödeme ekle/sil.

### 7.5 Ana veri CRUD akışları

**AF-18 Müşteri ekle/düzenle/sil** (D)
- Ekle: FAB → DLG-11 `Dialog(height: screenH*0.55)` → `CustomerFormWidget(cubit: ..., onTap: (_) {})` → `إضافة` butonu → validate → `cubit.addCustomer(...)` → dialog **formun kendi `Navigator.pop`'ı ile** kapanır (kaydetme tamamlanmamış). Liste `customers` stream'i ile yeniler.
- Düzenle: kart `Icons.edit` → DLG-12 `Dialog(width 500, height*0.45)` → form `customerModel` dolu, `cubit` null → `onTap` dalı çalışır → `updateCustomer(model)` → `customers.update().eq('id')`.
- Sil: kart `Icons.delete` → DLG-13 uyarı (`'سيتم حذف جميع البيانات المرتبطة بهذا المورd/العميل:'`) → `حذف` → `deleteCustomer(id)`: 4 adımda `sales_invoice_items` → `sales_invoices` → `payments` → `customers`; **transaction yok** → yarı silinmiş veri riski (D).
- `مسح` butonu → `_formKey.currentState.reset()` — controller'ları temizlemez, metinler kalır (D).

**AF-19 Tedarikçi ekle/düzenle/sil** (D) — AF-18 ile aynı; farklar: `deleteSupplier` `purchase_invoices`+`purchase_invoice_items` siler, **`payments` silmez**; DLG-15 `AlertDialog` + `SizedBox(width:500)` + tek `إلغاء`; formda buton çift `validate()` + **koşulsuz `Navigator.pop`** (D).

**AF-20 Ürün CRUD** (D)
1. `/products` → FAB / kategori çipleri / arama (debounce 500 ms; `clearCategoryFilter` metodu var ama çağrılmıyor → kategori filtresi temizlenemez).
2. Ürün formu (DLG-23): ad, birim, kategori, alış/satış fiyatı, açılış stoğu, minimum stok → `addProduct` → `products` insert (+ gerekirse `stock_movements` açılış kalemi; kesin SQL → Bölüm 10).
3. Kart: `Dismissible`/sil ikonu → DLG-25 onay → `deleteProduct(id)` → satış/kalem referansı kontrolü **yok** → FK hatası → `ProductError` snackbar. **B (RLS/FK davranışı sunucu tarafı)**
4. Düzenleme: tam ekran `edit_product_add_widget` değil, ürün dialogu (5.17-5.18).

**AF-21 Gider CRUD** (D) — `/expenses` → DLG-27 form (ad/tutar/tarih/kategori) → `expenses.insert`; kart tap → DLG-28 detay; sil → DLG-29; `DateFilterSheet` BSH-01 ile dönem filtresi; `fl_chart` bar grafiği kategorilere göre yeniden çizilir.

**AF-22 Kasa çıkışı CRUD** (D) — `/withdrawals` → AppBar/çipler → DLG-32 `AddWithdrawalDialog` (ortak/user seçimi DLG-31 `AddUserDialog`) → `withdrawals.insert` → tablo + grafik yeniler; satır tap → DLG-33 detay; sil → DLG-34.
- Ölü `ViewModeSelector` nedeniyle tablo↔kart geçişi **kullanıcıya açık değil** (D).

**AF-23 Raporlar ve PDF** (D)
1. `/takrirler` → 3 `ReportCard`.
2. Taraf raporları: `CustomerInvoicesPage` → müşteri/tedarikçi ara (**debounce yok**) → seç → `CustomerInvoiceDetailPage` → `PartyInvoiceCubit` faturaları listeler → `DateFilterSheet` ile dönem → PDF/indirme (`document_download` ikonu).
3. Stok takibi: `StockTrackingPage` → **repository'yi atlayan 3 paralel query** → hareket listesi + yıl filtresi (yalnızca görsel, `_availableYears` hatası nedeniyle bazı yıllar seçilemez, D) → `generateStockPdf`.

### 7.6 Tercih, senkronizasyon ve kesinti akışları

**AF-24 Para birimi tercihi** (D)
1. `SettingsPage` → para birimi çipleri (`NumberFormatter.availableCurrencies` = `SYP, USD, EUR, TRY`).
2. Tap → `await NumberFormatter.setCurrency(code)` → `selected_currency` pref'e yazar + `setState` → çip zemini `primary`, metin beyaz.
3. **Uygulama yeniden başlatılmaz; sayfa yeniden çizilen ekranlar yeni sembolü gösterir.** Cache'lenmiş ekranlar (dashboard, borç listesi) sonraki veri çekimine kadar eski sembolü gösterebilir. **Ç**
4. `ل.س`/`﷼` gibi **sabit** yazılmış gösterimler (ölü withdrawal kartları, DLG-32 prefix) tercih değişse de **değişmez** (D).

**AF-25 Sayı kısaltma tercihi** (D)
1. `SettingsPage` "تنسيق الأرقام" kartı: hem `InkWell(onTap: toggle)` hem `Switch(onChanged: toggle)` aynı `setUseShortFormat`'ı çağırıyor → Switch'e doğrudan dokunmak iki handler'ı da tetikleyebilir → **değer iki kez çevrilebilir** (D kod; hangi gesture'un kazandığı → **B**, runtime).
2. `main.dart:27` her açılışta `setArabicFormat(true)` çağrılıp **pref'e yazıyor** → `'use_arabic_number_format'` her zaman `true`; bunu açan UI yok → `_useArabicFormat` dalı (Arapça-Indic rakamlar) varsayılan olarak **her zaman aktif**. **D**
3. Sonuç: `K/M` kısaltması + Arapça rakam glifi kombinasyonu tüm ekranlarda aynı anda geçerli; 4 farklı para birimi gösterim yolu (5.27) bu nedenle ekranlar arasında **tutarsız sayı biçimi** üretiyor. **D**

**AF-26 Realtime senkron** (D)
1. Cubit constructor'ları `_startRealtimeListener()` çağırır → `supabase.stream(primaryKey:['id'])` (gerçek stream) veya `.asStream()` (tek seferlik sahte stream — modüle göre farklı, 10'da tablo).
2. Bir satır insert/update/delete olduğunda → ilgili view/tablo yeniden çekilir → `Loaded` emit → liste güncellenir.
3. `CustomerDebtCubit` özelinde: `sales_invoices` **ve** `payments` olaylarında view yeniden çekilir; `payments` stream'i **kullanıcı ayrımı yapmaz** → başka kullanıcının ödemesi de refresh tetikler (D).
4. Akış hatası repository sarmalayıcıda yutulur (`handleError((_) => null)`) → stream kapanmaz, UI son veride kalır. **Ç**
5. **Düzeltme (önceki iddiaya göre):** 8 cubit'in 8'i de `close()` override edip stream aboneliklerini iptal ediyor (`customer_cubit.dart:111`, `supplier_cubit.dart:110`, `product_cubit.dart:245-249`, `invoice_cubit.dart:937-943`, `expense_cubit.dart:128`, `withdrawal_cubit.dart:248`, `customer_debt_cubit.dart:172`, `supplier_debt_cubit.dart:237`). Sayfaların çoğu `BlocProvider(create: …)` kullandığı için flutter_bloc provider ağaçtan çıkarken cubit'i **dispose eder** → abonelikler kapanır. **İstisna:** `ProductsPage` **3 yerde `BlocProvider.value`** kullanıyor (`products_page.dart:78,236,323`, instance `State`'te tutuluyor, `:33`) ve `BlocProvider.value` dispose **etmez** → `ProductCubit.close()` hiç çalışmıyor → ürün/kategori stream'leri sayfa kapansa da açık kalır (sızıntı). `main.dart` içindeki tek `.value` kullanımı aynı desende. **D — ayrım 10.9'da**

**AF-27 Offline çalışma** (D)
1. `NetworkInfoImpl` (internet_connection_checker) → online olmayan yol: repository **yalnız** fatura/borç/dashboard cache'inden okur.
2. Cache dolu → `Right(cached)` + (modüle göre) offline banner; cache boş → `CacheFailure.notFound()` / `NetworkFailure.noConnection()` → `'لا يوجد اتصال بالإنترنت'` metni.
3. Offline'da FAB'ler gizli (`invoices_page.dart:155`, `isLocal` `CustomersPage` FAB yok) → ekleme yapılamaz.
4. `pending_payments` Drift kuyruğu: çevrimdışı ödeme kaydı kuyruğa yazılır, bağlantı gelince `syncPendingPayments()` gönderir. **D**; kuyruk UI'ıda "başarılı" mı gösteriyor → **B**
5. Ürün/gider/çıkış/rapor/stok modüllerinin cache'i **yok** → offline'da bu ekranlar doğrudan hata gösterir. **D**

**AF-28 Çift tıklama / yinelenen istek** (D/Ç)
1. Loading'de buton `onPressed: null` yalnız login formunda ve `InvoiceActionsWidget`'te (spinner'lı dal).
2. `إضافة` (müşteri/tedarikçi formu) ve dialog butonları **koşulsuz `Navigator.pop`** yaptığı için hızlı çift tıklamada iki insert gidebilir → mükerrer kayıt riski. **Ç (kod kanıtı: debounce/lock yok)**
3. `Dismissible` satır swipe'ı art arda iki kez → index kayması ile yanlış kalem silinmesi riski. **Ç**

**AF-29 Kesinti/iptal** (D)
1. Dialog dışına dokunma → `showDialog` `barrierDismissible` varsayılan `true` → kapanır, istek iptal edilmez (gönderilmişse sunucuda işlenir).
2. `showDateRangePicker`/`showDatePicker` iptali → `null` döner, state değişmez.
3. Sistem geri tuşu: route pop → cubit kapatılmaz, stream açık kalır (AF-26/5).
---

## 8. Formlar ve validasyonlar

> Alan alan döküm. **Global bulgular (Doğrulandı — 13 form dosyasının tamamında grep):** `maxLength` **yok**, `textCapitalization` **yok**, `obscureText` yalnız login şifresinde, `autovalidateMode` **yok** → hiçbir validator yazarken değil **yalnız `validate()` çağrıldığında** çalışır; `onSaved` **yok** → değerler her zaman controller'dan okunur; `enabled: false` **yok** → hiçbir alan sunucu isteği sırasında kilitlenmez (yalnız login butonu ve `حفظ` butonu `onPressed: null`).
> Etiketler: **D**=Doğrulandı, **Ç**=Çıkarım, **B**=Bilinmiyor.

### 8.1 F-01 Giriş / Kayıt formu — `LoginForm` (`lib/features/auth/presentation/widgets/login_form.dart`)

`GlobalKey<FormState> _formKey` (:14); `Form(key:…)` (:51); `validate()` **tek kez** `_submitForm` içinde (:30). Controllers: `_emailController` :15, `_passwordController` :16, `_businessNameController` :17.

| # | Alan (sıra) | Widget / satır | Etiket & ikon | Klavye / maske | Validatör (koşul → **birebir metin**) | Doldurma / düzenleme | Submit'e yazılımı |
|---|---|---|---|---|---|---|---|
| 1 | E-posta | `TextFormField` :76-92 | `labelText: 'البريد الإلكتروني'`, `prefixIcon: Icon(Icons.email)` (**boyutsuz**) :79-82 | `TextInputType.emailAddress` :78 | `value==null \|\| trim().isEmpty` → **`'البريد الإلكتروني مطلوب'`** :84-86; `!value.contains('@')` → **`'البريد الإلكتروني غير صحيح'`** :87-89 — **şekli doğrulamaz** (`a@b` geçer, `@` tek şart) | boş; `.trim()` ile gönderilir :32 | `AuthCubit.login(email, password)` :31-35 |
| 2 | Şirket adı (yalnız kayıt) | `TextFormField` :97-110, koşul `if (!_isLogin)` :96 | `labelText: 'اسم الشركة'`, `prefixIcon: Icon(Icons.business)` :99-102 | tanımsız (varsayılan text) | `!_isLogin && (null \|\| trim().isEmpty)` → **`'اسم الشركة مطلوب'`** :103-108 | — | `register(email, password, businessName)` :36-40 |
| 3 | Şifre | `TextFormField` :115-143 | `labelText: 'كلمة المرور'`, `prefixIcon: Icon(Icons.lock)`, `suffixIcon: IconButton(visibility/visibility_off)` :118-133 | `obscureText: _obscurePassword` :117 | `isEmpty` → **`'كلمة المرور مطلوبة'`** :135-137; `length < 8` → **`'كلمة المرور يجب أن تكون 8 أحرف على الأقل'`** :138-140 | — | trim ** edilmeden** gönderilir :33,:38 |

- **Göster/gizle:** `suffixIcon` → `setState(_obscurePassword = !…)` (:127-131). Tek yönlü toggle, ikon `Icons.visibility` (gizliyken) / `Icons.visibility_off` (açıkken) — **not:** anlamsal olarak ters (gizliyken "göster" ikonu doğru, kod `_obscurePassword ? visibility : visibility_off` → gizliyken `visibility` çizer; tutarlı). **D**
- **Submit:** `ElevatedButton` :147-156, `onPressed: state is AuthLoading ? null : _submitForm` → **tek disable koşulu**; loading'de child 20×20 `CircularProgressIndicator(strokeWidth: 2)`; etiket modda göre `'تسجيل الدخول'` / `'إنشاء حساب'` :155.
- **Toggle:** `TextButton` :160-173 `'ليس لديك حساب؟ إنشاء حساب'` ↔ `'لديك حساب بالفعل؟ تسجيل الدخول'`, `AuthLoading` iken `null`.
- **Şifre sıfırlama:** `TextButton` yalnız giriş modunda :176-186 `'نسيت كلمة المرور؟'`.
- **Odak sırası:** tanımlı değil (DOM sırası: e-posta → şirket → şifre). **D**
- **Temizleme butonu yok**; `_businessNameController` `dispose()`'ta **bırakılmıyor** (:21-25'te yok) → sızıntı. **D**
- Validasyon sırasında hata metni alanın altında Material varsayılan kırmızısıyla çizilir (`InputDecoration.error` tema override'ı yok) → renk `colorScheme.error` (M3 default), `AppColors.error` **değil**. **Ç (tema kodunda hata rengi tanımsız)**
- **B:** Supabase sunucu tarafı politikaları (min şifre, e-posta doğrulama) — kayıt 6-7 karakterli şifreyi client'ta engeller ama sunucu 6 isterse davranış **Bilinmiyor**.

### 8.2 F-02 Müşteri formu — `CustomerFormWidget` (`customer_form_widget.dart`)

`_formKey` :17; `Form` :81; `validate()` **tek** :50 (`currentState!` force-unwrap).

| # | Alan | satır | Etiket / ikon | Klavye | Validatör |
|---|---|---|---|---|---|
| 1 | Ad (zorunlu) | `TextFormField` :89-101 | `اسم العميل *`, `Icon(Icons.person)` (boyutsuz) :93 | varsayılan | `null \|\| trim().isEmpty` → **`'اسم العميل مطلوب'`** :95-99 |
| 2 | Telefon | :105-112 | `رقم الهاتف`, `Icons.phone` :110 | `TextInputType.phone` :107 | **yok** |
| 3 | Şehir | :116-122 | `المدينة`, `Icons.location_city` :120 | varsayılan | **yok** |
| 4 | Adres | :126-133 | `العنوان`, `Icons.location_on` :131 | varsayılan, `maxLines: 2` :128 | **yok** |

- **Formda çizilmeyen ama modele yazılan alanlar (D):** `_codeController` :18 ve `_creditLimitController` :23 tanımlı, `initState`'te modelden dolduruluyor (:29,:34), submit'te okunuyor (:55,:60) → **yeni müşteride `code: ''`, `creditLimit: 0`**; düzenlemede eski değer sessizce taşınır ve değiştirilemez. `currentBalance/totalPurchases/isActive/createdAt/updatedAt/deletedAt` doğrudan modelden kopyalanır (:61-66).
- `id, userId, currentBalance, totalPurchases, isActive, deletedAt` alanlarının **hiç UI'ı yok** (`customer.dart:4-17`).
- `userId` :54 → `… ?? await UserService.getUserId() ?? ''` → oturum yoksa **boş string** yazılır (tedarikçi formunun `userId!` çökmesinin tersi; **politika tutarsızlığı, D**).
- **Butonlar:** `ElevatedButton` etiketi `widget.customerModel == null ? 'إضافة' : 'تحديث'` :139; `TextButton 'مسح'` :143-150 → **yalnız `_formKey.currentState?.reset()`** (:146) → 4 çizili alan `initialValue`'a (`''`) döner, hata metinleri temizlenir; `_codeController`/`_creditLimitController` **temizlenmez**.
- **Sonuç (D):** `cubit != null` dalında `createCustomer(...)` **await edilmeden** çağrılır (:69) ve ardından `Navigator.pop` (:71, `context.mounted` korumalı) → dialog kaydetme bitmeden kapanır, hata `CustomerError` state'inde kalıp görünmez. Ayrıca **var olan müşteri için de `createCustomer` çağrılır** (id kontrolü yok, :69). `cubit == null` (kart düzenleme yolu, `customer_list_widget.dart:248-252`) dalında `onTap(customer)` çağrılır ama **pop yapılmaz** → düzenleme dialogu başarılı olsa bile **açık kalır**. **D**

### 8.3 F-03 Tedarikçi formu — `SupplierFormWidget` (`supplier_form_widget.dart`)

| # | Alan | satır | Etiket / ikon | Klavye | Validatör |
|---|---|---|---|---|---|
| 1 | Ad | :75-87 | `اسم المورد *`, `Icons.business` :79 | varsayılan | `null \|\| trim().isEmpty` → **`'اسم المورد مطلوب'`** :81-86 |
| 2 | Telefon | :89-96 | `رقم الهاتف`, `Icons.phone` :94 | `TextInputType.phone` :91 | **yok** |
| 3 | Şehir | :98-104 | `المدينة`, `Icons.location_city` :102 | varsayılan | **yok** |

- **Çift `validate()` (D):** buton `onPressed` :109-114 `if (_formKey.currentState!.validate()) { _submit(); Navigator.pop(context); }` ve `_submit` içinde tekrar `validate()` :43 → aynı hata metni iki kez üretilir (zararsız, gereksiz).
- `Navigator.pop` :112 **koşulsuz ve kaydetme tamamlanmadan** çalışır; `_submit()` async (:42) ve `createSupplier` await edilmez (:60).
- **Crash (D):** `userId: userId!` :48 — `UserService.getUserId()` null dönerse `Null check operator used on a null value`, **await edilmemiş async fonksiyon içinde** →Unhandled exception; kullanıcı zaten kapanmış dialogu görür.
- **Temizleme butonu hiç yok.** Prefill `initState` :27-31 (`widget.supplier!` null-korumalı).
- Etiket :115 `widget.supplier == null ? 'إضافة' : 'تحديث'`; `isActive/updatedAt` vs. modelden taşınır (:52-56). `SupplierModel`'de `code` **yok** (`supplier.dart:4-12`).

### 8.4 F-04 Ürün formu — `ProductFormWidget` (`product_form_widget.dart`)

`_formKey` :28; `Form` :118; `validate()` tek :76. **En sorunlu form (8 alan).**

| # | Alan | Widget / satır | Etiket / ikon | Klavye / maske | Validatör |
|---|---|---|---|---|---|
| 1 | Ad | `TextFormField` :143-155 | `اسم المنتج *`, `Icons.inventory` :147 | varsayılan | `isEmpty` → **`'اسم المنتج مطلوب'`** :149-153 |
| 2 | Kategori | `DropdownButtonFormField<String?>` :156-179 | `الفئة`, `Icons.category` :160 | — | **yok** (null = `بدون فئة` :163-166) |
| 3 | Satış fiyatı | :183-199 | `سعر البيع *`, `Icons.attach_money` :188 | `TextInputType.number` :185 | `isEmpty` → **`'سعر البيع مطلوب'`**; `double.tryParse==null` → **`'سعر غير صحيح'`** :190-197 |
| 4 | Min. satış fiyatı | :203-211 | `أقل سعر بيع`, `Icons.money_off` :208 | number | **yok** → bozuk metin sessizce `0.0` (:89) |
| 5 | Alış fiyatı | :214-230 | `شراء*`, `Icons.shopping_cart` :219 | number | `isEmpty` → **`'سعر الشراء مطلوب'`**; parse null → **`'سعر غير صحيح'`** :221-228 |
| 6 | Hacim | :232-240 | `حجم`, hint `حجم ` (**sonda boşluk**), `Icons.straighten` :236 | `FilteringTextInputFormatter.digitsOnly` :239 | **yok** — `ProductModel.measurement` `int.parse` ile okunuyor (`product.dart:126`) → boş/bozuk metin ileride çökme riski |
| 7 | Birim (القياس) | `DropdownButtonFormField<String>` :242-255 | `القياس`, `Icons.straighten` :246 | — | **yok** — `_unitController.text`'e yazar (:251-252) |
| 8 | Min. stok | :260-268 | `الحد الأدنى للمخزون`, hint `0`, `Icons.inventory_2` :264 | number | **yok** |

- `ProductUnitData.unitItems` = `كيلوغرام, غرام, ظرف, قطعه, لتر, مل, متر` (`products/data/models/product_unit_data.dart:4-12`; tip `List<DropdownMenuItem<String>>`, `value` = metnin aynısı). **D**
- **Dropdown/reset uyuşmazlığı (D):** `DropdownButtonFormField` deprecated `value:` / `initialValue:` kullanıyor; `initialValue` yalnız `FormField.initialValue` olur. `'مسح'` (:286-291) `reset()` çağırınca (:288) dropdown **ilk build değerine** döner, `_selectedCategoryId` ve `_unitController.text` **kullanıcının seçimini korur** → UI ile gönderilen veri ayrışır (yanlış birim/kategori kaydedilebilir). **Ç (Framework davranışı, `dropdown.dart:1785-1795,1852`)**
- **Düzenlemede birim kaybı (D):** `_loadCategoriesAndInitializeForm` :45-60 içinde satır :58 **koşulsuz** `_unitController.text = ilk birim` atıyor → `widget.product!.unit` (:53) eziliyor; ürünü düzenleyip kaydedince birim `كيلوغرام`'a dönebilir.
- ** üretilmeyen/çizilmeyen alanlar (D):** `_codeController` :29 tanımlı ama **hiç kullanılmıyor**; `code` `now.microsecond.toString()` ile otomatik üretiliyor (:82) → aynı mikro saniyede iki kayıt = çakışma. `barcode`, `currentStock` (submit'te **zorla 0** :91), `maxStock` (null :93), `location`, `notes` formda yok.
- **Yerleşim hatası (D):** `SizedBox(width: 16)` :241 `Column` içinde (Row değil) → işlevsiz dikey-boşluk.
- **Sonuç (D, kritik):** submit butonu :276-284 `onPressed: () { _submitForm(); Navigator.pop(context); }` → `pop` **validasyon sonucundan bağımsız ve koşulsuz**: hatalı girişte dialog kapanır, hiçbir şey kaydedilmez → **sessiz veri kaybı**. `_submitForm` içinde `try { … } catch (e) {}` (:77,:102) hataları **yutuyor**. Kaydetme `onSubmit` → `products_page.dart:149,282` `_productCubit.createProduct(product)` **await edilmez**.
- `Icons.close` başlık satırı :137-140 → koşulsuz pop.

### 8.5 F-05 Kategori formu — `CategoryFormWidget` (`category_form_widget.dart`)

| # | Alan | satır | Etiket / ikon | Validatör |
|---|---|---|---|---|
| 1 | Kategori adı | `TextFormField` :68-81 | `اسم الفئة *`, `OutlineInputBorder()`, `Icons.category` :73 | `null \|\| trim().isEmpty` → **`'يرجى إدخال اسم الفئة'`** :75-80 |

- `_descriptionController` :19 tanımlı, :26 prefill, :43-45 modele yazılıyor ama **çizilmiyor** → yeni kategoriler `description: null`; `parentId`, `sortOrder` hiç UI'da yok; `isActive` **sabit `true`** :46.
- Buton etiketi :96 `widget.category == null ? 'إضافة' : 'حفظ'`; `_saveCategory` :37-59: `validate()` :38 → `createCategory`/`updateCategory` **await edilmez** (:52,:54) → `Navigator.pop` :57 koşulsuz.
- `context.read<ProductCubit>()` :52,:54 → provider yoksa fırlatır (tek çağrı noktası `products_page.dart:323-325` sağlıyor). **D**
- **Düzenleme dalı erişilemez:** `CategoryFormWidget` her zaman `const` ve `category:` verilmeden kuruluyor (`products_page.dart:325`) → `updateCategory` yolu ölü. **D**
- `'إلغاء'` :86-90 yalnız pop; reset yok.

### 8.6 F-06 Gider formu — `ExpenseFormDialog` (`expense_form_dialog.dart`)

Etiketler `labelText` yerine **harici `Text`** (`_buildLabel` :210-219); `validate()` tek :379.

| # | Alan | Widget / satır | İpucu / ikon | Klavye / maske | Validatör |
|---|---|---|---|---|---|
| 1 | **المبلغ \*** | `TextFormField` :112-131 | hint `'أدخل المبلغ'`; `prefixIcon` = **`Text(NumberFormatter.getCurrencySymbol())`** (ikon değil) :120,:227-231, `prefixIconConstraints` min 0×0 | `TextInputType.number` :114; `FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))` :116 | `isEmpty` (**trim yok**) → **`'المبلغ مطلوب'`**; `double.tryParse==null` → **`'المبلغ غير صالح'`** :122-129. **>0 kontrolü yok** → `0` ve `.` kabul edilir |
| 2 | الفئة | **`DropdownButton<String>`** (FormField **değil**) :262-284 | hint `'اختر الفئة'`, `isExpanded: true` | — | **yok** — `بدون فئة` :268-271 + kategori adları; validation dışı |
| 3 | الوصف | `TextFormField` :143-148 | hint `'وصف المصروف'`, ikonsuz | tek satır | **yok** |
| 4 | **التاريخ \*** | salt okunur **`InkWell` + `showDatePicker`** :289-323 | `Icons.calendar_today, size:18` :313; gösterim `'d/m/yyyy'` :316 | — | `firstDate DateTime(2000)`, `lastDate DateTime(2100)` :292-297. **FormField olmadığı için `*` dekoratif, asla validate edilmez**; `_expenseDate` :32 varsayılan `DateTime.now()` (:32,:52) |
| 5 | ملاحظات | `TextFormField` :159-165 | hint `'ملاحظات إضافية (اختياري)'` | `maxLines: 3` :161 | **yok** |

- **Çizilmeyen/ölü alanlar (D):** `receiptNumber` — `_receiptController` :28 prefill (:45-47) ve persist (:402-404) ama UI yok. **`paymentMethod` ÖLİ**: `_buildPaymentMethodSelector` (:325-376, seçenekler `نقدي/بطاقة/تحويل` :327-329) **`build`'de hiç çağrılmıyor** → `_paymentMethod` :33 `:53` initialize, `:401` persist → **her yeni gider `'cash'` olarak kaydedilir**. `deletedAt` hiç set edilmiyor.
- Butonlar :178-203: `'إلغاء'` :186 → pop :182 (bu dosyada **hiç `_formKey.reset()` yok**); submit etiketi `isEditing ? 'حفظ التغييرات' : 'إضافة مصروف'` :198, `onPressed: _submit` :192, **disable/loading yok**.
- `_submit` :378-412: `double.parse(_amountController.text)` :380 (validate ile korumalı); kategori `firstWhere(orElse: (id:'',name:'',…))` :381-389 → listede yoksa **boş adlı hayalet kategori** yazılır, `categoryName` :399 ondan türetilir → `''`.
- `widget.onSubmit(expense)` :410 → **pop yok**: dialog kayıttan sonra açık kalır (sayfa yönetir). **D**

### 8.7 F-07 Kasa çıkışı formu — `AddWithdrawalDialog` (`add_withdrawal_dialog.dart`)

`validate()` tek :48; **ikinci katman kontrol** :49-54 → `_selectedUserId == null` ise **snackbar `'يرجى اختيار المستخدم'`** :50-52 ve `return`. Yani "zorunlu kullanıcı" kuralı FormField validator'ı **değil**, alan kırmızıya dönmez.

| # | Alan | Widget / satır | Etiket / hint | Klavye / maske | Validatör |
|---|---|---|---|---|---|
| 1 | **المستخدم \*** | `DropdownButton<String>` (**FormField değil**) :142-153 | harici etiket :126-133; hint `'اختر المستخدم'` :145; öğe metni `entry.value['name'] ?? '-'` :149 | — | **yok** (snackbar ile ikinci katman) |
| 2 | **المبلغ \*** | `TextFormField` :171-208 | hint `'0.00'` :175; **`prefixText: '﷼ '`** :176 (ikon değil, sabit metin — **para birimi tercihini yok sayar**) | `TextInputType.number` :173; **`inputFormatters` YOK** | `isEmpty` → **`'المبلغ مطلوب'`**; `double.tryParse==null` → **`'أدخل رقماً صحيحاً'`** :199-206. >0/kap kontrolü yok |
| 3 | التاريخ | salt okunur `InkWell` + `showDatePicker` :224-252 (`_selectDate` :73-83) | `Icons.calendar_today 16 textSecondary` :244-248; gösterim `dd.MM.yyyy` :240 | — | `firstDate 2020`, `lastDate 2030` :77-78; **validate edilmez** |
| 4 | الوصف | `TextFormField` :268-295 | hint `'أدخل الوصف...'` :271 | `maxLines: 2` :294 | **yok** |
| 5 | ملاحظات | `TextFormField` :311-338 | hint `'ملاحظات إضافية...'` :314 | `maxLines: 3` :337 | **yok** |

- `'إضافة دفعة جديدة'` başlığı :102-108 (**gider mi çıkış mı — metin "دفعة" diyor, dialog `AddWithdrawalDialog`; etiket tutarsızlığı D**).
- Butonlar :343-386: `'إلغاء'` :355 → pop :346; `'حفظ'` :377 → `_submit` :366; disable/loading **yok**; prefill/reset **yok** (yalnız oluşturma).
- **Veri bütünlüğü (D):** `userId: _selectedUserId ?? 'current_user_id'` :57 → **ortak (partner) ID'si `userId` alanına yazılıyor** ve placeholder metni veritabanına gidebiliyor; `partnerId: _selectedUserId` :58; `paymentMethod: 'cash'` **sabit** :61; `id: ''` :56; `notes/description` boşsa `null` :60,:63; `createdAt/updatedAt = now` :64-65; `deletedAt` hiç.
- `onSave(withdrawal)` :68 → ardından `Navigator.pop` :69 **koşulsuz** (istek bitmeden kapanır).

### 8.8 F-08 Yeni ortak formu — `AddUserDialog` (`add_user_dialog.dart`)

| # | Alan | satır | Etiket / hint | Klavye | Validatör |
|---|---|---|---|---|---|
| 1 | **الاسم الكامل \*** | `TextFormField` :96-128 | harici etiket :87-94; hint `'الاسم الكامل'` :99; ikonsuz | varsayılan | `null \|\| trim().isEmpty` → **`'الاسم الكامل مطلوب'`** :122-126 |
| 2 | **الهاتف \*** | `TextFormField` :144-177 | harici etiket :135-142; hint `'+966-5X-XXX-XXXX'` :148 | `TextInputType.phone` :146 | `null \|\| trim().isEmpty` → **`'الهاتف مطلوب'`** :171-175 — **biçim/digit kontrolü YOK**; `flutter/services.dart` import edilmiş (:2) ama **kullanılmıyor** → formatter yok |

- Başlık `'مستخدم جديد'` :64; `'إلغاء'` :194→pop :185; `'حفظ'` :216→`_submit` :205; `validate()` tek :37.
- `_submit` :36-44 → `onSave(name.trim(), phone.trim())` :38-41 (senkron) + `Navigator.pop` :42 koşulsuz. Sayfa handler'ı (`withdrawals_page.dart:337-346`) `Partner(id:'', …, phone: phone.isEmpty?null:phone, createdAt: now)` kurup `createPartner(...)` **await etmiyor** → hata görünmez. **D**
- `Partner` modelinin geri kalan alanları UI'da yok. Reset/prefill yok.

### 8.9 F-09 Ödeme formu — `PaymentDialogWidget` (müşteri ve tedarikçi borçları)

`_formKey` :21; `Form` :132; `validate()` tek :269. Alanlar:

| # | Alan | satır | Etiket / ikon | Klavye | Validatör koşulları → metin |
|---|---|---|---|---|---|
| 1 | مبلغ الدفعة | `TextFormField` :137-173 | `labelText: 'مبلغ الدفعة'` :141, hint `'0.00'` :142, `prefixIcon: Icon(Icons.attach_money, AppColors.primary)` :155-158 | `TextInputType.number` :139; **formatter yok** | `isEmpty` → **`'الرجاء إدخال المبلغ'`**; `tryParse==null \|\| amount<=0` → **`'الرجاء إدخال مبلغ صحيح'`**; `amount > debt.remainingDebt` → **`'المبلغ لا يمكن أن يتجاوز الدين المتبقي'`** :160-171 — **projedeki tek iş kuralı tavanı** |
| 2 | ملاحظة (اختياري) | `TextFormField` :178-201 | `labelText: 'ملاحظة (اختياري)'` :181, hint `'إضافة ملاحظة...'` :182, `prefixIcon: Icon(Icons.note_outlined, textSecondary)` :195-198, `maxLines: 2` :200 | varsayılan | **yok** |
| 3 | تاريخ الدفعة | `InkWell` + `InputDecorator` salt okunur :206-236 | `labelText 'تاريخ الدفعة'` :210, `prefixIcon: Icons.calendar_today textSecondary` :223-226; gösterim `'d/m/yyyy'` :228-234 | — | `showDatePicker(first 2020, last now+30d)` :27-32; **validate edilmez** |

- Salt okunur bağlam: `widget.debt.name` :97-104 ve `'الدين المتبقي: '` + `NumberFormatter.formatCurrency(remainingDebt)` :109-116 → **gösterilir, gönderilmez**.
- Butonlar :245-297: `'إلغاء'` :257→pop :248; `'حفظ'` :288 → `onPressed` :268-279 = `if (validate()) { amount=double.parse; note=trim→null; formattedDate='yyyy-MM-dd'; widget.onPaymentSubmit(amount, note, formattedDate); Navigator.pop(context); }`.
- **Eşzamanlılık hatası (D):** `onPaymentSubmit` imzası `Function(double, String?, String)` :8, çağrı noktaları **async closure** geçiyor (`customer_debts_page.dart:174-176`, `suppliers_debts_page.dart:168-174`) → dönen Future **await edilmez**, `pop` :277 `addPayment` bitmeden çalışır; `'تم تسجيل الدفعة بنجاح'` mesajı **sonuca bakılmaksızın** sayfa tarafından basılır (:180).
- Aynı dialog tedarikçi borçlarında da kullanılıyor (`suppliers_debts/.../payment_dialog_widget.dart` **ayrı kopya dosya**, validator metinleri `customer_debts` ile birebir; `payment_modal_widget` kopyalarında metinler farklı varyant: `'الرجاء إدخال مبلغ صالح'` ve `'لا يمكن أن يتجاوز المبلغ الدين المتبقي'` — **D, 4 kopya dialog, 2 farklı hata metni**)

### 8.10 F-10 Fatura oluşturma — `Form` **YOK** (tamamında grep: `Form`/`GlobalKey<FormState>`/`validator:`/`validate()` bulunamadı)

Doğrulama tamamen `InvoiceCubit.canSaveInvoice` içinde (`invoice_cubit.dart:673-698`): satış⇒müşteri :680-683, alış⇒tedarikçi :684-687, `invoiceItems` boş değil :688-691, `invoiceDate != null` :692-695. Tek mesaj: **`'يرجى إكمال جميع الحقول المطلوبة'`** (`invoice_actions_widget.dart:45` + `InvoiceError` :701-703).

| Bileşen | Toplanan girdi | Boşluk/krash riski |
|---|---|---|
| `combined_invoice_info_widget` | tip `DropdownButton<String>` :178-191 (`مبيع`/`شراء`); arama `TextField` :224-253 (hint `isSale ? 'ابحث عن عميل...' : 'ابحث عن مورد...'` :228, `Icons.search`, `onChanged` :252, sonuçlar ≤10) | `_buildPaymentTypeDropdown` (**آجل/نقدي**, :197-221) **hiç çağrılmıyor** → `debtType` cubit'te `'debtor'` değerinde kilitli, kullanıcı ödeme tipini **buradan seçemez** (seçim `InvoiceActionsWidget` dropdown'ında). `suffixIcon Icons.clear` :245-250 → `_clearSelection` :103-110 yalnız controller/seçim temizler, **cubit'teki müşteri/tedarikçi id'sini temizlemez**. `_onEntitySelected(dynamic entity)` :85 → tip güvenliği yok |
| `invoice_dates_widget` | 2 readonly `TextFormField` :199-237 (`'تاريخ الفاتورة'` :146, `'تاريخ الاستحقاق'` :154; prefix `event_outlined`/`calendar_month_outlined` 18, suffix `IconButton(calendar_today 18)`; `readOnly: true` :232, `enableInteractiveSelection: false` :233, `onTap` :234) | `showDatePicker(2020→2030)` :80-98; **cross-check yok** → vade, fatura tarihinden önce olabilir; controller metninden `int.parse` :68-72 → bozuk metinde `FormatException` (runtime'da zor ama mümkün). Fatura tarihi değişince vade eşitse o da overwritten :108-111 |
| `product_add_widget` | `اسم المنتج` `TextField` :328-351 (hint `'ابحث عن منتج أو اكتب اسم المنتج...'`), `الكمية` `TextField` :383-408 (`digitsOnly` :406, `textAlign: center`, `onSubmitted` :407), `إضافة` butonu :425 | **`existingProduct!` force-unwrap :150** → katalogda olmayan ad yazılıp miktar girilirse **çökme** (hint'in vaat ettiği "kendi ürün adını yaz" yolu kırık). Miktar boş/0 ise **sessizce `return`** (:89-90,:131-133) — hata mesajı yok. Eklenen üründen sonra miktar **`'1'`'e resetleniyor** :168. Arama metnine `'name (unit)'` yazılıyor :83,:145 ve ürün adı kaynağı olarak kullanılıyor :124 → parantezli metin `productName`'e sızabilir (:157). Fiyat alanı yok — `salePrice/purchasePrice` ürün kaydından kopyalanıyor (:93,:100,:150,:160) |
| `invoice_summary_widget` | `الخصم (المبلغ)` `TextField` :214-249 (`TextInputType.number`, `FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$'))` :246-248, labelText/hint/ikon **yok**), `'طبق'` butonu :252-264 | **İndirim > ara toplam kabul edilir** → `grandTotal` negatif (:56) ve `- X <sembol>` kırmızı satır negatif üretir. `double.tryParse(value) ?? 0.0` :43 → bozuk metin sessizce `0`. `_discountController` :17 **ölü controller**. **`paidAmount` için hiçbir giriş alanı yok** (cubit:44,592) → kısmi ödeme girilemez, `paymentType`'tan türetilir (:561-563). `build` içinde controller'lara yazılıyor :60-64 (yan etki) |
| `invoice_actions_widget` | ödeme tipi `DropdownButtonFormField<String>` :157-186 (`مدفوعة نقدا`=cash :176-179, `مديون`=debt :180-183; `prefixIcon Icons.money 18 textSecondary`; `border: InputBorder.none`), `حفظ` `ElevatedButton.icon` :196-225, `حذف` :232-251, PDF butonu **yorum satırında** :254-278 | `onChanged: _isSaving ? null : …` :185 → **audited form setindeki tek disable/loading koşulu**; `_saveInvoice` :41-65 gerçekten `await cubit.saveInvoice()` :54, `catch` :56-57 `'فشل حفظ الفاتورة: …'` üretir; **ancak cubit exception fırlatmayıp `InvoiceError` emit ettiği için dal pratikte çalışmıyor** (5.7 ile tutarlı). Save **pop/navigasyon yapmaz**. `_deleteInvoice` :67-76 → onay + `'تم حذف الفاتورة'` :74, **repository çağrısı yok** → silme gerçeğe dönüşmüyor. `status/notes/reference/project/deliveryDate/paymentMethod` bu beş bileşende hiç çizilmiyor (`status` sabit `'completed'` cubit:50) |

### 8.11 Formlar arası ortak bulgular (yeniden yazım için kural listesi)

| # | Bulgu | Kanıt |
|---|---|---|
| 1 | **Zorunlu işaret görsel:** `*` etiket metnine elle yazılıyor (`'اسم العميل *'`, `'المبلغ *'`); hiçbir alan `required` sembolü ile üretilmiyor. | 8.2, 8.6 |
| 2 | **Tarih alanlarının yarısı FormField değil** → `*` taşısalar da validate edilmiyor (gider `التاريخ *`, çıkış `التاريخ`, ödeme `تاريخ الدفعة`). | 8.6 #4, 8.7 #3, 8.9 #3 |
| 3 | **Dropdown'lar validation dışı:** `DropdownButton` (FormField **değil**) gider kategorisi, çıkış kullanıcısı, fatura tipi. | 8.6 #2, 8.7 #1, 8.10 |
| 4 | **Sıfır/negatif para kontrolü yok** (gider, çıkış); yalnız ödeme dialogunda `>0` ve `> remainingDebt`. | 8.6 #1, 8.7 #2, 8.9 #1 |
| 5 | **Telefon doğrulaması hiçbir yerde yok** (müşteri/tedarikçi/ortak), `TextInputType.phone` sadece klavye seçtirir. | 8.2, 8.3, 8.8 |
| 6 | **Kaydetme await edilmeden dialog kapatma** 6 formda yaygın: müşteri(cubit dalı), tedarikçi, ürün, kategori, çıkış, ödeme. Sonuç: hata mesajı kaybolur, mükerrer kayıt riski. | 8.2-8.9 |
| 7 | **Loading/disabled yalnız 2 yerde:** login (`AuthLoading`) ve fatura `حفظ` (`_isSaving`). Diğer submit butonları her zaman tıklanabilir. | 8.1, 8.10 |
| 8 | **Reset davranışı tutarsız:** müşteri `reset()` var (controller'ları temizlemez), ürün `reset()` var (dropdown'ları bozar), gider/çıkış/ortak/ödeme **hiç reset yok**. | 8.2-8.9 |
| 9 | **Türkçe/İngilizce sızıntısı:** `invoice_notes_widget.dart:103` `'Fatura notları...'`, `:249` `'Seçiniz'`; `quick_product_add_card.dart:145-146` `'Ürün Ara'` / `'Ürün adı veya kodu yazın...'` — bu iki dosya 5.7'deki **ölü widget listesinde**, yani canlı UI'da görünmüyorlar ama yeniden yazımda yanlışlıkla canlandırılabilecek Arapça-olmayan metinler. Canlı ekranlarda İngilizce kalanlar: `InvoiceCardWidget` rozetleri `'sale'`/`'purchase'` (5.21), `WithdrawalCard` `'cash'` (ölü, 5.27), müşteri/tedarikçi kart `tooltip`'leri `'يحرر'`/`'sil'` ve `'Düzenle'`/`'Sil'` (5.10/5.11), `'Unknown state'` metni (5.10). **D** |
| 10 | **Modelde olan, formda olmayan alanlar (özet):** müşteri `code/creditLimit/currentBalance/isActive`; ürün `barcode/currentStock/maxStock/location/notes/id`; gider `receiptNumber/paymentMethod(dead)/deletedAt`; çıkış `paymentMethod(sabit)/deletedAt`; kategori `description/dead parentId/sortOrder/isActive(true)`; ortak `Partner` ek alanları. **Yeniden yazımda ya UI'a eklendiği ya da resmen "alan yok" olarak dokümante edilmelidir.** |
---

## 9. Veri modelleri ve depolama

> Alan tabloları `fromMap/toMap` yönleriyle verilir. **D** = dosya satırından doğrulandı. Sentetik örnekler §9.6'da (gerçek kullanıcı verisi içermez).

### 9.1 Model haritası (sınıf → dosya → tablo)

| Sınıf | Dosya | Okuduğu/yazdığı Supabase nesnesi | Durum |
|---|---|---|---|
| `User` (ad `UserModel` **değil**) | `auth/data/models/user.dart:3` | `profiles` | D |
| `CustomerModel` | `customers/data/models/customer.dart:3` | `customers` | D |
| `SupplierModel` | `suppliers/data/models/supplier.dart:3` | `suppliers` | D |
| `ProductModel` | `products/data/models/product.dart:5` | `products` | D |
| `ProductCategory` | `products/data/models/product_category.dart:3` | `categories` | D |
| `ProductUnitData` | `products/data/models/product_unit_data.dart:3` (statik liste) | — (sabit) | D |
| `SalesInvoice` | `invoices/data/models/sales_invoice.dart:6` | `sales_invoices` + `sales_invoice_items` | D |
| `PurchaseInvoice` | `invoices/data/models/purchase_invoice.dart:6` | `purchase_invoices` + `purchase_invoice_items` | D |
| `InvoiceItem` | `invoices/data/models/invoice_item.dart:5` | `*_invoice_items` | D |
| `Invoice` (legacy) | `invoices/data/models/invoice.dart:7` | **hiçbir datasource tarafından kullanılmıyor** | D ölü |
| `Invoice` (unified) | `invoices/data/models/invoice_unified.dart:4` | **erişilemez (ölü)**: 15.3 import grafiğinde `main.dart`'dan ulaşılamıyor; `InvoiceUnified` adının hiçbir referansı yok (grep 0) | D |
| `InvoiceStatus` / `PaymentStatus` | `invoices/data/models/invoice_status.dart:3`, `payment_status.dart:3` | kolon değerleri | D |
| `InvoiceStatus` (2. tanım) | `invoices/data/models/invoice.dart:5` — `draft/sent/paid/overdue/cancelled/pending` | **aynı kavramda ikinci enum** | D çelişki |
| `CustomerDebtModel`, `CustomerDebtTotalsModel`, `InvoiceModel`, `PaymentModel` | `customer_debts/data/models/*` | `view_customer_debt_details`, `view_dashboard_customer_debts`, `sales_invoices`, `payments` | D |
| `SupplierDebtModel`, `SupplierDebtTotalsModel`, `PurchaseInvoiceModel`, `SupplierPaymentModel` | `suppliers_debts/data/models/*` | `view_supplier_debt_details`, `view_dashboard_supplier_debts`, `purchase_invoices`, `payments` | D |
| `Expense`, `ExpenseCategory` | `expenses/data/models/expense.dart:3`, `expense_category.dart:3` | `expenses`, `expense_categories` | D |
| `Withdrawal`, `Partner` | `withdrawals/data/models/withdrawal.dart:3`, `partner.dart:3` | `withdrawals`, `partners` | D |
| `StockMovement` | `stock/data/models/stock_movement.dart:5` | **yok** — hiçbir datasource yazmıyor/okumuyor | D ölü |
| `DashboardFinancialsModel`, `DashboardProductStockModel` | `dashboard/data/models/*` | RPC `get_dashboard_financials`, tablo `dashboard_product_stock` | D |
| — | `reports/` | **kendi modeli yok**, `SalesInvoice`/`PurchaseInvoice` yeniden kullanılıyor (`report_remote_datasource.dart:77,96`) | D |

### 9.2 Alan tabloları

#### `User` — `auth/data/models/user.dart`
| Alan | Tip | Null | Varsayılan | DB anahtarı | Not |
|---|---|---|---|---|---|
| `id` | `String` | hayır | — (zorunlu) | `id` | auth user id |
| `email` | `String` | hayır | — | `email` | |
| `fullName`,`phone`,`businessName`,`businessAddress`,`taxNumber` | `String?` | evet | — | `full_name`,`phone`,`business_name`,`business_address`,`tax_number` | **`fromMap:99-103` eksik anahtarı `''` yapıyor** → nullability kaybı (bilerek "bilinmiyor" demek imkânsız) |
| `currencyCode` | `String` | hayır | **`'SAR'`** :25 | `currency_code` | **Çelişki:** `NumberFormatter` varsayılanı `'SYP'`, sembollerde `SAR` yok (9.5) |
| `language` | `String` | hayır | `'ar'` | `language` | |
| `themeMode` | `String` | hayır | `'light'` | `theme_mode` | **hiçbir yerde okunmuyor** (dark theme yok → 6.4, 11) |
| `createdAt`,`updatedAt` | `DateTime` | hayır | — | `created_at`,`updated_at` | `DateTime.parse` **korumasız** :107-108 → bozuk tarih = çökme |
| — | — | — | — | — | `toMap` `id`, `created_at`, `updated_at` dâhil **tümünü yazar** |

#### `CustomerModel` — `customers/data/models/customer.dart`
| Alan | Tip | Null | Varsayılan | Dönüşüm |
|---|---|---|---|---|
| `id`,`userId`,`code`,`name` | `String` | hayır | — | — |
| `phone`,`address`,`city` | `String?` | evet | — | — |
| `creditLimit`,`currentBalance`,`totalPurchases` | `double` | hayır | `0` | `fromMap:114-116` `(x ?? 0).toDouble()` |
| `isActive` | `bool` | hayır | `true` | — |
| `createdAt`,`updatedAt` | `DateTime` | hayır | — | `DateTime.parse` **korumasız** :118-119 |
| `deletedAt` | `DateTime?` | evet | — | — |
| **`toMap:88-103` YAZMAZ:** `id`, **`code`** | | | | → `code` alanı hiçbir kayda gönderilemez; formda da çizilmiyor (8.2) → özellik fiilen ölü |
| Equatable `props:37-52` tüm alanları içerir | | | | |

#### `SupplierModel` — `suppliers/data/models/supplier.dart`
`id/userId/name` zorunlu; `phone/city` null; `currentBalance/totalPurchases/isActive` **zorunlu** :21-23; `createdAt/updatedAt` zorunlu (`DateTime.parse` :82-83 korumasız).
`fromMap:75-80` iki-tip toleransı: `double.tryParse(x)` **veya** `(x as num?)?.toDouble()`. **`toMap` `id` yazmaz; `deletedAt` alanı modelde hiç yok** → tedarikçiler soft-delete edilemez.

#### `ProductModel` — `products/data/models/product.dart`
| Alan | Tip | Varsayılan / dönüşüm |
|---|---|---|
| `id,user,code,name,unit,measurement` | `String` zorunlu | `measurement` **String** olarak tutuluyor |
| `barcode,categoryId,categoryName,location,notes` | `String?` | `categoryName` nested `map['categories']['name']` :159 |
| `purchasePrice,salePrice,minSalePrice` | `double` `0` | |
| `currentStock,minStock` | `int` `0`; `maxStock` `int?` | |
| `isActive` `true`; `deletedAt?`; `createdAt/updatedAt` | | `DateTime.parse` :171 korumasız |
| `fromMap:160` `unit` düşüşü **`'piece'`** | **Çelişki:** `ProductUnitData` Arapça literaller içeriyor (`كيلوغرام…`) → DB'de İngilizce `piece` ile Arapça birimler bir arada | D |
| `fromMap:161` `measurement: map['measurement']?.toString() ?? '0'` | | |
| **`toMap:126` `int.parse(measurement)` → fırlatır** | boş/non-numeric metin = crash; `measurement` **int** olarak yazılır | D kritik |
| `toMap` **YAZMAZ:** `id`, `code`, `barcode` | 8.4 ile tutarlı | D |

#### `ProductCategory`
`id/userId/name/createdAt` zorunlu; `description/parentId` null; `sortOrder int=0`; `isActive=true`; `toMap` `id` yazmaz; `fromMap:70` düz erişimler, `DateTime.parse` :79 korumasız. `parent_id` **self-FK** — UI'da ağaç yok (5.18).

#### Fatura modelleri
| Konu | `SalesInvoice` | `PurchaseInvoice` | Not |
|---|---|---|---|
| Zorunlu alanlar | `id,userId,invoiceNumber,invoiceDate,subtotal,totalAmount,createdAt,updatedAt,status,paymentStatus` | aynı + `supplierId?` | |
| Varsayılan | `paymentMethod='cash'` :49, `totalPurchaseAmount/profit=0`, `items=[]` | `paymentMethod` **alanı yok** | D |
| `toJson` | **`id` YAZMAZ**, `notes` YAZMAZ :121-148 | **`id` YAZAR**, `notes` ve `payment_method` YAZMAZ | D |
| Enum serileştirme | `status.name`, `paymentStatus.name` (**İngilizce**) | aynı | D |
| `fromJson:150/131` | `firstWhere(...orElse: draft/cash)` :167-174; tarih yoksa **`DateTime.now()`** | aynı | D — bozuk tarih sessizce "bugün" olur |
| Equatable `props` :191-217 / :168-190 | **`status` listesi YOK** (24 alan sayıldı, `status` yok) | aynı eksik | D kritik → `status` değişimi tek başına state'i "değişmemiş" kılar, bloc rebuild yapmaz |
| Dosya içi yorumlanmış `SalesInvoiceItem` :220-328 | ölü kod | | D |

`InvoiceItem`: tüm alanlar null-uyumlu, `purchasePrice/discountAmount=0.0`; `fromJson:77` `(json['x'] as num?)?.toDouble()/toInt()`; **`invoice_id` taşımaz** — FK datasource'ta ekleniyor (`invoice_remote_datasource.dart:150`).

`Invoice` (unified, `invoice_unified.dart`): `userId` zorunlu, `paymentMethod='cash'` :46, `taxPercentage/shippingCost`. **Yalnız ölü kodda bulunan roundtrip kaybı (D):** `invoice_unified.dart` erişilemez durumda (15.3) ve `InvoiceUnified` hiçbir yerden referans almıyor; aşağıdaki davranış **canlı akışı etkilemez**. Canlı modeller tutarlı: `sales_invoice.dart:138` ve `purchase_invoice.dart:121` `payment_status: paymentStatus.name` (İngilizce) yazar, `:172`/`:147` aynı adla okur. `toJson:129` `payment_status` kolonuna **`paymentStatus.getArabicName` (Arapça)** yazar, `fromJson:158` `PaymentStatus.fromString(json['payment_status'] ?? 'pending')` **İngilizce enum adı** bekler → eşleşmez, `orElse` ile `cash`'e düşer. Yani bu model üzerinden yazılıp okunan ödeme durumu her seferinde `cash` olur.
`Invoice` (legacy, `invoice.dart`) ve `StockMovement` → **ölü** (kaynak yok).

#### Borç modelleri
| Model | Alanlar | Önemli |
|---|---|---|
| `CustomerDebtModel` | `id, name, totalInvoices(double), totalPaid(double)`, sayılar `int=0`, `latestDueDate` **`String?`** | `fromMap:67` anahtar takma adları: `customer_id→id`, `customer_name→name`, **`total_debt→totalInvoices`**; `fromViewMap:81` yalnız `view_customer_debt_details` için; `_parseDouble:91-96` null/num/String toleransı; `toMap` **`id` dâhil hepsini yazar** |
| `CustomerDebtTotalsModel` | 3 `double=0` | `fromMap:16`: `remaining_balance_all→totalDebtAll`, `total_debt_all→totalInvoicesAll` → **anlam kayması** (5.14 etiket tablosu ile tutarlı); **`toMap` yok** (salt okuma) |
| `InvoiceModel` (müşteri borcu) | `invoiceDate` ve `dueDate` **`String`**, `paymentStatus` **`String='debt'`** :30 | `isDebt` literal `'debt'` karşılaştırması :50; `toMap` **`paid_amount` satırı yorumda** :94 → hiçbir zaman yazılmaz; `id` **yazar**; tarihler `toIso8601String()` :43 |
| `PaymentModel` (müşteri) | `paymentMethod` varsayılan **Arapça `'نقداً'`** :26; `paymentType` **`String='customer'`** :18,31 | `fromMap:100` `payment_date` yoksa **`created_at`**'a düşer; `toMap` `id` yazmaz; insert'ler `'payment_type':'customer'` **sabit** yazıyor (`customer_debt_remote_datasource.dart:89`, offline kuyruk `customer_debt_repository_impl.dart:147`) |
| `SupplierDebtModel`/`Totals` | ayna | totals `fromMap` önce `*_suppliers` anahtarlarını dener :16-22; **tedarikçi tarafının yerel cache'i yok** (`supplier_debt_repository_impl.dart:10` remote-only) |
| `PurchaseInvoiceModel` | ayna, `supplierId` | `toMap` `paid_amount` **yok** :80-95; `id` yazar |
| `SupplierPaymentModel` | ayna | Arapça `'نقداً'` :21,86; `paymentType` alanı yok; `toMap` `id` yazmaz |

#### Gider / çıkış
| Model | Zorunlu | Varsayılan | Dönüşüm/Not |
|---|---|---|---|
| `Expense` :3 | `id,userId,amount,expenseDate,createdAt,updatedAt` | `paymentMethod='cash'` :26 | `categoryName` nested `expense_categories.name` :104; `DateTime.parse` :107,111-112 korumasız; `toMap` `id` yazmaz; `deletedAt` :16 hiç set edilmiyor |
| `ExpenseCategory` :3 | `id,userId,name,createdAt` | `isActive=true`, `description?` | `toMap` `id` yazmaz |
| `Partner` :3 | `id,name,createdAt` | `phone?`, `updatedAt?` | `DateTime.parse` :51; `toMap` `id` yazmaz |
| `Withdrawal` :3 | `id,userId,amount,withdrawalDate,createdAt,updatedAt` | `partnerId?`, `paymentMethod='cash'` :23 | `DateTime.parse` :95,98-99; `toMap` `id` yazmaz; UI'da `userId ← partner seçimi` + `?? 'current_user_id'` (8.7) |

#### Dashboard
`DashboardFinancialsModel` :3 — `userId` zorunlu + 9 `double=0`; `fromMap:30` **`map['user_id'] as String` → anahtar yoksa TypeError**; `_toDouble:58-64` num/String toleransı; `toMap` var; cache'te sabit satır `id='financials'`.
`DashboardProductStockModel` :3 — `userId/productId/productName` zorunlu + 4 `int=0`; `:24-25` `user_id`/`product_id` **`as String`** → satırda anahtar yoksa TypeError; `:26` `product_display_name` **`as String? ?? ''`** → güvenli; `_toInt:46-52`; `system_stock/total_purchased_qty/total_sold_qty/calculated_remaining_stock` alanları; cache key `product_id`. **D**

### 9.3 Enum → DB eşlemeleri

| Enum | Değerler | DB yazımı | Etiket (Arapça) | `fromString` düşüşü |
|---|---|---|---|---|
| `InvoiceStatus` (`invoice_status.dart:3`) | `draft, completed, cancelled` | `.name` (İngilizce) | `مسودة / مكتملة / ملغاة` :10-12 | orElse `draft` :26-30 |
| `InvoiceStatus` (2. tanım, `invoice.dart:5`) | `draft, sent, paid, overdue, cancelled, pending` | **kullanılmıyor** | — | — |
| `PaymentStatus` | `cash, debt` | `.name` (İngilizce) — **unified `Invoice` istisnası: Arapça yazar** (9.2) | `مدفوعة نقدا / مديون` :10-12 | orElse `cash`; `'pending'` literali geçersiz → `cash` |
| `InvoiceType` (`invoice.dart:4`) | `sale, purchase` | legacy | — | orElse `sale` |
| `MovementType` (`stock_movement.dart:3`) | `sale, purchase, adjustment, returnSale, returnPurchase` | — (model ölü) | — | orElse `adjustment` :56-58 |
| String-literaller (enum **değil**) | `paymentStatus: 'debt'/'cash'` (borç modelleri + `invoice_cubit.dart:49`), `paymentType: 'customer'/'supplier'`, `payment_method: 'cash'`, `status: 'completed'` sabit (cubit:50) | | | **D — tip güvenliği yok, yeniden yazımda enum'a çevrilmeli** |

### 9.4 Tarih, para, ID ve eşitlik kuralları

| Konu | Proje davranışı (D) |
|---|---|
| Zaman dilimi | Kod tabanında **hiç `.toUtc()` / `toLocal()` yok** (grep) → `DateTime.now()` yerel saat + `toIso8601String()` ile `timestamptz` kolonlarına yazılıyor → sunucu UTC'ye çevirirken **ofset bilgisi yerel varsayılır**. Dashboard/rapor tarih filtreleri bu yüzden kayabilir. **Risk → 12, 15** |
| Tarih tipi | Faturaların çoğu `DateTime`; **borç modüllerinde `invoiceDate/dueDate/latestDueDate/paymentDate` `String`** (9.2) → biçim karışımı (`yyyy-MM-dd` vs ISO tam) |
| Görünen tarih biçimleri | `yyyy-M-dd` (`invoice_dates_widget:55`), `d/m/yyyy` (gider, ödeme), `dd.MM.yyyy` (çıkış), `gün/ay - gün/ay` (fatura çipi), `toString().split(' ')[0]` (ölü `WithdrawalCard`) → **5 farklı biçim** |
| Para tipi | Her yerde `double`; DB `numeric`. Okurken `(x ?? 0).toDouble()` / `double.tryParse` / `_parseDouble` karışık |
| Biçimlendirme | `NumberFormatter` (`core/utils/number_formatter.dart`): `_useArabicFormat=false→main.dart:27 ile her açılışta true`, `_selectedCurrency='SYP'`, `_useShortFormat=true`; semboller `SYP→'ل.س'`, `USD→'$'`, `EUR→'€'`, `TRY→'₺'`; `getCurrencySymbol()` bilinmeyen kodda **kodun kendisini döner** :66 → `profiles.currency_code='SAR'` olan kullanıcı `'SAR'` metnini görür. **D** |
| Kısaltma | `_useShortFormat` true iken `K/M` kısaltması (`_formatArabic` / `_formatShortStandard`, :70+) |
| Parsing çökmesi | `int.parse` (measurement, yıl), `double.parse` (formlar), `DateTime.parse` (8 model), `as String`/`as num` cast'leri (dashboard, cache) → §9.5.11 liste |
| ID üretimi | Supabase `id`'yi üretir; client `id: ''` gönderir. Client üretimi: ürün `code = now.microsecond.toString()` (`product_form_widget.dart:82`, 0–999999 → **çakışma riski + `toMap` code yazmadığı için zaten kayboluyor**), offline ödeme `id='pending_<ms>'` (`customer_debt_repository_impl.dart:130,140` → aynı ms'te `INSERT OR REPLACE` satırı düşürür), gider `temp_<ms>_<Random(1000)>` (`expense_cubit.dart:141`), fatura no `INV\|PUR-YYYYMMDD-(ms%10000)` (`invoice_cubit.dart:846-852` → günde 10.000'den fazla faturada **çakışma**) |
| Equatable | `CustomerModel`, `SalesInvoice`, `PurchaseInvoice` vb. extends Equatable; **`status` props dışı** (9.2) ve `Invoice` (unified) Equatable **değil** → state karşılaştırması kimlik üzerinden yapılır, gereksiz/görünmez rebuild riskleri iki yönlü |

### 9.5 Yerel depolama

#### 9.5.1 Drift / sqlite — `lib/core/database/app_database.dart`
Dosya `erad_cache.db`, `schemaVersion: 1`, **`allTables = []`** (şema ham SQL `CREATE TABLE IF NOT EXISTS` ile `onCreate`'te kuruluyor; Drift DSL tanımlı değil) → **şema sürümü ilerlememiş, migration yolu yok. D**

| Tablo (satır) | Kolonlar | Yazan / okuyan | Temizleme |
|---|---|---|---|
| `sales_invoices_cache` :27 | `id TEXT PK`, `user_id TEXT NN`, `data TEXT NN` (JSON), `updated_at TEXT NN` | `invoice_local_datasource.dart:19-27` / `:41-44` | yazmadan önce `clearTable` :20 + `clearCache` :54 — **ancak `upsertJsonList` idExtractor `map['id'] as String` :25 ve `SalesInvoice.toJson()` `id` yazmıyor (9.2) → satır `null as String` ile **TypeError** üretir; online-sonrası cache yazımı pratikte çalışmıyor. D kritik** |
| `purchase_invoices_cache` :32 | aynı | `:30-38` / `:46-50` | `:31,:55` (PurchaseInvoice `id` **yazar** → bu tablo çalışır) |
| `customer_debts_cache` :37 | aynı | `customer_debt_local_datasource.dart:25-34` / `:36-40`, `updateDebtAfterPayment :91-101` | `:26,:111` |
| `customer_invoices_cache` :42 | `PK (customer_id, user_id)`, `data`, `updated_at` | `:42-48` / `:50-56` | **hiç temizlenmiyor** |
| `customer_payments_cache` :48 | `PK (customer_id, user_id)` | `:58-65` / `:67-73`, append `:103-107` | **hiç temizlenmiyor** |
| `dashboard_financials_cache` :54 (ayrıca `:74,:78`) | `PK (id, user_id)` | `dashboard_local_datasource.dart:19` / `:24` | **hiç temizlenmiyor** (tek satır `id='financials'`) |
| `dashboard_product_stock_cache` :60, `:80` | `id TEXT PK` (= `product_id`) | `:31-38` / `:40-44` | `:31` |
| `pending_payments` :67, `:143` | `id TEXT PK`, `user_id NN`, `customer_id NN`, `amount REAL NN`, `notes`, `payment_date TEXT NN`, `created_at NN` | `queuePayment` ← `customer_debt_repository_impl.dart:129-137`; oku/sync `:167-189` | satır satır silme sync'ten sonra (`app_database.dart:188`, repo `:178`); **toplu temizlik yok** |

**Cache'i olan modüller:** faturalar (satış/alış), müşteri borçları + faturaları + ödemeleri, dashboard (finans + stok), offline ödeme kuyruğu. **Olmayanlar:** ürünler, kategoriler, müşteriler, tedarikçiler, giderler, çıkışlar, ortaklar, raporlar, stok takibi → offline'da bu ekranlar çalışmaz (5.x, AF-27).
**Oturum değişiminde cache süpürme yok** → AF-05 adımlarındaki çapraz-veri riski burada.

#### 9.5.2 SharedPreferences anahtarları
| Anahtar | Yazan | Okuyan | Varsayılan | Not |
|---|---|---|---|---|
| `user_id` | `core/services/user_service.dart:14` | `:25` | — | `UserService.getUserId()` tüm datasource'ların kimlik kaynağı |
| `user_name` | `:16` | `:30` | — | |
| `user_email` | `:19` | `:35` | — | |
| `use_arabic_number_format` | `number_formatter.dart:36` | `:23` | `false` | **`main.dart:27` her açılışta `true` yazar** → fiilen hep `true` (AF-25) |
| `selected_currency` | `:46` | `:24` | `'SYP'` | |
| `use_short_number_format` | `:56` | `:25` | `true` | |
| `CACHED_USER` | `auth_local_datasource.dart:30` | `:39` (silme `:52`) | — | JSON `User` |
| `AUTH_TOKEN` | `:61` | `:70` (`:79`) | — | **değer bu dokümanda yazılmıyor** (güvenlik); Supabase oturumu zaten kendi storage'ında tutuyor → **anahtarın pratikte kullanıldığı yol belirsiz → B** |
| `USER_ID` | `:88` | `:97` (`:106`) | — | **`user_id` ile aynı bilginin ikinci anahtarı (BÜYÜK HARF)** → iki kaynaık durum. **D çelişki** |
Tümü `prefs.clear()` ile siliniyor (`user_service.dart:40`) → logout'ta kullanıcı tercihleri de dahil her şey temizleniyor; **ancak Drift cache temizlenmiyor** (9.5.1).
**`flutter_secure_storage` bağımlılığı pubspec'te var (10.0.0) ama `lib/` içinde hiç import edilmiyor** → token'lar düz `SharedPreferences`'ta. **D; güvenlik bulgusu → 10.8**

### 9.6 Sentetik örnek kayıtlar (gerçek veri içermez)

```jsonc
// customers (POST /rest/v1/customers) — toMap çıktısı
{ "user_id":"8f2c…-uuid","code":"","name":"نموذج عميل","phone":"0900000000",
  "address":"عنوان تجريبي","city":"دمشق","credit_limit":0,
  "current_balance":12500.5,"total_purchases":0,"is_active":true,
  "created_at":"2026-01-05T14:03:22.000","updated_at":"2026-01-05T14:03:22.000","deleted_at":null }
// Dikkat: code boş (toMap code yazmıyor), id yok.

// products — toMap
{ "user_id":"…","name":"منتج تجريبي","unit":"كيلوغرام","measurement":5,   // int.parse ile yazılır
  "category_id":"3a1…","category_name":"فئات","purchase_price":100,"sale_price":150,
  "min_sale_price":120,"current_stock":0,"min_stock":10,"max_stock":null,   // current_stock zorla 0 (8.4)
  "location":null,"notes":null,"is_active":true,"created_at":"…","updated_at":"…","deleted_at":null }
// code/barcode/id yok.

// sales_invoices + sales_invoice_items — insert gövdesi (invoice_remote_datasource.dart:130-160)
{ "user_id":"…","invoice_number":"INV-20260105-4821","customer_id":"…","invoice_date":"2026-01-05T00:00:00.000",
  "subtotal":300,"discount_amount":0,"tax_amount":0,"tax_percentage":0,"shipping_cost":0,
  "total_amount":300,"paid_amount":0,"remaining_amount":300,"payment_method":"cash",
  "status":"completed","payment_status":"debt","is_finalized":false,
  "created_at":"…","deleted_at":null,"total_purchase_amount":200,"profit":100 }
// Gövde = SalesInvoice.toJson() eksi: `id` (yok), `notes` (yok), ve datasource'un sildiği
// `updated_at`, `customer_name`, `items` (invoice_remote_datasource.dart:130-138 invoiceData.remove(...)).
// items ayrı insert: {invoice_id, product_id:"null_data"!, product_name:"null_data"!, quantity, unit_price,
//   purchase_price, discount_amount, total_price, measurement:"null_data"!, unit:"null_data"!, product_id FK!}

// payments — insert (customer_debt_remote_datasource.dart:86-94)
{ "user_id":"…","customer_id":"…","payment_type":"customer","amount":250.0,
  "payment_date":"2026-01-12","notes":"دفعة تجريبية" }

// view_customer_debt_details satırı → CustomerDebtModel.fromViewMap
{ "user_id":"…","customer_id":"c-1","customer_name":"نموذج عميل","phone":null,
  "total_debt":1000.0,"total_paid":750.0 }        // totalInvoices=1000, remainingDebt=250 (9.2 anlam kayması)

// withdrawals satırı
{ "id":"w-1","user_id":"p-2",   // ← aslında PARTNER id'si (8.7 bug)
  "partner_id":"p-2","amount":500,"withdrawal_date":"2026-01-03T00:00:00.000",
  "payment_method":"cash","description":"وصف تجريبي","notes":null,
  "created_at":"…","updated_at":"…","deleted_at":null }
// liste sorgusu .isFilter('deleted_at', null) → soft delete destekli (tek modül)

// get_dashboard_financials RPC yanıtı — DashboardFinancialsModel.fromMap anahtarları (dashboard_financials.dart:27-40)
{ "user_id":"…","total_profit":0,"total_expenses":0,"net_profit":0,
  "total_customer_debt":0,"total_supplier_debt":0,"cash_in_hand":0,
  "total_withdrawals":0,"total_sales_revenue":0,"total_purchase_cost":0 }

// dashboard_product_stock satırı — DashboardProductStockModel.fromMap (dashboard_product_stock.dart:23-31)
{ "user_id":"…","product_id":"…","product_display_name":"منتج تجريبي",
  "system_stock":0,"total_purchased_qty":0,"total_sold_qty":0,"calculated_remaining_stock":0 }
// product_display_name yoksa '' olur; user_id/product_id `as String` olduğu için null → TypeError.
```

### 9.7 Model ilişkileri (FK diyagramı — metin)

```
profiles.id ──1:1── auth.users.id
profiles.id = user_id ──┬── customers.id ──┬── sales_invoices.customer_id ── sales_invoice_items.invoice_id
                        │                  │        └── products.id ← sales_invoice_items.product_id  (FK, 'null_data' yazılıyor!)
                        │                  └── payments.customer_id
                        ├── suppliers.id ── purchase_invoices.supplier_id ── purchase_invoice_items.invoice_id
                        │                            └── products.id
                        │        └── payments.supplier_id (payment_type='supplier' — kodda hiç üretilmiyor, B)
                        ├── categories.id ── products.category_id ; categories.parent_id → categories.id (self)
                        ├── expense_categories.id ── expenses.category_id
                        ├── partners.id ── withdrawals.partner_id
                        └── dashboard_product_stock / view_* : salt okuma türevleri
```
Görünen view'lar: `view_customer_debt_details`, `view_supplier_debt_details`, `view_dashboard_customer_debts`, `view_dashboard_supplier_debts` + tablolar `dashboard_product_stock`, `categories`, `products`, `profiles`, `customers`, `suppliers`, `sales_invoices`, `sales_invoice_items`, `purchase_invoices`, `purchase_invoice_items`, `payments`, `expenses`, `expense_categories`, `withdrawals`, `partners`. **`stock_movements` tablosuna hiçbir sorgu yok** (grep `from('stock_movements')` → 0) → `StockMovement` modeli ve stok hareketi defteri fiilen **uygulama dışı**. **D**

### 9.8 Bölüm 9 doğrulanamayanları
1. Supabase şemasının gerçek kolon tipleri/notnull/default/idempotent RPC davranışı → veritabanı şeması dump'ı veya `information_schema` erişimi gerekir (**15**).
2. `payments.payment_type='supplier'` üretildiği yer yok; tedarikçi ödemesi hangi alanla ayrışıyor → **B**.
3. `AUTH_TOKEN` pref anahtarının okunduğu ve gerçekten kullanıldığı yol → **B**.
4. `paid_amount` yazılmıyorsa bakiye nasıl doğru görünüyor → RPC/view tarafında hesaplanıyor olmalı → **B** (SQL gerekir).
---

## 10. API ve harici servisler

> **Güvenlik kısıtı:** Bu bölümde gerçek token/anon key/URL değeri **yazılmıyor**. Değerler `lib/core/constants/api_constans.dart:2-3` içinde kaynak koda gömülü; dosya yolu ve değişken adları veriliyor, değerler maskelendi. Yeniden yazımda §10.8'deki nedenlerle gömme **yapılmamalı**.

### 10.1 Yapılandırma ve istemci başlatma

| Konu | Değer / konum | Not |
|---|---|---|
| Paket | `supabase_flutter ^2.12.0` (`pubspec.yaml`) | PostgREST + GoTrue + Realtime tek istemci |
| Başlatma | `Supabase.initialize(url: ApiConstants.supabaseUrl, anonKey: ApiConstants.supabaseAnonKey)` — `core/di/services_locator.dart:65-67` | `initServicesLocator()` içinde, `main.dart:25` çağrısı ile **runApp öncesi** |
| Sabitler | `ApiConstants.supabaseUrl` (`api_constans.dart:2`), `ApiConstants.supabaseAnonKey` (`:3`) | **Değerler burada kopyalanmadı.** URL proje referansını içeriyor (`https://<ref>.supabase.co`); anon key JWT, `role: anon`, `iat 1761356188`, `exp 2076932188` (yani ~2036'ya kadar geçerli) — **anon key olduğu için public kabul edilse de kaynak deposunda düz metin durması §10.8 bulgusu** |
| Diğer ortam sabitleri | `.env`/`--dart-define` **kullanılmıyor** (grep: `String.fromEnvironment`, `dotenv` → 0) | Yeniden yazımda enjeksiyon noktası eklenmeli |
| `client` erişimi | `Supabase.instance.client` datasource'larda; DI'a `get_it` üzerinden `supabaseClient` kaydı var (`services_locator.dart`) | 4 sayfa (`customer_detail_page.dart:124`, `supplier_detail_page.dart:90`, `stock_tracking_page.dart:53`, `customer_invoice_detail_page.dart:101`) **doğrudan** `from()` çağırıyor → katman ihlali. **D** |
| Timeout / retry | **Yok** — `Supabase.initialize` seçenekleri geçilmemiş, hiçbir datasource'ta `timeout`, `retry`, `CancelToken` yok | Ağ askıda kalırsa UI spinner'da kalır (`Bilinmiyor` → runtime). **D** |
| Sayfa/pagination | Yalnız `products` sorgularında `.limit(50)` (`product_remote_datasource.dart:87,267`); **diğer tüm listeler sınırsız** (Supabase varsayılan 1000 satır kesmesi uygulanır ve UI'da "daha fazla" yok) | **D — büyük veri hatası sessizce kırpılır → 12** |

### 10.2 Supabase Auth çağrıları — `auth/data/datasource/auth_remote_datasource.dart`

| # | Metot | Satır | Endpoint (kitaplık içinde) | İstek gövdesi | Yanıt modeli | Çağıran |
|---|---|---|---|---|---|---|
| 1 | `login` | :34 `client.auth.signInWithPassword` | `POST /auth/v1/token?grant_type=password` | `{email, password}` | `AuthResponse` → `User` (+ `profiles` tek satır okuması) | `AuthCubit.login` → F-01 submit |
| 2 | `register` | :66 `client.auth.signUp` | `POST /auth/v1/signup` | `{email, password, data:{…}}` | `AuthResponse`; ardından :80 `profiles.insert` | `AuthCubit.register` |
| 3 | `profiles.insert` | :80-88 | `POST /rest/v1/profiles` | `{id, email, business_name, currency_code:'SAR', language:'ar', theme_mode:'light', created_at, updated_at}` (ISO **yerel**) | — | kayıt akışı |
| 4 | `logout` | :124 `client.auth.signOut` | `POST /auth/v1/logout` | — | — | `SettingsPage` → DLG-06 |
| 5 | `forgotPassword` | :143 `resetPasswordForEmail(email)` | `POST /auth/v1/recover` | `{email}` | — | DLG-09 |
| 6 | `resetPassword` | :158 `verifyOTP(...)` | `POST /auth/v1/verify` | token+şifre | — | **UI'dan çağrısız → ölü** (9.2 AF-04/6) |
| 7 | `changePassword` | :210 `signInWithPassword` **sonra** :216 `updateUser(UserAttributes(password:))` | `POST /auth/v1/token`, `PUT /auth/v1/user` | — | `User` | `AuthCubit.changePassword` — **UI'dan çağıran yok** (grep 0) → ölü |
| 8 | `getCurrentUser` | :206 `client.auth.currentUser` | yerel oturum okuma | — | `User?` | `main.dart:32` (soğuk başlangıç AF-01) |
| 9 | `updateProfile` | :180-194 `profiles.update({full_name, phone, business_name, business_address, tax_number, currency_code, language, theme_mode, updated_at}).eq('id')` | `PATCH /rest/v1/profiles?id=eq.…` | 9 kolon | `_getUserData` ile geri okuma | `settings_page.dart:192` (şirket adı kaydet) |
| 10 | `onAuthStateChange` | :232 `auth.onAuthStateChange.asyncMap(...)` | realtime/yerel olay | — | `Stream` | repository'de tanımlı; **dinleyen var mı → B** |

**Risk (D):** #9 `user.copyWith(businessName: …)` ile **tüm profil kolonları** gönderiliyor. `_currentUser` alanları bayat/null ise `full_name/phone/tax_number/business_address` **null üzerine yazılabilir**. Yeniden yazımda yalnız değişen kolon gönderilmeli.
**Risk (D):** #7 önce `signInWithPassword` yapıyor → mevcut şifre doğrulaması için; başarısızda hata mesajı İngilizce exception'dan türeyebilir (**B**).
`profiles` okuması :241-244 `.select().eq('id', userId).single()` → profil satırı yoksa PostgREST `PGRST116` → `exceptionToFailure` → `AuthError`. **D**

### 10.3 PostgREST tablo işlemleri (tam envanter)

`from('<ad>')` kullanımları `lib/` genelinde sayıldı: `sales_invoices` 15, `purchase_invoices` 15, `payments` 11, `products` 9, `suppliers` 8, `customers` 8, `sales_invoice_items` 7, `purchase_invoice_items` 7, `profiles` 7, `categories` 7, `withdrawals` 6, `expenses` 6, `expense_categories` 5, `view_supplier_debt_details` 4, `view_customer_debt_details` 4, `partners` 4, `dashboard_product_stock` 2, `view_dashboard_supplier_debts` 1, `view_dashboard_customer_debts` 1.

| Tablo/View | Opsiyonlar (R/I/U/D/S=stream) | Filtre & sıralama (kodda görünen) | Çağıran dosya |
|---|---|---|---|
| `customers` | R(:36), **S(:53)**, R by id(:65), I(:81), U(:96), D(:125) | `select()`; `order('created_at', desc)`; `eq('id')`; arama `or('name.ilike.%q%,phone.ilike.%q%,city.ilike.%q%,address.ilike.%q%')` :136-139 — **`user_id` filtresi YOK** | `customer_remote_datasource.dart` |
| `suppliers` | R, S(:51), I, U, D | `getSuppliers()` `eq('is_active', true)`; `watchSuppliers()` **is_active filtrelemiyor** (5.11); arama `eq('user_id', userId!)` + `or('name,phone,city .ilike')` :126-140 | `supplier_remote_datasource.dart` |
| `products` | R(:42), R by id(:59), I(:116), U(:131), **"D" = soft delete `update({'is_active': false})` :151**, arama(:202), S**= `.asStream()`** (:244,:268) | `select('*, categories(name)')`, `eq('user_id')`, `eq('is_active', true)`, `order('created_at', desc)`, `.limit(50)`, arama `or('name,description,sku .ilike')` :205 — **`user_id` filtresi YOK** | `product_remote_datasource.dart` |
| `categories` | R(:81), R by id(:101), I(:161), U(:177), soft delete `update({'is_active': false})` :192, **S `.asStream()`** :244/? | `select('id, user_id, name, description, parent_id, sort_order, is_active, created_at')`, `eq('user_id')`, `eq('is_active', true)`, `order('sort_order', asc)` + `order('name')` | `product_remote_datasource.dart` |
| `sales_invoices` | R(:55), R by id(:103), I(:140), U(4 site), D, S(:386) | `select('*, customers!inner(name), sales_invoice_items(*)')`, `eq('user_id')`, **`eq('customers.is_active', true)`** :59, `order('created_at', desc)` | `invoice_remote_datasource.dart` |
| `purchase_invoices` | R(:79), R by id(:118), I, U, D, S(:429) | `select('*, suppliers(name), purchase_invoice_items(*)')`, `eq('user_id')`, `order('created_at', desc)` | `invoice_remote_datasource.dart` |
| `sales_invoice_items` / `purchase_invoice_items` | R (embed), I (toplu liste), D `eq('invoice_id')` | düzenlemede **önce hepsini sil, sonra yeniden insert** (`edit_invoice_datasource.dart:107-124,163-179`) → kalem `id`'leri her kayıtta değişir | invoices datasources |
| `payments` | R(:154), I(:86), D(:178), S(:210) | `select('*')`, `eq('user_id')`, `eq('customer_id')`, `order('payment_date', desc)`; silmede `eq('id')` + `eq('user_id')` | `customer_debt_remote_datasource.dart` |
| `view_customer_debt_details` | R(:21), R+`eq('customer_id')`.single()(:110), R arama(:59 `ilike('customer_name','%q%')` — **`user_id` yok**), S tetikleyince yeniden çekme(:240) | `select('*')`, `eq('user_id')` | `customer_debt_remote_datasource.dart` |
| `view_dashboard_customer_debts` | R(:44) `.single()` | `select('*')`, `eq('user_id')` | aynı |
| `view_supplier_debt_details` / `view_dashboard_supplier_debts` | aynı kalıp (:21/:44 bölgesi, `ilike('supplier_name')` :70) | | `supplier_debt_remote_datasource.dart` |
| `expenses` | R(:135), R by id(:151), I(:173), U(:188), D(:203), **S `.asStream()`** :218 | `select('*, expense_categories(name)')`, `eq('user_id')`, `order('expense_date', desc)` | `expense_remote_datasource.dart` |
| `expense_categories` | R(:48), I(:71), U(:86), D(:101), **S `.asStream()`** :116 | `eq('user_id')`, `eq('is_active', true)`, `order('name')` | aynı |
| `withdrawals` | R(:36), R by id(:63), I(:126), U(:141), D, **S gerçek** :79 | `select()`, `eq('user_id')`, **`isFilter('deleted_at', null)`** :39, `gte/lte('withdrawal_date', iso)` :45-48, `order('withdrawal_date', desc)` | `withdrawal_remote_datasource.dart` |
| `partners` | R, I, U, D, **S gerçek** :103 | `eq('user_id')`, `order('created_at', desc)` | aynı |
| `dashboard_product_stock` | R(:54) — **view değil tablo**, `select()`, `eq('user_id')`; ayrıca `stock_tracking_page.dart:54` doğrudan okuma | sıralama yok | dashboard ds / stok sayfası |
| `profiles` | R(:241), I(:80), U(:180) | `eq('id', userId)`; `select('business_name')` (`stock_tracking_page.dart:132`, `customer_invoice_detail_page.dart:101`, `customer_detail_page.dart:124`) | auth ds + 4 sayfa |

### 10.4 RPC çağrıları (tam liste — `rpc(` grepleri)

| RPC | Parametreler | Çağıran | Ne zaman |
|---|---|---|---|
| `get_dashboard_financials` | `p_user_id`, `p_start_date`, `p_end_date` (tarih **String**) | `dashboard_remote_datasource.dart:29` | Dashboard açılışı + tarih filtresi değişimi (AF-04/AF-27); yanıt `List` ise `.first` alınır :36 |
| `update_customer_balance` | `p_customer_id`, `p_amount` (eksi işaretli gönderilebiliyor) | `customer_debt_remote_datasource.dart:183` (**ödeme silme**); `invoice_remote_datasource.dart:465-474` → `InvoiceRepository.updateCustomerBalance` → `invoice_cubit.dart:263` (`deleteSalesInvoiceWithBalanceAdjustment`), `:780`, `:925` (`updateInvoicePaymentStatusWithBalance`) | Canlı yollar: (a) ödeme silme, (b) detay ekranında ödeme durumunu `cash`'e çekme (AF-11/4), (c) `invoice_details_widget.dart:572` üzerinden fatura silme + bakiye düzeltmesi — **bu widget ölü (5.7) ve `invoice_management_page` de ölü** → (c) fiilen çalışmıyor. **Fatura oluşturmada ve ödeme EKLEMEDE çağrılmıyor** (D, 5.14/AF-15/16) |
| `update_supplier_balance` | `p_supplier_id`, `p_amount` | `supplier_debt_remote_datasource.dart:192` (ödeme silme); `edit_invoice_datasource.dart:213-222` (metot tanımlı — **`EditInvoiceCubit` tarafından çağrılıyor mu: çağrılmıyor**, 5.7/AF-10/10 ile tutarlı) | tedarikçi tarafında **yalnız ödeme silme** yolunda çalışır; ödeme ekleme/durum değişimi/fatura düzenlemede çalışmaz (D) |
| — | — | — | Yukarıdaki 3 RPC dışında `rpc(` kullanımı **yok** → `stock_movements` yazan/okuyan hiçbir çağrı ve stok düşümü RPC'si mevcut değil (D, 10.6) |

### 10.5 Realtime akışları

| Gerçek `.stream(primaryKey: ['id'])` | Dosya: satır | Konu |
|---|---|---|
| ✅ | `customer_remote_datasource.dart:54` | `customers` (`eq user_id`, `order created_at`) |
| ✅ | `supplier_remote_datasource.dart:51` | `suppliers` |
| ✅ | `invoice_remote_datasource.dart:386`, `:429` | `sales_invoices`, `purchase_invoices` |
| ✅ | `customer_debt_remote_datasource.dart:206`, `:211` | `sales_invoices`, `payments` — **`payments` stream'i müşteri/tedarikçi ayrımı yapmıyor** |
| ✅ | `supplier_debt_remote_datasource.dart:215`, `:220` | `purchase_invoices`, `payments` |
| ✅ | `withdrawal_remote_datasource.dart:80`, `:104` | `withdrawals`, `partners` |
| ✅ | `customer_detail_page.dart:192`, `:216`; `supplier_detail_page.dart:138`, `:161` | **UI katmanından** açan stream'ler (4 adet) |
| ❌ `.asStream()` (tek seferlik, gerçek realtime **değil**) | `product_remote_datasource.dart:244`, `:268`; `expense_remote_datasource.dart:121`, `:223` | ürün/kategori/gider "watch" metotları yanıp sönen veri üretmiyor → **ekran kendini yenilemez** (D, 5.17/5.23) |
Stream'ler cubit constructor'larında açılıyor, hiç `cancel`/`close` edilmiyor (3.x). Repository sarmalayıcıları akış hatasını yutuyor (`handleError`) → 12.
**B:** Realtime için Supabase tarafında `publication`'a eklenmiş kolon/tablo listesi kodda görünmüyor; hangi tabloların gerçekten yayınlandığı **Bilinmiyor** → §15.

### 10.6 Veri yazma yolları ve "stok donduruldu" bulgusu

| Yazma yolu | Tablo(lar) | Ek not |
|---|---|---|
| Satış faturası oluştur | `sales_invoices.insert` → `sales_invoice_items.insert(liste)` | `invoiceData.remove('updated_at' \| 'customer_name' \| 'items')` :134-138; kalem gövdelerinde `product_id/product_name/measurement/unit` için **`?? 'null_data'`** :151-159 → **FK kolonuna FK olmayan literal yazılıyor**. Ardından `log('Stock şimdilik donduruldu - Invoice status = …')` :167 — **ürün stoğu güncellenmiyor** |
| Alış faturası oluştur | `purchase_invoices.insert` → `purchase_invoice_items.insert` | :220 `log('Stock şimdilik donduruldu - Creating purchase invoice')` → **alışta da stok artmıyor** |
| Fatura düzenle | `sales_invoices.update` + `items delete/insert` + `update_customer/supplier_balance` RPC | :127,:182 `// Stock şimdilik donduruldu` yorumu |
| Fatura sil | kalem + fatura silimi; müşteri/tedarikçi silmede 4 adımlı cascade (5.10/5.11) | transaction **yok** |
| Ödeme ekle | `payments.insert` + `syncPendingPayments()` | bakiye RPC'si **çağrılmıyor** |
| Ödeme sil | `payments.delete` + `update_*_balance` RPC | **sadece bu yolda RPC var** |
| Ürün/gider/çıkış/ortak/müşteri/tedarikçi ekle | tek `insert` | `toMap` eksikleri §9.2 |
| **Stok takibi ekranı** | **salt okuma** (`categories`, `dashboard_product_stock`, `products`, `profiles`) | `stock_tracking_page.dart:53-55,132`; `dashboard_product_stock` view/tablosu **DB tarafında hesaplanan** bir türev → uygulamanın kendisi stok hareketi üretmiyor (D) |

**Sonuç (D):** Uygulama **stok düşümü/maliyet muhasebesini istemci tarafında yapmıyor**; stok değerleri Supabase tarafındaki tablo/view'dan geliyor. `StockMovement` modeli ve `stock_movements` tablolaştırması atıl. Yeniden yazımda bu bilinçli bir sınırlama olarak ele alınmalı ya da DB tarafına RPC/trigger eklenmeli (§13 faz planı).

### 10.7 Harici paketler ve SDK davranışları

| Paket | Sürüm | Kullanım | Ağ/davranış notu |
|---|---|---|---|
| `supabase_flutter` | ^2.12.0 | auth + PostgREST + realtime | tek harici backend |
| `google_fonts` | ^6.2.1 | `GoogleFonts.changaTextTheme` (`main.dart:47`), 25× `GoogleFonts.cairo`, 2× `inter` (ölü getter'lar) | **İlk çalıştırmada fontları ağdan indirir**; offline'da fallback → §12. **D** |
| `pdf` + `printing` | ^3.11.3 / ^5.14.2 | `PdfInvoiceService` (864 satır, **canlı**, 5 çağrı: `invoice_detail_page.dart:463`, `customer_detail_page.dart:133`, `supplier_detail_page.dart:99`, `stock_tracking_page.dart:145`, `customer_invoice_detail_page.dart:116`) → `Printing.sharePdf`; `InvoicePdfService` (245 satır) → `Printing.layoutPdf:192` **yalnız ölü `invoice_details_widget.dart:595` tarafından çağrılıyor → ölü servis** | Paylaşım sheet'i platform API'sine devreder (11) |
| `arabic_reshaper` ^0.0.1 + `intl` | | PDF'te `Bidi.logicalToVisual` | yalnız PDF; UI'ı RTL `Directionality` hallediyor |
| `drift` ^2.34.0 | | §9.5.1 cache | sqlite dosyası `erad_cache.db` |
| `shared_preferences` ^2.5.4 | | §9.5.2 | |
| `flutter_secure_storage` ^10.0.0 | | **hiç import edilmiyor** (grep 0) | tercih edilseydi token'lar burada olmalıydı — **D bulgu** |
| `internet_connection_checker` ^3.0.1 | | `core/network/network_info.dart` → `NetworkInfoImpl.hasConnection` | gerçek HTTP isteği atarak değil, bağlantı kontrolü ile; §12 |
| `fl_chart` ^1.1.1 | | gider + çıkış bar grafikleri | |
| `syncfusion_flutter_charts` ^28.2.8 | | **`FinancialAreaChart` ölü** (5.25) | bağımlılık boşuna yük |
| `iconsax` ^0.0.8 | | 14 dosya | ikon fontu pakette |
| `get_it` ^9.2.0 | | `core/di/services_locator.dart` | büyük çoğunluk `registerFactory` |
| `flutter_bloc` ^9.1.1, `equatable`, `dartz` | | Cubit + `Either<Failure,T>` | |
| `uuid` ^4.5.1 | | **`lib/` içinde kullanımı yok** (grep) | boşa bağımlılık — **D** |
| `provider` ^6.1.5+1 | | **tek satır import**: `invoice_detail_page.dart:8` — dosyada `Provider`/`Consumer` kullanımı yok → **ölü import**, bağımlılık fiilen gereksiz | boşa bağımlılık — **D** |
| `path_provider` ^2.1.5 | | **canlı**: `core/database/app_database.dart:6` → sqlite dosya yolu | gerekli — **D** |
| `flutter_launcher_icons` / `flutter_native_splash` | dev | §11 | |
| Analytics / crash / push / advertising | — | **YOK** (grep `firebase\|analytics\|sentry\|crashlytics\|local_notifications` → yalnız `AppStrings.analytics` sabiti ve `Navigator.push`) | Hata raporlama yok → üretim hataları **toplanmıyor**, §15 |

### 10.8 Güvenlik bulguları (API katmanı)

| # | Bulgu | Etki | Öneri (yeniden yazım) |
|---|---|---|---|
| 1 | Anon key ve URL kaynak koda gömülü (`api_constans.dart:2-3`), `.env`/`dart-define` yok | Git geçmişinde kalıcı; rotasyon zor | Build-time enjeksiyon + ayrı ortam dosyaları |
| 2 | `flutter_secure_storage` bağımlı ama kullanılmıyor; `AUTH_TOKEN` düz `SharedPreferences`'ta (`auth_local_datasource.dart:61`) | Cihaz root/adb ile okunabilir | SecureStorage'a taşı veya Supabase'in kendi storage'ına bırak, çift kaydı sil |
| 3 | Arama sorgularında `user_id` filtresi yok: `customers` (:136), `products` (:202), `view_customer_debt_details` (:59), `view_supplier_debt_details` (:70) | **RLS yoksa diğer kiracıların verisi sızar**; RLS varsa yalnız performans kaybı | Filtreyi ekle + Supabase RLS politikalarının dump'ı incelenmeli (**Bilinmiyor**, §15) |
| 4 | `customer_debts` repository'sinin remote `searchCustomerDebts` yolu UI'dan çağrılmıyor (5.11) ama **kodda duruyor** | Yanlışlıkla çağrılırsa 3. maddedeki sızıntı aktif olur | Ölü kodu sil |
| 5 | SQL injection riski: `.or('name.ilike.%$query%…')` metin interpolasyonu (`customer:138`, `supplier:133`, `product:205`) | PostgREST filtresine `%`, `,`, `()` enjekte edilebilir → filtre manipülasyonu (parametrik SQL değil) | Girdi doğrulama/escape veya RPC |
| 6 | Silme işlemleri transaction dışında, cascade elle (5.10/5.11) | Yarı silinmiş veri | DB trigger/transaction veya RPC |
| 7 | Şifre sıfırlama `verifyOTP` yolu ölü; `changePassword` ölü | Kullanıcı şifresini uygulama içinden değiştiremez | Gerekiyorsa ekran + akış eklenmeli (§15 soru) |
| 8 | Hata mesajları doğrudan `Exception.toString()` / Supabase İngilizce metni ile gösterilebiliyor (`SnackBar(Text(state.message))`) | İç detay sızıntısı + dil tutarsızlığı | Mesaj sözlüğü |

### 10.9 Abonelik ömrü tablosu (düzeltmeli bulgu)

| Cubit | `close()` override + `cancel()` | Sayfa provider tipi | Sonuç |
|---|---|---|---|
| `AuthCubit` | stream yok | `main.dart:31` `create`, `login_page.dart:14` `create` | sorun yok |
| `CustomerCubit` | `:111` cancel | `customers_page.dart:51` **`create`** (`sl<CustomerCubit>()` instance State'te) | dispose → kapanır. **D** |
| `SupplierCubit` | `:110` | `suppliers_page.dart` `create` | kapanır |
| `InvoiceCubit` | `:937-943` (2 abonelik) | `main.dart` route `create`, `dashboard_page.dart` `create(lazy:true)`, invoice sayfaları `create` | kapanır |
| `CustomerDebtCubit` / `SupplierDebtCubit` | `:172` / `:237` | `create` | kapanır |
| `ExpenseCubit` | `:128` | `create` | kapanır (yalnız `.asStream()` sahte akış → gerçek abonelik yok) |
| `WithdrawalCubit` | `:248` | `create` | kapanır |
| **`ProductCubit`** | `:245-249` cancel ediliyor | **`products_page.dart:78,236,323` `BlocProvider.value`** | **`close()` hiç çağrılmıyor** → `products`/`categories` abonelikleri sayfa kapandıktan sonra da emit eder; her yeniden açılışta `sl<ProductCubit>()` yeni instance + yeni abonelik (**biriken sızıntı**). `dashboard_page.dart` `ProductCubit`'i `create` ile sarıyor → orada dispose olur; **aynı tip iki farklı ömür kuralı** tutarsızlığı. **D** |

Ek: `customer_detail_page.dart:61-65` `dispose()` içinde `_cancelSubscriptions()` çağrılıyor (:176-179) ve stream'ler UI'dan açılıyor (:192,:216) → **bu iki sayfada** abonelikler düzgün kapanıyor. `supplier_detail_page.dart:55-58,126-127` aynı. **D**

### 10.10 Bu bölümde doğrulanamayanlar
1. **Supabase RLS politikaları** — sorgulardan görünmüyor; çok kiracılı izolasyonun gerçekten sunucuda mı uygulandığı **Bilinmiyor**. Gereken: `pg_policies`/`supabase` dashboard dump'ı.
2. `get_dashboard_financials`, `update_customer_balance`, `update_supplier_balance` fonksiyonlarının **imzası/gövdesi** (SECURITY DEFINER mi, hangi tabloyu nasıl günceller) — DB tarafı gerekli.
3. `view_*` view'larının tanımları (`total_debt` hangi faturalardan, `paid_amount` nereden) — §9.8/4 ile aynı boşluk.
4. Realtime `publication` listesi (§10.5 notu).
5. Ağ hatası/timeout davranışı gerçek sürede (§12.4) — çalıştırma gerekir.

---

## 11. İzinler, cihaz özellikleri, platform davranışı

> Yöntem: `android/`, `web/`, `windows/` dizinleri ve `pubspec.yaml` yapılandırması satır satır okundu; `lib/` içinde platform koşullu kod (`kIsWeb`, `Platform.is*`, `SystemChrome`, `TargetPlatform`) ve donanım/izin plugin kullanımı grep ile arandı. **Uygulama çalıştırılamadığı için** hiçbir izin diyalogu, status bar görünümü, notch/safe-area davranışı veya Android sürümüne özgü sonuç **görsel olarak doğrulanamadı** → 11.9.

### 11.1 Platform hedefleri

| Platform | Dizin var mı | Durum | Kanıt | Etiket |
|---|---|---|---|---|
| Android | `android/` (app/src: debug, main, profile) | **tek gerçek hedef** | `android/app/build.gradle.kts`, `android/app/src/main/AndroidManifest.xml` | Doğrulandı (yapı), Bilinmiyor (çalışma) |
| Web | `web/` (`index.html`, `manifest.json`, `icons/`, `favicon.png`) | Flutter dosyaları var ama **derlenemez**: `lib/core/database/app_database.dart:2` `import 'dart:io'` + `:13` `NativeDatabase(File)` → dart2js `dart:io` desteklemez | dosya içerikleri | Çıkarım (güçlü) |
| Windows | `windows/` (CMakeLists, runner/) | runner `_window.Create(L"erad", …, Size(1280, 720))` (`windows/runner/main.cpp:28-30`) — standart şablon, özelleştirme yok | `main.cpp`, `Runner.rc:92-99` (`CompanyName=com.example`, `2026 com.example` telif satırı) | Doğrulandı (dosya), Bilinmiyor (runtime; 11.5'teki `dart:io` sınırlaması masaüstünde geçerli değil ama sqlite dosya yolu gerektirir) |
| iOS | **yok** | `flutter_launcher_icons ios: false` (`pubspec.yaml:86`) → `Info.plist` izin anahtarları, bundle id, cihaz sınırlamaları hakkında **hiçbir şey söylenemez** | `ls`, `pubspec.yaml:83-88` | Doğrulandı (yokluk) |
| macOS / Linux | yok | — | `ls` | Doğrulandı (yokluk) |

### 11.2 Uygulama kimliği ve derleme yapılandırması

| Anahtar | Değer | Kaynak | Not |
|---|---|---|---|
| Paket adı | `erad` | `pubspec.yaml:1` | `import 'package:erad/…'` |
| Sürüm | `1.0.0+1` | `pubspec.yaml:19` | tek sürüm, ortam varyantı yok |
| Dart SDK | `^3.10.7` | `pubspec.yaml:23` | yeniden geliştirmede aynı veya üstü gerekir |
| Android `namespace` / `applicationId` | **`com.example.mindPrint`** | `android/app/build.gradle.kts:9,18` | proje adıyla ilintisiz; başka bir projeden kopyalama kalıntısı. Mağaza kaydı bu kimlikle yapılır. **Doğrulandı** |
| Launcher etiketi | `إيراد` | `main/AndroidManifest.xml` `android:label` | `applicationId` ile ilgisi yok |
| `MainActivity` | `com.example.mindPrint.MainActivity : FlutterActivity` | `android/app/src/main/kotlin/com/example/zadana_user_v3/MainActivity.kt` | **dosya yolu ile paket adı uyuşmuyor** (Kotlin için sorun değil). Manifest `.MainActivity` → `com.example.mindPrint.MainActivity`'ı çözüyor ve bu sınıf bu dosyada tanımlı → çalışır. **Doğrulandı** |
| İkinci `MainActivity` | `package com.example.erad` | `.../com/example/erad_accounting_system/MainActivity.kt` | hiçbir manifest bu pakete referans vermiyor → **ölü dosya**. Yeniden geliştirmede silinmeli. **Doğrulandı** |
| Java / AGP / Kotlin | Java 17, AGP `8.11.1`, Kotlin `2.1.0` | `build.gradle.kts:12-15`, `settings.gradle.kts:31-32`, `:44-58` | `gradle.projectsLoaded` içinde `resolutionStrategy` ile **tüm plugin alt projlerine zorlanıyor** |
| Maven depoları | **Aliyun aynaları birincil**, `google()/mavenCentral()` fallback | `settings.gradle.kts:9-13`, `:38-42` | aynalar erişilemezse derleme patlar; coğrafi/şirket ağı bağımlılığı. **Doğrulandı** |
| `minSdk` / `targetSdk` / `compileSdk` | `flutter.minSdkVersion` vb. | `build.gradle.kts:22-27` | **sayısal değerler repo'da yazılı değil**, Flutter SDK sürümüne bağlı → Bilinmiyor (çıkışı `flutter build apk --verbose` veya SDK sabitleri gerekir). `flutter_launcher_icons.min_sdk_android: 21` (`pubspec.yaml:88`) yalnız ikon üretimi için |
| Release imzası | `signingConfig = signingConfigs.getByName("debug")` | `build.gradle.kts:36-39` | **release APK debug anahtarla imzalanıyor** → Play Store'a yüklenemez, dağıtım kimliği doğrulanamaz. Kritik bulgu. **Doğrulandı (satır), Çıkarım (etki)** |
| Yerel dosya | `android/local.properties` repoda | `ls android` | `flutter.sdk` mutlak yolu içerir → makine bağımlı; `.gitignore`'a eklenmeli. **Doğrulandı (varlık)** |

### 11.3 Bildirilen Android izinleri ve bunları kullanan kod

Tüm izinler `android/app/src/main/AndroidManifest.xml:3-10` içinde; `debug/` ve `profile/` manifestlerinde yalnız `INTERNET` var.

| İzin | Bunu kullanan uygulama kodu | Ne zaman isteniyor | Reddedilirse ne olur | Değerlendirme |
|---|---|---|---|---|
| `INTERNET` | Supabase (`services_locator.dart:65-69`), `google_fonts` runtime indirme, `printing` | kurulumda (normal izin) — diyalog yok | kaldırılamaz | gerekli — **D** |
| `ACCESS_NETWORK_STATE` | `internet_connection_checker` → `NetworkInfoImpl` (`core/network/network_info.dart:26-36`), `services_locator.dart:62` | kurulumda | — | gerekli — **D** |
| `RECORD_AUDIO` | **yok** — grep: `record`, `audio_session`, `MediaRecorder` → 0 eşleşme | hiçbir zaman | — | **kullanılmayan izin**, kaldırılmalı — **D** |
| `MODIFY_AUDIO_SETTINGS` | **yok** | hiçbir zaman | — | **kullanılmayan izin** — **D** |
| `WRITE_EXTERNAL_STORAGE` | **yok**. PDF çıktısı `Printing.sharePdf` ile plugin'in kendi `FileProvider`/intent paylaşımı üzerinden gidiyor; uygulama hiçbir dosyayı harici depoya yazmıyor (`path_provider` yalnız app-documents → `app_database.dart:11`) | hiçbir zaman | — | **kullanılmayan izin**; Android ≥ 23'te zaten fiilen etkisiz — **D + Çıkarım** |
| `READ_EXTERNAL_STORAGE` | **yok** | hiçbir zaman | — | **kullanılmayan izin** — **D** |

Kesin sonuçlar:
- **Uygulama hiçbir çalışma zamanı izin diyalogu göstermez.** `permission_handler` bağımlılığı yok (`pubspec.yaml:30-60` listesi), `lib/` içinde izin sorma kodu yok. Bölüm 5 ekran envanterinde "izin ekranı" olmaması bununla tutarlı. **D**
- 6 izinden **4'ü gereksiz**; mağaza inceleme sürecinde "unused permission" uyarısı ve gereksiz yetki algısı yaratır. Yeniden geliştirmede yalnız `INTERNET` + `ACCESS_NETWORK_STATE` kalmalı. **D**
- `android:maxSdkVersion` hiç verilmemiş; `uses-permission` dışında `<uses-feature>` declarations yok → kamera/mikrofon donanım zorunluluğu işaretlenmiyor (filtreleme kaybı). **D**

### 11.4 Android pencere, system bar ve yaşam döngüsü davranışı

| Konu | Yapılandırılmış değer | Kaynak | Etki |
|---|---|---|---|
| Cleartext traffic | `android:usesCleartextTraffic="true"` | `main/AndroidManifest.xml` | **düz HTTP serbest** — Supabase HTTPS, ancak yapılandırma gereksiz risk taşır; `network_security_config` yok. Güvenlik bulgusu — **D** |
| Activity | `exported=true`, `launchMode=singleTop`, `taskAffinity=""`, `hardwareAccelerated=true` | aynı | standart Flutter şablonu; `singleTop` → simgeden yeniden açılışta yeni instance yok |
| Yazım alanı | `windowSoftInputMode=adjustResize` | aynı | klavye içeriği iter; Flutter tarafında `resizeToAvoidBottomInset` dashboard'da **yorum satırı** (`dashboard_page.dart:108`) → varsayılan `true`. **D** |
| `configChanges` | `orientation\|keyboardHidden\|keyboard\|screenSize\|smallestScreenSize\|locale\|layoutDirection\|fontScale\|screenLayout\|density\|uiMode` | aynı | rotasyonda Activity yeniden başlamıyor, Flutter yeniden layout yapıyor |
| Yönelim kilidi | **yok** — `SystemChrome.setPreferredOrientations` kullanılmıyor (grep 0) | `lib/` | telefon/tablet her yönde dönebilir; tek breakpoint `width<600` (`edit_product_add_widget.dart:161`). Landscape/tablet düzeni **kodda tasarlanmamış** — **D + Çıkarım** |
| Launch teması | `Theme.Light.NoTitleBar`, `windowBackground=@drawable/launch_background` (`background.png` fill + `splash.png` center), `forceDarkAllowed=false`, `windowFullscreen=false`, `windowDrawsSystemBarBackgrounds=false`, `windowLayoutInDisplayCutoutMode=shortEdges` | `res/values/styles.xml:3-15`, `res/drawable/launch_background.xml` | splash beyaz zemin + logo; notch/cutout bölgesine kadar çizilir → üst içerik kesinti riski **çalıştırılmadan doğrulanamaz** |
| Normal tema | `windowBackground=?android:colorBackground` | `styles.xml:20-22` | ilk frame öncesi arka plan sistem rengi; uygulamanın `AppColors.background #FFFFFF` sabitinden bağımsız — **Çıkarım** |
| Gece / API 31 varyantları | `values-night/styles.xml`, `values-v31/styles.xml`, `drawable-*/android12splash.png` | `find android/app/src` | `flutter_native_splash` (android_12: renk `#FFFFFF`) bir kez çalıştırılmış; üretilmiş çıktılar repoda — **D** |
| Status bar / navigation bar | `SystemChrome.setSystemUIOverlayStyle`, `AnnotatedRegion` **yok** (grep 0) | `lib/` | bar renkleri kodla kontrol edilmiyor → sistem varsayılanı; **görsel doğrulanamadı** |
| Derin bağlantı | intent-filter yalnız `MAIN`/`LAUNCHER`; `android:scheme`/`host` yok; `app_links`/`uni_links`/`firebase_dynamic_links` bağımlılığı yok | manifest, `pubspec.yaml` | **uygulama hiçbir URL/intent yakalamaz** → şifre sıfırlama bağlantısı (10.8 #7) uygulama içinde tüketilemez; `resetPassword` zaten ölü. **D** |
| Bilirim/push | `Firebase`, `flutter_local_notifications`, FCM yok (grep 0) | `pubspec.yaml`, `lib/` | bildirim ekranı/akışı yok — Bölüm 5 "derin bağlantı/bildirim ekranı" maddesinin cevabı: **yok** |
| Yaşam döngüsü | tek `WidgetsBindingObserver`: `dashboard_page.dart:33-34, 122-127, 92-96`; yalnız `didChangeMetrics` (`viewInsets.bottom > 100`) | `lib/` | `didChangeAppLifecycleState` **yok** → arka plana alma/ön plana dönüşte özel davranış yok: oturum yenileme, stream yeniden bağlama, cache yazma yapılmıyor. `_isKeyboardVisible` bayrağı build'de kullanılmıyor (ölü durum, Bölüm 7 notu). **D** |
| Pano | `Clipboard` kullanımı yok (grep 0) | `lib/` | manifest'teki `PROCESS_TEXT` sorgusu yalnız engine şablonundan; kopyala/yapıştır özelliği yok — **D** |

### 11.5 Platforma koşullu kod ve uyarlanabilir düzen

`lib/` içinde **platform dallanması hiç yok**: `kIsWeb` 0, `Platform.isAndroid/isWindows/...` 0, `TargetPlatform` 0, `defaultTargetPlatform` 0. Tek kod tabanı tüm hedeflere aynı davranıyor. **D**

Bunun yerine ölçüm tabanlı (`MediaQuery`) uyarlamalar var:

| Yer | Ölçü | Ne yapar | Etiket |
|---|---|---|---|
| `edit_product_add_widget.dart:161` | `isMobile = width < 600` | :211'de ek alan bloğunu koşullu basıyor; `product_list_widget.dart:166,210` aynı bayrağı `isMobile: true` geçiriyor | **D** — projedeki **tek** gerçek breakpoint |
| `custom_app_drawe.dart:13` | `width * 0.72` (Drawer) | `CustomAppDrawer(` çağrısı **0** → kullanılmıyor | **D** |
| `app_sidebar.dart:30` | `width * 0.13` (min 200) | `AppSidebar(` çağrısı **0** → kullanılmıyor | **D** |
| `suppliers_page.dart:111` | `height * 0.5` | bottom sheet yüksekliği | **D** |
| `customer_list_widget.dart:224` | `height * 0.45` | bottom sheet yüksekliği | **D** |
| `debt_stats_widget.dart:37,40` (iki modül) | `screenWidth` | kart genişliği hesabı | **D** |
| `main.dart:47` builder | `textScaler.clamp(0.8, 1.0)` | sistem font ölçeği 0.8–1.0 arasına sıkıştırılıyor | **D** |
| SafeArea | 9 sayfa: `customers_page.dart:56`, `settings_page.dart:46`, `expenses_page.dart:168`, `products_page.dart:80`, `supplier_detail_page.dart:412`, `product_add_fullscreen_widget.dart:137`, `invoice_detail_page.dart:114`, `withdrawals_page.dart:139`, `suppliers_page.dart:57`, `customer_detail_page.dart:498` | üst/alt çentik boşluğu bu sayfalarda korunuyor | **D** |

Kritik tutarsızlık: **dashboard'un özel alt navigasyonu `SafeArea` içinde değil** (`dashboard_page.dart:109-157`), :111'deki `MediaQuery.of(context).padding.bottom > 0 ? 8 : 12` hesabı **yorum satırı**. Ayrıca masaüstü "sidebar" tasarımı (`AppSidebar`) ve mobil `Drawer` tasarım her ikisi de bağlanmamış → **geniş ekranda da alt navigasyon** kullanılıyor (tek gerçek navigasyon yolu). Gesture navigation / masaüstü penceresinde barın system overlay altında kalıp kalmadığı **çalıştırılmadan doğrulanamaz**.

### 11.6 Cihaz donanımı ve harici platform servisleri

| Özellik | Kullanım | Kanıt |
|---|---|---|
| Kamera, mikrofon, GPS, NFC, biyometri, sensör, titreşim | **YOK** | bağımlılık listesi (`pubspec.yaml:30-60`) + grep |
| Yazdırma / PDF paylaşımı | `Printing.sharePdf` — **5 canlı çağrı**: `invoice_detail_page.dart:466`, `customer_detail_page.dart:143`, `supplier_detail_page.dart:109`, `stock_tracking_page.dart:152`, `customer_invoice_detail_page.dart:125` → OS paylaşım paneli açılır | **D** |
| Doğrudan yazdırma dialogu | `Printing.layoutPdf` yalnız `invoice_pdf_service.dart:192`; ona giden tek yol `InvoiceDetailsWidget._printInvoice` (`invoice_details_widget.dart:594-596`) ve **`InvoiceDetailsWidget` hiçbir yerde inşa edilmiyor** (grep: yalnız kendi dosyası) → yazdırma akışı fiilen erişilemez | **D + Çıkarım** |
| Arapça metin yönü (PDF) | `ArabicReshaper.instance.reshape` (`pdf_invoice_service.dart:859`) + `Bidi.logicalToVisual` → PDF'te Arapça doğru basılır; UI RTL'i ise Flutter `Directionality` ile (11.7) | **D** |
| Yerel veritabanı dosyası | `erad_cache.db`, `getApplicationDocumentsDirectory()` (`app_database.dart:11-13`) | **D** |
| Anahtar deposu | `shared_preferences` (düzyazı), `flutter_secure_storage` bağımlı ama **kullanımsız** | Bölüm 9/10.8 #2 — **D** |
| Ağ durumu | `InternetConnectionChecker.createInstance()` (`services_locator.dart:62`) → varsayılan konfigürasyon; bu paket TCP probe kullanır, **web'de tarayıcı sınırlaması** nedeniyle güvenilir değil (paketin web fallback'i var ama davranış doğrulanamadı) | **D (kod), Bilinmiyor (web)** |
| Offline kuyruk / senkron | Supabase tarafında offline queue yok (`Supabase.initialize` yalnız `url` + `anonKey`, `services_locator.dart:65-68`) → çevrimdışıyken **yazma işlemleri kaybolur**; salt-okuma cache Bölüm 9.7 | **D + Çıkarım** |
| Oturum dinleyicisi | `userChanges` (`auth_remote_datasource.dart:231-237`, `client.auth.onAuthStateChange` üzerinden) **tanımlı ama hiç tüketilmiyor** (grep: tek eşleşme kendi tanımı) → token düşmesi/başka cihazdan çıkış UI'ya yansımıyor; sonraki istek hata verene kadar uygulama "oturum açık" görünüyor | **D + Çıkarım** |
| Analitik / crash reporting / push | **YOK** | Bölüm 10.7 |

### 11.7 Dil, yazı tipi ve asset davranışı (ağ bağımlılığı)

| Konu | Durum | Kaynak | Etiket |
|---|---|---|---|
| Bildirim edilen assetler | yalnız `- assets/images/` | `pubspec.yaml:83-84` | D |
| Asset dosyaları | `assets/images/logo.png`, `assets/images/log_outline.png` (2 dosya) | `ls assets/images` | D |
| Font asset | **`fonts:` bölümü yok** — `AppFonts.arabicFont/latinFont` sabitleri kullanılmıyor | `pubspec.yaml`, `app_constants.dart` | D |
| Fontların kaynağı | `google_fonts` runtime indirme: `GoogleFonts.changaTextTheme()` (`main.dart:47`) + `GoogleFonts.cairo*` (`app_theme.dart:24-210`) → ilk kullanımda Google Fonts CDN'inden indirilip uygulama dizinine cache'leniyor | kod | D |
| Sonuç | **ilk açılışta ağ yoksa tüm metinler sistem varsayılan fontuyla çizilir**; Bölüm 6'daki font boyutu/ağırlık/satır yüksekliği gözlemleri bozulur. Yeniden geliştirmede fontların `pubspec.yaml`'a gömülmesi önerilir | — | Çıkarım |
| Dil | `locale: Locale('ar')`, `supportedLocales` tanımsız, `flutter_localizations`/ARB yok → tek dil, çeviri altyapısı yok; `intl` yalnız sayı/tarih biçimlendirme için (`NumberFormatter`, `initializeDateFormatting('en')` `main.dart:29`) | `main.dart:44-52` | D |
| RTL | `builder` içinde global `Directionality(textDirection: TextDirection.rtl)` (`main.dart` builder) → tüm ekranlar RTL; `flutter_localizations` olmadığı için Material widget metinleri İngilizce kalabilir (doğrulanamadı) | `main.dart` | D + Bilinmiyor |
| Splash | `flutter_native_splash`: renk `#FFFFFF`, `image: assets\images\log_outline.png` (**Windows ters bölü**), `android_12` aynı, `web: false` | `pubspec.yaml:90-96` | D (satır), Çıkarım (yol hatası riski) |
| Launcher icon | `android: true`, `ios: false`, `image_path: assets/images/logo.png`, `adaptive_icon_background: "#FFFFFF"`, `min_sdk_android: 21`; üretilmiş `mipmap-*/ic_launcher.png` repoda | `pubspec.yaml:83-88`, `res/mipmap-*` | D |
| Web manifest | `background_color`/`theme_color`: `#0175C2` (Flutter varsayılanı), `orientation: portrait-primary`, `name/short_name/description`: `erad` / "A new Flutter project." | `web/manifest.json`, `web/index.html:20-33` | D — **uygulamanın `#0F1B3D` paletiyle çelişiyor**, ancak web derlemesi zaten olanaksız (11.1) |

### 11.8 Tema ve koyu mod

- `MaterialApp` yalnız `theme: AppTheme.lightTheme.copyWith(textTheme: GoogleFonts.changaTextTheme())` veriyor; `darkTheme` ve `themeMode` parametreleri **yok** (`main.dart:44-47`) → **sistem koyu modda bile uygulama her zaman light**. `styles.xml` içinde `android:forceDarkAllowed=false` bunu Android penceresi için pekiştiriyor. **D**
- `app_theme.dart:11` `brightness: Brightness.light` tek tema; `_buildTextTheme(Brightness brightness)` parametre alıyor ama koyu tema üreten çağrı yok. **D**
- Kullanıcı modelinde `themeMode` alanı var ve `profiles.theme_mode='light'` DB'ye yazılıyor (`auth_remote_datasource.dart:86,104,189`, `user.dart:13,27,89,106`), **UI hiçbir yerde okumuyor** (grep: `themeMode` yalnız model/datasource satırlarında) → ölü yapılandırma. **D**
- Erişilebilirlik: `Semantics`, `Tooltip`, `ExcludeSemantics` kullanımı **yok** (grep 0); `textScaler` 0.8–1.0 ile sınırlı (11.5); `focusOrder`/`focusNode` tanımları yok. `debugShowCheckedModeBanner: false`. **D**

### 11.9 Bu bölümde doğrulanamayanlar (Bölüm 15'e taşınır)

1. İzin diyalogları: 4 kullanılmayan izin için sistem diyalogu hiç açılmıyor mu, `sharePdf` Android 13+ medya izinlerini istiyor mu — **ekranlı cihaz/emülatör gerekir**.
2. Status bar / navigation bar rengi ve ikonları, gesture navigation altında alt barın kesilmesi (11.5) — **çalıştırma gerekir**.
3. Notch/cutout (`shortEdges`) ile üst içeriğin çakışıp çakışmadığı, landscape/tablet düzeninin okunabilirliği — **çalıştırma gerekir**.
4. `minSdk/targetSdk/compileSdk` sayısal değerleri — **`flutter --version` + SDK sabitleri gerekir**.
5. Web derlemesinin gerçekten `dart:io` nedeniyle başarısız olup olmadığı — **`flutter build web` çıktısı gerekir**.
6. Windows hedefinde `printing` paylaşım dialogu ve sqlite dosya yolunun çalışıp çalışmadığı — **Windows'ta derleme/çalıştırma gerekir**.
7. `google_fonts` indirmesi başarısız olduğunda uygulamanın hata fırlatıp fırlatmadığı (fallback mi crash mi) — **çalıştırma/`pubspec` font gömme testi gerekir**.
8. iOS davranışı: `ios/` olmadığı için tamamen **kapsam dışı**.

---

## 12. Durumlar, hatalar ve sınır durumları

> Kural: her bulguda **koşul → gözlemlenebilir sonuç** veriliyor; kodun söyleyemediği runtime sonuçlar ayrı listelendi (12.9).

### 12.1 Durum taksonomisi (kodda nasıl temsil ediliyor)

| Durum sınıfı | Kaynak | Not |
|---|---|---|
| `AuthLoading / Authenticated / Unauthenticated / AuthError / AuthSuccess / AuthRegistered` | `features/auth/presentation/bloc/auth_cubit.dart` | Bölüm 7 AF-01'de dallanma haritası |
| `<Modül>Loading / <Modül>Loaded(Filtered/Success) / <Modül>Error(message)` | `invoice_cubit.dart`, `product_cubit.dart`, `customer_cubit.dart`, `supplier_cubit.dart`, `customer_debt_cubit.dart`, `supplier_debt_cubit.dart`, `expense_cubit.dart`, `withdrawal_cubit.dart`, `dashboard_cubit.dart`, `party_invoice_cubit.dart`, `edit_invoice_cubit.dart` | her modülün kendi hata sınıfı var; ortak bir `AppErrorState` yok |
| Hata nesnesi alanı | `state.message` (düz `String`) | hata kodu/tipi UI'ya taşınmıyor → **programatik dallanma yapılamıyor** (ör. 401 → login'e dön) — **D** |
| Yüklenme görseli | 47 `CircularProgressIndicator` çağrısı (`lib/`) | **skeleton/shimmer yok** (grep `Shimmer\|Skeleton` → 0) — **D** |
| Ortak durum widget'ları | `EmptyStateWidget` (`core/widgets/common_widgets.dart:179`), `LoadingWidget` (:233), `CustomButton` (:4), `CustomTextField` (:70) | **dışarıdan kullanımları 0** (grep: `LoadingWidget(`/`CustomButton(`/`CustomTextField(` → 0; `EmptyStateWidget(` tek kullanımı `withdrawals` modülünün **aynı adlı başka sınıfı**) → paylaşılan durum katmanı fiilen **ölü**, her ekran kendi durum görünümünü elle yazıyor — **D** |
| Ad çakışması | `core/widgets/common_widgets.dart:179` `EmptyStateWidget` ile `features/withdrawals/presentation/widgets/empty_state_widget.dart:3` `EmptyStateWidget` | iki farklı sınıf, aynı ad; ilki `title` zorunlu, ikici argsız — yeniden geliştirmede tek hale getirilmeli — **D** |
| `StatusBadge` | `common_widgets.dart:265` | tek kullanım `core/widgets/invoice_card_widget.dart:224` (kendi private `_buildStatusBadge`'i değil, import ettiği tip) — Bölüm 6.4 |

### 12.2 Yüklenme (loading) davranışı

| Ekran | Ne gösteriyor | Kaynak |
|---|---|---|
| Uygulama açılışı (oturum belirsiz) | tam sayfa `Center(CircularProgressIndicator())` | `main.dart:118-122` (`MainWrapper`, `AuthLoading`) |
| Giriş formu gönderimi | buton içinde 20×20 `CircularProgressIndicator(strokeWidth: 2)` + buton `null` (devre dışı) | `login_form.dart` submit bloğu |
| Faturalar listesi | `Center(CircularProgressIndicator())` | `invoices_page.dart:181-182` |
| Ürünler listesi | `ProductError` hariç dallar; yüklenme dalı `product_list_widget.dart:35-42` civarı (spinner) | `products_page.dart:89` |
| Dashboard | `state is! DashboardLoaded → SizedBox.shrink()` → **yüklenirken boş alan** (spinner yok) | `dashboard_overview.dart:61-63` — **D** |
| Şirket adı güncelleme | yerel `_isLoadingCompany` bayrağı ile buton spinner'ı | `settings_page.dart` |
| Cache'ten okuma (offline) | ek bir "eski veri" rozeti **yok** → kullanıcı çevrimdışı veriyi güncel sanır | Bölüm 5/7 — **D + Çıkarım** |

### 12.3 Boş durumlar (birebir metinler)

| Nerede | Koşul | Metin | Kanıt |
|---|---|---|---|
| Müşteri listesi | liste boş | `لا يوجد عملاء` | `customer_list_widget.dart:25` |
| Tedarikçi listesi | liste boş | `لا يوجد موردون` | `supplier_list_widget.dart:25` |
| Kategori listesi | kategori yok | `لا يوجد فئات` | `category_list_widget.dart:46` |
| Ürün listesi | filtre sonucu boş | `لا توجد منتجات في هذه الفئة` | `product_list_widget.dart:80,131` |
| Fatura listesi (ölü widget) | satış/alış boş | `لا يوجد فواتير بيع` / `لا يوجد فواتير شراء` | `invoice_list_widget.dart:31,57` |
| Satış/alış fatura listesi (ölü widget) | boş | `لا توجد فواتير مبيعات` / `لا توجد فواتير شراء` | `sales_invoice_list_widget.dart:93`, `purchase_invoice_list_widget.dart:92` |
| Fatura kalemleri | kalem yok | `لا توجد صنفات في هذه الفاتورة` | `invoice_items_widget.dart:13` |
| Fatura boş durumu (canlı) | fatura yok | `InvoiceEmptyStateWidget` içeriği (Bölüm 6.4) | `invoices_page.dart:243` |
| Ürün arama | eşleşme yok | `لا توجد نتائج` | `product_add_fullscreen_widget.dart:329`, `customer_supplier_search_card_new.dart:433` |
| Gider kategorileri dialog | kategori yok | `لا توجد فئات` | `expense_categories_dialog.dart:261` |
| Gider listesi / grafiği | kayıt/veri yok | `لا توجد مصروفات` / `لا توجد بيانات للعرض` | `expense_list_widget.dart:40`, `expense_monthly_chart_widget.dart:32` |
| Müşteri borçları sekmesi | borç yok | `لا توجد ديون مستحقة` | `customer_debts_page.dart:141` |
| Ödeme geçmişi | ödeme yok | `لا توجد مدفوعات` | `payment_history_widget.dart:213` |
| Kasa çıkışları | kayıt yok | `لا يوجد سحوبات` + `أضف سحب جديد للبدء` | `withdrawals/.../empty_state_widget.dart:17-21` |
| Telefon alanı boş | `phone == null` | `لا يوجد` | `customer_supplier_search_card_new.dart:342,405` |

Ortak boş durum öğesi: ikon + metin düzeni; ölçüleri Bölüm 6'da. **Pull-to-refresh yalnız 3 widget'ta** (`RefreshIndicator`: `product_list_widget.dart`, `sales_invoice_list_widget.dart`, `purchase_invoice_list_widget.dart`) — son ikisi ölü → **canlı tek pull-to-refresh ürün listesi**; diğer listelerde yenileme yalnız yeniden giriş/rpc ile. **D**

### 12.4 Failure taksonomisi ve gerçek kullanım

`lib/core/errors/failures.dart` (284 satır) — abstract `Failure` + 8 somut sınıf, 50 `factory`. Kullanım sayımları (`failures.dart` kendi eşleşmeleri hariç, `lib/` grep):

| Factory | Çağrı | Sonuç |
|---|---|---|
| `NetworkFailure.noConnection()` | **73** | pratikte tek canlı hata mesajı: `لا يوجد اتصال بالإنترنت` |
| `CacheFailure.notFound()` | 6 | offline + cache boş |
| `AuthFailure.invalidCredentials()` | 5 | login hatası |
| `AuthFailure.userNotFound()` | 4 | — |
| `AuthFailure.weakPassword()` | 3 | register |
| `AuthFailure.tokenInvalid()` / `emailAlreadyExists()` | 2 / 2 | — |
| `ServerFailure.databaseError()` | 1 | — |
| `CacheFailure.writeError()` | 1 | offline kuyruk yazma hatası |
| `AuthFailure.emailNotVerified()` | 1 | — |
| `ValidationFailure.*` (11 factory), `PermissionFailure.*` (4), `BusinessFailure.*` (9), `FileFailure.*` (5), `NetworkFailure.timeout/serverError/unauthorized/forbidden/notFound`, `ServerFailure.internalServerError/serviceUnavailable`, `CacheFailure.readError/clearError`, `AuthFailure.sessionExpired/accountDisabled` | **0** | **ölü hata sözlüğü**: 40 Arapça hata metni factory olarak tanımlı ama hiç üretilmiyor (`failures.dart` içinde 50 `factory`, 10 farklı factory canlı çağrılıyor); `PermissionFailure` özellikle 11.3'teki "izin diyalogu yok" bulgusuyla tutarlı |
| `Failure exceptionToFailure(dynamic)` | 145 çağrı noktası | sıralı `toString().contains(...)` eşlemesi: `SocketException→noConnection`, `TimeoutException→timeout`, `HttpException→serverError`, `FormatException→internalServerError`, **varsayılan → `ServerFailure.internalServerError()`**; yani **tanınmayan her hata tek mesajla yutuluyor** — **D** |
| `ServerFailure(...)` düz constructor | `invoice_repository.dart:64,87` | `Left(ServerFailure(e.toString()))` → **ham İngilizce exception metni kullanıcıya gider** (10.8 #8) |
| `ServerFailure('User not found')` | `invoice_repository.dart:67,93` | İngilizce sabit; offline + userId yok durumunda gösterilir — **D** |

### 12.5 Hata gösterim desenleri (4 desen)

| Desen | Nasıl | Örnek yerler | Yeniden deneme |
|---|---|---|---|
| A. Geçici snackbar (liste sayfaları) | `BlocListener` içinde `showSnackBar(SnackBar(content: Text(state.message)))` | `customers_page.dart:59-63`, `products_page.dart:89-97` (kırmızı, 2 sn), `invoices_page.dart:174-178`, `suppliers_page.dart:60`, `withdrawals_page.dart:150`, `expenses_page.dart:179`, borç sayfaları `:24/:39` | **yok** — snackbar kaybolunca liste eski halinde kalır — **D** |
| B. Inline hata ekranı | ikon + `حدث خطأ` + `state.message` + `ElevatedButton('حاول ثانية') → cubit.getAllInvoices()` | `invoices_page.dart:185-217` | **var** — uygulamadaki tek liste-seviyesi retry |
| C. Inline kırmızı metin | `Center(Text(state.message, color: AppColors.error))` | `dashboard_overview.dart:53-60` | yok |
| D. Widget içi hata kartı | `Icon(Icons.error,64,AppColors.error)` + mesaj + `ElevatedButton('أعد المحاولة') → getProducts()` | `product_list_widget.dart:42-60` | **var** (2. retry) |
| E. Sessiz yutma | `catch (_) {}` / `catch (e) {}` — hiçbir UI efekti | `product_form_widget.dart:102`, `pdf_invoice_service.dart:435`, `edit_product_add_widget.dart:124`, `product_add_fullscreen_widget.dart:102`, `edit_customer_supplier_widget.dart:46,58`, `auth_repository.dart:105`, `customer_debt_repository_impl.dart:102,208,234,260`, `dashboard_repository.dart:44,71`, `invoice_repository.dart:73,99` | **kullanıcı hatayı hiç görmez** — kritik bulgu; `lib/` içinde `catch` geçen 319 satır var; bunlardan ~15'i bloğu **boş** bırakıyor — **D** |

Genel sonuç: **uygulamada merkezi hata yönetimi yok** — aynı hata sınıfı 5 farklı şekilde sunuluyor; hangi ekranda hangi desenin kullanıldığını yeniden geliştiren kişi satır satır kopyalamalı. **D**

### 12.6 Zaman aşımı ve tekrar deneme

- `.timeout(` kullanımı **0** (`lib/` grep; yalnız `failures.dart:31,273` içindeki metin/ eşleme). Supabase/`http` varsayılan süreleri dışında **uygulama seviyesi timeout yok** → askıda kalan istek sonsuza dek `Loading` bırakır. **D + Çıkarım**
- Retry/backoff yok; hata sonrası tek yol kullanıcının ekranı yeniden tetiklemesi (B/D desenleri). **D**
- `NetworkFailure.timeout()` üreten yol yalnız `exceptionToFailure` içindeki `TimeoutException` string eşleşmesi; bu exception gerçekten fırlatılıyor mu **doğrulanamadı**. **Bilinmiyor**

### 12.7 Çevrimdışı (offline) davranış — modül modül

Kaynak: her repository'nin `if (await networkInfo.isConnected)` dalları (`isConnected` 81 kullanım / 12 dosya).

| Modül | Offline okuma | Offline yazma | Kanıt |
|---|---|---|---|
| Faturalar (satış/alış listesi) | cache'ten okur; cache boşsa `Left(NetworkFailure.noConnection())`; cache okuma hatası da aynı mesaja düşürülüyor (`catch (_)`) | **yok** → fatura oluşturma çevrimdışı başarısız | `invoice_repository.dart:65-75, 90-100` — **D** |
| Müşteri borçları | cache'ten filtreli okuma (`customer_debt_repository_impl.dart:95-104`), boşsa noConnection | **tek gerçek offline kuyruk**: `addPayment` offline → `pending_payments` satırı + yerel borç güncelleme + yerel ödeme geçmişi satırı → `Right(null)` (kullanıcı "başarılı" görür) | `:110-156` — **D** |
| Tedarikçi borçları | cache okuma var | `addPayment` offline → **doğrudan `Left(NetworkFailure.noConnection())`** → müşteri tarafıyla **asimetri** | `supplier_debt_repository_impl.dart:62-75` — **D** |
| Ürünler / müşteriler / tedarikçiler / giderler / çıkışlar | repository'de `isConnected` dalları var (6-12 adet), ayrıntı Bölüm 5/9 | çoğu yazma yolu online'e bağlı | grep sayımları — **D** |
| Dashboard | RPC + cache (`dashboard_repository.dart:44,71` sessiz catch) | — | **D** |
| Auth | `auth_repository.dart` 7 dal; çevrimdışı giriş Supabase local session'a bağlı → **doğrulanamadı** | — | **Bilinmiyor** |

Offline ödeme kuyruğunun tam davranışı (`customer_debt_repository_impl.dart:110-185`):
1. `UserService.getUserId()` null → `Left(CacheFailure.notFound())`.
2. Kuyruk satırı id'si `pending_<millisecondsSinceEpoch>`; `created_at` ISO.
3. Yerel borç azaltılıyor (`updateDebtAfterPayment`) ve ödeme geçmişine satır ekleniyor — `payment_method: 'نقداً'` **sabit Arapça** yazılıyor (:139).
4. Sonraki online `addPayment` çağrısında `syncPendingPayments()` çalışıyor: kuyruk FIFO, her kayıt `remoteDataSource.addPayment(...)`, başarılıysa `deletePendingPayment`.
5. **Bir kayıt başarısız olursa `break`** (:183) → kalan kuyruk o oturumda hiç denemiyor; tekrar deneme yalnız bir sonraki online yazma işleminde. Kalıcı "sync" butonu/timer'ı yok. **D + Çıkarım**
6. Kuyruk senkronizasyonu UI'da gösterilmiyor → kullanıcı bekleyen ödeme sayısını göremez. **D**

Diğer offline/cache sınırları:
- `sales_invoices_cache` yazımı bozuk: `cacheSalesInvoices` `map['id'] as String` kullanıyor, `SalesInvoice.toJson()` (`sales_invoice.dart:121-148`) `id` üretmiyor → **TypeError → çevrimdışı satış faturası listesi pratikte hiç dolu olmaz** (Bölüm 9.7/10.6). **D (kod), Çıkarım (etki)**
- `customer_invoices_cache`, `customer_payments_cache`, `dashboard_financials_cache` **hiç temizlenmiyor/siliniyor** → oturumlar arası eski veri kalabilir (Bölüm 9.7). **D**

### 12.8 Sınır durumları ve tanınmış kırılganlıklar

| # | Koşul | Sonuç | Etiket |
|---|---|---|---|
| SS-01 | DB'de beklenmeyen enum değeri (`payment_status`, `invoice_status`, `invoice_type`) | `fromString` orElse: **sessizce `cash` / `draft`** (`payment_status.dart:25-30`, `invoice_status.dart:27-32`, `invoice.dart:137-141`) → ödeme durumu yanlış "nakit" görünür; 10.6'daki Arapça-yazma/İngilizce-okuma turuyla birleşince **borç faturaları nakit görünür** | D |
| SS-02 | `map['user_id'] as String` / `map['product_id'] as String` gibi cast'lar (dashboard modelleri, Section 9) | kolon null/gizli → TypeError → cubit hata dalı; hangi ekranın tam olarak patladığı çalıştırılmadan doğrulanamadı | D + Bilinmiyor |
| SS-03 | `firstWhere` (orElse'sız) — 20 eşleşme: `financial_area_chart.dart:94` (ölü), `product_form_widget.dart:110`, `edit_product_add_widget.dart:121`, `product_add_fullscreen_widget.dart:99`, `product_add_widget.dart:137`, `edit_customer_supplier_widget.dart:40,52`, `expense_form_dialog.dart:381`, `<Enum>.values.firstWhere` (sarılı) | bulunamazsa **StateError**; ürün/kategori/ödeme kaydı lookup'larında crash riski. `edit_customer_supplier_widget.dart:46,58` ve `product_add_fullscreen_widget.dart:102` **try/catch ile sessize alınıyor** → formda seçim boş kalır, hata görünmez | D |
| SS-04 | Formda tutar alanı: 6 `double.parse` (`expense_form_dialog.dart:380`, müşteri/tedarikçi `payment_dialog_widget.dart:270/:263`, `payment_modal_widget.dart:255/:249`, `add_withdrawal_dialog.dart:59`) | hepsi `validate()` **sonrasında**: validatorlar `double.tryParse` + `<= 0` kontrolü yapıyor (`payment_dialog_widget.dart:165` vb.) → geçersiz/Arapça rakamlı girdi validatorda durur, parse'a ulaşmaz. **Ancak** `add_withdrawal_dialog.dart:59` ve `expense_form_dialog.dart:380` için validator'un tryParse kullandığı ayrı ayrı doğrulandı (Bölüm 8); yine de `tryParse` kullanılmayan yolda `FormatException` riski teorik | D |
| SS-05 | Negatif/sıfır tutar | validator `amount <= 0` → hata metni (Bölüm 8); **bakiye düşmede** negatif koruması yok → `update_customer_balance`'a negatif `-amountToReduce` gidebilir (10.4) | D + Çıkarım |
| SS-06 | Çift tıklama / mükerrer gönderim | yalnız login butonu `state is AuthLoading ? null` ile kilitli; diğer form butonları (müşteri, tedarikçi, gider, çıkış, ürün) **kilitlenmiyor**, bazıları `Navigator.pop`'u await sonucuna bakmadan çağırıyor (`product_form_widget.dart:278-281`) → hızlı çift gönderimde iki kayıt / kaybolan hata | D + Çıkarım |
| SS-07 | Liste boyut sınırı | ürün araması/listesi `.limit(50)` (`product_remote_datasource.dart:87,267`) → 50'den fazla ürün **sessizce kesilir**; sayaç/uyarı yok | D |
| SS-08 | Tarih sınırı | `DateTime(int.parse(year),1,1)/12,31` (`invoices_page.dart:53-54`) yıl chip'ten gelir (kontrolü sabit); `invoice_dates_widget.dart:69 int.parse(parts[0])` → beklenmeyen tarih dizgisi (ör. `null`/`''`) FormatException | D + Bilinmiyor (DB formatı) |
| SS-09 | Tarih aralığı sırası | `DateFilterSheet` içinde `from > to` kontrolü **yok** (grep `isBefore/isAfter` → 0, `:86/:173` yalnız `Navigator.pop`) → ters aralık seçilirse sorgu boş döner, UI "boş" gösterir, hata yok | D |
| SS-10 | Para birimi bilinmeyen kod | `NumberFormatter.getCurrencySymbol()` eşleşmeyen kodda **ham kodu** döner (ör. `SAR` → `SAR`) | D |
| SS-11 | Sayı biçimi | `main.dart:27` her açılışta `setArabicFormat(true)` yazıyor → `use_arabic_number_format` tercihindeki kullanıcı seçimi **kalıcı olarak eziliyor**; `useShortFormat` varsayılan `true` | D |
| SS-12 | Equatable kapsamı | `SalesInvoice.props` (`sales_invoice.dart:190-215`) `status` alanını içermiyor → yalnız durum değişen güncellemede bloc state eşit kalır, **UI yenilenmez** | D |
| SS-13 | Stream sızıntısı | `ProductCubit` `BlocProvider.value` ile sarılı (3 yer) → `close()` hiç çağrılmıyor → sayfa her yeniden açılışında ek abonelik, eski stream emit etmeye devam eder (10.9) | D |
| SS-14 | Silme + ilişkiler | silme transaction dışı, cascade elle (10.8 #6) → yarı silinmiş kayıt; UI'da "bu kayda bağlı faturalar var" uyarısı **yok** | D |
| SS-15 | Oturum düşmesi | `userChanges` dinlenmiyor (11.6) → token süresi dolduğunda ilk istek 401 döner; hata mesajı `AuthFailure` değil genelde `ServerFailure(...)`/İngilizce metin; **login ekranına yönlendirme yok** | D + Çıkarım |
| SS-16 | Kaynak kodunda `dev.log` / `log(...)` yaygın | hata/uyarı ayrıntıları yalnız konsola; üretimde toplama yok (10.7) | D |
| SS-17 | Uzun Arapça metin / taşma | hiçbir ekranda `Semantics`/`FittedBox`/maxLines standardı yok; `RenderFlex overflow` riskleri **çalıştırmadan doğrulanamaz** | Bilinmiyor |
| SS-18 | Silme/çıkış onayı | dialoglar `AlertDialog` + iptal/onay; `Dialog` içinde `Navigator.pop` sonucu dinlenmeden işlem yapılan yerler var (Bölüm 7) → iptal edilen akışta yan etki riski satır bazlı listelendi | D |

### 12.9 Bu bölümde doğrulanamayanlar (Bölüm 15'e taşınır)

1. Hiçbir hata ekranı **ekranlı cihazda görülmedi**: snackbar süreleri, inline hata kartlarının gerçek yerleşimi, "حدث خطأ" ekranına giden adım.
2. Supabase SDK'nin timeout/tekrar deneme davranışı ve kopan ağda hangi exception tipinin fırladığı (`exceptionToFailure` eşlemesinin gerçekten `noConnection` üretip üretmediği).
3. Çevrimdışı giriş (`auth_repository` offline dalları) ve süresi dolmuş token ile cache'li dashboard'un birlikte davranışı.
4. `SalesInvoice.toJson()`'daki `id` eksikliğinin runtime'da TypeError olarak görünmesi (çevrimdışı fatura listesi testi gerekir).
5. `.limit(50)` kesiminin kullanıcı tarafından fark edilip edilmediği (ürünü 50+ olan hesapla test).
6. `RenderFlex overflow`, uzun metin/RTL taşmaları, düşük bellek, yavaş ağ (profil). 

---

## 13. Yeniden geliştirme spesifikasyonu (faz bazlı)

> Hedef: bu belgeyi okuyan bir Flutter geliştiricisi, orijinal kodu görmeden **davranışı birebir** yeniden kurabilsin. Fazlar bağımlılık sırasına göre verildi; her fazda "kaynak bölüm" refermeleri bu belgenin kendi bölümleridir.

### 13.0 Ölçüm ve ön koşullar

| Metrik | Değer | Not |
|---|---|---|
| Dart dosya (tümü) | **235** | `lib/` |
| Dart satır (tümü) | **45.796** | |
| `main.dart` import grafiğinden **ulaşılabilir** dosya | **184** | `part/export/import` kenarlarıyla hesaplandı (Bölüm 15.3'te liste) |
| Ulaşılabilir satır | **36.583** | yeniden yazılacak gerçek kapsam |
| Ulaşılamaz (ölü) dosya / satır | **51 / ≈9.213** | port **edilmeyecek** (13.17) |
| Dışsı (canlı) modül dağılımı | invoices 43 dosya/10.586 sat · customer_debts 21/4.005 · suppliers_debts 17/3.320 · expenses 14/2.991 · withdrawals 13/2.628 · products 13/2.549 · dashboard 12/1.396 · reports 9/1.331 · customers 8/1.234 · auth 8/1.118 · suppliers 8/1.098 · core/* 17/4.027 · settings 1/455 | aynı sırayla fazlara yayıldı |
| **Zorunlu ön koşul** | Supabase projesi + **şemanın elde edilmesi** | bu belgede tablolar/kolonlar çağrılardan çıkarıldı (Bölüm 9.2-9.5); view/RPC tanımları **Bilinmiyor** → Faz 0'sız yeniden geliştirme mümkün değil |

### 13.1 Faz 0 — Ortam, kimlik ve sunucu sözleşmesi (tek seferlik)
1. Flutter/Dart kurulumu: `environment.sdk: ^3.10.7` (`pubspec.yaml:23`); AGP 8.11.1, Kotlin 2.1.0, Java 17 (11.2).
2. Proje kimliğini düzelt: `applicationId`/`namespace` `com.example.mindPrint` yerine gerçek kimlik; iki kalıntı `MainActivity.kt` dosyasından yalnız birini bırak (11.2).
3. Release imzası: `signingConfigs.getByName("debug")` yerine gerçek keystore (11.2).
4. Supabase: proje + `profiles`, `customers`, `suppliers`, `products`, `categories`, satış/alış fatura ve kalem tabloları, ödeme tabloları + **`get_dashboard_financials`, `update_customer_balance`, `update_supplier_balance` RPC'leri** + `view_customer_debt_details`, `view_supplier_debt_details` view'ları. Bu belge **yalnız istemci tarafını** gözlemleyebildi → şema/RLS/view/RPC tanımları customer'ın DB dökümüyle tamamlanmalı (15.1).
5. Sırları koddan çıkar: `api_constans.dart:2-3` yerine `--dart-define`/`.env` (10.8 #1).
6. **Kabul ölçütü:** taze bir Supabase projesine karşı `flutter run` ile kayıt → giriş → boş dashboard zinciri kurulabiliyor; RLS açıkken çok kiracılı izolasyon testi geçiyor.

### 13.2 Faz 1 — Çekirdek katman (bağımlılık: yok)
| İş | Kaynak spesifikasyon |
|---|---|
| Tema (yalnız light) + tipografi çelişkisini çöz (`Cairo` vs `changaTextTheme`) | 6.1, 11.8 |
| Renk/boşluk/radius tokenları; `AppConstants` içindeki **0 kullanılan** sabitleri taşıma | 6.1, 15.4 |
| `NumberFormatter` (keys, SYP/USD/EUR/TRY sembolü, kısa sayı, Arapça rakam) | 9.8, 12.8 SS-10/SS-11 |
| `NetworkInfo` (81 `isConnected` dalının dayandığı sözleşme) | 12.7 |
| `AppDatabase` (raw SQL cache tabloları) — typed Drift tablolarına geçirilmeli; `allTables=[]` ve `schemaVersion 1` borcu | 3.x, 9.7 |
| `Failure` hiyerarşisi + `exceptionToFailure` — canlı 10 factory'yi koru, ölü ~40'ı sil veya gerçekten kullan | 12.4 |
| GetIt kayıtları (28 satır DI; `registerFactory` cubit'ler, lazy singleton ds/repo) | 3.x, 10.1 |
| Paylaşılan widget kütüphanesi: `DateFilterSheet` (6 çağrı noktası), `InvoiceCardWidget`, `SearchField`, `CustomCard`, `EmptyStateWidget`/`LoadingWidget`'i **gerçekten kullan** | 6.10, 12.1 |
| Rota üretimi `AppRoutes` + `onGenerateRoute`, `default → DashboardPage` fallback'i | 4.x |

### 13.3 Faz 2 — Auth (8 dosya / 1.118 satır)
Ekranlar: SCR-001 Login (form + register toggle + forgot dialog), DLG-… şifre sıfırlama dialogu, `MainWrapper` gate. Akışlar AF-01…AF-05. Validasyonlar F-01…F-03 (metinler birebir Bölüm 8).
Bilinen tuzaklar: `_businessNameController` dispose eksik; `AuthSuccess` dalının LoginPage'i yeniden push etmesi; `resetPassword`/`changePassword` ölü; `updateProfile` üzerinden gelen `AuthError`'un settings'te hiç gösterilmemesi; `usesCleartextTraffic` ve izinsiz deep-link nedeniyle şifre sıfırlama bağlantısının yakalanamaması (11.4) → yeniden yazımda **deep-link + `resetPassword` akışı ya tamamlanmalı ya tamamen kaldırılmalı**.

### 13.4 Faz 3 — Veri sözleşmeleri (modüllerin tamamı)
1. Model sınıflarını Bölüm 9.1-9.5'ten üret; **`toJson` alanlarını DB kolonlarıyla elle eşleştir** (satış faturasında `id` eksikliği → offline cache'i bozuyor; 12.7).
2. `Equatable.props` eksiklerini kapat (`status` yok → UI güncellenmiyor; SS-12).
3. Repository imzaları `Either<Failure,T>` (23 dosya); offline dalların tam tablosu 12.7.
4. Remote ds'lerdeki payload temizliği: `updated_at/customer_name/items` alanlarının `remove` edilmesi, kalem payload'ında `?? 'null_data'` FK tuzağı (10.6).
5. **Kabul ölçütü:** her model için `fromMap ↔ toMap` round-trip testi; `payment_status` ve `status` değerleri Arapça/İngilizce dönüşümünde kaybolmamalı.

### 13.5 Faz 4 — Dashboard kabuğu ve navigasyon (12 dosya / 1.396 satır)
- `bottomNavigationBar` (özel `Row`, `AnimatedContainer` 200 ms, seçili `surface`/değil şeffaf, radius `borderRadiusMd`, padding symmetric(6,10), vertical 14, fontSize 13, w600/w400).
- Online 5 sekme / offline 3 sekme (`_menuItems`), `_selectedIndex` switch → `DashboardOverview / InvoicesPage / CustomerDebtsPage / SuppliersDebtsPage / MorePage`; offline `isLocal:true`.
- Klavye gözlemcisi (`didChangeMetrics`, `viewInsets.bottom > 100`) — **bayrak kullanılmıyor, port etme** (7 notu).
- `SafeArea` eksikliği + `padding.bottom` hesabının yorumda olması → yeniden yazımda düzelt (11.5).
- `MultiBlocProvider(lazy:true)` ile 4 cubit; `AppSidebar`/`CustomAppDrawer` **port edilmeyecek** (13.17).

### 13.6 Faz 5 — Faturalar, salt okuma (43 dosyanın ~yarısı)
Liste (arama + yıl/özeli tarih + Realtime), detay (kalem listesi, toplam, ödeme durumu dialogu, PDF paylaşımı), filtre `InvoiceFiltered` state, `getAllInvoices`, stream abonelikleri. Ölçüler 6.4-6.6; etkileşimler AF-06…AF-12; boş/hata desenleri 12.3/12.5. `.limit(50)` benzeri sessiz kesme bu modülde yok ama **sayfalama hiç yok** → büyük hesaplarda tüm satırlar çekiliyor (14 test matrisinde ölçülmeli).

### 13.7 Faz 6 — Fatura oluşturma/düzenleme + PDF
`edit_invoice_page` + `product_add_*` + `edit_product_add_widget` (tek breakpoint `width<600`), fiyat/quantity düzenleme, `payment_status` geçişi ve `updateInvoicePaymentStatusWithBalance` bakiye etkisi (10.4), `PdfInvoiceService` (859 satır) + `ArabicReshaper`/`Bidi` (11.6), `Printing.sharePdf` 5 çağrı noktası.
**Fark edilmesi gereken boşluk:** istemci tarafında **stok düşmüyor** ("Stock şimdilik donduruldu" log'ları, 10.6); yeniden yazımda ya DB tetikleyicisi/RPC ile düşürülecek ya da aynı davranış bilinçli olarak korunacak.

### 13.8 Faz 7 — Müşteriler ve tedarikçiler (8 + 8 dosya)
Listeler (offline cache/arama), form dialogları (F-04…F-07), silme onayı, detay sayfaları. Tuzaklar: `supplier_form_widget.dart:48` `userId!`, arama sorgusunda `user_id` filtresi yok (10.8 #3), `or('name.ilike.%$query%…')` enjeksiyon yüzeyi (#5).

### 13.9 Faz 8 — Borçlar, ödemeler ve offline kuyruk (21 + 17 dosya)
12.7'deki kuyruk akışını **olduğu gibi** kur (id `pending_<ms>`, `payment_method:'نقداً'`, borcun yerelde düşülmesi, `syncPendingPayments` FIFO + `break`), sonra **iyileştir**: tedarikçi tarafındaki asimetriyi kapat, sync'i periyodik/uygulanabilir hale getir, bekleyen sayısını UI'da göster.

### 13.10 Faz 9 — Ürünler ve kategoriler (13 dosya)
`ProductsPage` (`BlocProvider.value` → sızıntı, 10.9), `RefreshIndicator` (canlı tek pull-to-refresh), `product_list_widget` (`ListView.builder shrinkWrap + NeverScrollableScrollPhysics` — iç scroll fiziksel olarak kapalı), kategori chip'leri, realtime stream'ler, `code = now.microsecond.toString()` üretimi (SS-... Bölüm 8), `existingProduct!.unit` crash'i, `.limit(50)` kesimi.

### 13.11 Faz 10 — Giderler ve kasa çıkışları (14 + 13 dosya)
Önemli not: withdrawals modülünde **11 widget dosyası ölü** (13.17) — canlı yol `summary_cards/monthly_chart/withdrawals_table/add_user_dialog/add_withdrawal_dialog` + `DateFilterSheet`. `add_withdrawal_dialog.dart:57` `userId: _selectedUserId ?? 'current_user_id'` **sabit placeholder** değerini DB'ye yazıyor → yeniden yazımda zorunlu alan yap.

### 13.12 Faz 11 — Raporlar ve stok takibi (9 dosya)
`takrirler_page`, `customer_invoices_page`, `customer_invoice_detail_page`, `stock_tracking_page` (PDF + DateFilterSheet). `PartyInvoiceCubit` tek cubit, iki tip (customer/supplier) ayrımı `customerSupplierSearchCard*` ölü varyantlarıyla karıştırılmamalı. Stok hareket modeli (`stock_movement.dart`) **ölü** → stok geçmişi ekranı yok.

### 13.13 Faz 12 — Ayarlar (455 satır, tek dosya)
Para birimi chip'leri (`setCurrency`), sayı biçimi kartı (**InkWell + Switch aynı setter'ı çağırıyor → tek dokunuşta iki tetikleme riski**), şirket adı güncelleme (`AuthCubit.updateProfile`, BlocListener yok), `profiles.theme_mode` yazılıyor ama okunmuyor, çıkış dialogu DLG-06. Yeniden yazımda dark-mode/deep-link eksiklikleri de burada kararlaştırılmalı (11.8).

### 13.14 Faz 13 — Platform yapılandırması
Manifest'te yalnız `INTERNET` + `ACCESS_NETWORK_STATE` bırak; `usesCleartextTraffic` kaldır; orientation kilidi + `SafeArea`; `SystemChrome` ile status bar; `flutter_launcher_icons`/`flutter_native_splash` asset yollarını düz bölüye çevir; `web/manifest.json` renk ve adlarını gerçek marka ile eşleştir; `ios/` hedefi istenirse `Info.plist` izin anahtarları **sıfırdan** yazılmalı (bu belgede iOS yok). Fontları `pubspec.yaml`'a göm (11.7).

### 13.15 Faz 14 — Sertleştirme (belgelenen kusurların kapatılması)
Sıra: (a) crash üreten yollar (`as String` cast'leri, orElse'sız `firstWhere`, `userId!`, `existingProduct!.unit`), (b) veri kaybı üreten yollar (`id` eksik toJson, cache tabloları temizliği, sync `break`), (c) sessiz `catch (_)` (15 yer) → kullanıcıya mesaj, (d) timeout/retry eksikliği (12.6), (e) çift gönderim kilidi (SS-06), (f) `PaymentStatus.fromString` orElse'sunu `cash` yerine **hata** yap (SS-01), (g) central hata sunumu (12.5'teki 5 deseni tek desene indir).

### 13.16 Faz bağımlılık sırası

```
Faz 0 ─▶ Faz 1 ─▶ Faz 2 ─▶ Faz 3 ─┬─▶ Faz 4 ─▶ Faz 5 ─▶ Faz 6 ─▶ Faz 8
                                   ├─▶ Faz 7 ─▶ Faz 9 ─▶ Faz 10 ─▶ Faz 11
                                   └─▶ Faz 12 (Faz 2'ye de bağlı)
Tüm fazlar ─▶ Faz 13 ─▶ Faz 14 ─▶ Bölüm 14 kabul/test matrisi
```

### 13.17 Port edilmeyecekler (bilinçli olarak atla)
1. **51 ulaşılamaz dosya** (tam liste Bölüm 15.3) — özellikle: `invoice_management_page.dart` (ölü sayfa), `sales/purchase_invoice_list_widget.dart`, `invoice_items/filters/header/info_grid/notes/product_list/type_selector_widget.dart`, `quick_product_add_card(_simple).dart`, `customer_supplier_search_card(_new/_widget).dart`, `discount_widget.dart`, `cancel_invoice_dialog.dart`, dashboard'un 5 navigasyon/kabuk varyantı (`app_sidebar`, `custom_app_drawe`, `navigation_drawer`, `app_navigation_drawer`, `dashboard_page_wrapper`), `date_filter_section.dart`, `remaining_stock_section.dart`, `dashboard_stats_card.dart`, withdrawals'ın 11 widget'ı, `expense_cards/list_widget.dart`, reports'un 3 `party_invoice_*` widget'ı, `stock_movement.dart`, `invoice_unified.dart`, `financial_area_chart.dart`, `custom_loading_animation.dart`, `app_dialog.dart`, iki `models.dart` barrel'ı, `debt_table_header_widget.dart` (2 kopya), `customer_summary_cards_widget.dart`.
2. **Ölü bağımlılıklar**: `syncfusion_flutter_charts`, `uuid`, `provider` (ölü import), `flutter_secure_storage` (kullanılmıyor) → `pubspec.yaml`'dan çıkar (10.7).
3. **Kullanılmayan izinler**: `RECORD_AUDIO`, `MODIFY_AUDIO_SETTINGS`, `WRITE/READ_EXTERNAL_STORAGE` (11.3).
4. **0 kullanılan sabitler**: `AppConstants.contentPadding/gap*/spacingXs/Sm/Xl/sidebarWidth/minWindow*/defaultPageSize/currencyFormat/dateFormat`, `AppFonts.arabicFont/latinFont` (6.1).
5. **Ölü hata sözlüğü**: ~40 factory (12.4) ve `LoadingWidget/CustomButton/CustomTextField/core EmptyStateWidget` (12.1).
6. **Ölü UI durum kodu**: `_isKeyboardVisible`, `profiles.theme_mode`, `User.themeMode`, `userChanges` stream'i, `Printing.layoutPdf` yolu (12.7/11.x).

### 13.18 Yeniden yazımda korunması gereken "kötü" davranışlar
Ürün sahibi bunu isteyebilir ama **davranış uyumu** için not düşüldü: stok düşürmenin olmaması (10.6), arama sonuçlarının `user_id` filtresiz oluşu (10.8 #3), ürün listesinde 50 kesimi (SS-07), offline ödeme kuyruğunun müşteri tarafında sessiz "başarılı" göstermesi (12.7), Para birimi/ sayı biçimi tercihlerinin her açılışta `setArabicFormat(true)` ile ezilmesi (SS-11).

---

## 14. Kabul kriterleri ve test matrisi

> **Önemli başlangıç gerçeği:** repoda **test yok** — `test/` dizini mevcut değil, `*_test.dart` sayısı **0**, `dev_dependencies` yalnız `flutter_test` + `flutter_lints` (`pubspec.yaml:62-70`). Yani aşağıdaki matris **sıfırdan kurulacak** bir test setidir; orijinal projede hiçbir regresyon güvencesi yoktu. **Doğrulandı**

### 14.1 Test katmanları ve araçlar

| Katman | Araç | Kapsam | Not |
|---|---|---|---|
| Statik | `flutter analyze` + `analysis_options.yaml` (flutter_lints 6.0.0) | lint kuralları | bugün kaç uyarı ürettiği **doğrulanamadı** (çalıştırılmadı) |
| Unit (model/repo) | `flutter_test` + `mocktail` (öneri) | `fromMap/toJson` round-trip, `NumberFormatter`, `Failure` eşlemesi, cubit durum geçişleri | network `NetworkInfo` ve `SupabaseClient` sahte implementasyonla |
| Widget | `flutter_test` | `DateFilterSheet`, `LoginForm`, `InvoiceCardWidget`, form dialogları | RTL + `textScaler` etkisini sabitlemek için testte `MediaQuery` override gerekir |
| Integration | `integration_test` (öneri) | AF-01…AF-29 uçtan uca | gerçek Supabase **test projesi** şart (14.8) |
| Manuel platform | cihaz/emülatör | 14.7 | izin/status bar/notch/overflow gibi **yalnız görsel** doğrulanabilen maddeler |

### 14.2 Ekran bazlı kabul kriterleri (SCR)

| SCR | Kabul ölçütü (ölçülebilir) |
|---|---|
| SCR-001 `MainWrapper` | `AuthLoading` → tam ekran spinner; `Authenticated` → SCR-003; **diğer her state** → SCR-002. Oturum yokken 1 sn'den uzun "boş beyaz" kare görünmemeli. |
| SCR-002 Login/Kayıt | 5 validasyon metni **birebir** (Bölüm 8 F-01…F-03); gönderimde buton kilitli + 20×20 spinner; hatalı girişte kırmızı snackbar + form verisi korunuyor; başarıda `pushReplacement` (geri tuşu login'e dönmez). Toggle'da "اسم الشركة" alanı yalnız kayıt modunda beliriyor. |
| SCR-003 Dashboard kabuğu | Online 5 sekme / offline 3 sekme; sekme değişimi `AnimatedContainer` 200 ms; offline'da iken bağlantı gelince 5 sekmeye çıkar; offline'da `_selectedIndex>1` iken bağlantı kesilirse seçim 0'a düşer (`dashboard_page.dart:83-84`). |
| SCR-004 Ana özet | `DashboardLoaded` olmadan **boş alan** (`SizedBox.shrink`) gösteriliyor — kabul: yüklenme durumunun görünür olması isteniyorsa bu bir **değişiklik talebi**, mevcut davranış bu. `DashboardError` → kırmızı metin. |
| SCR-005 Faturalar | Arama + yıl chip + özel aralık birlikte çalışıyor; boş → `InvoiceEmptyStateWidget`; hata → `حدث خطأ` + `حاول ثانية` ve buton `getAllInvoices()` tetikliyor; realtime: başka cihazdan eklenen fatura **bu açıkken** listeye düşüyor. |
| SCR-009 Fatura detay | Ödeme durumu değişimi önce yerel (`setState` + `جاري تحديث حالة الدفع...`), sonra sunucu; `cash`e geçişte müşteri bakiyesi **kalan tutar kadar** azalıyor (10.4) — DB'de doğrulanmalı. |
| SCR-010/011 Oluştur/Düzenle | Kalem eklemeden kayıt **engellenmiyor mu** → mevcut davranış: engelleniyor/engellenmiyor Bölüm 8'de belgelendi; toplam satırı kalem değişiklikleriyle anlık güncelleniyor; düzenlemede `items` payload'dan kaldırılıp ayrı ayrı işleniyor (10.6). |
| SCR-012 Tam ekran ürün ekle | `لا توجد نتائج` boş durumu; `quantity<=0` için sessiz erken dönüş (`product_add_fullscreen_widget.dart:91`) — kabul: sessiz dönüş yerine kullanıcıya geri bildirim (mevcut: sessiz). |
| SCR-013 Ayarlar | Para birimi chip'i → `NumberFormatter.setCurrency`; **tüm tutarlar tek biçime dönmeli**; sayı biçimi kartında tek dokunuş **tek** toggle (mevcutta hem `InkWell` hem `Switch` aynı setter'ı çağırıyor → kabul testi çift tetiklemeyi yakalar); şirket adı boşsa `الرجاء إدخال اسم الشركة`, başarıda `تم تحديث اسم الشركة بنجاح`; **cubit hatası görünür olmalı** (mevcutta BlocListener yok → bu kabul kritere eklenmeli); çıkış dialogu onaylamasız oturumu kapatıyor. |
| SCR-014 Ürünler | Kategori chip'leri + arama birlikte; liste tek sütun `ListView.builder` (iç kaydırma `NeverScrollableScrollPhysics`); pull-to-refresh çalışıyor; **51+ üründe listenin 50'de kesildiği doğrulanmalı ve belgelenmeli** (SS-07); hata kartında `أعد المحاولة` → `getProducts()`. |
| SCR-015/016 Müşteri/Tedarikçi | `GridView.builder(crossAxisCount:1)`, `childAspectRatio` **1.7 / 2.0** farkı korunuyor; boş metinler `لا يوجد عملاء` / `لا يوجد موردون`; silme sonrası ilişkili faturalar da gidiyor (tedarikçide `payments` **gitmiyor** — mevcut davranış). |
| SCR-017/018 Gider/Çıkış | Özet kutuları + `fl_chart` (220 px) aynı dönem verisiyle tutarlı; tablo satır yükseklikleri Bölüm 6; `AddWithdrawalDialog`'da kullanıcı seçilmezse DB'ye `current_user_id` **sabit değeri** yazılıyor (mevcut kusur) → kabul: ya zorunlu alan ya düzeltme notu. |
| SCR-019…022 Raporlar | `TakrirlerPage` 3 kart; `CustomerInvoicesPage` tipi rozetinde **İngilizce `sale`/`purchase`** metni çıkıyor (mevcut); `StockTrackingPage` PDF + yıl filtresi; SafeArea eksik sayfalar 14.7'de notch testine giriyor. |
| SCR-023/024 Detaylar | Ödeme ekle/sil, geçmiş listesi, PDF paylaşımı; abonelikler `dispose`'ta iptal (10.9). |

### 14.3 Etkileşim akışı testleri (AF → test)

| Test | AF | Adım (özet) | Beklenen |
|---|---|---|---|
| T-01 Soğuk başlangıç (oturum var/yok) | AF-01 | cache'li session ile aç / temiz install ile aç | sırasıyla SCR-003 / SCR-002; splash→UI arası beyaz kare tek |
| T-02 Hatalı giriş | AF-02 | 8+ karakter şifre, yanlış e-posta | kırmızı snackbar, `AuthError`, form korunur, yönlendirme yok |
| T-03 Kayıt | AF-03 | boş şirket adı / kısa şifre / geçerli | F-01…F-03 metinleri; başarıda yeşil snackbar + **LoginPage yeniden push** (kabul: beklenen davranış bu) |
| T-04 Şifre sıfırlama | AF-04 | boş / dolu e-posta | boşsa istek yok; doluysa `AuthSuccess('تم إرسال رابط استعادة كلمة المرور')` + diyaloğun anında kapanması |
| T-05 Çıkış | AF-05 | DLG-06 onay | `Unauthenticated` → `MainWrapper` SCR-002; geri tuşu SCR-003'e dönmez |
| T-06 Sekme geçişleri (10 kombinasyon) | AF-06 | online/offline × 5 sekme | offline 3 sekme; offline'da cache veri; "güncel" rozeti yok (mevcut) |
| T-07 Named route'lar | AF-07 | MorePage → 6 dış ekran, `/x` bilinmeyen route | default fallback **DashboardPage** (`main.dart:_generateRoute`) |
| T-08 Satış faturası uçtan uca | AF-08 | müşteri + kalem + nakit/borç | `sales_invoices` + `sales_invoice_items`; borçta müşteri bakiyesi artıyor; **stok değişmiyor** (10.6) |
| T-09 Alış faturası | AF-09 | tedarikçi + kalem | `purchase_*`; tedarikçi borcu artıyor |
| T-10 Fatura düzenleme | AF-10 | kalem sayısını/toplamı değiştir | tutar farkı bakiyeye yansıyor mu → Bölüm 15 doğrulama listesi |
| T-11 Ödeme durumu | AF-11 | borç → nakit | bakiye `remainingAmount>0 ? remainingAmount : totalAmount` kadar düşüyor; hata → `InvoiceError('فشل تحديث حالة الدفع: …')` |
| T-12 Fatura silme | AF-12 | onayla / iptal et | iptalde yan etki yok; onayda kalemler de siliniyor (transaction dışı — kısmi silme testi) |
| T-13 PDF | AF-13 | 5 PDF noktası | Arapça metin doğru yön; dosya adı `invoiceNumber`; OS share paneli açılıyor |
| T-14 Arama + filtre | AF-14 | aynı anda metin + yıl + aralık; `from>to` | ters aralık → boş liste, **hata mesajı yok** (SS-09) |
| T-15 Müşteri ödemesi (online) | AF-15 | tutar 0/negatif/çok ondalıklı | validator `<=0` değerini engelliyor; `payments` satırı + bakiye |
| T-16 Ödeme silme | AF-16 | sil → bakiye | bakiye geri ekleniyor mu (15 doğrulama) |
| T-17 Taraf detay | AF-17 | liste → detay → fatura | parametre aktarımı, `SafeArea` var |
| T-18/19 Müşteri/Tedarikçi CRUD | AF-18/19 | eksik alan / uzun telefon / aynı isim | Bölüm 8 metinleri; tedarikçi silmede `payments` **kalmıyor/gidiyor** farkı |
| T-20 Ürün CRUD | AF-20 | kategori olmadan kayıt; eşzamanlı iki kayıt | `code = microsecond` çakışma testi (aynı µs nadir ama yinelenen kod riski) |
| T-21 Gider CRUD | AF-21 | DLG-27/28/29 + filtre | grafik yenileniyor |
| T-22 Çıkış CRUD | AF-22 | DLG-31/32/33/34, kullanıcı seçimli/seçimsiz | seçim yoksa `current_user_id` yazılıyor (kusur) |
| T-23 Rapor/PDF | AF-23 | 3 rapor çıkışı | veri tutarlılığı SCR-004 ile |
| T-24/25 Tercihler | AF-24/25 | para birimi + kısa sayı + `Arabic format` | uygulama yeniden başlatıldığında `use_arabic_number_format` **tekrar true'ya zorlanıyor** (SS-11) → kabul: kullanıcı tercihi korunmalı |
| T-26 Realtime | AF-26 | 2 cihaz; ürün/fatura/borç stream'leri | emit'ler UI'a yansıyor; sayfa kapandıktan sonra `ProductCubit` stream'i **emit etmeye devam ediyor** (SS-13 → sızıntı testi) |
| T-27 Offline | AF-27 | uçak modu: listeler, ödeme kuyruğu, fatura oluşturma | müşteri ödemesi kuyruğa girip "başarılı"; tedarikçi ödemesi `noConnection`; fatura oluşturma hata; satış cache'i boş (12.7) |
| T-28 Çift tıklama | AF-28 | butona 2 kez | tek kayıt beklenir; **mevcutta yalnız login kilitli** → diğerlerinde çift kayıt çıkması beklenen sonuç |
| T-29 Kesinti/iptal | AF-29 | istek ortasında sayfadan çık | abonelik iptali, crash yok |

### 14.4 Form/validasyon sınır testleri

| Form | Girdi | Beklenen |
|---|---|---|
| E-posta | `a@b`, boş, `@`, süslemeli ` a@b ` | `contains('@')` tek kural → `a@b` **kabul**; boş → `البريد الإلكتروني مطلوب` |
| Şifre | 7/8/9 karakter, Arapça, boşluklu | `<8` → `كلمة المرور يجب أن تكون 8 أحرف على الأقل` |
| Şirket adı | yalnız kayıt modunda görünür; boş | `اسم الشركة مطلوب` |
| Telefon | boş, 1 hane, çok uzun | Bölüm 8'deki metinler; uzunluk sınırı **yok** (kod kanıtı) |
| Tutar | `0`, `-5`, `١٢٣` (Arapça rakam), `1.234,56`, `1,2`, 12 ondalık | `tryParse` başaramaz → hata metni; `<=0` → hata; **parse sonrası yuvarlama/para birimi basamağı tanımsız** (15 doğrulama) |
| Miktar | `0`, negatif, `''` | `quantity<=0` için **sessiz erken dönüş** (SCR-012) veya `>` guard'ı |
| Zorunlu seçiler | müşteri/tedarikçi/kategori/user seçilmeden gönderim | Bölüm 8: bazılarında `null` DB'ye gidiyor, bazılarında UI engelliyor — satır referansları orada |

### 14.5 Veri bütünlüğü testleri

1. **Round-trip:** her model için `toMap → DB → fromMap` eşitliği; özellikle `payment_status`, `status`, `id`. `SalesInvoice.toJson()` `id` üretmediği için offline cache testi **bugün başarısız olmalı** (beklenen regresyon kanıtı).
2. **Bakiye tutarlılığı:** fatura borç→nakit, ödeme ekle/sil, silme sonrası `customer_debts` view değeri ile `sales_invoices` toplamının mutabakatı.
3. **Cascade:** müşteri sil → `sales_invoices` + kalemler; tedarikçi sil → `purchase_*` (ödeme tabloları hariç).
4. **Cache hijyeni:** `customer_invoices_cache`, `customer_payments_cache`, `dashboard_financials_cache` çıkış yapınca **temizlenmiyor** → yeni oturumda eski kayıt görünmemeli (kabul: logout'ta `delete*` çağrısı eklenmeli veya test bu boşluğu işaretlemeli).
5. **Kuyruk:** `pending_payments` FIFO + `break` davranışı; bozuk kayıt (eksik `customer_id`) → tüm kuyruk tıkanıyor mu (tip: evet, `break`).
6. **RLS/çok kiracılı:** A hesabının token'ı ile B müşterisinin `id`'si üzerinden okuma/yazma denemesi → 403/0 satır beklenir (sunucu tarafı doğrulaması gerekir, 15.1).
7. **İlaç/parametre enjeksiyonu:** arama alanına `%`, `,`, `()` → filtre bozuluyor mu (10.8 #5).

### 14.6 Hata ve durum testleri (12.5/12.7 desenleri)

| # | Senaryo | Beklenen (mevcut davranış) |
|---|---|---|
| H-01 | Sunucu 500 | snackbar veya inline; mesaj `ServerFailure`/`Exception.toString()` → **İngilizce sızıntı** (10.8 #8) |
| H-02 | Kablo çekildi, liste açık | `noConnection` mesajı; realtime stream'ler sessiz kesiliyor; retry yalnız 2 yerde (B/D deseni) |
| H-03 | İstek çok yavaş (şebeke gecikmesi 30 sn) | **uygulama timeout yok** → spinner sonsuz kalabilir (12.6) |
| H-04 | Cache'te none + offline | `Center` hata/boş; `لا…` metni |
| H-05 | `catch (_) {}` yolları (15 yer) | hata **gizleniyor** → test log/flag ile yakalanmalı |
| H-06 | Oturum düşmesi | UI "oturum açık" kalıyor; ilk yazmada hata (11.6) |
| H-07 | Null kolon → `as String` cast'leri | TypeError, debug'da kırmızı ekran; release'te sessiz düşme **doğrulanamadı** |

### 14.7 Platform / ortam matrisi

| Eksen | Değerler | Neden |
|---|---|---|
| Cihaz | telefon (portrait/landscape), tablet, katlanabilir | orientation kilidi yok (11.4); tek breakpoint 600 px (11.5) |
| Android sürümü | 6–12 (minSdk/flutter default) ve 13+ (paylaşım/media izinleri) | 4 kullanılmayan izin + `sharePdf` davranışı (11.3) |
| Sistem teması | light/dark | `darkTheme` yok → koyu sistemde uygulama light kalmalı (11.8) |
| Font ölçeği | 0.8 / 1.0 / 1.3 / 2.0 | `textScaler` clamp 0.8–1.0 → ≥1.0 istenmiyor (11.5) → **kabul kriteri: erişilebilirlik ölçeği ya kaldırılmalı ya belgelenmeli** |
| Notch/cutout | çentikli cihaz, gesture navigation | dashboard alt bar SafeArea'siz (11.5) |
| Yazı tipi kaynağı | ilk açılış ağa kapalı | `google_fonts` runtime fetch → fallback font (11.7) |
| Web | **test kapsamı dışı** (derlenemez, 11.1) | `dart:io` |
| Windows | pencere 1280×720, yeniden boyut, klavye yok | masaüstü `printing`/sqlite davranışı doğrulanmadı (11.9) |
| iOS | kapsam dışı (dizin yok) | — |
| RTL | tüm ekranlar | `Directionality(rtl)`; sayı/karma metin yönü (6.10) |
| Veri hacmi | 0 / 1 / 50 / 51 / 500 kayıt | `.limit(50)` kesimi, sayfalama yok (SS-07) |

### 14.8 Yayın öncesi (Definition of Done)

1. Bölüm 15'deki **kritik doğrulama listesi** (RLS, view/RPC tanımları) kapalı.
2. 14.5 veri bütünlüğü testleri geçiyor; `SalesInvoice.toJson()` `id` düzeltmesi yapılmış.
3. Ölü kod port edilmemiş (13.17 listesiyle birebir) **veya** bilinçli olarak taşındığı belgelenmiş.
4. Kullanılmayan 4 izin kaldırılmış; `usesCleartextTraffic=false`; release imzası gerçek keystore.
5. Supabase anon key/URL kaynakta değil; `.env`/dart-define ile enjekte.
6. Her SCR için en az 1 widget/1 integration testi; 12.5'teki 5 hata deseni tek desene inmiş.
7. `flutter analyze` temiz; `flutter build apk --release` ve (istenirse) `flutter build windows` başarılı.
8. Gerçek cihazda: T-01…T-29 + 14.7 matrisi elle yürütülmüş ve ekran görüntüleri Bölüm 6 ölçüleriyle karşılaştırılmış.

### 14.9 Bu bölümde ölçülemeyenler
Kabul ölçütü olarak verilemeyen, **yalnız çalıştırınca bilinecek** maddeler: gerçek hata metinlerinin son kullanıcıya ulaşma biçimi, timeout süreleri, RenderFlex taşmaları, PDF'in Arapça dizilimi, paylaşım paneli içeriği, performans sayıları (liste açılış süresi, PDF üretme süresi, bellek). → Bölüm 15.

---

## 15. Açık noktalar ve doğrulama listesi

> Bu bölüm, belgenin "uydurma yapma" kuralının çıktısıdır: **kod okunarak bilinemeyen her şey burada**. Her madde hangi komut/erişimle kapanacağını da söylüyor.

### 15.1 Sunucu tarafı (Supabase) — hiç görülemedi

| # | Bilinmeyen | Neden gerekli | Kapatma yolu |
|---|---|---|---|
| S-01 | Tüm tabloların **DDL**'i (kolon tipleri, not null, default, FK, check) | Bölüm 9'daki alan listeleri istemci çağrılarından çıkarıldı; tipler tahmin | `supabase db pull` / `pg_dump --schema-only` veya dashboard → SQL Editor: `select * from information_schema.columns where table_schema='public'` |
| S-02 | **RLS politikaları** | Çok kiracılı izolasyonun gerçekten sunucuda mı yoksa yalnız istemci filtresinde mi olduğu bilinemiyor; 10.8 #3 sızıntı riski bu soruya bağlı | `select schemaname,tablename,policyname,cmd,qual from pg_policies where schemaname='public'` |
| S-03 | `get_dashboard_financials(p_user_id, …)` **gövdesi/imzası** (SECURITY DEFINER mi, hangi parametrelerle çağrılıyor, hangi tarih filtresini kabul ediyor) | Bölüm 4/9'daki dashboard tarih filtreleme davranışı; 15.8 listesindeki "istek parametreleri" yalnız istemci tarafında görüldü | `\df+` / dashboard → Database → Functions; veya `select prosrc from pg_proc where proname='get_dashboard_financials'` |
| S-04 | `update_customer_balance` / `update_supplier_balance` gövdeleri | bakiye mutabakat kuralı (10.4), negatif/korumalı davranış (SS-05) | aynı |
| S-05 | `view_customer_debt_details`, `view_supplier_debt_details` tanımları | `total_debt`, `paid_amount`, `remaining_amount` hangi tablolardan/hesaplardan geliyor (Bölüm 9.6 sentetik örnekler alan adlarını gösteriyor, **kaynağını göstermiyor**) | `select pg_get_viewdef('public.view_customer_debt_details', true)` |
| S-06 | Realtime **publication** listesi ve hangi tabloların `replica identity` ile yayında olduğu | AF-26 realtime senkron testleri; Bölüm 10.5'teki stream listesi istemci talebi | `select * from pg_publication_tables` |
| S-07 | İndeksler / performans | sayfalama olmayan listeler (SS-07) + `ilike '%…%'` aramaları | `pg_indexes` |
| S-08 | Trigger/cascade kuralları | silme işlemlerinin istemcide elle yapılması (10.8 #6) sunucuda da bir şey yapıldığı anlamına gelmiyor | `pg_trigger` dökümü |
| S-09 | `profiles` satırının gerçek kolonları (`theme_mode`, `business_name` dışında) | Bölüm 9 auth modeli | S-01 ile |
| S-10 | Ortam ayrımı (dev/prod proje mi, hangi projeye bağlanıyor) | tek sabit `api_constans.dart:2-3` → tek ortam izlenimi | proje sahibine soru |

### 15.2 Runtime / görsel — çalıştırılmadan bilinemeyenler
Bölüm 6.10, 9.8, 10.10, 11.9, 12.9 ve 14.9'daki maddelerin toplamı; tekrar edilmiyor, **kapanış aracı tek**: gerçek bir `flutter run` oturumu + ekran görüntüleri.

| Toplam kategori | Örnek açık sorular |
|---|---|
| Görsel ölçüm | Kodda tanımsız olan gerçek satır yükseklikleri, `RenderFlex overflow` taşmaları, uzun Arapça metin davranışı, `fl_chart` eksen etiketlerinin çakışması |
| Sistem entegrasyonu | status/navigation bar renkleri, notch, gesture navigation, Android 13+ paylaşım paneli içeriği, `sharePdf` dosya adı görünümü |
| Ağ | timeout süreleri, kopan ağda hangi exception'ın fırladığı (`exceptionToFailure` eşlemesinin gerçekten `noConnection` üretip üretmediği), realtime reconnect |
| Oturum | süresi dolmuş token ile cache'li dashboard'un birleşik davranışı, çevrimdışı giriş |
| Performans | liste açılış süresi, PDF üretim süresi, `ProductCubit` sızıntısının bellek eğrisi |
| Platform derlemeleri | `flutter build web` başarısızlığı (`dart:io`), Windows derlemesi, `flutter_native_splash` ters bölü yolunun gerçekten asset bulup bulmadığı |

### 15.3 Ölü kod envanteri (51 dosya — port edilmeyecek)

Yöntem (**yeniden üretilebilir**): `lib/` içindeki 235 `.dart` dosyası için `import`/`export`/`part` kenarlarından grafik kuruldu, `lib/main.dart`'tan gezildi → 184 ulaşılabilir, **51 ulaşılamsız**. Ulaşılamaz dosyaların bir kısmı başka ölü dosyalar tarafından referans alınıyor (ikinci derece ölü).

```
core/utils/custom_loading_animation.dart        core/utils/financial_area_chart.dart
core/widgets/app_dialog.dart                    invoices/data/models/invoice_unified.dart
invoices/presentation/pages/invoice_management_page.dart
invoices/presentation/widgets/cancel_invoice_dialog.dart
invoices/presentation/widgets/customer_supplier_search_card.dart
invoices/presentation/widgets/customer_supplier_search_card_new.dart
invoices/presentation/widgets/customer_supplier_search_widget.dart
invoices/presentation/widgets/discount_widget.dart
invoices/presentation/widgets/invoice_filters_widget.dart
invoices/presentation/widgets/invoice_header_widget.dart
invoices/presentation/widgets/invoice_info_grid_widget.dart
invoices/presentation/widgets/invoice_items_widget.dart
invoices/presentation/widgets/invoice_list_widget.dart
invoices/presentation/widgets/invoice_notes_widget.dart
invoices/presentation/widgets/invoice_product_list_widget.dart
invoices/presentation/widgets/invoice_type_selector_widget.dart
invoices/presentation/widgets/purchase_invoice_list_widget.dart
invoices/presentation/widgets/quick_product_add_card.dart
invoices/presentation/widgets/quick_product_add_card_simple.dart
invoices/presentation/widgets/sales_invoice_list_widget.dart
dashboard/presentation/widgets/app_navigation_drawer.dart
dashboard/presentation/widgets/app_sidebar.dart
dashboard/presentation/widgets/custom_app_drawe.dart
dashboard/presentation/widgets/dashboard_page_wrapper.dart
dashboard/presentation/widgets/dashboard_stats_card.dart
dashboard/presentation/widgets/date_filter_section.dart
dashboard/presentation/widgets/navigation_drawer.dart
dashboard/presentation/widgets/remaining_stock_section.dart
customer_debts/data/models/models.dart
customer_debts/presentation/widgets/debt_table_header_widget.dart
suppliers_debts/data/models/models.dart
suppliers_debts/presentation/widgets/customer_summary_cards_widget.dart
suppliers_debts/presentation/widgets/debt_table_header_widget.dart
expenses/presentation/widgets/expense_cards_widget.dart
expenses/presentation/widgets/expense_list_widget.dart
reports/presentation/widgets/party_invoice_app_bar_actions.dart
reports/presentation/widgets/party_invoice_empty_state.dart
reports/presentation/widgets/party_invoice_list.dart
stock/data/models/stock_movement.dart
withdrawals/presentation/widgets/empty_state_widget.dart
withdrawals/presentation/widgets/filters_widget.dart
withdrawals/presentation/widgets/header_widget.dart
withdrawals/presentation/widgets/user_selector_widget.dart
withdrawals/presentation/widgets/view_mode_selector_widget.dart
withdrawals/presentation/widgets/withdrawal_card.dart
withdrawals/presentation/widgets/withdrawal_details_dialog.dart
withdrawals/presentation/widgets/withdrawal_list_widget.dart
withdrawals/presentation/widgets/withdrawals_app_bar.dart
withdrawals/presentation/widgets/withdrawals_cards_widget.dart
```

Ek ölü yüzeyler (dosya ölçeğinde değil): `AuthCubit.resetPassword/changePassword`, `userChanges`, `Printing.layoutPdf` yolu, `AppConstants` ve `AppFonts` içindeki 0-kullanımlı sabitler, ~40 `Failure` factory, `LoadingWidget/CustomButton/CustomTextField/core EmptyStateWidget`, `syncfusion_flutter_charts`/`uuid`/`provider`/`flutter_secure_storage`, `_isKeyboardVisible`, `profiles.theme_mode`, 4 Android izni. **D**

### 15.4 Ürün/sahip kararı gereken belirsizlikler

| # | Soru | Belgedeki iz | Neden önemli |
|---|---|---|---|
| U-01 | Uygulamanın gerçek hedef kitlesi/pazarı (Arapça UI + `SYP` varsayılan para birimi + Türkçe repo/commit dili) | 6.1, 9.8, git geçmişi | yeniden geliştirmede dil/para birimi varsayılanları |
| U-02 | Masaüstü mü mobil mi birincil? (`AppSidebar` + `windows/` var ama hiç bağlanmamış; tek breakpoint 600 px) | 11.5, 15.3 | navigasyon tasarımı |
| U-03 | Tema: Cairo mu Changa mı? Dark mode isteniyor mu (`theme_mode` yazılıyor, okunmuyor)? | 6.1, 11.8 | tipografi kararları |
| U-04 | Stok düşümü bilerek mi donduruldu, yoksa yarım kalmış mı? | 10.6 | en büyük işlevsel boşluk |
| U-05 | Şifre sıfırlama bağlantısı uygulama içinde mi tamamlanacaktı (`resetPassword` ölü, deep-link yok)? | 11.4, 10.8 #7 | auth akışı |
| U-06 | Offline hedefi: salt-okuma mı, yazma kuyruğu da mı? (yalnız müşteri ödemesi kuyrukta) | 12.7 | mimari |
| U-07 | 50 kayıt kesimi ve sayfalama eksikliği kabul edilebilir mi? | SS-07 | performans |
| U-08 | RLS var mı, yoksa çok kiracılı veri mi risk altında? | 10.8 #3, S-02 | güvenlik |
| U-09 | Uygulama mağazaya çıkacak mı (debug imza, `com.example.mindPrint` kimliği, kullanılmayan izinler)? | 11.2, 11.3 | yayın hazırılığı |
| U-10 | `test.html` ve `promt.windsurfrules` neyin çıktısı? **Bu belge kapsamında okunmadı** (kapsam dışı) | — | 16.2 |
| U-11 | README neden hâlâ Flutter şablon metni? (`README.md` 16 satır, ürünle ilgili tek cümle yok) | `README.md` | tek doküman kaynağı bu belge |
| U-12 | `MorePage` içindeki gerçek geçiş yöntemi (5.4'te satır referansıyla netleştirildi mi?) | 4.x notu | rota envanteri |

### 15.5 Kritik eksiklerin özeti (ilk 10 — yeniden geliştirme riski sırasına göre)

1. **Sunucu sözleşmesi belgesiz** (S-01…S-06): şema/RLS/view/RPC dökümü olmadan Bölüm 9-10 "yarı" doğrudur; istemci kodu DB gerçekliğini kanıtlamaz.
2. **RLS belirsizliği + arama sorgularında `user_id` filtresi yokluğu** → potansiyel kiracılar arası veri sızması (10.8 #3).
3. **Ödeme durumu turu**: DB'ye İngilizce enum yazılıyor ama `fromString` `orElse → cash`; ayrıca `status` Equatable dışında → **para tahsilatı ekranlarda yanlış görünebilir** (SS-01, SS-12).
4. **Çevrimdışı satış faturası listesi fiilen bozuk** (`SalesInvoice.toJson()` `id` yok → cache TypeError) (12.7).
5. **Timeout/retry yok** + 15 sessiz `catch (_)` → hata görünmez, spinner sonsuz (12.5 E, 12.6).
6. **Offline yazma kuyruğu asimetrik ve sessiz**: müşteri ödemesi "başarılı" görünüyor, tedarikçi ödemesi hata; `break` ile kuyruk tıkanabiliyor; sync durumu UI'da yok (12.7).
7. **Stok düşmüyor** (10.6) — muhasebe/stok uygulamasında en büyük işlevsel boşluk.
8. **Sayfalama yok + sessiz 50 kesimi** (SS-07) → veri hacmi artınca hem performans hem doğruluk riski.
9. **Yayın hazırliği yok**: debug imza, `com.example.mindPrint` kimliği, 4 gereksiz izin, cleartext, gömülü anon key, hiç test yok (11.2, 11.3, 10.8 #1, 14 giriş notu).
10. **Kod tabanının ~%22'si (51 dosya / ≈9.213 satır) ölü** ve canlı olanla iç içe → yeniden geliştirmede yanlışlıkla port edilme riski (15.3).

### 15.6 Bu belgeyi kapatma (tamamlama) planı

| Adım | Komut / erişim | Kim | Beklenen çıktı |
|---|---|---|---|
| 1 | Supabase dashboard veya `supabase db pull` + `pg_dump --schema-only` | DB erişimi olan | S-01, S-08, S-09 |
| 2 | `select * from pg_policies…`, `pg_get_viewdef(…)`, `select prosrc from pg_proc…`, `pg_publication_tables` | DB erişimi olan | S-02…S-06 |
| 3 | `flutter pub get && flutter analyze && flutter test` | geliştirici | 14.1 statik katman; bugün 0 test → ölçülen ilk sayı |
| 4 | `flutter run` (Android telefon + tablet + koyu tema + font ölçeği 2.0) | geliştirici | 15.2 görsel/izin maddeleri, Bölüm 6 ölçü karşılaştırması |
| 5 | `flutter build web` ve `flutter build windows` | CI | 11.1/11.9 doğrulaması |
| 6 | İki cihazla realtime + uçak modu senaryosu (T-26/T-27) | QA | 12.7 davranış kaydı |
| 7 | 500+ kayıt ile tohum data ve performans profili | QA | SS-07/14.7 veri hacmi |
| 8 | U-01…U-12 cevaplarının Bölüm 13 faz planına işlenmesi | ürün sahibi | kapsam onayı |

---

## 16. Kaynak dosya indeksi ve kapsam dışı

### 16.1 `lib/` dosya indeksi (235 dosya, 45.796 satır)

Sütun **Erişim**: `canlı` = `lib/main.dart`'tan `import/export/part` grafiğinde ulaşılıyor; `ölü` = ulaşılamıyor (15.3 yöntemiyle yeniden üretilebilir). Grup satırları dizin adlarıdır.

| Yol | Satır | Erişim |
|---|---|---|
| **lib/** | | |
| `lib/main.dart` | 132 | canlı (giriş noktası) |
| **lib/core/constants/** | | |
| `lib/core/constants/api_constans.dart` | 4 | canlı |
| `lib/core/constants/app_constants.dart` | 189 | canlı |
| **lib/core/database/** | | |
| `lib/core/database/app_database.dart` | 201 | canlı |
| **lib/core/di/** | | |
| `lib/core/di/services_locator.dart` | 227 | canlı |
| **lib/core/errors/** | | |
| `lib/core/errors/failures.dart` | 284 | canlı |
| **lib/core/network/** | | |
| `lib/core/network/network_info.dart` | 37 | canlı |
| **lib/core/services/** | | |
| `lib/core/services/invoice_pdf_service.dart` | 245 | canlı |
| `lib/core/services/pdf_invoice_service.dart` | 864 | canlı |
| `lib/core/services/user_service.dart` | 47 | canlı |
| **lib/core/theme/** | | |
| `lib/core/theme/app_theme.dart` | 255 | canlı |
| **lib/core/utils/** | | |
| `lib/core/utils/app_utils.dart` | 166 | canlı |
| `lib/core/utils/custom_date_range_picker.dart` | 217 | canlı |
| `lib/core/utils/custom_loading_animation.dart` | 24 | **ölü** |
| `lib/core/utils/financial_area_chart.dart` | 430 | **ölü** |
| `lib/core/utils/number_formatter.dart` | 145 | canlı |
| **lib/core/widgets/** | | |
| `lib/core/widgets/app_dialog.dart` | 229 | **ölü** |
| `lib/core/widgets/common_widgets.dart` | 359 | canlı |
| `lib/core/widgets/date_filter_sheet.dart` | 243 | canlı |
| `lib/core/widgets/invoice_card_widget.dart` | 257 | canlı |
| **lib/features/auth/data/datasource/** | | |
| `lib/features/auth/data/datasource/auth_local_datasource.dart` | 111 | canlı |
| `lib/features/auth/data/datasource/auth_remote_datasource.dart` | 252 | canlı |
| **lib/features/auth/data/models/** | | |
| `lib/features/auth/data/models/user.dart` | 111 | canlı |
| **lib/features/auth/data/repositories/** | | |
| `lib/features/auth/data/repositories/auth_repository.dart` | 196 | canlı |
| **lib/features/auth/presentation/bloc/** | | |
| `lib/features/auth/presentation/bloc/auth_cubit.dart` | 85 | canlı |
| `lib/features/auth/presentation/bloc/auth_state.dart` | 57 | canlı |
| **lib/features/auth/presentation/pages/** | | |
| `lib/features/auth/presentation/pages/login_page.dart` | 63 | canlı |
| **lib/features/auth/presentation/widgets/** | | |
| `lib/features/auth/presentation/widgets/login_form.dart` | 243 | canlı |
| **lib/features/customer_debts/data/datasource/** | | |
| `lib/features/customer_debts/data/datasource/customer_debt_local_datasource.dart` | 113 | canlı |
| `lib/features/customer_debts/data/datasource/customer_debt_remote_datasource.dart` | 258 | canlı |
| **lib/features/customer_debts/data/models/** | | |
| `lib/features/customer_debts/data/models/customer_debt_model.dart` | 110 | canlı |
| `lib/features/customer_debts/data/models/customer_debt_totals_model.dart` | 34 | canlı |
| `lib/features/customer_debts/data/models/invoice_model.dart` | 150 | canlı |
| `lib/features/customer_debts/data/models/models.dart` | 11 | **ölü** |
| `lib/features/customer_debts/data/models/payment_model.dart` | 133 | canlı |
| **lib/features/customer_debts/data/repositories/** | | |
| `lib/features/customer_debts/data/repositories/customer_debt_repository.dart` | 19 | canlı |
| `lib/features/customer_debts/data/repositories/customer_debt_repository_impl.dart` | 291 | canlı |
| **lib/features/customer_debts/presentation/bloc/** | | |
| `lib/features/customer_debts/presentation/bloc/customer_debt_cubit.dart` | 174 | canlı |
| `lib/features/customer_debts/presentation/bloc/customer_debt_state.dart` | 68 | canlı |
| **lib/features/customer_debts/presentation/pages/** | | |
| `lib/features/customer_debts/presentation/pages/customer_debts_page.dart` | 196 | canlı |
| `lib/features/customer_debts/presentation/pages/customer_detail_page.dart` | 645 | canlı |
| **lib/features/customer_debts/presentation/widgets/** | | |
| `lib/features/customer_debts/presentation/widgets/customer_detail_header_widget.dart` | 85 | canlı |
| `lib/features/customer_debts/presentation/widgets/customer_summary_cards_widget.dart` | 126 | canlı |
| `lib/features/customer_debts/presentation/widgets/debt_card_widget.dart` | 166 | canlı |
| `lib/features/customer_debts/presentation/widgets/debt_search_widget.dart` | 95 | canlı |
| `lib/features/customer_debts/presentation/widgets/debt_stats_widget.dart` | 191 | canlı |
| `lib/features/customer_debts/presentation/widgets/debt_table_header_widget.dart` | 73 | **ölü** |
| `lib/features/customer_debts/presentation/widgets/payment_dialog_widget.dart` | 306 | canlı |
| `lib/features/customer_debts/presentation/widgets/payment_history_widget.dart` | 315 | canlı |
| `lib/features/customer_debts/presentation/widgets/payment_modal_widget.dart` | 289 | canlı |
| `lib/features/customer_debts/presentation/widgets/unpaid_invoices_widget.dart` | 241 | canlı |
| **lib/features/customers/data/datasource/** | | |
| `lib/features/customers/data/datasource/customer_remote_datasource.dart` | 146 | canlı |
| **lib/features/customers/data/models/** | | |
| `lib/features/customers/data/models/customer.dart` | 127 | canlı |
| **lib/features/customers/data/repositories/** | | |
| `lib/features/customers/data/repositories/customer_repository.dart` | 118 | canlı |
| **lib/features/customers/presentation/bloc/** | | |
| `lib/features/customers/presentation/bloc/customer_cubit.dart` | 113 | canlı |
| `lib/features/customers/presentation/bloc/customer_state.dart` | 52 | canlı |
| **lib/features/customers/presentation/pages/** | | |
| `lib/features/customers/presentation/pages/customers_page.dart` | 197 | canlı |
| **lib/features/customers/presentation/widgets/** | | |
| `lib/features/customers/presentation/widgets/customer_form_widget.dart` | 158 | canlı |
| `lib/features/customers/presentation/widgets/customer_list_widget.dart` | 323 | canlı |
| **lib/features/dashboard/data/datasource/** | | |
| `lib/features/dashboard/data/datasource/dashboard_local_datasource.dart` | 45 | canlı |
| `lib/features/dashboard/data/datasource/dashboard_remote_datasource.dart` | 65 | canlı |
| **lib/features/dashboard/data/helpers/** | | |
| `lib/features/dashboard/data/helpers/dashboard_filter_helper.dart` | 61 | canlı |
| **lib/features/dashboard/data/models/** | | |
| `lib/features/dashboard/data/models/dashboard_financials.dart` | 79 | canlı |
| `lib/features/dashboard/data/models/dashboard_product_stock.dart` | 64 | canlı |
| **lib/features/dashboard/data/repositories/** | | |
| `lib/features/dashboard/data/repositories/dashboard_repository.dart` | 76 | canlı |
| **lib/features/dashboard/presentation/bloc/** | | |
| `lib/features/dashboard/presentation/bloc/dashboard_cubit.dart` | 116 | canlı |
| `lib/features/dashboard/presentation/bloc/dashboard_state.dart` | 76 | canlı |
| **lib/features/dashboard/presentation/pages/** | | |
| `lib/features/dashboard/presentation/pages/dashboard_overview.dart` | 383 | canlı |
| `lib/features/dashboard/presentation/pages/dashboard_page.dart` | 187 | canlı |
| `lib/features/dashboard/presentation/pages/more_page.dart` | 122 | canlı |
| **lib/features/dashboard/presentation/widgets/** | | |
| `lib/features/dashboard/presentation/widgets/app_bar_date_filter.dart` | 122 | canlı |
| `lib/features/dashboard/presentation/widgets/app_navigation_drawer.dart` | 126 | **ölü** |
| `lib/features/dashboard/presentation/widgets/app_sidebar.dart` | 145 | **ölü** |
| `lib/features/dashboard/presentation/widgets/custom_app_drawe.dart` | 285 | **ölü** |
| `lib/features/dashboard/presentation/widgets/dashboard_page_wrapper.dart` | 23 | **ölü** |
| `lib/features/dashboard/presentation/widgets/dashboard_stats_card.dart` | 71 | **ölü** |
| `lib/features/dashboard/presentation/widgets/date_filter_section.dart` | 205 | **ölü** |
| `lib/features/dashboard/presentation/widgets/navigation_drawer.dart` | 128 | **ölü** |
| `lib/features/dashboard/presentation/widgets/remaining_stock_section.dart` | 185 | **ölü** |
| **lib/features/expenses/data/datasource/** | | |
| `lib/features/expenses/data/datasource/expense_remote_datasource.dart` | 226 | canlı |
| **lib/features/expenses/data/models/** | | |
| `lib/features/expenses/data/models/expense.dart` | 116 | canlı |
| `lib/features/expenses/data/models/expense_category.dart` | 68 | canlı |
| **lib/features/expenses/data/repositories/** | | |
| `lib/features/expenses/data/repositories/expense_repository.dart` | 176 | canlı |
| **lib/features/expenses/presentation/bloc/** | | |
| `lib/features/expenses/presentation/bloc/expense_cubit.dart` | 246 | canlı |
| `lib/features/expenses/presentation/bloc/expense_state.dart` | 100 | canlı |
| **lib/features/expenses/presentation/pages/** | | |
| `lib/features/expenses/presentation/pages/expenses_page.dart` | 450 | canlı |
| **lib/features/expenses/presentation/widgets/** | | |
| `lib/features/expenses/presentation/widgets/expense_cards_widget.dart` | 222 | **ölü** |
| `lib/features/expenses/presentation/widgets/expense_categories_dialog.dart` | 322 | canlı |
| `lib/features/expenses/presentation/widgets/expense_detail_dialog.dart` | 174 | canlı |
| `lib/features/expenses/presentation/widgets/expense_filters_widget.dart` | 181 | canlı |
| `lib/features/expenses/presentation/widgets/expense_form_dialog.dart` | 413 | canlı |
| `lib/features/expenses/presentation/widgets/expense_list_widget.dart` | 351 | **ölü** |
| `lib/features/expenses/presentation/widgets/expense_monthly_chart_widget.dart` | 210 | canlı |
| `lib/features/expenses/presentation/widgets/expense_summary_cards_widget.dart` | 90 | canlı |
| `lib/features/expenses/presentation/widgets/expense_table_widget.dart` | 219 | canlı |
| **lib/features/invoices/data/datasources/** | | |
| `lib/features/invoices/data/datasources/edit_invoice_datasource.dart` | 223 | canlı |
| `lib/features/invoices/data/datasources/invoice_local_datasource.dart` | 57 | canlı |
| `lib/features/invoices/data/datasources/invoice_remote_datasource.dart` | 516 | canlı |
| **lib/features/invoices/data/models/** | | |
| `lib/features/invoices/data/models/invoice.dart` | 195 | canlı |
| `lib/features/invoices/data/models/invoice_item.dart` | 128 | canlı |
| `lib/features/invoices/data/models/invoice_status.dart` | 32 | canlı |
| `lib/features/invoices/data/models/invoice_unified.dart` | 170 | **ölü** |
| `lib/features/invoices/data/models/payment_status.dart` | 31 | canlı |
| `lib/features/invoices/data/models/purchase_invoice.dart` | 191 | canlı |
| `lib/features/invoices/data/models/sales_invoice.dart` | 328 | canlı |
| **lib/features/invoices/data/repositories/** | | |
| `lib/features/invoices/data/repositories/edit_invoice_repository.dart` | 81 | canlı |
| `lib/features/invoices/data/repositories/invoice_repository.dart` | 232 | canlı |
| **lib/features/invoices/presentation/bloc/** | | |
| `lib/features/invoices/presentation/bloc/edit_invoice_cubit.dart` | 361 | canlı |
| `lib/features/invoices/presentation/bloc/edit_invoice_state.dart` | 87 | canlı |
| `lib/features/invoices/presentation/bloc/invoice_cubit.dart` | 944 | canlı |
| `lib/features/invoices/presentation/bloc/invoice_state.dart` | 178 | canlı |
| **lib/features/invoices/presentation/pages/** | | |
| `lib/features/invoices/presentation/pages/create_invoice_page.dart` | 105 | canlı |
| `lib/features/invoices/presentation/pages/edit_invoice_page.dart` | 176 | canlı |
| `lib/features/invoices/presentation/pages/invoice_detail_page.dart` | 618 | canlı |
| `lib/features/invoices/presentation/pages/invoice_management_page.dart` | 389 | **ölü** |
| `lib/features/invoices/presentation/pages/invoices_page.dart` | 425 | canlı |
| **lib/features/invoices/presentation/widgets/** | | |
| `lib/features/invoices/presentation/widgets/cancel_invoice_dialog.dart` | 33 | **ölü** |
| `lib/features/invoices/presentation/widgets/combined_invoice_info_widget.dart` | 362 | canlı |
| `lib/features/invoices/presentation/widgets/customer_supplier_search_card.dart` | 461 | **ölü** |
| `lib/features/invoices/presentation/widgets/customer_supplier_search_card_new.dart` | 444 | **ölü** |
| `lib/features/invoices/presentation/widgets/customer_supplier_search_widget.dart` | 632 | **ölü** |
| `lib/features/invoices/presentation/widgets/delete_invoice_dialog.dart` | 35 | canlı |
| `lib/features/invoices/presentation/widgets/discount_widget.dart` | 119 | **ölü** |
| `lib/features/invoices/presentation/widgets/edit_customer_supplier_widget.dart` | 307 | canlı |
| `lib/features/invoices/presentation/widgets/edit_invoice_actions_widget.dart` | 146 | canlı |
| `lib/features/invoices/presentation/widgets/edit_invoice_dates_widget.dart` | 209 | canlı |
| `lib/features/invoices/presentation/widgets/edit_invoice_summary_widget.dart` | 205 | canlı |
| `lib/features/invoices/presentation/widgets/edit_invoice_type_widget.dart` | 81 | canlı |
| `lib/features/invoices/presentation/widgets/edit_product_add_widget.dart` | 823 | canlı |
| `lib/features/invoices/presentation/widgets/invoice_action_buttons_widget.dart` | 116 | canlı |
| `lib/features/invoices/presentation/widgets/invoice_actions_widget.dart` | 285 | canlı |
| `lib/features/invoices/presentation/widgets/invoice_card_widget.dart` | 1 | canlı |
| `lib/features/invoices/presentation/widgets/invoice_dates_widget.dart` | 241 | canlı |
| `lib/features/invoices/presentation/widgets/invoice_detail_header_widget.dart` | 58 | canlı |
| `lib/features/invoices/presentation/widgets/invoice_details_widget.dart` | 641 | canlı |
| `lib/features/invoices/presentation/widgets/invoice_empty_state_widget.dart` | 52 | canlı |
| `lib/features/invoices/presentation/widgets/invoice_filters_widget.dart` | 179 | **ölü** |
| `lib/features/invoices/presentation/widgets/invoice_header_widget.dart` | 116 | **ölü** |
| `lib/features/invoices/presentation/widgets/invoice_info_card_widget.dart` | 222 | canlı |
| `lib/features/invoices/presentation/widgets/invoice_info_grid_widget.dart` | 225 | **ölü** |
| `lib/features/invoices/presentation/widgets/invoice_items_widget.dart` | 102 | **ölü** |
| `lib/features/invoices/presentation/widgets/invoice_list_widget.dart` | 179 | **ölü** |
| `lib/features/invoices/presentation/widgets/invoice_notes_widget.dart` | 277 | **ölü** |
| `lib/features/invoices/presentation/widgets/invoice_product_list_widget.dart` | 223 | **ölü** |
| `lib/features/invoices/presentation/widgets/invoice_stats_widget.dart` | 95 | canlı |
| `lib/features/invoices/presentation/widgets/invoice_status_dialog.dart` | 73 | canlı |
| `lib/features/invoices/presentation/widgets/invoice_summary_widget.dart` | 281 | canlı |
| `lib/features/invoices/presentation/widgets/invoice_totals_widget.dart` | 84 | canlı |
| `lib/features/invoices/presentation/widgets/invoice_type_selector_widget.dart` | 202 | **ölü** |
| `lib/features/invoices/presentation/widgets/payment_status_dialog.dart` | 73 | canlı |
| `lib/features/invoices/presentation/widgets/product_add_fullscreen_widget.dart` | 537 | canlı |
| `lib/features/invoices/presentation/widgets/product_add_widget.dart` | 449 | canlı |
| `lib/features/invoices/presentation/widgets/product_list_widget.dart` | 302 | canlı |
| `lib/features/invoices/presentation/widgets/purchase_invoice_list_widget.dart` | 349 | **ölü** |
| `lib/features/invoices/presentation/widgets/quick_product_add_card.dart` | 413 | **ölü** |
| `lib/features/invoices/presentation/widgets/quick_product_add_card_simple.dart` | 468 | **ölü** |
| `lib/features/invoices/presentation/widgets/sales_invoice_list_widget.dart` | 379 | **ölü** |
| **lib/features/products/data/datasource/** | | |
| `lib/features/products/data/datasource/product_remote_datasource.dart` | 275 | canlı |
| **lib/features/products/data/models/** | | |
| `lib/features/products/data/models/product.dart` | 186 | canlı |
| `lib/features/products/data/models/product_category.dart` | 82 | canlı |
| `lib/features/products/data/models/product_unit_data.dart` | 14 | canlı |
| **lib/features/products/data/repositories/** | | |
| `lib/features/products/data/repositories/product_repository.dart` | 210 | canlı |
| **lib/features/products/presentation/bloc/** | | |
| `lib/features/products/presentation/bloc/product_cubit.dart` | 250 | canlı |
| `lib/features/products/presentation/bloc/product_state.dart` | 61 | canlı |
| **lib/features/products/presentation/pages/** | | |
| `lib/features/products/presentation/pages/products_page.dart` | 546 | canlı |
| **lib/features/products/presentation/widgets/** | | |
| `lib/features/products/presentation/widgets/category_form_widget.dart` | 105 | canlı |
| `lib/features/products/presentation/widgets/category_list_widget.dart` | 190 | canlı |
| `lib/features/products/presentation/widgets/product_card_widget.dart` | 160 | canlı |
| `lib/features/products/presentation/widgets/product_form_widget.dart` | 301 | canlı |
| `lib/features/products/presentation/widgets/product_list_widget.dart` | 169 | canlı |
| **lib/features/reports/data/datasources/** | | |
| `lib/features/reports/data/datasources/report_remote_datasource.dart` | 98 | canlı |
| **lib/features/reports/data/repositories/** | | |
| `lib/features/reports/data/repositories/report_repository.dart` | 36 | canlı |
| **lib/features/reports/presentation/bloc/** | | |
| `lib/features/reports/presentation/bloc/party_invoice_cubit.dart` | 120 | canlı |
| `lib/features/reports/presentation/bloc/party_invoice_state.dart` | 38 | canlı |
| **lib/features/reports/presentation/pages/** | | |
| `lib/features/reports/presentation/pages/customer_invoice_detail_page.dart` | 258 | canlı |
| `lib/features/reports/presentation/pages/customer_invoices_page.dart` | 217 | canlı |
| `lib/features/reports/presentation/pages/stock_tracking_page.dart` | 400 | canlı |
| `lib/features/reports/presentation/pages/takrirler_page.dart` | 118 | canlı |
| **lib/features/reports/presentation/widgets/** | | |
| `lib/features/reports/presentation/widgets/party_invoice_app_bar_actions.dart` | 74 | **ölü** |
| `lib/features/reports/presentation/widgets/party_invoice_empty_state.dart` | 28 | **ölü** |
| `lib/features/reports/presentation/widgets/party_invoice_list.dart` | 29 | **ölü** |
| `lib/features/reports/presentation/widgets/party_list_tile.dart` | 46 | canlı |
| **lib/features/settings/presentation/pages/** | | |
| `lib/features/settings/presentation/pages/settings_page.dart` | 455 | canlı |
| **lib/features/stock/data/models/** | | |
| `lib/features/stock/data/models/stock_movement.dart` | 88 | **ölü** |
| **lib/features/suppliers/data/datasource/** | | |
| `lib/features/suppliers/data/datasource/supplier_remote_datasource.dart` | 141 | canlı |
| **lib/features/suppliers/data/models/** | | |
| `lib/features/suppliers/data/models/supplier.dart` | 100 | canlı |
| **lib/features/suppliers/data/repositories/** | | |
| `lib/features/suppliers/data/repositories/supplier_repository.dart` | 111 | canlı |
| **lib/features/suppliers/presentation/bloc/** | | |
| `lib/features/suppliers/presentation/bloc/supplier_cubit.dart` | 112 | canlı |
| `lib/features/suppliers/presentation/bloc/supplier_state.dart` | 48 | canlı |
| **lib/features/suppliers/presentation/pages/** | | |
| `lib/features/suppliers/presentation/pages/suppliers_page.dart` | 195 | canlı |
| **lib/features/suppliers/presentation/widgets/** | | |
| `lib/features/suppliers/presentation/widgets/supplier_form_widget.dart` | 123 | canlı |
| `lib/features/suppliers/presentation/widgets/supplier_list_widget.dart` | 268 | canlı |
| **lib/features/suppliers_debts/data/datasource/** | | |
| `lib/features/suppliers_debts/data/datasource/supplier_debt_remote_datasource.dart` | 267 | canlı |
| **lib/features/suppliers_debts/data/models/** | | |
| `lib/features/suppliers_debts/data/models/invoice_model.dart` | 141 | canlı |
| `lib/features/suppliers_debts/data/models/models.dart` | 4 | **ölü** |
| `lib/features/suppliers_debts/data/models/payment_model.dart` | 117 | canlı |
| `lib/features/suppliers_debts/data/models/supplier_debt_model.dart` | 110 | canlı |
| `lib/features/suppliers_debts/data/models/supplier_debt_totals_model.dart` | 34 | canlı |
| **lib/features/suppliers_debts/data/repositories/** | | |
| `lib/features/suppliers_debts/data/repositories/supplier_debt_repository.dart` | 18 | canlı |
| `lib/features/suppliers_debts/data/repositories/supplier_debt_repository_impl.dart` | 149 | canlı |
| **lib/features/suppliers_debts/presentation/bloc/** | | |
| `lib/features/suppliers_debts/presentation/bloc/supplier_debt_cubit.dart` | 239 | canlı |
| **lib/features/suppliers_debts/presentation/pages/** | | |
| `lib/features/suppliers_debts/presentation/pages/supplier_detail_page.dart` | 505 | canlı |
| `lib/features/suppliers_debts/presentation/pages/suppliers_debts_page.dart` | 192 | canlı |
| **lib/features/suppliers_debts/presentation/widgets/** | | |
| `lib/features/suppliers_debts/presentation/widgets/customer_summary_cards_widget.dart` | 61 | **ölü** |
| `lib/features/suppliers_debts/presentation/widgets/debt_card_widget.dart` | 156 | canlı |
| `lib/features/suppliers_debts/presentation/widgets/debt_stats_widget.dart` | 169 | canlı |
| `lib/features/suppliers_debts/presentation/widgets/debt_table_header_widget.dart` | 45 | **ölü** |
| `lib/features/suppliers_debts/presentation/widgets/payment_dialog_widget.dart` | 299 | canlı |
| `lib/features/suppliers_debts/presentation/widgets/payment_history_widget.dart` | 311 | canlı |
| `lib/features/suppliers_debts/presentation/widgets/payment_modal_widget.dart` | 283 | canlı |
| `lib/features/suppliers_debts/presentation/widgets/supplier_detail_header_widget.dart` | 85 | canlı |
| `lib/features/suppliers_debts/presentation/widgets/unpaid_invoices_widget.dart` | 245 | canlı |
| **lib/features/withdrawals/data/datasource/** | | |
| `lib/features/withdrawals/data/datasource/withdrawal_remote_datasource.dart` | 216 | canlı |
| **lib/features/withdrawals/data/models/** | | |
| `lib/features/withdrawals/data/models/partner.dart` | 55 | canlı |
| `lib/features/withdrawals/data/models/withdrawal.dart` | 103 | canlı |
| **lib/features/withdrawals/data/repositories/** | | |
| `lib/features/withdrawals/data/repositories/withdrawal_repository.dart` | 151 | canlı |
| **lib/features/withdrawals/presentation/bloc/** | | |
| `lib/features/withdrawals/presentation/bloc/withdrawal_cubit.dart` | 255 | canlı |
| `lib/features/withdrawals/presentation/bloc/withdrawal_state.dart` | 98 | canlı |
| **lib/features/withdrawals/presentation/pages/** | | |
| `lib/features/withdrawals/presentation/pages/withdrawals_page.dart` | 478 | canlı |
| **lib/features/withdrawals/presentation/widgets/** | | |
| `lib/features/withdrawals/presentation/widgets/add_user_dialog.dart` | 233 | canlı |
| `lib/features/withdrawals/presentation/widgets/add_withdrawal_dialog.dart` | 394 | canlı |
| `lib/features/withdrawals/presentation/widgets/empty_state_widget.dart` | 25 | **ölü** |
| `lib/features/withdrawals/presentation/widgets/filters_widget.dart` | 244 | **ölü** |
| `lib/features/withdrawals/presentation/widgets/header_widget.dart` | 27 | **ölü** |
| `lib/features/withdrawals/presentation/widgets/monthly_chart_widget.dart` | 178 | canlı |
| `lib/features/withdrawals/presentation/widgets/summary_cards_widget.dart` | 84 | canlı |
| `lib/features/withdrawals/presentation/widgets/user_selector_widget.dart` | 304 | **ölü** |
| `lib/features/withdrawals/presentation/widgets/view_mode_selector_widget.dart` | 64 | **ölü** |
| `lib/features/withdrawals/presentation/widgets/withdrawal_card.dart` | 43 | **ölü** |
| `lib/features/withdrawals/presentation/widgets/withdrawal_detail_dialog.dart` | 172 | canlı |
| `lib/features/withdrawals/presentation/widgets/withdrawal_details_dialog.dart` | 45 | **ölü** |
| `lib/features/withdrawals/presentation/widgets/withdrawal_list_widget.dart` | 52 | **ölü** |
| `lib/features/withdrawals/presentation/widgets/withdrawals_app_bar.dart` | 26 | **ölü** |
| `lib/features/withdrawals/presentation/widgets/withdrawals_cards_widget.dart` | 224 | **ölü** |
| `lib/features/withdrawals/presentation/widgets/withdrawals_table_widget.dart` | 211 | canlı |

### 16.2 `lib/` dışı incelenen yapılandırma dosyaları

| Dosya | Ne için okundu | İlgili bölüm |
|---|---|---|
| `pubspec.yaml` | bağımlılıklar, SDK, asset, launcher/splash ayarları | 2, 10.7, 11.2, 11.7 |
| `analysis_options.yaml` | lint seti (`flutter_lints`) | 14.1 |
| `android/app/build.gradle.kts` | namespace/applicationId, Java 17, debug imza | 11.2 |
| `android/settings.gradle.kts` | AGP/Kotlin zorlaması, Aliyun aynaları | 11.2 |
| `android/app/src/main/AndroidManifest.xml` | izinler, label, cleartext, activity, intent-filter | 11.3, 11.4 |
| `android/app/src/{debug,profile}/AndroidManifest.xml` | yalnız INTERNET | 11.3 |
| `android/app/src/main/kotlin/**/MainActivity.kt` (2) | aktif/ölü activity | 11.2 |
| `android/app/src/main/res/values*/styles.xml`, `drawable*/launch_background.xml` | splash/tema, forceDark, cutout | 11.4 |
| `web/index.html`, `web/manifest.json` | web meta/renk uyumsuzluğu | 11.7 |
| `windows/runner/main.cpp`, `windows/runner/Runner.rc` | pencere başlığı/boyutu, şirket adı | 11.1 |
| `README.md` | ürün niyeti hakkında bilgi **yok** (16 satır şablon metni) | 15.4 U-11 |

### 16.3 Kapsam dışı bırakılanlar (bilinçli)

| Kapsam dışı | Neden |
|---|---|
| `build/` | üretilmiş derleme çıktıları; kaynak değil |
| `assets/images/*.png`, `android/app/src/main/res/**.png`, `web/icons/*` | ikili görseller; piksel içeriği bu belgenin konusu değil (yalnız hangi kodun tükettiği belirtildi) |
| `docs/**`, `promt.windsurfrules`, `test.html`, `*.iml`, `pubspec.lock`, `android/local.properties` | uygulama davranışını tanımlamıyor; `test.html`/`promt.windsurfrules` **hiç okunmadı** (15.4 U-10) |
| Supabase sunucu tarafı (şema, RLS, view, RPC, publication, trigger, index) | istemci kodundan okunamıyor → 15.1 |
| iOS/macOS/Linux yapılandırması | repoda dizin yok (11.1) |
| Runtime ölçümleri (kare hızı, bellek, süreler) | çalıştırma yok (15.2) |
| Gerçek kullanıcı verisi / içerik | yok; Bölüm 9'daki örnekler **sentetik** |
| **Gizli anahtar değerleri** | görev gereği **bu belgeye yazılmadı** — yalnız hangi satırlarda tanımlı olduğu (`api_constans.dart:2-3`) ve nasıl taşınması gerektiği belirtildi (10.1, 10.8 #1) |

### 16.4 Kalite kontrolü (son geçiş bulguları)

**A. Rota ↔ ekran envanteri karşılaştırması** — **Doğrulandı**
- `AppRoutes` sabit sayısı: **19** (`app_constants.dart:142-162`).
- `_generateRoute` `case` sayısı: **9** (`main.dart:75-104`: products, customers, invoices, suppliers, expenses, withdrawals, settings, customerDebts, takrirler).
- Handler'ı olmayan 10 sabit: `login`, `dashboard` (`home:` üzerinden zaten gösteriliyor), `analytics`, `profile`, `customerDetails`, `productDetails`, `invoiceDetails`, `createInvoice`, `supplierDetails`, `expenseDetails` → hepsi `default` dalına düşüp **`DashboardPage` gösteriyor** (`main.dart:104-105`). `/:id` kalıplı 5 sabit **parametre taşımacılığı için hiç kullanılmıyor**; detay sayfaları `MaterialPageRoute(builder:)` ile doğrudan push ediliyor (Bölüm 4).
- Canlı `Navigator.pushNamed` çağrıları: **7**, hepsi `more_page.dart:28-64` (customers, suppliers, expenses, withdrawals, products, takrirler, settings). Ölü drawer widget'larında (`app_navigation_drawer.dart`, `navigation_drawer.dart`, `custom_app_drawe.dart`) 8 ek çağrı var ama bu dosyalar 15.3'te ulaşılamaz → **`/analytics` rota talebi yalnız ölü kodda** ve olsa olsa DashboardPage'e düşerdi.
- `customerDebts` sabiti handler'lı ama **canlı pushNamed çağrısı yok** → SCR-006'ya yalnız sekmeden ulaşılıyor (Bölüm 4 tablosuyla tutarlı).
- Ekran sayımı: §5.1 kanonik tablosunda **SCR-001…SCR-024** (24 kimlik) + 5 dashboard içi sekme; Bölüm 1/özet tablosundaki "20 sayfa/ekran" ifadesi **bu sayımla çelişiyordu → SCR tablosu esas alınarak düzeltildi** (16.4/B).

**B. Çelişki taraması ve bu oturumda düzeltilen iddialar** — belge kalitesi için şeffaf kayıt
| # | Yanlış/eksik iddia | Doğrusu | Kanıt |
|---|---|---|---|
| 1 | Ürün listesi "GridView `crossAxisCount: 2`, aspectRatio 0.9" | `ListView.builder(shrinkWrap:true, physics:NeverScrollableScrollPhysics)` tek sütun; ** GridView değil** | `product_list_widget.dart:97,146` |
| 2 | "AnalyticsPage" ekranı var | Böyle bir sayfa **yok** (`find`/grep: 0); yalnız rota sabiti + `AppStrings.analytics` metni | 15.3, 16.4/A |
| 3 | "Abonelikler hiç kapatılmıyor" | 8 cubit'in 8'i de `close()` override ediyor; **istisna `ProductCubit`** (`BlocProvider.value`, 3 yer) | 10.9 |
| 4 | `invoice_unified.dart` round-trip hatası canlı akışı bozuyor | Dosya **ulaşılamaz**; canlı modeller İngilizce enum adı yazıyor/okuyor (tutarlı) | `sales_invoice.dart:138/172`, `purchase_invoice.dart:121/147`, 15.3 |
| 5 | `product_unit_data.dart` için "invoices altında ikinci kopya var" | **Tek kopya** `products/data/models/` altında; tek tüketici `product_form_widget.dart:6` | `find lib -name product_unit_data*` |
| 6 | `provider`/`path_provider` "kullanımsız" | `provider` yalnız ölü import (`invoice_detail_page.dart:8`); `path_provider` **canlı** (`app_database.dart:6`) | 10.7 |
| 7 | §9.6 dashboard RPC örneklerinde uydurma anahtarlar | Gerçek `fromMap` anahtarları kullanıldı | 9.6 |
| 8 | Auth dalı iddiaları (login `AuthSuccess`, logout `AuthUninitialized`) | login → `Authenticated`; logout → `Unauthenticated`; `AuthSuccess` yalnız şifre sıfırlama | `auth_cubit.dart`, `login_page.dart:14-60` |
| 9 | SCR kimlikleri §5.1 ile §5.10+ arasında kayıyordu | §5.1 kanonik; §5.29 düzeltme notu eklendi | 5.29 |
| 10 | Özet tablosunda "20 sayfa/ekran" | SCR-001…024 = **24** kimlik (5'i dashboard sekmesi) | 5.1 |

**C. Yeni bulunan çelişkiler (bu geçişte eklendi)**
1. **Para birimi üç katmanda tutarsız:** kayıt DB'ye `currency_code: 'SAR'` yazıyor (`auth_remote_datasource.dart:84,102`; `user.dart:25,104` default `SAR`), istemci varsayılanı `NumberFormatter._selectedCurrency = 'SYP'` (`number_formatter.dart:9,24,29`), ve `SAR` sembol sözlüğünde yok → sembol olarak ham `SAR` basılır (SS-10). **`User.currencyCode` hiçbir yerde `NumberFormatter`'a beslenmiyor**; tek `setCurrency` çağrısı `settings_page.dart:269`. Sonuç: yeni hesap kayıttan sonra **SYP** ile gösterime başlar, profilinde SAR yazar. **Doğrulandı** → 15.4 U-01 ve 13.15 (düzeltme listesi) ile ilişkili.
2. **Tema:** Bölüm 6.1'deki Cairo/Changa çelişkisi duruyor; ek olarak `NormalTheme` Android pencere rengi (`?android:colorBackground`) ile `AppColors.background=#FFFFFF` ayrı kaynaklardan geliyor (11.4).
3. **Erişim adı çakışması:** iki farklı `EmptyStateWidget` (12.1).
4. **Sayı biçimi tercihi:** `main.dart:27` her açılışta `setArabicFormat(true)` → kullanıcı tercihi eziliyor (SS-11); `pubspec`/prefs üzerinden kalıcılık iddiası **yanlış olurdu**, belge bunu "her açılışta overwrite" olarak düzeltti.
5. **Ölü kod canlı görünüm veriyor:** Bölüm 5'te "erişilemeyen sayfa" olarak işaretli `InvoiceManagementPage`, 15.3'te de ölü; ayrıca dashboard'un 5 navigasyon/kabuk varyantı ölü → "uygulamada drawer/sidebar var" çıkarımı **yanlış olurdu** (11.5'te engellendi).

**D. Kritik eksiklerin son tekrarı** (detay: 15.5)
Sunucu sözleşmesinin (şema/RLS/view/RPC/publication) hiç görülememiş olması, ödeme durumu turundaki `orElse → cash` + `status` Equatable boşluğu, bozuk satış faturası cache'i, timeout/retry yokluğu ve 15 sessiz `catch (_)`, asimetrik ve sessiz offline ödeme kuyruğu, hiç uygulanmayan stok düşümü, sayfalama yokluğu/50 kesimi, yayın hazırlığı eksikleri (debug imza, `com.example.mindPrint`, 4 gereksiz izin, cleartext, gömülü anon key) ve **hiç test bulunmaması**. Bu maddeler kapatılmadan "birebir yeniden geliştirme" yalnız **istemci davranışı** düzeyinde doğrudur.

### 16.5 Belgenin yeniden üretilebilirliği

| İş | Komut |
|---|---|
| Dosya/satır erişilebilirlik sayımı (15.3, 16.1) | `lib/` üzerinde `import/export/part` grafiği kurup `lib/main.dart`'tan DFS — bu belgede kullanılan yöntem; çıktı: 235 dosya / 184 canlı / 51 ölü |
| Rota envanteri | `grep -n "case AppRoutes" lib/main.dart` + `grep -n "class AppRoutes" -A 20 lib/core/constants/app_constants.dart` |
| Supabase uç nokta envanteri | `grep -rn "\.from(\|\.rpc(\|\.stream(\|\.insert(\|\.update(\|\.delete(" lib` |
| Kullanılmayan shared widget | `grep -rn "LoadingWidget(\|CustomButton(\|CustomTextField(" lib` |
| Ölü bağımlılık | her paket adı için `grep -rn "<paket>" lib` |
| Failures kullanım sayımı | `grep -roh "NetworkFailure\.[a-zA-Z]*\|…" lib --exclude=failures.dart \| sort \| uniq -c` |

## 17. Sesle fatura ekleme (yeni özellik)

- **Akış:** Fatura ekleme sayfasındaki mikrofon FAB'ı → cihaz içi `speech_to_text` ile canlı
  transkript → `voice-invoice` Supabase Edge Function → LLM + veritabanı eşleştirmesi →
  mevcut `InvoiceCubit` formuna uygulama (satış/alım → taraf → ürünler → ödeme türü).
- **Kaydetme:** Ses akışı faturayı otomatik kaydetmez; kullanıcı mevcut kaydet adımını onaylar.
- **Sunucu:** `supabase/functions/voice-invoice/index.ts`; JWT doğrulaması ve tüm sorgularda
  `user_id` filtresi zorunludur. Fiyatlar veritabanından alınır, LLM'den alınmaz.
- **Doküman:** kurulum, secret'lar, istek/yanıt sözleşmesi ve Flutter katmanları için
  [`docs/voice_invoice_feature.md`](voice_invoice_feature.md).
