import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../config/constants.dart';
import '../../services/kitsu_api.dart';

class AnimeBoardModal extends StatefulWidget {
  final List<Map<String, dynamic>> initialTopThree;
  final List<Map<String, dynamic>> initialWatched;
  final List<Map<String, dynamic>> initialNextToWatch;

  const AnimeBoardModal({
    super.key,
    required this.initialTopThree,
    required this.initialWatched,
    required this.initialNextToWatch,
  });

  @override
  _AnimeBoardModalState createState() => _AnimeBoardModalState();
}

class _AnimeBoardModalState extends State<AnimeBoardModal> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _topThree = [];
  List<Map<String, dynamic>> _watched = [];
  List<Map<String, dynamic>> _nextToWatch = [];
  List<Map<String, dynamic>> _searchResults = [];
  String _selectedCategory = 'Top 3 Favorites';

  @override
  void initState() {
    super.initState();
    _topThree = List.from(widget.initialTopThree);
    _watched = List.from(widget.initialWatched);
    _nextToWatch = List.from(widget.initialNextToWatch);
    // Ensure Top 3 Favorites are in Watched Anime
    for (var anime in _topThree) {
      if (!_watched.any((w) => w['id'] == anime['id'])) {
        _watched.add(anime);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _searchAnime(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }
    final results = await KitsuApi.searchAnime(query);
    setState(() {
      _searchResults = results;
    });
  }

  void _addAnime(Map<String, dynamic> anime) {
    final animeData = {
      'id': anime['id'],
      'title': anime['attributes']['titles']['en'] ?? anime['attributes']['titles']['en_jp'],
      'thumbnail': anime['attributes']['posterImage']['medium'] ?? Constants.placeholderImagePath,
    };
    setState(() {
      if (_selectedCategory == 'Top 3 Favorites' && _topThree.length < 3) {
        _topThree.add(animeData);
        // Automatically add to Watched Anime
        if (!_watched.any((w) => w['id'] == animeData['id'])) {
          _watched.add(animeData);
        }
      } else if (_selectedCategory == 'Watched Anime') {
        _watched.add(animeData);
      } else if (_selectedCategory == 'Next to Watch') {
        _nextToWatch.add(animeData);
      }
      _searchController.clear();
      _searchResults = [];
    });
  }

  void _removeAnime(String id, String category) {
    setState(() {
      if (category == 'Top 3 Favorites') {
        _topThree.removeWhere((anime) => anime['id'] == id);
      } else if (category == 'Watched Anime') {
        _watched.removeWhere((anime) => anime['id'] == id);
        // If removed anime is in Top 3, remove it from there too
        _topThree.removeWhere((anime) => anime['id'] == id);
      } else if (category == 'Next to Watch') {
        _nextToWatch.removeWhere((anime) => anime['id'] == id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        border: Border.all(color: const Color(0xFF00FF7F), width: 1),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Edit Anime Board',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: const Color(0xFF00FF7F),
                fontFamily: 'AnimeAce',
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            // Category Selector
            DropdownButton<String>(
              value: _selectedCategory,
              items: ['Top 3 Favorites', 'Watched Anime', 'Next to Watch'].map((category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(
                    category,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontFamily: 'AnimeAce',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                  _searchController.clear();
                  _searchResults = [];
                });
              },
              dropdownColor: Colors.black.withOpacity(0.8),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontFamily: 'AnimeAce',
                fontWeight: FontWeight.w400,
              ),
              icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF00FF7F), size: 20),
            ),
            const SizedBox(height: 12),
            // Search Bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search anime to add to $_selectedCategory',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Color(0xFF00FF7F)),
                ),
                hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                  fontFamily: 'AnimeAce',
                  fontWeight: FontWeight.w400,
                ),
              ),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontFamily: 'AnimeAce',
                fontWeight: FontWeight.w400,
              ),
              onChanged: _searchAnime,
            ),
            const SizedBox(height: 8),
            // Search Results
            _searchResults.isEmpty
                ? Container()
                : Container(
              height: 120,
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final anime = _searchResults[index];
                  final thumbnail = anime['attributes']['posterImage']['medium'] ?? Constants.placeholderImagePath;
                  return ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: CachedNetworkImage(
                        imageUrl: thumbnail,
                        width: 40,
                        height: 60,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const CircularProgressIndicator(
                          color: Color(0xFF00FF7F),
                        ),
                        errorWidget: (context, url, error) {
                          debugPrint('Search thumbnail failed: $url, error: $error');
                          return Image.asset(
                            Constants.placeholderImagePath,
                            width: 40,
                            height: 60,
                            fit: BoxFit.cover,
                          );
                        },
                      ),
                    ),
                    title: Text(
                      anime['attributes']['titles']['en'] ?? anime['attributes']['titles']['en_jp'],
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontFamily: 'AnimeAce',
                        fontWeight: FontWeight.w400,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => _addAnime(anime),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            // Top 3 Favorites
            Text(
              'Top 3 Favorites',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: const Color(0xFF00FF7F),
                fontFamily: 'AnimeAce',
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _topThree.isEmpty
                ? Text(
              'No favorites added',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white70,
                fontFamily: 'AnimeAce',
                fontWeight: FontWeight.w400,
              ),
            )
                : Column(
              children: _topThree.map((anime) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
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
                          debugPrint('Top 3 modal thumbnail failed: $url, error: $error');
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
                    IconButton(
                      icon: const Icon(Icons.remove_circle, color: Colors.redAccent, size: 20),
                      onPressed: () => _removeAnime(anime['id'], 'Top 3 Favorites'),
                    ),
                  ],
                ),
              )).toList(),
            ),
            const Divider(color: Color(0xFF00FF7F), height: 1),
            const SizedBox(height: 12),
            // Watched Anime
            Text(
              'Watched Anime',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: const Color(0xFF00FF7F),
                fontFamily: 'AnimeAce',
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _watched.isEmpty
                ? Text(
              'No anime watched yet',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white70,
                fontFamily: 'AnimeAce',
                fontWeight: FontWeight.w400,
              ),
            )
                : Column(
              children: _watched.map((anime) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
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
                          debugPrint('Watched modal thumbnail failed: $url, error: $error');
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
                    IconButton(
                      icon: const Icon(Icons.remove_circle, color: Colors.redAccent, size: 20),
                      onPressed: () => _removeAnime(anime['id'], 'Watched Anime'),
                    ),
                  ],
                ),
              )).toList(),
            ),
            const Divider(color: Color(0xFF00FF7F), height: 1),
            const SizedBox(height: 12),
            // Next to Watch
            Text(
              'Next to Watch',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: const Color(0xFF00FF7F),
                fontFamily: 'AnimeAce',
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _nextToWatch.isEmpty
                ? Text(
              'No anime in Next to Watch',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white70,
                fontFamily: 'AnimeAce',
                fontWeight: FontWeight.w400,
              ),
            )
                : Column(
              children: _nextToWatch.map((anime) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
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
                          debugPrint('Next to Watch modal thumbnail failed: $url, error: $error');
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
                    IconButton(
                      icon: const Icon(Icons.remove_circle, color: Colors.redAccent, size: 20),
                      onPressed: () => _removeAnime(anime['id'], 'Next to Watch'),
                    ),
                  ],
                ),
              )).toList(),
            ),
            const SizedBox(height: 12),
            // Save Button
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00FF7F),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onPressed: () {
                  Navigator.pop(context, {
                    'topThree': _topThree,
                    'watched': _watched,
                    'nextToWatch': _nextToWatch,
                  });
                },
                child: const Text(
                  'Save',
                  style: TextStyle(fontFamily: 'AnimeAce', fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}