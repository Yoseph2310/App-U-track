import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Pantalla 9 — Recordatorios / Configuración
/// Según especificación en docs/u-track-especificaciones-ui.md
class SettingsScreen extends StatefulWidget {
  final String userName;
  final String userEmail;
  final VoidCallback? onLogout;

  const SettingsScreen({
    super.key,
    this.userName = 'Estudiante',
    this.userEmail = 'correo@ejemplo.com',
    this.onLogout,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notificationsEnabled = true;
  String reminderAnticipation = '1 día antes';
  String reminderHour = '8:00 AM';
  bool darkTheme = false;
  String language = 'Español';

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
    }
  }

  Future<void> _pickReminderHour() async {
    final parts = reminderHour.split(' ');
    final timeParts = parts[0].split(':');
    var hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    if (parts.length > 1 && parts[1] == 'PM' && hour != 12) hour += 12;
    if (parts.length > 1 && parts[1] == 'AM' && hour == 12) hour = 0;

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: hour, minute: minute),
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
      final displayHour = picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod;
      final displayMinute = picked.minute.toString().padLeft(2, '0');
      final period = picked.period == DayPeriod.am ? 'AM' : 'PM';
      setState(() => reminderHour = '$displayHour:$displayMinute $period');
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
    final initials = widget.userName.isNotEmpty
        ? widget.userName.trim().split(' ').map((w) => w[0]).take(2).join()
        : '?';

    return GestureDetector(
      onTap: () {
        // Aquí se abriría la edición de nombre/foto cuando exista esa pantalla
      },
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
                    widget.userName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.userEmail,
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
          onChanged: (value) => setState(() => notificationsEnabled = value),
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
        _switchRow(
          label: 'Tema oscuro',
          value: darkTheme,
          onChanged: (value) => setState(() => darkTheme = value),
        ),
        _divider(),
        _valueRow(
          label: 'Idioma',
          value: language,
          onTap: () {},
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
        onPressed: widget.onLogout,
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
