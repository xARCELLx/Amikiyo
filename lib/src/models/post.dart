class Post {
  final int id;
  final String username;
  final String profileImage;
  final String content;
  final String timestamp;
  final String? imageUrl;
  final int likes;

  Post({
    required this.id,
    required this.username,
    required this.profileImage,
    required this.content,
    required this.timestamp,
    required this.likes,
    this.imageUrl,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      username: json['author_username'] ?? '',
      profileImage: json['author_profile_image'] ?? '',
      content: json['caption'] ?? '',
      timestamp: json['created_at'] ?? '',
      imageUrl: json['image'],
      likes: json['likes_count'] ?? 0,
    );
  }
}
