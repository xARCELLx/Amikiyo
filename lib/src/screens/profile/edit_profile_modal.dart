// lib/src/screens/profile/edit_profile_modal.dart
import 'dart:io';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/constants.dart';
import '../../services/storage_service.dart';
import 'image_edit_modal.dart';
import '../../services/constants.dart';

class EditProfileModal extends StatefulWidget {
  final String initialUsername;
  final String initialBio;
  final String initialProfileImage;

  const EditProfileModal({
    super.key,
    required this.initialUsername,
    required this.initialBio,
    required this.initialProfileImage,
  });

  @override
  _EditProfileModalState createState() => _EditProfileModalState();
}

class _EditProfileModalState extends State<EditProfileModal> {
  late TextEditingController _usernameController;
  late TextEditingController _bioController;
  String _profileImage = '';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.initialUsername);
    _bioController = TextEditingController(text: widget.initialBio);
    _profileImage = widget.initialProfileImage;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  // Your existing isolate validation (kept 100%)
  static Future<String> _validateImage(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      debugPrint('Image file does not exist: $path');
      return '';
    }
    return path;
  }

  Future<void> _pickImage() async {
    try {
      debugPrint('Opening gallery for image selection');
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 100,
      );

      if (pickedFile == null) {
        debugPrint('Image selection canceled');
        return;
      }

      final validatedPath = await compute(_validateImage, pickedFile.path);
      if (validatedPath.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid image file')),
        );
        return;
      }

      final editedImagePath = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
        ),
        backgroundColor: Colors.transparent,
        builder: (context) => Stack(
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(color: Colors.black.withOpacity(0.5)),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: ImageEditModal(imagePath: validatedPath),
            ),
          ],
        ),
      );

      if (editedImagePath != null && editedImagePath.isNotEmpty) {
        setState(() {
          _profileImage = editedImagePath;
          debugPrint('Edited image set: $_profileImage');
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Error in _pickImage: $e\n$stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  // THE REAL SAVE FUNCTION — UPLOADS TO DJANGO
  Future<void> _saveToServer() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final token = await StorageService.getToken();
      if (token == null) throw Exception("No auth token found");

      final dio = Dio();
      dio.options.headers['Authorization'] = 'Token $token';

      FormData formData = FormData();

      // Text fields
      formData.fields
        ..add(MapEntry('username', _usernameController.text.trim()))
        ..add(MapEntry('bio', _bioController.text.trim()));

      // Upload image if changed
      if (_profileImage.isNotEmpty && File(_profileImage).existsSync()) {
        final fileName = _profileImage.split('/').last;
        formData.files.add(MapEntry(
          'profile_image',
          await MultipartFile.fromFile(_profileImage, filename: fileName),
        ));
      }

      final response = await dio.patch(
        '${ApiConstants.baseUrl}/profiles/me/',
        data: formData,
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile Updated Successfully!'),
            backgroundColor: Color(0xFF00FF7F),
          ),
        );
        Navigator.pop(context, {'saved': true}); // Triggers refresh in Settings → Profile
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Save failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        border: Border.all(color: const Color(0xFF00FF7F), width: 1),
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Edit Profile',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF00FF7F),
                  fontFamily: 'AnimeAce',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Divider(color: Color(0xFF00FF7F), height: 1),

            // Profile Picture
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.transparent,
                    child: ClipOval(
                      child: _profileImage.isEmpty
                          ? Image.asset(Constants.defaultProfilePath, fit: BoxFit.cover)
                          : _profileImage.startsWith('http')
                          ? CachedNetworkImage(
                        imageUrl: _profileImage,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => const CircularProgressIndicator(color: Color(0xFF00FF7F)),
                        errorWidget: (_, __, error) => Image.asset(Constants.defaultProfilePath, fit: BoxFit.cover),
                      )
                          : Image.file(
                        File(_profileImage),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Image.asset(Constants.defaultProfilePath, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00FF7F),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    onPressed: _pickImage,
                    child: const Text(
                      'Change Profile Picture',
                      style: TextStyle(fontFamily: 'AnimeAce', fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),

            // Username Field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                    fontFamily: 'AnimeAce',
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: Color(0xFF00FF7F)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: Color(0xFF00FF7F), width: 2),
                  ),
                ),
                style: const TextStyle(color: Colors.white, fontFamily: 'AnimeAce'),
              ),
            ),

            // Bio Field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: TextField(
                controller: _bioController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Bio',
                  labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                    fontFamily: 'AnimeAce',
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: Color(0xFF00FF7F)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: Color(0xFF00FF7F), width: 2),
                  ),
                ),
                style: const TextStyle(color: Colors.white, fontFamily: 'AnimeAce'),
              ),
            ),

            // Buttons
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00FF7F),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    ),
                    onPressed: _isSaving ? null : _saveToServer,
                    child: _isSaving
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                        : const Text(
                      'SAVE',
                      style: TextStyle(fontFamily: 'AnimeAce', fontWeight: FontWeight.w600),
                    ),
                  ),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF00FF7F)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'CANCEL',
                      style: TextStyle(fontFamily: 'AnimeAce', fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}