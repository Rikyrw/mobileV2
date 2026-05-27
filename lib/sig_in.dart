import 'package:flutter/material.dart';
import 'email_verification_notice.dart';
import 'services/firebase_account_service.dart';
import 'sign_up.dart';
import 'widgets/google_auth_button.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  bool _obscurePassword = true;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = false;
  bool _googleLoading = false;
  bool _resetLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    FocusManager.instance.primaryFocus?.unfocus();

    final identifier = _emailController.text.trim();
    final password = _passwordController.text;
    if (identifier.isEmpty || password.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password')),
      );
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final credential = await FirebaseAccountService.signInWithEmailOrUsername(
        identifier: identifier,
        password: password,
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(
        '/dashboard',
        arguments: {'email': credential.user?.email},
      );
    } catch (e) {
      if (mounted) {
        if (FirebaseAccountService.isEmailNotVerifiedError(e)) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => EmailVerificationNoticeScreen(
                email: FirebaseAccountService.emailFromEmailNotVerifiedError(e),
              ),
            ),
          );
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(FirebaseAccountService.messageForError(e))),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _sendPasswordReset() async {
    FocusManager.instance.primaryFocus?.unfocus();

    final identifier = _emailController.text.trim();

    if (identifier.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masukkan email atau username terlebih dahulu.'),
        ),
      );
      return;
    }

    setState(() {
      _resetLoading = true;
    });

    try {
      await FirebaseAccountService.sendPasswordResetForIdentifier(identifier);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Jika akun ditemukan, link reset password sudah dikirim ke email Anda.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _resetLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFCFB),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: (constraints.maxHeight - 64) < 0
                      ? 0
                      : (constraints.maxHeight - 64),
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.black,
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),
                      const Center(
                        child: Text(
                          'GreenPoint',
                          style: TextStyle(
                            color: Color(0xFF4CAF50),
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Roboto',
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      const Text(
                        'Masuk',
                        style: TextStyle(
                          color: Color(0xFF333333),
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Roboto',
                        ),
                      ),
                      const SizedBox(height: 30),
                      _buildInputContainer(
                        child: TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            fontFamily: 'Roboto',
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Email or Username',
                            hintStyle: TextStyle(
                              color: Color(0xFF7A867E),
                              fontSize: 14,
                              fontFamily: 'Roboto',
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(16),
                            isDense: true,
                          ),
                        ),
                      ),
                      _buildInputContainer(
                        child: TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) {
                            if (!_loading) _signIn();
                          },
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            fontFamily: 'Roboto',
                          ),
                          decoration: InputDecoration(
                            hintText: 'Password (min. 8 characters)',
                            hintStyle: const TextStyle(
                              color: Color(0xFF7A867E),
                              fontSize: 14,
                              fontFamily: 'Roboto',
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.fromLTRB(
                              16,
                              16,
                              0,
                              16,
                            ),
                            isDense: true,
                            suffixIconConstraints: const BoxConstraints(
                              minWidth: 48,
                              maxWidth: 48,
                              minHeight: 48,
                              maxHeight: 48,
                            ),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                              padding: const EdgeInsets.all(12),
                              splashRadius: 20,
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                size: 24,
                                color: const Color(0xFF333333),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _resetLoading ? null : _sendPasswordReset,
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF315A39),
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: _resetLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF315A39),
                                  ),
                                )
                              : const Text(
                                  'Lupa Password?',
                                  style: TextStyle(
                                    color: Color(0xFF315A39),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Roboto',
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _signIn,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF315A39),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: _loading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Masuk',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    fontFamily: 'Roboto',
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const SignUpScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              'Belum Punya Akun? Daftar',
                              style: TextStyle(
                                color: Color(0xFF666666),
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Roboto',
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      const SizedBox(
                        width: double.infinity,
                        child: Text(
                          'Atau Masuk Dengan',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF999999),
                            fontSize: 14,
                            fontFamily: 'Roboto',
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      GoogleAuthButton(
                        label: 'Masuk dengan Google',
                        isLoading: _googleLoading,
                        onTap: _googleLoading ? null : _signInWithGoogle,
                      ),
                      const SizedBox(height: 40),
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

  Widget _buildInputContainer({required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE1E8E1)),
      ),
      child: child,
    );
  }

  Future<void> _signInWithGoogle() async {
    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _googleLoading = true;
    });

    try {
      final credential = await FirebaseAccountService.signInWithGoogle();
      if (credential == null) {
        return;
      }

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(
        '/dashboard',
        arguments: {'email': credential.user?.email},
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(FirebaseAccountService.messageForGoogleError(e)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _googleLoading = false;
        });
      }
    }
  }
}
