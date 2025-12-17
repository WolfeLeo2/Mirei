import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';
import 'diary/diary_screen.dart';
import 'mood_entry_flow/mood_entry_flow.dart';
import 'progress.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  User? _currentUser;
  StreamSubscription<User?>? _authSubscription;

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

  String _firstName(User? user) {
    final displayName =
        (user?.userMetadata?['display_name'] as String?)?.trim() ??
        (user?.userMetadata?['full_name'] as String?)?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      final parts = displayName.split(' ');
      if (parts.isNotEmpty) {
        return parts.first;
      }
    }
    final email = user?.email;
    if (email != null && email.isNotEmpty) {
      final atIndex = email.indexOf('@');
      if (atIndex > 0) {
        return email.substring(0, atIndex);
      }
      return email;
    }
    return 'Friend';
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    if (hour < 22) return 'Good evening';
    return 'Hello';
  }

  Future<void> _startMoodCheckIn() async {
    final username = _firstName(_currentUser);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            MoodEntryFlow(username: username, onComplete: () {}),
      ),
    );
  }

  Future<void> _openDiary() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const DiaryScreen()));
  }

  Future<void> _openProgress() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const ProgressScreen()));
  }

  Widget _buildAvatar(BuildContext context) {
    final theme = Theme.of(context);
    final size = 36.0;
    final photoUrl =
        _currentUser?.userMetadata?['avatar_url'] as String? ??
        _currentUser?.userMetadata?['picture'] as String?;
    final initials = _deriveInitials(_currentUser);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.25),
          width: 1.5,
        ),
      ),
      child: ClipOval(
        child: photoUrl != null && photoUrl.isNotEmpty
            ? Image.network(
                photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _InitialsAvatar(
                  initials: initials,
                  background: theme.colorScheme.primaryContainer,
                ),
              )
            : _InitialsAvatar(
                initials: initials,
                background: theme.colorScheme.primaryContainer,
              ),
      ),
    );
  }

  String _deriveInitials(User? user) {
    final first = _firstName(user);
    if (first.isNotEmpty) {
      return first[0].toUpperCase();
    }
    return 'U';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = _currentUser;
    final firstName = _firstName(user);

    return Scaffold(
      appBar: AppBar(
        title: Text('${_greeting()}, $firstName'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _buildAvatar(context),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _HomeHeroCard(
              firstName: firstName,
              onCheckInPressed: _startMoodCheckIn,
            ),
            const SizedBox(height: 24),
            Text(
              'Quick actions',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _QuickLinkCard(
              title: 'Open Diary',
              subtitle: 'Capture thoughts, feelings, and favorite moments.',
              icon: Icons.auto_awesome_outlined,
              onTap: _openDiary,
            ),
            _QuickLinkCard(
              title: 'View Progress',
              subtitle: 'See how your moods have changed recently.',
              icon: Icons.show_chart_outlined,
              onTap: _openProgress,
            ),
            const SizedBox(height: 24),
            Text(
              'Need a suggestion?',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _SuggestionTile(
              title: 'Take a mindful pause',
              description:
                  'Spend 2 minutes breathing deeply and notice how your body feels.',
            ),
            _SuggestionTile(
              title: 'Reach out to someone',
              description:
                  'Send a quick message to a friend you have not spoken to recently.',
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeHeroCard extends StatelessWidget {
  final String firstName;
  final VoidCallback onCheckInPressed;

  const _HomeHeroCard({
    required this.firstName,
    required this.onCheckInPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back, $firstName',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'How are you feeling today? A quick check-in can help you notice patterns.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onCheckInPressed,
              icon: const Icon(Icons.favorite_outline),
              label: const Text('Start check-in'),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickLinkCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickLinkCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  final String title;
  final String description;

  const _SuggestionTile({required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(description, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  final String initials;
  final Color background;

  const _InitialsAvatar({required this.initials, required this.background});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: background,
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }
}
