import 'package:flutter/material.dart';

class PostCreationModal extends StatelessWidget {
  const PostCreationModal({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      height: 300,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Create a Post', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(
              hintText: 'What’s on your mind?',
              border: OutlineInputBorder(),
              hintStyle: TextStyle(color: Color(0xFFB0BEC5)),
            ),
            maxLines: 3,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {}, // TODO: Implement image picker
                icon: const Icon(Icons.image, size: 20),
                label: const Text('Image'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {}, // TODO: Implement video picker
                icon: const Icon(Icons.videocam, size: 20),
                label: const Text('Video'),
              ),
            ],
          ),
          const Spacer(),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                foregroundColor: Colors.white,
              ),
              onPressed: () {}, // TODO: Implement post submission
              child: const Text('Post'),
            ),
          ),
        ],
      ),
    );
  }
}