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

  List<StoryItem> get stories => widget.storyUser.stories;

  bool get isMyStory => widget.storyUser.isMe == true;

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

  // ───────── START STORY ─────────

  void _startStory() {

    final story = stories[currentIndex];

    StoryService.viewStory(story.id);

    _controller.stop();
    _controller.reset();
    _controller.forward();
  }

  // ───────── NEXT STORY ─────────

  void _nextStory() {

    if (currentIndex < stories.length - 1) {

      setState(() {
        currentIndex++;
      });

      _startStory();

    } else {

      Navigator.pop(context, true);
    }
  }

  // ───────── PREVIOUS STORY ─────────

  void _previousStory() {

    if (currentIndex > 0) {

      setState(() {
        currentIndex--;
      });

      _startStory();
    }
  }

  // ───────── TAP HANDLER ─────────

  void _handleTap(TapUpDetails details) {

    final width = MediaQuery.of(context).size.width;

    if (details.globalPosition.dx < width / 2) {
      _previousStory();
    } else {
      _nextStory();
    }
  }

  // ───────── PAUSE / RESUME ─────────

  void _pauseStory() {
    _controller.stop();
  }

  void _resumeStory() {
    _controller.forward();
  }

  // ───────── DELETE STORY WITH CONFIRMATION ─────────

  Future<void> _deleteStory() async {

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: Colors.black,
          title: const Text(
            "Delete Story",
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            "Are you sure you want to delete this story?",
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.pop(context, false),
            ),
            TextButton(
              child: const Text(
                "Delete",
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    final story = stories[currentIndex];

    await StoryService.deleteStory(story.id);

    if (!mounted) return;

    Navigator.pop(context, true);
  }

  // ───────── VIEWERS MODAL ─────────

  Future<void> _openViewers() async {

    final story = stories[currentIndex];

    final viewers = await StoryService.getStoryViewers(story.id);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) {

        if (viewers.isEmpty) {
          return const SizedBox(
            height: 200,
            child: Center(
              child: Text(
                "No viewers yet",
                style: TextStyle(color: Colors.white54),
              ),
            ),
          );
        }

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              const SizedBox(height: 8),

              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),

              const SizedBox(height: 14),

              const Text(
                "Viewers",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 10),

              const Divider(color: Colors.white12, height: 1),

              Expanded(
                child: ListView.separated(
                  itemCount: viewers.length,
                  separatorBuilder: (_, __) =>
                  const Divider(color: Colors.white12, height: 1),
                  itemBuilder: (context, index) {

                    final viewer = viewers[index];

                    return ListTile(
                      leading: CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.grey[800],
                        backgroundImage: viewer["profile_image"] != null
                            ? NetworkImage(viewer["profile_image"])
                            : null,
                        child: viewer["profile_image"] == null
                            ? const Icon(Icons.person, color: Colors.white54)
                            : null,
                      ),
                      title: Text(
                        viewer["username"],
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ───────── UI ─────────

  @override
  Widget build(BuildContext context) {

    final story = stories[currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapUp: _handleTap,
        onLongPressStart: (_) => _pauseStory(),
        onLongPressEnd: (_) => _resumeStory(),

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

                        if (isMyStory)
                          IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.red,
                            ),
                            onPressed: _deleteStory,
                          ),

                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            Navigator.pop(context, true);
                          },
                        )
                      ],
                    ),

                    const Spacer(),

                    if (isMyStory)
                      GestureDetector(
                        onTap: _openViewers,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [

                            const Icon(
                              Icons.remove_red_eye,
                              color: Colors.white70,
                            ),

                            const SizedBox(width: 6),

                            Text(
                              "${story.viewsCount} views",
                              style: const TextStyle(
                                color: Colors.white70,
                              ),
                            )
                          ],
                        ),
                      ),

                    const SizedBox(height: 20),

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