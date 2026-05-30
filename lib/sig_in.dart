import 'package:flutter/material.dart';
import 'email_verification_notice.dart';
import 'sign_up.dart';
import 'viewmodels/sign_in_view_model.dart';
import 'widgets/google_auth_button.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final SignInViewModel _viewModel = SignInViewModel();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _viewModel.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    FocusManager.instance.primaryFocus?.unfocus();

    final result = await _viewModel.signIn(
      identifier: _emailController.text,
      password: _passwordController.text,
    );
    await _handleAuthResult(result);
  }

  Future<void> _sendPasswordReset(String identifier) async {
    FocusManager.instance.primaryFocus?.unfocus();

    final result = await _viewModel.sendPasswordReset(identifier);
    _handleMessageResult(result);
  }

  Future<void> _showPasswordResetDialog() async {
    FocusManager.instance.primaryFocus?.unfocus();

    final resetController = TextEditingController(
      text: _emailController.text.trim(),
    );

    try {
      final identifier = await showDialog<String>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Reset Password'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Masukkan email atau username akun yang dibuat lewat form daftar. Akun Google tetap masuk lewat tombol Google.',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: resetController,
                  keyboardType: TextInputType.emailAddress,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Email atau username',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (value) {
                    Navigator.of(dialogContext).pop(value.trim());
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(
                  dialogContext,
                ).pop(resetController.text.trim()),
                child: const Text('Kirim Link'),
              ),
            ],
          );
        },
      );

      if (identifier == null) return;
      await _sendPasswordReset(identifier);
    } finally {
      resetController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
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
                              obscureText: _viewModel.obscurePassword,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) {
                                if (!_viewModel.loading) _signIn();
                              },
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                                fontFamily: 'Roboto',
                              ),
                              decoration: InputDecoration(
                                hintText: 'Password',
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
                                  onPressed:
                                      _viewModel.togglePasswordVisibility,
                                  padding: const EdgeInsets.all(12),
                                  splashRadius: 20,
                                  icon: Icon(
                                    _viewModel.obscurePassword
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
                              onPressed: _viewModel.resetLoading
                                  ? null
                                  : _showPasswordResetDialog,
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF315A39),
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: _viewModel.resetLoading
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
                              onPressed: _viewModel.loading ? null : _signIn,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF315A39),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: _viewModel.loading
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
                                      builder: (context) =>
                                          const SignUpScreen(),
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
                            isLoading: _viewModel.googleLoading,
                            onTap: _viewModel.googleLoading
                                ? null
                                : _signInWithGoogle,
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
      },
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

    final result = await _viewModel.signInWithGoogle();
    await _handleAuthResult(result);
  }

  Future<void> _handleAuthResult(SignInResult result) async {
    if (!mounted) return;

    switch (result.type) {
      case SignInResultType.success:
        await _showPasswordWarningIfNeeded(result.passwordWarning);
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed(
          '/dashboard',
          arguments: {'email': result.email},
        );
        return;
      case SignInResultType.emailVerificationRequired:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) =>
                EmailVerificationNoticeScreen(email: result.email),
          ),
        );
        return;
      case SignInResultType.validationError:
      case SignInResultType.failure:
        _showMessage(result.message);
        return;
      case SignInResultType.cancelled:
      case SignInResultType.resetSent:
        return;
    }
  }

  void _handleMessageResult(SignInResult result) {
    if (!mounted) return;

    switch (result.type) {
      case SignInResultType.resetSent:
      case SignInResultType.validationError:
      case SignInResultType.failure:
        _showMessage(result.message);
        return;
      case SignInResultType.success:
      case SignInResultType.emailVerificationRequired:
      case SignInResultType.cancelled:
        return;
    }
  }

  void _showMessage(String? message) {
    if (message == null || message.isEmpty) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  Future<void> _showPasswordWarningIfNeeded(String? message) async {
    if (message == null || message.isEmpty) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Perbarui Password'),
          content: Text(message),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Lanjut Masuk'),
            ),
          ],
        );
      },
    );
  }
}
