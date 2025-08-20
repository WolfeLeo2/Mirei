import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:mirei/screens/media_screen.dart';
import 'package:mirei/widgets/mini_player.dart';
import 'home_screen.dart';
import 'mood_tracker.dart';
import 'meditation_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation>
    with TickerProviderStateMixin {
  late TabController _tabController;

  // Define your screens here
  late final List<Widget> _screens;

  final List<Color> colors = [
    const Color.fromARGB(255, 119, 10, 90), // Beige
    Colors.green,
    Colors.amberAccent,
    Color(0xFF1e3a8a), // Yellow/Golden
  ];

  // Breathing animation variables
  late AnimationController _breathingController;
  late Animation<double> _breathingAnimation;
  bool _isUserActive = false;
  DateTime _lastActivity = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Initialize screens
    _screens = [
      const HomeScreenContent(),
      const MoodTrackerScreenContent(),
      const MeditationScreen(),
      const MediaScreenContent(),
    ];

    _tabController.addListener(() {
      _markUserActivity(); // Tab change is user activity
      setState(() {});
    });

    // Initialize breathing animation
    _initializeBreathingAnimation();
    
    // Start monitoring user activity
    _startActivityMonitoring();
  }

  void _initializeBreathingAnimation() {
    _breathingController = AnimationController(
      duration: const Duration(milliseconds: 2500), // 2.5 second breathing cycle
      vsync: this,
    );

    _breathingAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02, // Very subtle 2% scale
    ).animate(CurvedAnimation(
      parent: _breathingController,
      curve: Curves.easeInOut,
    ));
  }

  void _startActivityMonitoring() {
    // Check every second if user has been idle long enough to start breathing
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 5));
      
      if (!mounted) return false;
      
      final timeSinceActivity = DateTime.now().difference(_lastActivity);
      final shouldBreathe = timeSinceActivity.inSeconds > 120; // Start breathing after 2 minutes of inactivity
      
      if (shouldBreathe && !_isUserActive && !_breathingController.isAnimating) {
        print('🌬️ Starting breathing animation after ${timeSinceActivity.inSeconds} seconds of inactivity');
        _breathingController.repeat(reverse: true);
      } else if (_isUserActive && _breathingController.isAnimating) {
        print('⏹️ Stopping breathing animation due to user activity');
        _breathingController.stop();
        _breathingController.reset();
      }
      
      return true;
    });
  }

  void _markUserActivity() {
    setState(() {
      _isUserActive = true;
      _lastActivity = DateTime.now();
    });
    
    // Mark as inactive after a brief delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isUserActive = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _breathingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Listener(
        onPointerDown: (_) => _markUserActivity(), // Catches ALL pointer events including TabBar taps
        child: GestureDetector(
          onTap: _markUserActivity,
          onTapDown: (_) => _markUserActivity(), // More reliable tap detection
          onPanUpdate: (_) => _markUserActivity(),
          onPanStart: (_) => _markUserActivity(),
          behavior: HitTestBehavior.translucent,
          child: Stack(
            children: [
              // Main content with bottom bar
              AnimatedBuilder(
                animation: _breathingAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _breathingAnimation.value,
                    child: BottomBar(
                      child: TabBar(
                        controller: _tabController,
                        indicatorColor: colors[_tabController.index],
                        dividerColor: Colors.transparent,
                        labelColor: colors[_tabController.index],
                        unselectedLabelColor: const Color.fromARGB(255, 21, 55, 26),
                        onTap: (index) {
                          _markUserActivity(); // Tab tap is user activity
                          _tabController.animateTo(index);
                        },
                        tabs: const [
                          Tab(icon: Icon(FontAwesome.house_chimney_solid, size: 24)),
                          Tab(icon: Icon(FontAwesome.book_journal_whills_solid, size: 24)),
                          Tab(icon: Icon(FontAwesome.spa_solid, size: 24)),
                          Tab(icon: Icon(FontAwesome.radio_solid, size: 24)),
                        ],
                      ),
                      fit: StackFit.expand,
                      icon: (width, height) => Center(
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          onPressed: null,
                          icon: Icon(
                            Icons.arrow_upward_rounded,
                            color: Colors.black,
                            size: width,
                          ),
                        ),
                      ),
                      borderRadius: BorderRadius.circular(500),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.decelerate,
                      showIcon: true,
                      width: MediaQuery.of(context).size.width * 0.6,
                      start: 2,
                      end: 0,
                      offset: 10,
                      barAlignment: Alignment.bottomCenter,
                      iconHeight: 35,
                      iconWidth: 35,
                      barColor: const Color.fromARGB(212, 255, 255, 255),
                      hideOnScroll: true,
                      scrollOpposite: false,
                      body: (context, controller) => NotificationListener<ScrollNotification>(
                        onNotification: (scrollNotification) {
                          if (scrollNotification is ScrollUpdateNotification) {
                            _markUserActivity(); // Scrolling is user activity
                          }
                          return false;
                        },
                        child: TabBarView(
                          controller: _tabController,
                          dragStartBehavior: DragStartBehavior.down,
                          physics: const BouncingScrollPhysics(),
                          children: _screens,
                        ),
                      ),
                    ),
                  );
                },
              ),
              
              // Mini player positioned above the floating bottom bar
              Positioned(
                left: 0,
                right: 0,
                bottom: 60, // Move lower but keep above the floating bottom bar
                child: const MiniPlayer(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Content-only version of HomeScreen (without its own navigation)
class HomeScreenContent extends StatefulWidget {
  const HomeScreenContent({super.key});

  @override
  State<HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<HomeScreenContent>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return const HomeScreen();
  }
}

// Content-only version of MoodTrackerScreen (without its own navigation)
class MoodTrackerScreenContent extends StatefulWidget {
  const MoodTrackerScreenContent({super.key});

  @override
  State<MoodTrackerScreenContent> createState() =>
      _MoodTrackerScreenContentState();
}

class _MoodTrackerScreenContentState extends State<MoodTrackerScreenContent>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return const MoodTrackerScreen();
  }
}

// Content-only version of MeditationScreen (without its own navigation)
class MeditationScreenContent extends StatefulWidget {
  const MeditationScreenContent({super.key});

  @override
  State<MeditationScreenContent> createState() =>
      _MeditationScreenContentState();
}

class _MeditationScreenContentState extends State<MeditationScreenContent>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return const MeditationScreen();
  }
}

// Content-only version of MediaScreen (without its own navigation)
class MediaScreenContent extends StatefulWidget {
  const MediaScreenContent({super.key});

  @override
  State<MediaScreenContent> createState() => _MediaScreenContentState();
}

class _MediaScreenContentState extends State<MediaScreenContent>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return const MediaScreen();
  }
}
