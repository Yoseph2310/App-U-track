import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TaskService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Ruta base: users/{uid}/tasks
  CollectionReference get _ref => _db
      .collection('users')
      .doc(_auth.currentUser!.uid)
      .collection('tasks');

  // Stream: próximas entregas ordenadas por fecha
  Stream<List<Map<String, dynamic>>> getUpcomingTasks() {
    final now = DateTime.now();
    return _ref
        .where('completed', isEqualTo: false)
        .where('dueDate', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
        .orderBy('dueDate')
        .limit(5)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {
      'id': doc.id,
      ...doc.data() as Map<String, dynamic>,
    }).toList());
  }

  // Contar tareas pendientes (para el Home)
  Stream<int> getPendingCount() {
    return _ref
        .where('completed', isEqualTo: false)
        .snapshots()
        .map((s) => s.docs.length);
  }

  // Agregar tarea
  Future<void> addTask({
    required String title,
    required String subjectName,
    required DateTime dueDate,
  }) async {
    await _ref.add({
      'title': title,
      'subjectName': subjectName,
      'dueDate': Timestamp.fromDate(dueDate),
      'completed': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Marcar como completada
  Future<void> completeTask(String id) async {
    await _ref.doc(id).update({'completed': true});
  }

  // Eliminar tarea
  Future<void> deleteTask(String id) async {
    await _ref.doc(id).delete();
  }
}