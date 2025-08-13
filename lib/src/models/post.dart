class Post {
  final String username;
  final String profileImage;
  final String timestamp;
  final String content;
  final String? imageUrl;
  final String? videoUrl;
  final int likes;
  final int comments;

  Post({
    required this.username,
    required this.profileImage,
    required this.timestamp,
    required this.content,
    this.imageUrl,
    this.videoUrl,
    this.likes = 0,
    this.comments = 0,
  });
}