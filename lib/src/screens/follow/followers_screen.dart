import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../services/storage_service.dart';
import '../../services/constants.dart';
import 'follow_user_tile.dart';

class FollowersScreen extends StatefulWidget {
  final int userId;

  const FollowersScreen({super.key, required this.userId});

  @override
  State<FollowersScreen> createState() => _FollowersScreenState();
}

class _FollowersScreenState extends State<FollowersScreen> {
  List<Map<String, dynamic>> _followers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFollowers();
  }

  Future<void> _loadFollowers() async {
    final token = await StorageService.getToken();
    if (token == null) return;

    try {
      final res = await http.get(
        Uri.parse(
          '${ApiConstants.baseUrl}/profiles/${widget.userId}/followers/',
        ),
        headers: {'Authorization': 'Token $token'},
      );

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        setState(() {
          _followers = data.cast<Map<String, dynamic>>();
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
        title: const Text('Followers'),
      ),
      body: _loading
          ? const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF00FF7F),
        ),
      )
          : _followers.isEmpty
          ? const Center(
        child: Text(
          'No followers yet',
          style: TextStyle(color: Colors.white54),
        ),
      )
          : ListView.builder(
        itemCount: _followers.length,
        itemBuilder: (_, i) =>
            FollowUserTile(user: _followers[i]),
      ),
    );
  }
}
