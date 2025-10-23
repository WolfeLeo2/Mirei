import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';

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
  int _currentImageIndex = 0;

  void _openImagePreview(String imagePath) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _ImagePreviewScreen(imagePath: imagePath),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final caption = widget.memory.entry.caption;
    final formattedDate = DateFormat(
      'MMM d, yyyy • h:mm a',
    ).format(widget.memory.entry.createdAt.toLocal());

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.close, color: Colors.white),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () async {
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
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.of(context).pop(true),
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
            },
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_outline, color: Colors.white),
            ),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Blurred background
          if (widget.memory.resolvedImagePaths.isNotEmpty)
            Image.file(
              File(widget.memory.resolvedImagePaths.first),
              fit: BoxFit.cover,
            ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: Container(color: Colors.black.withOpacity(0.3)),
          ),
          // Content
          SafeArea(
            child: Column(
              children: [
                // Card swiper for images
                Expanded(
                  child: widget.memory.resolvedImagePaths.length == 1
                      ? _SingleImageView(
                          imagePath: widget.memory.resolvedImagePaths.first,
                          onTap: () => _openImagePreview(
                            widget.memory.resolvedImagePaths.first,
                          ),
                        )
                      : CardSwiper(
                          cardsCount: widget.memory.resolvedImagePaths.length,
                          onSwipe: (previousIndex, currentIndex, direction) {
                            setState(() {
                              _currentImageIndex = currentIndex ?? 0;
                            });
                            return true;
                          },
                          cardBuilder:
                              (
                                context,
                                index,
                                percentThresholdX,
                                percentThresholdY,
                              ) {
                                final imagePath =
                                    widget.memory.resolvedImagePaths[index];
                                return GestureDetector(
                                  onTap: () => _openImagePreview(imagePath),
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 32,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0x40000000),
                                          blurRadius: 24,
                                          offset: Offset(0, 12),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: Image.file(
                                        File(imagePath),
                                        fit: BoxFit.contain,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Container(
                                                  color: const Color(
                                                    0xFFE6EEEF,
                                                  ),
                                                  child: const Icon(
                                                    Icons.broken_image_outlined,
                                                    size: 64,
                                                    color: Color(0xFF6A7F81),
                                                  ),
                                                ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                        ),
                ),
                // Bottom info panel
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x20000000),
                        blurRadius: 20,
                        offset: Offset(0, -8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image indicator
                      if (widget.memory.resolvedImagePaths.length > 1)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              widget.memory.resolvedImagePaths.length,
                              (index) => Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: index == _currentImageIndex
                                      ? const Color(0xFF115e5a)
                                      : const Color(0xFFD0D5D6),
                                ),
                              ),
                            ),
                          ),
                        ),
                      // Caption
                      if (caption != null && caption.trim().isNotEmpty) ...[
                        Text(
                          caption.trim(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      // Date
                      Text(
                        formattedDate,
                        style: const TextStyle(
                          color: Color(0xFF6A7F81),
                          fontSize: 14,
                        ),
                      ),
                    ],
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

class _SingleImageView extends StatelessWidget {
  const _SingleImageView({required this.imagePath, required this.onTap});

  final String imagePath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x40000000),
              blurRadius: 24,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.file(
            File(imagePath),
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Container(
              color: const Color(0xFFE6EEEF),
              child: const Icon(
                Icons.broken_image_outlined,
                size: 64,
                color: Color(0xFF6A7F81),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ImagePreviewScreen extends StatelessWidget {
  const _ImagePreviewScreen({required this.imagePath});

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.close, color: Colors.white),
          ),
        ),
      ),
      body: PhotoView(
        imageProvider: FileImage(File(imagePath)),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 2,
        backgroundDecoration: const BoxDecoration(color: Colors.black),
        loadingBuilder: (context, event) =>
            const Center(child: CircularProgressIndicator(color: Colors.white)),
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Icon(
            Icons.broken_image_outlined,
            size: 64,
            color: Colors.white54,
          ),
        ),
      ),
    );
  }
}
