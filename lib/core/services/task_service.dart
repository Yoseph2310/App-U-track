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
  //
  // Solo se filtra por 'completed' en Firestore (un único campo, no pide
  // índice). Lo demás se hace aquí: combinar un filtro de fecha con orderBy
  // exige un índice compuesto, y si no existe el stream falla en silencio y
  // el Home mostraba "No tienes entregas próximas" aunque sí hubiera.
  Stream<List<Map<String, dynamic>>> getUpcomingTasks() {
    return _ref
        .where('completed', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);

      final tasks = snapshot.docs
          .map((doc) => <String, dynamic>{
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              })
          .where((task) {
        final due = task['dueDate'];
        // Las que vencen hoy también cuentan como próximas.
        return due is Timestamp && !due.toDate().isBefore(startOfToday);
      }).toList();

      tasks.sort((a, b) =>
          (a['dueDate'] as Timestamp).compareTo(b['dueDate'] as Timestamp));
      return tasks.take(5).toList();
    });
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