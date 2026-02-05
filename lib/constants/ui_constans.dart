// lib/constants/ui_constants.dart
import 'package:flutter/material.dart';

/// ✅ Centralized UI constants for consistent design across the app
class UIConstants {
  // --- Spacing ---
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 12.0;
  static const double spacingL = 16.0;
  static const double spacingXL = 24.0;
  static const double spacingXXL = 32.0;

  // --- Card Margins ---
  static const EdgeInsets cardMarginStandard =
      EdgeInsets.symmetric(vertical: 4, horizontal: 8);
  static const EdgeInsets cardPaddingStandard =
      EdgeInsets.symmetric(vertical: 12, horizontal: 16);

  // --- Border Radius ---
  static const double borderRadiusS = 8.0;
  static const double borderRadiusM = 12.0;
  static const double borderRadiusL = 16.0;

  // --- Colors ---
  static const Color primaryColor = Color(0xFF2196F3);
  static const Color accentColor = Color(0xFF4CAF50);

  static const Color incomeColor = Color(0xFF00897B); // Teal
  static const Color expenseColor = Color(0xFF546E7A); // Blue Grey
  static const Color savingsColor = Color(0xFF3F51B5); // Indigo
  static const Color remainingColor = Color(0xFF673AB7); // Deep Purple

  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color errorColor = Color(0xFFF44336);
  static const Color infoColor = Color(0xFF2196F3);

  // --- Text Styles ---
  static const TextStyle headingLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle headingSmall = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: Colors.grey,
  );

  // --- Icon Sizes ---
  static const double iconSizeS = 20.0;
  static const double iconSizeM = 24.0;
  static const double iconSizeL = 32.0;
  static const double iconSizeXL = 48.0;

  // --- Button Heights ---
  static const double buttonHeightStandard = 48.0;
  static const double buttonHeightLarge = 55.0;

  // --- Shadow ---
  static List<BoxShadow> standardShadow = [
    BoxShadow(
      color: Colors.black.withAlpha((0.05 * 255).round()),
      blurRadius: 10,
      offset: const Offset(0, 2),
    ),
  ];

  // --- Frequency Display ---
  static String getFrequencyLabel(String frequencyName) {
    return frequencyName[0].toUpperCase() + frequencyName.substring(1);
  }
}
