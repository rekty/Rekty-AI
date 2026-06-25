import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'api_key_service.dart';
import 'language_service.dart';
import '../models/chat_message.dart';
import '../prompts/chat_system_prompt.dart';
import '../prompts/image_director_system_prompt.dart';
import '../config/ai_config.dart';
import '../config/pollinations_config.dart';

class GeminiConfig {
  // URL Cloudflare Workers untuk ambil app key secara aman dari backend
  static const String configUrl =
      'https://rektyconfigirma-aurel94workersdev.irma-aurel94.workers.dev';
}

class GeminiResult {
  final bool success;
  final String? text;
  final Uint8List? imageBytes;
  final String? errorMessage;

  GeminiResult({
    this.success = true,
    this.text,
    this.imageBytes,
    this.errorMessage,
  });

  factory GeminiResult.error(String message) {
    return GeminiResult(success: false, errorMessage: message);
  }
}

// ── Helper: konversi aspect ratio ke width/height ──────────────────────────
Map<String, int> _aspectRatioToSize(String aspectRatio) {
  switch (aspectRatio) {
    case '3:4 Portrait':
      return {'width': 1024, 'height': 1365};
    case '2:3 Portrait':
      return {'width': 1024, 'height': 1536};
    case '9:16 Story HD':
      return {'width': 1080, 'height': 1920};
    case '9:16 Mobile':
      return {'width': 830, 'height': 1536};
    case '4:3 Landscape':
      return {'width': 1365, 'height': 1024};
    case '3:2 Landscape':
      return {'width': 1536, 'height': 1024};
    case '16:9 Widescreen':
      return {'width': 1820, 'height': 1024};
    case '1:1 Square':
    default:
      return {'width': 1024, 'height': 1024};
  }
}

class GeminiService {
  void clearHistory() {
    // Chat history dikelola oleh Isar, tidak ada state lokal yang perlu direset.
  }

  // Cache in-memory agar tidak fetch ke server tiap request
  String? _cachedAppKey;

  /// Fetch app key dari Cloudflare Workers (backend).
  /// Key tidak pernah tertanam di APK.
  Future<String?> _fetchAppKeyFromServer() async {
    if (_cachedAppKey != null) return _cachedAppKey;
    try {
      final response = await http.get(
        Uri.parse(GeminiConfig.configUrl),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _cachedAppKey = data['app_key'] as String?;
        print('APP KEY dari server: berhasil diambil');
        return _cachedAppKey;
      }
      print('Fetch server gagal: \${response.statusCode}');
    } catch (e) {
      print('Fetch server error: \$e');
    }
    return null;
  }

  /// Resolve key untuk Pollinations (chat & image).
  /// Prioritas: Pollinations API Key → Pollinations App Key → Server (Cloudflare).
  Future<String> _resolvePollinationsKey() async {
    final apiKey = await ApiKeyService.instance.getPollinationsApiKey();
    if (apiKey != null && apiKey.isNotEmpty) return apiKey;

    final appKey = await ApiKeyService.instance.getPollinationsAppKey();
    if (appKey != null && appKey.isNotEmpty) return appKey;

    final serverKey = await _fetchAppKeyFromServer();
    if (serverKey != null && serverKey.isNotEmpty) return serverKey;

    return '';
  }

  // ── Chat ────────────────────────────────────────────────────────────────

  Future<GeminiResult> sendChatMessage(
    String message, {
    File? imageFile,
    List<ChatMessage> historyMessages = const [],
  }) async {
    final language =
        await LanguageService.instance.getLanguage() ?? 'Indonesia';

    try {
      final apiKey = await _resolvePollinationsKey();

      final selectedModel =
          await ApiKeyService.instance.getChatModel() ?? 'openai';

      // ── Bangun history messages (max 20 pesan terakhir) ───────────────
      final history = _buildHistoryMessages(historyMessages);

      final response = await http.post(
        Uri.parse('https://text.pollinations.ai/openai'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          "model": selectedModel,
          "temperature": AIConfig.chatTemperature,
          "messages": [
            {
              "role": "system",
              "content":
                  "$chatSystemPrompt\n\nSelalu jawab menggunakan bahasa $language.",
            },
            ...history,
            {
              "role": "user",
              "content": message,
            }
          ]
        }),
      );

      print('MODEL DIPAKAI: $selectedModel');
      print('CHAT STATUS: ${response.statusCode}');
      print('CHAT BODY: ${response.body}');

      if (response.statusCode != 200) {
        return GeminiResult.error(
          'Pollinations Error: ${response.statusCode}\n${response.body}',
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final text =
          data['choices'][0]['message']['content']?.toString();

      if (text == null || text.isEmpty) {
        return GeminiResult.error('Pollinations tidak memberikan respons.');
      }

      return GeminiResult(success: true, text: text);
    } catch (e) {
      return GeminiResult.error('Chat gagal: $e');
    }
  }

  // ── Chat Streaming ───────────────────────────────────────────────────────

  /// Stream jawaban AI token demi token via SSE.
  /// Yield setiap potongan teks yang datang dari API.
  /// Caller bisa cancel StreamSubscription untuk Stop Generating.
  Stream<String> sendChatMessageStream(
    String message, {
    File? imageFile,
    List<ChatMessage> historyMessages = const [],
  }) async* {
    final language =
        await LanguageService.instance.getLanguage() ?? 'Indonesia';

    final apiKey = await _resolvePollinationsKey();

    final selectedModel =
        await ApiKeyService.instance.getChatModel() ?? 'openai';

    // ── Bangun history messages (max 20 pesan terakhir) ───────────────
    final history = _buildHistoryMessages(historyMessages);

    final client = http.Client();

    try {
      final request = http.Request(
        'POST',
        Uri.parse('https://text.pollinations.ai/openai'),
      );

      request.headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
        'Accept': 'text/event-stream',
      });

      request.body = jsonEncode({
        'model': selectedModel,
        'temperature': AIConfig.chatTemperature,
        'stream': true,
        'messages': [
          {
            'role': 'system',
            'content':
                '$chatSystemPrompt\n\nSelalu jawab menggunakan bahasa $language.',
          },
          ...history,
          {
            'role': 'user',
            'content': message,
          },
        ],
      });

      print('STREAM MODEL: $selectedModel');

      final streamedResponse = await client.send(request);

      print('STREAM STATUS: ${streamedResponse.statusCode}');

      if (streamedResponse.statusCode != 200) {
        final body = await streamedResponse.stream.bytesToString();
        yield '\n⚠️ Error ${streamedResponse.statusCode}: $body';
        return;
      }

      // SSE parsing: setiap baris format "data: {...}" atau "data: [DONE]"
      final lineStream = streamedResponse.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final line in lineStream) {
        if (line.isEmpty || line == 'data: [DONE]') continue;
        if (!line.startsWith('data: ')) continue;

        final jsonStr = line.substring(6).trim();

        try {
          final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;
          final choices = parsed['choices'] as List?;
          if (choices == null || choices.isEmpty) continue;

          final delta = choices.first['delta'] as Map<String, dynamic>?;
          final content = delta?['content'] as String?;

          if (content != null && content.isNotEmpty) {
            yield content;
          }
        } catch (_) {
          // skip malformed SSE chunk
        }
      }
    } catch (e) {
      yield '\n⚠️ ${_parseError(e)}';
    } finally {
      client.close();
    }
  }

  // ── Generate Gambar ─────────────────────────────────────────────────────

  /// Konversi list ChatMessage menjadi format messages untuk API.
  /// Hanya ambil pesan text (bukan gambar), max 20 pesan terakhir,
  /// dan skip pesan yang teks-nya kosong atau error.
  List<Map<String, String>> _buildHistoryMessages(
    List<ChatMessage> messages,
  ) {
    final filtered = messages
        .where((m) =>
            m.text.isNotEmpty &&
            m.status != MessageStatus.error &&
            (m.type == MessageType.text || m.type == MessageType.textWithImage))
        .toList();

    // Ambil max 20 pesan terakhir (10 pasang user-ai)
    final recent = filtered.length > 20
        ? filtered.sublist(filtered.length - 20)
        : filtered;

    return recent.map((m) {
      final role = m.role == MessageRole.user ? 'user' : 'assistant';
      return {'role': role, 'content': m.text};
    }).toList();
  }

  /// Enhance prompt user via Pollinations text API menggunakan imageDirectorSystemPrompt.
  /// Jika gagal, kembalikan prompt asli agar generate tetap berjalan.
  Future<String> _enhancePromptWithDirector(
    String userPrompt,
    String? apiKey,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('https://text.pollinations.ai/openai'),
        headers: {
          'Content-Type': 'application/json',
          if (apiKey != null && apiKey.isNotEmpty)
            'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'openai',
          'messages': [
            {
              'role': 'system',
              'content': imageDirectorSystemPrompt,
            },
            {
              'role': 'user',
              'content': userPrompt,
            },
          ],
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final enhanced =
            data['choices']?[0]?['message']?['content']?.toString().trim();
        if (enhanced != null && enhanced.isNotEmpty) {
          print('ENHANCED PROMPT: $enhanced');
          return enhanced;
        }
      }
      print('ENHANCE FAILED (${response.statusCode}), pakai prompt asli.');
    } catch (e) {
      print('ENHANCE ERROR: $e, pakai prompt asli.');
    }
    return userPrompt;
  }

  Future<GeminiResult> generateImage(String prompt) async {
    try {
      // Resolve key: API Key → App Key → defaultAppKey
      final resolvedKey = await _resolvePollinationsKey();

      // App Key (PK_...) tetap diambil khusus untuk token image API
      final appKey = await ApiKeyService.instance.getPollinationsAppKey();

      final selectedModel =
          await ApiKeyService.instance.getImageModel() ?? 'flux';

      // ── Ambil aspect ratio dari storage dan konversi ke ukuran piksel ──
      final aspectRatio =
          await ApiKeyService.instance.getAspectRatio() ?? '1:1 Square';
      final size = _aspectRatioToSize(aspectRatio);
      final width = size['width']!;
      final height = size['height']!;

      print('================================');
      print('ASPECT RATIO: $aspectRatio');
      print('SIZE: ${width}x$height');
      print('MODEL: $selectedModel');
      print(
        'RESOLVED KEY: '
        '${resolvedKey.substring(0, resolvedKey.length.clamp(0, 12))}',
      );
      print(
        'POLLINATIONS APP KEY: '
        '${appKey == null ? "NULL" : appKey.substring(0, appKey.length.clamp(0, 12))}',
      );
      print('================================');

      // ── Enhance prompt via Image Director ────────────────────────────
      final enhancedPrompt = await _enhancePromptWithDirector(
        prompt,
        resolvedKey,
      );

      // ── Mode Auto: coba beberapa model secara berurutan ──────────────
      if (selectedModel == 'auto') {
        const autoModels = ['flux', 'gptimage', 'seedream', 'kontext'];

        for (final model in autoModels) {
          print('================================');
          print('AUTO TRY MODEL: $model');
          print('================================');

          try {
            final result = await _fetchPollinationsImage(
              prompt: enhancedPrompt,
              model: model,
              width: width,
              height: height,
              apiKey: resolvedKey,
              appKey: appKey ?? resolvedKey,
            );
            if (result != null) return result;
          } catch (e) {
            print('AUTO ERROR ($model): $e');
          }
        }

        return GeminiResult.error(
          'Semua model Auto gagal menghasilkan gambar.',
        );
      }

      // ── Mode model tunggal ────────────────────────────────────────────
      final result = await _fetchPollinationsImage(
        prompt: enhancedPrompt,
        model: selectedModel,
        width: width,
        height: height,
        apiKey: resolvedKey,
        appKey: appKey ?? resolvedKey,
      );

      if (result != null) return result;

      return GeminiResult.error(
        'Gagal menghasilkan gambar dengan model "$selectedModel".',
      );
    } catch (e) {
      return GeminiResult.error('Generate gambar gagal: $e');
    }
  }

  /// Kirim request ke Pollinations image endpoint.
  /// Kembalikan [GeminiResult] jika berhasil (status 200), null jika gagal.
  Future<GeminiResult?> _fetchPollinationsImage({
    required String prompt,
    required String model,
    required int width,
    required int height,
    String? apiKey,
    String? appKey,  // App Key (PK_...) untuk token Pollinations
  }) async {
    // App Key dipakai sebagai 'token', fallback ke API Key jika App Key kosong
    final tokenKey = (appKey != null && appKey.isNotEmpty) ? appKey : apiKey;

    // Bangun query parameters secara eksplisit agar mudah dibaca & diubah.
    final params = <String, String>{
      'model': model,
      'width': '$width',
      'height': '$height',
      'nologo': PollinationsConfig.noLogo.toString(),
      'enhance': PollinationsConfig.enhance.toString(),
      'safe': PollinationsConfig.safe.toString(),
    };

    if (tokenKey != null && tokenKey.isNotEmpty) {
      params['token'] = tokenKey; // App Key (PK_...) sebagai token
    }

    final uri = Uri.https(
      'image.pollinations.ai',
      '/prompt/${Uri.encodeComponent(prompt)}',
      params,
    );

    print('================================');
    print('URL: $uri');
    print('TOKEN: ${tokenKey == null ? "NULL" : tokenKey.substring(0, tokenKey.length.clamp(0, 12))}');
    print('================================');

    final response = await http.get(
      uri,
      headers: {
        'Accept': 'image/*',
        if (tokenKey != null && tokenKey.isNotEmpty)
          'Authorization': 'Bearer $tokenKey',
      },
    ).timeout(const Duration(seconds: 90));

    print('STATUS ($model): ${response.statusCode}');

    if (response.statusCode == 200) {
      // Validasi bahwa yang diterima memang bytes gambar, bukan JSON error
      final contentType =
          response.headers['content-type'] ?? '';
      if (!contentType.startsWith('image/')) {
        print('CONTENT TYPE bukan gambar: $contentType');
        print('BODY: ${response.body}');
        return null;
      }
      return GeminiResult(
        success: true,
        imageBytes: response.bodyBytes,
      );
    }

    print('BODY ($model): ${response.body}');
    return null;
  }


  // ── Model yang support img2img (edit gambar) ────────────────────────────
  static const _img2imgModels = ['kontext', 'gptimage'];

  /// Edit gambar via Pollinations img2img.
  /// Model kontext / gptimage → kirim gambar + instruksi ke Pollinations.
  /// Model lain → fallback ke generateImage biasa (gambar diabaikan).
  Future<GeminiResult> editImage(File sourceImage, String instruction) async {
    try {
      final resolvedKey = await _resolvePollinationsKey();
      final appKey = await ApiKeyService.instance.getPollinationsAppKey();
      final tokenKey =
          (appKey != null && appKey.isNotEmpty) ? appKey : resolvedKey;

      final selectedModel =
          await ApiKeyService.instance.getImageModel() ?? 'kontext';

      final aspectRatio =
          await ApiKeyService.instance.getAspectRatio() ?? '1:1 Square';
      final size = _aspectRatioToSize(aspectRatio);
      final width = size['width']!;
      final height = size['height']!;

      // ── Enhance prompt via Image Director ──────────────────────────────
      final enhancedPrompt = await _enhancePromptWithDirector(
        instruction,
        resolvedKey,
      );

      // Model yang tidak support img2img → generate biasa, abaikan gambar
      final modelToUse = _img2imgModels.contains(selectedModel)
          ? selectedModel
          : 'kontext'; // default ke kontext untuk edit

      print('================================');
      print('EDIT IMAGE MODEL: $modelToUse');
      print('SIZE: ${width}x$height');
      print('================================');

      final bytes = await sourceImage.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Kirim via POST multipart ke Pollinations
      final uri = Uri.parse(
        'https://image.pollinations.ai/prompt/${Uri.encodeComponent(enhancedPrompt)}',
      );

      final params = <String, String>{
        'model': modelToUse,
        'width': '$width',
        'height': '$height',
        'nologo': PollinationsConfig.noLogo.toString(),
        'safe': PollinationsConfig.safe.toString(),
        if (tokenKey.isNotEmpty) 'token': tokenKey,
      };

      final fullUri = uri.replace(queryParameters: params);

      final request = http.MultipartRequest('POST', fullUri);

      if (tokenKey.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $tokenKey';
      }

      // Kirim gambar sebagai field 'image' dalam base64
      request.fields['image'] = base64Image;

      print('EDIT REQUEST URL: $fullUri');

      final streamedResponse =
          await request.send().timeout(const Duration(seconds: 120));
      final response = await http.Response.fromStream(streamedResponse);

      print('EDIT STATUS: ${response.statusCode}');

      if (response.statusCode == 200) {
        final contentType = response.headers['content-type'] ?? '';
        if (!contentType.startsWith('image/')) {
          print('CONTENT TYPE bukan gambar: $contentType');
          print('BODY: ${response.body}');
          return GeminiResult.error(
            'Gagal edit gambar. Coba ubah instruksi atau model.',
          );
        }
        return GeminiResult(success: true, imageBytes: response.bodyBytes);
      }

      print('EDIT ERROR BODY: ${response.body}');
      return GeminiResult.error(
        'Gagal edit gambar (${response.statusCode}). Coba lagi.',
      );
    } catch (e) {
      return GeminiResult.error(_parseError(e));
    }
  }

  String _parseError(Object e) {
    final msg = e.toString();

    if (msg.contains('high demand')) {
      return 'Server AI sedang ramai. Coba lagi beberapa menit.';
    }
    if (msg.contains('API_KEY_INVALID') ||
        msg.contains('API key not valid')) {
      return 'API key tidak valid.';
    }
    if (msg.contains('SocketException') || msg.contains('Network')) {
      return 'Tidak ada koneksi internet.';
    }
    if (msg.contains('RESOURCE_EXHAUSTED') ||
        msg.contains('quota')) {
      return 'Kuota API sudah habis untuk saat ini.';
    }
    if (msg.contains('SAFETY')) {
      return 'Permintaan diblokir oleh filter keamanan.';
    }
    if (msg.contains('TimeoutException')) {
      return 'Koneksi timeout. Coba lagi sebentar.';
    }

    return 'Terjadi kesalahan. Silakan coba lagi.';
  }
}
