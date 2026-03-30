# STF Capital — Flutter Application

A full-featured cross-platform application (iOS, Android, Web) for STF Capital's financial services platform. Built with Flutter and Firebase.

---

## Technology Stack

| Layer | Technology |
|---|---|
| UI Framework | Flutter 3.x (Dart) |
| State Management | Provider |
| Navigation | GoRouter |
| Backend / Auth | Firebase Auth |
| Database | Cloud Firestore |
| File Storage | Firebase Storage |
| Fonts | Google Fonts (Cormorant Garamond + Montserrat) |

---

## Project Structure

```
lib/
├── main.dart                          # App entry point
├── router.dart                        # GoRouter navigation config
├── theme/
│   └── app_theme.dart                 # Platinum & gold design system
├── models/
│   └── app_models.dart                # All data models + product catalogue
├── services/
│   ├── auth_service.dart              # Auth (login, register, forgot, delete)
│   └── application_service.dart      # Application CRUD + file uploads
├── widgets/
│   └── shared_widgets.dart            # Reusable UI components
└── screens/
    ├── splash_screen.dart
    ├── privacy_policy_screen.dart
    ├── auth/
    │   ├── login_screen.dart
    │   ├── register_screen.dart
    │   └── forgot_screens.dart        # Forgot password + forgot username
    ├── client/
    │   ├── client_dashboard.dart
    │   ├── onboarding_documents_screen.dart
    │   ├── product_selection_screen.dart
    │   ├── application_detail_screen.dart
    │   ├── resubmit_screen.dart
    │   └── profile_screen.dart        # Profile + change password
    └── admin/
        └── admin_dashboard.dart       # Admin dashboard + user management
```

---

## Application Flow

### Client Journey

```
Register → Upload Documents → Select Product Category
        → Select Specific Product → Preview → Submit
        → Dashboard (Pending Review)
        → [If Returned] → Resubmit with corrected docs
        → [If Approved] → Approved status shown
        → [If Declined] → Declined status shown
```

### Admin Journey

```
Login → Admin Dashboard → View all applications
      → Filter/Search applications → Open application
      → Update status (Opened / Pending Outcome / Returned / Approved / Declined)
      → Add admin note and/or return reason
```

### Application Statuses

| Status | Shown to Client As |
|---|---|
| Pending Review | Awaiting review by our team |
| Opened | Your application has been opened |
| Pending Outcome | An outcome is being determined |
| Returned | Action required — see return reason |
| Approved | Application approved |
| Declined | Application declined |

---

## Setup Instructions

### 1. Prerequisites

- Flutter SDK 3.10+ installed: https://docs.flutter.dev/get-started/install
- Dart SDK (included with Flutter)
- Firebase CLI: `npm install -g firebase-tools`
- Xcode (for iOS builds)
- Android Studio (for Android builds)

### 2. Clone and Install

```bash
git clone <your-repo-url>
cd stf_capital
flutter pub get
```

### 3. Firebase Setup

#### 3a. Create Firebase Project

1. Go to https://console.firebase.google.com
2. Create a new project named `stf-capital`
3. Enable **Authentication** → Sign-in method → **Email/Password**
4. Enable **Cloud Firestore** → Start in production mode
5. Enable **Storage** → Start in production mode

#### 3b. Register Apps

**Android:**
- Register app with package name `com.stfcapital.app`
- Download `google-services.json`
- Place in `android/app/google-services.json`

**iOS:**
- Register app with bundle ID `com.stfcapital.app`
- Download `GoogleService-Info.plist`
- Place in `ios/Runner/GoogleService-Info.plist`
- Open `ios/Runner.xcworkspace` in Xcode and add the file to the project

**Web:**
- Register web app
- Copy the Firebase config

#### 3c. Configure Firebase Options

Install FlutterFire CLI:
```bash
dart pub global activate flutterfire_cli
```

Auto-configure for all platforms:
```bash
flutterfire configure --project=stf-capital
```

This generates `lib/firebase_options.dart`. Then update `main.dart`:

```dart
import 'firebase_options.dart';

await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

Remove the manual `FirebaseOptions(...)` block from `main.dart`.

#### 3d. Deploy Firestore Rules

```bash
firebase deploy --only firestore:rules
```

#### 3e. Deploy Storage Rules

```bash
firebase deploy --only storage
```

### 4. Create First Admin User

After registering your first admin account via the app:

1. Go to Firebase Console → Firestore → `users` collection
2. Find the user document by UID
3. Change the `role` field from `"client"` to `"admin"`

The user will be routed to the Admin Dashboard on next login.

### 5. Run the App

```bash
# iOS
flutter run -d ios

# Android
flutter run -d android

# Web
flutter run -d chrome

# All connected devices
flutter run
```

### 6. Build for Production

```bash
# Android APK
flutter build apk --release

# Android App Bundle (for Play Store)
flutter build appbundle --release

# iOS (requires Xcode + Apple Developer account)
flutter build ios --release

# Web
flutter build web --release
```

---

## Products Catalogue

### 1. Insurance Bonds and Guarantees
- Bid Bond
- Advance Payment Guarantee
- Performance Guarantee
- Retention Bond
- Credit Guarantee
- Maintenance Bond

### 2. Financial Advisory Services
- Capital Raise
- Consultancy Services
- Order Financing
- Risk Participation Structured Finance
- Debt Restructuring

### 3. General Insurance Products
- Contractor's All Risk (CAR) Insurance
- Erection All Risk Insurance
- Goods in Transit
- Public Liability Insurance
- Fire Damage Insurance
- Motor Insurance - Third Party Only
- Motor Insurance - Third Party Fire and Theft
- Motor Insurance - Comprehensive
- Agriculture Insurance
- Travel Insurance
- Export Credit Insurance
- Domestic Payments Insurance Policy (DPIP)
- Marine Insurance

---

## Required Registration Documents

1. Company Profile
2. Certificate of Incorporation
3. Articles of Association
4. CR6
5. CR14
6. Tax Clearance
7. Financial Statements or Bank Statements
8. Contract or Purchase Order *(conditional — required when requesting a product)*
9. Tender Documents *(conditional — for bid bonds)*

---

## Design System

### Colours

| Token | Hex | Usage |
|---|---|---|
| `gold` | `#B8860B` | Primary brand |
| `goldLight` | `#D4A017` | Buttons, links |
| `goldBright` | `#E6C84A` | Highlights |
| `platinum` | `#E5E4E2` | Text on dark |
| `darkBg` | `#0D0D0D` | App background |
| `darkSurface` | `#1A1A1A` | Cards |
| `darkSurface2` | `#252525` | Inputs |

### Typography

- **Display / Headings**: Cormorant Garamond (serif, luxury feel)
- **Body / UI**: Montserrat (geometric sans, clarity)

---

## Firestore Data Schema

### `users/{uid}`
```json
{
  "uid": "string",
  "username": "string",
  "email": "string",
  "firstName": "string",
  "lastName": "string",
  "phone": "string",
  "companyName": "string",
  "role": "client | admin",
  "createdAt": "ISO8601",
  "isActive": true
}
```

### `usernames/{username}`
```json
{ "uid": "string" }
```

### `applications/{applicationId}`
```json
{
  "id": "string",
  "clientUid": "string",
  "clientName": "string",
  "clientEmail": "string",
  "companyName": "string",
  "productCategoryId": "string",
  "productCategoryName": "string",
  "selectedProductId": "string",
  "selectedProductName": "string",
  "documents": [
    {
      "name": "string",
      "url": "string",
      "type": "image | document",
      "uploadedAt": "ISO8601"
    }
  ],
  "status": "pending_review | opened | pending_outcome | returned | approved | declined",
  "adminNote": "string | null",
  "returnReason": "string | null",
  "createdAt": "ISO8601",
  "updatedAt": "ISO8601"
}
```

---

## Customisation Notes

- **App name**: Update `android/app/src/main/AndroidManifest.xml` label and iOS `Info.plist` CFBundleDisplayName
- **Package name**: Update `applicationId` in `android/app/build.gradle` and iOS bundle ID in Xcode
- **Logo**: Replace the text-based `StfLogo` widget with your actual logo asset in `widgets/shared_widgets.dart`
- **Contact email**: Update `privacy@stfcapital.co.za` in `privacy_policy_screen.dart`
- **Firebase project**: Replace all Firebase config values in `main.dart` or use `firebase_options.dart`

---

## Dependencies

```yaml
provider: ^6.1.1          # State management
go_router: ^13.2.0         # Navigation
firebase_core: ^2.27.1     # Firebase core
firebase_auth: ^4.17.9     # Authentication
cloud_firestore: ^4.15.9   # Database
firebase_storage: ^11.6.10 # File storage
file_picker: ^6.1.1        # Document upload
google_fonts: ^6.2.1       # Cormorant + Montserrat
shimmer: ^3.0.0            # Loading states
uuid: ^4.3.3               # Unique IDs
url_launcher: ^6.2.5       # Open document URLs
```

---

*STF Capital Application — Built with Flutter*
