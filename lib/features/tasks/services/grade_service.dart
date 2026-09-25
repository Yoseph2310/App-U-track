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
  Future<List<GradeModel>> getGrades(
    String userId,
    String subjectId,
  ) async {
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
  Future<GradeModel?> getGrade(
    String userId,
    String subjectId,
    String gradeId,
  ) async {
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
      print('Error obteniendo calificación $e');
      return null;
    }
  }

  /// Crea una nueva calificación
  /// Automáticamente recalcula la nota ponderada de la materia
  Future<String?> createGrade(
    String userId,
    String subjectId,
    GradeModel grade,
  ) async {
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
  Future<bool> updateGrade(
    String userId,
    String subjectId,
    GradeModel grade,
  ) async {
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
  Future<bool> deleteGrade(
    String userId,
    String subjectId,
    String gradeId,
  ) async {
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
  Future<double> calculateWeightedGrade(
    String userId,
    String subjectId,
  ) async {
    try {
      final grades = await getGrades(userId, subjectId);

      if (grades.isEmpty) return 0.0;

      double totalScore = 0;
      double totalWeight = 0;

      for (var grade in grades) {
        totalScore += grade.score * grade.weight;
        totalWeight += grade.weight;
      }

      if (totalWeight == 0) return 0.0;

      return totalScore / totalWeight;
    } catch (e) {
      print('Error calculando nota ponderada $e');
      return 0.0;
    }
  }

  /// Actualiza la calificación ponderada en Firestore
  Future<void> _recalculateSubjectGrade(
    String userId,
    String subjectId,
  ) async {
    try {
      final weightedGrade = await calculateWeightedGrade(userId, subjectId);

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('subjects')
          .doc(subjectId)
          .update({'currentGrade': weightedGrade});
    } catch (e) {
      print('Error recalculando nota $e');
    }
  }

  /// Stream en tiempo real de calificaciones
  Stream<List<GradeModel>> getGradesStream(
    String userId,
    String subjectId,
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('subjects')
        .doc(subjectId)
        .collection('grades')
        .orderBy('dateAdded', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GradeModel.fromFirestore(doc))
            .toList());
  }

  /// Obtiene estadísticas de calificaciones
  /// Útil para mostrar promedio, mejor nota, peor nota, etc
  Future<GradeStats> getGradeStats(
    String userId,
    String subjectId,
  ) async {
    try {
      final grades = await getGrades(userId, subjectId);

      if (grades.isEmpty) {
        return GradeStats(
          average: 0,
          highestGrade: 0,
          lowestGrade: 0,
          totalGrades: 0,
        );
      }

      final scores = grades.map((g) => g.score).toList();
      scores.sort();

      return GradeStats(
        average: await calculateWeightedGrade(userId, subjectId),
        highestGrade: scores.last,
        lowestGrade: scores.first,
        totalGrades: grades.length,
      );
    } catch (e) {
      print('Error obteniendo estadísticas $e');
      return GradeStats(
        average: 0,
        highestGrade: 0,
        lowestGrade: 0,
        totalGrades: 0,
      );
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
