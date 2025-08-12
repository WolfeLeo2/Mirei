import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class MoodButton extends StatelessWidget {
  final String Mood;
  final String svgPath;
  final bool isSelected;
  final VoidCallback onTap;

  const MoodButton({
    super.key,
    required this.Mood,
    required this.svgPath,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque, // Improves touch responsiveness
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
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
              // Add RepaintBoundary for SVG icon to optimize repaints
              RepaintBoundary(
                child: Transform.scale(
                  scale: isSelected ? 1.0 : 1.0,
                  child: SvgPicture.asset(svgPath, height: 35, fit: BoxFit.fill),
                ),
              ),
              const SizedBox(width: 8),
              // Add RepaintBoundary for text to optimize when only selection changes
              RepaintBoundary(
                child: Text(
                  Mood,
                  style: TextStyle(
                    color: isSelected ? const Color(0xFF115e5a) : Colors.white,
                    fontSize: isSelected ? 17 : 16,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontFamily: GoogleFonts.inter().fontFamily,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
