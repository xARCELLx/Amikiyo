import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../services/constants.dart';
import '../../services/storage_service.dart';
import '../profile/post_detail_modal.dart';
import 'widgets/feed_post_card.dart';
import 'widgets/thought_viewer.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final List<dynamic> _posts = [];

  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _hasError = false;
  bool _isLoadingMore = false;

  final ScrollController _scrollController = ScrollController();

  int _page = 1;

  @override
  void initState() {
    super.initState();
    _fetchFeed();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ───────────────── FETCH FEED ─────────────────

  Future<void> _fetchFeed({bool refresh = false}) async {
    if (_isLoadingMore) return;

    if (refresh) {
      _page = 1;
      setState(() => _isRefreshing = true);
    } else if (_page == 1) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }

    try {
      final token = await StorageService.getToken();
      if (token == null) throw Exception("No token");

      final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/home-feed/?page=$_page'),
        headers: {'Authorization': 'Token $token'},
      );

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);

        List<dynamic> data;

        if (decoded is Map && decoded.containsKey('results')) {
          data = decoded['results'];
        } else {
          data = decoded;
        }

        if (!mounted) return;

        setState(() {
          if (refresh) {
            _posts.clear();
          }

          if (data.isEmpty) {
            // LOOP FEED — restart from page 1
            _page = 1;
          } else {
            _posts.addAll(data);
            _page++;
          }

          _isLoading = false;
          _isRefreshing = false;
          _isLoadingMore = false;
        });
      } else {
        throw Exception("Feed error ${res.statusCode}");
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _hasError = true;
        _isLoading = false;
        _isRefreshing = false;
        _isLoadingMore = false;
      });
    }
  }

  // ───────────────── SCROLL LISTENER ─────────────────

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 400 &&
        !_isLoadingMore &&
        !_isLoading) {
      setState(() => _isLoadingMore = true);
      _fetchFeed();
    }
  }

  // ───────────────── IMAGE POST MODAL ─────────────────

  void _openPostDetail(Map<String, dynamic> post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PostDetailModal(
        post: post,
        heroTag: 'feed_post_${post['id']}',
      ),
    );
  }

  // ───────────────── THOUGHT MODAL ─────────────────

  void _openThoughtViewer(Map<String, dynamic> post) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "thought",
      barrierColor: Colors.black45,
      pageBuilder: (_, __, ___) {
        return ThoughtViewer(post: post);
      },
    );
  }

  // ───────────────── LOADING UI ─────────────────

  Widget _buildLoading() {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: CircularProgressIndicator(
          color: Color(0xFF00FF7F),
        ),
      ),
    );
  }

  // ───────────────── ERROR UI ─────────────────

  Widget _buildError() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: TextButton(
          onPressed: () => _fetchFeed(refresh: true),
          child: const Text(
            "Retry",
            style: TextStyle(
              color: Color(0xFF00FF7F),
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  // ───────────────── EMPTY UI ─────────────────

  Widget _buildEmpty() {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Text(
          "No posts yet",
          style: TextStyle(
            color: Colors.white54,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  // ───────────────── MAIN UI ─────────────────

  @override
  Widget build(BuildContext context) {

    if (_isLoading && _posts.isEmpty) {
      return _buildLoading();
    }

    if (_hasError && _posts.isEmpty) {
      return _buildError();
    }

    if (_posts.isEmpty) {
      return _buildEmpty();
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: RefreshIndicator(
        color: const Color(0xFF00FF7F),
        backgroundColor: Colors.black,
        onRefresh: () => _fetchFeed(refresh: true),
        child: ListView.separated(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: _posts.length,
          separatorBuilder: (_, __) => Container(
            height: 0.6,
            color: Colors.white10,
          ),
          itemBuilder: (_, index) {

            final post = _posts[index];
            final isThought = post['post_type'] == 'thought';

            return FeedPostCard(
              post: post,
              onTap: () {
                if (isThought) {
                  _openThoughtViewer(post);
                } else {
                  _openPostDetail(post);
                }
              },
            );
          },
        ),
      ),
    );
  }
}