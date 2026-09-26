import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

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
  });

  final VoidCallback? onGuardar;

  @override
  State<SubjectFormScreen> createState() => _SubjectFormScreenState();
}

class _SubjectFormScreenState extends State<SubjectFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final nombreController = TextEditingController();
  final profesorController = TextEditingController();
  final grupoController = TextEditingController();

  final List<CorteEvaluacion> _cortes = [
    CorteEvaluacion(),
  ];

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

  void _guardar() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_totalValido) {
      return;
    }

    widget.onGuardar?.call();
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
        title: const Text('Nueva materia'),
        actions: [
          TextButton(
            onPressed: puedeGuardar ? _guardar : null,
            child: Text(
              'Guardar',
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
            _buildLabel('Nombre de la materia'),

            const SizedBox(height: 8),

            TextFormField(
              controller: nombreController,
              decoration: const InputDecoration(),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ingresa el nombre de la materia';
                }

                return null;
              },
            ),

            const SizedBox(height: 16),

            _buildLabel('Profesor'),

            const SizedBox(height: 8),

            TextFormField(
              controller: profesorController,
              decoration: const InputDecoration(),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ingresa el profesor';
                }

                return null;
              },
            ),

            const SizedBox(height: 16),

            _buildLabel('Grupo'),

            const SizedBox(height: 8),

            TextFormField(
              controller: grupoController,
              decoration: const InputDecoration(),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ingresa el grupo';
                }

                return null;
              },
            ),

            const SizedBox(height: 24),

            const Text(
              'Esquema de evaluación',
              style: TextStyle(
                color: AppColors.textMain,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              'Agrega los cortes o actividades que componen la nota final',
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
                child: const Text(
                  '+ Agregar corte',
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
                    const Icon(
                      Icons.error_outline,
                      size: 18,
                      color: AppColors.errorText,
                    ),

                  const SizedBox(width: 4),

                  Text(
                    'Total: ${_totalPorcentaje.toStringAsFixed(0)}%',
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
      style: const TextStyle(
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
              decoration: const InputDecoration(
                hintText: 'Nombre',
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
    'Parcial 1',
    'Parcial 2',
    'Taller',
    'Quiz',
    'Examen final',
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
        title: const Text('Nueva nota'),
        actions: [
          TextButton(
            onPressed: _esValido ? _guardar : null,
            child: Text(
              'Guardar',
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

            const Text(
              'Actividad',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: 8),

            DropdownButtonFormField<String>(
              value: _actividadSeleccionada,
              decoration: const InputDecoration(
                hintText: 'Selecciona una actividad',
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

            const Text(
              'Nota',
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
              onChanged: (_) {
                setState(() {});
              },
              decoration: const InputDecoration(
                hintText: 'Ej. 4.2',
                suffixText: '/ 5.0',
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Ingresa una nota entre 0.0 y 5.0',
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