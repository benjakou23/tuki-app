import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Naranja principal — identidad Tuki
  static const naranja = Color(0xFFFF6B00);
  static const naranjaOscuro = Color(0xFFCC5500);
  static const naranjaClaro = Color(0xFFFFF0E6);
  static const naranjaMedio = Color(0xFFFF8C33);

  // Amarillo acento
  static const amarillo = Color(0xFFFFB800);
  static const amarilloClaro = Color(0xFFFFF8E6);

  // Teal confianza — verificado
  static const teal = Color(0xFF00B894);
  static const tealOscuro = Color(0xFF00896F);
  static const tealClaro = Color(0xFFE6FAF6);

  // Neutros
  static const carbon = Color(0xFF1A1A18);
  static const grisOscuro = Color(0xFF444441);
  static const grisMedio = Color(0xFF888780);
  static const grisClaro = Color(0xFFD3D1C7);
  static const crema = Color(0xFFF8F6F1);
  static const cremaSuave = Color(0xFFFAF9F6);
  static const blanco = Color(0xFFFFFFFF);

  // Semánticos
  static const exito = Color(0xFF00B894);
  static const error = Color(0xFFFF6B00);

  // Aliases para compatibilidad
  static const coral = naranja;
  static const coralOscuro = naranjaOscuro;
  static const coralClaro = naranjaClaro;
  static const coralMedio = naranjaMedio;
}

class AppTextStyles {
  static TextStyle get display => GoogleFonts.poppins(
    fontSize: 36, fontWeight: FontWeight.w700,
    color: AppColors.naranja, letterSpacing: -0.5,
  );

  static TextStyle get h1 => GoogleFonts.poppins(
    fontSize: 26, fontWeight: FontWeight.w600,
    color: AppColors.carbon, letterSpacing: -0.3,
  );

  static TextStyle get h2 => GoogleFonts.poppins(
    fontSize: 20, fontWeight: FontWeight.w600,
    color: AppColors.carbon, letterSpacing: -0.2,
  );

  static TextStyle get h3 => GoogleFonts.poppins(
    fontSize: 17, fontWeight: FontWeight.w600,
    color: AppColors.carbon,
  );

  static TextStyle get h4 => GoogleFonts.poppins(
    fontSize: 15, fontWeight: FontWeight.w500,
    color: AppColors.carbon,
  );

  static TextStyle get body => GoogleFonts.poppins(
    fontSize: 14, fontWeight: FontWeight.w400,
    color: AppColors.carbon, height: 1.5,
  );

  static TextStyle get bodySmall => GoogleFonts.poppins(
    fontSize: 12, fontWeight: FontWeight.w400,
    color: AppColors.grisOscuro, height: 1.4,
  );

  static TextStyle get label => GoogleFonts.poppins(
    fontSize: 11, fontWeight: FontWeight.w500,
    color: AppColors.grisMedio, letterSpacing: 0.3,
  );

  static TextStyle get caption => GoogleFonts.poppins(
    fontSize: 10, fontWeight: FontWeight.w400,
    color: AppColors.grisMedio,
  );

  static TextStyle get boton => GoogleFonts.poppins(
    fontSize: 15, fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );

  static TextStyle get precio => GoogleFonts.poppins(
    fontSize: 20, fontWeight: FontWeight.w700,
    color: AppColors.carbon, letterSpacing: -0.3,
  );

  static TextStyle get tag => GoogleFonts.poppins(
    fontSize: 11, fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
  );
}

class AppTheme {
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.naranja,
      primary: AppColors.naranja,
      secondary: AppColors.teal,
      surface: AppColors.blanco,
      error: AppColors.error,
    ),
    scaffoldBackgroundColor: AppColors.cremaSuave,
    textTheme: GoogleFonts.poppinsTextTheme(),

    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.blanco,
      foregroundColor: AppColors.carbon,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      centerTitle: false,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 16, fontWeight: FontWeight.w600,
        color: AppColors.carbon,
      ),
      iconTheme: const IconThemeData(
        color: AppColors.carbon, size: 22),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.naranja,
        foregroundColor: AppColors.blanco,
        disabledBackgroundColor: AppColors.grisClaro,
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14)),
        elevation: 0,
        textStyle: GoogleFonts.poppins(
          fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.naranja,
        textStyle: GoogleFonts.poppins(
          fontSize: 13, fontWeight: FontWeight.w500),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.carbon,
        side: const BorderSide(color: AppColors.grisClaro, width: 1),
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14)),
        textStyle: GoogleFonts.poppins(
          fontSize: 15, fontWeight: FontWeight.w500),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.blanco,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.grisClaro),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.grisClaro),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: AppColors.naranja, width: 2),
      ),
      labelStyle: GoogleFonts.poppins(
        fontSize: 14, color: AppColors.grisMedio,
        fontWeight: FontWeight.w400),
      hintStyle: GoogleFonts.poppins(
        fontSize: 13, color: AppColors.grisClaro),
      floatingLabelStyle: GoogleFonts.poppins(
        fontSize: 11, color: AppColors.naranja,
        fontWeight: FontWeight.w500),
    ),

    cardTheme: CardThemeData(
      color: AppColors.blanco,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppColors.grisClaro.withValues(alpha: 0.6),
          width: 0.5),
      ),
      margin: EdgeInsets.zero,
    ),

    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.blanco,
      selectedItemColor: AppColors.naranja,
      unselectedItemColor: AppColors.grisMedio,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      selectedLabelStyle: GoogleFonts.poppins(
        fontSize: 10, fontWeight: FontWeight.w600),
      unselectedLabelStyle: GoogleFonts.poppins(
        fontSize: 10, fontWeight: FontWeight.w400),
    ),

    dividerTheme: const DividerThemeData(
      color: AppColors.grisClaro,
      thickness: 0.5, space: 0,
    ),

    chipTheme: ChipThemeData(
      backgroundColor: AppColors.cremaSuave,
      selectedColor: AppColors.naranjaClaro,
      labelStyle: GoogleFonts.poppins(
        fontSize: 12, fontWeight: FontWeight.w400),
      side: const BorderSide(color: AppColors.grisClaro, width: 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    ),
  );
}