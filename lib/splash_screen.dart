import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.initialization});

  final Future<void>? initialization;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _openWelcomeWhenReady();
  }

  Future<void> _openWelcomeWhenReady() async {
    final minimumSplash = Future<void>.delayed(
      const Duration(milliseconds: 850),
    );

    try {
      await Future.wait([
        minimumSplash,
        widget.initialization ?? Future<void>.value(),
      ]);
    } catch (e) {
      debugPrint('App initialization finished with warning: $e');
      await minimumSplash;
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/welcome');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2E5634),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/pohon1.png',
              width: 200,
              height: 100,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 20),
            const Text(
              'GreenPoint',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                fontFamily: 'Roboto',
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Aplikasi Bank Sampah',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontFamily: 'Roboto',
              ),
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
