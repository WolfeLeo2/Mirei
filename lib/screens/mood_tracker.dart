import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:realm/realm.dart';
import 'package:mirei/components/activity_icon.dart';
import 'package:mirei/components/mood_button.dart';
import '../models/realm_models.dart';
import '../utils/realm_database_helper.dart';
import '../utils/performance_mixins.dart';
import '../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'progress.dart';
import 'journal_list.dart';
import 'media_screen.dart';
import 'package:lottie/lottie.dart';

// Const widgets for static decorative elements
class _EmphasisIcon extends StatelessWidget {
  const _EmphasisIcon();

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/icons/emphasis.svg',
      width: 20,
      height: 20,
      color: Colors.white,
    );
  }
}

class _UnderlineIcon extends StatelessWidget {
  const _UnderlineIcon();

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/icons/underline.svg',
      width: 17,
      height: 17,
      color: Colors.white,
    );
  }
}

class MoodTrackerScreen extends StatefulWidget {
  const MoodTrackerScreen({super.key});

  @override
  _MoodTrackerScreenState createState() => _MoodTrackerScreenState();
}

class _MoodTrackerScreenState extends State<MoodTrackerScreen>
    with PerformanceOptimizedStateMixin {
  int selectedMoodIndex = 1;

  // Lottie overlay state
  bool _showMoodAnimation = false;
  int _animationKey = 0; // Forces replay when set
  static const String _moodLottieAsset =
      'assets/animations/Bubble Explosion.json';

  // GlobalKeys for tracking mood button positions
  final List<GlobalKey> _moodButtonKeys = List.generate(
    10,
    (index) => GlobalKey(),
  );
  Offset? _animationPosition;
  Size? _animationSize;

  // Make Moods list const for better performance
  static const List<String> Moods = [
    'Happy',
    'Cutesy',
    'Shocked',
    'Neutral',
    'Awkward',
    'Disappointed',
    'Sad',
    'Angry',
    'Worried',
    'Tired',
  ];

  // Make Moods config const for lazy loading
  static const List<Map<String, String>> MoodConfigs = [
    {'Mood': 'Happy', 'svgPath': 'assets/emotion-icons/happy.svg'},
    {'Mood': 'Cutesy', 'svgPath': 'assets/emotion-icons/cutesy.svg'},
    {'Mood': 'Shocked', 'svgPath': 'assets/emotion-icons/shocked.svg'},
    {'Mood': 'Neutral', 'svgPath': 'assets/emotion-icons/neutral.svg'},
    {'Mood': 'Awkward', 'svgPath': 'assets/emotion-icons/awkward.svg'},
    {
      'Mood': 'Disappointed',
      'svgPath': 'assets/emotion-icons/dissapointed.svg',
    },
    {'Mood': 'Sad', 'svgPath': 'assets/emotion-icons/sad.svg'},
    {'Mood': 'Angry', 'svgPath': 'assets/emotion-icons/angry.svg'},
    {'Mood': 'Worried', 'svgPath': 'assets/emotion-icons/worried.svg'},
    {'Mood': 'Tired', 'svgPath': 'assets/emotion-icons/tired.svg'},
  ];

  firebase_auth.User? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadTodaysMood();
    _loadUserProfile();
  }

  void _loadUserProfile() {
    _currentUser = AuthService().currentUser;
    AuthService().authStateChanges.listen((user) {
      if (mounted) {
        setState(() {
          _currentUser = user;
        });
      }
    });
  }

  Future<void> _loadTodaysMood() async {
    try {
      final todaysMood = await RealmDatabaseHelper().getTodaysMoodEntry();
      if (todaysMood != null) {
        final moodIndex = Moods.indexOf(todaysMood.mood);
        if (moodIndex != -1) {
          safeSetState(() {
            selectedMoodIndex = moodIndex;
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
      final existingMoodEntry = await RealmDatabaseHelper()
          .getTodaysMoodEntry();

      if (existingMoodEntry != null) {
        // Update existing mood entry with current timestamp
        final updatedMoodEntry = MoodEntryRealm(
          existingMoodEntry.id,
          mood,
          DateTime.now(),
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

  void _playMoodAnimation() {
    // Get the position of the selected mood button
    final selectedKey = _moodButtonKeys[selectedMoodIndex];
    final RenderBox? renderBox =
        selectedKey.currentContext?.findRenderObject() as RenderBox?;

    if (renderBox != null) {
      final position = renderBox.localToGlobal(Offset.zero);
      final size = renderBox.size;

      setState(() {
        _animationPosition = Offset(
          position.dx + size.width / 2, // Center horizontally on the button
          position.dy + size.height / 2, // Center vertically on the button
        );
        _animationSize = Size(
          size.width * 1.5,
          size.height * 1.5,
        ); // Make animation slightly larger than button
        _showMoodAnimation = true;
        _animationKey++;
      });
    } else {
      // Fallback to center if position can't be determined
      setState(() {
        _animationPosition = null;
        _animationSize = null;
        _showMoodAnimation = true;
        _animationKey++;
      });
    }
  }

  void _onMoodSelected(int index, String mood) {
    // Material 3 Expressive haptic feedback for selection
    HapticFeedback.selectionClick();
    safeSetState(() {
      selectedMoodIndex = index;
    });

    // Add a small delay to ensure the UI has rendered before getting button position
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) {
        // Play lottie overlay animation
        _playMoodAnimation();
      }
    });

    // Save the mood immediately on selection
    _saveMoodSelection(mood);
  }

  // Lazy builder for Mood buttons with const optimization
  Widget _buildMoodButton(int index) {
    final config = MoodConfigs[index];
    return MoodButton(
      key: _moodButtonKeys[index], // Add the GlobalKey here
      Mood: config['Mood']!,
      svgPath: config['svgPath']!,
      isSelected: selectedMoodIndex == index,
      onTap: () => _onMoodSelected(index, config['Mood']!),
    );
  }

  // Const widget for hamburger menu icon
  static const Widget _hamburgerMenuIcon = SizedBox(
    width: 24,
    height: 24,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        SizedBox(height: 2, child: ColoredBox(color: Colors.white)),
        SizedBox(height: 2, child: ColoredBox(color: Colors.white)),
        SizedBox(height: 2, child: ColoredBox(color: Colors.white)),
      ],
    ),
  );

  // Const widget for subtitle text
  static const Widget _subtitleText = Text(
    'Select your current mood',
    style: TextStyle(
      color: Color.fromRGBO(255, 255, 255, 0.7),
      fontSize: 16,
      fontWeight: FontWeight.w400,
      fontFamily: '.SF Pro Text',
    ),
  );

  // Create const activity icons for better performance
  Widget _buildActivityIcons(BuildContext context) {
    return RepaintBoundary(
      child: Row(
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
                  MaterialPageRoute(builder: (context) => const MediaScreen()),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF115e5a),
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                color: const Color(0xFF115e5a),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (_currentUser != null)
                            Row(
                              children: [
                                RepaintBoundary(
                                  child: CircleAvatar(
                                    radius: 28,
                                    backgroundImage: NetworkImage(
                                      _currentUser!.photoURL ??
                                          'https://api.dicebear.com/7.x/avataaars/png?seed=${_currentUser!.uid}&size=150',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _currentUser!.displayName ?? '',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: '.SF Pro Display',
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _currentUser!.email ?? '',
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
                          // Use const hamburger menu for better performance
                          _hamburgerMenuIcon,
                        ],
                      ),
                      const SizedBox(height: 40),
                      RepaintBoundary(
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
                            const Positioned(
                              top: -10,
                              left: -20,
                              child: _EmphasisIcon(),
                            ),
                            const Positioned(
                              bottom: -10,
                              right: 50,
                              child: _UnderlineIcon(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _subtitleText,
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              Container(
                color: const Color(0xFF115e5a),
                child: RepaintBoundary(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: List.generate(
                        MoodConfigs.length,
                        (index) => _buildMoodButton(index),
                      ),
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
                      color: Color.fromARGB(255, 251, 245, 240),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(25),
                        topRight: Radius.circular(25),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Hook/Handle component - make it const
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
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                12,
                                18,
                                100,
                              ), // Added bottom padding for nav bar
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  RepaintBoundary(
                                    child: RichText(
                                      text: TextSpan(
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 24,
                                          fontWeight: FontWeight.w700,
                                          height: 1.3,
                                          fontFamily:
                                              GoogleFonts.inter().fontFamily,
                                        ),
                                        children: [
                                          const TextSpan(
                                            text: 'Do You know?\n3 Days Your',
                                          ),
                                          WidgetSpan(
                                            alignment:
                                                PlaceholderAlignment.middle,
                                            child: RepaintBoundary(
                                              child: Stack(
                                                alignment: Alignment.center,
                                                children: [
                                                  SvgPicture.asset(
                                                    'assets/icons/circle.svg',
                                                    width: 50,
                                                    height: 35,
                                                    color: const Color.fromARGB(
                                                      255,
                                                      180,
                                                      235,
                                                      117,
                                                    ),
                                                  ),
                                                  Text(
                                                    'Happiness',
                                                    style: TextStyle(
                                                      color:
                                                          const Color.fromARGB(
                                                            255,
                                                            17,
                                                            84,
                                                            70,
                                                          ),
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 22,
                                                      fontFamily:
                                                          GoogleFonts.inter()
                                                              .fontFamily,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  RepaintBoundary(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'Some things you might be\ninterested in doing',
                                            style: TextStyle(
                                              color: Colors.black54,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w400,
                                              height: 1.4,
                                              fontFamily: GoogleFonts.inter()
                                                  .fontFamily,
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
                                    ),
                                  ),
                                  const SizedBox(height: 32),
                                  _buildActivityIcons(context),
                                  const SizedBox(height: 24),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Lottie overlay (ignores touches)
          if (_showMoodAnimation)
            Positioned(
              left: _animationPosition != null
                  ? _animationPosition!.dx - (_animationSize?.width ?? 100) / 2
                  : MediaQuery.of(context).size.width / 2 - 100,
              top: _animationPosition != null
                  ? _animationPosition!.dy - (_animationSize?.height ?? 100) / 2
                  : MediaQuery.of(context).size.height / 2 - 100,
              child: IgnorePointer(
                ignoring: true,
                child: Lottie.asset(
                  _moodLottieAsset,
                  key: ValueKey(_animationKey),
                  repeat: false,
                  onLoaded: (composition) {
                    // Auto-hide when finished
                    Future.delayed(composition.duration, () {
                      if (mounted) {
                        setState(() => _showMoodAnimation = false);
                      }
                    });
                  },
                  width: _animationSize?.width ?? 200,
                  height: _animationSize?.height ?? 200,
                  fit: BoxFit.contain,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
