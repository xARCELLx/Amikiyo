// lib/src/screens/profile/other_user_profile_screen.dart

import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../config/constants.dart';
import '../../services/constants.dart';
import '../../services/storage_service.dart';
import '../home/widgets/bottom_nav_bar.dart';

class OtherUserProfileScreen extends StatefulWidget {
  final int userId;

  const OtherUserProfileScreen({
    super.key,
    required this.userId,
  });

  @override
  State<OtherUserProfileScreen> createState() =>
      _OtherUserProfileScreenState();
}

class _OtherUserProfileScreenState extends State<OtherUserProfileScreen> {
  Map<String, dynamic>? profileData;
  List<dynamic> posts = [];
  bool isLoading = true;
  String error = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      isLoading = true;
      error = '';
    });

    try {
      final token = await StorageService.getToken();

      if (token == null) {
        setState(() {
          error = 'Authentication required';
          isLoading = false;
        });
        return;
      }

      // ✅ CORRECT ENDPOINT (ID ONLY)
      final profileResponse = await http.get(
        Uri.parse(
          '${ApiConstants.baseUrl}/profiles/${widget.userId}/',
        ),
        headers: {'Authorization': 'Token $token'},
      );

      if (profileResponse.statusCode != 200) {
        setState(() {
          error = 'User not found';
          isLoading = false;
        });
        return;
      }

      final profileJson = jsonDecode(profileResponse.body);

      // Fetch posts (optional, does not block profile)
      final postsResponse = await http.get(
        Uri.parse(
          '${ApiConstants.baseUrl}/posts/user/${widget.userId}/',
        ),
        headers: {'Authorization': 'Token $token'},
      );

      List<dynamic> fetchedPosts = [];
      if (postsResponse.statusCode == 200) {
        fetchedPosts = jsonDecode(postsResponse.body);
      }

      setState(() {
        profileData = profileJson;
        posts = fetchedPosts;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Network error';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF00FF7F),
          ),
        ),
      );
    }

    if (error.isNotEmpty || profileData == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(backgroundColor: Colors.black),
        body: Center(
          child: Text(
            error.isNotEmpty ? error : 'User not found',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    final username = profileData!['username'] ?? 'Unknown';
    final bio = profileData!['bio'] ?? 'No bio';
    final profileImage =
        profileData!['profile_image'] ??
            Constants.defaultProfilePath;
    final board =
        profileData!['anime_board'] as Map<String, dynamic>? ?? {};

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          username,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Header ─────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage:
                    CachedNetworkImageProvider(profileImage),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          username,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          bio,
                          style: const TextStyle(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Anime Board ───────────────────────
            if (board.isNotEmpty)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF00FF7F),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Anime Board',
                      style: TextStyle(
                        color: Color(0xFF00FF7F),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Top 3: ${(board['top_three'] as List?)?.length ?? 0}',
                      style:
                      const TextStyle(color: Colors.white),
                    ),
                    Text(
                      'Watched: ${(board['watched'] as List?)?.length ?? 0}',
                      style:
                      const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),

            // ── Posts ─────────────────────────────
            if (posts.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics:
                const NeverScrollableScrollPhysics(),
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final post = posts[index];
                  final imageUrl = post['image'];

                  if (imageUrl == null || imageUrl.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return Padding(
                    padding: const EdgeInsets.all(8),
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                    ),
                  );
                },
              )
            else
              const Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No posts yet',
                  style:
                  TextStyle(color: Colors.white54),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar:
      const BottomNavBar(currentIndex: 0),
    );
  }
}
