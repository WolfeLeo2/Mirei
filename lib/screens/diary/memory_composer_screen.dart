import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/typography.dart';
import '../../services/memory_service.dart';

class MemoryComposerScreen extends StatefulWidget {
  const MemoryComposerScreen({super.key});

  @override
  State<MemoryComposerScreen> createState() => _MemoryComposerScreenState();
}

class _MemoryComposerScreenState extends State<MemoryComposerScreen> {
  final TextEditingController _captionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _selectedFiles = <XFile>[];

  bool _saving = false;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickImages({required bool fromCamera}) async {
    try {
      if (fromCamera) {
        final capture = await _picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 85,
        );
        if (capture != null) {
          setState(() {
            _selectedFiles.add(capture);
          });
        }
      } else {
        final picks = await _picker.pickMultiImage(imageQuality: 85);
        if (picks.isNotEmpty) {
          setState(() {
            _selectedFiles.addAll(picks);
          });
        }
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Something went wrong: $error')));
    }
  }

  void _removeImage(XFile file) {
    setState(() {
      _selectedFiles.remove(file);
    });
  }

  Future<void> _saveMemory() async {
    if (_selectedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least one photo to save a memory.'),
        ),
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final paths = _selectedFiles.map((file) => file.path).toList();
      final caption = _captionController.text.trim().isEmpty
          ? null
          : _captionController.text.trim();

      await MemoryService.instance.createMemory(
        imagePaths: paths,
        caption: caption,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not save memory: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F6),
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'New Memory',
          style: TextStyle(
            fontFamily: AppTypography.primaryFontFamily,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _saveMemory,
            child: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _captionController,
                textInputAction: TextInputAction.newline,
                maxLines: null,
                decoration: InputDecoration(
                  labelText: 'Caption',
                  hintText: 'How would you describe this moment?',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _saving
                        ? null
                        : () => _pickImages(fromCamera: false),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Add from gallery'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _saving
                        ? null
                        : () => _pickImages(fromCamera: true),
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('Camera'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _selectedFiles.isEmpty
                  ? _EmptyMemoryPlaceholder(
                      onPick: () => _pickImages(fromCamera: false),
                    )
                  : _ImagesGrid(files: _selectedFiles, onRemove: _removeImage),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImagesGrid extends StatelessWidget {
  const _ImagesGrid({required this.files, required this.onRemove});

  final List<XFile> files;
  final ValueChanged<XFile> onRemove;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];
        return Stack(
          clipBehavior: Clip.none,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(File(file.path), fit: BoxFit.cover),
            ),
            Positioned(
              top: -8,
              right: -8,
              child: IconButton.filled(
                onPressed: () => onRemove(file),
                icon: const Icon(Icons.close, size: 18),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black87,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _EmptyMemoryPlaceholder extends StatelessWidget {
  const _EmptyMemoryPlaceholder({required this.onPick});

  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE3ECEC)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.collections_outlined,
            size: 48,
            color: Color(0xFF115e5a),
          ),
          const SizedBox(height: 16),
          Text(
            'Add photos',
            style: TextStyle(
              fontFamily: AppTypography.primaryFontFamily,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Start by adding 1 or more photos to save this memory.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onPick,
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Choose photos'),
          ),
        ],
      ),
    );
  }
}
