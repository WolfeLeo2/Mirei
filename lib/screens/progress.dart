import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/realm_models.dart';
import '../utils/realm_database_helper.dart';
import '../utils/emotion_colors.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  _ProgressScreenState createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  List<MoodEntryRealm> monthlyMoods = [];
  Map<String, int> moodFrequency = {};
  String currentMonth = DateFormat('MMMM yyyy').format(DateTime.now());
  bool isLoading = true;
  int totalEntries = 0;
  int touchedIndex = -1;
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadMoodAnalytics();
  }

  Future<void> _loadMoodAnalytics() async {
    try {
      final startOfMonth = DateTime(selectedDate.year, selectedDate.month, 1);
      final endOfMonth = DateTime(
        selectedDate.year,
        selectedDate.month + 1,
        0,
        23,
        59,
        59,
      );

      final dbHelper = RealmDatabaseHelper();
      final moods = await dbHelper.getMoodEntriesForPeriod(
        startOfMonth,
        endOfMonth,
      );

      final frequency = <String, int>{};
      for (final mood in moods) {
        frequency[mood.mood] = (frequency[mood.mood] ?? 0) + 1;
      }

      setState(() {
        monthlyMoods = moods;
        moodFrequency = frequency;
        totalEntries = moods.length;
        currentMonth = DateFormat('MMMM yyyy').format(selectedDate);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading mood analytics: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToPreviousMonth() {
    setState(() {
      selectedDate = DateTime(selectedDate.year, selectedDate.month - 1, 1);
      isLoading = true;
    });
    _loadMoodAnalytics();
  }

  void _navigateToNextMonth() {
    setState(() {
      selectedDate = DateTime(selectedDate.year, selectedDate.month + 1, 1);
      isLoading = true;
    });
    _loadMoodAnalytics();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFfaf6f1),
      appBar: AppBar(
        backgroundColor: const Color(0xFFfaf6f1),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Color(0xFF115e5a),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Mood Insights',
          style: GoogleFonts.inter(
            color: const Color(0xFF115e5a),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF115e5a)),
            )
          : Column(
              children: [
                _buildMonthSelector(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: totalEntries == 0
                        ? _buildEmptyState()
                        : _buildAnalytics(),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMonthSelector() {
    final now = DateTime.now();
    final isCurrentMonth =
        selectedDate.year == now.year && selectedDate.month == now.month;
    final canGoNext = selectedDate.isBefore(DateTime(now.year, now.month, 1));

    // Calculate days with mood tracking in this month
    final daysInMonth = DateTime(
      selectedDate.year,
      selectedDate.month + 1,
      0,
    ).day;
    final daysTracked = monthlyMoods
        .map((e) => DateFormat('yyyy-MM-dd').format(e.createdAt))
        .toSet()
        .length;
    final completionPercentage = daysInMonth > 0
        ? ((daysTracked / daysInMonth) * 100).round()
        : 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left arrow
          GestureDetector(
            onTap: _navigateToPreviousMonth,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.chevron_left,
                color: Colors.grey[600],
                size: 20,
              ),
            ),
          ),

          // Month and year display with completion badge
          Row(
            children: [
              if (totalEntries > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF115e5a).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$completionPercentage%',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF115e5a),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Column(
                children: [
                  Text(
                    currentMonth,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF115e5a),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isCurrentMonth
                        ? 'Current Month'
                        : '$daysTracked of $daysInMonth days tracked',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Right arrow
          GestureDetector(
            onTap: canGoNext ? _navigateToNextMonth : null,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: canGoNext ? Colors.grey[100] : Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.chevron_right,
                color: canGoNext ? Colors.grey[600] : Colors.grey[300],
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 60),
          Icon(Icons.analytics_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 20),
          Text(
            'No mood data for ${DateFormat('MMMM yyyy').format(selectedDate)}',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Start tracking your moods to see analytics for this month',
            style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF115e5a).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Try navigating to a different month using the arrows above',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF115e5a),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalytics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMoodDistribution(),
        const SizedBox(height: 30),
        _buildRecentActivity(),
      ],
    );
  }

  Widget _buildMoodDistribution() {
    if (moodFrequency.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              'Mood Distribution',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF115e5a),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No mood data available',
              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04), // Reduced from 0.08
            blurRadius: 10, // Reduced from 15
            offset: const Offset(0, 4), // Reduced offset
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mood Distribution',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF115e5a),
            ),
          ),
          const SizedBox(height: 30),
          AspectRatio(
            aspectRatio: 1.2,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          pieTouchResponse == null ||
                          pieTouchResponse.touchedSection == null) {
                        touchedIndex = -1;
                        return;
                      }
                      touchedIndex =
                          pieTouchResponse.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                borderData: FlBorderData(show: false),
                sectionsSpace: 2,
                centerSpaceRadius: 0,
                sections: _buildPieChartSections(),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildMoodLegend(),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections() {
    final sortedMoods = moodFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedMoods.asMap().entries.map((entry) {
      final index = entry.key;
      final moodEntry = entry.value;
      final isTouched = index == touchedIndex;
      final fontSize = isTouched ? 16.0 : 14.0;
      final radius = isTouched ? 120.0 : 100.0;
      final widgetSize = isTouched ? 50.0 : 40.0;

      final percentage = (moodEntry.value / totalEntries * 100).round();
      final color = getEmotionColor(moodEntry.key);

      return PieChartSectionData(
        color: color,
        value: moodEntry.value.toDouble(),
        title: '$percentage%',
        radius: radius,
        titleStyle: GoogleFonts.inter(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: const [Shadow(color: Colors.black26, blurRadius: 2)],
        ),
        badgeWidget: _MoodBadge(
          mood: moodEntry.key,
          size: widgetSize,
          borderColor: color,
        ),
        badgePositionPercentageOffset: 0.98,
      );
    }).toList();
  }

  Widget _buildMoodLegend() {
    final sortedMoods = moodFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: sortedMoods.map((entry) {
        final percentage = (entry.value / totalEntries * 100).round();
        final color = getEmotionColor(entry.key);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  entry.key,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF115e5a),
                  ),
                ),
              ),
              Text(
                '$percentage% (${entry.value})',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecentActivity() {
    final recentMoods = monthlyMoods.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activity',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF115e5a),
            ),
          ),
          const SizedBox(height: 16),
          if (recentMoods.isNotEmpty)
            ...recentMoods.map((mood) {
              final color = getEmotionColor(mood.mood);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mood.mood,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: color,
                            ),
                          ),
                          Text(
                            DateFormat(
                              'MMM dd, yyyy • hh:mm a',
                            ).format(mood.createdAt),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }
}

class _MoodBadge extends StatelessWidget {
  const _MoodBadge({
    required this.mood,
    required this.size,
    required this.borderColor,
  });

  final String mood;
  final double size;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    // Map moods to emoji icons based on your emotion system
    final moodEmojis = {
      'angelic': '😇',
      'sorry': '�',
      'excited': '🤩',
      'embarrassed': '�',
      'happy': '�',
      'romantic': '😍',
      'neutral': '😐',
      'sad': '�',
      'silly': '🤪',
      // Add fallback variations
      'calm': '😌',
      'grateful': '🙏',
      'frustrated': '😤',
      'content': '😊',
      'worried': '😟',
      'joyful': '😄',
      'overwhelmed': '😵',
    };

    final emoji = moodEmojis[mood.toLowerCase()] ?? '😐';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            offset: const Offset(2, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Center(
        child: Text(emoji, style: TextStyle(fontSize: size * 0.4)),
      ),
    );
  }
}
