import 'package:flutter/material.dart';

class TideTheme {
  static Color getColorForLevel(double value) {
    if (value >= 140) {
      return const Color(0xFFD32F2F); // Red - Exceptional
    } else if (value >= 110) {
      return const Color(0xFFF57C00); // Orange - Very High
    } else if (value >= 80) {
      return const Color(0xFFFBC02D); // Yellow - Sustained
    } else {
      return const Color(0xFF00ACC1); // Cyan/Blue - Normal
    }
  }
  
  static Color getBackgroundColorForLevel(double value) {
     if (value >= 140) {
      return const Color(0xFFFFEBEE); // Light Red
    } else if (value >= 110) {
      return const Color(0xFFFFF3E0); // Light Orange
    } else if (value >= 80) {
      return const Color(0xFFFFF9C4); // Light Yellow
    } else {
      return const Color(0xFFE0F7FA); // Light Cyan
    }
  }

  static String getStatusText(double value) {
    if (value >= 140) {
      return 'MAREA ECCEZIONALE';
    } else if (value >= 110) {
      return 'MAREA MOLTO SOSTENUTA';
    } else if (value >= 80) {
      return 'MAREA SOSTENUTA';
    } else {
      return 'MAREA NORMALE';
    }
  }
}
