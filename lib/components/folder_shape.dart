import 'package:flutter/material.dart';

class FolderPainter extends CustomPainter {
  final Color fillColor;
  final Color borderColor;

  FolderPainter({required this.fillColor, required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double r = 18.0; // corner radius

    // Notch parameters
    final double notchStartX = 70.0;
    final double notchWidth = 80.0;
    final double notchDepth = 16.0;

    final Path path = Path();

    // Start at top-left corner (after radius)
    path.moveTo(r, 0);

    // Top edge to notch start
    path.lineTo(notchStartX, 0);

    // Concave notch using cubic bezier
    path.cubicTo(
      notchStartX + notchWidth * 0.20,
      0,
      notchStartX + notchWidth * 0.25,
      notchDepth,
      notchStartX + notchWidth * 0.35,
      notchDepth,
    );
    path.cubicTo(
      notchStartX + notchWidth * 0.60,
      notchDepth,
      notchStartX + notchWidth * 0.65,
      0,
      notchStartX + notchWidth,
      0,
    );

    // Top edge to before top-right corner
    path.lineTo(w - r, 0);
    // Top-right corner arc
    path.quadraticBezierTo(w, 0, w, r);

    // Right edge
    path.lineTo(w, h - r);
    // Bottom-right corner arc
    path.quadraticBezierTo(w, h, w - r, h);

    // Bottom edge
    path.lineTo(r, h);
    // Bottom-left corner arc
    path.quadraticBezierTo(0, h, 0, h - r);

    // Left edge
    path.lineTo(0, r);
    // Top-left corner arc
    path.quadraticBezierTo(0, 0, r, 0);

    // Fill
    final Paint fill = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fill);

    // Stroke
    final Paint stroke = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant FolderPainter oldDelegate) {
    return oldDelegate.fillColor != fillColor ||
        oldDelegate.borderColor != borderColor;
  }
}

// Provided folder shape painter (parameterized and defaulted to white)
class RPSCustomPainter extends CustomPainter {
  final Color flapColor;
  final Color bodyColor;
  final Color? borderColor;

  const RPSCustomPainter({
    this.flapColor = Colors.white,
    this.bodyColor = Colors.white,
    this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    Path path0 = Path();
    path0.moveTo(size.width * 0.8823200, size.height * 0.2189600);
    path0.lineTo(size.width * 0.4607600, size.height * 0.2189600);
    path0.lineTo(size.width * 0.3670800, size.height * 0.1252800);
    path0.lineTo(size.width * 0.1328800, size.height * 0.1252800);
    path0.cubicTo(
      size.width * 0.08135600,
      size.height * 0.1252800,
      size.width * 0.03920000,
      size.height * 0.1674360,
      size.width * 0.03920000,
      size.height * 0.2189600,
    );
    path0.lineTo(size.width * 0.03920000, size.height * 0.4063200);
    path0.lineTo(size.width * 0.9760000, size.height * 0.4063200);
    path0.lineTo(size.width * 0.9760000, size.height * 0.3126400);
    path0.cubicTo(
      size.width * 0.9760000,
      size.height * 0.2611160,
      size.width * 0.9338440,
      size.height * 0.2189600,
      size.width * 0.8823200,
      size.height * 0.2189600,
    );
    path0.close();

    final Paint paint0Fill = Paint()..style = PaintingStyle.fill;
    paint0Fill.color = flapColor;
    canvas.drawPath(path0, paint0Fill);

    Path path1 = Path();
    path1.moveTo(size.width * 0.8823200, size.height * 0.2189600);
    path1.lineTo(size.width * 0.1328800, size.height * 0.2189600);
    path1.cubicTo(
      size.width * 0.08135600,
      size.height * 0.2189600,
      size.width * 0.03920000,
      size.height * 0.2611160,
      size.width * 0.03920000,
      size.height * 0.3126400,
    );
    path1.lineTo(size.width * 0.03920000, size.height * 0.7810400);
    path1.cubicTo(
      size.width * 0.03920000,
      size.height * 0.8325640,
      size.width * 0.08135600,
      size.height * 0.8747200,
      size.width * 0.1328800,
      size.height * 0.8747200,
    );
    path1.lineTo(size.width * 0.8823200, size.height * 0.8747200);
    path1.cubicTo(
      size.width * 0.9338440,
      size.height * 0.8747200,
      size.width * 0.9760000,
      size.height * 0.8325640,
      size.width * 0.9760000,
      size.height * 0.7810400,
    );
    path1.lineTo(size.width * 0.9760000, size.height * 0.3126400);
    path1.cubicTo(
      size.width * 0.9760000,
      size.height * 0.2611160,
      size.width * 0.9338440,
      size.height * 0.2189600,
      size.width * 0.8823200,
      size.height * 0.2189600,
    );
    path1.close();

    // Soft drop shadow behind the body
    canvas.drawShadow(path1, Colors.black.withOpacity(0.12), 6.0, true);

    final Paint paint1Fill = Paint()..style = PaintingStyle.fill;
    paint1Fill.color = bodyColor;
    canvas.drawPath(path1, paint1Fill);

    if (borderColor != null) {
      final stroke = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = borderColor!;
      canvas.drawPath(path0, stroke);
      canvas.drawPath(path1, stroke);
    }
  }

  @override
  bool shouldRepaint(covariant RPSCustomPainter oldDelegate) {
    return oldDelegate.flapColor != flapColor ||
        oldDelegate.bodyColor != bodyColor ||
        oldDelegate.borderColor != borderColor;
  }
}
