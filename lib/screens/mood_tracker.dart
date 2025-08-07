import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:realm/realm.dart';
import 'package:mirei/components/activity_icon.dart';
import 'package:mirei/components/emotion_button.dart';
import 'package:mirei/models/user.dart';
import '../models/realm_models.dart';
import '../utils/realm_database_helper.dart';
import '../utils/performance_mixins.dart';
import 'progress.dart';
import 'journal_list.dart';
import 'media_screen.dart';

class MoodTrackerScreen extends StatefulWidget {
  const MoodTrackerScreen({super.key});

  @override
  _MoodTrackerScreenState createState() => _MoodTrackerScreenState();
}

class _MoodTrackerScreenState extends State<MoodTrackerScreen> 
    with PerformanceOptimizedStateMixin {
  int selectedEmotionIndex = 1;
  static const List<String> emotions = [
    'Angelic',
    'Sorry',
    'Excited',
    'Embarrassed',
    'Happy',
    'Romantic',
    'Neutral',
    'Sad',
    'Silly',
  ];

  // Lazy-loaded emotion data
  static const List<Map<String, String>> _emotionData = [
    {'emotion': 'Angelic', 'svgPath': 'assets/icons/angelic.svg'},
    {'emotion': 'Sorry', 'svgPath': 'assets/icons/disappointed.svg'},
    {'emotion': 'Excited', 'svgPath': 'assets/icons/excited.svg'},
    {'emotion': 'Embarrassed', 'svgPath': 'assets/icons/embarrassed.svg'},
    {'emotion': 'Happy', 'svgPath': 'assets/icons/Happy.svg'},
    {'emotion': 'Romantic', 'svgPath': 'assets/icons/loving.svg'},
    {'emotion': 'Neutral', 'svgPath': 'assets/icons/neutral.svg'},
    {'emotion': 'Sad', 'svgPath': 'assets/icons/sad.svg'},
    {'emotion': 'Silly', 'svgPath': 'assets/icons/silly.svg'},
  ];

  static const User _user = User(
    name: 'User',
    email: 'user@example.com',
    avatarUrl: 'https://i.pravatar.cc/150?img=12',
  );

  @override
  void initState() {
    super.initState();
    _loadTodaysMood();
  }

  Future<void> _loadTodaysMood() async {
    try {
      final todaysMood = await RealmDatabaseHelper().getTodaysMoodEntry();
      if (todaysMood != null) {
        final moodIndex = emotions.indexOf(todaysMood.mood);
        if (moodIndex != -1) {
          safeSetState(() {
            selectedEmotionIndex = moodIndex;
          });
        }
      }
    } catch (e) {
      // Handle error silently, use default selection
      print('Error loading today\'s mood: $e');
    }
  }

  Future<void> _saveMoodSelection(String mood) async {
    try {
      // Check if there's already a mood entry for today
      final existingMoodEntry = await RealmDatabaseHelper().getTodaysMoodEntry();

      if (existingMoodEntry != null) {
        // Update existing mood entry
        final updatedMoodEntry = MoodEntryRealm(
          existingMoodEntry.id,
          mood,
          existingMoodEntry.createdAt,
          note: existingMoodEntry.note,
        );
        await RealmDatabaseHelper().updateMoodEntry(updatedMoodEntry);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Mood updated to "$mood"!',
                style: TextStyle(
                  fontFamily: GoogleFonts.inter().fontFamily,
                  color: Colors.white,
                ),
              ),
              duration: const Duration(seconds: 1),
              backgroundColor: const Color(0xFF115e5a),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } else {
        // Create a new mood entry
        final moodEntry = MoodEntryRealm(
          ObjectId(),
          mood,
          DateTime.now(),
          note: null,
        );
        await RealmDatabaseHelper().insertMoodEntry(moodEntry);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Mood "$mood" saved successfully!',
                style: TextStyle(
                  fontFamily: GoogleFonts.inter().fontFamily,
                  color: Colors.white,
                ),
              ),
              duration: const Duration(seconds: 1),
              backgroundColor: const Color(0xFF115e5a),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error saving mood: $e',
              style: TextStyle(
                fontFamily: GoogleFonts.inter().fontFamily,
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

  void _onMoodSelected(int index, String mood) {
    // Material 3 Expressive haptic feedback for selection
    HapticFeedback.selectionClick();
    safeSetState(() {
      selectedEmotionIndex = index;
    });
    // Save the mood immediately on selection
    _saveMoodSelection(mood);
  }

  // Build header with better performance
  Widget _buildHeader() {
    return Container(
      color: const Color(0xFF115e5a),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    RepaintBoundary(
                      child: CircleAvatar(
                        radius: 28,
                        backgroundImage: NetworkImage(_user.avatarUrl),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _user.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            fontFamily: '.SF Pro Display',
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _user.email,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            fontFamily: '.SF Pro Text',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const _MenuIcon(),
              ],
            ),
            const SizedBox(height: 40),
            const _MoodPrompt(),
            const SizedBox(height: 16),
            Text(
              'Select your current mood',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
                fontWeight: FontWeight.w400,
                fontFamily: '.SF Pro Text',
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF115e5a),
      body: Column(
        children: [
          _buildHeader(),
          Container(
            color: const Color(0xFF115e5a),
            child: RepaintBoundary(
              child: SizedBox(
                height: 45, // Fixed height for better performance
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  itemCount: _emotionData.length,
                  cacheExtent: 500, // Pre-cache nearby items
                  itemBuilder: (context, index) {
                    final emotion = _emotionData[index];
                    return RepaintBoundary(
                      child: EmotionButton(
                        emotion: emotion['emotion']!,
                        svgPath: emotion['svgPath']!,
                        isSelected: selectedEmotionIndex == index,
                        onTap: () => _onMoodSelected(index, emotion['emotion']!),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
          Expanded(
            child: RepaintBoundary(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFfaf6f1),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(25),
                    topRight: Radius.circular(25),
                  ),
                ),
                child: const _BottomContent(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Optimized const widgets for better performance
class _MenuIcon extends StatelessWidget {
  const _MenuIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Container(height: 2, color: Colors.white),
          Container(height: 2, color: Colors.white),
          Container(height: 2, color: Colors.white),
        ],
      ),
    );
  }
}

class _MoodPrompt extends StatelessWidget {
  const _MoodPrompt();

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Text(
            'Hi, How do you\nfeel today?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w900,
              height: 1.2,
              fontFamily: GoogleFonts.inter().fontFamily,
            ),
          ),
          Positioned(
            top: -10,
            left: -20,
            child: RepaintBoundary(
              child: SvgPicture.asset(
                'assets/icons/emphasis.svg',
                width: 20,
                height: 20,
                colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
              ),
            ),
          ),
          Positioned(
            bottom: -10,
            right: 50,
            child: RepaintBoundary(
              child: SvgPicture.asset(
                'assets/icons/underline.svg',
                width: 17,
                height: 17,
                colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomContent extends StatelessWidget {
  const _BottomContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Hook/Handle component
        Container(
          margin: const EdgeInsets.only(top: 8, bottom: 8),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFF115e5a).withOpacity(0.6),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 18, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _HappinessHeader(),
                  const SizedBox(height: 16),
                  const _ActivitySection(),
                  const SizedBox(height: 32),
                  const _ActionButtons(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HappinessHeader extends StatelessWidget {
  const _HappinessHeader();

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            height: 1.3,
            fontFamily: GoogleFonts.inter().fontFamily,
          ),
          children: [
            const TextSpan(
              text: 'Do You know?\n3 Days Your',
            ),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  RepaintBoundary(
                    child: SvgPicture.asset(
                      'assets/icons/circle.svg',
                      width: 50,
                      height: 35,
                      colorFilter: const ColorFilter.mode(
                        Color.fromARGB(255, 180, 235, 117),
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  Text(
                    'Happiness',
                    style: TextStyle(
                      color: const Color.fromARGB(255, 17, 84, 70),
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      fontFamily: GoogleFonts.inter().fontFamily,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivitySection extends StatelessWidget {
  const _ActivitySection();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            'Some things you might be\ninterested in doing',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 16,
              fontWeight: FontWeight.w400,
              height: 1.4,
              fontFamily: GoogleFonts.inter().fontFamily,
            ),
          ),
        ),
        const Text(
          'View More',
          style: TextStyle(
            color: Color(0xFF115e5a),
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamily: '.SF Pro Text',
          ),
        ),
      ],
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        RepaintBoundary(
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const JournalListScreen(),
                ),
              );
            },
            child: const ActivityIcon(
              label: 'My Journal',
              backgroundColor: Color(0XFFc6e99f),
              svgIcon: 'assets/icons/message.svg',
              svgShape: 'assets/icons/octagon.svg',
              shapeSize: 120,
            ),
          ),
        ),
        RepaintBoundary(
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProgressScreen(),
                ),
              );
            },
            child: const ActivityIcon(
              label: 'My Progress',
              backgroundColor: Color(0xFFECE9A5),
              svgIcon: 'assets/icons/pie-chart.svg',
              svgShape: 'assets/icons/b-circle.svg',
            ),
          ),
        ),
        RepaintBoundary(
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MediaScreen(),
                ),
              );
            },
            child: const ActivityIcon(
              label: 'Music & Media',
              backgroundColor: Color(0xFFC1DFDF),
              svgIcon: 'assets/icons/meditation.svg',
              svgShape: 'assets/icons/heptagon.svg',
            ),
          ),
        ),
      ],
    );
  }
}
