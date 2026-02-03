import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../config/constants.dart';
import '../profile/profile_screen.dart';

class FollowUserTile extends StatelessWidget {
  final Map<String, dynamic> user;

  const FollowUserTile({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final username = user['username'] ?? 'Unknown';
    final profileImage =
        user['profile_image'] ?? Constants.defaultProfilePath;
    final userId = user['user_id'];

    return ListTile(
      leading: CircleAvatar(
        radius: 24,
        backgroundImage: CachedNetworkImageProvider(profileImage),
      ),
      title: Text(
        username,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProfileScreen(userId: userId),
          ),
        );
      },
    );
  }
}
