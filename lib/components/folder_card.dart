import 'package:flutter/material.dart';
import 'folder_shape.dart';

class FolderCard extends StatelessWidget {
  final String title; // e.g., "September 2025"
  final int count; // number of entries
  final VoidCallback? onTap;

  const FolderCard({
    super.key,
    required this.title,
    required this.count,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        width: double.infinity,
        height: 126,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double w = constraints.maxWidth;
            final double h = constraints.maxHeight;

            // Responsive insets derived from the same proportional system
            // used by the painter paths
            // Content region derived from painter path_1 extents
            final double leftPad =
                w * 0.0692; // 0.0392 (left edge) + small inset
            final double rightPad = w * 0.0540; // (1-0.976) + small inset
            final double topPad =
                h * 0.33896; // 0.21896 (top edge) + small inset
            final double bottomPad = h * 0.17528; // (1-0.87472) + small inset

            // Count position (responsive anchor near top-left)
            final double countLeft = w * 0.08;
            final double countTop = h * 0.15;

            // Scale title font by width, clamped
            final double titleSize = (w * 0.12).clamp(12.0, 18.0);

            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: const RPSCustomPainter(
                      flapColor: Colors.white,
                      bodyColor: Colors.white,
                      borderColor: null,
                    ),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        leftPad,
                        topPad,
                        rightPad,
                        bottomPad,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            title,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  fontSize: titleSize,
                                  fontWeight: FontWeight.w600,
                                )
                                .apply(color: Colors.black),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                Positioned(
                  top: countTop,
                  left: countLeft,
                  child: Text(
                    count.toString(),
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(
                          fontSize: (w * 0.11).clamp(12.0, 18.0),
                          fontWeight: FontWeight.w600,
                        )
                        .apply(color: Colors.black.withValues(alpha: 0.6)),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
