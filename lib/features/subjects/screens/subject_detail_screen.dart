
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../tasks/models/grade_model.dart';
import '../../tasks/services/grade_service.dart';

class SubjectDetailScreen extends StatefulWidget {
  const SubjectDetailScreen({
    super.key,
    required this.subjectId,
    required this.nombreMateria,
    required this.notaAcumulada,
    required this.esquemaEvaluacion,
  });

  final String subjectId;
  final String nombreMateria;
  final double notaAcumulada;
  final List<Map<String, dynamic>> esquemaEvaluacion;

  @override
  State<SubjectDetailScreen> createState() =>
      _SubjectDetailScreenState();
}

class _SubjectDetailScreenState extends State<SubjectDetailScreen> {
  final GradeService _gradeService = GradeService();

  List<GradeModel> _grades = [];
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  double get _porcentajeEvaluado {
    if (widget.esquemaEvaluacion.isEmpty) {
      return _grades.fold<double>(
        0,
            (total, grade) => total + grade.weight,
      );
    }

    double total = 0;

    for (final corte in widget.esquemaEvaluacion) {
      final nombre = corte['name']?.toString() ?? '';
      final porcentaje =
          (corte['percentage'] as num?)?.toDouble() ?? 0.0;

      final tieneActividades = _grades.any(
            (grade) =>
        grade.cutName == nombre ||
            (grade.cutName == null && grade.name == nombre),
      );

      if (tieneActividades) {
        total += porcentaje;
      }
    }

    return total;
  }

// Nota acumulada sobre 5, calculada por cortes.
  double get _notaAcumulada {
    if (widget.esquemaEvaluacion.isEmpty) {
      return _grades.fold<double>(
        0,
            (total, grade) => total + grade.score * grade.weight,
      ) /
          100;
    }

    double nota = 0;

    for (final corte in widget.esquemaEvaluacion) {
      final nombre = corte['name']?.toString() ?? '';
      final porcentaje =
          (corte['percentage'] as num?)?.toDouble() ?? 0.0;

      final actividades = _grades.where(
            (grade) =>
        grade.cutName == nombre ||
            (grade.cutName == null && grade.name == nombre),
      ).toList();

      if (actividades.isEmpty) continue;

      final promedio =
          actividades.fold<double>(
            0,
                (total, grade) => total + grade.score,
          ) /
              actividades.length;

      nota += promedio * porcentaje / 100;
    }

    return nota;
  }

// Nota promedio necesaria en los cortes pendientes
// para alcanzar una nota final de 3.0 sobre 5.
  double? get _notaNecesaria {
    final restante = 100 - _porcentajeEvaluado;

    if (restante <= 0) return null;

    return (3.0 - _notaAcumulada) * 100 / restante;
  }


  Color get _stateColor {
    if (_notaAcumulada >= 3.5) return AppColors.okText;
    if (_notaAcumulada >= 3.0) return AppColors.warnText;
    return AppColors.errorText;
  }

  Color get _stateBackground {
    if (_notaAcumulada >= 3.5) return AppColors.okBg;
    if (_notaAcumulada >= 3.0) return AppColors.warnBg;
    return AppColors.errorBg;
  }

  @override
  void initState() {
    super.initState();
    _loadGrades();
  }

  Future<void> _loadGrades() async {
    final userId = _userId;

    if (userId == null) {
      setState(() {
        _errorMessage = 'Debes iniciar sesión para ver las calificaciones.';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final grades = await _gradeService.getGrades(
        userId,
        widget.subjectId,
      );

      if (!mounted) return;

      setState(() {
        _grades = grades;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'No se pudieron cargar las calificaciones.';
        _isLoading = false;
      });
    }
  }

  Future<void> _showGradeForm({
    GradeModel? existing,
    Map<String, dynamic>? esquema,
  }) async {
    final nameController = TextEditingController(
      text: existing?.name ?? '',
    );

    final scoreController = TextEditingController(
      text: existing?.score.toString() ?? '',
    );

    final weightController = TextEditingController(
      text: existing?.weight.toString() ??
          esquema?['percentage']?.toString() ??
          '',
    );

    final notesController = TextEditingController(
      text: existing?.notes ?? '',
    );
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(existing == null ? 'Nueva nota' : 'Editar nota'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Actividad',
                    hintText: 'Ej. Parcial 1',
                  ),
                  validator: (value) =>
                  value == null || value.trim().isEmpty
                      ? 'Escribe el nombre de la actividad'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: scoreController,
                  keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Nota',
                    hintText: 'Ej. 4.2',
                    suffixText: '/ 5.0',
                  ),
                  validator: (value) {
                    final score = double.tryParse(
                      (value ?? '').replaceAll(',', '.'),
                    );
                    if (score == null || score < 0 || score > 5) {
                      return 'Ingresa una nota entre 0 y 5';
                    }
                    return null;
                  },
                ),

              if (esquema == null)
          TextFormField(
          controller: weightController,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
          ),
          decoration: const InputDecoration(
            labelText: 'Porcentaje de la materia',
            suffixText: '%',
          ),
          validator: (value) {
            final weight = double.tryParse(
              (value ?? '').replaceAll(',', '.'),
            );

            if (weight == null ||
                weight <= 0 ||
                weight > 100) {
              return 'Ingresa un porcentaje mayor que 0 y hasta 100';
            }

            final otherWeight = _grades
                .where((grade) => grade.id != existing?.id)
                .fold<double>(
              0,
                  (total, grade) => total + grade.weight,
            );

            if (otherWeight + weight > 100.01) {
              return 'El total de los porcentajes supera el 100%';
            }

            return null;
          },
        ),
        const SizedBox(height: 12),

                TextFormField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Observaciones (opcional)',
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        actions: [

          TextButton(
            onPressed: () {
              FocusScope.of(dialogContext).unfocus();
              Navigator.of(dialogContext).pop(false);
            },
            child: const Text('Cancelar'),
          ),

          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      final userId = _userId;

      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debes iniciar sesión.')),
        );
      } else {
        final score = double.parse(
          scoreController.text.replaceAll(',', '.'),
        );
        final weight = esquema == null
            ? double.parse(weightController.text.replaceAll(',', '.'))
            : 100.0;

        final grade = GradeModel(
          id: existing?.id,
          subjectId: widget.subjectId,
          name: nameController.text.trim(),
          score: score,
          weight: weight,
          dateAdded: existing?.dateAdded ?? DateTime.now(),
          notes: notesController.text.trim().isEmpty
              ? null
              : notesController.text.trim(),
          cutName: esquema?['name']?.toString() ?? existing?.cutName,
        );

        setState(() => _isSaving = true);

        try {
          if (existing == null) {
            final id = await _gradeService.createGrade(
              userId,
              widget.subjectId,
              grade,
            );

            if (id == null) {
              throw Exception('No se pudo guardar la nota.');
            }
          } else {
            final success = await _gradeService.updateGrade(
              userId,
              widget.subjectId,
              grade,
            );

            if (!success) {
              throw Exception('No se pudo actualizar la nota.');
            }
          }

          await _loadGrades();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Calificación guardada.')),
            );
          }
        } catch (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No se pudo guardar la calificación.'),
              ),
            );
          }
        } finally {
          if (mounted) setState(() => _isSaving = false);
        }
      }
    }

    nameController.dispose();
    scoreController.dispose();
    weightController.dispose();
    notesController.dispose();
  }

  Future<void> _deleteGrade(GradeModel grade) async {
    if (grade.id == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar calificación'),
        content: Text('¿Deseas eliminar "${grade.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final userId = _userId;
    if (userId == null) return;

    final success = await _gradeService.deleteGrade(
      userId,
      widget.subjectId,
      grade.id!,
    );

    if (!mounted) return;

    if (success) {
      await _loadGrades();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo eliminar la calificación.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(widget.nombreMateria),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_errorMessage!),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _loadGrades,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        )
            : ListView(
          children: [
            const SizedBox(height: 8),
            _buildGradeCard(),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Actividades evaluadas',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMain,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _isSaving ? null : _showGradeForm,
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
        onPressed: _isSaving ? null : _showGradeForm,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: _isSaving
            ? const CircularProgressIndicator(color: Colors.white)
            : const Icon(Icons.add),
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
            style: TextStyle(color: _stateColor, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            _notaAcumulada.toStringAsFixed(2),
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
              value: (_porcentajeEvaluado / 100).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.65),
              valueColor: AlwaysStoppedAnimation<Color>(_stateColor),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_porcentajeEvaluado.toStringAsFixed(0)}% evaluado',
            style: TextStyle(color: _stateColor, fontSize: 12),
          ),
        ],
      ),
    );
  }



  Widget _buildActivitiesCard() {
    if (widget.esquemaEvaluacion.isNotEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: List.generate(
            widget.esquemaEvaluacion.length,
                (index) {
              final corte = widget.esquemaEvaluacion[index];
              final nombre = corte['name']?.toString() ?? '';
              final porcentaje =
              (corte['percentage'] as num).toDouble();

              final actividades = _grades.where((grade) {
                return grade.cutName == nombre ||
                    (grade.cutName == null && grade.name == nombre);
              }).toList();

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  border: index <
                      widget.esquemaEvaluacion.length - 1
                      ? const Border(
                    bottom: BorderSide(
                      color: AppColors.border,
                    ),
                  )
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            nombre,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMain,
                            ),
                          ),
                        ),
                        Text(
                          '${porcentaje.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (actividades.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          'Todavía no hay actividades en este corte.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),

                    ...actividades.map((grade) {
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(grade.name),
                        subtitle: grade.notes == null
                            ? null
                            : Text(grade.notes!),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              grade.score.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textMain,
                              ),
                            ),
                            PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _showGradeForm(
                                    existing: grade,
                                    esquema: corte,
                                  );
                                } else if (value == 'delete') {
                                  _deleteGrade(grade);
                                }
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Editar actividad'),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Eliminar actividad'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: _isSaving
                            ? null
                            : () => _showGradeForm(esquema: corte),
                        icon: const Icon(Icons.add),
                        label: const Text('Agregar actividad'),
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

    if (_grades.isEmpty) {
      return const Text(
        'Todavía no has registrado calificaciones para esta materia.',
        textAlign: TextAlign.center,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: _grades.map((grade) {
          return ListTile(
            title: Text(grade.name),
            subtitle: Text('${grade.weight.toStringAsFixed(0)}%'),
            trailing: Text(grade.score.toStringAsFixed(1)),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildWhatDoINeedCard() {
    final remaining = 100 - _porcentajeEvaluado;
    final needed = _notaNecesaria;

    String message;

    if (_grades.isEmpty) {
      message = 'Registra tus calificaciones para calcular la nota necesaria.';
    } else if (remaining <= 0) {
      message = _notaAcumulada >= 3.0
          ? 'Ya alcanzaste la nota mínima de 3.0.'
          : 'Ya está evaluado el 100% y no alcanzaste el 3.0.';
    } else if (needed != null && needed > 5.0) {
      message = 'No es posible llegar a 3.0 con el porcentaje restante.';
    } else if (needed != null && needed <= 0) {
      message = 'Ya tienes suficiente para alcanzar el 3.0.';
    } else {
      message =
      'Necesitas ${needed!.toStringAsFixed(2)} en el ${remaining.toStringAsFixed(0)}% restante.';
    }

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
                  'Cálculo para alcanzar 3.0',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.secondaryDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 16,
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
