# China Mall — Flutter App (Complete)
### iOS & Android · Multi-vendor marketplace · 47 Dart files · ~11,000 lines

## Quick Start

```bash
cd china_mall && flutter pub get
flutter run
```

Tap any demo credential row on the login screen to auto-fill.

## Demo Credentials

| Role    | Username     | Password  |
|---------|--------------|-----------|
| Buyer   | buyer_demo   | demo1234  |
| Vendor  | vendor_demo  | demo1234  |
| Staff   | staff_demo   | demo1234  |
| Admin   | admin        | admin123  |
| Courier | courier_demo | demo1234  |

## Base URL (lib/core/api/api_service.dart)

- Android emulator: `http://10.0.2.2:8000`
- iOS simulator: `http://127.0.0.1:8000`
- Physical device: your PC's WiFi IP (run `ipconfig` on Windows)

## File Structure (47 Dart files)

```
lib/
├── main.dart                          # Entry: 5 providers registered
├── main_shell.dart                    # Role-aware bottom nav
├── core/
│   ├── api/api_service.dart           # ALL API endpoints
│   ├── constants/app_constants.dart
│   ├── providers/app_config_provider.dart
│   ├── router/app_router.dart         # 30+ routes, auth guard
│   ├── theme/app_theme.dart           # China red, Satoshi font
│   ├── utils/app_utils.dart           # Currency, dates, validation
│   └── widgets/
│       ├── shared_widgets.dart        # 10+ reusable widgets
│       └── write_review_sheet.dart    # Star rating bottom sheet
└── features/
    ├── auth/      login, register, splash + AuthProvider + models
    ├── home/      home screen, buyer dashboard
    ├── products/  list, detail, search + ProductsProvider + models
    ├── stores/    list, detail
    ├── cart/      cart screen + CartProvider
    ├── orders/    list, detail, tracking, returns, disputes + provider
    ├── payments/  checkout, payment, history
    ├── profile/   profile, edit, password, notifications
    ├── vendor/    dashboard, products, add, orders, payouts
    ├── courier/   dashboard with online toggle + job stepper
    └── admin/     platform stats, approve stores/products
```

## Screens by Role

Buyer: Home · Dashboard · Search · Products · Product Detail · Stores ·
Store Detail · Cart · Checkout · Payment · Orders · Order Detail ·
Tracking · Returns · Disputes · Payment History · Profile · Edit Profile ·
Change Password · Notifications (20 screens)

Vendor: + Dashboard · My Products · Add Product · Store Orders · Payouts
Courier: + Courier Dashboard (online toggle, job status stepper)
Admin:   + Admin Dashboard (stats, store & product approvals)

## Design

- Color: China red #E63329 + Gold #FFB300
- Font: Satoshi (900/700/600/500)
- Cards: 16px radius, 1px border
- Buttons: 14px radius, 52px height

## Payment Testing

Use token `"test_token"` — always succeeds in test mode.

## Build

```bash
flutter build apk --release          # Android
flutter build appbundle --release    # Play Store
flutter build ios --release          # iOS (macOS + Xcode required)
```
