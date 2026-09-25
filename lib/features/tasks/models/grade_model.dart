import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de Calificación/Nota
///
/// Representa una calificación individual de una materia (ej. Parcial 1, Quiz, etc).
/// Se almacena en Firestore en 'users/{userId}/subjects/{subjectId}/grades'
class GradeModel {
  final String? id;                    // ID del documento
  final String subjectId;              // Referencia a la materia
  final String name;                   // Ej. "Parcial 1", "Quiz", "Examen final"
  final double score;                  // Calificación (0 a 5)
  final double weight;                 // Peso o porcentaje de la nota
  final DateTime dateAdded;            // Cuándo se registró
  final String? notes;                 // Notas adicionales (opcional)

  GradeModel({
    this.id,
    required this.subjectId,
    required this.name,
    required this.score,
    required this.weight,
    required this.dateAdded,
    this.notes,
  });

  /// Convierte el modelo a un Map para guardar en Firestore
  Map<String, dynamic> toMap() {
    return {
      'subjectId': subjectId,
      'name': name,
      'score': score,
      'weight': weight,
      'dateAdded': Timestamp.fromDate(dateAdded),
      'notes': notes,
    };
  }

  /// Crea un GradeModel desde un documento de Firestore
  factory GradeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return GradeModel(
      id: doc.id,
      subjectId: data['subjectId'] ?? '',
      name: data['name'] ?? '',
      score: (data['score'] ?? 0.0).toDouble(),
      weight: (data['weight'] ?? 0.0).toDouble(),
      dateAdded: (data['dateAdded'] as Timestamp).toDate(),
      notes: data['notes'],
    );
  }

  /// Copia con modificaciones
  GradeModel copyWith({
    String? id,
    String? subjectId,
    String? name,
    double? score,
    double? weight,
    DateTime? dateAdded,
    String? notes,
  }) {
    return GradeModel(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      name: name ?? this.name,
      score: score ?? this.score,
      weight: weight ?? this.weight,
      dateAdded: dateAdded ?? this.dateAdded,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() => 'GradeModel(id: $id, name: $name, score: $score)';
}
