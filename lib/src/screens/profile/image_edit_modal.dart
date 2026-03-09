import 'dart:io';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image/image.dart' as img;

class ImageEditModal extends StatefulWidget {
  final String imagePath;

  const ImageEditModal({super.key, required this.imagePath});

  @override
  State<ImageEditModal> createState() => _ImageEditModalState();
}

class _ImageEditModalState extends State<ImageEditModal> {
  final ScreenshotController _screenshotController = ScreenshotController();

  late String _imagePath;

  final List<TextOverlay> _texts = [];

  bool _isAddingText = false;

  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _imagePath = widget.imagePath;
  }

  // ─────────────────────────────
  // CROP IMAGE
  // ─────────────────────────────

  Future<void> _cropImage() async {
    final cropped = await ImageCropper().cropImage(
      sourcePath: _imagePath,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: "Crop",
          toolbarColor: Colors.black,
          toolbarWidgetColor: Colors.white,
        ),
        IOSUiSettings(title: "Crop"),
      ],
    );

    if (cropped != null) {
      setState(() {
        _imagePath = cropped.path;
      });
    }
  }

  // ─────────────────────────────
  // ROTATE IMAGE
  // ─────────────────────────────

  Future<void> _rotateImage() async {
    final file = File(_imagePath);
    final image = img.decodeImage(await file.readAsBytes())!;

    final rotated = img.copyRotate(image, angle: 90);

    final path =
        "${Directory.systemTemp.path}/${DateTime.now().millisecondsSinceEpoch}.jpg";

    await File(path).writeAsBytes(img.encodeJpg(rotated));

    setState(() {
      _imagePath = path;
    });
  }

  // ─────────────────────────────
  // FLIP IMAGE
  // ─────────────────────────────

  Future<void> _flipImage() async {
    final file = File(_imagePath);
    final image = img.decodeImage(await file.readAsBytes())!;

    final flipped = img.flipHorizontal(image);

    final path =
        "${Directory.systemTemp.path}/${DateTime.now().millisecondsSinceEpoch}.jpg";

    await File(path).writeAsBytes(img.encodeJpg(flipped));

    setState(() {
      _imagePath = path;
    });
  }

  // ─────────────────────────────
  // ADD TEXT
  // ─────────────────────────────

  void _confirmAddText() {
    final text = _textController.text.trim();

    if (text.isEmpty) return;

    setState(() {
      _texts.add(
        TextOverlay(
          text: text,
          position: const Offset(120, 200),
          scale: 1,
          rotation: 0,
        ),
      );

      _textController.clear();
      _isAddingText = false;
    });
  }

  // ─────────────────────────────
  // SAVE IMAGE
  // ─────────────────────────────

  Future<void> _saveImage() async {
    final image = await _screenshotController.capture();

    if (image == null) return;

    final path =
        "${Directory.systemTemp.path}/${DateTime.now().millisecondsSinceEpoch}.png";

    final file = File(path);
    await file.writeAsBytes(image);

    if (!mounted) return;

    Navigator.pop(context, path);
  }

  // ─────────────────────────────
  // TOOL BUTTON
  // ─────────────────────────────

  Widget toolButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFF1E1E1E),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Colors.white70))
        ],
      ),
    );
  }

  // ─────────────────────────────
  // UI
  // ─────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Edit Image"),
        actions: [
          TextButton(
            onPressed: _saveImage,
            child: const Text(
              "Save",
              style: TextStyle(
                color: Color(0xFF00FF7F),
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        ],
      ),

      body: Column(
        children: [

          // IMAGE CANVAS
          Expanded(
            child: Screenshot(
              controller: _screenshotController,
              child: Stack(
                children: [

                  Center(
                    child: Image.file(
                      File(_imagePath),
                      fit: BoxFit.contain,
                      width: double.infinity,
                    ),
                  ),

                  ..._texts.map((overlay) {
                    return Positioned(
                      left: overlay.position.dx,
                      top: overlay.position.dy,
                      child: GestureDetector(

                        onScaleUpdate: (details) {
                          setState(() {
                            overlay.scale = details.scale;
                            overlay.rotation = details.rotation;
                            overlay.position += details.focalPointDelta;
                          });
                        },

                        onLongPress: () {
                          setState(() {
                            _texts.remove(overlay);
                          });
                        },

                        child: Transform.rotate(
                          angle: overlay.rotation,
                          child: Transform.scale(
                            scale: overlay.scale,
                            child: Text(
                              overlay.text,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),

          // TEXT INPUT PANEL
          if (_isAddingText)
            Container(
              color: Colors.black,
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [

                  Expanded(
                    child: TextField(
                      controller: _textController,
                      autofocus: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: "Enter text",
                        hintStyle: TextStyle(color: Colors.white54),
                        border: InputBorder.none,
                      ),
                    ),
                  ),

                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    onPressed: _confirmAddText,
                  )
                ],
              ),
            ),

          // TOOLBAR
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFF111111),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [

                toolButton(Icons.crop, "Crop", _cropImage),

                toolButton(Icons.rotate_right, "Rotate", _rotateImage),

                toolButton(Icons.flip, "Flip", _flipImage),

                toolButton(Icons.text_fields, "Text", () {
                  setState(() {
                    _isAddingText = true;
                  });
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TextOverlay {
  String text;
  Offset position;
  double scale;
  double rotation;

  TextOverlay({
    required this.text,
    required this.position,
    required this.scale,
    required this.rotation,
  });
}