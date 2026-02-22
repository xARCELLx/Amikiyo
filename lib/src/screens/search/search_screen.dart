import 'dart:async';
import 'dart:convert';

import 'package:amikiyo/src/screens/profile/profile_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../config/constants.dart';
import '../../services/constants.dart';
import '../../services/storage_service.dart';

class SearchScreen extends StatefulWidget {
  /// When true:
  /// - Allows multi selection
  /// - Returns List<int> of selected user_ids
  /// - Does NOT navigate to profile
  final bool selectionMode;

  const SearchScreen({
    super.key,
    this.selectionMode = false,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();

  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;
  Timer? _debounce;

  /// Used only in selection mode
  final Set<int> _selectedUsers = {};

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  // ───────────────── SEARCH LOGIC ─────────────────

  Future<void> _onSearchChanged(String query) async {
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
    }

    _debounce = Timer(const Duration(milliseconds: 450), () async {
      if (!mounted) return;

      if (query.trim().isEmpty) {
        setState(() {
          _results = [];
          _isLoading = false;
        });
        return;
      }

      setState(() => _isLoading = true);

      try {
        final token = await StorageService.getToken();

        final response = await http.get(
          Uri.parse(
              '${ApiConstants.baseUrl}/profiles/search/?username=${query.trim()}'),
          headers: {'Authorization': 'Token $token'},
        );

        if (!mounted) return;

        if (response.statusCode == 200) {
          final List<dynamic> data = jsonDecode(response.body);

          setState(() {
            _results = data.cast<Map<String, dynamic>>();
            _isLoading = false;
          });

          _fadeController.forward(from: 0);
        } else {
          setState(() {
            _results = [];
            _isLoading = false;
          });
        }
      } catch (_) {
        if (!mounted) return;

        setState(() {
          _results = [];
          _isLoading = false;
        });
      }
    });
  }

  // ───────────────── UI ─────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(),
      floatingActionButton: widget.selectionMode
          ? _buildSelectionFAB()
          : null,
      body: _buildBody(),
    );
  }

  // ───────────────── APP BAR ─────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.black,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: TextField(
        controller: _controller,
        autofocus: true,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: widget.selectionMode
              ? "Search users to add..."
              : "Search users...",
          hintStyle: const TextStyle(color: Colors.white54),
          border: InputBorder.none,
        ),
        onChanged: _onSearchChanged,
      ),
    );
  }

  // ───────────────── BODY ─────────────────

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF00FF7F),
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Text(
          _controller.text.isEmpty
              ? (widget.selectionMode
              ? "Search users to add"
              : "Type to search users")
              : "No users found",
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 16,
          ),
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ListView.builder(
        itemCount: _results.length,
        itemBuilder: (context, index) {
          final user = _results[index];

          final username = user['username'] ?? 'Unknown';
          final profileImage =
              user['profile_image'] ?? Constants.defaultProfilePath;

          final userId = user['user_id'];

          return _buildUserTile(
            userId: userId,
            username: username,
            profileImage: profileImage,
          );
        },
      ),
    );
  }

  // ───────────────── USER TILE ─────────────────

  Widget _buildUserTile({
    required int userId,
    required String username,
    required String profileImage,
  }) {
    final isSelected = _selectedUsers.contains(userId);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF00FF7F).withOpacity(0.15)
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? const Color(0xFF00FF7F)
              : Colors.white.withOpacity(0.05),
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          radius: 24,
          backgroundImage: CachedNetworkImageProvider(profileImage),
        ),
        title: Text(
          username,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '@$username',
          style: const TextStyle(color: Colors.white54),
        ),
        trailing: widget.selectionMode
            ? Checkbox(
          value: isSelected,
          activeColor: const Color(0xFF00FF7F),
          checkColor: Colors.black,
          onChanged: (_) => _toggleSelection(userId),
        )
            : null,
        onTap: () {
          if (widget.selectionMode) {
            _toggleSelection(userId);
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProfileScreen(
                  userId: userId,
                ),
              ),
            );
          }
        },
      ),
    );
  }

  // ───────────────── SELECTION LOGIC ─────────────────

  void _toggleSelection(int userId) {
    setState(() {
      if (_selectedUsers.contains(userId)) {
        _selectedUsers.remove(userId);
      } else {
        _selectedUsers.add(userId);
      }
    });
  }

  // ───────────────── FAB (RETURN SELECTED) ─────────────────

  Widget _buildSelectionFAB() {
    return FloatingActionButton.extended(
      backgroundColor: const Color(0xFF00FF7F),
      onPressed: _selectedUsers.isEmpty
          ? null
          : () {
        Navigator.pop(
          context,
          _selectedUsers.toList(),
        );
      },
      icon: const Icon(Icons.check, color: Colors.black),
      label: Text(
        "Add (${_selectedUsers.length})",
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}