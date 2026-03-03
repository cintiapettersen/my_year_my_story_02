import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData get lightTheme => ThemeData(
  useMaterial3: false,
  brightness: Brightness.light,

  scaffoldBackgroundColor: Colors.white,
  canvasColor: Colors.white,

  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white,
    foregroundColor: Colors.black,
    elevation: 0,
  ),

  textTheme: GoogleFonts.interTextTheme().apply(
    bodyColor: Colors.black,
    displayColor: Colors.black,
  ), dialogTheme: DialogThemeData(backgroundColor: Colors.white),
);
