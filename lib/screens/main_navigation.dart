import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:icons_plus/icons_plus.dart';
// import 'home_screen.dart'; // COMMENTED OUT - HomeScreen removed from navigation
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
    CupertinoColors.systemGreen,
    CupertinoColors.systemOrange,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Initialize screens
    _screens = [
      const MoodTrackerScreenContent(),
      const MeditationScreenContent(),
    ];
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Listener(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          child: Stack(
            children: [
              // Main content with bottom bar
              AnimatedBuilder(
                animation: _tabController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1,
                    child: BottomBar(
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
                      body: (context, controller) =>
                          NotificationListener<ScrollNotification>(
                            onNotification: (scrollNotification) {
                              if (scrollNotification
                                  is ScrollUpdateNotification) {}
                              return false;
                            },
                            child: TabBarView(
                              controller: _tabController,
                              dragStartBehavior: DragStartBehavior.down,
                              physics: const BouncingScrollPhysics(),
                              children: _screens,
                            ),
                          ),
                      child: TabBar(
                        controller: _tabController,
                        indicatorColor: colors[_tabController.index],
                        dividerColor: Colors.transparent,
                        labelColor: colors[_tabController.index],
                        unselectedLabelColor: const Color.fromARGB(
                          255,
                          21,
                          55,
                          26,
                        ),
                        onTap: (index) {
                          _tabController.animateTo(index);
                        },
                        tabs: const [
                          Tab(
                            icon: Icon(
                              FontAwesome.house_chimney_solid,
                              size: 24,
                            ),
                          ),
                          Tab(icon: Icon(FontAwesome.spa_solid, size: 24)),
                        ],
                      ),
                    ),
                  );
                },
              ),
              // Mini player removed per request
            ],
          ),
        ),
      ),
    );
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
