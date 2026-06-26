# Patch yang perlu dilakukan manual

## 1. main.dart — Inisialisasi languageNotifier

Tambahkan pemanggilan `initNotifier()` setelah DB init:

```dart
// Di dalam fungsi main() atau initState root widget:
await IsarService.instance.init();
await LanguageService.instance.initNotifier(); // ← TAMBAHKAN INI
```

Pastikan import language_service.dart juga ada di main.dart:
```dart
import 'services/language_service.dart';
```

---

## 2. chat_screen.dart — Ikut berganti bahasa secara otomatis

Ganti cara load bahasa di ChatScreen dari "load sekali" menjadi "listen ke notifier".

### Di bagian atas state class, ganti:
```dart
String _selectedLanguage = 'Indonesia';
```
Tetap sama.

### Di initState(), ganti:
```dart
// SEBELUM (load sekali saja):
_loadLanguage();

// SESUDAH (listen ke perubahan):
_selectedLanguage = languageNotifier.value;
languageNotifier.addListener(_onLanguageChanged);
```

### Tambahkan method baru:
```dart
void _onLanguageChanged() {
  if (!mounted) return;
  setState(() => _selectedLanguage = languageNotifier.value);
}
```

### Di dispose(), tambahkan:
```dart
languageNotifier.removeListener(_onLanguageChanged);
```

### Hapus method _loadLanguage() yang lama (tidak diperlukan lagi):
```dart
// HAPUS method ini:
Future<void> _loadLanguage() async {
  final language = await LanguageService.instance.getLanguage();
  if (!mounted) return;
  setState(() {
    _selectedLanguage = language ?? 'Indonesia';
  });
}
```

### Tambahkan import di atas chat_screen.dart:
```dart
import '../services/language_service.dart';
```
(jika belum ada)

---

## Cara kerja setelah patch

- User buka Settings → pilih bahasa → `LanguageService.saveLanguage()` dipanggil
- `saveLanguage()` otomatis update `languageNotifier.value`
- Semua screen yang sudah `addListener` (settings_screen + chat_screen) langsung rebuild
- Tidak perlu restart app, tidak perlu package tambahan
