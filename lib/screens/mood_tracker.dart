import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../components/profile_pulldown_menu.dart';
import '../models/realm_models.dart';
import '../services/auth_service.dart';
import '../services/enhanced_mood_service.dart';
import '../utils/realm_database_helper.dart';
import 'mood_entry_flow/mood_entry_flow.dart';

class MoodTrackerScreen extends StatefulWidget {
  const MoodTrackerScreen({super.key});

  @override
  State<MoodTrackerScreen> createState() => _MoodTrackerScreenState();
}

class _MoodTrackerScreenState extends State<MoodTrackerScreen> {
  final EnhancedMoodService _moodService = EnhancedMoodService();
  final RealmDatabaseHelper _dbHelper = RealmDatabaseHelper();

  firebase_auth.User? _currentUser;
  StreamSubscription<firebase_auth.User?>? _authSubscription;

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Map to store moods by date (modal mood of the day)
  Map<DateTime, String> _moodsByDate = {};

  // Map to store all moods for each date (for the modal)
  Map<DateTime, List<MoodEntryRealm>> _allMoodsByDate = {};

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadMoodData();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  void _loadUserProfile() {
    final authService = AuthService();
    _currentUser = authService.currentUser;
    _authSubscription = authService.authStateChanges.listen((user) {
      if (!mounted) return;
      setState(() => _currentUser = user);
    });
  }

  Future<void> _loadMoodData() async {
    // Load last 60 days of mood data
    final startDate = DateTime.now().subtract(const Duration(days: 60));
    final endDate = DateTime.now().add(const Duration(days: 1));

    final moods = await _dbHelper.getMoodEntriesForPeriod(startDate, endDate);

    // Group moods by date
    final Map<DateTime, List<MoodEntryRealm>> moodsByDate = {};
    for (final mood in moods) {
      final date = DateTime(
        mood.createdAt.year,
        mood.createdAt.month,
        mood.createdAt.day,
      );
      moodsByDate.putIfAbsent(date, () => []).add(mood);
    }

    // Calculate modal mood for each day
    final Map<DateTime, String> modalMoods = {};
    moodsByDate.forEach((date, moods) {
      modalMoods[date] = _calculateModalMood(moods);
    });

    if (!mounted) return;
    setState(() {
      _moodsByDate = modalMoods;
      _allMoodsByDate = moodsByDate;
    });
  }

  String _calculateModalMood(List<MoodEntryRealm> moods) {
    if (moods.isEmpty) return 'Neutral';

    // Sort moods by creation time (most recent first)
    final sortedMoods = List<MoodEntryRealm>.from(moods)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Count frequency of each mood, keeping track of most recent occurrence
    final moodCounts = <String, int>{};
    final moodFirstOccurrence = <String, DateTime>{};

    for (final mood in sortedMoods) {
      moodCounts[mood.mood] = (moodCounts[mood.mood] ?? 0) + 1;
      // Keep the most recent occurrence (since we sorted by time desc)
      moodFirstOccurrence.putIfAbsent(mood.mood, () => mood.createdAt);
    }

    // Find the maximum count
    final maxCount = moodCounts.values.reduce((a, b) => a > b ? a : b);

    // Get all moods with the maximum count
    final topMoods = moodCounts.entries
        .where((entry) => entry.value == maxCount)
        .map((entry) => entry.key)
        .toList();

    // If there's a tie, return the most recent one
    if (topMoods.length > 1) {
      topMoods.sort(
        (a, b) => moodFirstOccurrence[b]!.compareTo(moodFirstOccurrence[a]!),
      );
      return topMoods.first;
    }

    // Otherwise, return the single most frequent mood
    return topMoods.first;
  }

  String _getMoodIconPath(String mood) {
    final moodMap = {
      'Happy': 'assets/emotion-icons/happy.svg',
      'Neutral': 'assets/emotion-icons/neutral.svg',
      'Sad': 'assets/emotion-icons/sad.svg',
      'Angry': 'assets/emotion-icons/angry.svg',
      'Worried': 'assets/emotion-icons/worried.svg',
      'Tired': 'assets/emotion-icons/tired.svg',
      'Shocked': 'assets/emotion-icons/shocked.svg',
      'Awkward': 'assets/emotion-icons/awkward.svg',
      'Disappointed': 'assets/emotion-icons/dissapointed.svg',
      'Cutesy': 'assets/emotion-icons/cutesy.svg',
    };
    return moodMap[mood] ?? 'assets/emotion-icons/neutral.svg';
  }

  String _getFirstName() {
    if (_currentUser == null) return 'Friend';

    final displayName = _currentUser!.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName.split(' ').first;
    }

    final email = _currentUser!.email;
    if (email != null && email.isNotEmpty) {
      final atIndex = email.indexOf('@');
      if (atIndex > 0) {
        return email.substring(0, atIndex);
      }
    }

    return 'Friend';
  }

  void _showMoodDetailsModal(DateTime date) {
    final moods = _allMoodsByDate[date] ?? [];
    if (moods.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _MoodDetailsModal(
        date: date,
        moods: moods,
        getMoodIconPath: _getMoodIconPath,
      ),
    );
  }

  Future<void> _navigateToMoodEntry() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MoodEntryFlow(
          username: _getFirstName(),
          onComplete: () => _loadMoodData(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeSection(),
            const SizedBox(height: 24),
            _buildCalendarCard(),
            const SizedBox(height: 24),
            _buildCheckInButton(),
            const SizedBox(height: 32),
            _buildMeditationSection(),
            const SizedBox(height: 32),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      toolbarHeight: 70,
      titleSpacing: 10,
      leadingWidth: 72,
      leading: _currentUser != null
          ? Padding(
              padding: const EdgeInsets.only(left: 20),
              child: ProfilePulldownMenu(
                child: CircleAvatar(
                  radius: 28,
                  child: ClipOval(
                    child: SizedBox(
                      width: 52,
                      height: 52,
                      child: _buildAvatar(),
                    ),
                  ),
                ),
              ),
            )
          : null,
      title: _currentUser != null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentUser!.displayName ?? '',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _currentUser!.email ?? '',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
                ),
              ],
            )
          : null,
    );
  }

  Widget _buildAvatar() {
    if (_currentUser == null) return const SizedBox.shrink();

    return CachedNetworkImage(
      imageUrl: _currentUser!.photoURL ??
          'https://api.dicebear.com/7.x/avataaars/png?seed=${_currentUser!.uid}&size=512',
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorWidget: (context, error, stackTrace) {
        final String name = (_currentUser!.displayName ?? '').trim();
        final String initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';
        return Container(
          color: const Color(0xFF0E504D),
          alignment: Alignment.center,
          child: Text(
            initial,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }

  Widget _buildWelcomeSection() {
    final greeting = _getGreeting();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        '$greeting, ${_getFirstName()}!',
        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Widget _buildCalendarCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              DateFormat('MMMM yyyy').format(_focusedDay),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF115e5a),
              ),
            ),
          ),
          TableCalendar(
            firstDay: DateTime.now().subtract(const Duration(days: 365)),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: CalendarFormat.week,
            startingDayOfWeek: StartingDayOfWeek.monday,
            headerVisible: false,
            daysOfWeekHeight: 40,
            rowHeight: 80,
            onDaySelected: (selectedDay, focusedDay) {
              final normalizedDay = DateTime(
                selectedDay.year,
                selectedDay.month,
                selectedDay.day,
              );
              setState(() {
                _focusedDay = focusedDay;
              });
              _showMoodDetailsModal(normalizedDay);
            },
            onPageChanged: (focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
              });
            },
            calendarStyle: const CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(color: Colors.transparent),
            ),
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) =>
                  _buildCalendarDay(day, false, false),
              todayBuilder: (context, day, focusedDay) =>
                  _buildCalendarDay(day, true, false),
              selectedBuilder: (context, day, focusedDay) =>
                  _buildCalendarDay(day, false, true),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCalendarDay(DateTime day, bool isToday, bool isSelected) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    final mood = _moodsByDate[normalizedDay];

    return Container(
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (mood != null) ...[
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isToday
                    ? const Color(0xFF115e5a).withValues(alpha: 0.15)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: SvgPicture.asset(
                _getMoodIconPath(mood),
                width: 32,
                height: 32,
              ),
            ),
          ] else ...[
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isToday
                    ? const Color(0xFF115e5a).withValues(alpha: 0.15)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.circle_outlined,
                size: 20,
                color: Colors.grey.withValues(alpha: 0.2),
              ),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            '${day.day}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isToday ? const Color(0xFF115e5a) : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckInButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _navigateToMoodEntry,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4A90E2),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
          ),
          child: const Text(
            'Check in',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  Widget _buildMeditationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Recommended for you',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              _MeditationCard(
                title: 'Breath',
                description: 'Meditation • 1-3 min',
                color: const Color(0xFFFF6B35),
                iconColor: Colors.orange.shade300,
              ),
              const SizedBox(width: 16),
              _MeditationCard(
                title: 'Body Scan',
                description: 'Meditation • 1-3 min',
                color: const Color(0xFF4ECDC4),
                iconColor: Colors.teal.shade300,
              ),
              const SizedBox(width: 16),
              _MeditationCard(
                title: 'Unwind',
                description: 'Meditation • 1-3 min',
                color: const Color(0xFF5D7DB8),
                iconColor: Colors.blue.shade300,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Center(
      child: Image.asset(
        'assets/images/footer_no_bg.webp',
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(height: 100, color: Colors.transparent);
        },
      ),
    );
  }
}

class _MeditationCard extends StatelessWidget {
  final String title;
  final String description;
  final Color color;
  final Color iconColor;

  const _MeditationCard({
    required this.title,
    required this.description,
    required this.color,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      height: 200,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                color: iconColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                  topLeft: Radius.circular(60),
                  topRight: Radius.circular(60),
                ),
              ),
              child: Icon(
                Icons.self_improvement,
                size: 40,
                color: color.withValues(alpha: 0.5),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.volume_up,
                      size: 14,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodDetailsModal extends StatelessWidget {
  final DateTime date;
  final List<MoodEntryRealm> moods;
  final String Function(String) getMoodIconPath;

  const _MoodDetailsModal({
    required this.date,
    required this.moods,
    required this.getMoodIconPath,
  });

  @override
  Widget build(BuildContext context) {
    // Sort moods by time, most recent first
    final sortedMoods = List<MoodEntryRealm>.from(moods)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              DateFormat('EEEE, MMMM d').format(date),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF115e5a),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: sortedMoods.length,
              itemBuilder: (context, index) {
                final mood = sortedMoods[index];
                return _MoodListItem(
                  mood: mood,
                  iconPath: getMoodIconPath(mood.mood),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _MoodListItem extends StatelessWidget {
  final MoodEntryRealm mood;
  final String iconPath;

  const _MoodListItem({required this.mood, required this.iconPath});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF115e5a).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          SvgPicture.asset(iconPath, width: 40, height: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mood.mood,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF115e5a),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('h:mm a').format(mood.createdAt.toLocal()),
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                if (mood.context != null && mood.context!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    mood.context!,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
