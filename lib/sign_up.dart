import 'package:flutter/material.dart';
import 'package:mob_2/email_verification_notice.dart';
import 'package:mob_2/sig_in.dart';
import 'package:mob_2/viewmodels/sign_up_view_model.dart';
import 'package:mob_2/widgets/google_auth_button.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final SignUpViewModel _viewModel = SignUpViewModel();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
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
                            'Daftar Akun',
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
                              controller: _fullNameController,
                              keyboardType: TextInputType.name,
                              textInputAction: TextInputAction.next,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                                fontFamily: 'Roboto',
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Nama Lengkap',
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
                              controller: _userNameController,
                              keyboardType: TextInputType.text,
                              textInputAction: TextInputAction.next,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                                fontFamily: 'Roboto',
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Username',
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
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                                fontFamily: 'Roboto',
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Email',
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
                              controller: _addressController,
                              keyboardType: TextInputType.streetAddress,
                              textInputAction: TextInputAction.next,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                                fontFamily: 'Roboto',
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Alamat',
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
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.next,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                                fontFamily: 'Roboto',
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Nomor Telepon',
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
                              textInputAction: TextInputAction.next,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                                fontFamily: 'Roboto',
                              ),
                              decoration: InputDecoration(
                                hintText: 'Password kuat',
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
                          _buildInputContainer(
                            bottomMargin: 30,
                            child: TextField(
                              controller: _confirmPasswordController,
                              obscureText: _viewModel.obscureConfirmPassword,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) {
                                if (!_viewModel.creating) _signUp();
                              },
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                                fontFamily: 'Roboto',
                              ),
                              decoration: InputDecoration(
                                hintText: 'Confirm Password',
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
                                  onPressed: _viewModel
                                      .toggleConfirmPasswordVisibility,
                                  padding: const EdgeInsets.all(12),
                                  splashRadius: 20,
                                  icon: Icon(
                                    _viewModel.obscureConfirmPassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    size: 24,
                                    color: const Color(0xFF333333),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox.shrink(),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _viewModel.creating ? null : _signUp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF315A39),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: _viewModel.creating
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Daftar',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                        fontFamily: 'Roboto',
                                      ),
                                    ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: InkWell(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const SignInScreen(),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'Sudah punya akun? Masuk',
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
                          const SizedBox(
                            width: double.infinity,
                            child: Text(
                              'Atau Daftar Dengan',
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
                            label: 'Daftar dengan Google',
                            isLoading: _viewModel.googleLoading,
                            onTap: _viewModel.googleLoading
                                ? null
                                : _signUpWithGoogle,
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

  @override
  void dispose() {
    _viewModel.dispose();
    _fullNameController.dispose();
    _userNameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    FocusManager.instance.primaryFocus?.unfocus();

    final result = await _viewModel.signUp(
      fullName: _fullNameController.text,
      userName: _userNameController.text,
      email: _emailController.text,
      address: _addressController.text,
      phone: _phoneController.text,
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
    );
    if (!mounted) return;

    switch (result.type) {
      case SignUpResultType.success:
        _showSnack(result.message);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) =>
                EmailVerificationNoticeScreen(email: result.email),
          ),
        );
        return;
      case SignUpResultType.validationError:
      case SignUpResultType.failure:
        _showSnack(result.message);
        return;
      case SignUpResultType.googleSuccess:
      case SignUpResultType.googleCancelled:
        return;
    }
  }

  Future<void> _signUpWithGoogle() async {
    FocusManager.instance.primaryFocus?.unfocus();

    final result = await _viewModel.signUpWithGoogle();
    if (!mounted) return;

    switch (result.type) {
      case SignUpResultType.googleSuccess:
        _showSnack(result.message);
        Navigator.of(context).pushReplacementNamed(
          '/dashboard',
          arguments: {'email': result.email},
        );
        return;
      case SignUpResultType.failure:
        _showSnack(result.message);
        return;
      case SignUpResultType.success:
      case SignUpResultType.validationError:
      case SignUpResultType.googleCancelled:
        return;
    }
  }

  void _showSnack(String? message) {
    if (message == null || message.isEmpty) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildInputContainer({
    required Widget child,
    double bottomMargin = 16,
  }) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: bottomMargin),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE1E8E1)),
      ),
      child: child,
    );
  }
}
