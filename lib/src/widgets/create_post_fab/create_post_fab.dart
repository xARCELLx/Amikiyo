import 'package:flutter/material.dart';

import '../../screens/post_creation/create_post_screen.dart';
import '../../screens/post_creation/create_thought_screen.dart';
import 'expandable_fab.dart';

class CreatePostFab extends StatelessWidget {
  final VoidCallback onPostCreated;

  const CreatePostFab({
    super.key,
    required this.onPostCreated,
  });

  @override
  Widget build(BuildContext context) {
    return ExpandableFab(
      onImagePost: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const CreatePostScreen(),
          ),
        );

        if (result == true) {
          onPostCreated();
        }
      },
      onThoughtPost: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const CreateThoughtScreen(),
          ),
        );

        if (result == true) {
          onPostCreated();
        }
      },
    );
  }
}