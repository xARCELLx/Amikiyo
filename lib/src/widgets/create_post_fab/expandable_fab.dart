import 'package:flutter/material.dart';

class ExpandableFab extends StatefulWidget {
  final VoidCallback onImagePost;
  final VoidCallback onThoughtPost;

  const ExpandableFab({
    super.key,
    required this.onImagePost,
    required this.onThoughtPost,
  });

  @override
  State<ExpandableFab> createState() => _ExpandableFabState();
}

class _ExpandableFabState extends State<ExpandableFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  bool _open = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  void _toggle() {
    setState(() => _open = !_open);

    if (_open) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          if (_open)
            Positioned(
              bottom: 120,
              right: 0,
              child: _actionButton(
                icon: Icons.photo,
                label: "Post",
                onTap: widget.onImagePost,
              ),
            ),

          if (_open)
            Positioned(
              bottom: 70,
              right: 0,
              child: _actionButton(
                icon: Icons.edit,
                label: "Thought",
                onTap: widget.onThoughtPost,
              ),
            ),

          FloatingActionButton(
            backgroundColor: const Color(0xFF00FF7F),
            onPressed: _toggle,
            child: AnimatedRotation(
              turns: _open ? 0.125 : 0,
              duration: const Duration(milliseconds: 200),
              child: const Icon(Icons.add, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _toggle();
          onTap();
        },
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: const Color(0xFF00FF7F)),
          ),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF00FF7F), size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF00FF7F),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}