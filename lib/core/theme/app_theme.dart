import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_constants.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: _buildTextTheme(Brightness.light),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.text,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.cairo(
          fontSize: AppFonts.fontSizeXLarge,
          fontWeight: AppFonts.fontWeightSemiBold,
          color: AppColors.text,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: AppConstants.cardElevation,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMd),
          side: BorderSide(color: AppColors.divider, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusMd),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: AppConstants.spacingLg,
            vertical: AppConstants.spacingMd,
          ),
          textStyle: GoogleFonts.cairo(
            fontSize: AppFonts.fontSizeMedium,
            fontWeight: AppFonts.fontWeightMedium,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.text,
          side: BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusMd),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: AppConstants.spacingLg,
            vertical: AppConstants.spacingMd,
          ),
          textStyle: GoogleFonts.cairo(
            fontSize: AppFonts.fontSizeMedium,
            fontWeight: AppFonts.fontWeightMedium,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMd),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMd),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMd),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMd),
          borderSide: BorderSide(color: AppColors.error),
        ),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppConstants.spacingMd,
          vertical: AppConstants.spacingMd,
        ),
        labelStyle: GoogleFonts.cairo(
          fontSize: AppFonts.fontSizeMedium,
          color: AppColors.textSecondary,
        ),
        hintStyle: GoogleFonts.cairo(
          fontSize: AppFonts.fontSizeMedium,
          color: AppColors.textSecondary,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 0,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusLg),
        ),
        elevation: 0,
        titleTextStyle: GoogleFonts.cairo(
          fontSize: AppFonts.fontSizeXLarge,
          fontWeight: AppFonts.fontWeightSemiBold,
          color: AppColors.text,
        ),
        contentTextStyle: GoogleFonts.cairo(
          fontSize: AppFonts.fontSizeMedium,
          color: AppColors.text,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.text,
        contentTextStyle: GoogleFonts.cairo(
          fontSize: AppFonts.fontSizeMedium,
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMd),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.cairo(
          fontSize: AppFonts.fontSizeSmall,
          fontWeight: AppFonts.fontWeightMedium,
        ),
        unselectedLabelStyle: GoogleFonts.cairo(
          fontSize: AppFonts.fontSizeSmall,
          fontWeight: AppFonts.fontWeightRegular,
        ),
      ),
    );
  }

  static TextTheme _buildTextTheme(Brightness brightness) {
    final Color textColor = AppColors.text;
    final Color secondaryTextColor = AppColors.textSecondary;

    return GoogleFonts.cairoTextTheme().copyWith(
      displayLarge: GoogleFonts.cairo(
        fontSize: AppFonts.fontSizeDisplay,
        fontWeight: AppFonts.fontWeightBold,
        color: textColor,
      ),
      displayMedium: GoogleFonts.cairo(
        fontSize: AppFonts.fontSizeXXXLarge,
        fontWeight: AppFonts.fontWeightSemiBold,
        color: textColor,
      ),
      displaySmall: GoogleFonts.cairo(
        fontSize: AppFonts.fontSizeXXLarge,
        fontWeight: AppFonts.fontWeightSemiBold,
        color: textColor,
      ),
      headlineLarge: GoogleFonts.cairo(
        fontSize: AppFonts.fontSizeXXLarge,
        fontWeight: AppFonts.fontWeightSemiBold,
        color: textColor,
      ),
      headlineMedium: GoogleFonts.cairo(
        fontSize: AppFonts.fontSizeXLarge,
        fontWeight: AppFonts.fontWeightSemiBold,
        color: textColor,
      ),
      headlineSmall: GoogleFonts.cairo(
        fontSize: AppFonts.fontSizeLarge,
        fontWeight: AppFonts.fontWeightMedium,
        color: textColor,
      ),
      titleLarge: GoogleFonts.cairo(
        fontSize: AppFonts.fontSizeLarge,
        fontWeight: AppFonts.fontWeightMedium,
        color: textColor,
      ),
      titleMedium: GoogleFonts.cairo(
        fontSize: AppFonts.fontSizeMedium,
        fontWeight: AppFonts.fontWeightMedium,
        color: textColor,
      ),
      titleSmall: GoogleFonts.cairo(
        fontSize: AppFonts.fontSizeMedium,
        fontWeight: AppFonts.fontWeightRegular,
        color: textColor,
      ),
      bodyLarge: GoogleFonts.cairo(
        fontSize: AppFonts.fontSizeLarge,
        fontWeight: AppFonts.fontWeightRegular,
        color: textColor,
      ),
      bodyMedium: GoogleFonts.cairo(
        fontSize: AppFonts.fontSizeMedium,
        fontWeight: AppFonts.fontWeightRegular,
        color: textColor,
      ),
      bodySmall: GoogleFonts.cairo(
        fontSize: AppFonts.fontSizeSmall,
        fontWeight: AppFonts.fontWeightRegular,
        color: secondaryTextColor,
      ),
      labelLarge: GoogleFonts.cairo(
        fontSize: AppFonts.fontSizeMedium,
        fontWeight: AppFonts.fontWeightMedium,
        color: textColor,
      ),
      labelMedium: GoogleFonts.cairo(
        fontSize: AppFonts.fontSizeSmall,
        fontWeight: AppFonts.fontWeightMedium,
        color: textColor,
      ),
      labelSmall: GoogleFonts.cairo(
        fontSize: AppFonts.fontSizeSmall,
        fontWeight: AppFonts.fontWeightRegular,
        color: secondaryTextColor,
      ),
    );
  }

  static TextStyle get latinTextStyle {
    return GoogleFonts.inter(
      fontSize: AppFonts.fontSizeMedium,
      fontWeight: AppFonts.fontWeightRegular,
      color: AppColors.text,
    );
  }

  static TextStyle get latinNumberStyle {
    return GoogleFonts.inter(
      fontSize: AppFonts.fontSizeMedium,
      fontWeight: AppFonts.fontWeightMedium,
      color: AppColors.text,
    );
  }
}
