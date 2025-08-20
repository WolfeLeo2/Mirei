import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import '../../models/realm_models.dart';
import '../../utils/image_loader.dart';

/// Widget that handles image loading for folder previews with performance optimizations
class FolderImageWidget extends StatefulWidget {
  final String monthKey;
  final List<JournalEntryRealm> entries;
  final bool isLargeSize;
  final Widget child;

  const FolderImageWidget({
    super.key,
    required this.monthKey,
    required this.entries,
    required this.isLargeSize,
    required this.child,
  });

  @override
  State<FolderImageWidget> createState() => _FolderImageWidgetState();
}

class _FolderImageWidgetState extends State<FolderImageWidget> {
  List<ui.Image?> _previewImages = [];
  bool _isLoading = false;
  String? _cachedPathsHash; // Cache key for avoiding unnecessary reloads
  
  // Static cache to share images across multiple widgets
  static final Map<String, List<ui.Image?>> _imageCache = {};
  static const int _maxCacheSize = 50; // Limit memory usage

  @override
  void initState() {
    super.initState();
    _loadPreviewImagesOptimized();
  }

  @override
  void didUpdateWidget(FolderImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only reload if entries actually changed (not just reference)
    if (_hasEntriesChanged(oldWidget.entries, widget.entries)) {
      _loadPreviewImagesOptimized();
    }
  }

  @override
  void dispose() {
    // Clear cache if it gets too large to prevent memory leaks
    if (_imageCache.length > _maxCacheSize) {
      _imageCache.clear();
    }
    super.dispose();
  }

  /// Optimized change detection to avoid unnecessary reloads
  bool _hasEntriesChanged(List<JournalEntryRealm> oldEntries, List<JournalEntryRealm> newEntries) {
    if (oldEntries.length != newEntries.length) return true;
    
    // Quick check on first few entries (most likely to change)
    final checkCount = math.min(5, oldEntries.length);
    for (int i = 0; i < checkCount; i++) {
      if (oldEntries[i].createdAt != newEntries[i].createdAt) return true;
    }
    return false;
  }

  /// Extract 4 most recent image paths from entries with caching
  List<String> _getRecentImagePaths() {
    final allImagePaths = <String>[];
    
    // Debug: Show total entries available
    print('📊 [${widget.monthKey}] Total entries available: ${widget.entries.length}');
    
    // Sort ALL entries by date first, then take top 20 for optimization
    final allSorted = List<JournalEntryRealm>.from(widget.entries);
    allSorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final sortedEntries = allSorted.take(20).toList();
    
    // Debug: Show what we're working with
    print('📋 [${widget.monthKey}] Analyzing ${sortedEntries.length} newest entries for images:');
    
    // Collect image paths from newest entries
    for (int i = 0; i < sortedEntries.length; i++) {
      final entry = sortedEntries[i];
      print('   Entry $i: ${entry.imagePaths.length} images');
      
      if (entry.imagePaths.isNotEmpty) {
        final beforeCount = allImagePaths.length;
        allImagePaths.addAll(entry.imagePaths);
        final addedCount = allImagePaths.length - beforeCount;
        print('     Added $addedCount images (total: ${allImagePaths.length})');
        
        if (allImagePaths.length >= 4) {
          print('     ✅ Reached 4 images, stopping search');
          break;
        }
      }
    }
    
    // Return up to 4 most recent images
    final result = allImagePaths.take(4).toList();
    
    // Debug: Print info about image extraction
    print('📁 [${widget.monthKey}] Found ${result.length} images from ${sortedEntries.length} entries');
    if (result.isNotEmpty) {
      print('   Images: ${result.map((p) => p.split('/').last).join(', ')}');
    }
    
    return result;
  }

  /// Check if image paths have changed to avoid unnecessary reloads
  bool _shouldReloadImages() {
    final currentPathsHash = _generatePathsHash();
    if (_cachedPathsHash != currentPathsHash || _previewImages.isEmpty) {
      _cachedPathsHash = currentPathsHash;
      return true;
    }
    return false;
  }

  /// Generate hash for current image paths to detect changes
  String _generatePathsHash() {
    final paths = <String>[];
    
    // Use same logic as main extraction
    final allSorted = List<JournalEntryRealm>.from(widget.entries);
    allSorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final limitedEntries = allSorted.take(20).toList();
    
    for (final entry in limitedEntries) {
      if (entry.imagePaths.isNotEmpty) {
        paths.addAll(entry.imagePaths); // Add ALL images, not just first
        if (paths.length >= 4) break;
    }
    }
    return paths.take(4).join('|'); // Take up to 4 for hash
  }

  Future<void> _loadPreviewImagesOptimized() async {
    // Check if we need to reload images
    if (!_shouldReloadImages()) {
      return; // Use cached images
    }
    
    final imagePaths = _getRecentImagePaths();
    
    if (imagePaths.isEmpty) {
      if (mounted) {
        setState(() {
          _previewImages = [];
          _isLoading = false;
        });
      }
      return;
    }

    // Check cache first
    final cacheKey = '${widget.monthKey}_${imagePaths.join('_')}';
    if (_imageCache.containsKey(cacheKey)) {
      if (mounted) {
      setState(() {
          _previewImages = _imageCache[cacheKey]!;
        _isLoading = false;
      });
      }
      return;
    }

    if (mounted) {
    setState(() {
      _isLoading = true;
    });
    }

    try {
      final loadedImages = <ui.Image?>[];
      
      // Debug: Track image loading
      print('🖼️ [${widget.monthKey}] Loading ${imagePaths.length} images...');
      
      // Load images in parallel for better performance
      final futures = imagePaths.map((imagePath) async {
        try {
          print('   Loading: ${imagePath.split('/').last}');
          
          // Handle test images gracefully
          if (imagePath.startsWith('test_images/')) {
            print('   📋 Test image detected, returning null for placeholder');
            return null; // Test images will show as placeholders
          }
          
          final image = await ImageLoader.loadImageFromPath(imagePath);
          print('   ✅ Loaded: ${imagePath.split('/').last}');
          return image;
        } catch (e) {
          print('   ❌ Failed: ${imagePath.split('/').last} - $e');
          return null; // Return null for failed loads
        }
      }).toList();
      
      final results = await Future.wait(futures);
      loadedImages.addAll(results);
      
      // Debug: Report results
      final successCount = loadedImages.where((img) => img != null).length;
      print('🎯 [${widget.monthKey}] Loaded $successCount/${imagePaths.length} images successfully');
      
      // Cache the results
      _imageCache[cacheKey] = loadedImages;
      
      if (mounted) {
        setState(() {
          _previewImages = loadedImages;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _previewImages = [];
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary( // Optimize repaints
      child: CustomPaint(
      painter: EnhancedFolderPainter(
          previewImages: _previewImages,
        isLargeSize: widget.isLargeSize,
        isLoading: _isLoading,
      ),
      child: widget.child,
      ),
    );
  }
}

/// Enhanced folder painter that can work with loaded images
class EnhancedFolderPainter extends CustomPainter {
  final List<ui.Image?> previewImages;
  final bool isLargeSize;
  final bool isLoading;

  EnhancedFolderPainter({
    required this.previewImages,
    required this.isLargeSize,
    this.isLoading = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw in order: shadow, base, lip, content
    _drawFolderShadow(canvas, size);
    _drawFolderBase(canvas, size);
    _drawFolderLip(canvas, size);
    _drawPreviewContent(canvas, size);
    _drawFolderEdges(canvas, size);
  }

  /// Draws the folder shadow for depth
  void _drawFolderShadow(Canvas canvas, Size size) {
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final shadowRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(2, 10, size.width, size.height - 8),
      const Radius.circular(16),
    );

    canvas.drawRRect(shadowRect, shadowPaint);
  }

  /// Draws the main folder background with realistic depth
  void _drawFolderBase(Canvas canvas, Size size) {
    // Main folder body
    final basePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final baseRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 8, size.width, size.height - 8),
      const Radius.circular(16),
    );

    canvas.drawRRect(baseRect, basePaint);

    // Inner shadow for depth
    final innerShadowPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.topLeft,
        radius: 1.0,
        colors: [Colors.grey.withValues(alpha: 0.05), Colors.transparent],
      ).createShader(Rect.fromLTWH(0, 8, size.width, size.height - 8));

    canvas.drawRRect(baseRect, innerShadowPaint);
  }

  /// Draws the folder lip/tab for realistic appearance
  void _drawFolderLip(Canvas canvas, Size size) {
    final lipHeight = isLargeSize ? 20.0 : 16.0;
    final lipWidth = size.width * 0.4; // 40% of folder width

    // Main lip background
    final lipPaint = Paint()
      ..color = Colors.grey[50]!
      ..style = PaintingStyle.fill;

    final lipRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, lipWidth, lipHeight),
      const Radius.circular(12),
    );

    canvas.drawRRect(lipRect, lipPaint);

    // Lip gradient for depth
    final gradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.grey[100]!,
          Colors.grey[50]!,
          Colors.white.withValues(alpha: 0.8),
        ],
      ).createShader(Rect.fromLTWH(0, 0, lipWidth, lipHeight));

    canvas.drawRRect(lipRect, gradientPaint);

    // Lip edge highlight
    final edgePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawRRect(lipRect, edgePaint);
  }

  /// Draws subtle edges for folder depth
  void _drawFolderEdges(Canvas canvas, Size size) {
    final edgePaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // Right edge
    canvas.drawLine(
      Offset(size.width - 0.5, 8),
      Offset(size.width - 0.5, size.height),
      edgePaint,
    );

    // Bottom edge
    canvas.drawLine(
      Offset(0, size.height - 0.5),
      Offset(size.width, size.height - 0.5),
      edgePaint,
    );
  }

  /// Draws the preview content to make folder appear "full"
  void _drawPreviewContent(Canvas canvas, Size size) {
    if (isLoading) {
      _drawLoadingContent(canvas, size);
    } else if (previewImages.isNotEmpty) {
      _drawActualImage(canvas, size);
    } else {
      _drawPlaceholderContent(canvas, size);
    }
  }

  /// Draws loading indicator
  void _drawLoadingContent(Canvas canvas, Size size) {
    final contentPadding = isLargeSize ? 16.0 : 12.0;
    final bottomPadding = isLargeSize ? 100.0 : 80.0;

    final loadingPaint = Paint()
      ..color = Colors.grey[100]!
      ..style = PaintingStyle.fill;

    final loadingRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        contentPadding,
        20 + contentPadding,
        size.width - (contentPadding * 2),
        size.height - bottomPadding,
      ),
      const Radius.circular(8),
    );

    canvas.drawRRect(loadingRect, loadingPaint);

    // Simple loading indicator
    final indicatorPaint = Paint()
      ..color = Colors.grey[300]!
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2 - 20);
    canvas.drawCircle(center, 8, indicatorPaint);
  }

  /// Draws the actual loaded images in a 2x2 grid
  void _drawActualImage(Canvas canvas, Size size) {
    if (previewImages.isEmpty) return;

    final contentPadding = isLargeSize ? 16.0 : 12.0;
    final bottomPadding = isLargeSize ? 120.0 : 100.0; // More space for text below

    // Grid container - positioned higher up
    final gridRect = Rect.fromLTWH(
      contentPadding,
      20 + contentPadding, // Start from top
      size.width - (contentPadding * 2),
      size.height - bottomPadding, // Leave space for text
    );

    // Calculate grid cell size
    const spacing = 4.0; // Gap between grid images
    final cellWidth = (gridRect.width - spacing) / 2;
    final cellHeight = (gridRect.height - spacing) / 2;

    final paint = Paint()..filterQuality = FilterQuality.medium;

    // Debug: Track image drawing
    print('🎨 [Drawing] ${previewImages.length} images available for 2x2 grid');
    int drawnCount = 0;

    // Draw up to 4 images in 2x2 grid
    for (int i = 0; i < math.min(4, previewImages.length); i++) {
      final image = previewImages[i];
      if (image == null) {
        print('   Skipping null image at position $i');
        continue;
      }

      // Calculate grid position (0,0), (1,0), (0,1), (1,1)
      final row = i ~/ 2;
      final col = i % 2;

      final cellRect = Rect.fromLTWH(
        gridRect.left + col * (cellWidth + spacing),
        gridRect.top + row * (cellHeight + spacing),
        cellWidth,
        cellHeight,
      );

      // Calculate scaling to fit image in cell while maintaining aspect ratio
      final imageSize = Size(image.width.toDouble(), image.height.toDouble());
      final scaleX = cellRect.width / imageSize.width;
      final scaleY = cellRect.height / imageSize.height;
      final scale = math.max(scaleX, scaleY); // Use max for crop effect

    final scaledWidth = imageSize.width * scale;
    final scaledHeight = imageSize.height * scale;

      // Center the image in the cell
      final offsetX = cellRect.left + (cellRect.width - scaledWidth) / 2;
      final offsetY = cellRect.top + (cellRect.height - scaledHeight) / 2;

    final destRect = Rect.fromLTWH(offsetX, offsetY, scaledWidth, scaledHeight);
    final srcRect = Rect.fromLTWH(0, 0, imageSize.width, imageSize.height);

      // Clip to rounded rectangle for each cell
    canvas.save();
    canvas.clipRRect(
        RRect.fromRectAndRadius(cellRect, const Radius.circular(6)),
    );

      canvas.drawImageRect(image, srcRect, destRect, paint);
    canvas.restore();

      // Add subtle border to each cell
      final borderPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

    canvas.drawRRect(
        RRect.fromRectAndRadius(cellRect, const Radius.circular(6)),
        borderPaint,
    );

      drawnCount++;
      print('   ✅ Drew image $i at position ($row,$col)');
    }

    print('🎨 [Drawing] Total images drawn: $drawnCount/${previewImages.length}');

    // If we have fewer than 4 images, fill remaining cells with placeholders
    for (int i = previewImages.length; i < 4; i++) {
      final row = i ~/ 2;
      final col = i % 2;

      final cellRect = Rect.fromLTWH(
        gridRect.left + col * (cellWidth + spacing),
        gridRect.top + row * (cellHeight + spacing),
        cellWidth,
        cellHeight,
      );

      // Draw placeholder
      final placeholderPaint = Paint()
        ..color = Colors.grey[100]!
      ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(cellRect, const Radius.circular(6)),
        placeholderPaint,
      );

      // Draw subtle icon
      final iconPaint = Paint()
        ..color = Colors.grey[300]!
        ..style = PaintingStyle.fill;

      final iconSize = math.min(cellWidth, cellHeight) * 0.3;
      final iconCenter = cellRect.center;
      canvas.drawCircle(iconCenter, iconSize / 2, iconPaint);
    }

    // Add overall grid shadow for depth
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.05)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    canvas.drawRRect(
      RRect.fromRectAndRadius(gridRect, const Radius.circular(8)),
      shadowPaint,
    );
  }

  /// Draws placeholder content when no image is available
  void _drawPlaceholderContent(Canvas canvas, Size size) {
    final contentPadding = isLargeSize ? 16.0 : 12.0;
    final bottomPadding = isLargeSize ? 100.0 : 80.0;

    final placeholderPaint = Paint()
      ..color = Colors.grey[100]!
      ..style = PaintingStyle.fill;

    final placeholderRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        contentPadding,
        20 + contentPadding,
        size.width - (contentPadding * 2),
        size.height - bottomPadding,
      ),
      const Radius.circular(8),
    );

    canvas.drawRRect(placeholderRect, placeholderPaint);

    // Draw multiple "document" layers for depth
    _drawDocumentLayers(canvas, placeholderRect.outerRect);

    // Draw folder icon in center
    _drawFolderIcon(canvas, size);
  }

  /// Draws multiple document layers to simulate folder contents
  void _drawDocumentLayers(Canvas canvas, Rect baseRect) {
    final layerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    // Draw 3 layers with slight offsets
    for (int i = 0; i < 3; i++) {
      final offset = i * 2.0;
      final layerRect = RRect.fromRectAndRadius(
        baseRect.translate(offset, offset).deflate(offset),
        const Radius.circular(6),
      );

      // Shadow first
      canvas.drawRRect(layerRect.shift(const Offset(1, 1)), shadowPaint);
      // Then the layer
      canvas.drawRRect(layerRect, layerPaint);
    }
  }

  /// Draws a folder icon in the center
  void _drawFolderIcon(Canvas canvas, Size size) {
    final iconPaint = Paint()
      ..color = Colors.grey[400]!
      ..style = PaintingStyle.fill;

    final iconSize = isLargeSize ? 32.0 : 24.0;
    final center = Offset(size.width / 2, size.height / 2 - 20);

    // Folder base
    final folderRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: iconSize, height: iconSize * 0.8),
      const Radius.circular(3),
    );

    canvas.drawRRect(folderRect, iconPaint);

    // Folder tab
    final tabRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: center.translate(-iconSize * 0.2, -iconSize * 0.3),
        width: iconSize * 0.6,
        height: iconSize * 0.2,
      ),
      const Radius.circular(2),
    );

    canvas.drawRRect(tabRect, iconPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is! EnhancedFolderPainter) return true;
    
    // Compare list lengths first
    if (oldDelegate.previewImages.length != previewImages.length) return true;
    
    // Compare each image in the list
    for (int i = 0; i < previewImages.length; i++) {
      if (oldDelegate.previewImages[i] != previewImages[i]) return true;
    }
    
    return oldDelegate.isLargeSize != isLargeSize ||
        oldDelegate.isLoading != isLoading;
  }
}
