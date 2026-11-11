
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/decimal_input.dart';
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

  /// Clave para recordar si el usuario pidió no volver a ver el aviso.
  static const _hideNotesTipKey = 'hide_activity_notes_tip';

  /// Actividades que ya tienen nota. Las pendientes (sin nota) no cuentan
  /// para la nota acumulada ni para el porcentaje evaluado.
  List<GradeModel> get _gradedGrades =>
      _grades.where((grade) => grade.hasScore).toList();

  double get _porcentajeEvaluado {
    if (widget.esquemaEvaluacion.isEmpty) {
      return _gradedGrades.fold<double>(
        0,
            (total, grade) => total + grade.weight,
      );
    }

    double total = 0;

    for (final corte in widget.esquemaEvaluacion) {
      final nombre = corte['name']?.toString() ?? '';
      final porcentaje =
          (corte['percentage'] as num?)?.toDouble() ?? 0.0;

      final tieneActividades = _gradedGrades.any(
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
      return _gradedGrades.fold<double>(
        0,
            (total, grade) => total + grade.score! * grade.weight,
      ) /
          100;
    }

    double nota = 0;

    for (final corte in widget.esquemaEvaluacion) {
      final nombre = corte['name']?.toString() ?? '';
      final porcentaje =
          (corte['percentage'] as num?)?.toDouble() ?? 0.0;

      final actividades = _gradedGrades.where(
            (grade) =>
        grade.cutName == nombre ||
            (grade.cutName == null && grade.name == nombre),
      ).toList();

      if (actividades.isEmpty) continue;

      final promedio =
          actividades.fold<double>(
            0,
                (total, grade) => total + grade.score!,
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
    // Muestra el aviso de las observaciones apenas se abre la pantalla.
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowNotesTip());
  }

  /// Muestra el aviso cada vez que se entra, salvo que el usuario haya
  /// elegido "No volver a mostrar".
  Future<void> _maybeShowNotesTip() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_hideNotesTipKey) ?? false) return;
    } catch (_) {
      // Si no se pueden leer las preferencias, se muestra igual.
    }
    if (!mounted) return;
    await _showNotesTip(allowHide: true);
  }

  /// Explica que las observaciones se ven tocando la actividad.
  /// [allowHide] agrega el botón "No volver a mostrar".
  Future<void> _showNotesTip({bool allowHide = false}) async {
    final hide = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        icon: const Icon(Icons.help_outline, color: AppColors.primary),
        title: const Text('Observaciones de las actividades'),
        content: const Text(
          'Las observaciones de cada nota están ocultas. Para verlas, toca '
          'la actividad y se abrirán en una ventana.',
        ),
        actions: [
          if (allowHide)
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('No volver a mostrar'),
            ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    if (hide == true) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_hideNotesTipKey, true);
      } catch (_) {}
    }
  }

  /// Ventana con el detalle de una actividad, incluidas sus observaciones.
  Future<void> _showGradeDetail(
    GradeModel grade, {
    Map<String, dynamic>? esquema,
  }) async {
    final edit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(grade.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow(
              'Nota',
              grade.hasScore ? _formatScore(grade.score!) : 'Pendiente',
            ),
            if (esquema == null)
              _detailRow('Porcentaje', '${_formatNumber(grade.weight)}%'),
            const SizedBox(height: 12),
            const Text(
              'Observaciones',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              grade.notes ?? 'Sin observaciones.',
              style: TextStyle(
                fontSize: 15,
                color: grade.notes == null
                    ? AppColors.textSecondary
                    : AppColors.textMain,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Editar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );

    if (edit == true && mounted) {
      await _showGradeForm(existing: grade, esquema: esquema);
    }
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textMain,
            ),
          ),
        ],
      ),
    );
  }

  /// Muestra la nota con los decimales que tenga (hasta 3), mínimo 1.
  static String _formatScore(double score) {
    final text = _formatNumber(score);
    return text.contains('.') ? text : '$text.0';
  }

  /// Quita ceros sobrantes: 4.500 → 4.5, 30.0 → 30.
  static String _formatNumber(double value) {
    var text = value.toStringAsFixed(3);
    text = text.replaceFirst(RegExp(r'0+$'), '');
    return text.replaceFirst(RegExp(r'\.$'), '');
  }

  /// Texto de la nota en la lista: la nota o "—" si está pendiente.
  Widget _scoreLabel(GradeModel grade) {
    return Text(
      grade.hasScore ? _formatScore(grade.score!) : '—',
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: grade.hasScore ? AppColors.textMain : AppColors.textSecondary,
      ),
    );
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
    // El diálogo maneja sus propios campos de texto y los libera él mismo
    // cuando termina de cerrarse. Antes se liberaban aquí, mientras la
    // animación de cierre aún los usaba, y al pulsar "Cancelar" la app fallaba.
    final data = await showDialog<_GradeFormData>(
      context: context,
      builder: (_) => _GradeFormDialog(
        existing: existing,
        esquema: esquema,
        otherGrades: _grades,
      ),
    );

    if (data == null || !mounted) return;

    final userId = _userId;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión.')),
      );
      return;
    }

    final grade = GradeModel(
      id: existing?.id,
      subjectId: widget.subjectId,
      name: data.name,
      score: data.score,
      weight: esquema == null ? data.weight : 100.0,
      dateAdded: existing?.dateAdded ?? DateTime.now(),
      notes: data.notes,
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
        if (id == null) throw Exception('No se pudo guardar la nota.');
      } else {
        final success = await _gradeService.updateGrade(
          userId,
          widget.subjectId,
          grade,
        );
        if (!success) throw Exception('No se pudo actualizar la nota.');
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
          const SnackBar(content: Text('No se pudo guardar la calificación.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
                const Text(
                  'Actividades evaluadas',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMain,
                  ),
                ),
                IconButton(
                  tooltip: '¿Cómo ver las observaciones?',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _showNotesTip(),
                  icon: const Icon(
                    Icons.help_outline,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
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
                        subtitle: grade.hasScore
                            ? null
                            : const Text('Pendiente'),
                        onTap: () =>
                            _showGradeDetail(grade, esquema: corte),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _scoreLabel(grade),
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
            subtitle: Text(
              grade.hasScore
                  ? '${_formatNumber(grade.weight)}%'
                  : '${_formatNumber(grade.weight)}% · Pendiente',
            ),
            onTap: () => _showGradeDetail(grade),
            trailing: _scoreLabel(grade),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildWhatDoINeedCard() {
    final remaining = 100 - _porcentajeEvaluado;
    final needed = _notaNecesaria;

    String message;

    if (_gradedGrades.isEmpty) {
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

/// Datos que devuelve el diálogo de nota al pulsar "Guardar".
class _GradeFormData {
  const _GradeFormData({
    required this.name,
    required this.score,
    required this.weight,
    this.notes,
  });

  final String name;
  final double? score;
  final double weight;
  final String? notes;
}

/// Diálogo para crear o editar una nota. Es dueño de sus controladores
/// y los libera en dispose(), cuando ya no se están dibujando.
class _GradeFormDialog extends StatefulWidget {
  const _GradeFormDialog({
    this.existing,
    this.esquema,
    required this.otherGrades,
  });

  final GradeModel? existing;
  final Map<String, dynamic>? esquema;
  final List<GradeModel> otherGrades;

  @override
  State<_GradeFormDialog> createState() => _GradeFormDialogState();
}

class _GradeFormDialogState extends State<_GradeFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _scoreController;
  late final TextEditingController _weightController;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _scoreController =
        TextEditingController(text: existing?.score?.toString() ?? '');
    _weightController = TextEditingController(
      text: existing?.weight.toString() ??
          widget.esquema?['percentage']?.toString() ??
          '',
    );
    _notesController = TextEditingController(text: existing?.notes ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _scoreController.dispose();
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final notes = _notesController.text.trim();
    Navigator.pop(
      context,
      _GradeFormData(
        name: _nameController.text.trim(),
        // Vacía = actividad pendiente, sin nota todavía.
        score: DecimalInput.parse(_scoreController.text),
        weight: DecimalInput.parse(_weightController.text) ?? 100,
        notes: notes.isEmpty ? null : notes,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(widget.existing == null ? 'Nueva nota' : 'Editar nota'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Actividad',
                  hintText: 'Ej. Parcial 1',
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Escribe el nombre de la actividad'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _scoreController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: DecimalInput.gradeFormatters,
                decoration: const InputDecoration(
                  labelText: 'Nota (opcional)',
                  hintText: 'Ej. 4.25',
                  helperText: 'Déjala vacía si aún no tienes la nota',
                  suffixText: '/ 5.0',
                ),
                validator: (value) {
                  final text = (value ?? '').trim();
                  if (text.isEmpty) return null; // la nota es opcional
                  final score = DecimalInput.parse(text);
                  if (score == null || score < 0 || score > 5) {
                    return 'Ingresa una nota entre 0 y 5';
                  }
                  return null;
                },
              ),
              if (widget.esquema == null)
                TextFormField(
                  controller: _weightController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: DecimalInput.formatters,
                  decoration: const InputDecoration(
                    labelText: 'Porcentaje de la materia',
                    suffixText: '%',
                  ),
                  validator: (value) {
                    final weight = DecimalInput.parse(value ?? '');
                    if (weight == null || weight <= 0 || weight > 100) {
                      return 'Ingresa un porcentaje mayor que 0 y hasta 100';
                    }
                    final otherWeight = widget.otherGrades
                        .where((grade) => grade.id != widget.existing?.id)
                        .fold<double>(0, (total, g) => total + g.weight);
                    if (otherWeight + weight > 100.01) {
                      return 'El total de los porcentajes supera el 100%';
                    }
                    return null;
                  },
                ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
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
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
