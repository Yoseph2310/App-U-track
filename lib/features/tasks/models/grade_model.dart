
import 'package:cloud_firestore/cloud_firestore.dart';

// Modelo de Calificación/Nota
// Representa una actividad evaluada dentro de un corte de una materia.
class GradeModel {
  final String? id;
  final String subjectId;
  final String name;
  final double score;
  final double weight;
  final DateTime dateAdded;
  final String? notes;

  // Identifica el corte al que pertenece la actividad.
  final String? cutName;

  GradeModel({
    this.id,
    required this.subjectId,
    required this.name,
    required this.score,
    required this.weight,
    required this.dateAdded,
    this.notes,
    this.cutName,
  });

  // Convierte el modelo a un Map para guardar en Firestore.
  Map<String, dynamic> toMap() {
    return {
      'subjectId': subjectId,
      'name': name,
      'score': score,
      'weight': weight,
      'dateAdded': Timestamp.fromDate(dateAdded),
      'notes': notes,
      'cutName': cutName,
    };
  }

  // Crea un GradeModel desde un documento de Firestore.
  factory GradeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return GradeModel(
      id: doc.id,
      subjectId: data['subjectId'] ?? '',
      name: data['name'] ?? '',
      score: (data['score'] as num? ?? 0).toDouble(),
      weight: (data['weight'] as num? ?? 0).toDouble(),
      dateAdded: data['dateAdded'] is Timestamp
          ? (data['dateAdded'] as Timestamp).toDate()
          : DateTime.now(),
      notes: data['notes'] as String?,
      cutName: data['cutName'] as String?,
    );
  }

  // Copia el modelo con modificaciones.
  GradeModel copyWith({
    String? id,
    String? subjectId,
    String? name,
    double? score,
    double? weight,
    DateTime? dateAdded,
    String? notes,
    String? cutName,
  }) {
    return GradeModel(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      name: name ?? this.name,
      score: score ?? this.score,
      weight: weight ?? this.weight,
      dateAdded: dateAdded ?? this.dateAdded,
      notes: notes ?? this.notes,
      cutName: cutName ?? this.cutName,
    );
  }

  @override
  String toString() =>
      'GradeModel(id: $id, name: $name, score: $score, cutName: $cutName)';
}
