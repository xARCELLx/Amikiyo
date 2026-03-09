import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/story_service.dart';
import '../profile/image_edit_modal.dart'; // <-- your editor

class CreateStoryScreen extends StatefulWidget {
  const CreateStoryScreen({super.key});

  @override
  State<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends State<CreateStoryScreen> {

  final ImagePicker _picker = ImagePicker();

  File? _image;

  bool _uploading = false;

  // ───────────────── PICK IMAGE ─────────────────

  Future<void> _pickImage() async {

    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );

    if (picked == null) return;

    // OPEN IMAGE EDITOR

    final editedPath = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ImageEditModal(
          imagePath: picked.path,
        ),
      ),
    );

    if (editedPath == null) return;

    setState(() {
      _image = File(editedPath);
    });
  }

  // ───────────────── UPLOAD STORY ─────────────────

  Future<void> _uploadStory() async {

    if (_image == null) return;

    setState(() {
      _uploading = true;
    });

    try {

      await StoryService.createStory(_image!.path);

      if (!mounted) return;

      Navigator.pop(context, true);

    } catch (_) {

      setState(() {
        _uploading = false;
      });
    }
  }

  // ───────────────── UI ─────────────────

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("New Story"),
        actions: [

          if (_image != null)
            TextButton(
              onPressed: _uploading ? null : _uploadStory,
              child: _uploading
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF00FF7F),
                ),
              )
                  : const Text(
                "Share",
                style: TextStyle(
                  color: Color(0xFF00FF7F),
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
        ],
      ),

      body: GestureDetector(
        onTap: _image == null ? _pickImage : null,

        child: Stack(
          children: [

            // IMAGE PREVIEW

            Positioned.fill(
              child: _image == null
                  ? _emptyState()
                  : Image.file(
                _image!,
                fit: BoxFit.contain,
              ),
            ),

            // BOTTOM ACTIONS

            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: Row(
                children: [

                  _circleButton(
                    icon: Icons.photo_library,
                    onTap: _pickImage,
                  ),

                  const Spacer(),

                  if (_image != null)
                    _circleButton(
                      icon: Icons.edit,
                      onTap: () async {

                        final edited = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ImageEditModal(
                              imagePath: _image!.path,
                            ),
                          ),
                        );

                        if (edited != null) {
                          setState(() {
                            _image = File(edited);
                          });
                        }
                      },
                    ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  // ───────────────── EMPTY STATE ─────────────────

  Widget _emptyState() {

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          const Icon(
            Icons.add_photo_alternate_outlined,
            size: 80,
            color: Colors.white30,
          ),

          const SizedBox(height: 16),

          const Text(
            "Tap to select image",
            style: TextStyle(
              color: Colors.white54,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────── MODERN CIRCLE BUTTON ─────────────────

  Widget _circleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 54,
        height: 54,
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E1E),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white,
        ),
      ),
    );
  }
}