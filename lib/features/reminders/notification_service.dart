import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;

import '../tasks/models/task_model.dart';
import '../tasks/services/task_service.dart';
import 'reminder_preferences.dart';

/// Resultado de intentar programar el recordatorio de una actividad.
enum ReminderResult {
  scheduled, // quedó programado
  notRequested, // la actividad no tiene recordatorio activado
  disabledInSettings, // "Notificaciones activas" está apagado en Configuración
  permissionDenied, // el sistema no tiene el permiso de notificaciones
  timePassed, // la fecha/hora del aviso ya pasó
  error, // falló algo inesperado
}

/// Programa y cancela los recordatorios como notificaciones locales.
///
/// Regla: el aviso suena [anticipación de la actividad] antes de la fecha
/// límite, a la hora que el usuario eligió en Configuración.
/// Ejemplo: entrega el 20/11, "3 días antes", hora 8:00 AM → suena el
/// 17/11 a las 8:00 AM.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  StreamSubscription<User?>? _authSub;

  static const AndroidNotificationDetails _androidDetails =
      AndroidNotificationDetails(
    'u_track_reminders',
    'Recordatorios',
    channelDescription: 'Avisos de tareas, talleres y exámenes próximos',
    importance: Importance.high,
    priority: Priority.high,
  );

  /// Llamar una vez al arrancar la app (después de Firebase.initializeApp).
  ///
  /// Además deja un listener de sesión: al iniciar sesión (o abrir la app con
  /// sesión activa) reprograma los avisos del usuario, y al cerrar sesión los
  /// borra para que no le lleguen a otra persona en el mismo celular.
  Future<void> init() async {
    try {
      await _ensureInitialized();
      _authSub ??= FirebaseAuth.instance.authStateChanges().listen((user) {
        if (user == null) {
          cancelAll();
        } else {
          rescheduleAll(user.uid);
        }
      });
    } catch (e) {
      // Los recordatorios nunca deben impedir que la app abra.
      debugPrint('No se pudo iniciar el servicio de notificaciones: $e');
    }
  }

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    const settings = InitializationSettings(
      // Ícono blanco y simple (res/drawable-*/ic_stat_u_track.png): la barra de
      // estado solo pinta la silueta, un ícono a todo color se vería como un cuadro.
      android: AndroidInitializationSettings('@drawable/ic_stat_u_track'),
      iOS: DarwinInitializationSettings(),
    );
    await _plugin.initialize(settings: settings);
    _initialized = true;
  }

  /// Id numérico estable (FNV-1a de 32 bits) a partir del id de Firestore,
  /// porque las notificaciones piden un entero y el id de la tarea es texto.
  int notificationId(String taskId) {
    var hash = 0x811C9DC5;
    for (final unit in taskId.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash & 0x7FFFFFFF;
  }

  static int _daysBefore(ReminderTiming timing) {
    switch (timing) {
      case ReminderTiming.unDia:
        return 1;
      case ReminderTiming.tresDias:
        return 3;
      case ReminderTiming.unaSemana:
        return 7;
    }
  }

  /// Momento exacto en que debe sonar el aviso de [task].
  DateTime reminderDateTime(TaskModel task, ReminderPreferences prefs) {
    final days = _daysBefore(task.reminderTiming ?? prefs.anticipation);
    final d = task.dueDate;
    // El constructor de DateTime normaliza días negativos (mes anterior).
    return DateTime(
      d.year,
      d.month,
      d.day - days,
      prefs.hour.hour,
      prefs.hour.minute,
    );
  }

  /// Programa (o reprograma) el recordatorio de [task]. Siempre borra primero
  /// el aviso anterior de esa actividad, así que sirve para crear y editar.
  Future<ReminderResult> scheduleTaskReminder(TaskModel task) async {
    final taskId = task.id;
    if (taskId == null) return ReminderResult.notRequested;

    try {
      await _ensureInitialized();
      final notifId = notificationId(taskId);
      await _plugin.cancel(id: notifId);

      if (!task.reminderEnabled || task.isCompleted) {
        return ReminderResult.notRequested;
      }

      final prefs = await ReminderPreferences.load();
      if (!prefs.enabled) return ReminderResult.disabledInSettings;
      if (!await Permission.notification.isGranted) {
        return ReminderResult.permissionDenied;
      }

      final when = reminderDateTime(task, prefs);
      if (!when.isAfter(DateTime.now())) return ReminderResult.timePassed;

      await _plugin.zonedSchedule(
        id: notifId,
        title: task.title,
        body: _body(task),
        // Es un aviso de una sola vez, así que lo que importa es el instante
        // exacto; por eso basta con expresarlo en UTC (no hace falta cargar la
        // base de zonas horarias ni saber la zona del teléfono).
        scheduledDate: tz.TZDateTime.from(when, tz.UTC),
        notificationDetails: const NotificationDetails(
          android: _androidDetails,
          iOS: DarwinNotificationDetails(),
        ),
        // "inexact" evita pedir el permiso especial de alarmas exactas
        // (Android 12+); el aviso puede variar unos minutos, es suficiente.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: taskId,
      );
      return ReminderResult.scheduled;
    } catch (e) {
      debugPrint('Error programando recordatorio: $e');
      return ReminderResult.error;
    }
  }

  /// Cancela el aviso de una actividad (usar al borrarla o completarla).
  Future<void> cancelTaskReminder(String taskId) async {
    try {
      await _ensureInitialized();
      await _plugin.cancel(id: notificationId(taskId));
    } catch (e) {
      debugPrint('Error cancelando recordatorio: $e');
    }
  }

  Future<void> cancelAll() async {
    try {
      await _ensureInitialized();
      await _plugin.cancelAll();
    } catch (e) {
      debugPrint('Error cancelando recordatorios: $e');
    }
  }

  /// Borra todos los avisos y vuelve a programar los de las actividades
  /// pendientes del usuario. Se usa al iniciar sesión y cuando cambian los
  /// ajustes (interruptor general u hora del recordatorio).
  Future<void> rescheduleAll(String userId) async {
    try {
      await _ensureInitialized();
      await _plugin.cancelAll();

      final prefs = await ReminderPreferences.load();
      if (!prefs.enabled) return;

      final tasks = await TaskService().getTasks(userId);
      for (final task in tasks) {
        if (task.reminderEnabled && !task.isCompleted) {
          await scheduleTaskReminder(task);
        }
      }
    } catch (e) {
      debugPrint('Error reprogramando recordatorios: $e');
    }
  }

  String _body(TaskModel task) {
    final date = '${task.dueDate.day}/${task.dueDate.month}/${task.dueDate.year}';
    final time = task.dueTime != null ? ' a las ${_formatTime12h(task.dueTime!)}' : '';
    return '${task.activityType.label} de ${task.subjectName} · vence el $date$time';
  }

  String _formatTime12h(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
}
