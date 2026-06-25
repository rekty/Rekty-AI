import 'dart:convert';
import 'package:http/http.dart' as http;

class PollinationsService {
  static Future<List<String>> getModels() async {
    try {
      final response = await http.get(
        Uri.parse('https://image.pollinations.ai/models'),
      );

      print('MODELS STATUS: ${response.statusCode}');
      print('MODELS BODY: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<String>.from(data);
      }
    } catch (e) {
      print('MODELS ERROR: $e');
    }

    return [];
  }
}