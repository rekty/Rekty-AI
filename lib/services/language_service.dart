import 'dart:io';

import 'package:path_provider/path_provider.dart';

class LanguageService {
  static final LanguageService instance =
      LanguageService._();

  LanguageService._();

  Future<File> _languageFile() async {
    final dir =
        await getApplicationDocumentsDirectory();

    return File(
      '${dir.path}/rekty_language.txt',
    );
  }

  Future<String?> getLanguage() async {
    try {
      final file = await _languageFile();

      if (!await file.exists()) {
        return null;
      }

      final language =
          (await file.readAsString()).trim();

      return language.isEmpty
          ? null
          : language;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveLanguage(
    String language,
  ) async {
    final file = await _languageFile();

    await file.writeAsString(
      language.trim(),
      flush: true,
    );
  }

  Future<void> clearLanguage() async {
    final file = await _languageFile();

    if (await file.exists()) {
      await file.delete();
    }
  }
}