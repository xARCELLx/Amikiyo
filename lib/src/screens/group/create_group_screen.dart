import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';

import '../../services/constants.dart';
import '../../services/storage_service.dart';
import '../../widgets/anime_search_modal.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _nameController = TextEditingController();
  final _aboutController = TextEditingController();
  final _searchController = TextEditingController();

  File? _groupImage;

  List<Map<String, dynamic>> _chatUsers = [];
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _selectedUsers = [];

  final Set<int> _selectedUserIds = {};

  Map<String, dynamic>? _selectedAnime;

  bool _loadingChats = true;
  bool _searching = false;
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    _loadChatUsers();
  }

  // ───────────────── IMAGE PICK ─────────────────

  Future<void> _pickImage() async {
    final picked =
    await ImagePicker().pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        _groupImage = File(picked.path);
      });
    }
  }

  // ───────────────── LOAD CHAT USERS ─────────────────

  Future<void> _loadChatUsers() async {
    try {
      final token = await StorageService.getToken();
      final myId = await StorageService.getUserId();
      if (token == null) return;

      final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/chat/my/'),
        headers: {'Authorization': 'Token $token'},
      );

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);

        final Map<int, Map<String, dynamic>> unique = {};

        for (final chat in data) {
          final user = chat['other_user'];
          if (user == null) continue;

          final int uid = user['id'];
          if (uid == myId) continue;

          unique[uid] = {
            'id': uid,
            'username': user['username'],
          };
        }

        setState(() {
          _chatUsers = unique.values.toList();
          _loadingChats = false;
        });
      }
    } catch (_) {
      setState(() => _loadingChats = false);
    }
  }

  // ───────────────── SEARCH USERS ─────────────────

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _searching = true);

    try {
      final token = await StorageService.getToken();
      if (token == null) return;

      final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/search-users/?username=$query'),
        headers: {'Authorization': 'Token $token'},
      );

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);

        setState(() {
          _searchResults = data
              .map((e) => {
            'id': e['user_id'],
            'username': e['username'],
          })
              .where((user) => !_selectedUserIds.contains(user['id']))
              .toList();
        });
      }
    } catch (_) {}

    setState(() => _searching = false);
  }

  // ───────────────── TOGGLE MEMBER ─────────────────

  void _toggleUser(Map<String, dynamic> user) {
    final int id = user['id'];

    setState(() {
      if (_selectedUserIds.contains(id)) {
        _selectedUserIds.remove(id);
        _selectedUsers.removeWhere((u) => u['id'] == id);
      } else {
        _selectedUserIds.add(id);
        _selectedUsers.add(user);
      }
    });
  }

  // ───────────────── CREATE GROUP ─────────────────

  Future<void> _createGroup() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Group name required")),
      );
      return;
    }

    setState(() => _creating = true);

    try {
      final token = await StorageService.getToken();
      if (token == null) return;

      final formData = FormData.fromMap({
        'name': name,
        'about': _aboutController.text.trim(),
        'anime_id': _selectedAnime?['id'],
        'anime_title': _selectedAnime?['title'],
        'member_ids': jsonEncode(_selectedUserIds.toList()),
        if (_groupImage != null)
          'image': await MultipartFile.fromFile(_groupImage!.path),
      });

      final response = await Dio().post(
        '${ApiConstants.baseUrl}/groups/create/',
        data: formData,
        options: Options(
          headers: {'Authorization': 'Token $token'},
        ),
      );

      if (response.statusCode == 201) {
        Navigator.pop(context, true);
      }
    } catch (_) {}

    setState(() => _creating = false);
  }

  // ───────────────── UI ─────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          "Create Group",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            // ── GROUP IMAGE ──
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[800],
                backgroundImage:
                _groupImage != null ? FileImage(_groupImage!) : null,
                child: _groupImage == null
                    ? const Icon(Icons.camera_alt,
                    color: Color(0xFF00FF7F), size: 30)
                    : null,
              ),
            ),
            const SizedBox(height: 20),

            // ── NAME ──
            _inputField(_nameController, "Group Name"),
            const SizedBox(height: 16),

            // ── ABOUT ──
            _inputField(_aboutController, "About (optional)", maxLines: 3),
            const SizedBox(height: 16),

            // ── ANIME TAG ──
            ListTile(
              tileColor: Colors.grey[900],
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              onTap: () async {
                final anime = await showAnimeSearchModal(context);
                if (anime != null) {
                  setState(() => _selectedAnime = anime);
                }
              },
              title: Text(
                _selectedAnime != null
                    ? _selectedAnime!['title']
                    : "Tag an anime (optional)",
                style: const TextStyle(color: Colors.white),
              ),
              trailing: _selectedAnime != null
                  ? IconButton(
                icon:
                const Icon(Icons.clear, color: Colors.red),
                onPressed: () =>
                    setState(() => _selectedAnime = null),
              )
                  : const Icon(Icons.arrow_forward_ios,
                  color: Color(0xFF00FF7F)),
            ),
            const SizedBox(height: 20),

            // ── SELECTED MEMBERS (SCROLLABLE LIST) ──
            if (_selectedUsers.isNotEmpty) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Selected Members",
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListView.builder(
                  itemCount: _selectedUsers.length,
                  itemBuilder: (_, i) {
                    final user = _selectedUsers[i];
                    return ListTile(
                      title: Text(
                        user['username'],
                        style:
                        const TextStyle(color: Colors.white),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle,
                            color: Colors.red),
                        onPressed: () => _toggleUser(user),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ── RECENT CHATS ──
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Recent Chats",
                style: TextStyle(color: Colors.white70),
              ),
            ),
            const SizedBox(height: 8),

            _loadingChats
                ? const CircularProgressIndicator(
              color: Color(0xFF00FF7F),
            )
                : Column(
              children: _chatUsers.map((user) {
                final selected =
                _selectedUserIds.contains(user['id']);
                return CheckboxListTile(
                  value: selected,
                  onChanged: (_) => _toggleUser(user),
                  title: Text(user['username'],
                      style: const TextStyle(
                          color: Colors.white)),
                  activeColor:
                  const Color(0xFF00FF7F),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // ── SEARCH USERS ──
            _inputField(_searchController, "Search users",
                onChanged: _searchUsers),

            if (_searching)
              const CircularProgressIndicator(
                  color: Color(0xFF00FF7F)),

            Column(
              children: _searchResults.map((user) {
                return ListTile(
                  title: Text(user['username'],
                      style:
                      const TextStyle(color: Colors.white)),
                  onTap: () => _toggleUser(user),
                );
              }).toList(),
            ),

            const SizedBox(height: 30),

            // ── CREATE BUTTON ──
            ElevatedButton(
              onPressed: _creating ? null : _createGroup,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00FF7F),
                minimumSize:
                const Size(double.infinity, 50),
              ),
              child: _creating
                  ? const CircularProgressIndicator(
                  color: Colors.black)
                  : const Text(
                "Create Group",
                style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputField(TextEditingController controller, String hint,
      {int maxLines = 1,
        Function(String)? onChanged}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
        const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: Colors.grey[900],
        border: OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}