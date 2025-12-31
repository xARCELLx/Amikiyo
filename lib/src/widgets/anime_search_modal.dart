// lib/src/widgets/anime_search_modal.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/constants.dart';

Future<Map<String, dynamic>?> showAnimeSearchModal(BuildContext context) async {
  return showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const AnimeSearchModal(),
  );
}

class AnimeSearchModal extends StatefulWidget {
  const AnimeSearchModal({super.key});

  @override
  State<AnimeSearchModal> createState() => _AnimeSearchModalState();
}

class _AnimeSearchModalState extends State<AnimeSearchModal> {
  final TextEditingController _controller = TextEditingController();
  List<dynamic> _results = [];
  bool _loading = false;
  Timer? _debounce;

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }

    setState(() => _loading = true);

    try {
      final response = await http.get(
        Uri.parse('https://kitsu.io/api/edge/anime?filter[text]=$query&page[limit]=15'),
        headers: {'Accept': 'application/vnd.api+json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _results = data['data'];
        });
      }
    } catch (e) {
      debugPrint('Kitsu search error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 500), () {
        _search(_controller.text);
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle + title
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(10))),
                const SizedBox(height: 16),
                const Text('Search Anime', style: TextStyle(color: Color(0xFF00FF7F), fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(
                  controller: _controller,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Enter anime title...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: Colors.grey[900],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF00FF7F)),
                  ),
                ),
              ],
            ),
          ),

          // Results
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF00FF7F)))
                : _results.isEmpty
                ? const Center(child: Text('Start typing to search anime', style: TextStyle(color: Colors.white70)))
                : ListView.builder(
              itemCount: _results.length,
              itemBuilder: (context, i) {
                final anime = _results[i]['attributes'];
                final title = anime['canonicalTitle'] ?? anime['titles']['en_jp'] ?? 'No Title';
                final poster = anime['posterImage']?['small'] ?? Constants.placeholderImagePath;

                return ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(poster, width: 50, height: 70, fit: BoxFit.cover),
                  ),
                  title: Text(title, style: const TextStyle(color: Colors.white), maxLines: 2, overflow: TextOverflow.ellipsis),
                  subtitle: Text(anime['showType'] ?? '', style: const TextStyle(color: Colors.white38)),
                  onTap: () {
                    final selected = {
                      'id': _results[i]['id'],
                      'title': title,
                      'poster_image': poster,
                    };
                    Navigator.pop(context, selected);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}