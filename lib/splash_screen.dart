import 'package:flutter/material.dart';

import 'viewmodels/splash_view_model.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.initialization});

  final Future<void>? initialization;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late final SplashViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = SplashViewModel(initialization: widget.initialization);
    _openInitialRouteWhenReady();
  }

  Future<void> _openInitialRouteWhenReady() async {
    final destination = await _viewModel.resolveDestination();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(
      destination.routeName,
      arguments: destination.arguments,
    );
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
