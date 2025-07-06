import 'dart:io';
import 'package:flutter/material.dart';

class ImageDisplay extends StatelessWidget {
  final File? imageFile;
  final double cutBottomHorizontalOffset;
  final double cutLeftVerticalOffset;
  final double outerWhiteBorderThickness;

  const ImageDisplay({
    Key? key,
    required this.imageFile,
    required this.cutBottomHorizontalOffset,
    required this.cutLeftVerticalOffset,
    required this.outerWhiteBorderThickness,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double totalPaddingForImage = outerWhiteBorderThickness;

    return imageFile != null
        ? SizedBox(
      width: 200 + (totalPaddingForImage * 2),
      height: 200 + (totalPaddingForImage * 2),
      child: CustomPaint(
        painter: PokedexDisplayPainter(
          outerBorderColor: Colors.white,
          outerBorderThickness: outerWhiteBorderThickness,
          innerBorderColor: Colors.transparent,
          innerBorderThickness: 0.0,
          cutBottomHorizontalOffset: cutBottomHorizontalOffset,
          cutLeftVerticalOffset: cutLeftVerticalOffset,
        ),
        child: Padding(
          padding: EdgeInsets.all(totalPaddingForImage),
          child: ClipPath(
            clipper: PokedexImageClipper(
              cutBottomHorizontalOffset: cutBottomHorizontalOffset,
              cutLeftVerticalOffset: cutLeftVerticalOffset,
            ),
            child: Image.file(
              imageFile!,
              height: 200,
              width: 200,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    )
        : const Text('No image selected');
  }
}

// Custom Painter Class for the Pokedex Display Border
class PokedexDisplayPainter extends CustomPainter {
  final Color outerBorderColor;
  final double outerBorderThickness;
  final Color innerBorderColor;
  final double innerBorderThickness;
  final double cutBottomHorizontalOffset;
  final double cutLeftVerticalOffset;

  PokedexDisplayPainter({
    required this.outerBorderColor,
    required this.outerBorderThickness,
    required this.innerBorderColor,
    required this.innerBorderThickness,
    required this.cutBottomHorizontalOffset,
    required this.cutLeftVerticalOffset,
  });

  static const double topDotRadius = 3.0;
  static const double topDotYOffset = 4.0;
  static const double topDotHorizontalSpacing = 10.0;

  static const double bottomLeftDotRadius = 6.0;
  static const double bottomLeftDotXOffsetFromLeft = 12.0;
  static const double bottomLeftDotYOffsetFromBottomCut = 12.0;

  // Constants for the three horizontal black lines
  static const double lineThickness = 2.0;
  static const double lineHeight = 2.0;
  static const double lineWidth = 15.0;
  static const double lineSpacing = 4.0;
  static const double linesRightOffsetFromOuterEdge = 20.0;
  static const double linesBottomOffsetFromOuterEdge = -6.0; // Keep this value or adjust as needed

  @override
  void paint(Canvas canvas, Size size) {
    final outerPaint = Paint()
      ..color = outerBorderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = outerBorderThickness;

    final outerPath = Path();
    outerPath.moveTo(0, 0);
    outerPath.lineTo(size.width, 0);
    outerPath.lineTo(size.width, size.height);
    outerPath.lineTo(cutBottomHorizontalOffset, size.height);
    outerPath.lineTo(0, size.height - cutLeftVerticalOffset);
    outerPath.close();

    canvas.drawPath(outerPath, outerPaint);

    final dotPaint = Paint()
      ..color = const Color(0xFFD32F2F)
      ..style = PaintingStyle.fill;

    final double topDotY = topDotYOffset;
    final double centerWidth = size.width / 2;

    canvas.drawCircle(Offset(centerWidth - topDotHorizontalSpacing, topDotY), topDotRadius, dotPaint);
    canvas.drawCircle(Offset(centerWidth + topDotHorizontalSpacing, topDotY), topDotRadius, dotPaint);

    final double bottomLeftDotX = bottomLeftDotXOffsetFromLeft;
    final double bottomLeftDotY = size.height - cutLeftVerticalOffset + (cutLeftVerticalOffset - bottomLeftDotYOffsetFromBottomCut);

    canvas.drawCircle(Offset(bottomLeftDotX, bottomLeftDotY), bottomLeftDotRadius, dotPaint);

    final linePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final double baseLineY = size.height - linesBottomOffsetFromOuterEdge - lineHeight;
    final double baseLineX = size.width - linesRightOffsetFromOuterEdge - lineWidth;

    for (int i = 0; i < 3; i++) {
      final double currentLineY = baseLineY - (i * (lineHeight + lineSpacing));
      canvas.drawRect(
        Rect.fromLTWH(baseLineX, currentLineY, lineWidth, lineHeight),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is PokedexDisplayPainter) {
      return oldDelegate.outerBorderColor != outerBorderColor ||
          oldDelegate.outerBorderThickness != outerBorderThickness ||
          oldDelegate.cutBottomHorizontalOffset != cutBottomHorizontalOffset ||
          oldDelegate.cutLeftVerticalOffset != cutLeftVerticalOffset;
    }
    return true;
  }
}

class PokedexImageClipper extends CustomClipper<Path> {
  final double cutBottomHorizontalOffset;
  final double cutLeftVerticalOffset;

  PokedexImageClipper({
    required this.cutBottomHorizontalOffset,
    required this.cutLeftVerticalOffset,
  });

  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(cutBottomHorizontalOffset, size.height);
    path.lineTo(0, size.height - cutLeftVerticalOffset);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    if (oldClipper is PokedexImageClipper) {
      return oldClipper.cutBottomHorizontalOffset != cutBottomHorizontalOffset ||
          oldClipper.cutLeftVerticalOffset != cutLeftVerticalOffset;
    }
    return false;
  }
}