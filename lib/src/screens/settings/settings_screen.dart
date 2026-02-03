// lib/src/screens/settings/settings_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import '../profile/edit_profile_modal.dart';
import '../../services/auth_service.dart';
import '../../screens/auth/auth_screen.dart';

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
      extendBodyBehindAppBar: true,
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
        iconTheme: const IconThemeData(color: Color(0xFF00FF7F)),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1E1E1E),
              Color(0xFF1A237E),
            ],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.only(top: 100, left: 16, right: 16, bottom: 20),
          children: [
            // EDIT PROFILE → NOW REFRESHES PROFILE SCREEN
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
              trailing: const Icon(Icons.arrow_forward_ios, color: Color(0xFF00FF7F), size: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              tileColor: Colors.white.withOpacity(0.05),
              onTap: () async {
                final result = await showModalBottomSheet<Map<String, dynamic>>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => Stack(
                    children: [
                      BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                        child: Container(color: Colors.black.withOpacity(0.5)),
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

                // THIS IS THE KEY: Tell ProfileScreen to refresh
                if (result != null && result['saved'] == true) {
                  Navigator.pop(context, true); // ← Triggers _loadEverything() in ProfileScreen
                }
              },
            ),
            const SizedBox(height: 8),

            const Divider(color: Color(0xFF00FF7F), height: 1, thickness: 0.5),

            // Future settings (you can expand later)
            ListTile(
              leading: const Icon(Icons.notifications, color: Color(0xFF00FF7F)),
              title: Text('Notifications', style: _tileTitleStyle(context)),
              tileColor: Colors.white.withOpacity(0.05),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              onTap: () {
                // TODO: Notifications settings
              },
            ),
            const SizedBox(height: 8),

            ListTile(
              leading: const Icon(Icons.lock, color: Color(0xFF00FF7F)),
              title: Text('Privacy', style: _tileTitleStyle(context)),
              tileColor: Colors.white.withOpacity(0.05),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              onTap: () {
                // TODO: Privacy settings
              },
            ),
            const SizedBox(height: 8),

            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: Text(
                'Log Out',
                style: _tileTitleStyle(context).copyWith(color: Colors.redAccent),
              ),
              tileColor: Colors.white.withOpacity(0.05),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              onTap: () async {
                // Show confirmation dialog first (best practice for logout)
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Logout?'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Logout', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );

                if (confirm != true) return;

                try {
                  await AuthService().logout();

                  // Clear any cached data if needed
                  // await StorageService.clearAll();  // optional - if you want to wipe everything

                  // Navigate to AuthScreen and replace current route
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const AuthScreen()),
                  );

                  // Show success snackbar AFTER navigation (on the new screen)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Logged out successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Logout failed: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  TextStyle _tileTitleStyle(BuildContext context) {
    return Theme.of(context).textTheme.titleMedium!.copyWith(
      color: Colors.white,
      fontFamily: 'AnimeAce',
      fontWeight: FontWeight.w600,
    );
  }
}