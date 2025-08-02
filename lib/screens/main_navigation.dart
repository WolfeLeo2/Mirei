import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'dart:ui';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mirei/bloc/emotion_bloc.dart';
import 'package:mirei/features/media_player/presentation/screens/media_player_screen.dart';
import 'package:mirei/components/media/mini_player.dart';
import 'home_screen.dart';
import 'mood_tracker.dart';

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
      const Journal2ScreenContent(),
      const CalendarScreen(),
      const MediaPlayerScreen(),
    ];

    _tabController.addListener(() {
      // Dispatch BLoC event when tab changes
      context.read<EmotionBloc>().add(EmotionSelected(_tabController.index));
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EmotionBloc, EmotionState>(
      builder: (context, state) {
        int currentIndex = 0;
        if (state is EmotionLoadSuccess) {
          currentIndex = state.selectedIndex;
        }

        return Scaffold(
          body: Stack(
            children: [
              BottomBar(
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: colors[currentIndex],
                  dividerColor: Colors.transparent,
                  labelColor: colors[currentIndex],
                  unselectedLabelColor: const Color.fromARGB(255, 77, 64, 64),
                onTap: (index) {
                    // Dispatch BLoC event when tab is tapped
                  context.read<EmotionBloc>().add(EmotionSelected(index));
                  _tabController.animateTo(index);
                },
                  tabs: const [
                    Tab(
                      icon: Icon(
                        Icons.home_filled,
                        size: 24,
                      ),
                    ),
                    Tab(
                      icon: Icon(
                        FontAwesome.book_open_solid,
                        size: 24,
                      ),
                    ),
                    Tab(
                      icon: Icon(
                        Icons.calendar_today_outlined,
                        size: 24,
                      ),
                    ),
                    Tab(
                      icon: Icon(
                        FontAwesome.microphone_solid,
                        size: 24,
                      ),
                    ),
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
                onBottomBarHidden: () {},
                onBottomBarShown: () {},
                body: (context, controller) => TabBarView(
                  controller: _tabController,
                  dragStartBehavior: DragStartBehavior.down,
                  physics: const BouncingScrollPhysics(),
                  children: _screens,
                  ),
              ),
              // Mini Player positioned above bottom navigation
              Positioned(
                left: 0,
                right: 0,
                bottom: 100, // Position above the bottom bar
                child: const MiniPlayer(),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Content-only version of HomeScreen (without its own navigation)
class HomeScreenContent extends StatelessWidget {
  const HomeScreenContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const HomeScreen();
  }
}

// Content-only version of Journal2Screen (without its own navigation)
class Journal2ScreenContent extends StatelessWidget {
  const Journal2ScreenContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const Journal2Screen();
  }
}

class MediaPlayerScreenContent extends StatelessWidget {
  const MediaPlayerScreenContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const MediaPlayerScreen();
  }
}

// Placeholder screens
class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.blue.shade100,
      child: const SafeArea(
        child: Center(
          child: Text(
            'Calendar Screen',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
