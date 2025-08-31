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
    try {
      final file = File(widget.imagePath);
      if (!await file.exists()) {
        debugPrint('Image file does not exist: ${widget.imagePath}');
        setState(() {
          _editedImagePath = '';
        });
        return;
      }

      final croppedFile = await ImageCropper().cropImage(
        sourcePath: widget.imagePath,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
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

      setState(() {
        _editedImagePath = croppedFile?.path ?? widget.imagePath;
        debugPrint('Cropped image: $_editedImagePath');
      });
    } catch (e, stackTrace) {
      debugPrint('Error in _cropImage: $e\nStackTrace: $stackTrace');
      setState(() {
        _editedImagePath = widget.imagePath;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to crop image: $e')),
      );
    }
  }

  Future<void> _invertImage() async {
    try {
      final imageFile = File(_editedImagePath);
      if (!await imageFile.exists()) {
        debugPrint('Image file for invert does not exist: $_editedImagePath');
        return;
      }
      final image = img.decodeImage(await imageFile.readAsBytes())!;
      final inverted = img.invert(image);
      final invertedPath = _editedImagePath.replaceAll('.jpg', '_inverted.jpg');
      await File(invertedPath).writeAsBytes(img.encodePng(inverted));
      setState(() {
        _editedImagePath = invertedPath;
        _isInverted = !_isInverted;
        debugPrint('Inverted image: $_editedImagePath');
      });
    } catch (e, stackTrace) {
      debugPrint('Error in _invertImage: $e\nStackTrace: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to invert image: $e')),
      );
    }
  }

  Future<void> _mirrorImage() async {
    try {
      final imageFile = File(_editedImagePath);
      if (!await imageFile.exists()) {
        debugPrint('Image file for mirror does not exist: $_editedImagePath');
        return;
      }
      final image = img.decodeImage(await imageFile.readAsBytes())!;
      final mirrored = img.flipHorizontal(image);
      final mirroredPath = _editedImagePath.replaceAll('.jpg', '_mirrored.jpg');
      await File(mirroredPath).writeAsBytes(img.encodePng(mirrored));
      setState(() {
        _editedImagePath = mirroredPath;
        _isMirrored = !_isMirrored;
        debugPrint('Mirrored image: $_editedImagePath');
      });
    } catch (e, stackTrace) {
      debugPrint('Error in _mirrorImage: $e\nStackTrace: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to mirror image: $e')),
      );
    }
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
              'Edit Profile Picture',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: const Color(0xFF00FF7F),
                fontFamily: 'AnimeAce',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
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
                  debugPrint('Image preview failed: $error\nStackTrace: $stackTrace');
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.flip, size: 18),
                  label: const Text('Invert'),
                  onPressed: _editedImagePath.isNotEmpty ? _invertImage : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isInverted ? Colors.grey : const Color(0xFF00FF7F),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.flip_camera_android, size: 18),
                  label: const Text('Mirror'),
                  onPressed: _editedImagePath.isNotEmpty ? _mirrorImage : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isMirrored ? Colors.grey : const Color(0xFF00FF7F),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ],
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
                  onPressed: _editedImagePath.isNotEmpty
                      ? () => Navigator.pop(context, _editedImagePath)
                      : null,
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
    );
  }
}