// lib/src/widgets/anime_search_modal.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/constants.dart';

Future<Map<String, dynamic>?> showAnimeSearchModal(
    BuildContext context,
    ) async {
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
  State<AnimeSearchModal> createState() =>
      _AnimeSearchModalState();
}

class _AnimeSearchModalState
    extends State<AnimeSearchModal> {
  final TextEditingController _controller =
  TextEditingController();

  List<dynamic> _results = [];
  bool _loading = false;
  Timer? _debounce;

  static const Color accent = Color(0xFF00FF7F);

  // ───────────────── SEARCH ─────────────────

  Future<void> _search(String query) async {
    if (!mounted) return;

    if (query.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }

    setState(() => _loading = true);

    try {
      final response = await http.get(
        Uri.parse(
            'https://kitsu.io/api/edge/anime?filter[text]=$query&page[limit]=15'),
        headers: {
          'Accept': 'application/vnd.api+json'
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data =
        jsonDecode(response.body);

        setState(() {
          _results = data['data'] ?? [];
        });
      }
    } catch (e) {
      debugPrint("Kitsu search error: $e");
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  // ───────────────── INIT ─────────────────

  @override
  void initState() {
    super.initState();

    _controller.addListener(() {
      _debounce?.cancel();
      _debounce = Timer(
        const Duration(milliseconds: 500),
            () {
          _search(_controller.text);
        },
      );
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  // ───────────────── BUILD ─────────────────

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent, // 🔥 Fixes Material error
      child: Container(
        height:
        MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E1E),
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildSearchField(),
              _buildResults(),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────── HEADER ─────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          16, 12, 16, 8),
      child: Column(
        children: [
          Container(
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius:
              BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Search Anime',
            style: TextStyle(
              color: accent,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────── SEARCH FIELD ─────────────────

  Widget _buildSearchField() {
    return Padding(
      padding:
      const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _controller,
        style:
        const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Enter anime title...',
          hintStyle:
          const TextStyle(color: Colors.white38),
          filled: true,
          fillColor: Colors.grey[900],
          border: OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: accent,
          ),
        ),
      ),
    );
  }

  // ───────────────── RESULTS ─────────────────

  Widget _buildResults() {
    return Expanded(
      child: _loading
          ? const Center(
        child:
        CircularProgressIndicator(
          color: accent,
        ),
      )
          : _results.isEmpty
          ? const Center(
        child: Text(
          'Start typing to search anime',
          style: TextStyle(
              color: Colors.white70),
        ),
      )
          : ListView.builder(
        keyboardDismissBehavior:
        ScrollViewKeyboardDismissBehavior
            .onDrag,
        padding:
        const EdgeInsets.only(top: 8),
        itemCount: _results.length,
        itemBuilder: (context, i) {
          final attributes =
          _results[i]['attributes'];

          final title =
              attributes['canonicalTitle'] ??
                  attributes['titles']
                  ?['en_jp'] ??
                  'No Title';

          final poster =
              attributes['posterImage']
              ?['small'] ??
                  Constants
                      .placeholderImagePath;

          return ListTile(
            leading: ClipRRect(
              borderRadius:
              BorderRadius.circular(
                  8),
              child: Image.network(
                poster,
                width: 50,
                height: 70,
                fit: BoxFit.cover,
                errorBuilder:
                    (_, __, ___) =>
                    Container(
                      width: 50,
                      height: 70,
                      color:
                      Colors.grey[800],
                    ),
              ),
            ),
            title: Text(
              title,
              style:
              const TextStyle(
                  color:
                  Colors.white),
              maxLines: 2,
              overflow:
              TextOverflow.ellipsis,
            ),
            subtitle: Text(
              attributes['showType']
                  ?.toString()
                  .toUpperCase() ??
                  '',
              style:
              const TextStyle(
                  color: Colors
                      .white38),
            ),
            onTap: () {
              final selected = {
                'id':
                _results[i]['id'],
                'title': title,
                'poster_image':
                poster,
              };

              Navigator.pop(
                  context, selected);
            },
          );
        },
      ),
    );
  }
}