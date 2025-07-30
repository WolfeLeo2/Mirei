import 'package:flutter/material.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8E8E8),
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.black87,
                        size: 20,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        color: Colors.black87,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'February',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          fontFamily: '.SF Pro Display',
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(height: 2, width: 16, color: Colors.black87),
                        const SizedBox(height: 3),
                        Container(height: 2, width: 16, color: Colors.black87),
                        const SizedBox(height: 3),
                        Container(height: 2, width: 16, color: Colors.black87),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Main content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title with underline
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                          fontFamily: '.SF Pro Display',
                        ),
                        children: [
                          TextSpan(
                            text: 'This Is ',
                            style: TextStyle(
                              color: const Color(0xFF115e5a),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const TextSpan(text: 'a\nPercentage Of\nPast '),
                          TextSpan(
                            text: 'Feelings',
                            style: TextStyle(
                              color: const Color(0xFF115e5a),
                              decoration: TextDecoration.underline,
                              decorationColor: const Color(0xFF115e5a),
                              decorationThickness: 3,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Progress circles
                    Expanded(
                      child: Stack(
                        children: [
                          // Happy - Large green circle (top left, askew)
                          Positioned(
                            top: -20,
                            left: -40,
                            child: Transform.rotate(
                              angle: -0.2,
                              child: _buildProgressCircle(
                                '33%',
                                'Happy',
                                const Color(0xFF4CAF50),
                                200,
                                PatternType.diagonal,
                              ),
                            ),
                          ),
                          
                          // Flat - Medium yellow circle (top right, askew)
                          Positioned(
                            top: 20,
                            right: -30,
                            child: Transform.rotate(
                              angle: 0.3,
                              child: _buildProgressCircle(
                                '17%',
                                'Flat',
                                const Color(0xFFFFC107),
                                160,
                                PatternType.diagonal,
                              ),
                            ),
                          ),
                          
                          // Excited - Medium blue circle (middle right, askew)
                          Positioned(
                            top: 180,
                            right: -20,
                            child: Transform.rotate(
                              angle: -0.1,
                              child: _buildProgressCircle(
                                '31%',
                                'Excited',
                                const Color(0xFF00BCD4),
                                170,
                                PatternType.horizontal,
                              ),
                            ),
                          ),
                          
                          // Angry - Small pink circle (bottom left, askew)
                          Positioned(
                            bottom: 80,
                            left: -10,
                            child: Transform.rotate(
                              angle: 0.15,
                              child: _buildProgressCircle(
                                '19%',
                                'Angry',
                                const Color(0xFFE91E63),
                                140,
                                PatternType.none,
                              ),
                            ),
                          ),
                          
                          // Bottom text
                          Positioned(
                            bottom: 20,
                            right: 20,
                            child: SizedBox(
                              width: 180,
                              child: Text(
                                'I hope, you always feel good every day that passes',
                                style: TextStyle(
                                  color: const Color(0xFF115e5a),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  height: 1.3,
                                  fontFamily: '.SF Pro Text',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCircle(
    String percentage,
    String emotion,
    Color color,
    double size,
    PatternType pattern,
  ) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: ProgressCirclePainter(color: color, pattern: pattern),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                percentage,
                style: TextStyle(
                  color: color.computeLuminance() > 0.5
                      ? Colors.black87
                      : Colors.white,
                  fontSize: size * 0.2,
                  fontWeight: FontWeight.w800,
                  fontFamily: '.SF Pro Display',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '($emotion)',
                style: TextStyle(
                  color: color.computeLuminance() > 0.5
                      ? Colors.black54
                      : Colors.white70,
                  fontSize: size * 0.12,
                  fontWeight: FontWeight.w500,
                  fontFamily: '.SF Pro Text',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum PatternType { none, diagonal, horizontal }

class ProgressCirclePainter extends CustomPainter {
  final Color color;
  final PatternType pattern;

  ProgressCirclePainter({required this.color, required this.pattern});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw base circle
    final basePaint = Paint()
      ..color = color.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, basePaint);

    // Draw pattern
    final patternPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    switch (pattern) {
      case PatternType.diagonal:
        _drawDiagonalPattern(canvas, center, radius, patternPaint);
        break;
      case PatternType.horizontal:
        _drawHorizontalPattern(canvas, center, radius, patternPaint);
        break;
      case PatternType.none:
        break;
    }
  }

  void _drawDiagonalPattern(
    Canvas canvas,
    Offset center,
    double radius,
    Paint paint,
  ) {
    final spacing = 8.0;
    for (double i = -radius * 2; i <= radius * 2; i += spacing) {
      final path = Path();
      path.moveTo(center.dx + i - radius, center.dy - radius);
      path.lineTo(center.dx + i + radius, center.dy + radius);

      // Clip to circle
      canvas.save();
      canvas.clipPath(
        Path()..addOval(Rect.fromCircle(center: center, radius: radius)),
      );
      canvas.drawPath(path, paint);
      canvas.restore();
    }
  }

  void _drawHorizontalPattern(
    Canvas canvas,
    Offset center,
    double radius,
    Paint paint,
  ) {
    final spacing = 6.0;
    for (double i = center.dy - radius; i <= center.dy + radius; i += spacing) {
      canvas.save();
      canvas.clipPath(
        Path()..addOval(Rect.fromCircle(center: center, radius: radius)),
      );
      canvas.drawLine(
        Offset(center.dx - radius, i),
        Offset(center.dx + radius, i),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
