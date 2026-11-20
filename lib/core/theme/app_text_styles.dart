import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  // Títulos de pantalla
  static TextStyle get headline1 => TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textMain,
    height: 1.3,
  );

  // Subtítulos / nombre de sección
  static TextStyle get headline2 => TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textMain,
    height: 1.3,
  );

  // Título de card
  static TextStyle get headline3 => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textMain,
    height: 1.4,
  );

  // Cuerpo principal
  static TextStyle get body1 => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textMain,
    height: 1.5,
  );

  // Cuerpo secundario / descripciones
  static TextStyle get body2 => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  // Labels de campos, botones pequeños
  static TextStyle get label => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.4,
    letterSpacing: 0.3,
  );

  // Texto de botón principal
  static TextStyle get button => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: Colors.white,
  );

  // Caption — fechas, metadata
  static TextStyle get caption => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.4,
  );
}