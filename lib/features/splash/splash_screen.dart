import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../auth/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _controller;
  bool _videoReady = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/videos/Splash_Screen_1.mp4')
      ..initialize().then((_) {
        _controller.setLooping(false);
        _controller.play();
        setState(() => _videoReady = true);

        // Cuando el video termine, ir al login
        _controller.addListener(() {
          if (_controller.value.position >= _controller.value.duration) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          }
        });
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Video de fondo
          if (_videoReady)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller.value.size.width,
                height: _controller.value.size.height,
                child: VideoPlayer(_controller),
              ),
            ),

          // Fade de negro a transparente cuando el video está listo
          AnimatedOpacity(
            opacity: _videoReady ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 600),
            child: Container(color: Colors.black),
          ),
        ],
      ),
    );
  }
}