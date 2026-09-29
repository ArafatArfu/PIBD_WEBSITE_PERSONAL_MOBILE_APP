import 'package:flutter/material.dart';

class PibdTheme {
  static const paper = Color(0xffFBFAF7);
  static const page = Color(0xffEFEDE6);
  static const ink = Color(0xff111111);
  static const blue = Color(0xff2952FF);
  static const blueSoft = Color(0xffE3E9FF);
  static const yellow = Color(0xffF5D90A);
  static const yellowSoft = Color(0xffFCF6C6);
  static const coral = Color(0xffff4b4b);
  static const coralSoft = Color(0xffffe2e0);
  static const green = Color(0xff00B87A);
  static const greenSoft = Color(0xffD6F7EA);
  static const muted = Color(0xff6B6B6B);

  static ThemeData theme() {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: blue,
          brightness: Brightness.light,
        ).copyWith(
          primary: blue,
          onPrimary: Colors.white,
          surface: paper,
          onSurface: ink,
          outline: ink,
        );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: page,
      fontFamily: 'Sora',
      appBarTheme: const AppBarTheme(
        backgroundColor: blueSoft,
        foregroundColor: ink,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: ink,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: ink, width: 2),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: ink, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: ink, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: blue, width: 2),
        ),
      ),
    );
  }
}
