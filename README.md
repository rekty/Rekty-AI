# Rekty AI

<p align="center">
  <img src="https://image.pollinations.ai/prompt/pollinations%20ai%20logo%20text%20white%20minimal%20clean?width=360&height=100&model=flux&nologo=true" alt="pollinations.ai Logo Text White" height="60"/>
</p>

<p align="center">
  <a href="https://pollinations.ai">
    <img src="https://pollinations.ai/p/built%20with%20pollinations%20badge%20white?width=200&height=48&model=flux&nologo=true" alt="Built With pollinations.ai" height="40"/>
  </a>
</p>

<p align="center">
  Aplikasi chat AI + generate/edit gambar berbasis <a href="https://pollinations.ai">Pollinations.ai</a>, dibangun dengan Flutter.
</p>

---

**Konfigurasi project ini disesuaikan untuk:**
- Flutter 3.2.8
- Java 17
- Android minSdk 26 (Android 8.0+)
- Gradle 7.6.3 + AGP 7.4.2 + Kotlin 1.8.22

## ⚠️ WAJIB DIBACA SEBELUM BUILD

Project ini berisi **source code lengkap**, tapi untuk jadi file `.apk` yang jalan,
kamu **harus** menjalankan beberapa langkah build di komputer kamu sendiri
(Flutter SDK tidak bisa dijalankan dari chat ini).

---

## 🌸 Powered by Pollinations.ai

Rekty AI menggunakan **[Pollinations.ai](https://pollinations.ai/)** sebagai backbone untuk:
- **Generasi gambar** — model Flux, Turbo, dan lainnya
- **Chat AI** — OpenAI, Gemini, DeepSeek, Mistral, Claude, dan banyak lagi
- **Vision** — kirim gambar ke AI untuk dianalisis

Pollinations.ai menyediakan API gambar dan teks gratis berbasis model open-source terkini.
Cek dokumentasi API di: https://pollinations.ai/docs

| Logo | Badge |
|------|-------|
| `pollinations.ai Logo White` | `Built With pollinations.ai` |
| Digunakan di splash/about screen | Digunakan di README & in-app |

> Gunakan aset logo resmi dari: https://pollinations.ai/about#logos

---

## Langkah 1 — Install Prasyarat

Pastikan sudah terinstall di komputer kamu:

1. **Flutter SDK 3.2.8** — https://docs.flutter.dev/get-started/install
   (kalau kamu pakai `flutter version` bisa cek dengan `flutter --version`)
2. **Java 17 (JDK 17)** — pastikan `JAVA_HOME` mengarah ke JDK 17, bukan versi lain
3. **Android Studio** dengan **Android SDK Platform 34** dan **minimal API 26** terinstall via SDK Manager
4. Jalankan `flutter doctor` di terminal, pastikan semua centang hijau (minimal Flutter & Android toolchain).

Project ini sudah dikonfigurasi pakai **Gradle 7.6.3 + AGP 7.4.2 + Kotlin 1.8.22** —
kombinasi ini stabil dengan Java 17 dan cocok dengan struktur project Flutter 3.2.8
(yang masih memakai format `apply plugin` lama, bukan `plugins{}` block modern
yang baru ada sejak Flutter 3.16).

## Langkah 2 — Isi API Key Pollinations

Buka file:
```
lib/services/api_key_service.dart
```

Atau, lebih mudah: langsung isi API key di dalam app via **Settings → Konfigurasi API**.

- **Pollinations API Key** — dapatkan di https://pollinations.ai
- **Pollinations App Key** (opsional, dimulai dengan `PK_`) — untuk fitur premium

> Tanpa API key pun, app sudah bisa berjalan dengan model gratis bawaan Pollinations.ai.

## Langkah 3 — Isi `local.properties`

Buka file:
```
android/local.properties
```
Ganti `ISI_PATH_ANDROID_SDK_KAMU` dan `ISI_PATH_FLUTTER_SDK_KAMU` dengan path asli di komputer kamu.

Contoh macOS:
```properties
sdk.dir=/Users/namakamu/Library/Android/sdk
flutter.sdk=/Users/namakamu/flutter
```

Contoh Windows:
```properties
sdk.dir=C\:\\Users\\NamaKamu\\AppData\\Local\\Android\\sdk
flutter.sdk=C:\Users\Administrator\develop\flutter\bin\flutter
```

> Tips: kalau bingung lokasi Flutter SDK kamu, jalankan `which flutter` (macOS/Linux)
> atau `where flutter` (Windows) di terminal.

## Langkah 4 — Install Dependencies & Generate Database Code

Buka terminal di folder root project ini, lalu jalankan:

```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

Perintah kedua **wajib** dijalankan — ini akan generate file `*.g.dart`
(seperti `chat_message.g.dart` dan `image_history.g.dart`) yang dibutuhkan Isar
dan **tidak disertakan** dalam zip ini karena memang harus digenerate sesuai
environment kamu.

> **Catatan jujur soal versi package**: `pubspec.yaml` di project ini sudah
> diisi dengan versi-versi package yang seharusnya compatible dengan Flutter
> 3.2.8, tapi karena aku tidak punya akses Flutter SDK langsung untuk
> menjalankan `flutter pub get` secara nyata, ada kemungkinan kecil
> `flutter pub get` menampilkan **version solving failed**. Kalau itu terjadi:
> baca pesan errornya (biasanya menyebutkan package mana yang konflik dan
> versi berapa yang dibutuhkan), lalu turunkan/naikkan versi package
> tersebut di `pubspec.yaml` sesuai saran error tersebut.

## Langkah 5 — Build APK

Untuk testing cepat (debug):
```bash
flutter run
```

Untuk build APK final (release):
```bash
flutter build apk --release
```

File hasil build ada di:
```
build/app/outputs/flutter-apk/app-release.apk
```

Tinggal install file itu ke HP Android kamu (aktifkan "Install dari sumber tidak dikenal" di Settings HP).

---

## Struktur Project

```
lib/
├── main.dart                    # Entry point, setup tema dark & init database
├── models/
│   ├── chat_message.dart        # Model pesan chat (Isar collection)
│   └── image_history.dart       # Model riwayat gambar (Isar collection)
├── services/
│   ├── api_key_service.dart     # Simpan & ambil API key (secure storage)
│   ├── pollinations_service.dart# Komunikasi dengan Pollinations.ai API
│   ├── pollinations_models.dart # Daftar model image & chat Pollinations
│   ├── isar_service.dart        # CRUD database lokal
│   ├── image_service.dart       # Pick, save, & hapus file gambar
│   └── language_service.dart    # Preferensi bahasa
├── screens/
│   ├── chat_screen.dart         # Halaman utama chat
│   ├── history_screen.dart      # Galeri riwayat gambar
│   └── settings_screen.dart     # Pengaturan & hapus data
└── widgets/
    ├── chat_bubble.dart         # Bubble chat user/AI
    └── loading_widget.dart      # Animasi loading saat AI memproses
```

## Fitur

- ✅ Chat teks dengan berbagai model AI (via Pollinations.ai)
- ✅ Kirim gambar untuk ditanya (vision)
- ✅ Generate gambar baru dari prompt teks
- ✅ Edit gambar yang sudah ada dengan instruksi teks
- ✅ Riwayat chat tersimpan lokal (Isar database)
- ✅ Galeri riwayat gambar dengan favorite & delete
- ✅ Pilihan aspect ratio gambar (Square, Portrait, Widescreen, dll)
- ✅ Multi-bahasa (Indonesia, English, dan 13 bahasa lainnya)
- ✅ Dark theme modern hitam

## ⚠️ Catatan Penting: Model Berubah Seiring Waktu

Pollinations.ai sering menambah atau meng-update model. Kalau app mendadak error
"model not found", ganti model di **Settings → Konfigurasi API** → pilih model
yang tersedia. Cek daftar model terbaru di:
- https://pollinations.ai/docs
- https://pollinations.ai/models

## Troubleshooting Umum

| Masalah | Solusi |
|---|---|
| `flutter.sdk not set in local.properties` | Isi ulang `android/local.properties` sesuai Langkah 3 |
| Error `ChatMessageSchema` not found | Jalankan ulang `build_runner` (Langkah 4) |
| Build gagal di Gradle | Pastikan `compileSdk`/`targetSdk` 34 sudah terinstall di Android Studio → SDK Manager |
| Gambar gagal di-generate | Pastikan API key valid & model yang dipilih masih tersedia di Pollinations.ai |
| App force-close saat dibuka | Jalankan `flutter run` (bukan langsung apk) dulu untuk lihat error log detail |
| `Unsupported class file major version` | JAVA_HOME kamu mengarah ke Java versi lain (bukan 17). Cek dengan `java -version` dan `echo $JAVA_HOME` |
| Error terkait `kotlin-stdlib` versi | Jalankan `flutter clean` lalu `flutter pub get` ulang, baru build lagi |
| Gradle gagal download/timeout | Cek koneksi internet, atau download manual Gradle 7.6.3 dari https://services.gradle.org/distributions/gradle-7.6.3-all.zip dan extract ke `~/.gradle/wrapper/dists/` |
| `minSdkVersion` conflict dengan salah satu plugin | Beberapa plugin pihak ketiga mensyaratkan minSdk lebih tinggi dari 26 — cek error log untuk nama plugin yang konflik |

---

## Kontak

Developer: **Rekty Anjany**
Email: rekty.anjany@gmail.com

---

<p align="center">
  <a href="https://pollinations.ai">
    <img src="https://image.pollinations.ai/prompt/pollinations%20ai%20logo%20white%20flower%20minimal?width=120&height=120&model=flux&nologo=true" alt="pollinations.ai Logo White" height="48"/>
  </a>
  <br/>
  <sub>Powered by <a href="https://pollinations.ai">pollinations.ai</a></sub>
</p>

## Screenshots

| Chat | Image Generator |
|------|-----------------|
| ![](screenshots/chat.png) | ![](screenshots/image.png) |

| History | Settings |
|---------|----------|
| ![](screenshots/history.png) | ![](screenshots/settings.png) |