import 'package:flutter/material.dart';

class StoryProgressBar extends StatelessWidget {
  final int total;
  final int currentIndex;
  final double progress;

  const StoryProgressBar({
    super.key,
    required this.total,
    required this.currentIndex,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (index) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            height: 3,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: index < currentIndex
                      ? 1
                      : index == currentIndex
                      ? progress
                      : 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}