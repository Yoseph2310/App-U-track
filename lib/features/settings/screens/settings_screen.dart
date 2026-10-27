import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/login_screen.dart';
import '../../reminders/notification_service.dart';
import '../../reminders/reminder_preferences.dart';
import '../../tasks/models/task_model.dart';

/// Pantalla 9 — Recordatorios / Configuración
/// Según especificación en docs/u-track-especificaciones-ui.md
class SettingsScreen extends StatefulWidget {
  /// Opcionales: si no se pasan, se toman del usuario de Firebase Auth.
  final String? userName;
  final String? userEmail;

  /// Opcional: si se pasa, se ejecuta al cerrar sesión en vez de ir al Login.
  final VoidCallback? onLogout;

  const SettingsScreen({
    super.key,
    this.userName,
    this.userEmail,
    this.onLogout,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notificationsEnabled = false;
  String reminderAnticipation = '1 día antes';
  String reminderHour = '8:00 AM';
  String theme = 'Claro';
  String language = 'Español';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  String get _displayName {
    final user = FirebaseAuth.instance.currentUser;
    final fromEmail = user?.email?.split('@').first;
    final name = widget.userName ?? user?.displayName ?? fromEmail;
    return (name == null || name.trim().isEmpty) ? 'Estudiante' : name;
  }

  String get _displayEmail =>
      widget.userEmail ?? FirebaseAuth.instance.currentUser?.email ?? '';

  TimeOfDay _parseHour(String text) {
    final parts = text.split(' ');
    final timeParts = parts[0].split(':');
    var hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    if (parts.length > 1 && parts[1] == 'PM' && hour != 12) hour += 12;
    if (parts.length > 1 && parts[1] == 'AM' && hour == 12) hour = 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _formatHour(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  /// Carga lo guardado en el dispositivo y revisa el permiso real del sistema.
  /// El switch solo aparece encendido si el usuario lo activó Y el sistema
  /// dio el permiso (la primera vez, el permiso aún no se ha pedido).
  Future<void> _loadPrefs() async {
    final prefs = await ReminderPreferences.load();
    final status = await Permission.notification.status;
    if (!mounted) return;
    setState(() {
      reminderAnticipation = prefs.anticipation.label;
      reminderHour = _formatHour(prefs.hour);
      notificationsEnabled = prefs.enabled && status.isGranted;
    });
  }

  Future<void> _savePrefs() async {
    await ReminderPreferences(
      enabled: notificationsEnabled,
      anticipation: ReminderTimingLabel.fromLabel(reminderAnticipation),
      hour: _parseHour(reminderHour),
    ).save();
  }

  /// Vuelve a programar los avisos de todas las actividades pendientes.
  Future<void> _rescheduleAll() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) await NotificationService.instance.rescheduleAll(uid);
  }

  Future<void> _logout() async {
    final navigator = Navigator.of(context);
    await NotificationService.instance.cancelAll();
    await FirebaseAuth.instance.signOut();
    if (widget.onLogout != null) {
      widget.onLogout!();
      return;
    }
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _showComingSoon(String feature) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature próximamente estará disponible')),
    );
  }

  Future<void> _pickTheme() async {
    final options = ['Claro', 'Oscuro'];
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => _OptionsSheet(
        title: 'Tema',
        options: options,
        current: theme,
      ),
    );
    if (selected != null && selected != theme) {
      _showComingSoon('El tema oscuro');
    }
  }

  Future<void> _pickLanguage() async {
    final options = ['Español', 'Inglés', 'Portugués', 'Francés', 'Alemán'];
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => _OptionsSheet(
        title: 'Idioma',
        options: options,
        current: language,
      ),
    );
    if (selected != null && selected != language) {
      _showComingSoon('El idioma $selected');
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    if (!value) {
      // Apagar el interruptor no necesita permiso: guardamos y borramos los avisos
      setState(() => notificationsEnabled = false);
      await _savePrefs();
      await NotificationService.instance.cancelAll();
      return;
    }

    final status = await Permission.notification.request();

    if (status.isGranted) {
      setState(() => notificationsEnabled = true);
      await _savePrefs();
      await _rescheduleAll();
      return;
    }

    // El usuario negó el permiso (o lo bloqueó antes), dejamos el switch apagado
    setState(() => notificationsEnabled = false);
    await _savePrefs();

    if (!mounted) return;

    if (status.isPermanentlyDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Activa las notificaciones desde los ajustes del sistema para recibir recordatorios',
          ),
          action: SnackBarAction(
            label: 'Abrir ajustes',
            onPressed: openAppSettings,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Necesitas conceder el permiso de notificaciones para activar los recordatorios'),
        ),
      );
    }
  }

  Future<void> _pickAnticipation() async {
    final options = ['1 día antes', '3 días antes', '1 semana antes'];
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => _OptionsSheet(
        title: 'Avisar con anticipación de',
        options: options,
        current: reminderAnticipation,
      ),
    );
    if (selected != null) {
      setState(() => reminderAnticipation = selected);
      // Es la anticipación por defecto de las actividades nuevas.
      await _savePrefs();
    }
  }

  Future<void> _pickReminderHour() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _parseHour(reminderHour),
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
      setState(() => reminderHour = _formatHour(picked));
      await _savePrefs();
      await _rescheduleAll(); // los avisos existentes pasan a la nueva hora
    }
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
          'Configuración',
          style: TextStyle(
            color: AppColors.textMain,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          _accountCard(),
          const SizedBox(height: 16),
          _sectionLabel('Recordatorios'),
          const SizedBox(height: 8),
          _remindersCard(),
          const SizedBox(height: 16),
          _sectionLabel('Preferencias'),
          const SizedBox(height: 8),
          _preferencesCard(),
          const SizedBox(height: 24),
          _logoutButton(),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _card({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: children),
    );
  }

  Widget _accountCard() {
    final name = _displayName;
    final initials = name.trim().isNotEmpty
        ? name
            .trim()
            .split(' ')
            .where((w) => w.isNotEmpty)
            .map((w) => w[0])
            .take(2)
            .join()
        : '?';

    return GestureDetector(
      onTap: () => _showComingSoon('Editar tu cuenta'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.primaryLight,
              child: Text(
                initials.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _displayEmail,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 18,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _remindersCard() {
    return _card(
      children: [
        _switchRow(
          label: 'Notificaciones activas',
          value: notificationsEnabled,
          onChanged: _toggleNotifications,
        ),
        _divider(),
        _valueRow(
          label: 'Avisar con anticipación de',
          value: reminderAnticipation,
          onTap: _pickAnticipation,
        ),
        _divider(),
        _valueRow(
          label: 'Hora de recordatorio',
          value: reminderHour,
          onTap: _pickReminderHour,
        ),
      ],
    );
  }

  Widget _preferencesCard() {
    return _card(
      children: [
        _valueRow(
          label: 'Tema',
          value: theme,
          onTap: _pickTheme,
        ),
        _divider(),
        _valueRow(
          label: 'Idioma',
          value: language,
          onTap: _pickLanguage,
        ),
      ],
    );
  }

  Widget _divider() {
    return const Divider(height: 1, color: AppColors.border);
  }

  Widget _switchRow({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: AppColors.textMain),
          ),
          Switch(
            value: value,
            activeColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _valueRow({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 14, color: AppColors.textMain),
            ),
            Row(
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _logoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: _logout,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.errorText),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        icon: const Icon(Icons.logout, size: 18, color: AppColors.errorText),
        label: const Text(
          'Cerrar sesión',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.errorText,
          ),
        ),
      ),
    );
  }
}

class _OptionsSheet extends StatelessWidget {
  final String title;
  final List<String> options;
  final String current;

  const _OptionsSheet({
    required this.title,
    required this.options,
    required this.current,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.textMain,
              ),
            ),
          ),
          ...options.map((option) {
            return ListTile(
              title: Text(option),
              trailing: option == current
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () => Navigator.pop(context, option),
            );
          }),
        ],
      ),
    );
  }
}
