import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../config/constants.dart';
import '../../../services/constants.dart';
import '../../comments/comments_bottom_sheet.dart';
import '../../chat/share_post_bottom_sheet.dart';
import '../../../services/storage_service.dart';
import 'package:http/http.dart' as http;

class FeedPostCard extends StatefulWidget {
  final Map<String, dynamic> post;
  final VoidCallback onTap;

  const FeedPostCard({
    super.key,
    required this.post,
    required this.onTap,
  });

  @override
  State<FeedPostCard> createState() => _FeedPostCardState();
}

class _FeedPostCardState extends State<FeedPostCard> {
  late bool _isLiked;
  late int _likesCount;
  late int _commentsCount;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.post['is_liked'] ?? false;
    _likesCount = widget.post['likes_count'] ?? 0;
    _commentsCount = widget.post['comments_count'] ?? 0;
    _recordView();
  }

  // ───────────────── RECORD VIEW ─────────────────

  Future<void> _recordView() async {
    final token = await StorageService.getToken();
    if (token == null) return;

    await http.post(
      Uri.parse('${ApiConstants.baseUrl}/posts/${widget.post['id']}/view/'),
      headers: {'Authorization': 'Token $token'},
    );
  }

  // ───────────────── LIKE TOGGLE ─────────────────

  Future<void> _toggleLike() async {
    if (_processing) return;

    setState(() {
      _processing = true;
      _isLiked = !_isLiked;
      _likesCount += _isLiked ? 1 : -1;
    });

    final token = await StorageService.getToken();
    final url = _isLiked
        ? '${ApiConstants.baseUrl}/posts/${widget.post['id']}/like/'
        : '${ApiConstants.baseUrl}/posts/${widget.post['id']}/unlike/';

    await http.post(
      Uri.parse(url),
      headers: {'Authorization': 'Token $token'},
    );

    setState(() => _processing = false);
  }

  // ───────────────── COMMENTS ─────────────────

  Future<void> _openComments() async {
    final updated = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      builder: (_) => CommentsBottomSheet(
        postId: widget.post['id'],
        initialCount: _commentsCount,
      ),
    );

    if (updated != null) {
      setState(() => _commentsCount = updated);
    }
  }

  // ───────────────── SHARE ─────────────────

  void _openShare() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      isScrollControlled: true,
      builder: (_) => SharePostBottomSheet(
        post: widget.post,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final image = widget.post['image'] ?? '';
    final caption = widget.post['caption'] ?? '';
    final username = widget.post['author_username'] ?? 'User';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // USER HEADER
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              username,
              style: const TextStyle(
                color: Color(0xFF00FF7F),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // IMAGE
          GestureDetector(
            onTap: widget.onTap,
            child: CachedNetworkImage(
              imageUrl: image.isNotEmpty
                  ? image
                  : Constants.placeholderImagePath,
              fit: BoxFit.cover,
              width: double.infinity,
              height: 400,
            ),
          ),

          const SizedBox(height: 8),

          // ACTIONS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    _isLiked ? Icons.favorite : Icons.favorite_border,
                    color: _isLiked ? Colors.red : Colors.white,
                  ),
                  onPressed: _toggleLike,
                ),
                Text("$_likesCount",
                    style: const TextStyle(color: Colors.white)),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.comment, color: Colors.white),
                  onPressed: _openComments,
                ),
                Text("$_commentsCount",
                    style: const TextStyle(color: Colors.white)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.white),
                  onPressed: _openShare,
                ),
              ],
            ),
          ),

          // CAPTION
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              caption,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
