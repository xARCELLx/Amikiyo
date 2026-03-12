import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';

import '../../../services/constants.dart';
import '../../../services/storage_service.dart';
import '../../comments/comments_bottom_sheet.dart';
import '../../chat/share_post_bottom_sheet.dart';
import '../../../config/constants.dart';

class ThoughtViewer extends StatefulWidget {
  final Map<String, dynamic> post;

  const ThoughtViewer({required this.post});

  @override
  State<ThoughtViewer> createState() => _ThoughtViewerState();
}

class _ThoughtViewerState extends State<ThoughtViewer> {

  late bool _liked;
  late int _likes;
  late int _comments;

  bool _processing = false;

  Future<List<Map<String, dynamic>>>? _animeFuture;

  @override
  void initState() {
    super.initState();

    _liked = widget.post['is_liked'] ?? false;
    _likes = widget.post['likes_count'] ?? 0;
    _comments = widget.post['comments_count'] ?? 0;

    final animeId = widget.post['anime_id'];
    if (animeId != null) {
      _animeFuture = _fetchAnime(animeId);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchAnime(String id) async {
    final res = await http.get(
      Uri.parse("https://kitsu.io/api/edge/anime/$id"),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return [data['data']];
    }

    return [];
  }

  Future<void> _toggleLike() async {

    if (_processing) return;

    setState(() {
      _processing = true;
      _liked = !_liked;
      _likes += _liked ? 1 : -1;
    });

    final token = await StorageService.getToken();

    final url = _liked
        ? '${ApiConstants.baseUrl}/posts/${widget.post['id']}/like/'
        : '${ApiConstants.baseUrl}/posts/${widget.post['id']}/unlike/';

    await http.post(
      Uri.parse(url),
      headers: {'Authorization': 'Token $token'},
    );

    setState(() => _processing = false);
  }

  Future<void> _openComments() async {

    final updated = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      builder: (_) => CommentsBottomSheet(
        postId: widget.post['id'],
        initialCount: _comments,
      ),
    );

    if (updated != null) {
      setState(() => _comments = updated);
    }
  }

  void _openShare() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      isScrollControlled: true,
      builder: (_) => SharePostBottomSheet(post: widget.post),
    );
  }

  @override
  Widget build(BuildContext context) {

    final username = widget.post['author_username'] ?? 'User';
    final caption = widget.post['caption'] ?? '';
    final pfp = widget.post['author_pfp'] ?? '';
    final animeTitle = widget.post['anime_title'];

    return Stack(
      children: [

        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(color: Colors.black54),
        ),

        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Row(
                    children: [

                      CircleAvatar(
                        radius: 20,
                        backgroundImage: pfp.isNotEmpty
                            ? NetworkImage(pfp)
                            : const AssetImage(Constants.placeholderImagePath)
                        as ImageProvider,
                      ),

                      const SizedBox(width: 10),

                      Text(
                        username,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  Text(
                    caption,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 22),

                  Row(
                    children: [

                      GestureDetector(
                        onTap: _toggleLike,
                        child: Row(
                          children: [
                            Icon(
                              _liked ? Icons.favorite : Icons.favorite_border,
                              color: _liked ? Colors.red : Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 6),
                            Text("$_likes",
                                style:
                                const TextStyle(color: Colors.white70)),
                          ],
                        ),
                      ),

                      const SizedBox(width: 20),

                      GestureDetector(
                        onTap: _openComments,
                        child: Row(
                          children: [
                            const Icon(Icons.comment_outlined,
                                color: Colors.white, size: 20),
                            const SizedBox(width: 6),
                            Text("$_comments",
                                style:
                                const TextStyle(color: Colors.white70)),
                          ],
                        ),
                      ),

                      const Spacer(),

                      GestureDetector(
                        onTap: _openShare,
                        child: const Icon(Icons.send,
                            color: Colors.white, size: 20),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  if (animeTitle != null && _animeFuture != null)
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: _animeFuture,
                      builder: (context, snap) {

                        String thumb = Constants.placeholderImagePath;

                        if (snap.hasData && snap.data!.isNotEmpty) {
                          thumb = snap.data!.first['attributes']
                          ['posterImage']['medium'];
                        }

                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(30),
                            border:
                            Border.all(color: const Color(0xFF00FF7F)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [

                              ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: thumb,
                                  width: 28,
                                  height: 28,
                                  fit: BoxFit.cover,
                                ),
                              ),

                              const SizedBox(width: 8),

                              Flexible(
                                child: Text(
                                  animeTitle,
                                  style:
                                  const TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}