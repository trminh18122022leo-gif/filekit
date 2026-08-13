import 'package:flutter/material.dart';

class FKTheme {
  // Zinc scale
  static const zinc950 = Color(0xFF09090B);
  static const zinc900 = Color(0xFF18181B);
  static const zinc800 = Color(0xFF27272A);
  static const zinc700 = Color(0xFF3F3F46);
  static const zinc600 = Color(0xFF52525B);
  static const zinc400 = Color(0xFFA1A1AA);
  static const zinc200 = Color(0xFFE4E4E7);
  static const zinc50 = Color(0xFFFAFAFA);

  // Accent
  static const emerald500 = Color(0xFF10B981);
  static const emerald400 = Color(0xFF34D399);
  static const emerald600 = Color(0xFF059669);

  // Semantic
  static const error = Color(0xFFEF4444);
  static const warning = Color(0xFFF59E0B);
  static const info = Color(0xFF3B82F6);

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: zinc950,
        colorScheme: const ColorScheme.dark(
          primary: emerald500,
          primaryContainer: Color(0xFF064E3B),
          secondary: emerald400,
          surface: zinc900,
          surfaceContainerHighest: zinc800,
          onPrimary: zinc950,
          onSurface: zinc200,
          error: error,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: zinc950,
          foregroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
        ),
        cardTheme: CardThemeData(
          color: zinc900,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: zinc800),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: emerald500,
            foregroundColor: zinc950,
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            textStyle:
                const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: zinc900,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: zinc700),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: emerald500, width: 2),
          ),
          hintStyle: const TextStyle(color: zinc600),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: zinc900,
          indicatorColor: emerald500.withValues(alpha: 0.15),
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(color: zinc400, fontSize: 12),
          ),
        ),
      );
}
