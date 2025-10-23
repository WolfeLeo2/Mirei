import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'home_screen.dart';
import 'mood_tracker.dart';
import 'profile_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  firebase_auth.User? _currentUser;
  StreamSubscription<firebase_auth.User?>? _authSubscription;

  final List<Widget> _screens = const [
    HomeScreen(),
    MoodTrackerScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    final authService = AuthService();
    _currentUser = authService.currentUser;
    _authSubscription = authService.authStateChanges.listen((user) {
      if (!mounted) return;
      setState(() => _currentUser = user);
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

    String _firstName(firebase_auth.User? user) {
    final displayName = user?.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      final parts = displayName.split(' ');
      if (parts.isNotEmpty) {
        return parts.first;
      }
    }
    return 'Profile';
  }

  void _onDestinationSelected(int index) {
    if (index == _selectedIndex) {
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final firstName = _firstName(_currentUser);

    final destinations = <NavigationDestination>[
      const NavigationDestination(
        icon: Icon(CupertinoIcons.house),
        selectedIcon: Icon(CupertinoIcons.house_fill),
        label: 'Home',
      ),
      const NavigationDestination(
        icon: Icon(CupertinoIcons.rectangle_3_offgrid),
        selectedIcon: Icon(CupertinoIcons.rectangle_3_offgrid_fill),
        label: 'Explore',
      ),
      NavigationDestination(
        icon: _ProfileIcon(user: _currentUser, selected: false),
        selectedIcon: _ProfileIcon(user: _currentUser, selected: true),
        label: firstName,
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: destinations,
      ),
    );
  }
}

class _ProfileIcon extends StatelessWidget {
  final firebase_auth.User? user;
  final bool selected;

  const _ProfileIcon({required this.user, required this.selected});

  static const double _size = 28;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (user == null) {
      return Icon(
        selected ? CupertinoIcons.person_fill : CupertinoIcons.person,
      );
    }

    final photoUrl = user!.photoURL;
    final initials = _initialsFor(user!);
    final borderColor = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.outline.withOpacity(0.3);

    if (photoUrl != null && photoUrl.isNotEmpty) {
      return Container(
        width: _size,
        height: _size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: selected ? 1.5 : 1),
        ),
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: photoUrl,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
            errorWidget: (_, __, ___) =>
                _ProfileInitialsBadge(initials: initials, selected: selected),
          ),
        ),
      );
    }

    return _ProfileInitialsBadge(initials: initials, selected: selected);
  }

  static String _initialsFor(firebase_auth.User user) {
    final displayName = user.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      final parts = displayName
          .split(RegExp(r'\s+'))
          .where((segment) => segment.isNotEmpty)
          .toList();
      if (parts.isNotEmpty) {
        final first = parts.first[0].toUpperCase();
        if (parts.length > 1) {
          final last = parts.last[0].toUpperCase();
          return '$first$last';
        }
        return first;
      }
    }

    final email = user.email;
    if (email != null && email.isNotEmpty) {
      return email[0].toUpperCase();
    }

    return 'U';
  }
}

class _ProfileInitialsBadge extends StatelessWidget {
  final String initials;
  final bool selected;

  const _ProfileInitialsBadge({required this.initials, required this.selected});

  static const double _size = _ProfileIcon._size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.secondaryContainer;
    final foreground = selected
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSecondaryContainer;

    return Container(
      width: _size,
      height: _size,
      alignment: Alignment.center,
      decoration: BoxDecoration(shape: BoxShape.circle, color: background),
      child: Text(
        initials,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      ),
    );
  }
}
