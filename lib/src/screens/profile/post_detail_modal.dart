// lib/src/screens/profile/post_detail_modal.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../config/constants.dart';
import '../../services/constants.dart';
import '../../services/storage_service.dart';
import '../../services/kitsu_api.dart';  // ← ADDED KITSU API IMPORT

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
  late String currentPrivacy;

  @override
  void initState() {
    super.initState();
    currentPrivacy = widget.post['privacy'] ?? 'public';
  }

  Future<void> _deletePost() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Delete Post?', style: TextStyle(color: Colors.white)),
        content: const Text('This cannot be undone.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel', style: TextStyle(color: Color(0xFF00FF7F)))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final token = await StorageService.getToken();
      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/posts/${widget.post['id']}/'),
        headers: {'Authorization': 'Token $token'},
      );

      if (response.statusCode == 204) {
        widget.onDelete();
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _togglePrivacy() async {
    final newPrivacy = currentPrivacy == 'public' ? 'followers' : 'public';
    try {
      final token = await StorageService.getToken();
      final response = await http.patch(
        Uri.parse('${ApiConstants.baseUrl}/posts/${widget.post['id']}/'),
        headers: {'Authorization': 'Token $token', 'Content-Type': 'application/json'},
        body: '{"privacy": "$newPrivacy"}',
      );

      if (response.statusCode == 200 && mounted) {
        setState(() => currentPrivacy = newPrivacy);
        widget.onUpdate();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.post['image'] ?? '';
    final caption = (widget.post['caption'] ?? '').toString().trim();
    final animeTitle = widget.post['anime_title']?.toString().trim();
    final date = DateFormat('MMM d, yyyy • h:mm a').format(DateTime.parse(widget.post['created_at']));

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  color: Colors.grey[900],
                  onSelected: (v) => v == 'delete' ? _deletePost() : _togglePrivacy(),
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [Icon(Icons.delete, color: Colors.red), SizedBox(width: 12), Text('Delete Post', style: TextStyle(color: Colors.red))]),
                    ),
                    PopupMenuItem(
                      value: 'privacy',
                      child: Row(
                        children: [
                          Icon(currentPrivacy == 'public' ? Icons.public : Icons.lock, color: Color(0xFF00FF7F)),
                          const SizedBox(width: 12),
                          Text(currentPrivacy == 'public' ? 'Followers Only' : 'Public', style: const TextStyle(color: Color(0xFF00FF7F))),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Main Image
          Expanded(
            child: Hero(
              tag: widget.heroTag,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                width: double.infinity,
                placeholder: (_, __) => const Center(child: CircularProgressIndicator(color: Color(0xFF00FF7F))),
              ),
            ),
          ),

          // Caption + Anime + Meta
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(color: Color(0xFF111111)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Caption
                if (caption.isNotEmpty)
                  Text(
                    caption,
                    style: const TextStyle(color: Colors.white, fontSize: 18, height: 1.5, fontWeight: FontWeight.w500),
                  )
                else
                  const Text('No caption', style: TextStyle(color: Colors.white38, fontStyle: FontStyle.italic)),

                const SizedBox(height: 16),

                // Anime Tag — FIXED: Use Kitsu API to fetch thumbnail
                if (animeTitle != null && animeTitle.isNotEmpty)
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: KitsuApi.searchAnime(animeTitle),
                    builder: (context, snapshot) {
                      String thumbnailUrl = Constants.placeholderImagePath;
                      if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                        final anime = snapshot.data!.first;
                        thumbnailUrl = anime['attributes']['posterImage']['medium'] ?? Constants.placeholderImagePath;
                      }

                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF00FF7F), width: 1.5),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.tag, color: Color(0xFF00FF7F), size: 20),
                            const SizedBox(width: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: thumbnailUrl,
                                width: 40,
                                height: 56,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const CircularProgressIndicator(
                                  color: Color(0xFF00FF7F),
                                ),
                                errorWidget: (context, url, error) {
                                  debugPrint('Post anime thumbnail failed: $url, error: $error');
                                  return Image.asset(
                                    Constants.placeholderImagePath,
                                    width: 40,
                                    height: 56,
                                    fit: BoxFit.cover,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Tagged Anime',
                                    style: TextStyle(
                                      color: Color(0xFF00FF7F),
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    animeTitle,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                // Date + Privacy
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        date,
                        style: const TextStyle(color: Colors.white38, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          currentPrivacy == 'public' ? Icons.public : Icons.lock_outline,
                          color: Colors.white54,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          currentPrivacy == 'public' ? 'Public' : 'Followers Only',
                          style: const TextStyle(color: Colors.white54, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}