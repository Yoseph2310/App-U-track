import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/services/subject_service.dart';
import '../../core/services/task_service.dart';
import '../subjects/screens/subjects_screen.dart';
import '../tasks/screens/grade_calculator_screen.dart';
import '../tasks/screens/create_edit_task_screen.dart';
import '../settings/screens/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _subjectService = SubjectService();
  final _taskService = TaskService();
  int _currentIndex = 0;

  // Nombre e inicial del usuario
  String get _userName {
    final name = FirebaseAuth.instance.currentUser?.displayName;
    if (name != null && name.isNotEmpty) return name.split(' ').first;
    return 'Estudiante';
  }

  String get _userInitial {
    final name = FirebaseAuth.instance.currentUser?.displayName;
    if (name != null && name.isNotEmpty) return name[0].toUpperCase();
    return 'U';
  }

  // Fecha de hoy en español
  String get _todayLabel {
    const dias = ['Lunes','Martes','Miércoles','Jueves','Viernes','Sábado','Domingo'];
    const meses = ['enero','febrero','marzo','abril','mayo','junio',
      'julio','agosto','septiembre','octubre','noviembre','diciembre'];
    final now = DateTime.now();
    return '${dias[now.weekday - 1]}, ${now.day} de ${meses[now.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),

              // HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hola, $_userName 👋', style: AppTextStyles.headline2),
                      const SizedBox(height: 2),
                      Text(_todayLabel, style: AppTextStyles.body2),
                    ],
                  ),
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      _userInitial,
                      style: AppTextStyles.headline3.copyWith(color: Colors.white),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // TARJETAS DE RESUMEN — datos reales
              Row(
                children: [
                  // Materias
                  StreamBuilder<int>(
                    stream: _subjectService.getSubjectCount(),
                    builder: (context, snap) => _SummaryCard(
                      label: 'Materias',
                      value: '${snap.data ?? 0}',
                      icon: Icons.book_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Pendientes
                  StreamBuilder<int>(
                    stream: _taskService.getPendingCount(),
                    builder: (context, snap) => _SummaryCard(
                      label: 'Pendientes',
                      value: '${snap.data ?? 0}',
                      icon: Icons.assignment_outlined,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Próximo examen (estático por ahora)
                  _SummaryCard(
                    label: 'Próx. examen',
                    value: '--',
                    icon: Icons.event_outlined,
                    color: AppColors.warnText,
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // ACCESOS RÁPIDOS
              Text('Accesos rápidos', style: AppTextStyles.headline3),
              const SizedBox(height: 12),
              Row(
                children: [
                  _QuickAction(
                    icon: Icons.add_circle_outline,
                    label: 'Nueva\nmateria',
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const SubjectsScreen())),
                  ),
                  const SizedBox(width: 12),
                  _QuickAction(
                    icon: Icons.grade_outlined,
                    label: 'Registrar\nnota',
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const SubjectsScreen())),
                  ),
                  const SizedBox(width: 12),
                  _QuickAction(
                    icon: Icons.calculate_outlined,
                    label: 'Calculadora',
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const GradeCalculatorScreen())),
                  ),
                  const SizedBox(width: 12),
                  _QuickAction(
                    icon: Icons.task_alt_outlined,
                    label: 'Nueva\ntarea',
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => CreateEditTaskScreen(userId: userId))),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // PRÓXIMAS ENTREGAS — datos reales
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Próximas entregas', style: AppTextStyles.headline3),
                  TextButton(
                    onPressed: () {},
                    child: Text('Ver todo',
                        style: AppTextStyles.label.copyWith(color: AppColors.primary)),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              StreamBuilder<List<Map<String, dynamic>>>(
                stream: _taskService.getUpcomingTasks(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final tasks = snap.data ?? [];
                  if (tasks.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text('No tienes entregas próximas 🎉',
                            style: AppTextStyles.body2),
                      ),
                    );
                  }
                  return Column(
                    children: tasks.map((task) {
                      final due = (task['dueDate'] as Timestamp).toDate();
                      final daysLeft = due.difference(DateTime.now()).inDays;
                      return _DeliveryItem(
                        subject: task['subjectName'] ?? '',
                        task: task['title'] ?? '',
                        daysLeft: daysLeft,
                        isUrgent: daysLeft <= 1,
                      );
                    }).toList(),
                  );
                },
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),

      // NAVEGACIÓN INFERIOR
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 1) {
            Navigator.push(context, MaterialPageRoute(
                builder: (_) => SubjectsScreen(
                  onInicio: () => Navigator.pop(context),
                  onCalculadora: () => Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (_) => const GradeCalculatorScreen())),
                  onConfiguracion: () => Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen())),
                )));
            return;
          }
          if (index == 2) {
            Navigator.push(context, MaterialPageRoute(
                builder: (_) => const GradeCalculatorScreen()));
            return;
          }
          if (index == 3) {
            Navigator.push(context, MaterialPageRoute(
                builder: (_) => const SettingsScreen()));
            return;
          }
          setState(() => _currentIndex = index);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.book_outlined), label: 'Materias'),
          BottomNavigationBarItem(icon: Icon(Icons.calculate_outlined), label: 'Calculadora'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Configuración'),
        ],
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
  final int daysLeft;
  final bool isUrgent;

  const _DeliveryItem({required this.subject, required this.task,
    required this.daysLeft, required this.isUrgent});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUrgent ? AppColors.errorText.withOpacity(0.3) : AppColors.border,
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
              daysLeft == 0 ? 'Hoy' : '${daysLeft}d',
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