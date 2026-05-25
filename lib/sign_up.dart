import 'package:flutter/material.dart';
import 'package:mob_2/email_verification_notice.dart';
import 'package:mob_2/sig_in.dart';
import 'package:mob_2/services/firebase_account_service.dart';
import 'package:mob_2/services/greenpoint_api_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _creating = false;
  bool _googleLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 64,
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
                              color: Color(0xFF2D2525),
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
                              color: Color(0xFF2D2525),
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
                              color: Color(0xFF2D2525),
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
                              color: Color(0xFF2D2525),
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
                              color: Color(0xFF2D2525),
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
                          textInputAction: TextInputAction.next,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            fontFamily: 'Roboto',
                          ),
                          decoration: InputDecoration(
                            hintText: 'Password (min. 8 characters)',
                            hintStyle: const TextStyle(
                              color: Color(0xFF2D2525),
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
                      _buildInputContainer(
                        bottomMargin: 30,
                        child: TextField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          textInputAction: TextInputAction.done,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            fontFamily: 'Roboto',
                          ),
                          decoration: InputDecoration(
                            hintText: 'Confirm Password',
                            hintStyle: const TextStyle(
                              color: Color(0xFF2D2525),
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
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword;
                                });
                              },
                              padding: const EdgeInsets.all(12),
                              splashRadius: 20,
                              icon: Icon(
                                _obscureConfirmPassword
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
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _creating ? null : _signUp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF315A39),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          child: _creating
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
                                  builder: (context) => const SignInScreen(),
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
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: _buildGoogleButton(
                          label: 'Daftar dengan Google',
                          onTap: _googleLoading ? null : _signUpWithGoogle,
                        ),
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

  @override
  void dispose() {
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
    final fullName = _fullNameController.text.trim();
    final userName = _userNameController.text.trim();
    final email = _emailController.text.trim();
    final address = _addressController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (fullName.isEmpty ||
        userName.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirm.isEmpty ||
        phone.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan isi semua field yang wajib')),
      );
      return;
    }

    if (password != confirm) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password dan konfirmasi tidak sama')),
      );
      return;
    }

    if (password.length < 8) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password minimal 8 karakter')),
      );
      return;
    }

    setState(() {
      _creating = true;
    });
    try {
      await GreenPointApiService.registerNasabah(
        fullName: fullName,
        userName: userName,
        email: email,
        password: password,
        confirmPassword: confirm,
        address: address,
        phone: phone,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pendaftaran berhasil. Cek email untuk verifikasi.'),
        ),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => EmailVerificationNoticeScreen(email: email),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(FirebaseAccountService.messageForError(e))),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _creating = false;
        });
      }
    }
  }

  Future<void> _signUpWithGoogle() async {
    setState(() {
      _googleLoading = true;
    });
    try {
      final credential = await FirebaseAccountService.signInWithGoogle();
      if (credential == null) {
        return;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masuk dengan Google berhasil')),
      );
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

  Widget _buildInputContainer({
    required Widget child,
    double bottomMargin = 16,
  }) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: bottomMargin),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDADADA)),
      ),
      child: child,
    );
  }

  Widget _buildGoogleButton({required String label, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 55,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color.fromARGB(255, 0, 0, 0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/google.png',
              width: 24,
              height: 24,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.account_circle,
                  size: 24,
                  color: Color(0xFF4285F4),
                );
              },
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF333333),
                fontSize: 14,
                fontFamily: 'Roboto',
              ),
            ),
            if (_googleLoading) ...[
              const SizedBox(width: 8),
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
