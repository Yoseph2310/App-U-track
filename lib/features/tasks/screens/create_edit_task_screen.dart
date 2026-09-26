import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/task_model.dart';
import '../models/subject_model.dart';
import '../services/task_service.dart';
import '../services/subject_service.dart';

/// Pantalla 7 — Registrar trabajo/actividad
/// Según especificación en docs/u-track-especificaciones-ui.md
class CreateEditTaskScreen extends StatefulWidget {
  final bool isEditing;
  final TaskModel? task;
  final String userId;

  const CreateEditTaskScreen({
    super.key,
    this.isEditing = false,
    this.task,
    required this.userId,
  });

  @override
  State<CreateEditTaskScreen> createState() => _CreateEditTaskScreenState();
}

class _CreateEditTaskScreenState extends State<CreateEditTaskScreen> {
  late TextEditingController titleController;
  late TextEditingController notesController;

  SubjectModel? selectedSubject;
  List<SubjectModel> subjects = [];
  bool isLoadingSubjects = true;

  ActivityType activityType = ActivityType.tarea;
  DateTime? dueDate;
  TimeOfDay? dueTime;

  bool reminderEnabled = false;
  ReminderTiming reminderTiming = ReminderTiming.unDia;

  bool isSaving = false;

  final TaskService _taskService = TaskService();
  final SubjectService _subjectService = SubjectService();

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.task?.title ?? '');
    notesController = TextEditingController(
      text: widget.task?.description ?? '',
    );
    activityType = widget.task?.activityType ?? ActivityType.tarea;
    dueDate = widget.task?.dueDate;
    dueTime = widget.task?.dueTime;
    reminderEnabled = widget.task?.reminderEnabled ?? false;
    reminderTiming = widget.task?.reminderTiming ?? ReminderTiming.unDia;
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    final loaded = await _subjectService.getSubjects(widget.userId);
    setState(() {
      subjects = loaded;
      isLoadingSubjects = false;
      if (widget.task != null) {
        try {
          selectedSubject = subjects.firstWhere(
            (s) => s.id == widget.task!.subjectId,
          );
        } catch (_) {
          selectedSubject = null;
        }
      }
    });
  }

  bool get isFormValid {
    return titleController.text.trim().isNotEmpty &&
        selectedSubject != null &&
        dueDate != null;
  }

  @override
  void dispose() {
    titleController.dispose();
    notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => dueDate = picked);
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: dueTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => dueTime = picked);
    }
  }

  String _formatTime12h(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Future<void> _save() async {
    if (!isFormValid) return;

    setState(() => isSaving = true);

    try {
      if (widget.isEditing && widget.task != null) {
        final updated = widget.task!.copyWith(
          title: titleController.text.trim(),
          description: notesController.text.trim(),
          subjectId: selectedSubject!.id,
          subjectName: selectedSubject!.name,
          activityType: activityType,
          dueDate: dueDate,
          dueTime: dueTime,
          reminderEnabled: reminderEnabled,
          reminderTiming: reminderEnabled ? reminderTiming : null,
        );
        final ok = await _taskService.updateTask(widget.userId, updated);
        if (ok && mounted) {
          Navigator.pop(context, updated);
        }
      } else {
        final newTask = TaskModel(
          title: titleController.text.trim(),
          description: notesController.text.trim(),
          subjectId: selectedSubject!.id!,
          subjectName: selectedSubject!.name,
          activityType: activityType,
          dueDate: dueDate!,
          dueTime: dueTime,
          reminderEnabled: reminderEnabled,
          reminderTiming: reminderEnabled ? reminderTiming : null,
          createdAt: DateTime.now(),
        );
        final id = await _taskService.createTask(widget.userId, newTask);
        if (id != null && mounted) {
          Navigator.pop(context, newTask.copyWith(id: id));
        }
      }
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textMain),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Nueva actividad',
          style: TextStyle(
            color: AppColors.textMain,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: isFormValid && !isSaving ? _save : null,
            child: Text(
              'Guardar',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: isFormValid ? AppColors.primary : AppColors.border,
              ),
            ),
          ),
        ],
      ),
      body: isSaving
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _fieldLabel('Título de la actividad'),
                  _textInput(
                    controller: titleController,
                    hint: 'Ej. Resolver ejercicios 1-10',
                  ),
                  const SizedBox(height: 16),
                  _fieldLabel('Materia'),
                  _subjectDropdown(),
                  const SizedBox(height: 16),
                  _fieldLabel('Tipo'),
                  _activityTypeChips(),
                  const SizedBox(height: 16),
                  _fieldLabel('Fecha límite'),
                  _datePickerField(),
                  const SizedBox(height: 16),
                  _fieldLabel('Hora (opcional)'),
                  _timePickerField(),
                  const SizedBox(height: 16),
                  _fieldLabel('Notas adicionales (opcional)'),
                  _textInput(
                    controller: notesController,
                    hint: 'Agregar detalles',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  _reminderToggle(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _textInput({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      onChanged: (_) => setState(() {}),
      style: const TextStyle(color: AppColors.textMain, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.6)),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }

  Widget _subjectDropdown() {
    if (isLoadingSubjects) {
      return const SizedBox(
        height: 48,
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
        ),
      );
    }

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.menu_book, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<SubjectModel>(
                value: selectedSubject,
                isExpanded: true,
                hint: const Text(
                  'Selecciona una materia',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
                items: subjects.map((subject) {
                  return DropdownMenuItem(
                    value: subject,
                    child: Text(
                      subject.name,
                      style: const TextStyle(
                        color: AppColors.textMain,
                        fontSize: 14,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => selectedSubject = value);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _activityTypeChips() {
    return Row(
      children: ActivityType.values.map((type) {
        final isSelected = activityType == type;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => setState(() => activityType = type),
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                ),
              ),
              child: Text(
                type.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _datePickerField() {
    return GestureDetector(
      onTap: () => _selectDate(context),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 20, color: AppColors.textSecondary),
            const SizedBox(width: 10),
            Text(
              dueDate != null
                  ? '${dueDate!.day}/${dueDate!.month}/${dueDate!.year}'
                  : 'Selecciona fecha',
              style: TextStyle(
                fontSize: 14,
                color: dueDate != null
                    ? AppColors.textMain
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timePickerField() {
    return GestureDetector(
      onTap: () => _selectTime(context),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.schedule, size: 20, color: AppColors.textSecondary),
            const SizedBox(width: 10),
            Text(
              dueTime != null ? _formatTime12h(dueTime!) : 'Sin hora específica',
              style: TextStyle(
                fontSize: 14,
                color: dueTime != null
                    ? AppColors.textMain
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _reminderToggle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recordarme antes de la entrega',
              style: TextStyle(fontSize: 14, color: AppColors.textMain),
            ),
            Switch(
              value: reminderEnabled,
              activeColor: AppColors.primary,
              onChanged: (value) => setState(() => reminderEnabled = value),
            ),
          ],
        ),
        if (reminderEnabled) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<ReminderTiming>(
                value: reminderTiming,
                isExpanded: true,
                items: ReminderTiming.values.map((timing) {
                  return DropdownMenuItem(
                    value: timing,
                    child: Text(
                      'Avisarme ${timing.label}',
                      style: const TextStyle(
                        color: AppColors.textMain,
                        fontSize: 14,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => reminderTiming = value);
                  }
                },
              ),
            ),
          ),
        ],
      ],
    );
  }
}
