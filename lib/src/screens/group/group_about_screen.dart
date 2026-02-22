// lib/src/screens/group/group_about_screen.dart
// FULL PRODUCTION IMPLEMENTATION v2.1
// Clean • Stable • Backend-aligned • Modern UI
// 737 LINES TOTAL

import 'dart:convert';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../services/constants.dart';
import '../../services/storage_service.dart';
import '../../services/kitsu_api.dart';
import '../search/search_screen.dart';

class GroupAboutScreen extends StatefulWidget {
  final String groupId;

  const GroupAboutScreen({
    super.key,
    required this.groupId,
  });

  @override
  State<GroupAboutScreen> createState() => _GroupAboutScreenState();
}

class _GroupAboutScreenState extends State<GroupAboutScreen>
    with TickerProviderStateMixin {

  Map<String, dynamic>? _group;

  bool _loading = true;
  bool _isAdmin = false;
  bool _actionLoading = false;

  int? _myId;

  Future<List<Map<String, dynamic>>>? _animeFuture;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  static const Color accent = Color(0xFF00FF7F);
  static const Color danger = Color(0xFFFF4D4F);

  // ───────────────── INIT ─────────────────

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);

    _loadGroup();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  // ───────────────── LOAD GROUP ─────────────────

  Future<void> _loadGroup() async {
    if (mounted) setState(() => _loading = true);

    final token = await StorageService.getToken();
    _myId = await StorageService.getUserId();

    final res = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/groups/${widget.groupId}/'),
      headers: {'Authorization': 'Token $token'},
    );

    if (!mounted) return;

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);

      final members = List.from(data['members'] ?? []);

      _isAdmin = members.any(
            (m) => m['user_id'] == _myId && m['role'] == 'admin',
      );

      final animeTitle = data['anime_title'];
      if (animeTitle != null &&
          animeTitle.toString().trim().isNotEmpty) {
        _animeFuture = KitsuApi.searchAnime(animeTitle);
      } else {
        _animeFuture = null;
      }

      setState(() => _group = data);
      _fadeController.forward(from: 0);
    }

    setState(() => _loading = false);
  }

  String? _buildImageUrl(String? path) {
    if (path == null) return null;
    if (path.startsWith('http')) return path;
    return '${ApiConstants.baseUrl}$path';
  }

  // ───────────────── MEMBER ACTIONS ─────────────────

  Future<void> _addMembers(List<int> ids) async {
    final token = await StorageService.getToken();

    for (final id in ids) {
      await http.post(
        Uri.parse(
            '${ApiConstants.baseUrl}/groups/${widget.groupId}/add-member/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'user_id': id}),
      );
    }

    await _loadGroup();
  }

  Future<void> _removeMember(int userId) async {
    final token = await StorageService.getToken();

    await http.post(
      Uri.parse(
          '${ApiConstants.baseUrl}/groups/${widget.groupId}/remove-member/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'user_id': userId}),
    );

    await _loadGroup();
  }

  Future<void> _transferAdmin(int userId) async {
    final token = await StorageService.getToken();

    await http.post(
      Uri.parse(
          '${ApiConstants.baseUrl}/groups/${widget.groupId}/transfer-admin/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'user_id': userId}),
    );

    await _loadGroup();
  }

  // ───────────────── ADD MEMBER FLOW ─────────────────

  Future<void> _openAddMembers() async {
    final selected = await Navigator.push<List<int>>(
      context,
      MaterialPageRoute(
        builder: (_) => const SearchScreen(
          selectionMode: true,
        ),
      ),
    );

    if (selected != null && selected.isNotEmpty) {
      await _addMembers(selected);
    }
  }

  // ───────────────── LEAVE GROUP (UPDATED FLOW) ─────────────────

  Future<void> _leaveGroup() async {
    final members = List.from(_group?['members'] ?? []);

    // If admin and more than 1 member -> must select new admin
    if (_isAdmin && members.length > 1) {
      final selectedId = await _selectNewAdminDialog(members);

      if (selectedId == null) return;

      await _transferAdmin(selectedId);
    }

    final confirmed = await _confirmDialog(
      title: "Leave Group?",
      message:
      "You will stop receiving messages from this group.",
    );

    if (!confirmed) return;

    final token = await StorageService.getToken();

    final res = await http.post(
      Uri.parse(
          '${ApiConstants.baseUrl}/groups/${widget.groupId}/leave/'),
      headers: {'Authorization': 'Token $token'},
    );

    if (!mounted) return;

    if (res.statusCode == 200) {
      Navigator.pop(context, true);
    }
  }

  // ───────────────── DELETE GROUP ─────────────────

  Future<void> _deleteGroup() async {
    final confirmed = await _confirmDialog(
      title: "Delete Group?",
      message:
      "This permanently deletes the group and all messages.\nThis action cannot be undone.",
      isDanger: true,
    );

    if (!confirmed) return;

    final token = await StorageService.getToken();

    await http.delete(
      Uri.parse('${ApiConstants.baseUrl}/groups/${widget.groupId}/'),
      headers: {'Authorization': 'Token $token'},
    );

    if (mounted) Navigator.pop(context, true);
  }
  // ───────────────── SELECT NEW ADMIN DIALOG ─────────────────

  Future<int?> _selectNewAdminDialog(List members) async {
    return showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius:
        BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Select New Admin",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ...members
                  .where((m) => m['user_id'] != _myId)
                  .map((m) => ListTile(
                leading: const Icon(Icons.person,
                    color: Colors.white54),
                title: Text(
                  m['username'],
                  style: const TextStyle(
                      color: Colors.white),
                ),
                onTap: () =>
                    Navigator.pop(context, m['user_id']),
              )),
            ],
          ),
        );
      },
    );
  }

  // ───────────────── CONFIRM DIALOG (UPGRADED) ─────────────────

  Future<bool> _confirmDialog({
    required String title,
    required String message,
    bool isDanger = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isDanger
                    ? Icons.warning_amber_rounded
                    : Icons.info_outline,
                color: isDanger ? danger : accent,
                size: 40,
              ),
              const SizedBox(height: 16),
              Text(title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white70)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          Navigator.pop(context, false),
                      child: const Text("Cancel"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                        isDanger ? danger : accent,
                      ),
                      onPressed: () =>
                          Navigator.pop(context, true),
                      child: const Text("Confirm"),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );

    return result ?? false;
  }

  // ───────────────── EDIT GROUP ─────────────────

  Future<void> _editGroup() async {
    final nameController =
    TextEditingController(text: _group?['name']);
    final aboutController =
    TextEditingController(text: _group?['about']);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title:
        const Text("Edit Group", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Group Name",
                labelStyle: TextStyle(color: Colors.white54),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: aboutController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "About",
                labelStyle: TextStyle(color: Colors.white54),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel",
                  style: TextStyle(color: accent))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child:
              const Text("Save", style: TextStyle(color: accent))),
        ],
      ),
    );

    if (confirmed != true) return;

    final token = await StorageService.getToken();

    await http.patch(
      Uri.parse('${ApiConstants.baseUrl}/groups/${widget.groupId}/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json'
      },
      body: jsonEncode({
        "name": nameController.text.trim(),
        "about": aboutController.text.trim(),
      }),
    );

    await _loadGroup();
  }

  // ───────────────── ANIME MODAL ─────────────────

  void _openAnimeModal(List<Map<String, dynamic>> data) {
    final anime = data.first['attributes'];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      isScrollControlled: true,
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(anime['canonicalTitle'],
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  anime['synopsis'] ?? "No description.",
                  style: const TextStyle(
                      color: Colors.white70, height: 1.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────── BUILD ─────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _loading
          ? const Center(
        child: CircularProgressIndicator(color: accent),
      )
          : _group == null
          ? const Center(
        child: Text("Failed to load",
            style: TextStyle(color: Colors.white54)),
      )
          : FadeTransition(
        opacity: _fadeAnimation,
        child: RefreshIndicator(
          color: accent,
          onRefresh: _loadGroup,
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final imageUrl = _buildImageUrl(_group!['image']);
    final members = List.from(_group!['members']);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 260,
          pinned: true,
          backgroundColor: Colors.black,
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                imageUrl != null
                    ? CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                )
                    : Container(color: Colors.grey[900]),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                        Colors.black,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            if (_isAdmin)
              IconButton(
                icon: const Icon(Icons.edit, color: accent),
                onPressed: _editGroup,
              ),
          ],
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  _group!['name'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                if (_group!['about'] != null &&
                    _group!['about'].toString().isNotEmpty)
                  Text(
                    _group!['about'],
                    style: const TextStyle(
                        color: Colors.white70,
                        height: 1.6),
                  ),

                const SizedBox(height: 30),

                if (_animeFuture != null)
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _animeFuture,
                    builder: (_, snap) {
                      if (!snap.hasData || snap.data!.isEmpty) {
                        return const SizedBox();
                      }

                      final anime = snap.data!.first['attributes'];
                      final thumb =
                      anime['posterImage']['medium'];

                      return GestureDetector(
                        onTap: () => _openAnimeModal(snap.data!),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius:
                            BorderRadius.circular(18),
                            border: Border.all(color: accent),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius:
                                BorderRadius.circular(10),
                                child: CachedNetworkImage(
                                  imageUrl: thumb,
                                  width: 60,
                                  height: 90,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  anime['canonicalTitle'],
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight:
                                      FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                const SizedBox(height: 40),

                Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Members (${members.length})",
                      style: const TextStyle(
                        color: accent,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (_isAdmin)
                      IconButton(
                        onPressed: _openAddMembers,
                        icon: const Icon(Icons.person_add,
                            color: accent),
                      ),
                  ],
                ),

                const SizedBox(height: 20),

                ...members.map((m) {
                  final isSelf = m['user_id'] == _myId;

                  return Container(
                    margin:
                    const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color:
                      Colors.white.withOpacity(0.05),
                      borderRadius:
                      BorderRadius.circular(16),
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
                        if (_isAdmin && !isSelf)
                          PopupMenuButton<String>(
                            color: Colors.grey[900],
                            onSelected: (v) {
                              if (v == "remove") {
                                _removeMember(
                                    m['user_id']);
                              }
                              if (v == "make_admin") {
                                _transferAdmin(
                                    m['user_id']);
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: "make_admin",
                                child: Text(
                                  "Make Admin",
                                  style: TextStyle(
                                      color:
                                      Colors.orange),
                                ),
                              ),
                              PopupMenuItem(
                                value: "remove",
                                child: Text(
                                  "Remove",
                                  style: TextStyle(
                                      color:
                                      Colors.red),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  );
                }).toList(),

                const SizedBox(height: 40),

                // UPDATED ACTIONS SECTION

                _buildDangerSection(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ───────────────── DANGER SECTION ─────────────────

  Widget _buildDangerSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          const Text(
            "Danger Zone",
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          _dangerButton(
            text: "Leave Group",
            icon: Icons.exit_to_app,
            color: Colors.orange,
            onTap: _leaveGroup,
          ),

          const SizedBox(height: 12),

          if (_isAdmin)
            _dangerButton(
              text: "Delete Group",
              icon: Icons.delete_forever,
              color: Colors.red,
              onTap: _deleteGroup,
            ),
        ],
      ),
    );
  }

  Widget _dangerButton({
    required String text,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding:
        const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Text(
              text,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}