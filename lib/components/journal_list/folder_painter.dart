import 'package:flutter/material.dart';

/// CustomPainter for drawing folder appearance with preview image
class FolderPainter extends CustomPainter {
  final String? previewImagePath;
  final bool isLargeSize;

  FolderPainter({this.previewImagePath, required this.isLargeSize});

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
    if (previewImagePath != null) {
      _drawPreviewImage(canvas, size);
    } else {
      _drawPlaceholderContent(canvas, size);
    }
  }

  /// Draws the preview image positioned to look "inside" the folder
  void _drawPreviewImage(Canvas canvas, Size size) {
    final contentPadding = isLargeSize ? 16.0 : 12.0;
    final bottomPadding = isLargeSize ? 100.0 : 80.0;

    // Background for image area
    final bgPaint = Paint()
      ..color = Colors.grey[50]!
      ..style = PaintingStyle.fill;

    final imageRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        contentPadding,
        20 + contentPadding,
        size.width - (contentPadding * 2),
        size.height - bottomPadding,
      ),
      const Radius.circular(8),
    );

    canvas.drawRRect(imageRect, bgPaint);

    // Placeholder for actual image (will be implemented in next task)
    final imagePlaceholderPaint = Paint()
      ..color = Colors.grey[200]!
      ..style = PaintingStyle.fill;

    final placeholderRect = RRect.fromRectAndRadius(
      imageRect.outerRect.deflate(4),
      const Radius.circular(6),
    );

    canvas.drawRRect(placeholderRect, imagePlaceholderPaint);

    // Simulate image "peeking out" effect
    _drawPeekingEffect(canvas, imageRect.outerRect);

    // Add subtle overlay to simulate depth
    final overlayPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.3),
          Colors.transparent,
          Colors.black.withValues(alpha: 0.1),
        ],
      ).createShader(imageRect.outerRect);

    canvas.drawRRect(imageRect, overlayPaint);
  }

  /// Creates a "peeking out" effect for the image
  void _drawPeekingEffect(Canvas canvas, Rect imageRect) {
    final peekPaint = Paint()
      ..color = Colors.grey[300]!
      ..style = PaintingStyle.fill;

    // Small corner "peeking out"
    final peekPath = Path();
    peekPath.moveTo(imageRect.right - 20, imageRect.top);
    peekPath.lineTo(imageRect.right, imageRect.top);
    peekPath.lineTo(imageRect.right, imageRect.top + 20);
    peekPath.close();

    canvas.drawPath(peekPath, peekPaint);

    // Add small shadow to the peek
    final peekShadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    canvas.drawPath(peekPath, peekShadowPaint);
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
    return oldDelegate is! FolderPainter ||
        oldDelegate.previewImagePath != previewImagePath ||
        oldDelegate.isLargeSize != isLargeSize;
  }
}
