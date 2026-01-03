import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../config/constants.dart';
import '../../services/constants.dart';
import '../../services/storage_service.dart';
import '../../services/kitsu_api.dart';

class PostDetailModal extends StatefulWidget {
  final Map<String, dynamic> post;
  final String heroTag;
  final VoidCallback onDelete;
  final VoidCallback onUpdate;

  const PostDetailModal({
    super.key,
    required this.post,
    required this.heroTag,
    required this.onDelete,
    required this.onUpdate,
  });

  @override
  State<PostDetailModal> createState() => _PostDetailModalState();
}

class _PostDetailModalState extends State<PostDetailModal> {
  late final Map<String, dynamic> _post;
  late String _privacy;
  bool _deleting = false;

  /// ✅ FUTURE STORED ONCE (CRITICAL FIX)
  Future<List<Map<String, dynamic>>>? _animeFuture;

  @override
  void initState() {
    super.initState();
    _post = Map<String, dynamic>.from(widget.post);
    _privacy = _post['privacy'] ?? 'public';

    final animeTitle = _post['anime_title']?.toString().trim();
    if (animeTitle != null && animeTitle.isNotEmpty) {
      _animeFuture = KitsuApi.searchAnime(animeTitle);
    }
  }

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Delete Post?', style: TextStyle(color: Colors.white)),
        content: const Text('This cannot be undone.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF00FF7F))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true || _deleting) return;

    setState(() => _deleting = true);

    try {
      final token = await StorageService.getToken();
      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/posts/${_post['id']}/'),
        headers: {'Authorization': 'Token $token'},
      );

      if (!mounted) return;

      if (response.statusCode == 204) {
        Navigator.of(context, rootNavigator: true).pop();
        Future.microtask(widget.onDelete);
      } else {
        setState(() => _deleting = false);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _deleting = false);
    }
  }

  Future<void> _togglePrivacy() async {
    final next = _privacy == 'public' ? 'followers' : 'public';

    try {
      final token = await StorageService.getToken();
      final response = await http.patch(
        Uri.parse('${ApiConstants.baseUrl}/posts/${_post['id']}/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: '{"privacy":"$next"}',
      );

      if (response.statusCode == 200 && mounted) {
        setState(() => _privacy = next);
        widget.onUpdate();
      }
    } catch (_) {}
  }

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
            /// HEADER
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () =>
                        Navigator.of(context, rootNavigator: true).pop(),
                  ),
                  const Spacer(),
                  PopupMenuButton<String>(
                    color: Colors.grey[900],
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    onSelected: (v) =>
                    v == 'delete' ? _handleDelete() : _togglePrivacy(),
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 12),
                            Text('Delete Post',
                                style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'privacy',
                        child: Row(
                          children: [
                            Icon(
                              _privacy == 'public'
                                  ? Icons.public
                                  : Icons.lock,
                              color: const Color(0xFF00FF7F),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _privacy == 'public'
                                  ? 'Followers Only'
                                  : 'Public',
                              style: const TextStyle(
                                  color: Color(0xFF00FF7F)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            /// IMAGE
            Expanded(
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                width: double.infinity,
              ),
            ),

            /// FOOTER
            Container(
              padding: const EdgeInsets.all(20),
              color: const Color(0xFF111111),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    caption.isNotEmpty ? caption : 'No caption',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 14),

                  /// ✅ TAGGED ANIME (NOW STABLE)
                  if (_animeFuture != null && animeTitle != null)
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: _animeFuture,
                      builder: (context, snap) {
                        String thumb =
                            Constants.placeholderImagePath;

                        if (snap.hasData && snap.data!.isNotEmpty) {
                          thumb = snap.data!.first['attributes']
                          ['posterImage']['medium'] ??
                              thumb;
                        }

                        return Container(
                          constraints: BoxConstraints(
                            maxWidth:
                            MediaQuery.of(context).size.width * 0.75,
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                                color: const Color(0xFF00FF7F)),
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
                                  style: const TextStyle(
                                      color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          date,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        _privacy == 'public'
                            ? Icons.public
                            : Icons.lock_outline,
                        size: 16,
                        color: Colors.white54,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          _privacy == 'public'
                              ? 'Public'
                              : 'Followers Only',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
