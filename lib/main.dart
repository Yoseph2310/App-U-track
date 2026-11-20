
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/settings/app_settings.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/splash_screen.dart';
import 'features/reminders/notification_service.dart';
import 'features/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await AppSettings.load(); // tema e idioma guardados
  await NotificationService.instance.init(); // recordatorios (notificaciones locales)
  runApp(const UTrackApp());
}

class UTrackApp extends StatelessWidget {
  const UTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Se vuelve a construir cuando cambia el tema o el idioma.
    return ValueListenableBuilder<int>(
      valueListenable: AppSettings.changes,
      builder: (context, _, _) => MaterialApp(
        title: 'U-Track',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.current,
        // Idioma de los textos propios de Flutter (calendario, reloj, etc.)
        locale: Locale(AppSettings.isEnglish ? 'en' : 'es'),
        supportedLocales: const [Locale('es'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const SplashScreen(),
        routes: {
          '/home': (_) => const HomeScreen(),
        },
      ),
    );
  }
}
