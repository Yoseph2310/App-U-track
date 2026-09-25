import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

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
      sum += double.tryParse(row.weightController.text) ?? 0;
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
    final target = double.tryParse(targetGradeController.text);
    if (target == null) {
      _showMessage('Ingresa la nota que quieres alcanzar');
      return;
    }

    if (totalWeightNotifier.value != 100) {
      _showMessage('Los porcentajes deben sumar exactamente 100');
      return;
    }

    // Identifica la fila pendiente (sin nota)
    final pendingRows = rows.where(
      (row) => row.scoreController.text.trim().isEmpty,
    );

    if (pendingRows.length != 1) {
      _showMessage(
        'Deja vacía la nota de la única actividad que quieres calcular',
      );
      return;
    }

    final pendingRow = pendingRows.first;
    final pendingWeight = double.tryParse(pendingRow.weightController.text) ?? 0;

    if (pendingWeight == 0) {
      _showMessage('La actividad pendiente necesita un porcentaje mayor a 0');
      return;
    }

    double accumulated = 0;
    for (final row in rows) {
      if (row == pendingRow) continue;
      final score = double.tryParse(row.scoreController.text) ?? 0;
      final weight = double.tryParse(row.weightController.text) ?? 0;
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
        title: const Text(
          'Calculadora de notas',
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
                const Icon(
                  Icons.info_outline,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Calcula cualquier nota sin afectar tu cuenta',
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
                const Text(
                  'Actividades',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMain,
                  ),
                ),
                GestureDetector(
                  onTap: _addRow,
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
            const SizedBox(height: 12),
            ...List.generate(rows.length, (index) => _buildRow(index)),
            const SizedBox(height: 12),
            _buildTotalIndicator(),
            const SizedBox(height: 24),
            const Center(
              child: Text(
                'Nota que quiero alcanzar',
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
                  style: const TextStyle(
                    fontSize: 24,
                    color: AppColors.textMain,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
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
                child: const Text(
                  'Calcular',
                  style: TextStyle(
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
        final isTotalValid = totalWeight == 100;
        return Align(
          alignment: Alignment.centerRight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isTotalValid)
                const Padding(
                  padding: EdgeInsets.only(right: 4),
                  child: Icon(
                    Icons.error_outline,
                    size: 14,
                    color: AppColors.errorText,
                  ),
                ),
              Text(
                'Total ${totalWeight.toStringAsFixed(0)}%',
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
            child: _smallInput(row.nameController, 'Actividad'),
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
            child: _smallInput(row.scoreController, 'Nota', isNumber: true),
          ),
          IconButton(
            onPressed: rows.length > 1 ? () => _removeRow(index) : null,
            icon: const Icon(
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
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 14, color: AppColors.textMain),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 10,
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
            'Necesitas obtener',
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
            const Text(
              'No es posible alcanzar esta nota con el porcentaje restante',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.errorText),
            ),
          ],
        ],
      ),
    );
  }
}
