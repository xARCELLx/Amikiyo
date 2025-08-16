import 'dart:ui';
import 'package:flutter/material.dart';
import '../profile/edit_profile_modal.dart';

class SettingsScreen extends StatelessWidget {
  final String username;
  final String bio;
  final String profileImage;

  const SettingsScreen({
    super.key,
    required this.username,
    required this.bio,
    required this.profileImage,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontFamily: 'AnimeAce',
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [const Color(0xFF1E1E1E), const Color(0xFF1A237E).withOpacity(0.8)],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Edit Profile Option
            ListTile(
              leading: const Icon(Icons.edit, color: Color(0xFF00FF7F)),
              title: Text(
                'Edit Profile',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontFamily: 'AnimeAce',
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () async {
                final result = await showModalBottomSheet<Map<String, dynamic>>(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
                  ),
                  backgroundColor: Colors.transparent,
                  builder: (context) => Stack(
                    children: [
                      BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                        child: Container(
                          color: Colors.black.withOpacity(0.5),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: EditProfileModal(
                          initialUsername: username,
                          initialBio: bio,
                          initialProfileImage: profileImage,
                        ),
                      ),
                    ],
                  ),
                );
                if (result != null) {
                  Navigator.pop(context, result);
                }
              },
            ),
            const Divider(color: Color(0xFF00FF7F), height: 1),
            // Other Settings Options (Placeholder)
            ListTile(
              leading: const Icon(Icons.notifications, color: Color(0xFF00FF7F)),
              title: Text(
                'Notifications',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontFamily: 'AnimeAce',
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                // TODO: Implement notifications settings
              },
            ),
            ListTile(
              leading: const Icon(Icons.lock, color: Color(0xFF00FF7F)),
              title: Text(
                'Privacy',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontFamily: 'AnimeAce',
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                // TODO: Implement privacy settings
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Color(0xFF00FF7F)),
              title: Text(
                'Log Out',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontFamily: 'AnimeAce',
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                // TODO: Implement log out
              },
            ),
          ],
        ),
      ),
    );
  }
}