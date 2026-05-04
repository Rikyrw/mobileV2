import 'package:flutter/material.dart';
import 'package:mob_2/dashboard.dart';
import 'package:mob_2/emoney.dart';
import 'package:mob_2/pln.dart';
import 'package:mob_2/pulsa.dart';
import 'package:mob_2/profil.dart';
import 'package:mob_2/riwayat.dart';
import 'package:mob_2/setor_sampah.dart';
import 'package:mob_2/sig_in.dart';
import 'package:mob_2/sign_up.dart';
import 'package:mob_2/transaksi.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      routes: {
        '/dashboard': (context) => const DashboardScreen(),
        '/profil': (context) => const ProfilScreen(),
        '/transaksi': (context) => const TransaksiScreen(),
        '/riwayat': (context) => const RiwayatScreen(),
        '/emoney': (context) => const EmoneyScreen(),
        '/pln': (context) => const PlnScreen(),
        '/pulsa': (context) => const PulsaScreen(),
        '/setor-sampah': (context) => const SetorSampahScreen(),
      },
      home: const DashboardScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    );

    return Scaffold(
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: const Color(0xFF2E5634),
          child: Column(
            children: [
              const SizedBox(height: 24),
              SizedBox(
                height: 220,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 150,
                      child: Image.asset(
                        'assets/pohon1.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 48,
                      child: Image.asset('assets/gp.png', fit: BoxFit.contain),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),
              const Text(
                'Welcome',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'Roboto',
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 250,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const SignInScreen(),
                      ),
                    );
                  },
                  style: buttonStyle,
                  child: const Text(
                    'Sign In',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'Roboto',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 250,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const SignUpScreen(),
                      ),
                    );
                  },
                  style: buttonStyle,
                  child: const Text(
                    'Sign Up',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'Roboto',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
