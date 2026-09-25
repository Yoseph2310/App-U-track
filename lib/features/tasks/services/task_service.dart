import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';

/// Servicio de Tareas
///
/// Esta clase maneja toda la comunicación con Firestore para tareas.
/// Aquí va la lógica de crear, leer, actualizar y eliminar tareas.
class TaskService {
  static final TaskService _instance = TaskService._internal();

  factory TaskService() {
    return _instance;
  }

  TaskService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Obtiene todas las tareas del usuario actual
  /// userId debe venir de Firebase Auth
  Future<List<TaskModel>> getTasks(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .orderBy('dueDate')
          .get();

      return snapshot.docs
          .map((doc) => TaskModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error obteniendo tareas $e');
      return [];
    }
  }

  /// Obtiene las tareas de una materia específica
  Future<List<TaskModel>> getTasksBySubject(
    String userId,
    String subjectId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .where('subjectId', isEqualTo: subjectId)
          .orderBy('dueDate')
          .get();

      return snapshot.docs
          .map((doc) => TaskModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error obteniendo tareas de materia $e');
      return [];
    }
  }

  /// Obtiene una tarea específica
  Future<TaskModel?> getTask(String userId, String taskId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .doc(taskId)
          .get();

      if (doc.exists) {
        return TaskModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error obteniendo tarea $e');
      return null;
    }
  }

  /// Crea una nueva tarea
  Future<String?> createTask(String userId, TaskModel task) async {
    try {
      final docRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .add(task.toMap());

      return docRef.id;
    } catch (e) {
      print('Error creando tarea $e');
      return null;
    }
  }

  /// Actualiza una tarea existente
  Future<bool> updateTask(String userId, TaskModel task) async {
    if (task.id == null) return false;

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .doc(task.id)
          .update(task.toMap());

      return true;
    } catch (e) {
      print('Error actualizando tarea $e');
      return false;
    }
  }

  /// Marca una tarea como completada
  Future<bool> completeTask(String userId, String taskId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .doc(taskId)
          .update({
        'isCompleted': true,
        'completedAt': Timestamp.now(),
      });

      return true;
    } catch (e) {
      print('Error completando tarea $e');
      return false;
    }
  }

  /// Elimina una tarea
  Future<bool> deleteTask(String userId, String taskId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .doc(taskId)
          .delete();

      return true;
    } catch (e) {
      print('Error eliminando tarea $e');
      return false;
    }
  }

  /// Stream en tiempo real de todas las tareas
  /// Útil para actualizar la UI automáticamente
  Stream<List<TaskModel>> getTasksStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .orderBy('dueDate')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TaskModel.fromFirestore(doc))
            .toList());
  }

  /// Stream de tareas por materia
  Stream<List<TaskModel>> getTasksBySubjectStream(
    String userId,
    String subjectId,
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .where('subjectId', isEqualTo: subjectId)
        .orderBy('dueDate')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TaskModel.fromFirestore(doc))
            .toList());
  }

  /// Obtiene tareas próximas a vencer (próximos 7 días)
  Future<List<TaskModel>> getUpcomingTasks(String userId) async {
    try {
      final now = DateTime.now();
      final nextWeek = now.add(const Duration(days: 7));

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .where('dueDate', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
          .where('dueDate', isLessThanOrEqualTo: Timestamp.fromDate(nextWeek))
          .where('isCompleted', isEqualTo: false)
          .orderBy('dueDate')
          .get();

      return snapshot.docs
          .map((doc) => TaskModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error obteniendo tareas próximas $e');
      return [];
    }
  }
}
