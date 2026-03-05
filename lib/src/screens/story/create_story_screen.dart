import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/story_service.dart';

class CreateStoryScreen extends StatefulWidget {
  const CreateStoryScreen({super.key});

  @override
  State<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends State<CreateStoryScreen> {
  File? _image;
  bool _uploading = false;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (picked == null) return;

    setState(() {
      _image = File(picked.path);
    });
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Create Story"),
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [

          Expanded(
            child: Center(
              child: _image == null
                  ? const Text(
                "Pick an image",
                style: TextStyle(color: Colors.white70),
              )
                  : Image.file(_image!),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [

                Expanded(
                  child: ElevatedButton(
                    onPressed: _pickImage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[900],
                    ),
                    child: const Text("Gallery"),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: ElevatedButton(
                    onPressed: _uploading ? null : _uploadStory,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00FF7F),
                      foregroundColor: Colors.black,
                    ),
                    child: _uploading
                        ? const CircularProgressIndicator()
                        : const Text("Upload"),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}