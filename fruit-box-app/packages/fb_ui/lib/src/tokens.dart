import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';

/// Colours extracted from the approved Fruit Box logo (see docs/01-brand-and-tokens.md).
abstract final class FbColors {
  static const brown = Color(0xFF8A3D1F);
  static const cocoa = Color(0xFF602713);
  static const mint = Color(0xFF71BCA8);
  static const mintDeep = Color(0xFF4E9C87);
  static const red = Color(0xFFC1232C);
  static const pink = Color(0xFFF39A99);
  static const yellow = Color(0xFFFCD82F);
  static const leaf = Color(0xFF5F973E);
  static const cream = Color(0xFFFDF8F3);
  static const oat = Color(0xFFF4EADF);
  static const ink = Color(0xFF2B1A12);
  static const mintTint = Color(0xFFE3F2EE);
  static const blushTint = Color(0xFFFDE9E6);
  static const line = Color(0xFFEADCCB);
  static const muted = Color(0xFF8C7466);
  // dark mode
  static const night = Color(0xFF1E1410);
  static const nightSurface = Color(0xFF2A1C15);
  static const nightLine = Color(0xFF3D2A20);
}

abstract final class FbSpace {
  static const x1 = 4.0, x2 = 8.0, x3 = 12.0, x4 = 16.0, x5 = 20.0, x6 = 24.0, x8 = 32.0, x10 = 40.0, x14 = 56.0, x18 = 72.0;
}

abstract final class FbRadius {
  static const field = 8.0, icon = 14.0, card = 22.0, sheet = 32.0, pill = 999.0;
  static const cardAll = BorderRadius.all(Radius.circular(card));
}

/// Motion tokens — see docs/04-motion.md.
abstract final class FbDurations {
  static const instant = Duration(milliseconds: 90);
  static const quick = Duration(milliseconds: 160);
  static const base = Duration(milliseconds: 240);
  static const smooth = Duration(milliseconds: 360);
  static const hero = Duration(milliseconds: 520);
  static const confirm = Duration(milliseconds: 900);
  static const intro = Duration(milliseconds: 1400);
  static const reduced = Duration(milliseconds: 120);
}

abstract final class FbCurves {
  /// Pours in, then settles.
  static const pour = Cubic(0.2, 0.9, 0.1, 1);
  /// A soft squeeze with a small overshoot.
  static const squeeze = Cubic(0.34, 1.56, 0.64, 1);
  static const settle = Curves.easeOutCubic;
}

/// Drink illustration palettes per category (brand illustration only — not product photos).
abstract final class FbDrinkPalettes {
  static const strawberry = (Color(0xFFF7B3AE), Color(0xFFD9606A));
  static const mango = (Color(0xFFFFD37A), Color(0xFFF08A24));
  static const green = (Color(0xFFC9E68A), Color(0xFF7DB547));
  static const berry = (Color(0xFFC7A3D9), Color(0xFF7B4FA0));
  static const citrus = (Color(0xFFFFE680), Color(0xFFF4A340));
  static const mint = (Color(0xFFD8F0E6), Color(0xFF8CCBB5));
  static const cocoa = (Color(0xFFE2B99A), Color(0xFF8A3D1F));
  static const all = [strawberry, mango, green, berry, citrus, mint, cocoa];

  static (Color, Color) forKey(String key) => all[key.hashCode.abs() % all.length];
}
