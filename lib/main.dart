import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mob_2/dashboard.dart';
import 'package:mob_2/emoney.dart';
import 'package:mob_2/pln.dart';
import 'package:mob_2/pulsa.dart';
import 'package:mob_2/profil.dart';
import 'package:mob_2/riwayat.dart';
import 'package:mob_2/setor_sampah.dart';
import 'package:mob_2/sig_in.dart';
import 'package:mob_2/sign_up.dart';
import 'package:mob_2/splash_screen.dart';
import 'package:mob_2/welcome_screen.dart';
import 'package:mob_2/transaksi.dart';
import 'package:mob_2/chatbot.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await _initializeFirebase();
  await Supabase.initialize(
    url: 'https://yugkzkxwddabkjzooswk.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl1Z2t6a3h3ZGRhYmtqem9vc3drIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY4NjY5NzcsImV4cCI6MjA5MjQ0Mjk3N30.R8QcsDWjeAxwvR55BB8eDp-hi3GACpCW0qikV_uFxFc',
  );
  runApp(const MyApp());
}

Future<bool> _initializeFirebase() async {
  try {
    final options = _firebaseOptionsFromEnv();
    if (options == null) {
      debugPrint(
        'Firebase config belum lengkap. Isi FIREBASE_* di .env atau jalankan flutterfire configure.',
      );
      return false;
    }

    await Firebase.initializeApp(options: options);
    return true;
  } catch (e) {
    debugPrint('Firebase initialization skipped: $e');
    return false;
  }
}

FirebaseOptions? _firebaseOptionsFromEnv() {
  final apiKey = dotenv.env['FIREBASE_API_KEY']?.trim();
  final appId = dotenv.env['FIREBASE_APP_ID']?.trim();
  final messagingSenderId = dotenv.env['FIREBASE_MESSAGING_SENDER_ID']?.trim();
  final projectId = dotenv.env['FIREBASE_PROJECT_ID']?.trim();

  if (apiKey == null ||
      apiKey.isEmpty ||
      appId == null ||
      appId.isEmpty ||
      messagingSenderId == null ||
      messagingSenderId.isEmpty ||
      projectId == null ||
      projectId.isEmpty) {
    return null;
  }

  return FirebaseOptions(
    apiKey: apiKey,
    appId: appId,
    messagingSenderId: messagingSenderId,
    projectId: projectId,
    authDomain: dotenv.env['FIREBASE_AUTH_DOMAIN']?.trim(),
    storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET']?.trim(),
    measurementId: dotenv.env['FIREBASE_MEASUREMENT_ID']?.trim(),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      routes: {
        '/welcome': (context) => const WelcomeScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/profil': (context) => const ProfilScreen(),
        '/transaksi': (context) => const TransaksiScreen(),
        '/riwayat': (context) => const RiwayatScreen(),
        '/emoney': (context) => const EmoneyScreen(),
        '/pln': (context) => const PlnScreen(),
        '/pulsa': (context) => const PulsaScreen(),
        '/setor-sampah': (context) => const SetorSampahScreen(),
        '/sig-in': (context) => const SignInScreen(),
        '/sign-up': (context) => const SignUpScreen(),
        '/chatbot': (context) => const ChatbotScreen(),
      },
      home: const SplashScreen(),
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
