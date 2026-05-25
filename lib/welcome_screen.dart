import 'package:flutter/material.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _introController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _introController = AnimationController(
      duration: const Duration(milliseconds: 650),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _introController,
      curve: Curves.easeOutCubic,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
          CurvedAnimation(parent: _introController, curve: Curves.easeOutCubic),
        );

    _introController.forward();
  }

  @override
  void dispose() {
    _introController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2E5634),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final imageHeight = (constraints.maxHeight * 0.28)
                .clamp(150.0, 220.0)
                .toDouble();

            return Padding(
              padding: const EdgeInsets.fromLTRB(28, 22, 28, 34),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Spacer(),
                      RepaintBoundary(
                        child: Image.asset(
                          'assets/pohon1.png',
                          height: imageHeight,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Selamat Datang',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Roboto',
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'di GreenPoint',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xD9FFFFFF),
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                          fontFamily: 'Roboto',
                        ),
                      ),
                      const Spacer(),
                      _welcomeButton(
                        label: 'Masuk',
                        icon: Icons.login_rounded,
                        onPressed: () =>
                            Navigator.of(context).pushNamed('/sig-in'),
                      ),
                      const SizedBox(height: 12),
                      _welcomeButton(
                        label: 'Daftar',
                        icon: Icons.person_add_alt_1_rounded,
                        isSecondary: true,
                        onPressed: () =>
                            Navigator.of(context).pushNamed('/sign-up'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _welcomeButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    bool isSecondary = false,
  }) {
    final foreground = isSecondary ? Colors.white : const Color(0xFF315A39);

    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSecondary
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.white,
          foregroundColor: foreground,
          elevation: 0,
          side: isSecondary
              ? BorderSide(color: Colors.white.withValues(alpha: 0.46))
              : BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            fontFamily: 'Roboto',
          ),
        ),
      ),
    );
  }
}
