import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/due_date.dart';
import '../../core/utils/user_name.dart';
import '../tasks/models/task_model.dart';
import '../tasks/services/subject_service.dart';
import '../tasks/services/task_service.dart';
import '../subjects/screens/subjects_screen.dart';
import '../subjects/screens/subject_form_screen.dart';
import '../tasks/screens/grade_calculator_screen.dart';
import '../tasks/screens/create_edit_task_screen.dart';
import '../tasks/screens/upcoming_tasks_screen.dart';
import '../settings/screens/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Precarga las materias para que la pestaña Materias abra al instante.
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) SubjectsCache.preload(uid);
  }

  void _goTo(int index) => setState(() => _currentIndex = index);

  /// Pantalla que corresponde a cada pestaña del menú inferior.
  /// Todas comparten el mismo menú, así funciona igual en cualquier pantalla.
  Widget _buildTab() {
    switch (_currentIndex) {
      case 1:
        return const SubjectsScreen();
      case 2:
        return const GradeCalculatorScreen();
      case 3:
        return const SettingsScreen();
      default:
        return _HomeTab(onGoTo: _goTo);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // En otra pestaña, el botón "atrás" de Android vuelve a Inicio
      // en vez de cerrar la app.
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goTo(0);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: _buildTab(),

        // NAVEGACIÓN INFERIOR (única para todas las pestañas)
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          onTap: _goTo,
          items: [
            BottomNavigationBarItem(
                icon: const Icon(Icons.home_outlined),
                label: tr('Inicio', 'Home')),
            BottomNavigationBarItem(
                icon: const Icon(Icons.book_outlined),
                label: tr('Materias', 'Subjects')),
            BottomNavigationBarItem(
                icon: const Icon(Icons.calculate_outlined),
                label: tr('Calculadora', 'Calculator')),
            BottomNavigationBarItem(
                icon: const Icon(Icons.settings_outlined),
                label: tr('Configuración', 'Settings')),
          ],
        ),
      ),
    );
  }
}

/// Pestaña Inicio. Tiene su propio estado para crear las consultas en
/// tiempo real una sola vez cada vez que se abre.
class _HomeTab extends StatefulWidget {
  const _HomeTab({required this.onGoTo});

  final ValueChanged<int> onGoTo;

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  late final String _userId;
  late final Stream<int> _subjectCount;
  late final Stream<int> _pendingCount;
  late final Stream<List<TaskModel>> _upcoming;

  /// Escucha cambios del perfil (por ejemplo, el nombre que llega de Google
  /// un momento después de iniciar sesión) para actualizar el saludo.
  StreamSubscription<User?>? _userSub;

  @override
  void initState() {
    super.initState();
    _userId = FirebaseAuth.instance.currentUser!.uid;
    _subjectCount = SubjectService().watchSubjectCount(_userId);
    _pendingCount = TaskService().watchPendingCount(_userId);
    _upcoming = TaskService().watchUpcomingTasks(_userId);
    _userSub = FirebaseAuth.instance.userChanges().listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _userSub?.cancel();
    super.dispose();
  }

  // Nombre e inicial del usuario
  String get _userName => UserName.first(FirebaseAuth.instance.currentUser);

  String get _userInitial =>
      UserName.initial(FirebaseAuth.instance.currentUser);

  // Fecha de hoy en el idioma elegido
  String get _todayLabel {
    final text = DueDate.longLabel(DateTime.now());
    return text[0].toUpperCase() + text.substring(1);
  }

  /// Texto de la tarjeta "Próx. examen": cuánto falta para el examen
  /// pendiente más cercano, o "--" si no hay ninguno.
  String _nextExamLabel(List<TaskModel> upcoming) {
    for (final task in upcoming) {
      if (task.activityType == ActivityType.examen) {
        return DueDate.shortLabel(task.dueDate);
      }
    }
    return '--';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: StreamBuilder<List<TaskModel>>(
        stream: _upcoming,
        builder: (context, upcomingSnap) {
          final upcoming = upcomingSnap.data ?? const <TaskModel>[];
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),

                // HEADER
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tr('Hola, $_userName 👋', 'Hi, $_userName 👋'),
                              style: AppTextStyles.headline2),
                          const SizedBox(height: 2),
                          Text(_todayLabel, style: AppTextStyles.body2),
                        ],
                      ),
                    ),
                    // Acceso directo a la cuenta (pestaña Configuración)
                    Tooltip(
                      message: tr('Mi cuenta', 'My account'),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => widget.onGoTo(3),
                        child: CircleAvatar(
                          radius: 22,
                          backgroundColor: AppColors.primary,
                          child: Text(
                            _userInitial,
                            style: AppTextStyles.headline3
                                .copyWith(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // TARJETAS DE RESUMEN — datos reales
                Row(
                  children: [
                    StreamBuilder<int>(
                      stream: _subjectCount,
                      builder: (context, snap) => _SummaryCard(
                        label: tr('Materias', 'Subjects'),
                        value: '${snap.data ?? 0}',
                        icon: Icons.book_outlined,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    StreamBuilder<int>(
                      stream: _pendingCount,
                      builder: (context, snap) => _SummaryCard(
                        label: tr('Pendientes', 'Pending'),
                        value: '${snap.data ?? 0}',
                        icon: Icons.assignment_outlined,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    _SummaryCard(
                      label: tr('Próx. examen', 'Next exam'),
                      value: upcomingSnap.hasData
                          ? _nextExamLabel(upcoming)
                          : '--',
                      icon: Icons.event_outlined,
                      color: AppColors.warnText,
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // ACCESOS RÁPIDOS
                Text(tr('Accesos rápidos', 'Quick actions'),
                    style: AppTextStyles.headline3),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _QuickAction(
                      icon: Icons.add_circle_outline,
                      label: tr('Nueva\nmateria', 'New\nsubject'),
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SubjectFormScreen())),
                    ),
                    const SizedBox(width: 12),
                    _QuickAction(
                      icon: Icons.grade_outlined,
                      label: tr('Registrar\nnota', 'Add\ngrade'),
                      onTap: () => widget.onGoTo(1),
                    ),
                    const SizedBox(width: 12),
                    _QuickAction(
                      icon: Icons.calculate_outlined,
                      label: tr('Calculadora', 'Calculator'),
                      onTap: () => widget.onGoTo(2),
                    ),
                    const SizedBox(width: 12),
                    _QuickAction(
                      icon: Icons.task_alt_outlined,
                      label: tr('Nueva\ntarea', 'New\ntask'),
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  CreateEditTaskScreen(userId: _userId))),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // PRÓXIMAS ENTREGAS — datos reales
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(tr('Próximas entregas', 'Upcoming tasks'),
                        style: AppTextStyles.headline3),
                    TextButton(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const UpcomingTasksScreen())),
                      child: Text(tr('Ver todo', 'See all'),
                          style: AppTextStyles.label
                              .copyWith(color: AppColors.primary)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (upcomingSnap.hasError)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text(
                          tr('No se pudieron cargar las entregas.',
                              'Tasks could not be loaded.'),
                          style: AppTextStyles.body2),
                    ),
                  )
                else if (!upcomingSnap.hasData)
                  const Center(child: CircularProgressIndicator())
                else if (upcoming.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text(
                          tr('No tienes entregas próximas 🎉',
                              'You have no upcoming tasks 🎉'),
                          style: AppTextStyles.body2),
                    ),
                  )
                else
                  Column(
                    children: upcoming.take(5).map((task) {
                      final daysLeft = DueDate.daysUntil(task.dueDate);
                      return _DeliveryItem(
                        subject: task.subjectName,
                        task: task.title,
                        dueLabel: DueDate.shortLabel(task.dueDate),
                        isUrgent: daysLeft <= 1,
                      );
                    }).toList(),
                  ),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}

// WIDGET: Tarjeta de resumen
class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({required this.label, required this.value,
    required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(value, style: AppTextStyles.headline2.copyWith(color: color)),
            Text(label, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}

// WIDGET: Acceso rápido
class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _QuickAction({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.primary, size: 24),
              const SizedBox(height: 6),
              Text(label, textAlign: TextAlign.center,
                  style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
            ],
          ),
        ),
      ),
    );
  }
}

// WIDGET: Item de entrega
class _DeliveryItem extends StatelessWidget {
  final String subject;
  final String task;
  final String dueLabel;
  final bool isUrgent;

  const _DeliveryItem({required this.subject, required this.task,
    required this.dueLabel, required this.isUrgent});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUrgent
              ? AppColors.errorText.withValues(alpha: 0.3)
              : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4, height: 40,
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
                Text(subject, style: AppTextStyles.caption),
                const SizedBox(height: 2),
                Text(task, style: AppTextStyles.body1),
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
              dueLabel,
              style: AppTextStyles.caption.copyWith(
                color: isUrgent ? AppColors.errorText : AppColors.okText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
