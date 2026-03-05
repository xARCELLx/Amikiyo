import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class StoryAvatar extends StatelessWidget {
  final String username;
  final String? imageUrl;
  final bool isSeen;
  final VoidCallback onTap;

  const StoryAvatar({
    super.key,
    required this.username,
    required this.imageUrl,
    required this.isSeen,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [

          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isSeen
                  ? null
                  : const LinearGradient(
                colors: [
                  Color(0xFF00FF7F),
                  Color(0xFF00BFFF),
                ],
              ),
              border: isSeen
                  ? Border.all(color: Colors.grey, width: 2)
                  : null,
            ),
            child: CircleAvatar(
              radius: 30,
              backgroundColor: Colors.black,
              child: CircleAvatar(
                radius: 27,
                backgroundImage: imageUrl != null
                    ? CachedNetworkImageProvider(imageUrl!)
                    : null,
                child: imageUrl == null
                    ? const Icon(Icons.person, color: Colors.white54)
                    : null,
              ),
            ),
          ),

          const SizedBox(height: 6),

          SizedBox(
            width: 70,
            child: Text(
              username,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          )
        ],
      ),
    );
  }
}