import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class ActivityIcon extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final String svgIcon;
  final String svgShape;
  final double size;
  final double? shapeSize;
  final Color? iconColor;
  final Color? shapeColor;

  const ActivityIcon({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.svgIcon,
    required this.svgShape,
    this.size = 100,
    this.shapeSize,
    this.iconColor,
    this.shapeColor,
  });

  @override
  Widget build(BuildContext context) {
    final actualShapeSize = shapeSize ?? size;

    return Column(
      children: [
        Container(
          width: size,
          height: size,
          margin: const EdgeInsets.only(left: 10, right: 5),
          color: Colors.transparent,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SvgPicture.asset(
                svgShape,
                width: actualShapeSize,
                height: actualShapeSize,
                color: shapeColor ?? backgroundColor,
              ),
              SvgPicture.asset(
                svgIcon,
                width: size * 0.4,
                height: size * 0.4,
                color: iconColor ?? Colors.black,
                fit: BoxFit.contain,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: TextStyle(
            color: Colors.black54,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            fontFamily: GoogleFonts.inter().fontFamily,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
