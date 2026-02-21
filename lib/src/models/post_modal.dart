class Post {
  final int id;
  final String image;
  final String caption;
  final String authorUsername;
  final int authorUserId;
  final int likesCount;
  final int commentsCount;
  final int viewsCount;
  final bool isLiked;
  final String privacy;
  final String createdAt;

  Post({
    required this.id,
    required this.image,
    required this.caption,
    required this.authorUsername,
    required this.authorUserId,
    required this.likesCount,
    required this.commentsCount,
    required this.viewsCount,
    required this.isLiked,
    required this.privacy,
    required this.createdAt,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      image: json['image'] ?? '',
      caption: json['caption'] ?? '',
      authorUsername: json['author_username'] ?? '',
      authorUserId: json['author_user_id'],
      likesCount: json['likes_count'] ?? 0,
      commentsCount: json['comments_count'] ?? 0,
      viewsCount: json['views_count'] ?? 0,
      isLiked: json['is_liked'] ?? false,
      privacy: json['privacy'] ?? 'public',
      createdAt: json['created_at'] ?? '',
    );
  }
}
