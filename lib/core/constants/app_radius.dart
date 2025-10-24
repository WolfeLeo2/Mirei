import 'package:flutter/material.dart';

/// App Radius Constants
/// Provides consistent border radius values throughout the app
/// Supports both regular rounded corners and squircle (super-ellipse) shapes
class AppRadius {
  AppRadius._(); // Private constructor to prevent instantiation

  // Border radius values
  static const double none = 0.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;
  static const double huge = 40.0;
  static const double circle = 999.0; // Large value for fully circular

  // Semantic radius aliases
  static const double button = md; // 12
  static const double card = md; // 12
  static const double chip = lg; // 16
  static const double dialog = xl; // 20
  static const double bottomSheet = xxl; // 24
  static const double image = md; // 12
  static const double avatar = circle; // Fully circular

  // BorderRadius presets (regular rounded corners)
  static const BorderRadius noneRadius = BorderRadius.zero;
  static const BorderRadius xsRadius = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius smRadius = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdRadius = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgRadius = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlRadius = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius xxlRadius = BorderRadius.all(Radius.circular(xxl));
  static const BorderRadius xxxlRadius = BorderRadius.all(
    Radius.circular(xxxl),
  );
  static const BorderRadius hugeRadius = BorderRadius.all(
    Radius.circular(huge),
  );

  // Semantic BorderRadius presets
  static const BorderRadius buttonRadius = mdRadius;
  static const BorderRadius cardRadius = mdRadius;
  static const BorderRadius chipRadius = lgRadius;
  static const BorderRadius dialogRadius = xlRadius;
  static const BorderRadius bottomSheetRadius = xxlRadius;
  static const BorderRadius imageRadius = mdRadius;

  // Top-only radius (useful for bottom sheets, modals)
  static const BorderRadius topOnlyXl = BorderRadius.only(
    topLeft: Radius.circular(xl),
    topRight: Radius.circular(xl),
  );
  static const BorderRadius topOnlyXxl = BorderRadius.only(
    topLeft: Radius.circular(xxl),
    topRight: Radius.circular(xxl),
  );
  static const BorderRadius topOnlyXxxl = BorderRadius.only(
    topLeft: Radius.circular(xxxl),
    topRight: Radius.circular(xxxl),
  );

  // Bottom-only radius (useful for headers, app bars)
  static const BorderRadius bottomOnlyXl = BorderRadius.only(
    bottomLeft: Radius.circular(xl),
    bottomRight: Radius.circular(xl),
  );
  static const BorderRadius bottomOnlyXxl = BorderRadius.only(
    bottomLeft: Radius.circular(xxl),
    bottomRight: Radius.circular(xxl),
  );

  // Squircle shapes (super-ellipse) - more aesthetically pleasing
  // These should be used with RoundedSuperellipseBorder or similar
  static OutlinedBorder squircle(double radius) {
    try {
      return RoundedSuperellipseBorder(
        borderRadius: BorderRadius.all(Radius.circular(radius)),
      );
    } catch (_) {
      // Fallback to regular rounded rectangle if squircle not available
      return RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(radius)),
      );
    }
  }

  // Squircle presets
  static OutlinedBorder get squircleXs => squircle(xs);
  static OutlinedBorder get squircleSm => squircle(sm);
  static OutlinedBorder get squircleMd => squircle(md);
  static OutlinedBorder get squircleLg => squircle(lg);
  static OutlinedBorder get squircleXl => squircle(xl);
  static OutlinedBorder get squircleXxl => squircle(xxl);
  static OutlinedBorder get squircleXxxl => squircle(xxxl);

  // Semantic squircle presets
  static OutlinedBorder get squircleButton => squircleMd;
  static OutlinedBorder get squircleCard => squircleMd;
  static OutlinedBorder get squircleChip => squircleLg;
  static OutlinedBorder get squircleDialog => squircleXl;
  static OutlinedBorder get squircleBottomSheet => squircleXxl;

  // Circular clip
  static const BorderRadius circularRadius = BorderRadius.all(
    Radius.circular(circle),
  );

  // Helper method to create custom radius
  static BorderRadius custom({
    double topLeft = 0,
    double topRight = 0,
    double bottomLeft = 0,
    double bottomRight = 0,
  }) {
    return BorderRadius.only(
      topLeft: Radius.circular(topLeft),
      topRight: Radius.circular(topRight),
      bottomLeft: Radius.circular(bottomLeft),
      bottomRight: Radius.circular(bottomRight),
    );
  }
}
