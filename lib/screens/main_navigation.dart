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
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Main content with bottom bar
          BottomBar(
            child: TabBar(
              controller: _tabController,
              indicatorColor: colors[_tabController.index],
              dividerColor: Colors.transparent,
              labelColor: colors[_tabController.index],
              unselectedLabelColor: const Color.fromARGB(255, 21, 55, 26),
              onTap: (index) {
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
            body: (context, controller) => TabBarView(
              controller: _tabController,
              dragStartBehavior: DragStartBehavior.down,
              physics: const BouncingScrollPhysics(),
              children: _screens,
            ),
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
