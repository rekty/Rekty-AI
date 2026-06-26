import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Global notifier — semua widget yang listen ke ini akan otomatis
/// rebuild saat user mengganti bahasa dari Settings.
final languageNotifier = ValueNotifier<String>('Indonesia');

class LanguageService {
  static final LanguageService instance = LanguageService._();

  LanguageService._();

  Future<File> _languageFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/rekty_language.txt');
  }

  Future<String?> getLanguage() async {
    try {
      final file = await _languageFile();
      if (!await file.exists()) return null;
      final language = (await file.readAsString()).trim();
      return language.isEmpty ? null : language;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveLanguage(String language) async {
    final file = await _languageFile();
    await file.writeAsString(language.trim(), flush: true);
    // Beritahu semua listener bahwa bahasa berubah
    languageNotifier.value = language;
  }

  Future<void> clearLanguage() async {
    final file = await _languageFile();
    if (await file.exists()) await file.delete();
    languageNotifier.value = 'Indonesia';
  }

  /// Panggil sekali di main.dart setelah DB init,
  /// supaya notifier sudah berisi bahasa yang tersimpan.
  Future<void> initNotifier() async {
    final saved = await getLanguage();
    if (saved != null) languageNotifier.value = saved;
  }
}
