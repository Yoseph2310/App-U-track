import 'package:flutter/material.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/decimal_input.dart';

/// Fila de actividad dentro de la calculadora.
/// Si [scoreController] está vacío, esta es la actividad pendiente
/// a la que se le calcula la nota necesaria.
class _ActivityRow {
  final TextEditingController nameController;
  final TextEditingController weightController;
  final TextEditingController scoreController;

  _ActivityRow()
      : nameController = TextEditingController(),
        weightController = TextEditingController(),
        scoreController = TextEditingController();

  void dispose() {
    nameController.dispose();
    weightController.dispose();
    scoreController.dispose();
  }
}

/// Pantalla 8 — Calculadora de notas independiente
/// Según especificación en docs/u-track-especificaciones-ui.md
class GradeCalculatorScreen extends StatefulWidget {
  const GradeCalculatorScreen({super.key});

  @override
  State<GradeCalculatorScreen> createState() => _GradeCalculatorScreenState();
}

class _GradeCalculatorScreenState extends State<GradeCalculatorScreen> {
  final List<_ActivityRow> rows = [];
  final TextEditingController targetGradeController = TextEditingController();

  // Solo el indicador de "Total X%" necesita reaccionar mientras se escribe.
  // Usamos un ValueNotifier para repintar solo ese widget, en vez de
  // reconstruir toda la pantalla en cada tecla (eso era lo que la hacía
  // sentir lenta cuando el teclado sube y baja).
  final ValueNotifier<double> totalWeightNotifier = ValueNotifier<double>(0);

  double? result;
  bool isReachable = true;
  bool hasCalculated = false;

  @override
  void initState() {
    super.initState();
    _addRow();
    _addRow();
  }

  @override
  void dispose() {
    for (final row in rows) {
      row.dispose();
    }
    targetGradeController.dispose();
    totalWeightNotifier.dispose();
    super.dispose();
  }

  void _recalculateTotalWeight() {
    double sum = 0;
    for (final row in rows) {
      sum += DecimalInput.parse(row.weightController.text) ?? 0;
    }
    totalWeightNotifier.value = sum;
  }

  void _addRow() {
    setState(() {
      rows.add(_ActivityRow());
      hasCalculated = false;
    });
    _recalculateTotalWeight();
  }

  void _removeRow(int index) {
    setState(() {
      rows[index].dispose();
      rows.removeAt(index);
      hasCalculated = false;
    });
    _recalculateTotalWeight();
  }

  void _calculate() {
    final target = DecimalInput.parse(targetGradeController.text);
    if (target == null) {
      _showMessage(
        tr(
          'Ingresa la nota que quieres alcanzar',
          'Enter the grade you want to reach',
        ),
      );
      return;
    }
    if (target < 0 || target > 5) {
      _showMessage(
        tr(
          'La nota que quieres alcanzar debe estar entre 0 y 5',
          'The grade you want to reach must be between 0 and 5',
        ),
      );
      return;
    }

    // Cada fila: porcentaje entre 0 y 100, y nota (si la tiene) entre 0 y 5.
    for (final row in rows) {
      final weightText = row.weightController.text.trim();
      final weight = DecimalInput.parse(weightText);
      if (weightText.isEmpty || weight == null || weight <= 0 || weight > 100) {
        _showMessage(
          tr(
            'Cada porcentaje debe ser un número mayor a 0 y hasta 100',
            'Each percentage must be a number greater than 0 and up to 100',
          ),
        );
        return;
      }
      final scoreText = row.scoreController.text.trim();
      if (scoreText.isNotEmpty) {
        final score = DecimalInput.parse(scoreText);
        if (score == null || score < 0 || score > 5) {
          _showMessage(
            tr(
              'Cada nota debe ser un número entre 0 y 5',
              'Each grade must be a number between 0 and 5',
            ),
          );
          return;
        }
      }
    }

    if ((totalWeightNotifier.value - 100).abs() > 0.01) {
      _showMessage(
        tr(
          'Los porcentajes deben sumar exactamente 100',
          'The percentages must add up to exactly 100',
        ),
      );
      return;
    }

    // Identifica la fila pendiente (sin nota)
    final pendingRows = rows.where(
      (row) => row.scoreController.text.trim().isEmpty,
    );

    if (pendingRows.length != 1) {
      _showMessage(
        tr(
          'Deja vacía la nota de la única actividad que quieres calcular',
          'Leave the grade empty only for the one activity you want to calculate',
        ),
      );
      return;
    }

    final pendingRow = pendingRows.first;
    final pendingWeight = DecimalInput.parse(pendingRow.weightController.text) ?? 0;

    if (pendingWeight == 0) {
      _showMessage(
        tr(
          'La actividad pendiente necesita un porcentaje mayor a 0',
          'The pending activity needs a percentage greater than 0',
        ),
      );
      return;
    }

    double accumulated = 0;
    for (final row in rows) {
      if (row == pendingRow) continue;
      final score = DecimalInput.parse(row.scoreController.text) ?? 0;
      final weight = DecimalInput.parse(row.weightController.text) ?? 0;
      accumulated += score * weight;
    }

    final needed = (target * 100 - accumulated) / pendingWeight;

    setState(() {
      result = needed;
      isReachable = needed <= 5.0;
      hasCalculated = true;
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: Text(
          tr('Calculadora de notas', 'Grade calculator'),
          style: TextStyle(
            color: AppColors.textMain,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    tr(
                      'Calcula cualquier nota sin afectar tu cuenta',
                      'Calculate any grade without affecting your account',
                    ),
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  tr('Actividades', 'Activities'),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMain,
                  ),
                ),
                GestureDetector(
                  onTap: _addRow,
                  child: Text(
                    tr('+ Agregar', '+ Add'),
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...List.generate(rows.length, (index) => _buildRow(index)),
            const SizedBox(height: 12),
            _buildTotalIndicator(),
            const SizedBox(height: 24),
            Center(
              child: Text(
                tr('Nota que quiero alcanzar', 'Grade I want to reach'),
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.5,
                child: TextField(
                  controller: targetGradeController,
                  textAlign: TextAlign.center,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: DecimalInput.gradeFormatters,
                  style: TextStyle(
                    fontSize: 24,
                    color: AppColors.textMain,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _calculate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  tr('Calcular', 'Calculate'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (hasCalculated && result != null) _buildResultCard(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalIndicator() {
    return ValueListenableBuilder<double>(
      valueListenable: totalWeightNotifier,
      builder: (context, totalWeight, _) {
        final isTotalValid = (totalWeight - 100).abs() <= 0.01;
        return Align(
          alignment: Alignment.centerRight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isTotalValid)
                Padding(
                  padding: EdgeInsets.only(right: 4),
                  child: Icon(
                    Icons.error_outline,
                    size: 14,
                    color: AppColors.errorText,
                  ),
                ),
              Text(
                tr(
                  'Total ${totalWeight.toStringAsFixed(0)}%',
                  'Total ${totalWeight.toStringAsFixed(0)}%',
                ),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isTotalValid ? AppColors.okText : AppColors.errorText,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRow(int index) {
    final row = rows[index];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: _smallInput(
              row.nameController,
              tr('Actividad', 'Activity'),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: 2,
            child: _smallInput(
              row.weightController,
              '%',
              isNumber: true,
              onChanged: (_) => _recalculateTotalWeight(),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: 2,
            child: _smallInput(
              row.scoreController,
              tr('Nota', 'Grade'),
              isNumber: true,
              isGrade: true,
            ),
          ),
          IconButton(
            onPressed: rows.length > 1 ? () => _removeRow(index) : null,
            icon: Icon(
              Icons.delete_outline,
              size: 20,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallInput(
    TextEditingController controller,
    String hint, {
    bool isNumber = false,
    bool isGrade = false,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      inputFormatters: isGrade
          ? DecimalInput.gradeFormatters
          : isNumber
              ? DecimalInput.formatters
              : null,
      onChanged: onChanged,
      style: TextStyle(fontSize: 14, color: AppColors.textMain),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isReachable ? AppColors.okBg : AppColors.errorBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            tr('Necesitas obtener', 'You need to get'),
            style: TextStyle(
              fontSize: 13,
              color: isReachable ? AppColors.okText : AppColors.errorText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            result!.toStringAsFixed(2),
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w500,
              color: isReachable ? AppColors.okText : AppColors.errorText,
            ),
          ),
          if (!isReachable) ...[
            const SizedBox(height: 8),
            Text(
              tr(
                'No es posible alcanzar esta nota con el porcentaje restante',
                'It is not possible to reach this grade with the remaining percentage',
              ),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.errorText),
            ),
          ],
        ],
      ),
    );
  }
}
