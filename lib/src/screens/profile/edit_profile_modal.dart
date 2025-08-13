import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../config/constants.dart';
import '../../services/kitsu_api.dart';

class EditProfileModal extends StatefulWidget {
  const EditProfileModal({super.key});

  @override
  _EditProfileModalState createState() => _EditProfileModalState();
}

class _EditProfileModalState extends State<EditProfileModal> {
  final TextEditingController _bioController = TextEditingController(
    text: 'Loves Demon Slayer, Naruto, and One Piece',
  );
  final TextEditingController _searchController = TextEditingController();
  final List<Map<String, dynamic>> _favorites = [
    {
      'title': 'Demon Slayer',
      'thumbnail': 'https://media.kitsu.io/anime/poster_images/12191/medium.jpg',
      'id': '12191',
    },
    {
      'title': 'Naruto',
      'thumbnail': 'https://media.kitsu.io/anime/poster_images/12/medium.jpg',
      'id': '12',
    },
    {
      'title': 'One Piece',
      'thumbnail': 'https://media.kitsu.io/anime/poster_images/13/medium.jpg',
      'id': '13',
    },
    {
      'title': 'Attack on Titan',
      'thumbnail': 'https://media.kitsu.io/anime/poster_images/7442/medium.jpg',
      'id': '7442',
    },
  ];
  List<Map<String, dynamic>> _searchResults = [];

  @override
  void dispose() {
    _bioController.dispose();
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

  void _addFavorite(Map<String, dynamic> anime) {
    setState(() {
      _favorites.add({
        'title': anime['attributes']['titles']['en'] ?? anime['attributes']['titles']['en_jp'],
        'thumbnail': anime['attributes']['posterImage']['medium'],
        'id': anime['id'],
      });
      _searchController.clear();
      _searchResults = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        border: Border.all(color: const Color(0xFF00FF7F), width: 1),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit Profile',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              // Profile Picture
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: 'https://picsum.photos/150/150?random=5',
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const CircularProgressIndicator(),
                          errorWidget: (context, url, error) {
                            debugPrint('Profile image failed: $url, error: $error');
                            return Image.asset(
                              Constants.defaultProfilePath,
                              fit: BoxFit.cover,
                            );
                          },
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () {}, // TODO: Implement image picker
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF00FF7F),
                          ),
                          child: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Bio
              TextField(
                controller: _bioController,
                decoration: InputDecoration(
                  hintText: 'Enter your bio',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF00FF7F)),
                  ),
                  hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
                ),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              // Anime Search
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search anime to add to favorites',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF00FF7F)),
                  ),
                  hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
                ),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                ),
                onChanged: _searchAnime,
              ),
              const SizedBox(height: 8),
              // Search Results
              _searchResults.isEmpty
                  ? Container()
                  : Container(
                height: 150,
                child: ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final anime = _searchResults[index];
                    return ListTile(
                      leading: CachedNetworkImage(
                        imageUrl: anime['attributes']['posterImage']['medium'],
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const CircularProgressIndicator(),
                        errorWidget: (context, url, error) => Image.asset(
                          Constants.placeholderImagePath,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        ),
                      ),
                      title: Text(
                        anime['attributes']['titles']['en'] ?? anime['attributes']['titles']['en_jp'],
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      onTap: () => _addFavorite(anime),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              // Save Button
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00FF7F),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context, {
                      'bio': _bioController.text,
                      'favorites': _favorites,
                    });
                  },
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}