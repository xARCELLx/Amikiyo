import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';

import '../../services/constants.dart';
import '../../services/storage_service.dart';
import '../../services/kitsu_api.dart';

class GroupAboutScreen extends StatefulWidget {
  final String groupId;

  const GroupAboutScreen({super.key, required this.groupId});

  @override
  State<GroupAboutScreen> createState() => _GroupAboutScreenState();
}

class _GroupAboutScreenState extends State<GroupAboutScreen> {
  Map<String, dynamic>? _group;
  bool _loading = true;
  bool _isAdmin = false;

  Future<List<Map<String, dynamic>>>? _animeFuture;

  // ───────────────── INIT ─────────────────

  @override
  void initState() {
    super.initState();
    _loadGroup();
  }

  // ───────────────── IMAGE URL BUILDER ─────────────────

  String? _buildImageUrl(String? imagePath) {
    if (imagePath == null) return null;
    if (imagePath.startsWith('http')) return imagePath;
    return "${ApiConstants.baseUrl}$imagePath";
  }

  // ───────────────── LOAD GROUP ─────────────────

  Future<void> _loadGroup() async {
    setState(() => _loading = true);

    try {
      final token = await StorageService.getToken();
      final myId = await StorageService.getUserId();

      final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/groups/${widget.groupId}/'),
        headers: {'Authorization': 'Token $token'},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        final members = List.from(data['members'] ?? []);

        final adminCheck = members.any((m) =>
        m['user_id'] == myId && m['role'] == 'admin');

        final animeTitle = data['anime_title']?.toString().trim();

        if (animeTitle != null && animeTitle.isNotEmpty) {
          _animeFuture = KitsuApi.searchAnime(animeTitle);
        }

        setState(() {
          _group = data;
          _isAdmin = adminCheck;
        });
      }
    } catch (_) {}

    setState(() => _loading = false);
  }

  // ───────────────── ANIME DESCRIPTION MODAL ─────────────────

  void _openAnimeModal(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return;

    final anime = data.first['attributes'];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      isScrollControlled: true,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: MediaQuery.of(context).size.height * 0.75,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                anime['canonicalTitle'],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    anime['synopsis'] ?? 'No description available.',
                    style: const TextStyle(
                        color: Colors.white70, height: 1.5),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ───────────────── LEAVE / DELETE ─────────────────

  Future<void> _leaveGroup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          "Leave Group?",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "You will no longer receive messages from this group.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Color(0xFF00FF7F)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Leave",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final token = await StorageService.getToken();
      if (token == null) return;

      final res = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/groups/${widget.groupId}/leave/'),
        headers: {'Authorization': 'Token $token'},
      );

      if (!mounted) return;

      if (res.statusCode == 200 || res.statusCode == 204) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to leave group"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteGroup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          "Delete Group?",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "This will permanently delete the group, all messages, and remove all members.\n\nThis action cannot be undone.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Color(0xFF00FF7F)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final token = await StorageService.getToken();
      if (token == null) return;

      final res = await http.delete(
        // 🔥 USE STANDARD DRF DELETE ROUTE
        Uri.parse('${ApiConstants.baseUrl}/groups/${widget.groupId}/'),
        headers: {'Authorization': 'Token $token'},
      );

      if (!mounted) return;

      if (res.statusCode == 204 || res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Group deleted successfully"),
            backgroundColor: Colors.red,
          ),
        );

        Navigator.pop(context, true); // go back & refresh list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                "Failed to delete group (${res.statusCode})"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ───────────────── UI ─────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _loading
          ? const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF00FF7F),
        ),
      )
          : _group == null
          ? const Center(
        child: Text(
          "Failed to load group",
          style: TextStyle(color: Colors.white54),
        ),
      )
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    final imageUrl = _buildImageUrl(_group!['image']);
    final members = List.from(_group!['members'] ?? []);

    return CustomScrollView(
      slivers: [

        // ───────── HEADER ─────────

        SliverAppBar(
          expandedHeight: 260,
          pinned: true,
          backgroundColor: Colors.black,
          flexibleSpace: FlexibleSpaceBar(
            background: imageUrl != null
                ? CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
            )
                : Container(color: Colors.grey[900]),
          ),
        ),

        // ───────── BODY ─────────

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // NAME
                Text(
                  _group!['name'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                // ABOUT
                if (_group!['about'] != null &&
                    _group!['about'].toString().isNotEmpty)
                  Text(
                    _group!['about'],
                    style: const TextStyle(
                      color: Colors.white70,
                      height: 1.5,
                    ),
                  ),

                const SizedBox(height: 20),

                // TAGGED ANIME
                if (_animeFuture != null)
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _animeFuture,
                    builder: (context, snap) {
                      if (!snap.hasData || snap.data!.isEmpty) {
                        return const SizedBox();
                      }

                      final anime = snap.data!.first['attributes'];
                      final thumb =
                      anime['posterImage']['medium'];

                      return GestureDetector(
                        onTap: () =>
                            _openAnimeModal(snap.data!),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color:
                                const Color(0xFF00FF7F)),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius:
                                BorderRadius.circular(8),
                                child: CachedNetworkImage(
                                  imageUrl: thumb,
                                  width: 50,
                                  height: 70,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  anime['canonicalTitle'],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight:
                                    FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                const SizedBox(height: 30),

                // MEMBERS HEADER
                Text(
                  "Members (${_group!['members_count']})",
                  style: const TextStyle(
                    color: Color(0xFF00FF7F),
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                // MEMBERS LIST
                ListView.builder(
                  shrinkWrap: true,
                  physics:
                  const NeverScrollableScrollPhysics(),
                  itemCount: members.length,
                  itemBuilder: (_, i) {
                    final m = members[i];

                    return Container(
                      margin:
                      const EdgeInsets.only(bottom: 10),
                      padding:
                      const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white
                            .withOpacity(0.05),
                        borderRadius:
                        BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.person,
                              color: Colors.white54),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              m['username'],
                              style: const TextStyle(
                                  color: Colors.white),
                            ),
                          ),
                          if (m['role'] == 'admin')
                            Container(
                              padding:
                              const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange
                                    .withOpacity(0.2),
                                borderRadius:
                                BorderRadius.circular(
                                    20),
                              ),
                              child: const Text(
                                "ADMIN",
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 30),

                // ACTION BUTTONS
                if (!_isAdmin)
                  _buildActionButton(
                      "Leave Group", Colors.red, _leaveGroup),

                if (_isAdmin)
                  _buildActionButton(
                      "Delete Group", Colors.red, _deleteGroup),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
      String text, Color color, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding:
          const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius:
              BorderRadius.circular(14)),
        ),
        onPressed: onTap,
        child: Text(text,style:TextStyle(color: Colors.white),),
      ),
    );
  }
}