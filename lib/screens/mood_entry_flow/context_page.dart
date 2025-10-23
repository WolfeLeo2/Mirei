import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/mood_colors.dart';
import '../../data/mood_constants.dart';

class ContextPage extends StatefulWidget {
  final String mood;
  final Function(List<String> triggers, List<String> activities, String note)
  onComplete;
  final VoidCallback onBack;

  const ContextPage({
    super.key,
    required this.mood,
    required this.onComplete,
    required this.onBack,
  });

  @override
  State<ContextPage> createState() => _ContextPageState();
}

class _ContextPageState extends State<ContextPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _selectedTriggers = [];
  final List<String> _selectedActivities = [];
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        HapticFeedback.selectionClick();
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Color _getMoodColor() {
    final moodColors = Theme.of(context).extension<MoodColors>();
    if (moodColors == null) return const Color(0xFF115e5a);
    return moodColors.byMood(widget.mood);
  }

  Widget _buildChipSection({
    required String title,
    required List<String> options,
    required List<String> selected,
    required Function(String) onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Select all that apply',
          style: TextStyle(fontSize: 14, color: Colors.black54),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: options.map((option) {
            final isSelected = selected.contains(option);
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (bool selected) {
                onToggle(option);
              },
              selectedColor: _getMoodColor().withOpacity(0.2),
              checkmarkColor: _getMoodColor(),
              backgroundColor: Colors.white,
              side: BorderSide(
                color: isSelected
                    ? _getMoodColor()
                    : Colors.black.withOpacity(0.2),
                width: isSelected ? 2 : 1,
              ),
              labelStyle: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? _getMoodColor() : Colors.black87,
                fontFamily: AppTypography.primaryFontFamily,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            );
          }).toList(),
        ),
      ],
    );
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
          'Step 3 of 3',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            fontFamily: AppTypography.primaryFontFamily,
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),

          // Tab bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: _getMoodColor(),
                borderRadius: BorderRadius.circular(8),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.black54,
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'Triggers'),
                Tab(text: 'Activities'),
                Tab(text: 'Note'),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Triggers tab
                SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _buildChipSection(
                    title: 'What triggered\nthis mood?',
                    options: MoodConstants.commonTriggers,
                    selected: _selectedTriggers,
                    onToggle: (trigger) {
                      setState(() {
                        if (_selectedTriggers.contains(trigger)) {
                          _selectedTriggers.remove(trigger);
                        } else {
                          _selectedTriggers.add(trigger);
                        }
                      });
                    },
                  ),
                ),
                // Activities tab
                SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _buildChipSection(
                    title: 'What were you\ndoing?',
                    options: MoodConstants.commonActivities,
                    selected: _selectedActivities,
                    onToggle: (activity) {
                      setState(() {
                        if (_selectedActivities.contains(activity)) {
                          _selectedActivities.remove(activity);
                        } else {
                          _selectedActivities.add(activity);
                        }
                      });
                    },
                  ),
                ),
                // Note tab
                SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Add a note\n(optional)',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Describe your thoughts and feelings',
                        style: TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _noteController,
                          maxLines: 8,
                          decoration: InputDecoration(
                            hintText: 'Start writing...',
                            hintStyle: const TextStyle(
                              color: Colors.black26,
                              fontFamily: AppTypography.primaryFontFamily,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.all(20),
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                            fontFamily: AppTypography.primaryFontFamily,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Complete button
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: () {
                  widget.onComplete(
                    _selectedTriggers,
                    _selectedActivities,
                    _noteController.text,
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: _getMoodColor(),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: const Text(
                  'Complete',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
