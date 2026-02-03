import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../services/storage_service.dart';
import '../../services/constants.dart';
import 'follow_user_tile.dart';

class FollowingScreen extends StatefulWidget {
  final int userId;

  const FollowingScreen({super.key, required this.userId});

  @override
  State<FollowingScreen> createState() => _FollowingScreenState();
}

class _FollowingScreenState extends State<FollowingScreen> {
  List<Map<String, dynamic>> _following = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFollowing();
  }

  Future<void> _loadFollowing() async {
    final token = await StorageService.getToken();
    if (token == null) return;

    try {
      final res = await http.get(
        Uri.parse(
          '${ApiConstants.baseUrl}/profiles/${widget.userId}/following/',
        ),
        headers: {'Authorization': 'Token $token'},
      );

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        setState(() {
          _following = data.cast<Map<String, dynamic>>();
          _loading = false;
        });
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Following'),
      ),
      body: _loading
          ? const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF00FF7F),
        ),
      )
          : _following.isEmpty
          ? const Center(
        child: Text(
          'Not following anyone',
          style: TextStyle(color: Colors.white54),
        ),
      )
          : ListView.builder(
        itemCount: _following.length,
        itemBuilder: (_, i) =>
            FollowUserTile(user: _following[i]),
      ),
    );
  }
}
