// lib/src/screens/search/search_screen.dart
import 'dart:async';
import 'dart:convert';

import 'package:amikiyo/src/screens/profile/profile_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../config/constants.dart';
import '../../services/constants.dart';
import '../../services/storage_service.dart';
import '../profile/other_user_profile_screen.dart';  // ← CHANGE TO YOUR OTHER USER PROFILE SCREEN PATH

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;
  Timer? _debounce;

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _onSearchChanged(String query) async {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.trim().isEmpty) {
        setState(() => _results = []);
        return;
      }

      setState(() => _isLoading = true);

      try {
        final token = await StorageService.getToken();
        final response = await http.get(
          Uri.parse('${ApiConstants.baseUrl}/profiles/search/?username=$query'),
          headers: {'Authorization': 'Token $token'},
        );

        if (response.statusCode == 200) {
          final List<dynamic> data = jsonDecode(response.body);
          setState(() {
            _results = data.cast<Map<String, dynamic>>();
            _isLoading = false;
          });
        } else {
          setState(() {
            _results = [];
            _isLoading = false;
          });
        }
      } catch (e) {
        setState(() {
          _results = [];
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: TextField(
          controller: _controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Search users...',
            hintStyle: TextStyle(color: Colors.white54),
            border: InputBorder.none,
          ),
          onChanged: _onSearchChanged,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00FF7F)))
          : _results.isEmpty
          ? const Center(
        child: Text(
          'Type to search users',
          style: TextStyle(color: Colors.white54, fontSize: 18),
        ),
      )
          : ListView.builder(
        itemCount: _results.length,
        itemBuilder: (context, index) {
          final user = _results[index];
          final username = user['username'] ?? 'Unknown';
          final profileImage = user['profile_image'] ?? Constants.defaultProfilePath;

          return ListTile(
            leading: CircleAvatar(
              radius: 24,
              backgroundImage: CachedNetworkImageProvider(profileImage),
            ),
            title: Text(
              username,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '@$username',
              style: const TextStyle(color: Colors.white54),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfileScreen(
                    userId: user['user_id'], // ✅ CORRECT
                  ),
                ),
              );
            },

          );
        },
      ),
    );
  }
}