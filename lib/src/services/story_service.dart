import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/story_model.dart';
import '../services/constants.dart';
import '../services/storage_service.dart';

class StoryService {

  static Future<void> createStory(String imagePath) async {
    final token = await StorageService.getToken();

    final request = http.MultipartRequest(
      "POST",
      Uri.parse("${ApiConstants.baseUrl}/story/create/"),
    );

    request.headers["Authorization"] = "Token $token";

    request.files.add(
      await http.MultipartFile.fromPath(
        "image",
        imagePath,
      ),
    );

    final response = await request.send();

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception("Failed to upload story");
    }
  }

  static Future<List<StoryUser>> fetchStoryFeed() async {
    final token = await StorageService.getToken();

    final res = await http.get(
      Uri.parse("${ApiConstants.baseUrl}/story/feed/"),
      headers: {
        "Authorization": "Token $token",
      },
    );

    if (res.statusCode != 200) {
      throw Exception("Failed to load stories");
    }

    final List data = jsonDecode(res.body);

    return data.map((e) => StoryUser.fromJson(e)).toList();
  }

  static Future<void> viewStory(int storyId) async {
    final token = await StorageService.getToken();

    await http.post(
      Uri.parse("${ApiConstants.baseUrl}/story/$storyId/view/"),
      headers: {
        "Authorization": "Token $token",
      },
    );
  }
}