import 'package:flutter/material.dart';
import '../../post_creation/post_creation_modal.dart';

class EmptyFeed extends StatelessWidget {
  const EmptyFeed({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Join the anime community!\nShare your first post!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.secondary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => const PostCreationModal(),
              );
            },
            child: const Text('Create Post'),
          ),
        ],
      ),
    );
  }
}