import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:icons_plus/icons_plus.dart';
import 'home_screen.dart';
import 'journal2.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;

  // Define your screens here
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Initialize screens
    _screens = [
      const HomeScreenContent(), // We'll create this
      const Journal2ScreenContent(), // We'll create this
      const CalendarScreen(), // Placeholder
      const ProfileScreen(), // Placeholder
    ];

    _tabController.addListener(() {
      setState(() {
        _currentIndex = _tabController.index;
      });
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
      body: BottomBar(
        fit: StackFit.expand,
        icon: (width, height) => Center(
          child: IconButton(
            padding: EdgeInsets.zero,
            onPressed: null,
            icon: Icon(
              Icons.arrow_upward_rounded,
              color: Colors.white,
              size: width,
            ),
          ),
        ),
        borderRadius: BorderRadius.circular(500),
        duration: const Duration(seconds: 1),
        curve: Curves.decelerate,
        showIcon: true,
        width: MediaQuery.of(context).size.width * 0.6,
        barColor: const Color.fromARGB(255, 158, 154, 209).withOpacity(0.4),
        start: 2,
        end: 0,
        offset: 10,
        barAlignment: Alignment.bottomCenter,
        iconHeight: 60,
        iconWidth: 60,
        reverse: false,
        hideOnScroll: false,
        scrollOpposite: false,
        onBottomBarHidden: () {},
        onBottomBarShown: () {},
        body: (context, controller) => TabBarView(
          controller: _tabController,
          dragStartBehavior: DragStartBehavior.down,
          physics: const BouncingScrollPhysics(),
          children: _screens,
        ),
        child: TabBar(
          controller: _tabController,
          indicatorColor: const Color.fromARGB(255, 54, 54, 105),
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xFF1a237e).withOpacity(0.7),
          tabs: [
            Tab(
              icon: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _currentIndex == 0
                      ? const Color.fromARGB(255, 20, 50, 81)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.home_filled,
                  size: 24,
                  color: _currentIndex == 0
                      ? Colors.white
                      : const Color(0xFF1a237e).withOpacity(0.7),
                ),
              ),
            ),
            Tab(
              icon: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _currentIndex == 1
                      ? const Color.fromARGB(255, 20, 50, 81)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.gif_box_rounded,
                  size: 24,
                  color: _currentIndex == 1
                      ? Colors.white
                      : const Color(0xFF1a237e).withOpacity(0.7),
                ),
              ),
            ),
            Tab(
              icon: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _currentIndex == 2
                      ? const Color.fromARGB(255, 20, 50, 81)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.calendar_today_outlined,
                  size: 24,
                  color: _currentIndex == 2
                      ? Colors.white
                      : const Color(0xFF1a237e).withOpacity(0.7),
                ),
              ),
            ),
            Tab(
              icon: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _currentIndex == 3
                      ? const Color.fromARGB(255, 20, 50, 81)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  FontAwesome.microphone_solid,
                  size: 24,
                  color: _currentIndex == 3
                      ? Colors.white
                      : const Color(0xFF1a237e).withOpacity(0.7),
                ),
              ),
            ),
          ],
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

class _HomeScreenContentState extends State<HomeScreenContent> {
  @override
  Widget build(BuildContext context) {
    // Import the actual HomeScreen content
    return const HomeScreen();
  }
}

// Content-only version of Journal2Screen (without its own navigation)
class Journal2ScreenContent extends StatefulWidget {
  const Journal2ScreenContent({super.key});

  @override
  State<Journal2ScreenContent> createState() => _Journal2ScreenContentState();
}

class _Journal2ScreenContentState extends State<Journal2ScreenContent> {
  @override
  Widget build(BuildContext context) {
    // Return the actual Journal2Screen content
    return const Journal2Screen();
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

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.purple.shade100,
      child: const SafeArea(
        child: Center(
          child: Text(
            'Profile Screen',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
