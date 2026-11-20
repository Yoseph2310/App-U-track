import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Preferencias de apariencia de la app: tema (claro/oscuro) e idioma
/// (español/inglés). Se guardan en el dispositivo.
class AppSettings {
  AppSettings._();

  static const _kDarkTheme = 'app_dark_theme';
  static const _kEnglish = 'app_language_english';

  /// true si el usuario eligió el tema oscuro.
  static bool isDark = false;

  /// true si el usuario eligió inglés; false = español.
  static bool isEnglish = false;

  /// Cambia cada vez que se modifica el tema o el idioma, para que la app
  /// se vuelva a dibujar.
  static final ValueNotifier<int> changes = ValueNotifier<int>(0);

  /// Lee lo guardado. Se llama una vez al abrir la app.
  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      isDark = prefs.getBool(_kDarkTheme) ?? false;
      isEnglish = prefs.getBool(_kEnglish) ?? false;
    } catch (_) {
      // Si no se puede leer, se queda en claro y español.
    }
  }

  static Future<void> setDark(bool value) async {
    isDark = value;
    _applyChanges();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kDarkTheme, value);
    } catch (_) {}
  }

  static Future<void> setEnglish(bool value) async {
    isEnglish = value;
    _applyChanges();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kEnglish, value);
    } catch (_) {}
  }

  /// Avisa del cambio y obliga a redibujar todas las pantallas abiertas,
  /// porque los colores y textos se leen al construir cada pantalla.
  static void _applyChanges() {
    changes.value++;
    void rebuild(Element element) {
      element.markNeedsBuild();
      element.visitChildren(rebuild);
    }

    WidgetsBinding.instance.rootElement?.visitChildren(rebuild);
  }
}

/// Devuelve el texto en el idioma elegido: [es] en español, [en] en inglés.
String tr(String es, String en) => AppSettings.isEnglish ? en : es;
