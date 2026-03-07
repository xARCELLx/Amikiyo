import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/story_model.dart';
import '../services/constants.dart';
import '../services/storage_service.dart';

class StoryService {

  // ───────────────── CREATE STORY ─────────────────

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

  // ───────────────── STORY FEED ─────────────────

  static Future<List<StoryUser>> fetchStoryFeed() async {
    final token = await StorageService.getToken();

    final res = await http.get(
      Uri.parse("${ApiConstants.baseUrl}/story/feed/"),
      headers: {
        "Authorization": "Token $token",
        "Content-Type": "application/json",
      },
    );

    if (res.statusCode != 200) {
      throw Exception("Failed to load stories");
    }

    final List data = jsonDecode(res.body);

    return data.map((e) => StoryUser.fromJson(e)).toList();
  }

  // ───────────────── VIEW STORY ─────────────────

  static Future<void> viewStory(int storyId) async {
    final token = await StorageService.getToken();

    final res = await http.post(
      Uri.parse("${ApiConstants.baseUrl}/story/$storyId/view/"),
      headers: {
        "Authorization": "Token $token",
      },
    );

    if (res.statusCode != 200) {
      throw Exception("Failed to record story view");
    }
  }

  // ───────────────── DELETE STORY ─────────────────

  static Future<void> deleteStory(int storyId) async {
    final token = await StorageService.getToken();

    final res = await http.delete(
      Uri.parse("${ApiConstants.baseUrl}/story/$storyId/delete/"),
      headers: {
        "Authorization": "Token $token",
      },
    );

    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception("Failed to delete story");
    }
  }

  // ───────────────── GET MY STORIES ─────────────────

  static Future<List<StoryItem>> getMyStories() async {
    final token = await StorageService.getToken();

    final res = await http.get(
      Uri.parse("${ApiConstants.baseUrl}/story/my/"),
      headers: {
        "Authorization": "Token $token",
      },
    );

    if (res.statusCode != 200) {
      throw Exception("Failed to fetch my stories");
    }

    final List data = jsonDecode(res.body);

    return data.map((e) => StoryItem.fromJson(e)).toList();
  }

  // ───────────────── GET STORY VIEWERS ─────────────────

  static Future<List<dynamic>> getStoryViewers(int storyId) async {
    final token = await StorageService.getToken();

    final res = await http.get(
      Uri.parse("${ApiConstants.baseUrl}/story/$storyId/viewers/"),
      headers: {
        "Authorization": "Token $token",
      },
    );

    if (res.statusCode != 200) {
      throw Exception("Failed to fetch viewers");
    }

    return jsonDecode(res.body);
  }
}