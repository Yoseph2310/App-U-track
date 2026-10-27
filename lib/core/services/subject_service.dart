import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SubjectService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Ruta base: users/{uid}/subjects
  CollectionReference get _ref => _db
      .collection('users')
      .doc(_auth.currentUser!.uid)
      .collection('subjects');

  // Stream: escucha los cambios en tiempo real
  Stream<List<Map<String, dynamic>>> getSubjects() {
    return _ref.orderBy('name').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        }).toList());
  }

  // Contar materias (para el Home)
  Stream<int> getSubjectCount() {
    return _ref.snapshots().map((s) => s.docs.length);
  }

  // Agregar materia
  Future<void> addSubject(String name) async {
    await _ref.add({
      'name': name,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Editar materia
  Future<void> updateSubject(String id, String name) async {
    await _ref.doc(id).update({'name': name});
  }

  // Eliminar materia
  Future<void> deleteSubject(String id) async {
    await _ref.doc(id).delete();
  }
}