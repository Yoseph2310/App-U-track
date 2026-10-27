
import 'package:cloud_firestore/cloud_firestore.dart';

/// Representa una materia del estudiante.
class SubjectModel {
  final String? id;
  final String name;
  final String color;
  final String? teacher;
  final String? classroom;
  final double currentGrade;
  final DateTime createdAt;

  // Esquema de evaluación personalizado de la materia.
  final List<Map<String, dynamic>> evaluationScheme;

  SubjectModel({
    this.id,
    required this.name,
    required this.color,
    this.teacher,
    this.classroom,
    this.currentGrade = 0.0,
    required this.createdAt,
    this.evaluationScheme = const [],
  });

  /// Convierte el modelo a un Map para guardar en Firestore.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'color': color,
      'teacher': teacher,
      'classroom': classroom,
      'currentGrade': currentGrade,
      'createdAt': Timestamp.fromDate(createdAt),
      'evaluationScheme': evaluationScheme,
    };
  }

  /// Crea un SubjectModel desde Firestore.
  factory SubjectModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final rawScheme = data['evaluationScheme'];

    final scheme = rawScheme is List
        ? rawScheme
        .whereType<Map>()
        .map(
          (item) => Map<String, dynamic>.from(item),
    )
        .toList()
        : <Map<String, dynamic>>[];

    final rawCreatedAt = data['createdAt'];

    return SubjectModel(
      id: doc.id,
      name: data['name'] ?? '',
      color: data['color'] ?? '#2563EB',
      teacher: data['teacher'],
      classroom: data['classroom'],
      currentGrade: (data['currentGrade'] ?? 0.0).toDouble(),
      createdAt: rawCreatedAt is Timestamp
          ? rawCreatedAt.toDate()
          : DateTime.now(),
      evaluationScheme: scheme,
    );
  }

  /// Copia con modificaciones.
  SubjectModel copyWith({
    String? id,
    String? name,
    String? color,
    String? teacher,
    String? classroom,
    double? currentGrade,
    DateTime? createdAt,
    List<Map<String, dynamic>>? evaluationScheme,
  }) {
    return SubjectModel(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      teacher: teacher ?? this.teacher,
      classroom: classroom ?? this.classroom,
      currentGrade: currentGrade ?? this.currentGrade,
      createdAt: createdAt ?? this.createdAt,
      evaluationScheme: evaluationScheme ?? this.evaluationScheme,
    );
  }

  @override
  String toString() =>
      'SubjectModel(id: $id, name: $name, grade: $currentGrade)';
}
