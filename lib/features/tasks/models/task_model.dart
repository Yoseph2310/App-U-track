import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Tipo de actividad académica, según especificación de UI pantalla 7
enum ActivityType { tarea, taller, examen }

extension ActivityTypeLabel on ActivityType {
  String get label {
    switch (this) {
      case ActivityType.tarea:
        return 'Tarea';
      case ActivityType.taller:
        return 'Taller';
      case ActivityType.examen:
        return 'Examen';
    }
  }

  static ActivityType fromLabel(String label) {
    switch (label) {
      case 'Taller':
        return ActivityType.taller;
      case 'Examen':
        return ActivityType.examen;
      default:
        return ActivityType.tarea;
    }
  }
}

/// Opciones de anticipación para el recordatorio
enum ReminderTiming { unDia, tresDias, unaSemana }

extension ReminderTimingLabel on ReminderTiming {
  String get label {
    switch (this) {
      case ReminderTiming.unDia:
        return '1 día antes';
      case ReminderTiming.tresDias:
        return '3 días antes';
      case ReminderTiming.unaSemana:
        return '1 semana antes';
    }
  }

  static ReminderTiming fromLabel(String label) {
    switch (label) {
      case '3 días antes':
        return ReminderTiming.tresDias;
      case '1 semana antes':
        return ReminderTiming.unaSemana;
      default:
        return ReminderTiming.unDia;
    }
  }
}

/// Modelo de Tarea para la base de datos Firestore
///
/// Esta clase representa una actividad académica (tarea, taller o examen)
/// que el estudiante necesita completar.
class TaskModel {
  final String? id;                    // ID del documento en Firestore
  final String title;                  // Ej. "Resolver ejercicios 1-10"
  final String? description;           // Notas adicionales (opcional)
  final String subjectId;              // ID de la materia (referencia)
  final String subjectName;            // Nombre de la materia para mostrar
  final ActivityType activityType;     // Tarea, Taller o Examen
  final DateTime dueDate;              // Fecha límite
  final TimeOfDay? dueTime;            // Hora (opcional)
  final bool reminderEnabled;          // Si tiene recordatorio activo
  final ReminderTiming? reminderTiming;// Con cuánta anticipación avisar
  final bool isCompleted;              // Si está completada
  final DateTime createdAt;            // Cuándo se creó
  final DateTime? completedAt;         // Cuándo se completó (si aplica)

  TaskModel({
    this.id,
    required this.title,
    this.description,
    required this.subjectId,
    required this.subjectName,
    this.activityType = ActivityType.tarea,
    required this.dueDate,
    this.dueTime,
    this.reminderEnabled = false,
    this.reminderTiming,
    this.isCompleted = false,
    required this.createdAt,
    this.completedAt,
  });

  /// Convierte el modelo a un Map para guardar en Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'subjectId': subjectId,
      'subjectName': subjectName,
      'activityType': activityType.label,
      'dueDate': Timestamp.fromDate(dueDate),
      'dueTime': dueTime != null ? '${dueTime!.hour}:${dueTime!.minute}' : null,
      'reminderEnabled': reminderEnabled,
      'reminderTiming': reminderTiming?.label,
      'isCompleted': isCompleted,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }

  /// Crea un TaskModel desde un documento de Firestore
  factory TaskModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    TimeOfDay? parseTime(String? timeString) {
      if (timeString == null) return null;
      try {
        final parts = timeString.split(':');
        return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      } catch (e) {
        return null;
      }
    }

    return TaskModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'],
      subjectId: data['subjectId'] ?? '',
      subjectName: data['subjectName'] ?? '',
      activityType: ActivityTypeLabel.fromLabel(data['activityType'] ?? 'Tarea'),
      dueDate: (data['dueDate'] as Timestamp).toDate(),
      dueTime: parseTime(data['dueTime']),
      reminderEnabled: data['reminderEnabled'] ?? false,
      reminderTiming: data['reminderTiming'] != null
          ? ReminderTimingLabel.fromLabel(data['reminderTiming'])
          : null,
      isCompleted: data['isCompleted'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Crea una copia con algunos campos modificados
  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    String? subjectId,
    String? subjectName,
    ActivityType? activityType,
    DateTime? dueDate,
    TimeOfDay? dueTime,
    bool? reminderEnabled,
    ReminderTiming? reminderTiming,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      activityType: activityType ?? this.activityType,
      dueDate: dueDate ?? this.dueDate,
      dueTime: dueTime ?? this.dueTime,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderTiming: reminderTiming ?? this.reminderTiming,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  String toString() => 'TaskModel(id: $id, title: $title, subject: $subjectName)';
}
