import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/enhanced_mood_service.dart';
import '../data/mood_constants.dart';

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
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFFfaf6f1),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
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

          // Header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Mood Check-In',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.close, color: Colors.grey[600], size: 24),
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
                  // Selected mood display
                  _buildSelectedMoodSection(),
                  const SizedBox(height: 24),

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
                  const SizedBox(height: 32),

                  // Location input
                  _buildLocationSection(),
                  const SizedBox(height: 40),

                  // Save button
                  _buildSaveButton(),
                  const SizedBox(height: 24), // Extra padding at bottom
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntensitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How intense is this feeling?',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(20),
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
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '1',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    '$_intensity/10',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF115e5a),
                    ),
                  ),
                  Text(
                    '10',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: const Color(0xFF115e5a),
                  inactiveTrackColor: Colors.grey[300],
                  thumbColor: const Color(0xFF115e5a),
                  overlayColor: const Color(0xFF115e5a).withValues(alpha: 0.2),
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 12,
                  ),
                  trackHeight: 6,
                ),
                child: Slider(
                  value: _intensity.toDouble(),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  onChanged: (value) {
                    setState(() {
                      _intensity = value.round();
                    });
                  },
                ),
              ),
              const SizedBox(height: 8),
              Text(
                MoodConstants.getIntensityLabel(_intensity),
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
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
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
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
              hintStyle: GoogleFonts.inter(
                color: Colors.grey[500],
                fontSize: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(16),
            ),
            style: GoogleFonts.inter(fontSize: 16, color: Colors.black87),
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
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: MoodConstants.commonTriggers.map((trigger) {
            final isSelected = _selectedTriggers.contains(trigger);
            final isOther = trigger == 'Other';

            return GestureDetector(
              onTap: () {
                if (isOther) {
                  setState(() {
                    _showCustomTriggerInput = !_showCustomTriggerInput;
                  });
                } else {
                  setState(() {
                    if (isSelected) {
                      _selectedTriggers.remove(trigger);
                    } else {
                      _selectedTriggers.add(trigger);
                    }
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF115e5a) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF115e5a)
                        : Colors.grey[300]!,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Text(
                  trigger,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                ),
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
                hintStyle: GoogleFonts.inter(
                  color: Colors.grey[500],
                  fontSize: 14,
                ),
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
              style: GoogleFonts.inter(fontSize: 16, color: Colors.black87),
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
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: MoodConstants.commonActivities.map((activity) {
            final isSelected = _selectedActivities.contains(activity);
            final isOther = activity == 'Other';

            return GestureDetector(
              onTap: () {
                if (isOther) {
                  setState(() {
                    _showCustomActivityInput = !_showCustomActivityInput;
                  });
                } else {
                  setState(() {
                    if (isSelected) {
                      _selectedActivities.remove(activity);
                    } else {
                      _selectedActivities.add(activity);
                    }
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF115e5a) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF115e5a)
                        : Colors.grey[300]!,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Text(
                  activity,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                ),
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
                hintStyle: GoogleFonts.inter(
                  color: Colors.grey[500],
                  fontSize: 14,
                ),
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
              style: GoogleFonts.inter(fontSize: 16, color: Colors.black87),
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

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Where are you?',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
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
            controller: _locationController,
            decoration: InputDecoration(
              hintText: 'Type your location or select from suggestions...',
              hintStyle: GoogleFonts.inter(
                color: Colors.grey[500],
                fontSize: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(16),
              suffixIcon: PopupMenuButton<String>(
                icon: Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (value) {
                  setState(() {
                    _locationController.text = value;
                    _location = value;
                  });
                },
                itemBuilder: (context) => MoodConstants.commonLocations
                    .where((loc) => loc != 'Other')
                    .map(
                      (location) => PopupMenuItem<String>(
                        value: location,
                        child: Text(
                          location,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            style: GoogleFonts.inter(fontSize: 16, color: Colors.black87),
            onChanged: (value) {
              setState(() {
                _location = value;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveMoodDetails,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF115e5a),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'Save Mood Check-In',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
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
              style: GoogleFonts.inter(color: Colors.white),
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
              style: GoogleFonts.inter(color: Colors.white),
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

  Widget _buildSelectedMoodSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Mood icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF115e5a).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: SvgPicture.asset(
              _getMoodSvgPath(widget.selectedMood),
              width: 32,
              height: 32,
              colorFilter: const ColorFilter.mode(
                Color(0xFF115e5a),
                BlendMode.srcIn,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You\'re feeling',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  widget.selectedMood,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF115e5a),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getMoodSvgPath(String mood) {
    // Map to the correct SVG paths from your mood system
    const moodPaths = {
      'Happy': 'assets/emotion-icons/happy.svg',
      'Cutesy': 'assets/emotion-icons/cutesy.svg',
      'Shocked': 'assets/emotion-icons/shocked.svg',
      'Neutral': 'assets/emotion-icons/neutral.svg',
      'Awkward': 'assets/emotion-icons/awkward.svg',
      'Disappointed': 'assets/emotion-icons/dissapointed.svg',
      'Sad': 'assets/emotion-icons/sad.svg',
      'Angry': 'assets/emotion-icons/angry.svg',
      'Worried': 'assets/emotion-icons/worried.svg',
      'Tired': 'assets/emotion-icons/tired.svg',
    };

    return moodPaths[mood] ?? 'assets/emotion-icons/neutral.svg';
  }

  @override
  void dispose() {
    _contextController.dispose();
    _customTriggerController.dispose();
    _customActivityController.dispose();
    _locationController.dispose();
    super.dispose();
  }
}

 