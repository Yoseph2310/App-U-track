import 'package:flutter/material.dart';

import '../settings/app_settings.dart';

/// Colores de la app. Cada color tiene su versión clara y oscura; se usa
/// la que corresponde al tema elegido en Configuración.
class AppColors {
  AppColors._();

  static bool get _dark => AppSettings.isDark;

  // Fondo de página
  static Color get background =>
      _dark ? const Color(0xFF1C1C1A) : const Color(0xFFF1EFE8);

  // Primario — Teal
  static Color get primary =>
      _dark ? const Color(0xFF1D9E75) : const Color(0xFF0F6E56);
  static Color get primaryLight =>
      _dark ? const Color(0xFF103D32) : const Color(0xFFE1F5EE);
  static Color get primaryDark =>
      _dark ? const Color(0xFF9FE1CB) : const Color(0xFF085041);

  // Secundario — Azul
  static Color get secondary =>
      _dark ? const Color(0xFF5BA3E8) : const Color(0xFF185FA5);
  static Color get secondaryLight =>
      _dark ? const Color(0xFF12304D) : const Color(0xFFE6F1FB);
  static Color get secondaryDark =>
      _dark ? const Color(0xFFB5D4F4) : const Color(0xFF0C447C);

  // Estado "al día / aprobado"
  static Color get okBg =>
      _dark ? const Color(0xFF23361A) : const Color(0xFFEAF3DE);
  static Color get okText =>
      _dark ? const Color(0xFFB5D98A) : const Color(0xFF27500A);

  // Estado "por vencer / atención"
  static Color get warnBg =>
      _dark ? const Color(0xFF402D0E) : const Color(0xFFFAEEDA);
  static Color get warnText =>
      _dark ? const Color(0xFFF2C46D) : const Color(0xFF854F0B);

  // Estado "vencido / en riesgo"
  static Color get errorBg =>
      _dark ? const Color(0xFF431B1B) : const Color(0xFFFCEBEB);
  static Color get errorText =>
      _dark ? const Color(0xFFF09595) : const Color(0xFFA32D2D);

  // Texto
  static Color get textMain =>
      _dark ? const Color(0xFFF1EFE8) : const Color(0xFF2C2C2A);
  static Color get textSecondary =>
      _dark ? const Color(0xFFB4B2A9) : const Color(0xFF5F5E5A);

  // Bordes / divisores
  static Color get border =>
      _dark ? const Color(0xFF48473F) : const Color(0xFFD3D1C7);

  // Superficie de tarjeta
  static Color get surface =>
      _dark ? const Color(0xFF2A2A27) : const Color(0xFFFFFFFF);
}
