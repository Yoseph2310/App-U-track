import 'package:firebase_auth/firebase_auth.dart';

import '../settings/app_settings.dart';

/// Nombre que se muestra del usuario en la app.
class UserName {
  UserName._();

  /// Nombre completo, en este orden:
  /// 1. el nombre de la cuenta (el que se pone al registrarse o en Editar cuenta),
  /// 2. el nombre de la cuenta de Google,
  /// 3. la parte del correo antes de la @ (por ejemplo "esteban.t@..." → "Esteban"),
  /// 4. "Estudiante".
  static String full(User? user) {
    final own = user?.displayName?.trim();
    if (own != null && own.isNotEmpty) return own;

    for (final info in user?.providerData ?? const <UserInfo>[]) {
      final name = info.displayName?.trim();
      if (name != null && name.isNotEmpty) return name;
    }

    final fromEmail = fromEmailAddress(user?.email);
    if (fromEmail != null) return fromEmail;

    return tr('Estudiante', 'Student');
  }

  /// Primer nombre (para el saludo).
  static String first(User? user) => full(user).split(' ').first;

  /// Inicial para el círculo del perfil.
  static String initial(User? user) {
    final name = full(user);
    return name.isEmpty ? 'U' : name[0].toUpperCase();
  }

  /// Saca un nombre del correo: toma lo que está antes de la @, se queda con
  /// la primera palabra (separadas por punto, guion o guion bajo), le quita
  /// los números y pone la primera letra en mayúscula.
  /// "esteban.t_99@gmail.com" → "Esteban". Devuelve null si no queda nada.
  static String? fromEmailAddress(String? email) {
    if (email == null || !email.contains('@')) return null;
    final local = email.split('@').first;
    final firstWord = local.split(RegExp(r'[._\-+]')).first;
    final letters = firstWord.replaceAll(RegExp(r'[0-9]'), '');
    if (letters.isEmpty) return null;
    return letters[0].toUpperCase() + letters.substring(1).toLowerCase();
  }
}
