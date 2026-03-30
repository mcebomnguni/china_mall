# China Mall — Setup & Fix Guide
### Fixing the "Gradle daemon disappeared" crash

---

## The Problem

The Gradle daemon is crashing because it is configured to use **8GB of RAM** (`-Xmx8G`), 
which causes a JVM crash on most machines.

The fix is already included in this project: `android/gradle.properties` now sets `-Xmx2048m` (2GB) 
and disables the daemon entirely for reliability.

---

## Step 1 — Run these commands IN ORDER

Open Command Prompt **as Administrator**, navigate to the project folder, then run:

```cmd
cd C:\Users\twofa\Downloads\china_mall_flutter (4)\china_mall

:: Step 1: Kill any running Java/Gradle processes
taskkill /F /IM java.exe 2>nul

:: Step 2: Delete Gradle cache (fixes corrupted daemon)
rmdir /s /q %USERPROFILE%\.gradle

:: Step 3: Clean Flutter build
flutter clean

:: Step 4: Get packages
flutter pub get

:: Step 5: Run on your phone (V2434 was detected)
flutter run
```

---

## Step 2 — If Android still crashes, run on Chrome instead

```cmd
flutter run -d chrome
```

Chrome compiles much faster (30 seconds vs 5+ minutes) and doesn't need Gradle at all.
Use Chrome to verify the app works, then build for Android.

---

## Step 3 — Android-specific fixes

### Fix: "Build failed with an exception" / JVM crash

The `android/gradle.properties` file in this project is pre-configured with:
- `org.gradle.jvmargs=-Xmx2048m` (2GB instead of the crashing 8GB)
- `org.gradle.daemon=false` (no background daemon = no crashes)

After `flutter create .` regenerates the android folder, **copy our gradle.properties back**:

```
android/gradle.properties  ← use the one from this project
```

### Fix: NDK version mismatch

The `android/app/build.gradle.kts` pins NDK to `27.0.12077973`.
If you see an NDK error, run:

```cmd
flutter pub get
flutter run --verbose
```

### Fix: "Android v1 embedding" error

Run `flutter create .` then `flutter pub get`. This regenerates the Kotlin MainActivity.

---

## Step 4 — Verify your setup

```cmd
flutter doctor -v
```

You should see checkmarks (✓) for:
- Flutter
- Android toolchain
- Android Studio
- Connected device

---

## Base URL for API

Edit `lib/core/api/api_service.dart`:

```dart
// For Android emulator:
static const String _androidBase = 'http://10.0.2.2:8000';

// For Chrome / web testing:  
static const String _iosBase = 'http://localhost:8000';

// For physical Android phone (same WiFi as your PC):
// Find your PC's IP with: ipconfig
// Then set: static const String _androidBase = 'http://192.168.x.x:8000';
```

---

## Django Backend — Enable CORS for Chrome testing

In your Django `settings.py` add:

```python
INSTALLED_APPS = [
    ...
    'corsheaders',
]

MIDDLEWARE = [
    'corsheaders.middleware.CorsMiddleware',  # ← MUST be first
    'django.middleware.common.CommonMiddleware',
    ...
]

CORS_ALLOW_ALL_ORIGINS = True  # For development only
```

Install corsheaders:
```cmd
pip install django-cors-headers
```

---

## Quick Reference

| Command | Purpose |
|---------|---------|
| `flutter run -d chrome` | Fastest — no Gradle needed |
| `flutter run` | Android phone/emulator |
| `flutter run -d windows` | Windows desktop |
| `flutter clean && flutter pub get` | Reset after errors |
| `taskkill /F /IM java.exe` | Kill stuck Gradle |
| `rmdir /s /q %USERPROFILE%\.gradle` | Clear Gradle cache |

---

## Demo Login Credentials

| Role | Username | Password |
|------|----------|---------- |
| Buyer | buyer_demo | demo1234 |
| Vendor | vendor_demo | demo1234 |
| Staff | staff_demo | demo1234 |
| Admin | admin | admin123 |
| Courier | courier_demo | demo1234 |

Start Django backend first:
```cmd
cd C:\Users\twofa\Downloads\chinamall_django\chinamall
venv\Scripts\activate
python manage.py runserver 0.0.0.0:8000
```
