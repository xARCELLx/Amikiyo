import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/story_model.dart';
import '../../services/story_service.dart';
import '../../widgets/story/story_progress_bar.dart';

class StoryViewerScreen extends StatefulWidget {
  final StoryUser storyUser;

  const StoryViewerScreen({
    super.key,
    required this.storyUser,
  });

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  int currentIndex = 0;
  Timer? _timer;

  List<StoryItem> get stories => widget.storyUser.stories;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    _controller.addListener(() {
      setState(() {});
    });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _nextStory();
      }
    });

    _startStory();
  }

  void _startStory() {
    _controller.forward(from: 0);

    final story = stories[currentIndex];

    StoryService.viewStory(story.id);
  }

  void _nextStory() {
    if (currentIndex < stories.length - 1) {
      setState(() {
        currentIndex++;
      });
      _startStory();
    } else {
      Navigator.pop(context);
    }
  }

  void _previousStory() {
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
      });
      _startStory();
    }
  }

  void _handleTap(TapUpDetails details) {
    final width = MediaQuery.of(context).size.width;

    if (details.globalPosition.dx < width / 2) {
      _previousStory();
    } else {
      _nextStory();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final story = stories[currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapUp: _handleTap,
        child: Stack(
          children: [
            Positioned.fill(
              child: CachedNetworkImage(
                imageUrl: story.image,
                fit: BoxFit.cover,
              ),
            ),

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    StoryProgressBar(
                      total: stories.length,
                      currentIndex: currentIndex,
                      progress: _controller.value,
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundImage:
                          widget.storyUser.profileImage != null
                              ? CachedNetworkImageProvider(
                              widget.storyUser.profileImage!)
                              : null,
                          child: widget.storyUser.profileImage == null
                              ? const Icon(Icons.person)
                              : null,
                        ),

                        const SizedBox(width: 10),

                        Text(
                          widget.storyUser.username,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const Spacer(),

                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        )
                      ],
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
