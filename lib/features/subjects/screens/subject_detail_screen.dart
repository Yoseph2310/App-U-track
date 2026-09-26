import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'subject_form_screen.dart';

class Actividad {
  final String nombre;
  final double porcentaje;
  final double? nota;

  const Actividad({
    required this.nombre,
    required this.porcentaje,
    this.nota,
  });
}

class SubjectDetailScreen extends StatelessWidget {
  const SubjectDetailScreen({
    super.key,
    required this.nombreMateria,
    required this.notaAcumulada,
    required this.porcentajeEvaluado,
    required this.actividades,
    this.onBack,
    this.onEdit,
    this.onAgregarActividad,
  });

  final String nombreMateria;
  final double notaAcumulada;
  final double porcentajeEvaluado;
  final List<Actividad> actividades;

  final VoidCallback? onBack;
  final VoidCallback? onEdit;
  final VoidCallback? onAgregarActividad;

  Color get _stateColor {
    if (notaAcumulada >= 3.5) {
      return AppColors.okText;
    }

    if (notaAcumulada >= 3.0) {
      return AppColors.warnText;
    }

    return AppColors.errorText;
  }

  Color get _stateBackground {
    if (notaAcumulada >= 3.5) {
      return AppColors.okBg;
    }

    if (notaAcumulada >= 3.0) {
      return AppColors.warnBg;
    }

    return AppColors.errorBg;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        leading: IconButton(
          onPressed: onBack ?? () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(nombreMateria),
        actions: [
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit),
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ListView(
          children: [
            const SizedBox(height: 8),

            _buildGradeCard(),

            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Actividades evaluadas',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMain,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NewGradeScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    '+ Agregar',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            _buildActivitiesCard(),

            const SizedBox(height: 24),

            _buildWhatDoINeedCard(),

            const SizedBox(height: 90),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: onAgregarActividad,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildGradeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _stateBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            'Nota acumulada',
            style: TextStyle(
              color: _stateColor,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            notaAcumulada.toStringAsFixed(1),
            style: TextStyle(
              color: _stateColor,
              fontSize: 36,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 12),

          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: porcentajeEvaluado.clamp(0, 100) / 100,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.65),
              valueColor: AlwaysStoppedAnimation<Color>(_stateColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivitiesCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: List.generate(
          actividades.length,
          (index) {
            final actividad = actividades[index];

            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                border: index < actividades.length - 1
                    ? const Border(
                        bottom: BorderSide(
                          color: AppColors.border,
                          width: 1,
                        ),
                      )
                    : null,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          actividad.nombre,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textMain,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${actividad.porcentaje.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (actividad.nota != null)
                    Text(
                      actividad.nota!.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMain,
                      ),
                    )
                  else
                    const Text(
                      'Pendiente',
                      style: TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildWhatDoINeedCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondaryLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.calculate,
            size: 20,
            color: AppColors.secondaryDark,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Para pasar con 3.0 necesitas:',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.secondaryDark,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  '4.1 en el examen final',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: AppColors.secondaryDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}