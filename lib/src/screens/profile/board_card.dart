// lib/src/screens/profile/board_card.dart

import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../config/constants.dart';
import '../../services/kitsu_api.dart';
import 'anime_board_modal.dart';

class BoardCard extends StatelessWidget {
  final List<Map<String, dynamic>> topThree;
  final List<Map<String, dynamic>> watched;
  final List<Map<String, dynamic>> nextToWatch;

  /// 🔥 NEW
  final bool isEditable;

  const BoardCard({
    super.key,
    required this.topThree,
    required this.watched,
    required this.nextToWatch,
    this.isEditable = false,
  });

  // ───────────────── ANIME DETAILS MODAL ─────────────────

  void _showAnimeDetails(
      BuildContext context,
      String title,
      String thumbnail,
      String id,
      ) async {
    final results = await KitsuApi.searchAnime(title);
    final anime =
    results.firstWhere((a) => a['id'] == id, orElse: () => {});

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF00FF7F)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: thumbnail,
                  width: 90,
                  height: 130,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) =>
                      Image.asset(Constants.placeholderImagePath),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'AnimeAce',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                anime.isNotEmpty
                    ? anime['attributes']['synopsis'] ?? 'No description'
                    : 'No description',
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Close',
                  style: TextStyle(color: Color(0xFF00FF7F)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────── BUILD ─────────────────

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'anime_board',
      child: Container(
        width: MediaQuery.of(context).size.width * 0.92,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF00FF7F)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // HEADER
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Anime Board',
                            style: TextStyle(
                              color: Color(0xFF00FF7F),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'AnimeAce',
                            ),
                          ),
                          if (isEditable)
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: Color(0xFF00FF7F),
                              ),
                              onPressed: () async {
                                final result =
                                await showModalBottomSheet<
                                    Map<String, dynamic>>(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (_) => Stack(
                                    children: [
                                      BackdropFilter(
                                        filter: ImageFilter.blur(
                                            sigmaX: 6, sigmaY: 6),
                                        child: Container(
                                            color:
                                            Colors.black.withOpacity(0.6)),
                                      ),
                                      Align(
                                        alignment: Alignment.bottomCenter,
                                        child: AnimeBoardModal(
                                          initialTopThree: topThree,
                                          initialWatched: watched,
                                          initialNextToWatch: nextToWatch,
                                        ),
                                      ),
                                    ],
                                  ),
                                );

                                if (result != null && context.mounted) {
                                  Navigator.pop(context, {
                                    'topThree': result['topThree'],
                                    'watched': result['watched'],
                                    'nextToWatch': result['nextToWatch'],
                                  });
                                }
                              },
                            ),
                        ],
                      ),
                    ),

                    const Divider(color: Color(0xFF00FF7F), height: 1),

                    _section(
                      context,
                      title: 'Top 3 Favorites',
                      list: topThree,
                      large: true,
                    ),

                    const Divider(color: Color(0xFF00FF7F), height: 1),

                    _section(
                      context,
                      title: 'Watched',
                      list: watched,
                    ),

                    const Divider(color: Color(0xFF00FF7F), height: 1),

                    _section(
                      context,
                      title: 'Next to Watch',
                      list: nextToWatch,
                    ),

                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────── SECTION BUILDER ─────────────────

  Widget _section(
      BuildContext context, {
        required String title,
        required List<Map<String, dynamic>> list,
        bool large = false,
      }) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontFamily: 'AnimeAce',
            ),
          ),
          const SizedBox(height: 8),
          list.isEmpty
              ? const Text(
            'Nothing here yet',
            style: TextStyle(color: Colors.white54),
          )
              : Column(
            children: list.map((anime) {
              return GestureDetector(
                onTap: () => _showAnimeDetails(
                  context,
                  anime['title'] ?? '',
                  anime['thumbnail'] ??
                      Constants.placeholderImagePath,
                  anime['id']?.toString() ?? '',
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: CachedNetworkImage(
                          imageUrl: anime['thumbnail'] ??
                              Constants.placeholderImagePath,
                          width: large ? 70 : 50,
                          height: large ? 100 : 75,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          anime['title'] ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'AnimeAce',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
