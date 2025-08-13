import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../models/post.dart';
import '../../../config/constants.dart';

class PostCard extends StatefulWidget {
  final Post post;
  const PostCard({super.key, required this.post});

  @override
  _PostCardState createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> with SingleTickerProviderStateMixin {
  late int likes;
  double _scale = 1.0;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    likes = widget.post.likes;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _animation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showPostPopup(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User avatar and username in top-left
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: widget.post.profileImage,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const CircularProgressIndicator(),
                            errorWidget: (context, url, error) {
                              debugPrint('Profile image failed: $url, error: $error');
                              return Image.asset(
                                Constants.defaultProfilePath,
                                fit: BoxFit.cover,
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.post.username,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontSize: 16,
                          shadows: [
                            Shadow(
                              blurRadius: 4,
                              color: Colors.black.withOpacity(0.5),
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Image or text content
                if (widget.post.imageUrl != null && widget.post.imageUrl!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12), // Rounded edges for image
                    child: Hero(
                      tag: 'post_image_${widget.post.username}_${widget.post.timestamp}',
                      child: CachedNetworkImage(
                        imageUrl: widget.post.imageUrl!,
                        width: double.infinity,
                        height: MediaQuery.of(context).size.height * 0.6,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                        errorWidget: (context, url, error) => Image.asset(
                          Constants.placeholderImagePath,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    widget.post.content,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontSize: 18,
                      shadows: [
                        Shadow(
                          blurRadius: 4,
                          color: Colors.black.withOpacity(0.5),
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _showPostPopup(context),
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Transform.scale(
            scale: _animation.value,
            child: child,
          );
        },
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9, // Fixed responsive width (90% of screen)
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1), // Transparent background
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.secondary, // Electric green #00FF7F
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5), // Glassmorphism effect
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min, // Dynamic height based on content
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          child: ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: widget.post.profileImage,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const CircularProgressIndicator(),
                              errorWidget: (context, url, error) {
                                debugPrint('Profile image failed: $url, error: $error');
                                return Image.asset(
                                  Constants.defaultProfilePath,
                                  fit: BoxFit.cover,
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.post.username, style: Theme.of(context).textTheme.bodyMedium),
                              Text(widget.post.timestamp, style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            IconButton(
                              icon: Icon(
                                likes > widget.post.likes ? Icons.favorite : Icons.favorite_border,
                                size: 20,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                              onPressed: () {
                                setState(() {
                                  likes = likes > widget.post.likes ? widget.post.likes : widget.post.likes + 1;
                                });
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.comment, size: 20),
                              color: Theme.of(context).colorScheme.secondary,
                              onPressed: () {}, // TODO: Implement comment
                            ),
                            IconButton(
                              icon: const Icon(Icons.share, size: 20),
                              color: Theme.of(context).colorScheme.secondary,
                              onPressed: () {}, // TODO: Implement share
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.post.content,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        shadows: [
                          Shadow(
                            blurRadius: 2,
                            color: Colors.black.withOpacity(0.3),
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                    if (widget.post.imageUrl != null && widget.post.imageUrl!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Hero(
                          tag: 'post_image_${widget.post.username}_${widget.post.timestamp}',
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8), // Rounded edges for card image
                            child: CachedNetworkImage(
                              imageUrl: widget.post.imageUrl!,
                              width: double.infinity,
                              height: 200,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                              errorWidget: (context, url, error) => Image.asset(
                                Constants.placeholderImagePath,
                                height: 200,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}