import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:realm/realm.dart';
import 'package:exif/exif.dart';

import '../../core/theme/typography.dart';
import '../../models/realm_models.dart';
import '../../services/memory_service.dart';
import 'memory_detail_screen.dart';

class DiaryMemoriesTab extends StatefulWidget {
  const DiaryMemoriesTab({super.key});

  @override
  State<DiaryMemoriesTab> createState() => DiaryMemoriesTabState();
}

class DiaryMemoriesTabState extends State<DiaryMemoriesTab>
    with AutomaticKeepAliveClientMixin {
  final MemoryService _memoryService = MemoryService.instance;
  final DateFormat _dayFormatter = DateFormat('EEEE, MMM d, yyyy');

  Map<String, List<MemoryGroupItem>> _grouped = {};
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _loadMemories();
  }

  Future<void> refresh() async {
    await _loadMemories();
  }

  Future<void> _loadMemories() async {
    setState(() {
      _loading = true;
      _error = false;
    });

    try {
      final memories = await _memoryService.getAllMemories();
      if (memories.isEmpty) {
        if (!mounted) return;
        setState(() {
          _grouped = {};
          _loading = false;
        });
        return;
      }

      final grouped = <String, List<MemoryGroupItem>>{};
      await Future.wait(
        memories.map((memory) async {
          final resolved = await _memoryService.resolveImagePaths(
            memory.imagePaths,
          );
          final validPaths = resolved
              .where((path) => path.isNotEmpty && File(path).existsSync())
              .toList();
          if (validPaths.isEmpty) return;

          final key = _dayFormatter.format(memory.createdAt.toLocal());
          grouped
              .putIfAbsent(key, () => <MemoryGroupItem>[])
              .add(
                MemoryGroupItem(entry: memory, resolvedImagePaths: validPaths),
              );
        }),
      );

      if (!mounted) return;
      setState(() {
        _grouped = grouped;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  Future<void> _handleDelete(ObjectId id) async {
    try {
      await _memoryService.deleteMemory(id);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(const SnackBar(content: Text('Memory deleted')));
    } catch (_) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not delete memory')),
      );
    }
    await _loadMemories();
  }

  void _openMemory(MemoryGroupItem memory) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MemoryDetailScreen(
          memory: memory,
          onDelete: () async {
            Navigator.of(context).pop();
            await _handleDelete(memory.entry.id);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final keys = _grouped.keys.toList()..sort((a, b) => _compareKeysDesc(a, b));

    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF115e5a)),
      );
    }

    if (_error) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 36),
            const SizedBox(height: 12),
            Text(
              'Could not load memories',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(onPressed: _loadMemories, child: const Text('Retry')),
          ],
        ),
      );
    }

    final bool isEmpty = keys.isEmpty;
    if (isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                'assets/images/empty_memories.svg',
                width: 250,
                height: 250,
              ),
              const SizedBox(height: 16),
              Text(
                'No memories yet',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontFamily: AppTypography.primaryFontFamily,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Flatten all memories into a single list
    final allMemories = <MemoryGroupItem>[];
    for (final key in keys) {
      allMemories.addAll(_grouped[key] ?? const <MemoryGroupItem>[]);
    }

    return RefreshIndicator(
      onRefresh: _loadMemories,
      color: const Color(0xFF115e5a),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 104),
        itemCount: allMemories.length,
        itemBuilder: (context, index) {
          final memory = allMemories[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 32),
            child: _MemoryCard(item: memory, onOpen: _openMemory),
          );
        },
      ),
    );
  }

  int _compareKeysDesc(String a, String b) {
    try {
      final parsedA = _dayFormatter.parse(a);
      final parsedB = _dayFormatter.parse(b);
      return parsedB.compareTo(parsedA);
    } catch (_) {
      return b.compareTo(a);
    }
  }

  @override
  bool get wantKeepAlive => true;
}

class MemoryGroupItem {
  const MemoryGroupItem({
    required this.entry,
    required this.resolvedImagePaths,
  });

  final MemoryEntryRealm entry;
  final List<String> resolvedImagePaths;
}

class _MemoryCard extends StatefulWidget {
  const _MemoryCard({required this.item, required this.onOpen});

  final MemoryGroupItem item;
  final ValueChanged<MemoryGroupItem> onOpen;

  @override
  State<_MemoryCard> createState() => _MemoryCardState();
}

class _MemoryCardState extends State<_MemoryCard> {
  String? _dateRange;
  bool _loadingDates = true;

  @override
  void initState() {
    super.initState();
    _extractDateRange();
  }

  Future<void> _extractDateRange() async {
    try {
      final dates = <DateTime>[];

      // Extract dates from first 5 images (highlights)
      final mediaToCheck = widget.item.resolvedImagePaths.take(5).toList();

      for (final path in mediaToCheck) {
        if (_isVideo(path)) {
          // For videos, use file modification date
          final stat = await File(path).stat();
          dates.add(stat.modified);
        } else {
          // For images, try EXIF
          final date = await _getImageDate(path);
          if (date != null) {
            dates.add(date);
          }
        }
      }

      if (dates.isEmpty) {
        // Fallback to entry creation date
        dates.add(widget.item.entry.createdAt.toLocal());
      }

      // Sort dates
      dates.sort();

      // Format date range
      final formatter = DateFormat('d MMM');
      final firstDate = dates.first;
      final lastDate = dates.last;

      String range;
      if (firstDate.year == lastDate.year &&
          firstDate.month == lastDate.month &&
          firstDate.day == lastDate.day) {
        // Same day
        range = formatter.format(firstDate);
      } else {
        // Date range
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
          ).format(widget.item.entry.createdAt.toLocal());
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

  @override
  Widget build(BuildContext context) {
    final itemCount = widget.item.resolvedImagePaths.length;
    final title = widget.item.entry.caption;

    // Get first 5 media items for grid (highlights)
    final gridMedia = widget.item.resolvedImagePaths.take(5).toList();

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => widget.onOpen(widget.item),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date and item count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                if (_loadingDates)
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 1.5),
                  )
                else
                  Text(
                    _dateRange ?? '',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6A7F81),
                    ),
                  ),
                const Text(
                  ' • ',
                  style: TextStyle(fontSize: 13, color: Color(0xFF6A7F81)),
                ),
                Text(
                  '$itemCount item${itemCount > 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6A7F81),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              title?.isEmpty ?? true ? 'Untitled Memory' : title!,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 12),

          // Image grid (1 large on left, 4 small on right)
          _buildImageGrid(gridMedia),
        ],
      ),
    );
  }

  Widget _buildImageGrid(List<String> media) {
    if (media.isEmpty) {
      return Container(
        height: 280,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Icon(Icons.photo_library_outlined, size: 48),
        ),
      );
    }

    return SizedBox(
      height: 280,
      child: Row(
        children: [
          // Large image on the left
          Expanded(
            flex: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildMediaThumbnail(media[0]),
            ),
          ),
          const SizedBox(width: 6),

          // 4 smaller images on the right (or less if not enough media)
          Expanded(flex: 1, child: _buildRightGrid(media)),
        ],
      ),
    );
  }

  Widget _buildRightGrid(List<String> media) {
    return Column(
      children: [
        // Top image (or empty if only 1 media)
        if (media.length > 1)
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildMediaThumbnail(media[1]),
            ),
          )
        else
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        const SizedBox(height: 6),

        // Middle image (or empty if only 2 media)
        if (media.length > 2)
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildMediaThumbnail(media[2]),
            ),
          )
        else
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        const SizedBox(height: 6),

        // Bottom row with 2 images
        Expanded(
          child: Row(
            children: [
              // Bottom left
              if (media.length > 3)
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _buildMediaThumbnail(media[3]),
                  ),
                )
              else
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              const SizedBox(width: 6),

              // Bottom right
              if (media.length > 4)
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _buildMediaThumbnail(media[4]),
                  ),
                )
              else
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMediaThumbnail(String path) {
    final isVideo = _isVideo(path);

    return Stack(
      fit: StackFit.expand,
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
            color: Colors.black26,
            child: const Center(
              child: Icon(
                Icons.play_circle_fill,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
      ],
    );
  }
}
