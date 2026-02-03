// lib/src/screens/profile/post_detail_modal.dart

import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../config/constants.dart';
import '../../services/constants.dart';
import '../../services/storage_service.dart';
import '../../services/kitsu_api.dart';

// 👇 REQUIRED: your existing comments bottom sheet
// adjust path ONLY if your file lives elsewhere
import '../chat/share_post_bottom_sheet.dart';
import '../comments/comments_bottom_sheet.dart';

class PostDetailModal extends StatefulWidget {
  final Map<String, dynamic> post;
  final String heroTag;

  /// callbacks stay OPTIONAL
  final VoidCallback? onDelete;
  final VoidCallback? onUpdate;

  const PostDetailModal({
    super.key,
    required this.post,
    required this.heroTag,
    this.onDelete,
    this.onUpdate,
  });

  @override
  State<PostDetailModal> createState() => _PostDetailModalState();
}

class _PostDetailModalState extends State<PostDetailModal> {
  // ───────────────── CORE POST STATE ─────────────────

  late final Map<String, dynamic> _post;
  late String _privacy;

  bool _deleting = false;
  bool _isOwner = false;
  bool _ownershipResolved = false;

  /// cached anime search (no refetch spam)
  Future<List<Map<String, dynamic>>>? _animeFuture;

  // ───────────────── LIKE STATE ─────────────────

  bool _isLiked = false;
  int _likesCount = 0;
  bool _likeProcessing = false;

  // ───────────────── COMMENT STATE ─────────────────

  int _commentsCount = 0;

  // ───────────────── INIT ─────────────────

  @override
  void initState() {
    super.initState();

    _post = Map<String, dynamic>.from(widget.post);
    _privacy = _post['privacy'] ?? 'public';

    // hydrate metadata
    _isLiked = _post['is_liked'] ?? false;
    _likesCount = _post['likes_count'] ?? 0;
    _commentsCount = _post['comments_count'] ?? 0;

    _resolveOwnership();

    final animeTitle = _post['anime_title']?.toString().trim();
    if (animeTitle != null && animeTitle.isNotEmpty) {
      _animeFuture = KitsuApi.searchAnime(animeTitle);
    }
  }

  // ───────────────── OWNERSHIP ─────────────────

  Future<void> _resolveOwnership() async {
    try {
      final myId = await StorageService.getUserId();
      final authorUserId = _post['author_user_id'];

      if (myId != null &&
          authorUserId != null &&
          myId == authorUserId) {
        _isOwner = true;
      }
    } catch (_) {
      _isOwner = false;
    }

    if (mounted) {
      setState(() => _ownershipResolved = true);
    }
  }

  // ───────────────── DELETE ─────────────────

  Future<void> _handleDelete() async {
    if (!_isOwner || _deleting) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Delete Post?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF00FF7F)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _deleting = true);

    try {
      final token = await StorageService.getToken();
      final res = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/posts/${_post['id']}/'),
        headers: {'Authorization': 'Token $token'},
      );

      if (!mounted) return;

      if (res.statusCode == 204) {
        Navigator.of(context, rootNavigator: true).pop();
        widget.onDelete?.call();
      } else {
        setState(() => _deleting = false);
      }
    } catch (_) {
      if (mounted) setState(() => _deleting = false);
    }
  }

  // ───────────────── PRIVACY ─────────────────

  Future<void> _togglePrivacy() async {
    if (!_isOwner) return;

    final next = _privacy == 'public' ? 'followers' : 'public';

    try {
      final token = await StorageService.getToken();
      final res = await http.patch(
        Uri.parse('${ApiConstants.baseUrl}/posts/${_post['id']}/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: '{"privacy":"$next"}',
      );

      if (res.statusCode == 200 && mounted) {
        setState(() => _privacy = next);
        widget.onUpdate?.call();
      }
    } catch (_) {}
  }

  // ───────────────── LIKE / UNLIKE ─────────────────

  Future<void> _toggleLike() async {
    if (_likeProcessing) return;

    final prevLiked = _isLiked;
    final prevCount = _likesCount;

    setState(() {
      _likeProcessing = true;
      _isLiked = !_isLiked;
      _likesCount += _isLiked ? 1 : -1;
    });

    try {
      final token = await StorageService.getToken();
      final url = _isLiked
          ? '${ApiConstants.baseUrl}/posts/${_post['id']}/like/'
          : '${ApiConstants.baseUrl}/posts/${_post['id']}/unlike/';

      final res = await http.post(
        Uri.parse(url),
        headers: {'Authorization': 'Token $token'},
      );

      if (res.statusCode != 200 && mounted) {
        setState(() {
          _isLiked = prevLiked;
          _likesCount = prevCount;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLiked = prevLiked;
          _likesCount = prevCount;
        });
      }
    }

    if (mounted) {
      setState(() => _likeProcessing = false);
    }
  }

  // ───────────────── COMMENTS (REAL INTEGRATION) ─────────────────

  Future<void> _openComments() async {
    final updatedCount = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      builder: (_) => CommentsBottomSheet(
        postId: _post['id'],
        initialCount: _commentsCount,
      ),
    );

    // 👇 sync count when comments sheet closes
    if (updatedCount != null && mounted) {
      setState(() {
        _commentsCount = updatedCount;
      });
    }
  }

  Future<void> _openShareSheet() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      isScrollControlled: true,
      builder: (_) => SharePostBottomSheet(
        post: _post, // ✅ FULL POST MAP
      ),
    );
  }





  // ───────────────── UI ─────────────────

  @override
  Widget build(BuildContext context) {
    final imageUrl = _post['image'] ?? '';
    final caption = (_post['caption'] ?? '').toString().trim();
    final animeTitle = _post['anime_title']?.toString().trim();

    final date = DateFormat('MMM d, yyyy • h:mm a')
        .format(DateTime.parse(_post['created_at']));

    return SafeArea(
      top: false,
      child: Material(
        color: Colors.black,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: Column(
          children: [
            _buildHeader(),
            _buildImageWithActions(imageUrl),
            _buildFooter(caption, animeTitle, date),
          ],
        ),
      ),
    );
  }

  // ───────────────── HEADER ─────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () =>
                Navigator.of(context, rootNavigator: true).pop(),
          ),
          const Spacer(),
          if (_ownershipResolved && _isOwner)
            PopupMenuButton<String>(
              color: Colors.grey[900],
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (v) {
                if (v == 'delete') _handleDelete();
                if (v == 'privacy') _togglePrivacy();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete Post',
                      style: TextStyle(color: Colors.red)),
                ),
                PopupMenuItem(
                  value: 'privacy',
                  child: Text(
                    _privacy == 'public'
                        ? 'Followers Only'
                        : 'Public',
                    style:
                    const TextStyle(color: Color(0xFF00FF7F)),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ───────────────── IMAGE + ACTIONS ─────────────────

  Widget _buildImageWithActions(String imageUrl) {
    return Expanded(
      child: Stack(
        children: [
          CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.contain,
            width: double.infinity,
          ),
          Positioned(
            right: 12,
            bottom: 24,
            child: Column(
              children: [
                IconButton(
                  icon: Icon(
                    _isLiked
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color:
                    _isLiked ? Colors.red : Colors.white,
                  ),
                  onPressed: _toggleLike,
                ),
                Text('$_likesCount',
                    style:
                    const TextStyle(color: Colors.white)),
                const SizedBox(height: 16),
                IconButton(
                  icon: const Icon(Icons.comment,
                      color: Colors.white),
                  onPressed: _openComments,
                ),
                Text('$_commentsCount',
                    style:
                    const TextStyle(color: Colors.white)),

                IconButton(
                  icon: const Icon(Icons.send, color: Colors.white),
                  onPressed: _openShareSheet,
                ),

              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────── FOOTER ─────────────────

  Widget _buildFooter(
      String caption, String? animeTitle, String date) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: const Color(0xFF111111),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            caption.isNotEmpty ? caption : 'No caption',
            style: const TextStyle(
                color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 14),
          if (_animeFuture != null && animeTitle != null)
            _buildTaggedAnime(animeTitle),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(date,
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 13)),
              ),
              Icon(
                _privacy == 'public'
                    ? Icons.public
                    : Icons.lock_outline,
                size: 16,
                color: Colors.white54,
              ),
              const SizedBox(width: 6),
              Text(
                _privacy == 'public'
                    ? 'Public'
                    : 'Followers Only',
                style: const TextStyle(
                    color: Colors.white54, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ───────────────── TAGGED ANIME ─────────────────

  Widget _buildTaggedAnime(String animeTitle) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _animeFuture,
      builder: (context, snap) {
        String thumb = Constants.placeholderImagePath;

        if (snap.hasData && snap.data!.isNotEmpty) {
          thumb = snap.data!.first['attributes']
          ['posterImage']['medium'] ??
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                    const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
