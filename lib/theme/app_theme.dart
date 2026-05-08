import 'package:flutter/material.dart';

class AppTheme {
  // Kleuren
  static const bg = Color(0xFFF7F5F0);
  static const bgCard = Colors.white;
  static const green = Color(0xFF2D6A4F);
  static const greenLight = Color(0xFF52B788);
  static const greenPale = Color(0xFFE8F5E9);
  static const textDark = Color(0xFF1A1A1A);
  static const textMid = Color(0xFF6B6560);
  static const textLight = Color(0xFF9E9890);
  static const border = Color(0xFFE0DBD1);
  static const borderDark = Color(0xFFD4CFC4);
  static const amber = Color(0xFFF4A261);
  static const red = Color(0xFFE63946);
  static const redPale = Color(0xFFFFEBEE);

  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: bg,
    colorScheme: ColorScheme.fromSeed(seedColor: green, background: bg),
    appBarTheme: const AppBarTheme(
      backgroundColor: bg,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: textDark,
        fontWeight: FontWeight.w700,
        fontSize: 18,
      ),
      iconTheme: IconThemeData(color: textDark),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: green,
      unselectedItemColor: textLight,
      elevation: 0,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
      unselectedLabelStyle: TextStyle(fontSize: 11),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: bgCard,
      selectedColor: green,
      labelStyle: const TextStyle(fontSize: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: border),
      ),
    ),
  );

  // Herbruikbare decoraties
  static BoxDecoration cardDecoration({double radius = 16}) => BoxDecoration(
    color: bgCard,
    borderRadius: BorderRadius.circular(radius),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 10,
        offset: const Offset(0, 3),
      ),
    ],
  );

  static InputDecoration inputDecoration(
    String hint, {
    IconData? icon,
  }) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: textLight, fontSize: 14),
    filled: true,
    fillColor: bgCard,
    prefixIcon: icon != null ? Icon(icon, color: greenLight, size: 20) : null,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: green, width: 2),
    ),
  );
}
