import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_u_track/core/settings/app_settings.dart';
import 'package:app_u_track/core/utils/decimal_input.dart';
import 'package:app_u_track/core/utils/due_date.dart';
import 'package:app_u_track/core/utils/user_name.dart';
import 'package:app_u_track/features/tasks/models/grade_model.dart';
import 'package:app_u_track/features/tasks/services/grade_service.dart';

/// Crea una nota de prueba.
GradeModel nota(String name, double? score, double weight, {String? cut}) {
  return GradeModel(
    subjectId: 'materia',
    name: name,
    score: score,
    weight: weight,
    dateAdded: DateTime(2026, 1, 1),
    cutName: cut,
  );
}

/// Simula escribir tecla por tecla en un campo de nota ('<' = borrar).
String escribir(List<String> teclas) {
  var value = TextEditingValue.empty;
  for (final tecla in teclas) {
    final next = tecla == '<'
        ? TextEditingValue(text: value.text.substring(0, value.text.length - 1))
        : TextEditingValue(text: value.text + tecla);
    value = DecimalInput.gradeFormatter.formatEditUpdate(value, next);
  }
  return value.text;
}

void main() {
  group('Cálculo de la nota acumulada sin cortes', () {
    test('sin notas da 0', () {
      expect(GradeService.weightedGrade([], null), 0);
    });

    test('suma nota × porcentaje / 100', () {
      final grades = [nota('Parcial', 4.0, 30), nota('Taller', 3.0, 20)];
      // 4.0×30 + 3.0×20 = 180 → 1.8
      expect(GradeService.weightedGrade(grades, null), closeTo(1.8, 1e-9));
    });

    test('100% evaluado con nota perfecta da 5', () {
      final grades = [nota('A', 5, 50), nota('B', 5, 50)];
      expect(GradeService.weightedGrade(grades, []), closeTo(5, 1e-9));
    });

    test('las actividades sin nota (pendientes) no suman', () {
      final grades = [nota('Parcial', 4.0, 30), nota('Final', null, 40)];
      expect(GradeService.weightedGrade(grades, null), closeTo(1.2, 1e-9));
    });
  });

  group('Cálculo de la nota acumulada con cortes', () {
    final esquema = [
      {'name': 'Corte 1', 'percentage': 30},
      {'name': 'Corte 2', 'percentage': 30},
      {'name': 'Corte 3', 'percentage': 40},
    ];

    test('promedia las actividades de cada corte', () {
      final grades = [
        nota('Quiz', 4.0, 100, cut: 'Corte 1'),
        nota('Parcial', 3.0, 100, cut: 'Corte 1'),
        nota('Parcial', 5.0, 100, cut: 'Corte 2'),
      ];
      // Corte 1: promedio 3.5 × 30% = 1.05; Corte 2: 5 × 30% = 1.5
      expect(GradeService.weightedGrade(grades, esquema),
          closeTo(2.55, 1e-9));
    });

    test('un corte sin notas no suma', () {
      final grades = [nota('Parcial', 4.0, 100, cut: 'Corte 3')];
      expect(GradeService.weightedGrade(grades, esquema), closeTo(1.6, 1e-9));
    });

    test('las actividades pendientes no bajan el promedio del corte', () {
      final grades = [
        nota('Quiz', 4.0, 100, cut: 'Corte 1'),
        nota('Taller', null, 100, cut: 'Corte 1'),
      ];
      expect(GradeService.weightedGrade(grades, esquema), closeTo(1.2, 1e-9));
    });

    test('notas antiguas sin corte se asocian por nombre', () {
      final grades = [nota('Corte 2', 4.0, 100)];
      expect(GradeService.weightedGrade(grades, esquema), closeTo(1.2, 1e-9));
    });
  });

  group('Campos numéricos', () {
    test('acepta punto o coma como separador decimal', () {
      expect(DecimalInput.parse('4.25'), 4.25);
      expect(DecimalInput.parse('4,25'), 4.25);
      expect(DecimalInput.parse(''), isNull);
      expect(DecimalInput.parse('abc'), isNull);
    });

    test('no deja escribir letras en porcentajes', () {
      const old = TextEditingValue(text: '30');
      const conLetra = TextEditingValue(text: '30a');
      expect(DecimalInput.formatter.formatEditUpdate(old, conLetra).text, '30');
    });

    test('la nota pone el punto automático y permite 3 decimales', () {
      expect(escribir(['4']), '4.');
      expect(escribir(['4', '2', '5']), '4.25');
      expect(escribir(['4', '2', '5', '7', '9']), '4.257');
      expect(escribir(['4', 'a']), '4.');
      expect(escribir(['4', '<']), '4');
      expect(escribir(['4', '<', '<']), '');
    });
  });

  group('Fechas de entrega', () {
    test('cuenta los días sin importar la hora', () {
      final now = DateTime.now();
      final hoyTarde = DateTime(now.year, now.month, now.day, 23, 59);
      final manana = DateTime(now.year, now.month, now.day + 1, 0, 1);
      expect(DueDate.daysUntil(hoyTarde), 0);
      expect(DueDate.daysUntil(manana), 1);
    });

    test('muestra la etiqueta en el idioma elegido', () {
      final now = DateTime.now();
      AppSettings.isEnglish = false;
      expect(DueDate.shortLabel(now), 'Hoy');
      AppSettings.isEnglish = true;
      expect(DueDate.shortLabel(now), 'Today');
      AppSettings.isEnglish = false;
    });
  });

  group('Nombre a partir del correo', () {
    test('toma la primera palabra, sin números y con mayúscula', () {
      expect(UserName.fromEmailAddress('esteban.t_99@gmail.com'), 'Esteban');
      expect(UserName.fromEmailAddress('MARIA-lopez@uan.edu.co'), 'Maria');
      expect(UserName.fromEmailAddress('juan23@gmail.com'), 'Juan');
    });

    test('si no queda nombre, devuelve null', () {
      expect(UserName.fromEmailAddress('12345@gmail.com'), isNull);
      expect(UserName.fromEmailAddress(null), isNull);
      expect(UserName.fromEmailAddress('sin-arroba'), isNull);
    });
  });
}
