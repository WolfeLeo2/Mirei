import 'package:flutter/material.dart';
import '../services/enhanced_mood_service.dart';
import '../data/mood_constants.dart';
import '../core/theme/typography.dart';
import '../core/theme/mood_colors.dart';

class EnhancedMoodDetailsScreen extends StatefulWidget {
  final String selectedMood;
  final String? moodSvgPath;
  final VoidCallback? onMoodSaved;

  const EnhancedMoodDetailsScreen({
    super.key,
    required this.selectedMood,
    this.moodSvgPath,
    this.onMoodSaved,
  });

  @override
  State<EnhancedMoodDetailsScreen> createState() =>
      _EnhancedMoodDetailsScreenState();
}

class _EnhancedMoodDetailsScreenState extends State<EnhancedMoodDetailsScreen> {
  final EnhancedMoodService _moodService = EnhancedMoodService();

  // Form state
  int _intensity = 5;
  String _context = '';
  final List<String> _selectedTriggers = [];
  final List<String> _selectedActivities = [];
  String _location = '';
  bool _isLoading = false;

  // Controllers
  final TextEditingController _contextController = TextEditingController();
  final TextEditingController _customTriggerController =
      TextEditingController();
  final TextEditingController _customActivityController =
      TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  // Other options state
  bool _showCustomTriggerInput = false;
  bool _showCustomActivityInput = false;

  @override
  void dispose() {
    _contextController.dispose();
    _customTriggerController.dispose();
    _customActivityController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFFfaf6f1),
        borderRadius: BorderRadius.all(Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header with Cancel | Mood Pill | Save
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Cancel button
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),

                // Mood pill in center
                Expanded(child: Center(child: _buildMoodPill())),

                // Save button
                FilledButton(
                  onPressed: _isLoading ? null : _saveMoodDetails,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    backgroundColor: _getMoodColor(),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Save',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ],
            ),
          ),

          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Intensity scale
                  _buildIntensitySection(),
                  const SizedBox(height: 32),

                  // Context input
                  _buildContextSection(),
                  const SizedBox(height: 32),

                  // Triggers selection
                  _buildTriggersSection(),
                  const SizedBox(height: 32),

                  // Activities selection
                  _buildActivitiesSection(),
                  const SizedBox(height: 40),

                  // Removed: Location section

                  // Save button moved to header
                  const SizedBox(height: 24), // Extra padding at bottom
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build mood pill in header
  Widget _buildMoodPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: _getMoodColor().withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _getMoodColor(), width: 1.5),
      ),
      child: Text(
        widget.selectedMood,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: _getMoodColor(),
          fontFamily: AppTypography.primaryFontFamily,
        ),
      ),
    );
  }

  // Helper method to get mood color from theme
  Color _getMoodColor() {
    final moodColors = Theme.of(context).extension<MoodColors>();
    if (moodColors == null) return const Color(0xFF115e5a);
    return moodColors.byMood(widget.selectedMood);
  }

  Widget _buildIntensitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How intense is this feeling?',
          style: Theme.of(context).textTheme.bodyLarge
              ?.copyWith(fontSize: 18, fontWeight: FontWeight.w600)
              .apply(color: Colors.black87),
        ),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '1',
                    style: Theme.of(context).textTheme.titleSmall
                        ?.copyWith(fontSize: 14, fontWeight: FontWeight.w500)
                        .apply(color: Colors.grey[600]),
                  ),
                  Text(
                    '$_intensity/10',
                    style: Theme.of(context).textTheme.bodyLarge
                        ?.copyWith(fontSize: 18, fontWeight: FontWeight.w700)
                        .apply(color: _getMoodColor()),
                  ),
                  Text(
                    '10',
                    style: Theme.of(context).textTheme.titleSmall
                        ?.copyWith(fontSize: 14, fontWeight: FontWeight.w500)
                        .apply(color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Material 3 Slider
              Slider(
                value: _intensity.toDouble(),
                min: 1,
                max: 10,
                divisions: 9,
                activeColor: _getMoodColor(),
                onChanged: (value) {
                  setState(() {
                    _intensity = value.round();
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContextSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What\'s on your mind? (Optional)',
          style: Theme.of(context).textTheme.bodyLarge
              ?.copyWith(fontSize: 18, fontWeight: FontWeight.w600)
              .apply(color: Colors.black87),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _contextController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Describe what\'s contributing to this feeling...',
              hintStyle: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(fontSize: 14)
                  .apply(color: Colors.grey[500]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(16),
            ),
            style: TextStyle(
              fontFamily: AppTypography.primaryFontFamily,
              fontSize: 16,
              color: Colors.black87,
            ),
            onChanged: (value) {
              setState(() {
                _context = value;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTriggersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What triggered this feeling?',
          style: Theme.of(context).textTheme.bodyLarge
              ?.copyWith(fontSize: 18, fontWeight: FontWeight.w600)
              .apply(color: Colors.black87),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: MoodConstants.commonTriggers.map((trigger) {
            final isSelected = _selectedTriggers.contains(trigger);
            final isOther = trigger == 'Other';

            return FilterChip(
              label: Text(trigger),
              selected: isSelected,
              onSelected: (selected) {
                if (isOther) {
                  setState(() {
                    _showCustomTriggerInput = !_showCustomTriggerInput;
                  });
                } else {
                  setState(() {
                    if (selected) {
                      _selectedTriggers.add(trigger);
                    } else {
                      _selectedTriggers.remove(trigger);
                    }
                  });
                }
              },
              selectedColor: _getMoodColor().withOpacity(0.2),
              checkmarkColor: _getMoodColor(),
              side: BorderSide(
                color: isSelected ? _getMoodColor() : Colors.grey[300]!,
                width: 1,
              ),
            );
          }).toList(),
        ),

        // Custom trigger input
        if (_showCustomTriggerInput) ...[
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _customTriggerController,
              decoration: InputDecoration(
                hintText: 'Type your custom trigger...',
                hintStyle: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(fontSize: 14)
                    .apply(color: Colors.grey[500]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.all(16),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add, color: Color(0xFF115e5a)),
                  onPressed: () {
                    final customTrigger = _customTriggerController.text.trim();
                    if (customTrigger.isNotEmpty &&
                        !_selectedTriggers.contains(customTrigger)) {
                      setState(() {
                        _selectedTriggers.add(customTrigger);
                        _customTriggerController.clear();
                        _showCustomTriggerInput = false;
                      });
                    }
                  },
                ),
              ),
              style: TextStyle(
                fontFamily: AppTypography.primaryFontFamily,
                fontSize: 16,
                color: Colors.black87,
              ),
              onSubmitted: (value) {
                final customTrigger = value.trim();
                if (customTrigger.isNotEmpty &&
                    !_selectedTriggers.contains(customTrigger)) {
                  setState(() {
                    _selectedTriggers.add(customTrigger);
                    _customTriggerController.clear();
                    _showCustomTriggerInput = false;
                  });
                }
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActivitiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What activities helped or might help?',
          style: Theme.of(context).textTheme.bodyLarge
              ?.copyWith(fontSize: 18, fontWeight: FontWeight.w600)
              .apply(color: Colors.black87),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: MoodConstants.commonActivities.map((activity) {
            final isSelected = _selectedActivities.contains(activity);
            final isOther = activity == 'Other';

            return FilterChip(
              label: Text(activity),
              selected: isSelected,
              onSelected: (selected) {
                if (isOther) {
                  setState(() {
                    _showCustomActivityInput = !_showCustomActivityInput;
                  });
                } else {
                  setState(() {
                    if (selected) {
                      _selectedActivities.add(activity);
                    } else {
                      _selectedActivities.remove(activity);
                    }
                  });
                }
              },
              selectedColor: _getMoodColor().withOpacity(0.2),
              checkmarkColor: _getMoodColor(),
              side: BorderSide(
                color: isSelected ? _getMoodColor() : Colors.grey[300]!,
                width: 1,
              ),
            );
          }).toList(),
        ),

        // Custom activity input
        if (_showCustomActivityInput) ...[
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _customActivityController,
              decoration: InputDecoration(
                hintText: 'Type your custom activity...',
                hintStyle: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(fontSize: 14)
                    .apply(color: Colors.grey[500]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.all(16),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add, color: Color(0xFF115e5a)),
                  onPressed: () {
                    final customActivity = _customActivityController.text
                        .trim();
                    if (customActivity.isNotEmpty &&
                        !_selectedActivities.contains(customActivity)) {
                      setState(() {
                        _selectedActivities.add(customActivity);
                        _customActivityController.clear();
                        _showCustomActivityInput = false;
                      });
                    }
                  },
                ),
              ),
              style: TextStyle(
                fontFamily: AppTypography.primaryFontFamily,
                fontSize: 16,
                color: Colors.black87,
              ),
              onSubmitted: (value) {
                final customActivity = value.trim();
                if (customActivity.isNotEmpty &&
                    !_selectedActivities.contains(customActivity)) {
                  setState(() {
                    _selectedActivities.add(customActivity);
                    _customActivityController.clear();
                    _showCustomActivityInput = false;
                  });
                }
              },
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _saveMoodDetails() async {
    setState(() => _isLoading = true);

    try {
      await _moodService.detailedMoodCheckIn(
        mood: widget.selectedMood,
        intensity: _intensity,
        context: _context.isNotEmpty ? _context : null,
        triggers: _selectedTriggers.isNotEmpty ? _selectedTriggers : null,
        activities: _selectedActivities.isNotEmpty ? _selectedActivities : null,
        location: _location.isNotEmpty ? _location : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Mood check-in saved successfully!',
              style: TextStyle(
                fontFamily: AppTypography.primaryFontFamily,
                color: Colors.white,
              ),
            ),
            backgroundColor: const Color(0xFF115e5a),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );

        // Call the callback and close modal
        widget.onMoodSaved?.call();
        Navigator.pop(context);
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
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
