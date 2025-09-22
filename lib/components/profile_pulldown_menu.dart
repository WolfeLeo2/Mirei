import 'package:flutter/material.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:flutter/cupertino.dart';
import '../services/auth_service.dart';

class ProfilePulldownMenu extends StatelessWidget {
  final Widget child;
  final VoidCallback? onProfileTap;
  final VoidCallback? onSettingsTap;
  final VoidCallback? onFeedbackTap;

  const ProfilePulldownMenu({
    super.key,
    required this.child,
    this.onProfileTap,
    this.onSettingsTap,
    this.onFeedbackTap,
  });

  Future<void> _handleLogout(BuildContext context) async {
    // Show confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      try {
        await AuthService().signOut();

        // Clear navigation stack and return to AuthWrapper
        if (context.mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error signing out: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PullDownButton(
      itemBuilder: (context) => [
        PullDownMenuItem(
          title: 'Profile',
          icon: CupertinoIcons.person,
          onTap: onProfileTap ?? () {},
        ),
        PullDownMenuItem(
          title: 'Settings',
          icon: CupertinoIcons.settings,
          onTap: onSettingsTap ?? () {},
        ),
        PullDownMenuItem(
          title: 'Feedback',
          icon: CupertinoIcons.chat_bubble_2,
          onTap: onFeedbackTap ?? () {},
        ),
        const PullDownMenuDivider.large(),
        PullDownMenuItem(
          title: 'Logout',
          icon: CupertinoIcons.square_arrow_right,
          isDestructive: true,
          onTap: () => _handleLogout(context),
        ),
      ],
      buttonBuilder: (context, showMenu) =>
          GestureDetector(onTap: showMenu, child: child),
    );
  }
}
