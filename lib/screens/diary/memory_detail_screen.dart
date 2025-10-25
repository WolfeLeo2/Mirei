import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:intl/intl.dart';
import 'package:exif/exif.dart';
import 'package:video_player/video_player.dart';

import 'diary_memories_tab.dart';

class MemoryDetailScreen extends StatefulWidget {
  const MemoryDetailScreen({
    super.key,
    required this.memory,
    required this.onDelete,
  });

  final MemoryGroupItem memory;
  final VoidCallback onDelete;

  @override
  State<MemoryDetailScreen> createState() => _MemoryDetailScreenState();
}

class _MemoryDetailScreenState extends State<MemoryDetailScreen> {
  String? _dateRange;
  bool _loadingDates = true;
  int _coverIndex = 0; // Default to first image

  @override
  void initState() {
    super.initState();
    _extractDateRange();
  }

  Future<void> _extractDateRange() async {
    try {
      final dates = <DateTime>[];

      // Extract dates from first 5 images (highlights)
      final mediaToCheck = widget.memory.resolvedImagePaths.take(5).toList();

      for (final path in mediaToCheck) {
        if (_isVideo(path)) {
          final stat = await File(path).stat();
          dates.add(stat.modified);
        } else {
          final date = await _getImageDate(path);
          if (date != null) {
            dates.add(date);
          }
        }
      }

      if (dates.isEmpty) {
        dates.add(widget.memory.entry.createdAt.toLocal());
      }

      dates.sort();

      final formatter = DateFormat('d MMM');
      final firstDate = dates.first;
      final lastDate = dates.last;

      String range;
      if (firstDate.year == lastDate.year &&
          firstDate.month == lastDate.month &&
          firstDate.day == lastDate.day) {
        range = formatter.format(firstDate);
      } else {
        range =
            '${formatter.format(firstDate)} - ${formatter.format(lastDate)}';
      }

      if (mounted) {
        setState(() {
          _dateRange = range;
          _loadingDates = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _dateRange = DateFormat(
            'd MMM',
          ).format(widget.memory.entry.createdAt.toLocal());
          _loadingDates = false;
        });
      }
    }
  }

  bool _isVideo(String path) {
    final ext = path.toLowerCase();
    return ext.endsWith('.mp4') ||
        ext.endsWith('.mov') ||
        ext.endsWith('.avi') ||
        ext.endsWith('.mkv');
  }

  Future<DateTime?> _getImageDate(String path) async {
    try {
      final bytes = await File(path).readAsBytes();
      final data = await readExifFromBytes(bytes);

      if (data.isEmpty) {
        final stat = await File(path).stat();
        return stat.modified;
      }

      final dateTimeOriginal = data['EXIF DateTimeOriginal'];
      final dateTime = data['Image DateTime'];

      if (dateTimeOriginal != null) {
        return _parseExifDate(dateTimeOriginal.toString());
      } else if (dateTime != null) {
        return _parseExifDate(dateTime.toString());
      }

      final stat = await File(path).stat();
      return stat.modified;
    } catch (e) {
      try {
        final stat = await File(path).stat();
        return stat.modified;
      } catch (_) {
        return null;
      }
    }
  }

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

  void _openStoriesViewer() {
    // Get first 5 images as highlights
    final highlights = widget.memory.resolvedImagePaths.take(5).toList();
    if (highlights.isEmpty) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _StoriesViewer(
          mediaPaths: highlights,
          title: widget.memory.entry.caption ?? 'Untitled Memory',
          dateRange: _dateRange ?? '',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.memory.entry.caption;
    final coverPath = widget.memory.resolvedImagePaths.isNotEmpty
        ? widget.memory.resolvedImagePaths[_coverIndex]
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F6),
      body: CustomScrollView(
        slivers: [
          // Sliver AppBar with cover image
          SliverAppBar(
            expandedHeight: 400,
            pinned: false,
            floating: false,
            backgroundColor: Colors.white,
            leading: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            actions: [
              PopupMenuButton<String>(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.more_vert,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (value) async {
                  if (value == 'delete') {
                    final shouldDelete =
                        await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete memory?'),
                            content: const Text(
                              'This will remove the memory and all associated photos.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                ),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        ) ??
                        false;
                    if (shouldDelete) {
                      widget.onDelete();
                    }
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: Colors.red, size: 20),
                        SizedBox(width: 12),
                        Text(
                          'Delete',
                          style: TextStyle(fontSize: 16, color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: coverPath != null
                  ? GestureDetector(
                      onTap: _openStoriesViewer,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Cover image
                          Image.file(File(coverPath), fit: BoxFit.cover),
                          // Gradient overlay for text readability
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.7),
                                ],
                                stops: const [0.5, 1.0],
                              ),
                            ),
                          ),
                          // Date and title overlay
                          Positioned(
                            left: 20,
                            right: 20,
                            bottom: 20,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!_loadingDates && _dateRange != null)
                                  Text(
                                    _dateRange!,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                const SizedBox(height: 8),
                                Text(
                                  title?.isEmpty ?? true
                                      ? 'Untitled Memory'
                                      : title!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  : Container(
                      color: Colors.grey.shade300,
                      child: const Center(
                        child: Icon(
                          Icons.photo_library_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                      ),
                    ),
            ),
          ),

          // Masonry grid of all images
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverMasonryGrid.count(
              crossAxisCount: 3,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childCount: widget.memory.resolvedImagePaths.length,
              itemBuilder: (context, index) {
                final path = widget.memory.resolvedImagePaths[index];
                return _GridImageItem(path: path, isVideo: _isVideo(path));
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _GridImageItem extends StatelessWidget {
  const _GridImageItem({required this.path, required this.isVideo});

  final String path;
  final bool isVideo;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => _FullScreenImageViewer(imagePath: path),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: AspectRatio(
          aspectRatio: isVideo ? 16 / 9 : 0.75,
          child: Stack(
            fit: StackFit.passthrough,
            children: [
              Image.file(
                File(path),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.broken_image_outlined),
                ),
              ),
              if (isVideo)
                Container(
                  color: Colors.black.withValues(alpha: 0.3),
                  child: const Center(
                    child: Icon(
                      Icons.play_circle_fill,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StoriesViewer extends StatefulWidget {
  const _StoriesViewer({
    required this.mediaPaths,
    required this.title,
    required this.dateRange,
  });

  final List<String> mediaPaths;
  final String title;
  final String dateRange;

  @override
  State<_StoriesViewer> createState() => _StoriesViewerState();
}

class _StoriesViewerState extends State<_StoriesViewer> {
  late PageController _pageController;
  int _currentIndex = 0;
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _initializeMedia(0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _initializeMedia(int index) async {
    await _videoController?.dispose();
    _videoController = null;

    final path = widget.mediaPaths[index];
    if (_isVideo(path)) {
      _videoController = VideoPlayerController.file(File(path));
      await _videoController!.initialize();
      _videoController!.setLooping(false);
      _videoController!.play();
      if (mounted) setState(() {});
    }
  }

  bool _isVideo(String path) {
    final ext = path.toLowerCase();
    return ext.endsWith('.mp4') ||
        ext.endsWith('.mov') ||
        ext.endsWith('.avi') ||
        ext.endsWith('.mkv');
  }

  void _nextPage() {
    if (_currentIndex < widget.mediaPaths.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  void _previousPage() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Stories content
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
              _initializeMedia(index);
            },
            itemCount: widget.mediaPaths.length,
            itemBuilder: (context, index) {
              final path = widget.mediaPaths[index];
              final isVideo = _isVideo(path);

              return Stack(
                fit: StackFit.expand,
                children: [
                  // Image or video
                  if (isVideo && _videoController != null)
                    Center(
                      child: AspectRatio(
                        aspectRatio: _videoController!.value.aspectRatio,
                        child: VideoPlayer(_videoController!),
                      ),
                    )
                  else
                    Image.file(File(path), fit: BoxFit.contain),

                  // Tap zones for navigation
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _previousPage,
                          child: Container(color: Colors.transparent),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: _nextPage,
                          child: Container(color: Colors.transparent),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),

          // Progress indicators
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Progress bars
                  Row(
                    children: List.generate(
                      widget.mediaPaths.length,
                      (index) => Expanded(
                        child: Container(
                          height: 3,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: index <= _currentIndex
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Date and title
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.dateRange,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FullScreenImageViewer extends StatelessWidget {
  const _FullScreenImageViewer({required this.imagePath});

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close, color: Colors.white),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.file(File(imagePath), fit: BoxFit.contain),
        ),
      ),
    );
  }
}
