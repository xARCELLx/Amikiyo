// lib/src/screens/profile/profile_screen.dart
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? profileData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    // Retry loop — waits for token
    for (int i = 0; i < 5; i++) {
      final fresh = await ApiService.getMyProfile();
      if (fresh != null && mounted) {
        setState(() {
          profileData = fresh;
          isLoading = false;
        });
        return;
      }
      await Future.delayed(const Duration(milliseconds: 800));
    }

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFF00FF7F))),
      );
    }

    if (profileData == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Failed to load profile'),
              ElevatedButton(
                onPressed: _loadProfile,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // SAFE ACCESS — this was the crash!
    final String username = profileData!['username'] ?? 'Unknown User';
    final String bio = profileData!['bio'] ?? '';
    final String profileImage = profileData!['profile_image'] ?? '';
    final Map animeBoard = profileData!['anime_board'] ?? {};

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: const Color(0xFF00FF7F),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundImage: profileImage.isNotEmpty
                  ? NetworkImage(profileImage)
                  : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
              backgroundColor: Colors.grey[200],
            ),
            const SizedBox(height: 16),
            Text(
              username,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              bio.isEmpty ? 'No bio yet ~' : bio,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            const Text(
              'Anime Board',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            // Add your anime board UI here later
            Text(
              animeBoard.isEmpty ? 'No anime added yet!' : 'Anime board loaded!',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}