import 'dart:convert';
import 'package:http/http.dart' as http;

class KitsuApi {
  static const String _baseUrl = 'https://kitsu.io/api/edge';

  static Future<List<Map<String, dynamic>>> searchAnime(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/anime?filter[text]=$query'),
        headers: {'Accept': 'application/vnd.api+json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        print('Kitsu API error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Kitsu API exception: $e');
      return [];
    }
  }
}