import 'package:flutter/material.dart';

import 'tokens.dart';

/// Brand drink illustration (same drawing language as the approved app icon).
/// Used as a placeholder until ORIGINAL product photos are uploaded — the UI
/// labels it as an illustration, never as a photo of the product.
class DrinkArt extends StatelessWidget {
  const DrinkArt({super.key, required this.palette, this.size = 120, this.fill = 1, this.ribbon = 1, this.topping = true});
  final (Color, Color) palette;
  final double size;
  final double fill; // 0..1 — used by the order-confirmed animation
  final double ribbon; // 0..1 — ribbon unfurl
  final bool topping;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: CustomPaint(size: Size(size * .86, size), painter: _DrinkPainter(palette, fill, ribbon, topping)),
      );
}

class _DrinkPainter extends CustomPainter {
  _DrinkPainter(this.p, this.fill, this.ribbon, this.topping);
  final (Color, Color) p;
  final double fill, ribbon;
  final bool topping;

  @override
  void paint(Canvas canvas, Size s) {
    // native drawing space 600 × 700 (same as the brand SVG glass)
    canvas.save();
    canvas.scale(s.width / 600, s.height / 700);
    canvas.translate(300, 690);

    // floor shadow
    canvas.drawOval(Rect.fromCenter(center: const Offset(0, 4), width: 440, height: 40), Paint()..color = FbColors.cocoa.withValues(alpha: .12));
    // straw
    canvas.save();
    canvas.translate(128, -486);
    canvas.rotate(.49);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-22, -264, 44, 420), const Radius.circular(22)), Paint()..color = FbColors.red);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-12, -248, 10, 380), const Radius.circular(5)), Paint()..color = Colors.white.withValues(alpha: .45));
    canvas.restore();

    final glass = Path()
      ..moveTo(-232, -456)
      ..lineTo(232, -456)
      ..lineTo(190, -46)
      ..quadraticBezierTo(186, 0, 140, 0)
      ..lineTo(-140, 0)
      ..quadraticBezierTo(-186, 0, -190, -46)
      ..close();
    // empty glass
    canvas.drawPath(glass, Paint()..color = Colors.white.withValues(alpha: .55));
    // juice level
    canvas.save();
    canvas.clipPath(glass);
    final top = -456 * fill;
    canvas.drawRect(Rect.fromLTRB(-240, top, 240, 0),
        Paint()..shader = LinearGradient(colors: [p.$1, p.$2]).createShader(const Rect.fromLTRB(-240, -456, 240, 0)));
    canvas.restore();
    canvas.drawLine(const Offset(-190, -426), const Offset(-160, -56), Paint()
      ..color = Colors.white.withValues(alpha: .5)
      ..strokeWidth = 26
      ..strokeCap = StrokeCap.round);

    if (fill > .95) {
      final dome = Path()
        ..moveTo(-250, -444)
        ..cubicTo(-262, -516, -194, -546, -152, -528)
        ..cubicTo(-140, -584, -62, -602, -20, -564)
        ..cubicTo(18, -610, 106, -600, 124, -542)
        ..cubicTo(178, -560, 258, -528, 248, -444)
        ..quadraticBezierTo(248, -422, 226, -422)
        ..lineTo(-226, -422)
        ..quadraticBezierTo(-250, -422, -250, -444)
        ..close();
      canvas.drawPath(dome, Paint()..color = p.$1);
      if (topping) _strawberry(canvas, const Offset(-42, -610), .8);
    }

    if (ribbon > 0) {
      canvas.save();
      canvas.scale(ribbon, 1);
      final dark = Paint()..color = FbColors.cocoa;
      canvas.drawPath(Path()..addPolygon(const [Offset(-336, -198), Offset(-220, -210), Offset(-220, -94), Offset(-336, -82), Offset(-298, -140)], true), dark);
      canvas.drawPath(Path()..addPolygon(const [Offset(336, -198), Offset(220, -210), Offset(220, -94), Offset(336, -82), Offset(298, -140)], true), dark);
      final band = Path()
        ..moveTo(-260, -228)
        ..quadraticBezierTo(0, -258, 260, -228)
        ..lineTo(260, -112)
        ..quadraticBezierTo(0, -142, -260, -112)
        ..close();
      canvas.drawPath(band, Paint()..color = FbColors.brown);
      final hl = Path()
        ..moveTo(-180, -178)
        ..quadraticBezierTo(0, -198, 180, -178);
      canvas.drawPath(hl, Paint()
        ..color = FbColors.cream.withValues(alpha: .9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16
        ..strokeCap = StrokeCap.round);
      canvas.restore();
    }
    canvas.restore();
  }

  void _strawberry(Canvas c, Offset at, double k) {
    c.save();
    c.translate(at.dx, at.dy);
    c.scale(k);
    final body = Path()
      ..moveTo(0, -78)
      ..cubicTo(70, -86, 118, -52, 112, 6)
      ..cubicTo(106, 70, 46, 118, 0, 132)
      ..cubicTo(-46, 118, -106, 70, -112, 6)
      ..cubicTo(-118, -52, -70, -86, 0, -78)
      ..close();
    c.drawPath(body, Paint()..color = FbColors.red);
    final seed = Paint()..color = const Color(0xFFFFE9A8);
    for (final o in const [Offset(-50, -10), Offset(-12, -22), Offset(30, -12), Offset(66, -4), Offset(-66, 30), Offset(-28, 22), Offset(12, 26), Offset(52, 32), Offset(-36, 66), Offset(4, 70), Offset(36, 72)]) {
      c.drawOval(Rect.fromCenter(center: o, width: 12, height: 18), seed);
    }
    final leaf = Paint()..color = FbColors.leaf;
    c.drawPath(Path()..addPolygon(const [Offset(0, -70), Offset(-70, -104), Offset(-34, -64), Offset(-96, -52), Offset(-24, -48)], true), leaf);
    c.drawPath(Path()..addPolygon(const [Offset(0, -70), Offset(70, -104), Offset(34, -64), Offset(96, -52), Offset(24, -48)], true), leaf);
    c.restore();
  }

  @override
  bool shouldRepaint(_DrinkPainter o) => o.fill != fill || o.ribbon != ribbon || o.p != p;
}
