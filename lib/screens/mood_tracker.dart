import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:realm/realm.dart';
import 'package:mirei/components/activity_icon.dart';
import 'package:mirei/components/mood_button.dart';
import 'package:mirei/models/user.dart';
import '../models/realm_models.dart';
import '../utils/realm_database_helper.dart';
import '../utils/performance_mixins.dart';
import 'progress.dart';
import 'journal_list_new.dart';
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
    with PerformanceOptimizedStateMixin, TickerProviderStateMixin {
  int selectedMoodIndex = 1;

  // Lottie overlay state
  bool _showMoodAnimation = false;
  int _animationKey = 0; // Forces replay when set
  static const String _moodLottieAsset =
      'assets/animations/Bubble Explosion.json';

  // GlobalKeys for tracking mood button positions
  final List<GlobalKey> _moodButtonKeys = List.generate(
    9,
    (index) => GlobalKey(),
  );
  Offset? _animationPosition;
  Size? _animationSize;

  // Color spreading animation state
  late AnimationController _colorSpreadController;
  late Animation<double> _colorSpreadAnimation;
  bool _showColorSpread = false;
  Offset? _spreadOrigin;
  Color? _spreadColor;

  // Mood accent colors for the ripple effect
  static const Map<String, Color> moodAccentColors = {
    'Angelic': Color(0xFF1976D2), // Blue
    'Sorry': Color(0xFF616161), // Gray
    'Excited': Color(0xFFFF9800), // Orange
    'Embarrassed': Color(0xFFE91E63), // Pink
    'Happy': Color(0xFFFFC107), // Yellow
    'Romantic': Color(0xFFE53935), // Red
    'Neutral': Color(0xFF9E9E9E), // Neutral
    'Sad': Color(0xFF0277BD), // Blue
    'Silly': Color(0xFF9C27B0), // Purple
  };

  // Make Moods list const for better performance
  static const List<String> Moods = [
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

  // Make Moods config const for lazy loading
  static const List<Map<String, String>> MoodConfigs = [
    {'Mood': 'Angelic', 'svgPath': 'assets/icons/angelic.svg'},
    {'Mood': 'Sorry', 'svgPath': 'assets/icons/disappointed.svg'},
    {'Mood': 'Excited', 'svgPath': 'assets/icons/excited.svg'},
    {'Mood': 'Embarrassed', 'svgPath': 'assets/icons/embarrassed.svg'},
    {'Mood': 'Happy', 'svgPath': 'assets/icons/Happy.svg'},
    {'Mood': 'Romantic', 'svgPath': 'assets/icons/loving.svg'},
    {'Mood': 'Neutral', 'svgPath': 'assets/icons/neutral.svg'},
    {'Mood': 'Sad', 'svgPath': 'assets/icons/sad.svg'},
    {'Mood': 'Silly', 'svgPath': 'assets/icons/silly.svg'},
  ];

  final User _user = User(
    name: 'User',
    email: 'user@example.com',
    avatarUrl: 'https://i.pravatar.cc/150?img=12',
  );

  @override
  void initState() {
    super.initState();
    _loadTodaysMood();
    _initializeColorSpreadAnimation();
  }

  void _initializeColorSpreadAnimation() {
    _colorSpreadController = AnimationController(
      duration: const Duration(milliseconds: 800), // 0.8 second spreading effect
      vsync: this,
    );

    _colorSpreadAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _colorSpreadController,
      curve: Curves.easeOutCirc, // Smooth circular expansion
    ));

    _colorSpreadAnimation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Hide the spreading overlay after animation completes
        setState(() {
          _showColorSpread = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _colorSpreadController.dispose();
    super.dispose();
  }

  // Custom painter for the color spreading effect
  Widget _buildColorSpreadOverlay() {
    if (!_showColorSpread || _spreadOrigin == null || _spreadColor == null) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _colorSpreadAnimation,
          builder: (context, child) {
            return CustomPaint(
              painter: ColorSpreadPainter(
                origin: _spreadOrigin!,
                progress: _colorSpreadAnimation.value,
                color: _spreadColor!,
                screenSize: MediaQuery.of(context).size,
              ),
            );
          },
        ),
      ),
    );
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
        // Get the position of the selected mood button for color spreading
        final selectedKey = _moodButtonKeys[index];
        final RenderBox? renderBox =
            selectedKey.currentContext?.findRenderObject() as RenderBox?;

        if (renderBox != null) {
          final position = renderBox.localToGlobal(Offset.zero);
          final size = renderBox.size;
          
          // Set up color spreading animation
          final spreadCenter = Offset(
            position.dx + size.width / 2,
            position.dy + size.height / 2,
          );
          
          setState(() {
            _spreadOrigin = spreadCenter;
            _spreadColor = moodAccentColors[mood] ?? moodAccentColors['Neutral']!;
            _showColorSpread = true;
          });

          // Start the color spreading animation
          _colorSpreadController.reset();
          _colorSpreadController.forward();
        }

        // Play lottie overlay animation (existing)
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
                    builder: (context) => const JournalListScreenNew(),
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
                          Row(
                            children: [
                              RepaintBoundary(
                                child: CircleAvatar(
                                  radius: 28,
                                  backgroundImage: NetworkImage(
                                    _user.avatarUrl,
                                  ),
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
                                      color: Colors.white.withValues(alpha: 0.7),
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
                            color: const Color(0xFF115e5a).withValues(alpha: 0.6),
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

          // Color spreading overlay
          _buildColorSpreadOverlay(),

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

// Custom painter for the color spreading effect
class ColorSpreadPainter extends CustomPainter {
  final Offset origin;
  final double progress;
  final Color color;
  final Size screenSize;

  ColorSpreadPainter({
    required this.origin,
    required this.progress,
    required this.color,
    required this.screenSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Calculate the maximum radius needed to cover the entire screen
    final maxRadius = _calculateMaxRadius();
    
    // Current radius based on animation progress
    final currentRadius = maxRadius * progress;
    
    // Create the spreading circle with gradient fade
    final Paint paint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        colors: [
          color.withValues(alpha: 0.7 * (1.0 - progress * 0.5)), // More opaque at center
          color.withValues(alpha: 0.3 * (1.0 - progress * 0.8)), // Fade at edges
          Colors.transparent,
        ],
        stops: const [0.0, 0.7, 1.0],
      ).createShader(Rect.fromCircle(center: origin, radius: currentRadius))
      ..style = PaintingStyle.fill;

    // Draw the spreading circle
    canvas.drawCircle(origin, currentRadius, paint);

    // Add a subtle ring effect at the edge
    final ringPaint = Paint()
      ..color = color.withValues(alpha: 0.4 * (1.0 - progress))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(origin, currentRadius * 0.95, ringPaint);
  }

  double _calculateMaxRadius() {
    // Calculate distance to all corners and take the maximum
    final corners = [
      Offset.zero,
      Offset(screenSize.width, 0),
      Offset(0, screenSize.height),
      Offset(screenSize.width, screenSize.height),
    ];

    double maxDistance = 0;
    for (final corner in corners) {
      final distance = (corner - origin).distance;
      if (distance > maxDistance) {
        maxDistance = distance;
      }
    }

    return maxDistance * 1.2; // Add some extra to ensure full coverage
  }

  @override
  bool shouldRepaint(ColorSpreadPainter oldDelegate) {
    return oldDelegate.progress != progress ||
           oldDelegate.origin != origin ||
           oldDelegate.color != color;
  }
}
