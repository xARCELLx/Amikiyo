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
    setState(() => isLoading = true);

    // Try cache first
    final cached = await StorageService.getCachedProfile();
    if (cached != null) {
      setState(() {
        profileData = cached;
        isLoading = false;
      });
    }

    // Then fetch fresh
    final fresh = await ApiService.getMyProfile();
    if (fresh != null) {
      setState(() {
        profileData = fresh;
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
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

    final user = profileData!['user'];
    final profile = profileData!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: const Color(0xFF00FF7F),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Avatar
            CircleAvatar(
              radius: 60,
              backgroundImage: profile['profile_image'].toString().isNotEmpty
                  ? NetworkImage(profile['profile_image'])
                  : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
            ),
            const SizedBox(height: 16),

            // Username
            Text(
              user['username'],
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              user['email'],
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // Bio
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Bio', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(profile['bio'].toString().isEmpty ? 'No bio yet' : profile['bio']),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Anime Board
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Anime Board', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _buildAnimeList('Watching', profile['anime_board']['watching'] ?? []),
                    _buildAnimeList('Completed', profile['anime_board']['completed'] ?? []),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimeList(String title, List<dynamic> items) {
    if (items.isEmpty) return Container();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        ...items.map((anime) => Text('• $anime')).toList(),
        const SizedBox(height: 8),
      ],
    );
  }
}