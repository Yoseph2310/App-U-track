import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/grade_model.dart';

/// Servicio de Calificaciones
///
/// Maneja todas las operaciones con calificaciones (notas, parciales, quizzes, etc).
class GradeService {
  static final GradeService _instance = GradeService._internal();

  factory GradeService() {
    return _instance;
  }

  GradeService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Obtiene todas las calificaciones de una materia
  Future<List<GradeModel>> getGrades(String userId,
      String subjectId,) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('subjects')
          .doc(subjectId)
          .collection('grades')
          .orderBy('dateAdded', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => GradeModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error obteniendo calificaciones $e');
      return [];
    }
  }

  /// Obtiene una calificación específica
  Future<GradeModel?> getGrade(String userId,
      String subjectId,
      String gradeId,) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('subjects')
          .doc(subjectId)
          .collection('grades')
          .doc(gradeId)
          .get();

      if (doc.exists) {
        return GradeModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error obteniendo calificaciones: $e');
      rethrow;
    }
  }

  /// Crea una nueva calificación
  /// Automáticamente recalcula la nota ponderada de la materia
  Future<String?> createGrade(String userId,
      String subjectId,
      GradeModel grade,) async {
    try {
      final docRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('subjects')
          .doc(subjectId)
          .collection('grades')
          .add(grade.toMap());

      // Recalcula la nota ponderada
      await _recalculateSubjectGrade(userId, subjectId);

      return docRef.id;
    } catch (e) {
      print('Error creando calificación $e');
      return null;
    }
  }

  /// Actualiza una calificación existente
  Future<bool> updateGrade(String userId,
      String subjectId,
      GradeModel grade,) async {
    if (grade.id == null) return false;

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('subjects')
          .doc(subjectId)
          .collection('grades')
          .doc(grade.id)
          .update(grade.toMap());

      // Recalcula la nota ponderada
      await _recalculateSubjectGrade(userId, subjectId);

      return true;
    } catch (e) {
      print('Error actualizando calificación $e');
      return false;
    }
  }

  /// Elimina una calificación
  Future<bool> deleteGrade(String userId,
      String subjectId,
      String gradeId,) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('subjects')
          .doc(subjectId)
          .collection('grades')
          .doc(gradeId)
          .delete();

      // Recalcula la nota ponderada
      await _recalculateSubjectGrade(userId, subjectId);

      return true;
    } catch (e) {
      print('Error eliminando calificación $e');
      return false;
    }
  }

  /// Calcula la nota ponderada de una materia
  /// Fórmula nota_final = suma(calificación × peso) / suma(pesos)


  Future<double> calculateWeightedGrade(String userId,
      String subjectId,) async {
    try {
      final grades = await getGrades(userId, subjectId);

      if (grades.isEmpty) return 0.0;

      final subjectDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('subjects')
          .doc(subjectId)
          .get();

      final subjectData = subjectDoc.data();
      final rawScheme = subjectData?['evaluationScheme'];

      if (rawScheme is! List || rawScheme.isEmpty) {
        double totalScore = 0.0;

        for (final grade in grades) {
          totalScore += grade.score * grade.weight;
        }

        return totalScore / 100;
      }

      double totalScore = 0.0;

      for (final item in rawScheme) {
        if (item is! Map) continue;

        final cutName = item['name']?.toString() ?? '';
        final percentage =
            (item['percentage'] as num?)?.toDouble() ?? 0.0;

        final activities = grades.where(
              (grade) =>
          grade.cutName == cutName ||
              (grade.cutName == null && grade.name == cutName),
        );

        final activityList = activities.toList();

        if (activityList.isEmpty) continue;

        final average = activityList.fold<double>(
          0.0,
              (sum, grade) => sum + grade.score,
        ) /
            activityList.length;

        totalScore += average * percentage / 100;
      }

      return totalScore;
    } catch (e) {
      print('Error calculando nota acumulada: $e');
      return 0.0;
    }
  }

  Future<void> _recalculateSubjectGrade(String userId,
      String subjectId,) async {
    try {
      final weightedGrade =
      await calculateWeightedGrade(userId, subjectId);

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('subjects')
          .doc(subjectId)
          .update({'currentGrade': weightedGrade});
    } catch (e) {
      print('Error recalculando nota: $e');
    }
  }
}
/// Clase auxiliar para estadísticas de calificaciones
class GradeStats {
  final double average;
  final double highestGrade;
  final double lowestGrade;
  final int totalGrades;

  GradeStats({
    required this.average,
    required this.highestGrade,
    required this.lowestGrade,
    required this.totalGrades,
  });
}
