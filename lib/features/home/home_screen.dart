import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                      Text('Hola, Danna 👋', style: AppTextStyles.headline2),
                      const SizedBox(height: 2),
                      Text('Viernes, 26 de septiembre', style: AppTextStyles.body2),
                    ],
                  ),
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      'D',
                      style: AppTextStyles.headline3.copyWith(color: Colors.white),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // TARJETAS DE RESUMEN
              Row(
                children: [
                  _SummaryCard(
                    label: 'Materias',
                    value: '6',
                    icon: Icons.book_outlined,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  _SummaryCard(
                    label: 'Pendientes',
                    value: '4',
                    icon: Icons.assignment_outlined,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(width: 12),
                  _SummaryCard(
                    label: 'Próx. examen',
                    value: '3d',
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
                  _QuickAction(icon: Icons.add_circle_outline, label: 'Nueva\nmateria'),
                  const SizedBox(width: 12),
                  _QuickAction(icon: Icons.grade_outlined, label: 'Registrar\nnota'),
                  const SizedBox(width: 12),
                  _QuickAction(icon: Icons.calculate_outlined, label: 'Calculadora'),
                  const SizedBox(width: 12),
                  _QuickAction(icon: Icons.task_alt_outlined, label: 'Nueva\ntarea'),
                ],
              ),

              const SizedBox(height: 32),

              // PRÓXIMAS ENTREGAS
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Próximas entregas', style: AppTextStyles.headline3),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      'Ver todo',
                      style: AppTextStyles.label.copyWith(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              _DeliveryItem(
                subject: 'Ingeniería Clínica',
                task: 'Informe laboratorio EEG',
                daysLeft: 1,
                isUrgent: true,
              ),
              _DeliveryItem(
                subject: 'Análisis de Algoritmos',
                task: 'Taller complejidad computacional',
                daysLeft: 3,
                isUrgent: false,
              ),
              _DeliveryItem(
                subject: 'Diseño de Dispositivos',
                task: 'Avance plantilla instrumentada',
                daysLeft: 5,
                isUrgent: false,
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
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.book_outlined), label: 'Materias'),
          BottomNavigationBarItem(icon: Icon(Icons.calculate_outlined), label: 'Notas'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Ajustes'),
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

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

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

  const _QuickAction({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () {},
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
              Text(
                label,
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(color: AppColors.primary),
              ),
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

  const _DeliveryItem({
    required this.subject,
    required this.task,
    required this.daysLeft,
    required this.isUrgent,
  });

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
              '${daysLeft}d',
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