// lib/src/screens/comments/comments_bottom_sheet.dart

import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../services/constants.dart';
import '../../services/storage_service.dart';

class CommentsBottomSheet extends StatefulWidget {
  final int postId;
  final int initialCount;

  const CommentsBottomSheet({
    super.key,
    required this.postId,
    required this.initialCount,
  });

  @override
  State<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<CommentsBottomSheet> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _comments = [];
  bool _loading = true;
  bool _posting = false;

  late int _commentCount;

  @override
  void initState() {
    super.initState();
    _commentCount = widget.initialCount;
    _fetchComments();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ───────────────── FETCH COMMENTS ─────────────────

  Future<void> _fetchComments() async {
    try {
      final token = await StorageService.getToken();
      final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/posts/${widget.postId}/comments/'),
        headers: {'Authorization': 'Token $token'},
      );

      if (res.statusCode == 200) {
        final List list = jsonDecode(res.body);
        setState(() {
          _comments = list.cast<Map<String, dynamic>>();
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  // ───────────────── ADD COMMENT ─────────────────

  Future<void> _addComment() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _posting) return;

    setState(() => _posting = true);

    try {
      final token = await StorageService.getToken();
      final res = await http.post(
        Uri.parse(
            '${ApiConstants.baseUrl}/posts/${widget.postId}/comments/add/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'text': text}),
      );

      if (res.statusCode == 201) {
        final comment = jsonDecode(res.body);

        setState(() {
          _comments.insert(0, Map<String, dynamic>.from(comment));
          _commentCount++;
          _controller.clear();
        });

        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (_) {}
    finally {
      if (mounted) {
        setState(() => _posting = false);
      }
    }
  }

  // ───────────────── DELETE COMMENT ─────────────────

  Future<void> _deleteComment(int commentId, int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Delete comment?',
            style: TextStyle(color: Colors.white)),
        content: const Text('This cannot be undone.',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:
            const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
            const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final token = await StorageService.getToken();
      final res = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/comments/$commentId/delete/'),
        headers: {'Authorization': 'Token $token'},
      );

      if (res.statusCode == 204) {
        setState(() {
          _comments.removeAt(index);
          _commentCount--;
        });
      }
    } catch (_) {}
  }

  // ───────────────── AVATAR BUILDER (FIXED) ─────────────────

  Widget _buildAvatar(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return const CircleAvatar(
        radius: 18,
        backgroundImage:
        AssetImage('assets/images/placeholder_image.png'),
      );
    }

    return CircleAvatar(
      radius: 18,
      backgroundImage: CachedNetworkImageProvider(imageUrl),
    );
  }

  // ───────────────── UI ─────────────────

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _commentCount);
        return false;
      },
      child: Container(
        height: MediaQuery.of(context).size.height * 0.75,
        padding: const EdgeInsets.only(top: 12),
        decoration: const BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // HEADER
            const Text(
              'Comments',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const Divider(color: Colors.white12),

            // LIST
            Expanded(
              child: _loading
                  ? const Center(
                child: CircularProgressIndicator(
                    color: Color(0xFF00FF7F)),
              )
                  : _comments.isEmpty
                  ? const Center(
                child: Text(
                  'No comments yet',
                  style: TextStyle(color: Colors.white54),
                ),
              )
                  : ListView.builder(
                controller: _scrollController,
                reverse: true,
                itemCount: _comments.length,
                itemBuilder: (_, i) {
                  final c = _comments[i];

                  final username =
                      c['username']?.toString() ?? 'User';
                  final text =
                      c['text']?.toString() ?? '';
                  final createdAt = c['created_at'] != null
                      ? DateFormat('MMM d').format(
                      DateTime.parse(
                          c['created_at'].toString()))
                      : '';

                  return ListTile(
                    leading:
                    _buildAvatar(c['profile_image']),
                    title: Text(
                      username,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      text,
                      style: const TextStyle(
                          color: Colors.white70),
                    ),
                    trailing: c['is_owner'] == true
                        ? IconButton(
                      icon: const Icon(Icons.delete,
                          color: Colors.red, size: 18),
                      onPressed: () =>
                          _deleteComment(c['id'], i),
                    )
                        : Text(
                      createdAt,
                      style: const TextStyle(
                          color: Colors.white38),
                    ),
                  );
                },
              ),
            ),

            // INPUT
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style:
                      const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Add a comment...',
                        hintStyle:
                        TextStyle(color: Colors.white38),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: _posting
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF00FF7F)),
                    )
                        : const Icon(Icons.send,
                        color: Color(0xFF00FF7F)),
                    onPressed: _posting ? null : _addComment,
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



