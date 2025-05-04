import "package:flutter/material.dart";

class MyColors {
  static const Color primary = Color(0xFFEF4B59);

  static const Color brown = Color(0xFF726657);
  static const Color grey = Color(0xFF474747);
  static const Color lightGrey = Color(0xFFA5A6A8);
  static const Color orange = Color(0xFFFF7700);
  static const Color mint = Color(0xFFB2FFA9);

  static MaterialColor primarySwatch = createMaterialColor(primary);

  static MaterialColor createMaterialColor(Color color) {
    final List<double> strengths = <double>[.05];
    final Map<int, Color> swatch = <int, Color>{};
    final int r = color.red;
    final int g = color.green;
    final int b = color.blue;

    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }
    strengths.forEach((double strength) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    });
    return MaterialColor(color.value, swatch);
  }
}
