import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/settings/app_settings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/due_date.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';
import 'create_edit_task_screen.dart';

/// Cómo se agrupa la lista de próximas actividades.
enum _GroupBy { fecha, materia }

/// Lista completa de próximas actividades (las pendientes que vencen de hoy
/// en adelante), organizada por fecha o por materia.
class UpcomingTasksScreen extends StatefulWidget {
  const UpcomingTasksScreen({super.key});

  @override
  State<UpcomingTasksScreen> createState() => _UpcomingTasksScreenState();
}

class _UpcomingTasksScreenState extends State<UpcomingTasksScreen> {
  _GroupBy _groupBy = _GroupBy.fecha;
  late final Stream<List<TaskModel>>? _stream;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    _stream = uid == null ? null : TaskService().watchUpcomingTasks(uid);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: Text(
          tr('Próximas entregas', 'Upcoming tasks'),
          style: TextStyle(
            color: AppColors.textMain,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<_GroupBy>(
                segments: [
                  ButtonSegment(
                    value: _GroupBy.fecha,
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(tr('Por fecha', 'By date')),
                  ),
                  ButtonSegment(
                    value: _GroupBy.materia,
                    icon: const Icon(Icons.menu_book, size: 18),
                    label: Text(tr('Por materia', 'By subject')),
                  ),
                ],
                selected: {_groupBy},
                onSelectionChanged: (selection) =>
                    setState(() => _groupBy = selection.first),
              ),
            ),
          ),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  Widget _buildList() {
    final stream = _stream;
    if (stream == null) {
      return _message(tr('Debes iniciar sesión para ver tus actividades.',
          'You must sign in to see your tasks.'));
    }

    return StreamBuilder<List<TaskModel>>(
      stream: stream,
      builder: (context, snap) {
        if (snap.hasError) {
          return _message(tr('No se pudieron cargar las actividades.',
              'Tasks could not be loaded.'));
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final tasks = snap.data!;
        if (tasks.isEmpty) {
          return _message(tr('No tienes entregas próximas 🎉',
              'You have no upcoming tasks 🎉'));
        }

        final groups = _group(tasks);
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            for (final entry in groups.entries) ...[
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Text(
                  entry.key,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              for (final task in entry.value) _TaskTile(task: task),
            ],
          ],
        );
      },
    );
  }

  /// Agrupa las actividades. Por fecha: un grupo por día, en orden.
  /// Por materia: un grupo por materia (orden alfabético) y dentro por fecha.
  Map<String, List<TaskModel>> _group(List<TaskModel> tasks) {
    final groups = <String, List<TaskModel>>{};
    if (_groupBy == _GroupBy.fecha) {
      for (final task in tasks) {
        final key = _capitalize(DueDate.longLabel(task.dueDate));
        groups.putIfAbsent(key, () => []).add(task);
      }
      return groups;
    }

    final sorted = [...tasks]..sort((a, b) {
        final bySubject = a.subjectName
            .toLowerCase()
            .compareTo(b.subjectName.toLowerCase());
        return bySubject != 0 ? bySubject : a.dueDate.compareTo(b.dueDate);
      });
    for (final task in sorted) {
      final key = task.subjectName.isEmpty
          ? tr('Sin materia', 'No subject')
          : task.subjectName;
      groups.putIfAbsent(key, () => []).add(task);
    }
    return groups;
  }

  static String _capitalize(String text) =>
      text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);

  Widget _message(String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

/// Una actividad de la lista. Al tocarla se abre para editarla.
class _TaskTile extends StatelessWidget {
  const _TaskTile({required this.task});

  final TaskModel task;

  @override
  Widget build(BuildContext context) {
    final days = DueDate.daysUntil(task.dueDate);
    final isUrgent = days <= 1;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CreateEditTaskScreen(isEditing: true, task: task),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isUrgent
                ? AppColors.errorText.withValues(alpha: 0.3)
                : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: isUrgent ? AppColors.errorText : AppColors.primary,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${task.subjectName} · ${task.activityType.displayLabel}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    task.title,
                    style: TextStyle(fontSize: 14, color: AppColors.textMain),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isUrgent ? AppColors.errorBg : AppColors.okBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                DueDate.shortLabel(task.dueDate),
                style: TextStyle(
                  fontSize: 12,
                  color: isUrgent ? AppColors.errorText : AppColors.okText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
