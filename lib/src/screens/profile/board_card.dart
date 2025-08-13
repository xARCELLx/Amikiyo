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

  const BoardCard({
    super.key,
    required this.topThree,
    required this.watched,
    required this.nextToWatch,
  });

  void _showAnimeDetails(BuildContext context, String title, String thumbnail, String id) async {
    final results = await KitsuApi.searchAnime(title);
    final anime = results.firstWhere((a) => a['id'] == id, orElse: () => {});
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFF00FF7F), width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: CachedNetworkImage(
                  imageUrl: thumbnail,
                  width: 80,
                  height: 120,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const CircularProgressIndicator(
                    color: Color(0xFF00FF7F),
                  ),
                  errorWidget: (context, url, error) {
                    debugPrint('Anime details thumbnail failed: $url, error: $error');
                    return Image.asset(
                      Constants.placeholderImagePath,
                      width: 80,
                      height: 120,
                      fit: BoxFit.cover,
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontFamily: 'AnimeAce',
                  fontWeight: FontWeight.w600,
                  shadows: [
                    Shadow(
                      blurRadius: 4,
                      color: Colors.black.withOpacity(0.3),
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                anime.isNotEmpty ? anime['attributes']['synopsis'] : 'No description available',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                  fontFamily: 'AnimeAce',
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00FF7F),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Close',
                  style: TextStyle(fontFamily: 'AnimeAce', fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'anime_board',
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF00FF7F), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with Edit Button
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Anime Board',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: const Color(0xFF00FF7F),
                          fontFamily: 'AnimeAce',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Color(0xFF00FF7F), size: 20),
                        onPressed: () async {
                          final result = await showModalBottomSheet<Map<String, dynamic>>(
                            context: context,
                            isScrollControlled: true,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
                            ),
                            backgroundColor: Colors.transparent,
                            builder: (context) => Container(
                              height: MediaQuery.of(context).size.height * 0.8,
                              decoration: const BoxDecoration(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
                              ),
                              child: Stack(
                                children: [
                                  // Blur the background
                                  BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                    child: Container(
                                      color: Colors.black.withOpacity(0.5),
                                    ),
                                  ),
                                  // Position AnimeBoardModal at the bottom
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
                            ),
                          );
                          if (result != null) {
                            // Ensure Top 3 Favorites are added to Watched Anime
                            final updatedWatched = List<Map<String, dynamic>>.from(result['watched']);
                            for (var anime in result['topThree']) {
                              if (!updatedWatched.any((w) => w['id'] == anime['id'])) {
                                updatedWatched.add(anime);
                              }
                            }
                            Navigator.pop(context, {
                              'topThree': result['topThree'],
                              'watched': updatedWatched,
                              'nextToWatch': result['nextToWatch'],
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const Divider(color: Color(0xFF00FF7F), height: 1),
                // Top 3 Favorite Anime
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'Top 3 Favorites',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontFamily: 'AnimeAce',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                topThree.isEmpty
                    ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'No favorites added',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                      fontFamily: 'AnimeAce',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                )
                    : Column(
                  children: topThree.map((anime) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: GestureDetector(
                      onTap: () => _showAnimeDetails(
                        context,
                        anime['title'],
                        anime['thumbnail'] ?? Constants.placeholderImagePath,
                        anime['id'],
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: CachedNetworkImage(
                              imageUrl: anime['thumbnail'] ?? Constants.placeholderImagePath,
                              width: 70,
                              height: 100,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const CircularProgressIndicator(
                                color: Color(0xFF00FF7F),
                              ),
                              errorWidget: (context, url, error) {
                                debugPrint('Top 3 thumbnail failed: $url, error: $error');
                                return Image.asset(
                                  Constants.placeholderImagePath,
                                  width: 70,
                                  height: 100,
                                  fit: BoxFit.cover,
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              anime['title'],
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.white,
                                fontFamily: 'AnimeAce',
                                fontWeight: FontWeight.w400,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )).toList(),
                ),
                const Divider(color: Color(0xFF00FF7F), height: 1),
                // Watched Anime
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'Watched Anime',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontFamily: 'AnimeAce',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                watched.isEmpty
                    ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'No anime watched yet',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                      fontFamily: 'AnimeAce',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                )
                    : Column(
                  children: watched.map((anime) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: GestureDetector(
                      onTap: () => _showAnimeDetails(
                        context,
                        anime['title'],
                        anime['thumbnail'] ?? Constants.placeholderImagePath,
                        anime['id'],
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: CachedNetworkImage(
                              imageUrl: anime['thumbnail'] ?? Constants.placeholderImagePath,
                              width: 50,
                              height: 75,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const CircularProgressIndicator(
                                color: Color(0xFF00FF7F),
                              ),
                              errorWidget: (context, url, error) {
                                debugPrint('Watched thumbnail failed: $url, error: $error');
                                return Image.asset(
                                  Constants.placeholderImagePath,
                                  width: 50,
                                  height: 75,
                                  fit: BoxFit.cover,
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              anime['title'],
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.white,
                                fontFamily: 'AnimeAce',
                                fontWeight: FontWeight.w400,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )).toList(),
                ),
                const Divider(color: Color(0xFF00FF7F), height: 1),
                // Next to Watch
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'Next to Watch',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontFamily: 'AnimeAce',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                nextToWatch.isEmpty
                    ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'No anime in Next to Watch',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                      fontFamily: 'AnimeAce',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                )
                    : Column(
                  children: nextToWatch.map((anime) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: GestureDetector(
                      onTap: () => _showAnimeDetails(
                        context,
                        anime['title'],
                        anime['thumbnail'] ?? Constants.placeholderImagePath,
                        anime['id'],
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: CachedNetworkImage(
                              imageUrl: anime['thumbnail'] ?? Constants.placeholderImagePath,
                              width: 50,
                              height: 75,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const CircularProgressIndicator(
                                color: Color(0xFF00FF7F),
                              ),
                              errorWidget: (context, url, error) {
                                debugPrint('Next to Watch thumbnail failed: $url, error: $error');
                                return Image.asset(
                                  Constants.placeholderImagePath,
                                  width: 50,
                                  height: 75,
                                  fit: BoxFit.cover,
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              anime['title'],
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.white,
                                fontFamily: 'AnimeAce',
                                fontWeight: FontWeight.w400,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}