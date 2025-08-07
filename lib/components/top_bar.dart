import 'package:flutter/material.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:mirei/models/session_info.dart';

class TopBar extends StatelessWidget {
  final SessionInfo session;
  const TopBar({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(60.0, 20.0, 20.0, 0),
        child: Row(
          children: [
            Expanded(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(
                      0.3,
                    ), // Increased opacity, removed BackdropFilter
                    borderRadius: BorderRadius.circular(50.0),
                    border: Border.all(color: Colors.white.withOpacity(0.4)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(
                          0.05,
                        ), // Reduced opacity
                        blurRadius: 8, // Reduced blur
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.wb_sunny_outlined,
                        color: const Color(0xFF1a237e),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${session.greeting}',
                        style: const TextStyle(
                          color: Color(0xFF1a237e),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(width: 8),
          PullDownButton(
            itemBuilder: (context) => [
              PullDownMenuItem(
                title: 'Profile',
                icon: CupertinoIcons.person,
                onTap: () {},
              ),
              PullDownMenuItem(
                title: 'Settings',
                icon: CupertinoIcons.settings,
                onTap: () {},
              ),
              PullDownMenuItem(
                title: 'Feedback',
                icon: CupertinoIcons.chat_bubble_2,
                onTap: () {},
              ),
              const PullDownMenuDivider.large(),
              PullDownMenuItem(
                title: 'Logout',
                icon: CupertinoIcons.square_arrow_right,
                isDestructive: true,
                onTap: () {},
              ),
            ],
            buttonBuilder: (context, showMenu) => Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.menu,
                  color: const Color(0xFF1a237e),
                  size: 24,
                ),
                onPressed: showMenu,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
          ),
      ]
      ),
        
      ),
    );
  }
}
