// lib/src/screens/create_post/create_post_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:image_cropper/image_cropper.dart';

import '../../config/constants.dart';
import '../../services/storage_service.dart';
import '../../widgets/anime_search_modal.dart';
import '../../services/constants.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  File? _image; // ← FIXED: Using _image, not _imageFile
  final _captionController = TextEditingController();
  Map<String, dynamic>? _selectedAnime;
  String _privacy = 'public';
  bool _isLoading = false;

  final picker = ImagePicker();

  // FIXED: MOVED aspectRatioPresets INSIDE uiSettings
  Future<void> _pickAndCropImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    final croppedFile = await ImageCropper().cropImage(
      sourcePath: pickedFile.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Edit Post',
          toolbarColor: const Color(0xFF00FF7F),
          toolbarWidgetColor: Colors.black,
          backgroundColor: Colors.black,
          activeControlsWidgetColor: const Color(0xFF00FF7F),
          cropFrameColor: const Color(0xFF00FF7F),
          cropGridColor: Colors.white24,
          lockAspectRatio: false,
          aspectRatioPresets: [  // ← NOW IT'S INSIDE AndroidUiSettings
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio3x2,
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.ratio4x3,
            CropAspectRatioPreset.ratio16x9,
          ],
        ),
        IOSUiSettings(
          title: 'Edit Post',
          aspectRatioPresets: [  // ← NOW IT'S INSIDE IOSUiSettings
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio3x2,
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.ratio4x3,
            CropAspectRatioPreset.ratio16x9,
          ],
        ),
      ],
    );

    if (croppedFile != null) {
      setState(() {
        _image = File(croppedFile.path); // ← FIXED: _image, not _imageFile
      });
    }
  }

  Future<void> _submitPost() async {
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final token = await StorageService.getToken();
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(_image!.path),
        'caption': _captionController.text.trim(),
        'privacy': _privacy,
        if (_selectedAnime != null) ...{
          'anime_id': _selectedAnime!['id'],
          'anime_title': _selectedAnime!['title'],
        },
      });

      final response = await Dio().post(
        '${ApiConstants.baseUrl}/posts/',
        data: formData,
        options: Options(
          headers: {'Authorization': 'Token $token'},
          contentType: 'multipart/form-data',
        ),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post created successfully!'),
            backgroundColor: Color(0xFF00FF7F),
          ),
        );
        Navigator.pop(context, true); // true = refresh profile/feed
      }
    } on DioException catch (e) {
      String errorMsg = 'Post failed';
      if (e.response?.data is Map) {
        final errors = e.response!.data as Map;
        errorMsg = errors.values.first is List
            ? (errors.values.first as List).first
            : errors.values.first.toString();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'New Post',
          style: TextStyle(fontFamily: 'AnimeAce', color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _submitPost,
            child: _isLoading
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Color(0xFF00FF7F),
                strokeWidth: 2,
              ),
            )
                : const Text(
              'POST',
              style: TextStyle(
                color: Color(0xFF00FF7F),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGE PREVIEW
            GestureDetector(
              onTap: _pickAndCropImage,
              child: Container(
                height: 320,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF00FF7F), width: 2),
                ),
                child: _image != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.file(_image!, fit: BoxFit.cover),
                )
                    : const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo_outlined, size: 60, color: Color(0xFF00FF7F)),
                    SizedBox(height: 12),
                    Text(
                      'Tap to add image',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // CAPTION
            TextField(
              controller: _captionController,
              maxLines: 5,
              maxLength: 500,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "What's on your mind?",
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF00FF7F)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF00FF7F)),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ANIME TAG
            ListTile(
              onTap: () async {
                final anime = await showAnimeSearchModal(context);
                if (anime != null) {
                  setState(() => _selectedAnime = anime);
                }
              },
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              leading: _selectedAnime != null
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  _selectedAnime!['poster_image'] ?? Constants.placeholderImagePath,
                  width: 56,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              )
                  : Container(
                width: 56,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF00FF7F)),
                ),
                child: const Icon(Icons.search, color: Color(0xFF00FF7F), size: 30),
              ),
              title: Text(
                _selectedAnime != null ? _selectedAnime!['title'] : 'Tag an anime (optional)',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
              ),
              subtitle: _selectedAnime != null ? const Text('Tap to change', style: TextStyle(color: Colors.white38)) : null,
              trailing: _selectedAnime != null
                  ? IconButton(
                icon: const Icon(Icons.clear, color: Colors.red),
                onPressed: () => setState(() => _selectedAnime = null),
              )
                  : const Icon(Icons.arrow_forward_ios, color: Color(0xFF00FF7F), size: 16),
            ),
            const SizedBox(height: 24),

            // PRIVACY
            DropdownButtonFormField<String>(
              value: _privacy,
              dropdownColor: Colors.grey[900],
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Who can see this post?',
                labelStyle: const TextStyle(color: Color(0xFF00FF7F)),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF00FF7F)),
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'public', child: Text('Public')),
                DropdownMenuItem(value: 'followers', child: Text('Followers Only')),
              ],
              onChanged: (val) => setState(() => _privacy = val!),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}