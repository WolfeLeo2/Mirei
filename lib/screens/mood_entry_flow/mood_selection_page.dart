import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/mood_colors.dart';
import 'dart:math' as math;

class MoodSelectionPage extends StatefulWidget {
  final String username;
  final Function(String mood, double gaugeValue) onContinue;
  final Function(String mood) onSaveAndSkip;
  final String? initialMood;
  final double? initialGaugeValue;

  const MoodSelectionPage({
    super.key,
    required this.username,
    required this.onContinue,
    required this.onSaveAndSkip,
    this.initialMood,
    this.initialGaugeValue,
  });

  @override
  State<MoodSelectionPage> createState() => _MoodSelectionPageState();
}

class _MoodSelectionPageState extends State<MoodSelectionPage> {
  // Mood configuration with ranges
  static const List<Map<String, dynamic>> moodStops = [
    {
      'mood': 'Angry',
      'range': [0, 20],
      'icon': 'assets/emotion-icons/angry.svg',
    },
    {
      'mood': 'Sad',
      'range': [20, 40],
      'icon': 'assets/emotion-icons/sad.svg',
    },
    {
      'mood': 'Worried',
      'range': [40, 55],
      'icon': 'assets/emotion-icons/worried.svg',
    },
    {
      'mood': 'Neutral',
      'range': [55, 70],
      'icon': 'assets/emotion-icons/neutral.svg',
    },
    {
      'mood': 'Happy',
      'range': [70, 85],
      'icon': 'assets/emotion-icons/happy.svg',
    },
    {
      'mood': 'Cutesy',
      'range': [85, 100],
      'icon': 'assets/emotion-icons/cutesy.svg',
    },
  ];

  late double _gaugeValue;
  late String _currentMood;

  @override
  void initState() {
    super.initState();
    _gaugeValue = widget.initialGaugeValue ?? 55.0;
    _currentMood = widget.initialMood ?? 'Neutral';
    _updateMoodFromValue();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  void _updateMoodFromValue() {
    for (var stop in moodStops) {
      final range = stop['range'] as List<int>;
      if (_gaugeValue >= range[0] && _gaugeValue <= range[1]) {
        setState(() {
          _currentMood = stop['mood'] as String;
        });
        break;
      }
    }
  }

  Color _getMoodColor() {
    final moodColors = Theme.of(context).extension<MoodColors>();
    if (moodColors == null) return const Color(0xFF115e5a);
    return moodColors.byMood(_currentMood);
  }

  String _getMoodIcon() {
    for (var stop in moodStops) {
      if (stop['mood'] == _currentMood) {
        return stop['icon'] as String;
      }
    }
    return 'assets/emotion-icons/neutral.svg';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFfaf6f1),
      appBar: AppBar(
        backgroundColor: const Color(0xFFfaf6f1),
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle
            .dark, // Dark status bar icons for light background
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios),
          color: Colors.black87,
        ),
        centerTitle: true,
        title: Text(
          _getGreeting(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            fontFamily: AppTypography.primaryFontFamily,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 12),

            // Main question
            const Text(
              'How Do You Feel\nToday?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                height: 1.2,
                letterSpacing: -0.5,
              ),
            ),

            const SizedBox(height: 32),

            // Mood illustration
            Hero(
              tag: 'mood_icon',
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getMoodColor().withOpacity(0.1),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    _getMoodIcon(),
                    width: 110,
                    height: 110,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Mood label
            Text(
              _currentMood,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: _getMoodColor(),
                fontFamily: AppTypography.primaryFontFamily,
              ),
            ),

            const Spacer(),

            // Radial gauge
            SizedBox(
              height: 180,
              child: RadialMoodGauge(
                value: _gaugeValue,
                onChanged: (value) {
                  setState(() {
                    _gaugeValue = value;
                    _updateMoodFromValue();
                  });
                },
                moodStops: moodStops,
                currentMood: _currentMood,
              ),
            ),

            const SizedBox(height: 32),

            // Continue button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: () {
                  widget.onContinue(_currentMood, _gaugeValue);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: _getMoodColor(),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Save and skip button
            TextButton(
              onPressed: () {
                widget.onSaveAndSkip(_currentMood);
              },
              child: Text(
                'Save and Skip',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// Custom radial gauge widget
class RadialMoodGauge extends StatefulWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final List<Map<String, dynamic>> moodStops;
  final String currentMood;

  const RadialMoodGauge({
    super.key,
    required this.value,
    required this.onChanged,
    required this.moodStops,
    required this.currentMood,
  });

  @override
  State<RadialMoodGauge> createState() => _RadialMoodGaugeState();
}

class _RadialMoodGaugeState extends State<RadialMoodGauge> {
  String _lastMood = '';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        // Calculate angle from center
        final RenderBox box = context.findRenderObject() as RenderBox;
        final center = Offset(box.size.width / 2, box.size.height / 2);
        final position = box.globalToLocal(details.globalPosition);

        // Calculate angle (-180 to 180)
        double angle = math.atan2(
          position.dy - center.dy,
          position.dx - center.dx,
        );

        // Convert to 0-180 range (bottom semicircle)
        angle = angle * 180 / math.pi;
        if (angle < 0) angle += 360;

        // Map angle to value (180 to 360 degrees = 0 to 100 value)
        if (angle >= 180 && angle <= 360) {
          final normalizedAngle = (angle - 180) / 180;
          final newValue = normalizedAngle * 100;
          widget.onChanged(newValue.clamp(0, 100));

          // Haptic feedback on mood change
          if (_lastMood != widget.currentMood) {
            HapticFeedback.selectionClick();
            _lastMood = widget.currentMood;
          }
        }
      },
      child: CustomPaint(
        size: const Size(double.infinity, 200),
        painter: RadialGaugePainter(
          value: widget.value,
          moodStops: widget.moodStops,
        ),
      ),
    );
  }
}

class RadialGaugePainter extends CustomPainter {
  final double value;
  final List<Map<String, dynamic>> moodStops;

  RadialGaugePainter({required this.value, required this.moodStops});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height - 20);
    final radius = size.width * 0.4;

    // Draw gauge background arc
    final backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi, // Start at 180 degrees (left)
      math.pi, // Sweep 180 degrees (semicircle)
      false,
      backgroundPaint,
    );

    // Draw mood stop markers
    for (int i = 0; i <= 100; i += 20) {
      final angle = math.pi + (i / 100) * math.pi;
      final markerRadius = (i % 20 == 0) ? radius + 15 : radius + 10;
      final markerStart = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      final markerEnd = Offset(
        center.dx + markerRadius * math.cos(angle),
        center.dy + markerRadius * math.sin(angle),
      );

      final markerPaint = Paint()
        ..color = Colors.black.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = (i % 20 == 0) ? 2 : 1.5;

      canvas.drawLine(markerStart, markerEnd, markerPaint);

      // Draw labels for major stops
      if (i % 20 == 0) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: '$i',
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();

        final labelOffset = Offset(
          center.dx +
              (markerRadius + 20) * math.cos(angle) -
              textPainter.width / 2,
          center.dy +
              (markerRadius + 20) * math.sin(angle) -
              textPainter.height / 2,
        );

        textPainter.paint(canvas, labelOffset);
      }
    }

    // Draw active arc (from 0 to current value)
    final activePaint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.red, Colors.orange, Colors.yellow, Colors.green],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    final sweepAngle = (value / 100) * math.pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      sweepAngle,
      false,
      activePaint,
    );

    // Draw indicator circle
    final indicatorAngle = math.pi + sweepAngle;
    final indicatorPosition = Offset(
      center.dx + radius * math.cos(indicatorAngle),
      center.dy + radius * math.sin(indicatorAngle),
    );

    final indicatorPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill
      ..strokeWidth = 4;

    canvas.drawCircle(indicatorPosition, 12, indicatorPaint);

    final indicatorBorderPaint = Paint()
      ..color = const Color(0xFF6B4EFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    canvas.drawCircle(indicatorPosition, 12, indicatorBorderPaint);
  }

  @override
  bool shouldRepaint(RadialGaugePainter oldDelegate) {
    return oldDelegate.value != value;
  }
}
