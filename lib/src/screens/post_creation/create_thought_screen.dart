import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../../config/constants.dart';
import '../../services/storage_service.dart';
import '../../services/constants.dart';
import '../../widgets/anime_search_modal.dart';

class CreateThoughtScreen extends StatefulWidget {
  const CreateThoughtScreen({super.key});

  @override
  State<CreateThoughtScreen> createState() => _CreateThoughtScreenState();
}

class _CreateThoughtScreenState extends State<CreateThoughtScreen> {
  final _thoughtController = TextEditingController();

  Map<String, dynamic>? _selectedAnime;
  String _privacy = "public";
  bool _isLoading = false;

  // ───────────────── POST THOUGHT ─────────────────

  Future<void> _submitThought() async {
    final text = _thoughtController.text.trim();

    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Write something first")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final token = await StorageService.getToken();

      final formData = FormData.fromMap({
        "post_type": "thought",
        "caption": text,
        "privacy": _privacy,
        if (_selectedAnime != null) ...{
          "anime_id": _selectedAnime!["id"],
          "anime_title": _selectedAnime!["title"],
        }
      });

      final response = await Dio().post(
        "${ApiConstants.baseUrl}/posts/",
        data: formData,
        options: Options(
          headers: {"Authorization": "Token $token"},
        ),
      );

      if (response.statusCode == 201) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Thought posted!"),
            backgroundColor: Color(0xFF00FF7F),
          ),
        );

        Navigator.pop(context, true);
      }
    } on DioException catch (e) {
      String errorMsg = "Post failed";

      if (e.response?.data is Map) {
        final errors = e.response!.data as Map;

        errorMsg = errors.values.first is List
            ? (errors.values.first as List).first
            : errors.values.first.toString();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _thoughtController.dispose();
    super.dispose();
  }

  // ───────────────── UI ─────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "New Thought",
          style: TextStyle(
            fontFamily: "AnimeAce",
            color: Colors.white,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _submitThought,
            child: _isLoading
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF00FF7F),
              ),
            )
                : const Text(
              "POST",
              style: TextStyle(
                color: Color(0xFF00FF7F),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ───────── THOUGHT TEXT ─────────

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF00FF7F),
                  width: 2,
                ),
              ),
              child: TextField(
                controller: _thoughtController,
                maxLines: null,
                maxLength: 500,
                autofocus: true,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  height: 1.5,
                ),
                decoration: const InputDecoration(
                  hintText: "Share your anime thoughts...",
                  hintStyle: TextStyle(color: Colors.white38),
                  border: InputBorder.none,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ───────── ANIME TAG ─────────

            ListTile(
              onTap: () async {
                final anime = await showAnimeSearchModal(context);

                if (anime != null) {
                  setState(() => _selectedAnime = anime);
                }
              },

              contentPadding:
              const EdgeInsets.symmetric(horizontal: 12),

              leading: _selectedAnime != null
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  _selectedAnime!["poster_image"] ??
                      Constants.placeholderImagePath,
                  width: 56,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              )
                  : Container(
                width: 56,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF00FF7F),
                  ),
                ),
                child: const Icon(
                  Icons.search,
                  color: Color(0xFF00FF7F),
                  size: 30,
                ),
              ),

              title: Text(
                _selectedAnime != null
                    ? _selectedAnime!["title"]
                    : "Tag an anime (optional)",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),

              subtitle: _selectedAnime != null
                  ? const Text(
                "Tap to change",
                style: TextStyle(color: Colors.white38),
              )
                  : null,

              trailing: _selectedAnime != null
                  ? IconButton(
                icon: const Icon(Icons.clear, color: Colors.red),
                onPressed: () =>
                    setState(() => _selectedAnime = null),
              )
                  : const Icon(
                Icons.arrow_forward_ios,
                color: Color(0xFF00FF7F),
                size: 16,
              ),
            ),

            const SizedBox(height: 24),

            // ───────── PRIVACY ─────────

            DropdownButtonFormField<String>(
              value: _privacy,
              dropdownColor: Colors.grey[900],
              style: const TextStyle(color: Colors.white),

              decoration: InputDecoration(
                labelText: "Who can see this thought?",
                labelStyle: const TextStyle(
                  color: Color(0xFF00FF7F),
                ),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                  const BorderSide(color: Color(0xFF00FF7F)),
                ),
              ),

              items: const [
                DropdownMenuItem(
                  value: "public",
                  child: Text("Public"),
                ),
                DropdownMenuItem(
                  value: "followers",
                  child: Text("Followers Only"),
                ),
              ],

              onChanged: (val) => setState(() => _privacy = val!),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}