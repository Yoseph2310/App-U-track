import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/settings/app_settings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/decimal_input.dart';
import '../../tasks/services/subject_service.dart';
import '../../tasks/models/subject_model.dart';
class CorteEvaluacion {
  final TextEditingController nombreController;
  final TextEditingController porcentajeController;

  CorteEvaluacion({
    String nombre = '',
    String porcentaje = '',
  })  : nombreController = TextEditingController(text: nombre),
        porcentajeController = TextEditingController(text: porcentaje);

  void dispose() {
    nombreController.dispose();
    porcentajeController.dispose();
  }
}

class SubjectFormScreen extends StatefulWidget {
  const SubjectFormScreen({
    super.key,
    this.onGuardar,
    this.materia,
  });

  final VoidCallback? onGuardar;
  final SubjectModel? materia;

  @override
  State<SubjectFormScreen> createState() => _SubjectFormScreenState();
}

class _SubjectFormScreenState extends State<SubjectFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final SubjectService _subjectService = SubjectService();

  final nombreController = TextEditingController();
  final profesorController = TextEditingController();
  final grupoController = TextEditingController();

  final List<CorteEvaluacion> _cortes = [
    CorteEvaluacion(),
  ];

  @override
  @override
  void initState() {
    super.initState();

    final materia = widget.materia;

    if (materia != null) {
      nombreController.text = materia.name;
      profesorController.text = materia.teacher ?? '';
      grupoController.text = materia.classroom ?? '';

      if (materia.evaluationScheme.isNotEmpty) {
        _cortes.first.dispose();
        _cortes.clear();

        for (final evaluacion in materia.evaluationScheme) {
          _cortes.add(
            CorteEvaluacion(
              nombre: evaluacion['name']?.toString() ?? '',
              porcentaje: evaluacion['percentage']?.toString() ?? '',
            ),
          );
        }
      }
    }
  }


  @override
  void dispose() {
    nombreController.dispose();
    profesorController.dispose();
    grupoController.dispose();

    for (final corte in _cortes) {
      corte.dispose();
    }

    super.dispose();
  }

  double get _totalPorcentaje {
    double total = 0;

    for (final corte in _cortes) {
      total += double.tryParse(
            corte.porcentajeController.text.replaceAll(',', '.'),
          ) ??
          0;
    }

    return total;
  }

  bool get _totalValido {
    return (_totalPorcentaje - 100).abs() < 0.01;
  }

  void _agregarCorte() {
    setState(() {
      _cortes.add(CorteEvaluacion());
    });
  }

  void _eliminarCorte(int index) {
    if (_cortes.length == 1) {
      return;
    }

    setState(() {
      _cortes[index].dispose();
      _cortes.removeAt(index);
    });
  }


  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_totalValido) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr('La suma de los porcentajes debe ser exactamente 100%.', 'The percentages must add up to exactly 100%.'),
          ),
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('Debes iniciar sesión para guardar la materia.', 'You must sign in to save the subject.')),
        ),
      );
      return;
    }

    final materiaExistente = widget.materia;


    final materia = SubjectModel(
      id: materiaExistente?.id,
      name: nombreController.text.trim(),
      color: materiaExistente?.color ?? '#2563EB',
      teacher: profesorController.text.trim(),
      classroom: grupoController.text.trim(),
      currentGrade: materiaExistente?.currentGrade ?? 0.0,
      createdAt: materiaExistente?.createdAt ?? DateTime.now(),
      evaluationScheme: _cortes.map((corte) {
        return {
          'name': corte.nombreController.text.trim(),
          'percentage': double.parse(
            corte.porcentajeController.text.replaceAll(',', '.'),
          ),
        };
      }).toList(),
    );


    try {
      bool guardado;

      if (materiaExistente == null) {
        final subjectId = await _subjectService.createSubject(
          user.uid,
          materia,
        );

        guardado = subjectId != null;
      } else {
        guardado = await _subjectService.updateSubject(
          user.uid,
          materia,
        );
      }

      if (!mounted) return;

      if (guardado) {
        widget.onGuardar?.call();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              materiaExistente == null
                  ? tr('Materia creada correctamente.', 'Subject created successfully.')
                  : tr('Materia actualizada correctamente.', 'Subject updated successfully.'),
            ),
          ),
        );

        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('No se pudo guardar la materia.', 'Could not save the subject.')),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('Ocurrió un error al guardar: $e', 'An error occurred while saving: $e')),
        ),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    final puedeGuardar =
        nombreController.text.trim().isNotEmpty &&
        profesorController.text.trim().isNotEmpty &&
        grupoController.text.trim().isNotEmpty &&
        _totalValido;

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
        ),
        title: Text(
          widget.materia == null ? tr('Nueva materia', 'New subject') : tr('Editar materia', 'Edit subject'),
        ),
        actions: [
          TextButton(
            onPressed: puedeGuardar ? _guardar : null,
            child: Text(
              widget.materia == null ? tr('Guardar', 'Save') : tr('Actualizar', 'Update'),
              style: TextStyle(
                color: puedeGuardar
                    ? AppColors.primary
                    : AppColors.border,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),

      body: Form(
        key: _formKey,
        onChanged: () {
          setState(() {});
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          children: [
            _buildLabel(tr('Nombre de la materia', 'Subject name')),

            const SizedBox(height: 8),

            TextFormField(
              controller: nombreController,
              decoration: const InputDecoration(),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return tr('Ingresa el nombre de la materia', 'Enter the subject name');
                }

                return null;
              },
            ),

            const SizedBox(height: 16),

            _buildLabel(tr('Profesor', 'Teacher')),

            const SizedBox(height: 8),

            TextFormField(
              controller: profesorController,
              decoration: const InputDecoration(),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return tr('Ingresa el profesor', 'Enter the teacher');
                }

                return null;
              },
            ),

            const SizedBox(height: 16),

            _buildLabel(tr('Grupo', 'Group')),

            const SizedBox(height: 8),

            TextFormField(
              controller: grupoController,
              decoration: const InputDecoration(),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return tr('Ingresa el grupo', 'Enter the group');
                }

                return null;
              },
            ),

            const SizedBox(height: 24),

            Text(
              tr('Esquema de evaluación', 'Grading scheme'),
              style: TextStyle(
                color: AppColors.textMain,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              tr('Agrega los cortes o actividades que componen la nota final', 'Add the terms or activities that make up the final grade'),
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),

            const SizedBox(height: 16),

            ...List.generate(
              _cortes.length,
              (index) => _buildCorte(index),
            ),

            const SizedBox(height: 8),

            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: _agregarCorte,
                child: Text(
                  tr('+ Agregar corte', '+ Add term'),
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!_totalValido)
                    Icon(
                      Icons.error_outline,
                      size: 18,
                      color: AppColors.errorText,
                    ),

                  const SizedBox(width: 4),

                  Text(
                    tr('Total: ${_totalPorcentaje.toStringAsFixed(0)}%', 'Total: ${_totalPorcentaje.toStringAsFixed(0)}%'),
                    style: TextStyle(
                      color: _totalValido
                          ? AppColors.okText
                          : AppColors.errorText,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String texto) {
    return Text(
      texto,
      style: TextStyle(
        color: AppColors.textSecondary,
        fontSize: 13,
      ),
    );
  }

  Widget _buildCorte(int index) {
    final corte = _cortes[index];

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 6,
            child: TextField(
              controller: corte.nombreController,
              decoration: InputDecoration(
                hintText: tr('Nombre', 'Name'),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            flex: 3,
            child: TextField(
              controller: corte.porcentajeController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: DecimalInput.formatters,
              decoration: const InputDecoration(
                hintText: '0',
                suffixText: '%',
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),

          const SizedBox(width: 4),

          IconButton(
            onPressed: _cortes.length > 1
                ? () => _eliminarCorte(index)
                : null,
            icon: const Icon(
              Icons.delete_outline,
              size: 20,
            ),
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}class NewGradeScreen extends StatefulWidget {
  final VoidCallback? onGuardar;

  const NewGradeScreen({
    super.key,
    this.onGuardar,
  });

  @override
  State<NewGradeScreen> createState() => _NewGradeScreenState();
}

class _NewGradeScreenState extends State<NewGradeScreen> {
  String? _actividadSeleccionada;

  final TextEditingController _notaController =
  TextEditingController();

  final List<String> _actividades = [
    tr('Parcial 1', 'Midterm 1'),
    tr('Parcial 2', 'Midterm 2'),
    tr('Taller', 'Workshop'),
    tr('Quiz', 'Quiz'),
    tr('Examen final', 'Final exam'),
  ];

  bool get _esValido {
    final nota = double.tryParse(
      _notaController.text.replaceAll(',', '.'),
    );

    return _actividadSeleccionada != null &&
        nota != null &&
        nota >= 0 &&
        nota <= 5;
  }

  @override
  void dispose() {
    _notaController.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_esValido) return;

    widget.onGuardar?.call();

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
        ),
        title: Text(tr('Nueva nota', 'New grade')),
        actions: [
          TextButton(
            onPressed: _esValido ? _guardar : null,
            child: Text(
              tr('Guardar', 'Save'),
              style: TextStyle(
                color: _esValido
                    ? AppColors.primary
                    : AppColors.border,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            Text(
              tr('Actividad', 'Activity'),
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: 8),

            DropdownButtonFormField<String>(
              value: _actividadSeleccionada,
              decoration: InputDecoration(
                hintText: tr('Selecciona una actividad', 'Select an activity'),
              ),
              items: _actividades.map((actividad) {
                return DropdownMenuItem<String>(
                  value: actividad,
                  child: Text(actividad),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _actividadSeleccionada = value;
                });
              },
            ),

            const SizedBox(height: 24),

            Text(
              tr('Nota', 'Grade'),
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: 8),

            TextField(
              controller: _notaController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: DecimalInput.formatters,
              onChanged: (_) {
                setState(() {});
              },
              decoration: InputDecoration(
                hintText: tr('Ej. 4.2', 'e.g. 4.2'),
                suffixText: '/ 5.0',
              ),
            ),

            const SizedBox(height: 8),

            Text(
              tr('Ingresa una nota entre 0.0 y 5.0', 'Enter a grade between 0.0 and 5.0'),
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}