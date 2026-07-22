import 'package:flutter/material.dart';

class ColorHelper {
  static Color fromHex(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse(hexColor, radix: 16));
  }
  
  static String toHex(Color color) {
    return color.value.toRadixString(16).substring(2).toUpperCase();
  }
  
  static List<Color> getCategoryColors() {
    return [
      const Color(0xFFFF6B6B),
      const Color(0xFF4ECDC4),
      const Color(0xFFFFE66D),
      const Color(0xFFA8E6CF),
      const Color(0xFFFF8B94),
      const Color(0xFFC7CEEA),
      const Color(0xFFB5EAD7),
      const Color(0xFF4CAF50),
      const Color(0xFFFF9800),
      const Color(0xFF9C27B0),
    ];
  }
}