import 'package:flutter/material.dart';
import '../../models/story_model.dart';
import 'story_avatar.dart';
import '../../screens/story/story_viewer_screen.dart';
import '../../screens/story/create_story_screen.dart';

class StoryList extends StatelessWidget {
  final List<StoryUser> stories;

  // 🔥 refresh callback from HomeScreen
  final Future<void> Function() refreshStories;

  const StoryList({
    super.key,
    required this.stories,
    required this.refreshStories,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: stories.length + 1, // +1 for Your Story
        itemBuilder: (context, index) {

          // ───────── YOUR STORY BUTTON ─────────

          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: GestureDetector(
                onTap: () async {

                  final created = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CreateStoryScreen(),
                    ),
                  );

                  // 🔥 reload stories instantly
                  if (created == true) {
                    await refreshStories();
                  }

                },
                child: Column(
                  children: [

                    Stack(
                      children: [

                        const CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.grey,
                          child: Icon(
                            Icons.person,
                            color: Colors.white,
                          ),
                        ),

                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Color(0xFF00FF7F),
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(3),
                            child: const Icon(
                              Icons.add,
                              size: 16,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    const Text(
                      "Your Story",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // ───────── OTHER USERS STORIES ─────────

          final storyUser = stories[index - 1];

          final bool isSeen =
          storyUser.stories.every((s) => s.isSeen);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: StoryAvatar(
              username: storyUser.username,
              imageUrl: storyUser.profileImage,
              isSeen: isSeen,
              onTap: () async {

                final watched = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StoryViewerScreen(
                      storyUser: storyUser,
                    ),
                  ),
                );

                // 🔥 refresh ring after watching
                if (watched == true) {
                  await refreshStories();
                }

              },
            ),
          );
        },
      ),
    );
  }
}