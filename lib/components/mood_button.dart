import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:motor/motor.dart';
import '../core/theme/typography.dart';

class MoodButton extends StatefulWidget {
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
  State<MoodButton> createState() => _MoodButtonState();
}

class _MoodButtonState extends State<MoodButton>
    with SingleTickerProviderStateMixin {
  late SingleMotionController _scaleController;
  late Animation<double> _sizeMultiplier;
  late Animation<double> _cornerRadius;

  @override
  void initState() {
    super.initState();
    debugPrint(
      '🎬 MoodButton ${widget.Mood} initState: isSelected=${widget.isSelected}',
    );
    _scaleController = SingleMotionController(
      motion:
          MaterialSpringMotion.expressiveSpatialFast(), // M3 expressive spatial - designed for UI elements
      vsync: this,
    );

    // Size animation: 1.0x (normal) to 1.15x (selected) - more visible
    _sizeMultiplier = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(_scaleController);

    // Corner radius animation: 25 (normal) to 24.75 (selected) - reduces by 0.25
    _cornerRadius = Tween<double>(
      begin: 25.0,
      end: 18.75,
    ).animate(_scaleController);

    // Initialize: selected starts at 1.0 (will animate), unselected starts at 0.0
    _scaleController.value = widget.isSelected ? 0.85 : 0;
    debugPrint('  → Initial controller value: ${_scaleController.value}');
  }

  @override
  void didUpdateWidget(MoodButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    // When selection changes, animate to new state with spring physics
    if (widget.isSelected != oldWidget.isSelected) {
      debugPrint(
        '🎯 MoodButton ${widget.Mood}: selection changed to ${widget.isSelected}',
      );
      if (widget.isSelected) {
        // Became selected: spring animate to 1.15x (controller = 1.0)
        debugPrint('  → Animating TO selected (1.0)');
        _scaleController.animateTo(1.0);
      } else {
        // Became unselected: animate back to 1.0x (controller = 0.0)
        debugPrint('  → Animating TO unselected (0.0)');
        _scaleController.animateTo(0.0);
      }
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _scaleController,
          builder: (context, child) {
            final double multiplier = _sizeMultiplier.value;
            final double radius =
                _cornerRadius.value; // Use radius directly (not multiplied)
            return Container(
              margin: const EdgeInsets.only(right: 12),
              padding: EdgeInsets.symmetric(
                horizontal: 20 * multiplier,
                vertical: 0,
              ),
              decoration: BoxDecoration(
                // Instant color change (no animation)
                color: widget.isSelected
                    ? Colors.white
                    : const Color(0xFF1a6b67),
                borderRadius: BorderRadius.circular(radius),
              ),
              constraints: BoxConstraints(
                minHeight: 45 * multiplier,
                minWidth: 45 * multiplier,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  RepaintBoundary(
                    child: SvgPicture.asset(
                      widget.svgPath,
                      height: 35 * multiplier,
                      fit: BoxFit.fill,
                    ),
                  ),
                  SizedBox(width: 8 * multiplier),
                  RepaintBoundary(
                    child: Text(
                      widget.Mood,
                      style: TextStyle(
                        // Instant color change (no animation)
                        color: widget.isSelected
                            ? const Color(0xFF115e5a)
                            : Colors.white,
                        fontSize: (widget.isSelected ? 17 : 16) * multiplier,
                        fontWeight: widget.isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        fontFamily: AppTypography.primaryFontFamily,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
