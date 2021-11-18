import 'package:flutter/material.dart';

class MyColors {
  static const primary = Color(0xFFEF4B59);

  static const brown = Color(0xFF726657);
  static const grey = Color(0xFF474747);
  static const lightGrey = Color(0xFFA5A6A8);
  static const orange = Color(0xFFFF7700);
  static const mint = Color(0xFFB2FFA9);

  static MaterialColor primarySwatch = createMaterialColor(primary);

  static MaterialColor createMaterialColor(Color color) {
    final strengths = <double>[.05];
    final swatch = <int, Color>{};
    final int r = color.red, g = color.green, b = color.blue;

    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }
    strengths.forEach((strength) {
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
