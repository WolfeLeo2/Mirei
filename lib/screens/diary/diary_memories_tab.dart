import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:realm/realm.dart';

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
              const Icon(
                Icons.auto_awesome,
                size: 64,
                color: Color(0xFF115e5a),
              ),
              const SizedBox(height: 16),
              Text(
                'No memories yet',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontFamily: AppTypography.primaryFontFamily,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Capture special moments with the + button.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMemories,
      color: const Color(0xFF115e5a),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 104),
        itemCount: keys.length,
        itemBuilder: (context, index) {
          final key = keys[index];
          final items = _grouped[key] ?? const <MemoryGroupItem>[];
          return Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: _MemoryGroup(label: key, items: items, onOpen: _openMemory),
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

class _MemoryGroup extends StatelessWidget {
  const _MemoryGroup({
    required this.label,
    required this.items,
    required this.onOpen,
  });

  final String label;
  final List<MemoryGroupItem> items;
  final ValueChanged<MemoryGroupItem> onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.titleMedium?.copyWith(
            fontFamily: AppTypography.primaryFontFamily,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            const spacing = 12.0;
            final width = constraints.maxWidth;
            final columns = width > 640 ? 3 : 2;
            final itemWidth = (width - (spacing * (columns - 1))) / columns;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: items
                  .map(
                    (item) => SizedBox(
                      width: itemWidth,
                      child: _MemoryCard(item: item, onOpen: onOpen),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _MemoryCard extends StatelessWidget {
  const _MemoryCard({required this.item, required this.onOpen});

  final MemoryGroupItem item;
  final ValueChanged<MemoryGroupItem> onOpen;

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('MMM d, yyyy');
    final formattedDate = dateFormatter.format(item.entry.createdAt.toLocal());

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => onOpen(item),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image stack
          AspectRatio(
            aspectRatio: 3 / 4,
            child: Stack(
              children: [
                // Background cards to create stack effect
                if (item.resolvedImagePaths.length > 2)
                  Positioned(
                    top: 8,
                    left: 8,
                    right: 8,
                    bottom: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x14000000),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (item.resolvedImagePaths.length > 1)
                  Positioned(
                    top: 4,
                    left: 4,
                    right: 4,
                    bottom: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x18000000),
                            blurRadius: 10,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Front image
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: const BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x1F000000),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Image.file(
                        File(item.resolvedImagePaths.first),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: const Color(0xFFE6EEEF),
                          child: const Icon(
                            Icons.broken_image_outlined,
                            size: 48,
                            color: Color(0xFF6A7F81),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Photo count badge
                if (item.resolvedImagePaths.length > 1)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.photo_library,
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${item.resolvedImagePaths.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Date only
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              formattedDate,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4F5F60),
              ),
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}
