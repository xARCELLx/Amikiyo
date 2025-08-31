import 'dart:io';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart'; // Added for compute
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/constants.dart';
import 'image_edit_modal.dart';

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

  // Isolate function to validate image file
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

      // Validate file in isolate
      final validatedPath = await compute(_validateImage, pickedFile.path);
      if (validatedPath.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid image file')),
        );
        return;
      }

      // Open ImageEditModal
      debugPrint('Opening ImageEditModal with path: $validatedPath');
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

      if (editedImagePath != null) {
        setState(() {
          _profileImage = editedImagePath;
          debugPrint('Edited image: $_profileImage');
        });
      } else {
        debugPrint('ImageEditModal canceled');
      }
    } catch (e, stackTrace) {
      debugPrint('Error in _pickImage: $e\nStackTrace: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
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
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
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
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.transparent,
                    child: ClipOval(
                      child: _profileImage.startsWith('http')
                          ? CachedNetworkImage(
                        imageUrl: _profileImage,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const CircularProgressIndicator(
                          color: Color(0xFF00FF7F),
                        ),
                        errorWidget: (context, url, error) {
                          debugPrint('Profile image failed: $url, error: $error');
                          return Image.asset(
                            Constants.defaultProfilePath,
                            fit: BoxFit.cover,
                          );
                        },
                      )
                          : Image.file(
                        File(_profileImage.isNotEmpty ? _profileImage : Constants.defaultProfilePath),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          debugPrint('Local profile image failed: $error');
                          return Image.asset(
                            Constants.defaultProfilePath,
                            fit: BoxFit.cover,
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00FF7F),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                    fontFamily: 'AnimeAce',
                    fontWeight: FontWeight.w400,
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
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontFamily: 'AnimeAce',
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
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
                    fontWeight: FontWeight.w400,
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
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontFamily: 'AnimeAce',
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00FF7F),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context, {
                        'username': _usernameController.text,
                        'bio': _bioController.text,
                        'profileImage': _profileImage,
                      });
                    },
                    child: const Text(
                      'Save',
                      style: TextStyle(fontFamily: 'AnimeAce', fontWeight: FontWeight.w600),
                    ),
                  ),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF00FF7F)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancel',
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