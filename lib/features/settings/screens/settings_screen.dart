import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/user_name.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/services/auth_service.dart'; // ← NUEVO
import '../../reminders/notification_service.dart';
import '../../reminders/reminder_preferences.dart';
import '../../tasks/models/task_model.dart';
import '../../auth/login_screen.dart';

/// Pantalla 9 — Recordatorios / Configuración
class SettingsScreen extends StatefulWidget {
  /// Opcionales: si no se pasan, se toman del usuario con sesión iniciada.
  final String? userName;
  final String? userEmail;
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

class _SettingsScreenState extends State<SettingsScreen>
    with WidgetsBindingObserver {
  bool notificationsEnabled = false;
  ReminderTiming reminderAnticipation = ReminderTiming.unDia;
  String reminderHour = '8:00 AM';

  final _authService = AuthService(); // ← NUEVO

  /// true mientras el usuario está en los ajustes del sistema dando el permiso.
  bool _awaitingSystemSettings = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadPrefs();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Al volver a la app (por ejemplo desde los ajustes del sistema) se
  /// vuelve a revisar el permiso real.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _syncPermission();
  }

  Future<void> _syncPermission() async {
    final status = await Permission.notification.status;
    if (!mounted) return;

    if (notificationsEnabled && !status.isGranted) {
      // El usuario quitó el permiso en los ajustes del sistema.
      setState(() => notificationsEnabled = false);
      await _savePrefs();
      await NotificationService.instance.cancelAll();
    } else if (_awaitingSystemSettings && !notificationsEnabled && status.isGranted) {
      // Volvió de los ajustes del sistema después de darlo.
      setState(() => notificationsEnabled = true);
      await _savePrefs();
      await _rescheduleAll();
    }
    _awaitingSystemSettings = false;
  }

  /// El sistema ya no deja pedir el permiso desde la app: explicamos y
  /// llevamos al usuario a los ajustes de U-Track.
  Future<void> _askOpenSystemSettings() async {
    final open = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('Permiso de notificaciones', 'Notification permission')),
        content: Text(tr(
          'Las notificaciones de U-Track están bloqueadas en los ajustes del '
              'sistema. Actívalas allí para recibir tus recordatorios; al volver '
              'a la app se activarán solas.',
          'U-Track notifications are blocked in the system settings. Turn them '
              'on there to get your reminders; they will turn on by themselves '
              'when you come back to the app.',
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr('Ahora no', 'Not now')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr('Abrir ajustes', 'Open settings')),
          ),
        ],
      ),
    );
    if (open == true) {
      _awaitingSystemSettings = true;
      await openAppSettings();
    }
  }

  String get _displayName {
    final name = widget.userName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return UserName.full(FirebaseAuth.instance.currentUser);
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
      reminderAnticipation = prefs.anticipation;
      reminderHour = _formatHour(prefs.hour);
      notificationsEnabled = prefs.enabled && status.isGranted;
    });
  }

  Future<void> _savePrefs() async {
    await ReminderPreferences(
      enabled: notificationsEnabled,
      anticipation: reminderAnticipation,
      hour: _parseHour(reminderHour),
    ).save();
  }

  /// Vuelve a programar los avisos de todas las actividades pendientes.
  Future<void> _rescheduleAll() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) await NotificationService.instance.rescheduleAll(uid);
  }

  /// Abre la ventana para editar la cuenta (nombre y contraseña).
  Future<void> _editAccount() async {
    final updated = await showDialog<bool>(
      context: context,
      builder: (_) => _EditAccountDialog(
        initialName: _displayName,
        email: _displayEmail,
        authService: _authService,
      ),
    );

    if (updated == true && mounted) {
      setState(() {}); // la tarjeta muestra el nuevo nombre
      final name = _displayName;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('✅ ¡Listo! Tu nombre ahora es $name.',
              '✅ Done! Your name is now $name.')),
        ),
      );
    }
  }

  // ─── NUEVO: logout real ──────────────────────────────────────────
  Future<void> _logout() async {
    // Diálogo de confirmación
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('Cerrar sesión', 'Sign out')),
        content: Text(tr('¿Estás seguro de que quieres cerrar sesión?',
            'Are you sure you want to sign out?')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr('Cancelar', 'Cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.errorText),
            child: Text(tr('Cerrar sesión', 'Sign out')),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // Ventana "Cerrando sesión…" mientras se cierra todo.
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  tr('Cerrando sesión…', 'Signing out…'),
                  style: TextStyle(fontSize: 15, color: AppColors.textMain),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Se espera al menos un momento para que el mensaje alcance a verse.
    await Future.wait([
      () async {
        await NotificationService.instance.cancelAll(); // sin sesión no hay avisos
        await _authService.logout();
      }(),
      Future<void>.delayed(const Duration(milliseconds: 900)),
    ]);

    if (!mounted) return;

    // Llama al callback si la pantalla padre lo definió
    widget.onLogout?.call();

    // Borra todo el historial de navegación y va directo al Login
    // (pasar por el Splash repetía el video de bienvenida).
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen(justSignedOut: true)),
      (route) => false,
    );
  }
  // ────────────────────────────────────────────────────────────────

  /// Activa o desactiva el tema oscuro. Se aplica al instante en toda la app.
  Future<void> _toggleDarkTheme(bool value) async {
    await AppSettings.setDark(value);
    if (mounted) setState(() {});
  }

  Future<void> _pickLanguage() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => _OptionsSheet(
        title: tr('Idioma', 'Language'),
        options: const {'es': 'Español', 'en': 'English'},
        current: AppSettings.isEnglish ? 'en' : 'es',
      ),
    );
    if (selected == null) return;
    final english = selected == 'en';
    if (english != AppSettings.isEnglish) {
      await AppSettings.setEnglish(english);
      if (mounted) setState(() {});
      // Los recordatorios ya programados se vuelven a crear en el nuevo idioma.
      if (notificationsEnabled) await _rescheduleAll();
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
    setState(() => notificationsEnabled = false);
    await _savePrefs();
    if (!mounted) return;
    if (status.isPermanentlyDenied || status.isRestricted) {
      await _askOpenSystemSettings();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr(
              'Necesitas conceder el permiso de notificaciones para activar los recordatorios',
              'You need to grant the notification permission to turn on reminders')),
        ),
      );
    }
  }

  Future<void> _pickAnticipation() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => _OptionsSheet(
        title: tr('Avisar con anticipación de', 'Remind me in advance'),
        options: {
          for (final timing in ReminderTiming.values)
            timing.name: timing.displayLabel,
        },
        current: reminderAnticipation.name,
      ),
    );
    if (selected != null) {
      setState(() => reminderAnticipation =
          ReminderTiming.values.firstWhere((t) => t.name == selected));
      // Es la anticipación por defecto de las actividades nuevas.
      await _savePrefs();
    }
  }

  Future<void> _pickReminderHour() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _parseHour(reminderHour),
      builder: (context, child) => Theme(
        data: AppTheme.pickerTheme(context),
        child: child!,
      ),
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
        title: Text(
          tr('Configuración', 'Settings'),
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
          _sectionLabel(tr('Recordatorios', 'Reminders')),
          const SizedBox(height: 8),
          _remindersCard(),
          const SizedBox(height: 16),
          _sectionLabel(tr('Preferencias', 'Preferences')),
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
      style: TextStyle(
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
        ? name.trim().split(' ').where((w) => w.isNotEmpty).map((w) => w[0]).take(2).join()
        : '?';

    return GestureDetector(
      onTap: _editAccount,
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
                style: TextStyle(
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
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _displayEmail,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _remindersCard() {
    return _card(
      children: [
        _switchRow(
          label: tr('Notificaciones activas', 'Notifications on'),
          value: notificationsEnabled,
          onChanged: _toggleNotifications,
        ),
        _divider(),
        _valueRow(
          label: tr('Avisar con anticipación de', 'Remind me in advance'),
          value: reminderAnticipation.displayLabel,
          onTap: _pickAnticipation,
        ),
        _divider(),
        _valueRow(
          label: tr('Hora de recordatorio', 'Reminder time'),
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
          label: tr('Tema oscuro', 'Dark theme'),
          value: AppSettings.isDark,
          onChanged: _toggleDarkTheme,
        ),
        _divider(),
        _valueRow(
          label: tr('Idioma', 'Language'),
          value: AppSettings.isEnglish ? 'English' : 'Español',
          onTap: _pickLanguage,
        ),
      ],
    );
  }

  Widget _divider() => Divider(height: 1, color: AppColors.border);

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
          Text(label, style: TextStyle(fontSize: 14, color: AppColors.textMain)),
          Switch(value: value, activeThumbColor: AppColors.primary, onChanged: onChanged),
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
            Text(label, style: TextStyle(fontSize: 14, color: AppColors.textMain)),
            Row(
              children: [
                Text(value, style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right, size: 18, color: AppColors.textSecondary),
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
        onPressed: _logout, // ← antes mostraba snackbar, ahora llama _logout()
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.errorText),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        icon: Icon(Icons.logout, size: 18, color: AppColors.errorText),
        label: Text(
          tr('Cerrar sesión', 'Sign out'),
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.errorText),
        ),
      ),
    );
  }
}

/// Hoja inferior con opciones. [options] va de valor interno a texto visible;
/// al elegir devuelve el valor interno.
class _OptionsSheet extends StatelessWidget {
  final String title;
  final Map<String, String> options;
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
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.textMain,
              ),
            ),
          ),
          ...options.entries.map((option) => ListTile(
            title: Text(option.value,
                style: TextStyle(color: AppColors.textMain)),
            trailing: option.key == current
                ? Icon(Icons.check, color: AppColors.primary)
                : null,
            onTap: () => Navigator.pop(context, option.key),
          )),
        ],
      ),
    );
  }
}
/// Ventana para editar la cuenta: cambia el nombre y permite pedir el correo
/// para cambiar la contraseña. Maneja su propio campo de texto y lo libera al
/// cerrarse (así cancelar no genera errores).
class _EditAccountDialog extends StatefulWidget {
  const _EditAccountDialog({
    required this.initialName,
    required this.email,
    required this.authService,
  });

  final String initialName;
  final String email;
  final AuthService authService;

  @override
  State<_EditAccountDialog> createState() => _EditAccountDialogState();
}

class _EditAccountDialogState extends State<_EditAccountDialog> {
  late final TextEditingController _nameController =
      TextEditingController(text: widget.initialName);
  bool _saving = false;
  bool _sendingReset = false;
  String? _nameError;
  String? _resetMessage;
  bool _resetOk = false;

  bool get _busy => _saving || _sendingReset;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = tr('Escribe tu nombre.', 'Enter your name.'));
      return;
    }

    // Si el nombre no cambió no hace falta llamar a Firebase.
    if (name == widget.initialName.trim()) {
      Navigator.pop(context, false);
      return;
    }

    setState(() {
      _saving = true;
      _nameError = null;
    });

    final error = await widget.authService.updateDisplayName(name);

    if (!mounted) return;

    if (error == null) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _saving = false;
        _nameError = error;
      });
    }
  }

  Future<void> _sendPasswordReset() async {
    setState(() {
      _sendingReset = true;
      _resetMessage = null;
    });

    final error = await widget.authService.sendPasswordReset(widget.email);

    if (!mounted) return;

    setState(() {
      _sendingReset = false;
      _resetOk = error == null;
      _resetMessage = error ??
          tr('Te enviamos un correo para cambiar tu contraseña.',
              'We sent you an email to change your password.');
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasEmail = widget.email.trim().isNotEmpty;

    return AlertDialog(
      backgroundColor: AppColors.surface,
      scrollable: true,
      title: Text(tr('Editar cuenta', 'Edit account')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameController,
            enabled: !_busy,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) {
              if (!_busy) _save();
            },
            decoration: InputDecoration(
              labelText: tr('Nombre', 'Name'),
              prefixIcon: const Icon(Icons.person_outline),
              errorText: _nameError,
            ),
          ),
          if (hasEmail) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.email_outlined,
                    size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(widget.email, style: AppTextStyles.body2),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _busy ? null : _sendPasswordReset,
              icon: _sendingReset
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.lock_outline),
              label: Text(tr('Cambiar contraseña', 'Change password')),
            ),
            if (_resetMessage != null)
              Text(
                _resetMessage!,
                style: AppTextStyles.caption.copyWith(
                  color: _resetOk ? AppColors.okText : AppColors.errorText,
                ),
              ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context, false),
          child: Text(tr('Cancelar', 'Cancel')),
        ),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : Text(tr('Guardar', 'Save')),
        ),
      ],
    );
  }
}
