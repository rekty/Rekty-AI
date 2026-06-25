import 'dart:io';

import 'package:path_provider/path_provider.dart';


class ApiKeyService {
  static final ApiKeyService instance = ApiKeyService._();

  ApiKeyService._();

  Future<File> _geminiKeyFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/rekty_gemini_api_key.txt');
  }
  Future<File> _pollinationsAppKeyFile() async {
  
  final dir = await getApplicationDocumentsDirectory();
  return File('${dir.path}/rekty_pollinations_app_key.txt');
}

  Future<File> _pollinationsKeyFile() async {
  final dir = await getApplicationDocumentsDirectory();
  return File('${dir.path}/rekty_pollinations_api_key.txt');
}

Future<File> _imageModelFile() async {
  final dir = await getApplicationDocumentsDirectory();
  return File('${dir.path}/rekty_image_model.txt');
}
Future<File> _aspectRatioFile() async {
  final dir = await getApplicationDocumentsDirectory();

  return File(
    '${dir.path}/rekty_aspect_ratio.txt',
  );
}
Future<File> _chatModelFile() async {
  final dir = await getApplicationDocumentsDirectory();
  return File('${dir.path}/rekty_chat_model.txt');
}

  // GEMINI

  Future<String?> getGeminiApiKey() async {
    try {
      final file = await _geminiKeyFile();
      if (!await file.exists()) return null;

      final key = (await file.readAsString()).trim();
      return key.isEmpty ? null : key;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveGeminiApiKey(String apiKey) async {
    final file = await _geminiKeyFile();
    await file.writeAsString(apiKey.trim(), flush: true);
  }

  Future<void> clearGeminiApiKey() async {
    final file = await _geminiKeyFile();

    if (await file.exists()) {
      await file.delete();
    }
  }

  // POLLINATIONS

  Future<String?> getPollinationsApiKey() async {
    try {
      final file = await _pollinationsKeyFile();

      if (!await file.exists()) return null;

      final key = (await file.readAsString()).trim();

      return key.isEmpty ? null : key;
    } catch (_) {
      return null;
    }
  }
Future<String?> getPollinationsAppKey() async {
  try {
    final file = await _pollinationsAppKeyFile();

    if (!await file.exists()) return null;

    final key = (await file.readAsString()).trim();

    return key.isEmpty ? null : key;
  } catch (_) {
    return null;
  }
}
  Future<void> savePollinationsApiKey(String apiKey) async {
  final file = await _pollinationsKeyFile();
  
  await file.writeAsString(
    apiKey.trim(),
    flush: true,
  );
}
Future<void> savePollinationsAppKey(String appKey) async {
  final file = await _pollinationsAppKeyFile();

  await file.writeAsString(
    appKey.trim(),
    flush: true,
  );
}
Future<void> saveImageModel(String model) async {
  final file = await _imageModelFile();

  await file.writeAsString(
    model.trim(),
    flush: true,
  );
}


Future<String?> getImageModel() async {
  try {
    final file = await _imageModelFile();

    if (!await file.exists()) return null;

    final model = (await file.readAsString()).trim();

    return model.isEmpty ? null : model;
  } catch (_) {
    return null;
  }
}
Future<void> saveAspectRatio(String ratio) async {
  final file = await _aspectRatioFile();

  await file.writeAsString(
    ratio.trim(),
    flush: true,
  );
}

Future<String?> getAspectRatio() async {
  try {
    final file = await _aspectRatioFile();

    if (!await file.exists()) return null;

    final ratio = (await file.readAsString()).trim();

    return ratio.isEmpty ? null : ratio;
  } catch (_) {
    return null;
  }
}
Future<void> saveChatModel(String model) async {
  final file = await _chatModelFile();

  await file.writeAsString(
    model.trim(),
    flush: true,
  );
}

Future<String?> getChatModel() async {
  try {
    final file = await _chatModelFile();

    if (!await file.exists()) return null;

    final model = (await file.readAsString()).trim();

    return model.isEmpty ? null : model;
  } catch (_) {
    return null;
  }
}
  Future<void> clearPollinationsApiKey() async {
    final file = await _pollinationsKeyFile();

    if (await file.exists()) {
      await file.delete();
    }
  }

Future<void> clearPollinationsAppKey() async {
  final file = await _pollinationsAppKeyFile();

  if (await file.exists()) {
    await file.delete();
  }
}
}