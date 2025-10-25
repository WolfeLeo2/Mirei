import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:exif/exif.dart';

import '../../services/memory_service.dart';

class MemoryComposerScreen extends StatefulWidget {
  const MemoryComposerScreen({super.key});

  @override
  State<MemoryComposerScreen> createState() => _MemoryComposerScreenState();
}

class _MemoryComposerScreenState extends State<MemoryComposerScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _selectedMedia = <XFile>[];
  final List<int> _highlightIndices = <int>[]; // Indices of highlighted media
  final Map<String, Duration> _videoDurations = {}; // Cache video durations
  final Map<String, DateTime?> _mediaDates = {}; // Cache media dates

  int _coverIndex = 0; // First media is cover by default
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Get highlight media items
  List<XFile> get _highlights {
    return _highlightIndices
        .where((index) => index < _selectedMedia.length)
        .map((index) => _selectedMedia[index])
        .toList();
  }

  /// Check if media is a video
  bool _isVideo(String path) {
    final ext = path.toLowerCase();
    return ext.endsWith('.mp4') ||
        ext.endsWith('.mov') ||
        ext.endsWith('.avi') ||
        ext.endsWith('.mkv');
  }

  /// Get video duration
  Future<Duration?> _getVideoDuration(String path) async {
    if (_videoDurations.containsKey(path)) {
      return _videoDurations[path];
    }

    try {
      final controller = VideoPlayerController.file(File(path));
      await controller.initialize();
      final duration = controller.value.duration;
      await controller.dispose();

      setState(() {
        _videoDurations[path] = duration;
      });

      return duration;
    } catch (e) {
      return null;
    }
  }

  /// Extract date from image EXIF data
  Future<DateTime?> _getImageDate(String path) async {
    if (_mediaDates.containsKey(path)) {
      return _mediaDates[path];
    }

    try {
      final bytes = await File(path).readAsBytes();
      final data = await readExifFromBytes(bytes);

      if (data.isEmpty) {
        // Fallback to file modification date
        final stat = await File(path).stat();
        setState(() {
          _mediaDates[path] = stat.modified;
        });
        return stat.modified;
      }

      // Try different EXIF date tags
      final dateTimeOriginal = data['EXIF DateTimeOriginal'];
      final dateTime = data['Image DateTime'];

      if (dateTimeOriginal != null) {
        final parsed = _parseExifDate(dateTimeOriginal.toString());
        setState(() {
          _mediaDates[path] = parsed;
        });
        return parsed;
      } else if (dateTime != null) {
        final parsed = _parseExifDate(dateTime.toString());
        setState(() {
          _mediaDates[path] = parsed;
        });
        return parsed;
      }

      // Fallback to file modification date
      final stat = await File(path).stat();
      setState(() {
        _mediaDates[path] = stat.modified;
      });
      return stat.modified;
    } catch (e) {
      // Fallback to file modification date
      try {
        final stat = await File(path).stat();
        setState(() {
          _mediaDates[path] = stat.modified;
        });
        return stat.modified;
      } catch (_) {
        return null;
      }
    }
  }

  /// Parse EXIF date format: "2024:01:15 14:30:00"
  DateTime? _parseExifDate(String exifDate) {
    try {
      final parts = exifDate.split(' ');
      if (parts.length != 2) return null;

      final dateParts = parts[0].split(':');
      final timeParts = parts[1].split(':');

      if (dateParts.length != 3 || timeParts.length != 3) return null;

      return DateTime(
        int.parse(dateParts[0]),
        int.parse(dateParts[1]),
        int.parse(dateParts[2]),
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
        int.parse(timeParts[2]),
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> _pickMedia({required MediaSource source}) async {
    try {
      if (source == MediaSource.camera) {
        final capture = await _picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 85,
        );
        if (capture != null) {
          setState(() {
            _selectedMedia.add(capture);
            // Auto-add first 5 to highlights
            if (_selectedMedia.length <= 5) {
              _highlightIndices.add(_selectedMedia.length - 1);
            }
          });
          // Extract date
          _getImageDate(capture.path);
        }
      } else if (source == MediaSource.video) {
        final video = await _picker.pickVideo(source: ImageSource.gallery);
        if (video != null) {
          setState(() {
            _selectedMedia.add(video);
            // Auto-add first 5 to highlights
            if (_selectedMedia.length <= 5) {
              _highlightIndices.add(_selectedMedia.length - 1);
            }
          });
          // Get video duration
          _getVideoDuration(video.path);
        }
      } else {
        // Gallery - allow both images and videos
        final picks = await _picker.pickMultiImage(imageQuality: 85);
        if (picks.isNotEmpty) {
          final startIndex = _selectedMedia.length;
          setState(() {
            _selectedMedia.addAll(picks);
            // Auto-add first 5 to highlights
            for (var i = 0; i < picks.length; i++) {
              final index = startIndex + i;
              if (_highlightIndices.length < 5) {
                _highlightIndices.add(index);
              }
            }
          });
          // Extract dates for all
          for (final pick in picks) {
            _getImageDate(pick.path);
          }
        }
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Something went wrong: $error')));
    }
  }

  void _toggleHighlight(int index) {
    setState(() {
      if (_highlightIndices.contains(index)) {
        _highlightIndices.remove(index);
      } else {
        _highlightIndices.add(index);
      }
    });
  }

  void _clearHighlights() {
    setState(() {
      _highlightIndices.clear();
    });
  }

  void _removeMedia(int index) {
    setState(() {
      _selectedMedia.removeAt(index);

      // Remove from highlights if present
      _highlightIndices.remove(index);

      // Adjust highlight indices that are greater than removed index
      for (var i = 0; i < _highlightIndices.length; i++) {
        if (_highlightIndices[i] > index) {
          _highlightIndices[i]--;
        }
      }

      // Adjust cover index if needed
      if (_coverIndex == index) {
        _coverIndex = 0;
      } else if (_coverIndex > index) {
        _coverIndex--;
      }

      if (_selectedMedia.isEmpty) {
        _coverIndex = 0;
      }
    });
  }

  void _changeCover() {
    if (_selectedMedia.isEmpty) return;

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select album cover',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedMedia.length,
                itemBuilder: (context, index) {
                  final isSelected = index == _coverIndex;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _coverIndex = index);
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 100,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        border: isSelected
                            ? Border.all(
                                color: const Color(0xFF115e5a),
                                width: 3,
                              )
                            : null,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _buildMediaThumbnail(
                          _selectedMedia[index],
                          showDuration: false,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaThumbnail(XFile media, {bool showDuration = true}) {
    final isVideo = _isVideo(media.path);

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.file(File(media.path), fit: BoxFit.cover),
        if (isVideo)
          Container(
            color: Colors.black26,
            child: const Center(
              child: Icon(
                Icons.play_circle_outline,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
        if (isVideo && showDuration)
          Positioned(
            top: 4,
            right: 4,
            child: FutureBuilder<Duration?>(
              future: _getVideoDuration(media.path),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data == null) {
                  return const SizedBox.shrink();
                }
                final duration = snapshot.data!;
                final minutes = duration.inMinutes;
                final seconds = duration.inSeconds % 60;
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '$minutes:${seconds.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  void _showMediaPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickMedia(source: MediaSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam_outlined),
              title: const Text('Choose video'),
              onTap: () {
                Navigator.pop(context);
                _pickMedia(source: MediaSource.video);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take photo'),
              onTap: () {
                Navigator.pop(context);
                _pickMedia(source: MediaSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveMemory() async {
    if (_selectedMedia.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least one photo or video to save a memory.'),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final paths = _selectedMedia.map((file) => file.path).toList();
      final title = _titleController.text.trim().isEmpty
          ? null
          : _titleController.text.trim();

      await MemoryService.instance.createMemory(
        imagePaths: paths,
        caption: title,
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
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top toolbar
            _buildToolbar(),

            // Main scrollable content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Highlights section
                    if (_highlights.isNotEmpty) ...[
                      _buildHighlightsSection(),
                      const SizedBox(height: 16),
                    ],

                    // Album cover section
                    if (_selectedMedia.isNotEmpty) ...[
                      _buildAlbumCoverSection(),
                      const SizedBox(height: 16),
                    ],

                    // Title field
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          hintText: 'Add a title',
                          hintStyle: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade400,
                          ),
                          border: InputBorder.none,
                        ),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Description field
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _descriptionController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText:
                              'What was your favourite part of this moment?',
                          hintStyle: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade500,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF115e5a),
                            ),
                          ),
                        ),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Add media button (if no media yet)
                    if (_selectedMedia.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: OutlinedButton.icon(
                          onPressed: _showMediaPicker,
                          icon: const Icon(Icons.add_photo_alternate_outlined),
                          label: const Text('Add photos and videos'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                          ),
                        ),
                      ),

                    // Media grid
                    if (_selectedMedia.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildMediaGrid(),
                      ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // Floating add button
      floatingActionButton: _selectedMedia.isNotEmpty
          ? FloatingActionButton(
              onPressed: _showMediaPicker,
              backgroundColor: const Color(0xFF115e5a),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Check/Done button
          Material(
            color: Colors.black12,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: _saving ? null : _saveMemory,
              customBorder: const CircleBorder(),
              child: Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check, size: 24),
              ),
            ),
          ),

          const Spacer(),

          // Close button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.pop(context),
              customBorder: const CircleBorder(),
              child: Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                child: const Icon(Icons.close, size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Thumbnail preview
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _buildMediaThumbnail(_highlights.first),
            ),
          ),

          const SizedBox(width: 12),

          // Text info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_highlights.length} highlight${_highlights.length > 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap media to add/remove',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),

          // Delete button
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            onPressed: _clearHighlights,
            tooltip: 'Clear highlights',
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumCoverSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Cover thumbnail
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _buildMediaThumbnail(
                _selectedMedia[_coverIndex],
                showDuration: false,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Text
          const Expanded(
            child: Text(
              'Album cover',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),

          // Edit button
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: _changeCover,
          ),
        ],
      ),
    );
  }

  Widget _buildMediaGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: _selectedMedia.length,
      itemBuilder: (context, index) {
        final media = _selectedMedia[index];
        final isHighlighted = _highlightIndices.contains(index);

        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            _toggleHighlight(index);
          },
          child: Stack(
            children: [
              // Media thumbnail
              Container(
                decoration: BoxDecoration(
                  border: isHighlighted
                      ? Border.all(color: const Color(0xFF115e5a), width: 3)
                      : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _buildMediaThumbnail(media),
                ),
              ),

              // Highlight indicator
              if (isHighlighted)
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF115e5a),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Highlight',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

              // X button
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _removeMedia(index);
                  },
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

enum MediaSource { gallery, camera, video }
