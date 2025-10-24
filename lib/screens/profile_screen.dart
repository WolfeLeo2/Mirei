import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  firebase_auth.User? _currentUser;
  StreamSubscription<firebase_auth.User?>? _authSubscription;

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

  String _firstName(firebase_auth.User user) {
    final displayName = user.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName.split(' ').first;
    }
    final email = user.email;
    if (email != null && email.isNotEmpty) {
      final atIndex = email.indexOf('@');
      if (atIndex > 0) {
        return email.substring(0, atIndex);
      }
      return email;
    }
    return 'Friend';
  }

  String _initial(firebase_auth.User user) {
    final name = _firstName(user);
    if (name.isNotEmpty) {
      return name[0].toUpperCase();
    }
    return 'U';
  }

  Widget _buildAvatar(BuildContext context, firebase_auth.User user) {
    final theme = Theme.of(context);
    final photoUrl = user.photoURL;
    final initials = _initial(user);

    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: theme.colorScheme.primary.withAlpha(77),
          width: 3,
        ),
      ),
      child: ClipOval(
        child: photoUrl != null && photoUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: photoUrl,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
                progressIndicatorBuilder: (context, url, downloadProgress) => 
                CircularProgressIndicator(value: downloadProgress.progress),
                errorWidget: (_, __, ___) => _InitialsAvatar(
                  initials: initials,
                  background: theme.colorScheme.primaryContainer,
                  foreground: theme.colorScheme.onPrimaryContainer,
                ),
              )
            : _InitialsAvatar(
                initials: initials,
                background: theme.colorScheme.primaryContainer,
                foreground: theme.colorScheme.onPrimaryContainer,
              ),
      ),
    );
  }

@override
Widget build(BuildContext context) {
  final user = _currentUser;
  final theme = Theme.of(context);
  final screenWidth = MediaQuery.of(context).size.width;
  final avatarSize = 100.0; // 👈 Matches your avatar width/height
  final heroHeight = screenWidth * 0.4; // 👈 Responsive hero height (or use fixed like 200.0)
  final avatarOverlap = avatarSize / 2; // 👈 Half avatar overlaps

  if (user == null) {
    return Scaffold(
      body: SafeArea(child: _SignedOutMessage(theme: theme.textTheme)),
    );
  }

  return Scaffold(
    appBar: PreferredSize(
      preferredSize: Size.fromHeight(heroHeight + avatarOverlap), // 👈 Total height including overlap
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // SVG Hero Image
          SizedBox(
            height: heroHeight, // 👈 Actual AppBar height
            width: double.infinity,
            child: SvgPicture.asset(
              'assets/images/hero_clouds.svg',
              fit: BoxFit.cover,
            ),
          ),
          // Avatar positioned at bottom center
          Positioned(
            bottom: -avatarOverlap, // 👈 At the bottom of the AppBar
            left: 0,
            right: 0,
            child: Center(
              child: _buildAvatar(context, user),
            ),
          ),
        ],
      ),
    ),
    body: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 40), // 👈 Space for the overlapping avatar
            Center(
              child: Text(
                user.displayName ?? _firstName(user),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (user.email != null)
              Center(
                child: Text(
                  user.email!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodyMedium?.color
                        ?.withAlpha(179),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            _InfoTile(
              icon: Icons.calendar_month_outlined,
              title: 'Member since',
              subtitle: user.metadata.creationTime != null
                  ? DateFormat.yMMMMd()
                      .format(user.metadata.creationTime!)
                  : 'Unknown',
            ),
            _InfoTile(
              icon: Icons.shield_moon_outlined,
              title: 'Verification',
              subtitle:
                  user.emailVerified ? 'Email verified' : 'Pending',
            ),
            _InfoTile(
              icon: Icons.badge_outlined,
              title: 'User ID',
              subtitle: user.uid,
              isCopyable: true,
            ),
            const SizedBox(height: 16),
            const Text(
              'Recent sign-in providers',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ...user.providerData.map(
              (info) => _InfoTile(
                icon: Icons.login,
                title: info.providerId,
                subtitle: info.email ?? info.uid ?? '—',
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isCopyable;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isCopyable = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(icon, color: theme.colorScheme.primary),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: isCopyable
            ? IconButton(
                icon: const Icon(Icons.copy),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: subtitle));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied to clipboard')),
                  );
                },
              )
            : null,
      ),
    );
  }
}

class _SignedOutMessage extends StatelessWidget {
  final TextTheme theme;

  const _SignedOutMessage({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 48, color: theme.bodySmall?.color),
            const SizedBox(height: 16),
            Text(
              'You are not signed in',
              style: theme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Sign in to personalise your experience and keep your progress in sync.',
              style: theme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  final String initials;
  final Color background;
  final Color foreground;

  const _InitialsAvatar({
    required this.initials,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: background,
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: foreground,
          fontWeight: FontWeight.bold,
          fontSize: 32,
        ),
      ),
    );
  }
}
