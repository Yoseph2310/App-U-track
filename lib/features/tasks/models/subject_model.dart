import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de Materia
///
/// Representa una materia/asignatura del estudiante.
/// Se almacena en Firestore en la colección 'users/{userId}/subjects'
class SubjectModel {
  final String? id;                    // ID del documento
  final String name;                   // Ej. "Matemáticas", "Física"
  final String color;                  // Color en hexadecimal para la UI
  final String? teacher;               // Nombre del profesor (opcional)
  final String? classroom;             // Salón o aula (opcional)
  final double currentGrade;           // Calificación actual ponderada
  final DateTime createdAt;            // Cuándo se agregó

  SubjectModel({
    this.id,
    required this.name,
    required this.color,
    this.teacher,
    this.classroom,
    this.currentGrade = 0.0,
    required this.createdAt,
  });

  /// Convierte el modelo a un Map para guardar en Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'color': color,
      'teacher': teacher,
      'classroom': classroom,
      'currentGrade': currentGrade,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Crea un SubjectModel desde un documento de Firestore
  factory SubjectModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return SubjectModel(
      id: doc.id,
      name: data['name'] ?? '',
      color: data['color'] ?? '#2563EB',
      teacher: data['teacher'],
      classroom: data['classroom'],
      currentGrade: (data['currentGrade'] ?? 0.0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  /// Copia con modificaciones
  SubjectModel copyWith({
    String? id,
    String? name,
    String? color,
    String? teacher,
    String? classroom,
    double? currentGrade,
    DateTime? createdAt,
  }) {
    return SubjectModel(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      teacher: teacher ?? this.teacher,
      classroom: classroom ?? this.classroom,
      currentGrade: currentGrade ?? this.currentGrade,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'SubjectModel(id: $id, name: $name, grade: $currentGrade)';
}
