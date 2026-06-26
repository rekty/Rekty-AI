import 'dart:convert';
import 'package:http/http.dart' as http;

class PollinationsService {
  // Model untuk generate GAMBAR
  static Future<List<String>> getModels() async {
    try {
      final response = await http.get(
        Uri.parse('https://image.pollinations.ai/models'),
      );

      print('IMAGE MODELS STATUS: ${response.statusCode}');
      print('IMAGE MODELS BODY: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<String>.from(data);
      }
    } catch (e) {
      print('IMAGE MODELS ERROR: $e');
    }

    return [];
  }

  // Model untuk CHAT / TEXT — endpoint baru gen.pollinations.ai
  static Future<List<String>> getTextModels({String? apiKey}) async {
    try {
      final uri = Uri.parse('https://gen.pollinations.ai/v1/models');
      final headers = <String, String>{};
      if (apiKey != null) headers['Authorization'] = 'Bearer $apiKey';

      final response = await http.get(uri, headers: headers);

      print('TEXT MODELS STATUS: ${response.statusCode}');
      print('TEXT MODELS BODY: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Response OpenAI-compatible: { "data": [ { "id": "openai", ... } ] }
        if (data is Map && data['data'] is List) {
          final List models = data['data'];
          return models
              .map<String>((item) => item['id']?.toString() ?? '')
              .where((id) => id.isNotEmpty)
              // Filter hanya model text (bukan image/audio/video)
              .where((id) => !_isImageModel(id))
              .toList();
        }

        // Fallback kalau responsenya list langsung
        if (data is List) {
          return data.map<String>((item) {
            if (item is String) return item;
            if (item is Map) return item['id']?.toString() ?? item['name']?.toString() ?? '';
            return '';
          }).where((id) => id.isNotEmpty).toList();
        }
      }
    } catch (e) {
      print('TEXT MODELS ERROR: $e');
    }

    // Fallback statis kalau API gagal
    return [
      'openai',
      'openai-large',
      'openai-reasoning',
      'mistral',
      'mistral-large',
      'gemini',
      'gemini-thinking',
      'deepseek',
      'deepseek-reasoning',
      'llama',
      'llamalight',
      'qwen-coder',
      'qwq',
      'claude-hybridspace',
      'mercury',
      'mercury-2',
    ];
  }

  static bool _isImageModel(String id) {
    const imageModels = {'flux', 'turbo', 'sana', 'stable-diffusion', 'gpt-image'};
    return imageModels.contains(id.toLowerCase());
  }

  // Stream chat ke Pollinations — endpoint baru gen.pollinations.ai
  static Stream<String> streamChat({
    required String model,
    required List<Map<String, String>> messages,
    String? apiKey,
  }) async* {
    try {
      final body = jsonEncode({
        'model': model,
        'messages': messages,
        'stream': true,
      });

      final request = http.Request(
        'POST',
        Uri.parse('https://gen.pollinations.ai/v1/chat/completions'),
      );

      request.headers['Content-Type'] = 'application/json';
      if (apiKey != null) {
        request.headers['Authorization'] = 'Bearer $apiKey';
      }
      request.body = body;

      print('STREAM MODEL: $model');

      final streamedResponse = await request.send();

      print('STREAM STATUS: ${streamedResponse.statusCode}');

      if (streamedResponse.statusCode != 200) {
        yield '[Error: HTTP ${streamedResponse.statusCode}]';
        return;
      }

      await for (final chunk in streamedResponse.stream.transform(utf8.decoder)) {
        // Server-Sent Events format: "data: {...}\n\n"
        final lines = chunk.split('\n');
        for (final line in lines) {
          if (line.startsWith('data: ')) {
            final jsonStr = line.substring(6).trim();
            if (jsonStr == '[DONE]') return;
            try {
              final json = jsonDecode(jsonStr);
              final content = json['choices']?[0]?['delta']?['content'];
              if (content != null && content is String && content.isNotEmpty) {
                yield content;
              }
            } catch (_) {
              // skip malformed chunk
            }
          }
        }
      }
    } catch (e) {
      print('STREAM ERROR: $e');
      yield '[Error: $e]';
    }
  }
}
