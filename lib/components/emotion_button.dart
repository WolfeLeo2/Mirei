import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class EmotionButton extends StatelessWidget {
  final String emotion;
  final String svgPath;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onDoubleTap;

  const EmotionButton({
    super.key,
    required this.emotion,
    required this.svgPath,
    required this.isSelected,
    required this.onTap,
    this.onDoubleTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : const Color(0xFF1a6b67),
          borderRadius: BorderRadius.circular(25),
        ),
        constraints: const BoxConstraints(minHeight: 45, minWidth: 45),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SvgPicture.asset(
              svgPath,
              height: 35,
              fit: BoxFit.fill,
            ),
            const SizedBox(width: 8),
            Text(
              emotion,
              style: TextStyle(
                color: isSelected ? const Color(0xFF115e5a) : Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                fontFamily: '.SF Pro Text',
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
