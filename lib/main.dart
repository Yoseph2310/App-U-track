import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/splash_screen.dart';
import 'features/dev_menu_screen.dart'; // TEMPORAL, borrar esta línea después

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const UTrackApp());
}

class UTrackApp extends StatelessWidget {
  const UTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'U-Track',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const DevMenuScreen(), // TEMPORAL, volver a SplashScreen() para ver el splash y el login
    );
  }
}