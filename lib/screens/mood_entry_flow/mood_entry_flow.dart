import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'mood_selection_page.dart';
import 'intensity_page.dart';
import 'context_page.dart';
import '../../services/enhanced_mood_service.dart';
import '../../core/theme/typography.dart';

class MoodEntryFlow extends StatefulWidget {
  final String username;
  final VoidCallback? onComplete;

  const MoodEntryFlow({super.key, required this.username, this.onComplete});

  @override
  State<MoodEntryFlow> createState() => _MoodEntryFlowState();
}

class _MoodEntryFlowState extends State<MoodEntryFlow> {
  final EnhancedMoodService _moodService = EnhancedMoodService();
  final PageController _pageController = PageController();

  String _selectedMood = 'Neutral';
  double _gaugeValue = 55.0;
  int _intensity = 5;
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    HapticFeedback.lightImpact();
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_currentPage > 0) {
          _goToPage(_currentPage - 1);
          return false;
        }
        return true;
      },
      child: PageView(
        controller: _pageController,
        physics:
            const NeverScrollableScrollPhysics(), // Disable swipe to prevent gesture conflicts
        onPageChanged: (page) {
          setState(() {
            _currentPage = page;
          });
          HapticFeedback.lightImpact();
        },
        children: [
          // Page 1: Mood Selection
          MoodSelectionPage(
            key: ValueKey(
              'mood-$_selectedMood-$_gaugeValue',
            ), // Force rebuild with saved state
            username: widget.username,
            initialMood: _selectedMood,
            initialGaugeValue: _gaugeValue,
            onContinue: (mood, gaugeValue) {
              setState(() {
                _selectedMood = mood;
                _gaugeValue = gaugeValue;
              });
              _goToPage(1);
            },
            onSaveAndSkip: (mood) {
              _saveQuickMood(mood);
            },
          ),

          // Page 2: Intensity
          IntensityPage(
            key: ValueKey(
              'intensity-$_intensity',
            ), // Force rebuild with saved state
            mood: _selectedMood,
            initialIntensity: _intensity,
            onContinue: (intensity) {
              setState(() {
                _intensity = intensity;
              });
              _goToPage(2);
            },
            onBack: () {
              _goToPage(0);
            },
          ),

          // Page 3: Context
          ContextPage(
            mood: _selectedMood,
            onComplete: (triggers, activities, note) {
              _saveDetailedMood(
                mood: _selectedMood,
                intensity: _intensity,
                triggers: triggers,
                activities: activities,
                note: note,
              );
            },
            onBack: () {
              _goToPage(1);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _saveQuickMood(String mood) async {
    try {
      await _moodService.detailedMoodCheckIn(
        mood: mood,
        intensity: 5, // Default intensity
        context: null,
        triggers: null,
        activities: null,
        location: null,
      );

      if (mounted) {
        _showSuccessAndClose();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error saving mood: $e',
              style: TextStyle(
                fontFamily: AppTypography.primaryFontFamily,
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _saveDetailedMood({
    required String mood,
    required int intensity,
    required List<String> triggers,
    required List<String> activities,
    required String note,
  }) async {
    try {
      await _moodService.detailedMoodCheckIn(
        mood: mood,
        intensity: intensity,
        context: note.isNotEmpty ? note : null,
        triggers: triggers.isNotEmpty ? triggers : null,
        activities: activities.isNotEmpty ? activities : null,
        location: null,
      );

      if (mounted) {
        _showSuccessAndClose();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error saving mood details: $e',
              style: TextStyle(
                fontFamily: AppTypography.primaryFontFamily,
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showSuccessAndClose() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Mood saved successfully! 🎉',
          style: TextStyle(
            fontFamily: AppTypography.primaryFontFamily,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF115e5a),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    // Close flow and call callback
    Future.delayed(const Duration(milliseconds: 500), () {
      widget.onComplete?.call();
      Navigator.pop(context);
    });
  }
}
