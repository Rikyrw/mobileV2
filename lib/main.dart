import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mob_2/email_verification_notice.dart';
import 'package:mob_2/emoney.dart';
import 'package:mob_2/main_tab_scaffold.dart';
import 'package:mob_2/pln.dart';
import 'package:mob_2/pulsa.dart';
import 'package:mob_2/setor_sampah.dart';
import 'package:mob_2/sig_in.dart';
import 'package:mob_2/sign_up.dart';
import 'package:mob_2/splash_screen.dart';
import 'package:mob_2/topup_saldo.dart';
import 'package:mob_2/welcome_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appInitialization = _initializeAppServices().catchError((e) {
    debugPrint('App initialization finished with warning: $e');
  });
  runApp(MyApp(appInitialization: appInitialization));
}

Future<void> _initializeAppServices() async {
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Env load skipped: $e');
  }

  await _initializeFirebase();
  await Supabase.initialize(
    url: 'https://yugkzkxwddabkjzooswk.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl1Z2t6a3h3ZGRhYmtqem9vc3drIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY4NjY5NzcsImV4cCI6MjA5MjQ0Mjk3N30.R8QcsDWjeAxwvR55BB8eDp-hi3GACpCW0qikV_uFxFc',
  );
}

Future<bool> _initializeFirebase() async {
  try {
    if (!kIsWeb) {
      try {
        await Firebase.initializeApp();
        return true;
      } catch (e) {
        debugPrint('Native Firebase initialization skipped: $e');
      }
    }

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
  const MyApp({super.key, required this.appInitialization});

  final Future<void> appInitialization;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        splashFactory: InkRipple.splashFactory,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF315A39))
            .copyWith(
              primary: const Color(0xFF315A39),
              secondary: const Color(0xFF6B8F71),
              surface: Colors.white,
            ),
        scaffoldBackgroundColor: const Color(0xFFF7F8F7),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF315A39),
          foregroundColor: Colors.white,
          centerTitle: false,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            fontFamily: 'Roboto',
          ),
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.fuchsia: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          },
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF315A39),
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFFD8DED8),
            disabledForegroundColor: const Color(0xFF7A867E),
            elevation: 0,
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF315A39),
            side: const BorderSide(color: Color(0xFF315A39)),
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFDDE4DD)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFDDE4DD)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF315A39), width: 1.5),
          ),
          hintStyle: const TextStyle(
            color: Color(0xFF7A867E),
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
      routes: {
        '/welcome': (context) => const WelcomeScreen(),
        '/dashboard': (context) =>
            const MainTabScaffold(initialIndex: MainTabScaffold.homeIndex),
        '/profil': (context) =>
            const MainTabScaffold(initialIndex: MainTabScaffold.profilIndex),
        '/transaksi': (context) =>
            const MainTabScaffold(initialIndex: MainTabScaffold.transaksiIndex),
        '/riwayat': (context) =>
            const MainTabScaffold(initialIndex: MainTabScaffold.riwayatIndex),
        '/emoney': (context) => const EmoneyScreen(),
        '/pln': (context) => const PlnScreen(),
        '/pulsa': (context) => const PulsaScreen(),
        '/setor-sampah': (context) => const SetorSampahScreen(),
        '/sig-in': (context) => const SignInScreen(),
        '/sign-up': (context) => const SignUpScreen(),
        '/email-verification-notice': (context) =>
            const EmailVerificationNoticeScreen(),
        '/chatbot': (context) =>
            const MainTabScaffold(initialIndex: MainTabScaffold.chatIndex),
        '/topup-saldo': (context) => const TopupSaldoScreen(),
      },
      home: SplashScreen(initialization: appInitialization),
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
