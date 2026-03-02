import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ChatPostBubble extends StatelessWidget {
  final Map<String, dynamic> post;
  final bool isMe;
  final String? senderUsername;
  final Widget? replyPreview;
  final bool showReadReceipt;
  final bool isSeen;

  const ChatPostBubble({
    super.key,
    required this.post,
    required this.isMe,
    this.senderUsername,
    this.replyPreview,
    this.showReadReceipt = false,
    this.isSeen = false,
  });

  @override
  Widget build(BuildContext context) {
    final image = post['image'];
    final caption = post['caption'] ?? '';
    final author = post['author_username'] ?? 'User';

    return Align(
      alignment:
      isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin:
        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        padding: const EdgeInsets.all(8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe
              ? const Color(0xFF00FF7F)
              : Colors.grey[800],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            if (replyPreview != null) replyPreview!,

            if (senderUsername != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  senderUsername!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isMe
                        ? Colors.black.withOpacity(0.7)
                        : const Color(0xFF00FF7F),
                  ),
                ),
              ),

            if (image != null &&
                image is String &&
                image.startsWith('http'))
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: image,
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),

            if (caption.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                caption,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isMe ? Colors.black : Colors.white,
                ),
              ),
            ],

            const SizedBox(height: 6),

            Text(
              "Post by $author",
              style: TextStyle(
                fontSize: 11,
                color: isMe
                    ? Colors.black.withOpacity(0.6)
                    : Colors.white54,
              ),
            ),

            // 🔥 READ RECEIPT
            if (showReadReceipt)
              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    isSeen ? "✓✓" : "✓",
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}