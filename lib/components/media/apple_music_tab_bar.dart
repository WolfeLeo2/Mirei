import 'package:flutter/material.dart';

class AppleMusicTabBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppleMusicTabBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!, width: 0.5)),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildTabItem(
              index: 0,
              icon: Icons.play_circle_outline,
              activeIcon: Icons.play_circle,
              label: 'Listen Now',
            ),
            _buildTabItem(
              index: 1,
              icon: Icons.grid_view_outlined,
              activeIcon: Icons.grid_view,
              label: 'Browse',
            ),
            _buildTabItem(
              index: 2,
              icon: Icons.radio_outlined,
              activeIcon: Icons.radio,
              label: 'Radio',
            ),
            _buildTabItem(
              index: 3,
              icon: Icons.library_music_outlined,
              activeIcon: Icons.library_music,
              label: 'Library',
            ),
            _buildTabItem(
              index: 4,
              icon: Icons.search_outlined,
              activeIcon: Icons.search,
              label: 'Search',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final bool isSelected = currentIndex == index;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSelected ? activeIcon : icon,
            color: isSelected ? Colors.red : Colors.grey[600],
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isSelected ? Colors.red : Colors.grey[600],
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
