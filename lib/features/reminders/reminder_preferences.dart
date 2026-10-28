import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../tasks/models/task_model.dart';

/// Preferencias de recordatorios del usuario (pantalla 9 — Configuración).
///
/// Se guardan en el dispositivo con shared_preferences porque las
/// notificaciones locales también son propias de cada dispositivo.
class ReminderPreferences {
  /// Interruptor general: si está apagado no se programa ningún aviso.
  final bool enabled;

  /// Anticipación por defecto para las actividades nuevas.
  final ReminderTiming anticipation;

  /// Hora del día a la que suena el recordatorio.
  final TimeOfDay hour;

  const ReminderPreferences({
    required this.enabled,
    required this.anticipation,
    required this.hour,
  });

  static const ReminderPreferences defaults = ReminderPreferences(
    enabled: false,
    anticipation: ReminderTiming.unDia,
    hour: TimeOfDay(hour: 8, minute: 0),
  );

  static const _kEnabled = 'reminders_enabled';
  static const _kAnticipation = 'reminders_anticipation';
  static const _kMinutes = 'reminders_minutes_of_day';

  static Future<ReminderPreferences> load() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final anticipationName = sp.getString(_kAnticipation);
      final minutes = sp.getInt(_kMinutes);

      return ReminderPreferences(
        enabled: sp.getBool(_kEnabled) ?? defaults.enabled,
        anticipation: ReminderTiming.values.firstWhere(
          (t) => t.name == anticipationName,
          orElse: () => defaults.anticipation,
        ),
        hour: minutes == null
            ? defaults.hour
            : TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
      );
    } catch (_) {
      return defaults;
    }
  }

  Future<void> save() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kEnabled, enabled);
    await sp.setString(_kAnticipation, anticipation.name);
    await sp.setInt(_kMinutes, hour.hour * 60 + hour.minute);
  }
}
