import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/mood_colors.dart';

class IntensityPage extends StatefulWidget {
  final String mood;
  final Function(int intensity) onContinue;
  final VoidCallback onBack;
  final int? initialIntensity;

  const IntensityPage({
    super.key,
    required this.mood,
    required this.onContinue,
    required this.onBack,
    this.initialIntensity,
  });

  @override
  State<IntensityPage> createState() => _IntensityPageState();
}

class _IntensityPageState extends State<IntensityPage> {
  late double _intensity;

  @override
  void initState() {
    super.initState();
    _intensity = widget.initialIntensity?.toDouble() ?? 5.0;
  }

  Color _getMoodColor() {
    final moodColors = Theme.of(context).extension<MoodColors>();
    if (moodColors == null) return const Color(0xFF115e5a);
    return moodColors.byMood(widget.mood);
  }

  String _getIntensityLabel() {
    if (_intensity <= 2) return 'Very Mild';
    if (_intensity <= 4) return 'Mild';
    if (_intensity <= 6) return 'Moderate';
    if (_intensity <= 8) return 'Strong';
    return 'Very Strong';
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
          onPressed: widget.onBack,
          icon: const Icon(Icons.arrow_back_ios),
          color: Colors.black87,
        ),
        centerTitle: true,
        title: Text(
          'Step 2 of 3',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            fontFamily: AppTypography.primaryFontFamily,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Question
              const Text(
                'How intense is\nthis feeling?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 80),

              // Large intensity display
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _getMoodColor().withOpacity(0.3),
                      _getMoodColor().withOpacity(0.05),
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _intensity.round().toString(),
                        style: TextStyle(
                          fontSize: 72,
                          fontWeight: FontWeight.bold,
                          color: _getMoodColor(),
                          fontFamily: AppTypography.primaryFontFamily,
                        ),
                      ),
                      Text(
                        _getIntensityLabel(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: _getMoodColor(),
                          fontFamily: AppTypography.primaryFontFamily,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // Slider
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 8,
                        activeTrackColor: _getMoodColor(),
                        inactiveTrackColor: _getMoodColor().withOpacity(0.2),
                        thumbColor: _getMoodColor(),
                        overlayColor: _getMoodColor().withOpacity(0.2),
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 14,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 28,
                        ),
                      ),
                      child: Slider(
                        value: _intensity,
                        min: 1,
                        max: 10,
                        divisions: 9,
                        onChanged: (value) {
                          setState(() {
                            _intensity = value;
                          });
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Barely',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                          Text(
                            'Extremely',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 60),

              // Continue button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: () {
                    widget.onContinue(_intensity.round());
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

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
