import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import 'tasks/screens/create_edit_task_screen.dart';
import 'tasks/screens/grade_calculator_screen.dart';
import 'settings/screens/settings_screen.dart';

/// Pantalla temporal solo para probar tus pantallas mientras las conectas
/// a la navegación real de la app. Bórrala cuando ya no la necesites.
class DevMenuScreen extends StatelessWidget {
  const DevMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Menú de pruebas',
          style: TextStyle(color: AppColors.textMain),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _devButton(
              context,
              label: 'Pantalla 7 — Nueva actividad',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateEditTaskScreen(
                      userId: 'test-user',
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _devButton(
              context,
              label: 'Pantalla 8 — Calculadora de notas',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GradeCalculatorScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _devButton(
              context,
              label: 'Pantalla 9 — Configuración',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _devButton(
    BuildContext context, {
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 260,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
