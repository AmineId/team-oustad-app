import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  // Headers — Barlow Condensed, sport/gym feel
  static TextStyle get h1 => GoogleFonts.barlowCondensed(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static TextStyle get h2 => GoogleFonts.barlowCondensed(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static TextStyle get h3 => GoogleFonts.barlowCondensed(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.3,
    height: 1.3,
  );

  static TextStyle get h4 => GoogleFonts.barlowCondensed(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    height: 1.3,
  );

  static TextStyle get h5 => GoogleFonts.barlowCondensed(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    height: 1.4,
  );

  static TextStyle get h6 => GoogleFonts.barlowCondensed(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  // Body text — Barlow, readable and modern
  static TextStyle get body1 => GoogleFonts.barlow(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );

  static TextStyle get body2 => GoogleFonts.barlow(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );

  static TextStyle get caption => GoogleFonts.barlow(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    height: 1.4,
  );

  // Button
  static TextStyle get button => GoogleFonts.barlow(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );

  // Overline (labels)
  static TextStyle get overline => GoogleFonts.barlow(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.0,
    height: 1.3,
  );
}
