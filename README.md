# Cinelog Mobile App (Flutter)

Aplikasi Mobile Flutter untuk melacak film & serial TV, memberi rating, dan menyimpan tontonan ke server VPS pribadi.

---

## Prasyarat
- **Flutter SDK**: v3.0.0 atau lebih baru
- **Android Studio / Xcode** (untuk Emulator/Simulator)

---

## Konfigurasi Environment & API URL

Lokasi konfigurasi API URL ada di file `lib/services/api_service.dart`:

```dart
class ApiService {
  // Untuk Android Emulator -> Host Windows/WSL:
  static String baseUrl = 'http://10.0.2.2:3000';

  // Untuk Device Fisik di Jaringan WiFi sama:
  // static String baseUrl = 'http://192.168.1.X:3000';

  // Untuk Produksi VPS:
  // static String baseUrl = 'https://api.domainkamu.com';
}
```

---

## Jalankan di Lokal (Development)

```bash
# 1. Unduh dependensi Flutter
flutter pub get

# 2. Jalankan aplikasi di emulator / device
flutter run
```

---

## Build APK / Bundle Produksi (Release)

### 1. Build APK Standalone
```bash
flutter build apk --release
```
File APK rilis akan dihasilkan di:
`build/app/outputs/flutter-apk/app-release.apk`

### 2. Build Android App Bundle (AAB untuk Google Play Store)
```bash
flutter build appbundle --release
```

---

## 📱 Fitur Utama Aplikasi Mobile
- 🔍 **Multi-Search**: Cari Film dan TV Series langsung dari TMDB.
- ⭐ **Personal Rating & Review**: Beri nilai 0.0 - 10.0 dan catatan pribadi.
- 📌 **Status Watchlist**: Filter tontonan (*Watching*, *Completed*, *Plan to Watch*, *Dropped*).
- ☁️ **VPS Asset Integration**: Menampilkan gambar poster dari VPS local storage.
- 🔑 **Auth State**: Menyimpan token JWT secara aman di perangkat.
