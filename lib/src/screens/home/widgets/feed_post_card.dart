import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../config/constants.dart';
import '../../../services/constants.dart';
import '../../../services/storage_service.dart';
import '../../comments/comments_bottom_sheet.dart';
import '../../chat/share_post_bottom_sheet.dart';

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

  bool get _isThought => widget.post['post_type'] == 'thought';

  Future<List<Map<String, dynamic>>>? _animeFuture;

  @override
  void initState() {
    super.initState();

    _isLiked = widget.post['is_liked'] ?? false;
    _likesCount = widget.post['likes_count'] ?? 0;
    _commentsCount = widget.post['comments_count'] ?? 0;

    final animeId = widget.post['anime_id'];
    if (animeId != null) {
      _animeFuture = _fetchAnime(animeId);
    }

    if (!_isThought) {
      _recordView();
    }
  }

  // ───────────────── FETCH ANIME ─────────────────

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

  // ───────────────── RECORD VIEW ─────────────────

  Future<void> _recordView() async {
    final token = await StorageService.getToken();
    if (token == null) return;

    await http.post(
      Uri.parse('${ApiConstants.baseUrl}/posts/${widget.post['id']}/view/'),
      headers: {'Authorization': 'Token $token'},
    );
  }

  // ───────────────── LIKE ─────────────────

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

  // ───────────────── TIME FORMAT ─────────────────

  String _formatTime(String raw) {
    try {
      final date = DateTime.parse(raw).toLocal();
      final diff = DateTime.now().difference(date);

      if (diff.inSeconds < 60) return "${diff.inSeconds}s";
      if (diff.inMinutes < 60) return "${diff.inMinutes}m";
      if (diff.inHours < 24) return "${diff.inHours}h";
      if (diff.inDays < 7) return "${diff.inDays}d";

      return "${date.day}/${date.month}/${date.year}";
    } catch (_) {
      return "";
    }
  }

  // ───────────────── HEADER ─────────────────

  Widget _header() {
    final username = widget.post['author_username'] ?? 'User';
    final pfp = widget.post['author_pfp'] ?? '';
    final createdAt = widget.post['created_at'] ?? '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundImage: pfp.isNotEmpty
                ? CachedNetworkImageProvider(pfp)
                : const AssetImage(Constants.placeholderImagePath)
            as ImageProvider,
          ),
          const SizedBox(width: 10),
          Text(
            username,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            "· ${_formatTime(createdAt)}",
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────── IMAGE POST ─────────────────

  Widget _imagePost() {
    final image = widget.post['image'] ?? '';
    final caption = widget.post['caption'] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: widget.onTap,
          child: CachedNetworkImage(
            imageUrl: image.isNotEmpty
                ? image
                : Constants.placeholderImagePath,
            width: double.infinity,
            height: 420,
            fit: BoxFit.cover,
          ),
        ),
        if (caption.isNotEmpty) ...[
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              caption,
              style: const TextStyle(color: Colors.white),
            ),
          )
        ]
      ],
    );
  }

  // ───────────────── THOUGHT POST ─────────────────

  Widget _thoughtPost() {
    final caption = widget.post['caption'] ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Text(
          caption,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  // ───────────────── TAGGED ANIME ─────────────────

  Widget _taggedAnime() {
    final animeTitle = widget.post['anime_title'];

    if (animeTitle == null || _animeFuture == null) {
      return const SizedBox();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _animeFuture,
        builder: (context, snap) {
          String thumb = Constants.placeholderImagePath;

          if (snap.hasData && snap.data!.isNotEmpty) {
            thumb =
                snap.data!.first['attributes']['posterImage']['medium'] ??
                    thumb;
          }

          return ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: const Color(0xFF00FF7F)),
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ───────────────── ACTIONS ─────────────────

  Widget _actions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: _toggleLike,
            child: Row(
              children: [
                Icon(
                  _isLiked ? Icons.favorite : Icons.favorite_border,
                  color: _isLiked ? Colors.red : Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Text("$_likesCount",
                    style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          const SizedBox(width: 20),
          GestureDetector(
            onTap: _openComments,
            child: Row(
              children: [
                const Icon(Icons.mode_comment_outlined,
                    color: Colors.white, size: 20),
                const SizedBox(width: 6),
                Text("$_commentsCount",
                    style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _openShare,
            child: const Icon(Icons.send, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  // ───────────────── MAIN BUILD ─────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(),

        if (_isThought) _thoughtPost() else _imagePost(),

        const SizedBox(height: 12),

        _actions(),

        _taggedAnime(),

        const SizedBox(height: 18),

        Container(
          height: 0.6,
          color: Colors.white10,
        ),
      ],
    );
  }
}