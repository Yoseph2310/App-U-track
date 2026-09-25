import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/subject_model.dart';

/// Servicio de Materias
///
/// Maneja la comunicación con Firestore para materias/asignaturas.
class SubjectService {
  static final SubjectService _instance = SubjectService._internal();

  factory SubjectService() {
    return _instance;
  }

  SubjectService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Obtiene todas las materias del usuario
  Future<List<SubjectModel>> getSubjects(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('subjects')
          .orderBy('name')
          .get();

      return snapshot.docs
          .map((doc) => SubjectModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error obteniendo materias $e');
      return [];
    }
  }

  /// Obtiene una materia específica
  Future<SubjectModel?> getSubject(String userId, String subjectId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('subjects')
          .doc(subjectId)
          .get();

      if (doc.exists) {
        return SubjectModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error obteniendo materia $e');
      return null;
    }
  }

  /// Crea una nueva materia
  Future<String?> createSubject(String userId, SubjectModel subject) async {
    try {
      final docRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('subjects')
          .add(subject.toMap());

      return docRef.id;
    } catch (e) {
      print('Error creando materia $e');
      return null;
    }
  }

  /// Actualiza una materia existente
  Future<bool> updateSubject(String userId, SubjectModel subject) async {
    if (subject.id == null) return false;

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('subjects')
          .doc(subject.id)
          .update(subject.toMap());

      return true;
    } catch (e) {
      print('Error actualizando materia $e');
      return false;
    }
  }

  /// Actualiza la calificación actual de una materia
  /// (Se calcula automáticamente desde las notas)
  Future<bool> updateGrade(
    String userId,
    String subjectId,
    double newGrade,
  ) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('subjects')
          .doc(subjectId)
          .update({'currentGrade': newGrade});

      return true;
    } catch (e) {
      print('Error actualizando calificación $e');
      return false;
    }
  }

  /// Elimina una materia
  Future<bool> deleteSubject(String userId, String subjectId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('subjects')
          .doc(subjectId)
          .delete();

      return true;
    } catch (e) {
      print('Error eliminando materia $e');
      return false;
    }
  }

  /// Stream en tiempo real de todas las materias
  Stream<List<SubjectModel>> getSubjectsStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('subjects')
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SubjectModel.fromFirestore(doc))
            .toList());
  }

  /// Stream de una materia específica
  Stream<SubjectModel?> getSubjectStream(String userId, String subjectId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('subjects')
        .doc(subjectId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return SubjectModel.fromFirestore(doc);
      }
      return null;
    });
  }
}
