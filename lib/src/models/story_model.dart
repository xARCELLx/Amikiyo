class StoryUser {
  final int userId;
  final String username;
  final String? profileImage;
  final List<StoryItem> stories;
  final bool isMe;

  StoryUser({
    required this.userId,
    required this.username,
    required this.profileImage,
    required this.stories,
    required this.isMe,
  });

  factory StoryUser.fromJson(Map<String, dynamic> json) {
    return StoryUser(
      userId: json["user_id"],
      username: json["username"],
      profileImage: json["profile_image"],
      stories: (json["stories"] as List)
          .map((s) => StoryItem.fromJson(s))
          .toList(),

      // backend should return this
      isMe: json["is_me"] ?? false,
    );
  }
}

class StoryItem {
  final int id;
  final String image;
  final DateTime createdAt;
  final bool isSeen;
  final int viewsCount;

  StoryItem({
    required this.id,
    required this.image,
    required this.createdAt,
    required this.isSeen,
    required this.viewsCount,
  });

  factory StoryItem.fromJson(Map<String, dynamic> json) {
    return StoryItem(
      id: json['id'],
      image: json['image'],
      createdAt: DateTime.parse(json['created_at']),
      isSeen: json['is_seen'],
      viewsCount: json['views_count'],
    );
  }
}