import 'dart:ui';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
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

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 150,
      maxHeight: 150,
      imageQuality: 80,
    );
    if (pickedFile != null) {
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
              child: Container(
                color: Colors.black.withOpacity(0.5),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: ImageEditModal(imagePath: pickedFile.path),
            ),
          ],
        ),
      );
      if (editedImagePath != null) {
        setState(() {
          _profileImage = editedImagePath;
          debugPrint('Selected and edited profile image: $_profileImage');
        });
      }
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
            // Drag Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
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
                    backgroundColor: Theme.of(context).colorScheme.primary,
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
            // Username
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
            // Bio
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
            // Save and Cancel Buttons
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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