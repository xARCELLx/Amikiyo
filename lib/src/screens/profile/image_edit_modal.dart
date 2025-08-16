import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image/image.dart' as img;

class ImageEditModal extends StatefulWidget {
  final String imagePath;

  const ImageEditModal({super.key, required this.imagePath});

  @override
  _ImageEditModalState createState() => _ImageEditModalState();
}

class _ImageEditModalState extends State<ImageEditModal> {
  String _editedImagePath = '';
  bool _isInverted = false;
  bool _isMirrored = false;

  @override
  void initState() {
    super.initState();
    _cropImage();
  }

  Future<void> _cropImage() async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: widget.imagePath,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1), // Force square crop
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Profile Picture',
          toolbarColor: const Color(0xFF1A237E),
          toolbarWidgetColor: Colors.white,
          activeControlsWidgetColor: const Color(0xFF00FF7F),
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
        ),
        IOSUiSettings(
          title: 'Crop Profile Picture',
          aspectRatioLockEnabled: true,
        ),
      ],
    );
    if (croppedFile != null) {
      setState(() {
        _editedImagePath = croppedFile.path;
      });
    } else {
      // If cropping is canceled, use original path
      setState(() {
        _editedImagePath = widget.imagePath;
      });
    }
  }

  Future<void> _invertImage() async {
    final imageFile = File(_editedImagePath);
    final image = img.decodeImage(imageFile.readAsBytesSync())!;
    final inverted = img.invert(image);
    final invertedPath = _editedImagePath.replaceAll('.jpg', '_inverted.jpg');
    File(invertedPath).writeAsBytesSync(img.encodePng(inverted));
    setState(() {
      _editedImagePath = invertedPath;
      _isInverted = !_isInverted;
      debugPrint('Inverted image: $_editedImagePath');
    });
  }

  Future<void> _mirrorImage() async {
    final imageFile = File(_editedImagePath);
    final image = img.decodeImage(imageFile.readAsBytesSync())!;
    final mirrored = img.flipHorizontal(image);
    final mirroredPath = _editedImagePath.replaceAll('.jpg', '_mirrored.jpg');
    File(mirroredPath).writeAsBytesSync(img.encodePng(mirrored));
    setState(() {
      _editedImagePath = mirroredPath;
      _isMirrored = !_isMirrored;
      debugPrint('Mirrored image: $_editedImagePath');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        border: Border.all(color: const Color(0xFF00FF7F), width: 1),
      ),
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
              'Edit Profile Picture',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: const Color(0xFF00FF7F),
                fontFamily: 'AnimeAce',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Image Preview
          Padding(
            padding: const EdgeInsets.all(12),
            child: _editedImagePath.isNotEmpty
                ? ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.file(
                File(_editedImagePath),
                width: 150,
                height: 150,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  debugPrint('Image preview failed: $error');
                  return Image.asset(
                    'assets/images/default_profile.png',
                    width: 150,
                    height: 150,
                    fit: BoxFit.cover,
                  );
                },
              ),
            )
                : const CircularProgressIndicator(color: Color(0xFF00FF7F)),
          ),
          // Editing Options
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.flip, size: 18),
                  label: const Text('Invert'),
                  onPressed: _invertImage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isInverted ? Colors.grey : const Color(0xFF00FF7F),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.flip_camera_android, size: 18),
                  label: const Text('Mirror'),
                  onPressed: _mirrorImage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isMirrored ? Colors.grey : const Color(0xFF00FF7F),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
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
                    Navigator.pop(context, _editedImagePath);
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
    );
  }
}