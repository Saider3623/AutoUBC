import 'package:flutter/material.dart';

abstract final class AppColors {
  static const primary = Color(0xFF1565C0);
  static const primaryDark = Color(0xFF0D47A1);
  static const page = Color(0xFFF8FAFC);
  static const surface = Colors.white;
  static const dialog = Color(0xFFF9F7FF);
  static const ink = Color(0xFF18202B);
  static const muted = Color(0xFF68717E);
  static const line = Color(0xFFCBD2DC);
  static const fieldBorder = Color(0xFF7E8794);
  static const success = Color(0xFF2E7D32);
  static const warning = Color(0xFFB56A00);
  static const error = Color(0xFFB3261E);
}

abstract final class AppSpacing {
  static const page = 16.0;
  static const field = 16.0;
  static const group = 24.0;
  static const dialogInsetHorizontal = 16.0;
  static const dialogInsetVertical = 24.0;
}

abstract final class AppRadii {
  static const field = 12.0;
  static const button = 12.0;
  static const card = 16.0;
  static const dialog = 28.0;
}

abstract final class AppElevation {
  static const resting = 1.0;
  static const dialog = 12.0;
  static const floating = 8.0;
}

abstract final class AppSizes {
  static const minimumInteractiveDimension = 48.0;
}

abstract final class AppTheme {
  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primaryDark,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      surface: AppColors.page,
      onSurface: AppColors.ink,
      outline: AppColors.line,
      error: AppColors.error,
      onError: Colors.white,
    );

    final textTheme = ThemeData.light().textTheme.apply(
          bodyColor: AppColors.ink,
          displayColor: AppColors.ink,
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.page,
      textTheme: textTheme.copyWith(
        titleLarge: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: -0.1,
        ),
        titleMedium: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: textTheme.bodyLarge?.copyWith(
          color: AppColors.ink,
        ),
        bodyMedium: textTheme.bodyMedium?.copyWith(
          color: AppColors.ink,
        ),
        bodySmall: textTheme.bodySmall?.copyWith(
          color: AppColors.muted,
        ),
        labelLarge: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 21,
          fontWeight: FontWeight.w500,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: AppElevation.resting,
        shadowColor: Colors.black12,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
          side: const BorderSide(color: Color(0xFFE6E9EF)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.dialog,
        surfaceTintColor: Colors.transparent,
        elevation: AppElevation.dialog,
        insetPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.dialogInsetHorizontal,
          vertical: AppSpacing.dialogInsetVertical,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.dialog),
        ),
        titleTextStyle: textTheme.headlineSmall?.copyWith(
          color: AppColors.ink,
          fontSize: 28,
          fontWeight: FontWeight.w500,
          height: 1.15,
          letterSpacing: -0.4,
        ),
        contentTextStyle: textTheme.bodyLarge?.copyWith(
          color: AppColors.ink,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: false,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        labelStyle: const TextStyle(
          color: AppColors.muted,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: const TextStyle(
          color: AppColors.muted,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        helperStyle: const TextStyle(
          color: AppColors.muted,
          fontSize: 12,
          height: 1.35,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.field),
          borderSide: const BorderSide(color: AppColors.fieldBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.field),
          borderSide: const BorderSide(color: AppColors.fieldBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.field),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.field),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.field),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(0, AppSizes.minimumInteractiveDimension),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.button),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, AppSizes.minimumInteractiveDimension),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.button),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(0, AppSizes.minimumInteractiveDimension),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          side: const BorderSide(color: AppColors.line),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.button),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(0, AppSizes.minimumInteractiveDimension),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.button),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize:
              const Size.square(AppSizes.minimumInteractiveDimension),
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.line,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
