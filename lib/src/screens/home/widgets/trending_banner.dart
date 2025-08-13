import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../config/constants.dart';

class TrendingBanner extends StatelessWidget {
  const TrendingBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final trends = [
      {'title': 'Top Naruto Memes', 'image': 'https://picsum.photos/150/150?random=5'},
      {'title': 'Jujutsu Kaisen Fans', 'image': 'https://picsum.photos/150/150?random=6'},
      {'title': 'Shonen Hype', 'image': 'https://picsum.photos/150/150?random=7'},
    ];

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.12, // Responsive: 12% of screen height
        minHeight: 70, // Minimum height to prevent collapse
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        itemCount: trends.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Shrink-wrap content
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.secondary, // Electric green #00FF7F
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: trends[index]['image']!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) => Image.asset(
                        Constants.placeholderImagePath,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: 60,
                  child: Text(
                    trends[index]['title']!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}