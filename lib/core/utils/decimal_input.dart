import 'package:flutter/services.dart';

/// Utilidades para campos que solo aceptan números decimales
/// (notas, porcentajes). Evita que el usuario escriba letras.
class DecimalInput {
  DecimalInput._();

  static final _pattern = RegExp(r'^\d{0,3}([.,]\d{0,3})?$');

  /// Solo deja escribir dígitos y un separador decimal (punto o coma),
  /// con máximo 3 enteros y 3 decimales. Si la tecla no es válida,
  /// el texto no cambia.
  static final TextInputFormatter formatter =
      TextInputFormatter.withFunction((oldValue, newValue) {
    return _pattern.hasMatch(newValue.text) ? newValue : oldValue;
  });

  /// Lista lista para usar en `inputFormatters:`.
  static List<TextInputFormatter> get formatters => [formatter];

  /// Convierte el texto a número aceptando coma o punto. Devuelve null si
  /// está vacío o no es un número.
  static double? parse(String text) =>
      double.tryParse(text.trim().replaceAll(',', '.'));

  /// Para notas de 0 a 5: pone el punto automáticamente después del primer
  /// dígito (4 → "4.", 425 → "4.25"). Permite hasta 3 decimales.
  /// Al borrar, el punto se quita solo para no quedar "atascado".
  static final TextInputFormatter gradeFormatter =
      TextInputFormatter.withFunction((oldValue, newValue) {
    var digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > 4) digits = digits.substring(0, 4);

    final isDeleting = newValue.text.length < oldValue.text.length;
    String text;
    if (digits.isEmpty) {
      text = '';
    } else if (digits.length == 1) {
      text = isDeleting ? digits : '$digits.';
    } else {
      text = '${digits[0]}.${digits.substring(1)}';
    }

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  });

  /// Lista lista para usar en `inputFormatters:` de un campo de nota.
  static List<TextInputFormatter> get gradeFormatters => [gradeFormatter];
}
