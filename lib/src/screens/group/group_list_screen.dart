import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';

import '../../services/constants.dart';
import '../../services/storage_service.dart';
import '../chat/chat_screen.dart';
import 'create_group_screen.dart';
import 'group_about_screen.dart';

class GroupListScreen extends StatefulWidget {
  const GroupListScreen({super.key});

  @override
  State<GroupListScreen> createState() => _GroupListScreenState();
}

class _GroupListScreenState extends State<GroupListScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _myGroups = [];
  List<Map<String, dynamic>> _searchResults = [];

  bool _loadingMyGroups = true;
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _loadMyGroups();
  }

  // ───────────────── IMAGE URL BUILDER ─────────────────

  String? _buildImageUrl(String? imagePath) {
    if (imagePath == null) return null;

    if (imagePath.startsWith('http')) {
      return imagePath;
    }

    return "${ApiConstants.baseUrl}$imagePath";
  }

  // ───────────────── LOAD MY GROUPS ─────────────────

  Future<void> _loadMyGroups() async {
    setState(() => _loadingMyGroups = true);

    try {
      final token = await StorageService.getToken();
      if (token == null) return;

      final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/groups/my/'),
        headers: {'Authorization': 'Token $token'},
      );

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        setState(() {
          _myGroups = data.cast<Map<String, dynamic>>();
        });
      }
    } catch (_) {}

    setState(() => _loadingMyGroups = false);
  }

  // ───────────────── SEARCH GROUPS ─────────────────

  Future<void> _searchGroups(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _searching = true);

    try {
      final token = await StorageService.getToken();
      if (token == null) return;

      final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/groups/search/?q=$query'),
        headers: {'Authorization': 'Token $token'},
      );

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        setState(() {
          _searchResults = data.cast<Map<String, dynamic>>();
        });
      }
    } catch (_) {}

    setState(() => _searching = false);
  }

  // ───────────────── REQUEST JOIN ─────────────────

  Future<void> _requestJoin(String groupId) async {
    final token = await StorageService.getToken();
    if (token == null) return;

    await http.post(
      Uri.parse('${ApiConstants.baseUrl}/groups/$groupId/request-join/'),
      headers: {'Authorization': 'Token $token'},
    );

    _searchGroups(_searchController.text);
  }

  // ───────────────── IMAGE PREVIEW MODAL ─────────────────

  void _showGroupImagePreview(Map<String, dynamic> group) {
    final imageUrl = _buildImageUrl(group['image']);
    if (imageUrl == null) return;

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: Container(color: Colors.black.withOpacity(0.5)),
              ),
              Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.85,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF00FF7F),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          width: double.infinity,
                          height: 300,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        group['name'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ───────────────── CREATE GROUP NAVIGATION ─────────────────

  Future<void> _openCreateGroup() async {
    final created = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CreateGroupScreen(),
      ),
    );

    if (created == true) {
      _loadMyGroups();
    }
  }

  // ───────────────── UI ─────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          "Groups",
          style: TextStyle(color: Colors.white),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF00FF7F),
        onPressed: _openCreateGroup,
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              onChanged: _searchGroups,
              decoration: InputDecoration(
                hintText: "Search groups...",
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.grey[900],
                prefixIcon:
                const Icon(Icons.search, color: Colors.white54),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: _searchController.text.isNotEmpty
                ? _buildSearchResults()
                : _buildMyGroups(),
          ),
        ],
      ),
    );
  }

  // ───────────────── MY GROUPS LIST ─────────────────

  Widget _buildMyGroups() {
    if (_loadingMyGroups) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF00FF7F),
        ),
      );
    }

    if (_myGroups.isEmpty) {
      return const Center(
        child: Text(
          "No groups joined yet",
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return ListView.builder(
      itemCount: _myGroups.length,
      itemBuilder: (_, i) {
        final group = _myGroups[i];
        final imageUrl = _buildImageUrl(group['image']);

        return ListTile(
          leading: GestureDetector(
            onTap: () => _showGroupImagePreview(group),
            child: CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey[800],
              backgroundImage:
              imageUrl != null ? CachedNetworkImageProvider(imageUrl) : null,
              child: imageUrl == null
                  ? const Icon(Icons.group, color: Colors.white)
                  : null,
            ),
          ),
          title: Text(
            group['name'],
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: group['anime_title'] != null
              ? Text(
            group['anime_title'],
            style: const TextStyle(color: Colors.white54),
          )
              : null,
          trailing: IconButton(
            icon: const Icon(Icons.info_outline,
                color: Color(0xFF00FF7F)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      GroupAboutScreen(groupId: group['id']),
                ),
              );
            },
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatScreen(
                  chatRoomId: group['id'],
                  title: group['name'],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ───────────────── SEARCH RESULTS LIST ─────────────────

  Widget _buildSearchResults() {
    if (_searching) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF00FF7F),
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return const Center(
        child: Text(
          "No groups found",
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (_, i) {
        final group = _searchResults[i];
        final imageUrl = _buildImageUrl(group['image']);
        final status = group['membership_status'];

        Widget trailing;

        if (status == "active") {
          trailing = const Text(
            "Joined",
            style: TextStyle(color: Colors.green),
          );
        } else if (status == "pending") {
          trailing = const Text(
            "Pending",
            style: TextStyle(color: Colors.orange),
          );
        } else {
          trailing = TextButton(
            onPressed: () => _requestJoin(group['id']),
            child: const Text(
              "Join",
              style: TextStyle(color: Color(0xFF00FF7F)),
            ),
          );
        }

        return ListTile(
          leading: CircleAvatar(
            radius: 24,
            backgroundColor: Colors.grey[800],
            backgroundImage:
            imageUrl != null ? CachedNetworkImageProvider(imageUrl) : null,
            child: imageUrl == null
                ? const Icon(Icons.group, color: Colors.white)
                : null,
          ),
          title: Text(
            group['name'],
            style: const TextStyle(color: Colors.white),
          ),
          subtitle: group['anime_title'] != null
              ? Text(
            group['anime_title'],
            style: const TextStyle(color: Colors.white54),
          )
              : null,
          trailing: trailing,
        );
      },
    );
  }
}