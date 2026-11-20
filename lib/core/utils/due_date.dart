import '../settings/app_settings.dart';

/// Utilidades para mostrar fechas de entrega.
class DueDate {
  DueDate._();

  /// Días que faltan desde hoy hasta [date], contando solo la fecha
  /// (sin la hora). Hoy = 0, mañana = 1.
  static int daysUntil(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    return day.difference(today).inDays;
  }

  /// Texto corto: "Hoy", "Mañana" o "3d".
  static String shortLabel(DateTime date) {
    final days = daysUntil(date);
    if (days == 0) return tr('Hoy', 'Today');
    if (days == 1) return tr('Mañana', 'Tomorrow');
    return '${days}d';
  }

  /// Fecha completa, por ejemplo "lunes 24 de noviembre" o
  /// "Monday, November 24".
  static String longLabel(DateTime date) {
    const diasEs = [
      'lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'
    ];
    const mesesEs = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio',
      'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    const daysEn = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday',
      'Sunday'
    ];
    const monthsEn = [
      'January', 'February', 'March', 'April', 'May', 'June', 'July',
      'August', 'September', 'October', 'November', 'December'
    ];
    if (AppSettings.isEnglish) {
      return '${daysEn[date.weekday - 1]}, ${monthsEn[date.month - 1]} ${date.day}';
    }
    return '${diasEs[date.weekday - 1]} ${date.day} de ${mesesEs[date.month - 1]}';
  }
}
