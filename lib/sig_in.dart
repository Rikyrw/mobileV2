import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bcrypt/bcrypt.dart';
import 'sign_up.dart';

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
  bool _creatingUser = false;
  bool _fetchingUser = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _fetchUser() async {
    final identifier = _emailController.text.trim();
    if (identifier.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter username or email to fetch')),
      );
      return;
    }

    setState(() {
      _fetchingUser = true;
    });

    try {
        var res = await Supabase.instance.client
          .from('nasabah')
          .select('id_nasabah,user_name,email,password')
          .eq('email', identifier)
          .limit(1);

      // If no result by email, try username
      if (res is List && res.isEmpty) {
        res = await Supabase.instance.client
            .from('nasabah')
            .select('id_nasabah,user_name,email,password')
            .eq('user_name', identifier)
            .limit(1);
      }

      if (res is List && res.isEmpty) {
        debugPrint('Fetch user: not found');
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User not found')));
      } else {
        final record = res is List ? (res as List).first : res;
        debugPrint('Fetch user record: $record');
        final storedPassword = record['password'] as String?;
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Found user. password hash starts with: ${storedPassword?.substring(0, storedPassword.length>20?20:storedPassword.length) ?? 'null'}')));
      }
    } catch (e) {
      debugPrint('Fetch user exception: ${e.toString()}');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fetch exception: ${e.toString()}')));
    } finally {
      if (mounted) setState(() { _fetchingUser = false; });
    }
  }

  Future<void> _signIn() async {
    debugPrint('SignIn button pressed');
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
      // Try Supabase Auth only when identifier looks like an email
      final isEmail = identifier.contains('@');
      if (isEmail) {
        try {
          await Supabase.instance.client.auth.signInWithPassword(
            email: identifier,
            password: password,
          );

          if (mounted) {
            final user = Supabase.instance.client.auth.currentUser;
            if (user != null) {
              Navigator.of(context).pushReplacementNamed('/dashboard');
              return;
            }
          }
        } catch (authErr) {
          debugPrint('Auth sign-in error: $authErr');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Auth failed; trying fallback to nasabah table')),
            );
          }
        }
      } else {
        debugPrint('Identifier is not an email, skipping Supabase Auth and using nasabah fallback');
      }

      // Fallback: check nasabah table by email then username
      // `identifier` may be email or username
        var res = await Supabase.instance.client
          .from('nasabah')
          .select('id_nasabah,user_name,email,password')
          .eq('email', identifier)
          .limit(1);

      // If not found by email, try username
      if (res is List && res.isEmpty) {
        res = await Supabase.instance.client
            .from('nasabah')
            .select('id_nasabah,user_name,email,password')
            .eq('user_name', identifier)
            .limit(1);
      }

      if (res is List && res.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User not found')));
      } else {
        final record = res is List ? (res as List).first : res;
        debugPrint('Fallback record: $record');
        final storedPassword = record['password'] as String?;
        if (storedPassword != null && BCrypt.checkpw(password, storedPassword)) {
          if (!mounted) return;
          Navigator.of(context).pushReplacementNamed('/dashboard');
          return;
        } else {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Login failed: invalid credentials')));
        }
      }
    } catch (e) {
      debugPrint('SignIn unexpected error: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Login error: ${e.toString()}')));
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _createTestUser() async {
    final identifier = _emailController.text.trim();
    final password = _passwordController.text;
    if (identifier.isEmpty || password.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter username/email and password first')),
      );
      return;
    }

    setState(() {
      _creatingUser = true;
    });

    try {
      String userName;
      String email;
      if (identifier.contains('@')) {
        email = identifier;
        userName = identifier.split('@').first;
      } else {
        userName = identifier;
        email = '$identifier@example.com';
      }

      final hashed = BCrypt.hashpw(password, BCrypt.gensalt());

      // Check if username or email already exists to avoid unique constraint errors
      final existingByUsername = await Supabase.instance.client
          .from('nasabah')
          .select('id_nasabah')
          .eq('user_name', userName)
          .limit(1);
      if (existingByUsername is List && existingByUsername.isNotEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User already exists (username)')));
        return;
      }

      final existingByEmail = await Supabase.instance.client
          .from('nasabah')
          .select('id_nasabah')
          .eq('email', email)
          .limit(1);
      if (existingByEmail is List && existingByEmail.isNotEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User already exists (email)')));
        return;
      }

      final insertRes = await Supabase.instance.client.from('nasabah').insert({
        'user_name': userName,
        'nama_lengkap': userName,
        'email': email,
        'no_hp': null,
        'status': 'aktif',
        'saldo': 0,
        'alamat': '',
        'password': hashed,
      }).select();

      if (insertRes is List && insertRes.isNotEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Test user created successfully')));
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Create user: no rows returned')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Create user exception: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _creatingUser = false;
        });
      }
    }
  }

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
                  minHeight: (constraints.maxHeight - 64) < 0 ? 0 : (constraints.maxHeight - 64),
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                        'Sign In',
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
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            fontFamily: 'Roboto',
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Email or Username',
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
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            fontFamily: 'Roboto',
                          ),
                          decoration: InputDecoration(
                            hintText: 'Password (min. 8 characters)',
                            hintStyle: const TextStyle(
                              color: Colors.black,
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
                      const Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Roboto',
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _signIn,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF315A39),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
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
                                  'Sign In',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    fontFamily: 'Roboto',
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const SizedBox(height: 30),
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
                              'New Here? Sign Up',
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
                          'Or Login With',
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
                        height: 70,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildGoogleButton(
                              label: 'Google',
                            ),
                            const SizedBox(width: 10),
                            // _buildSocialButton(
                            //   assetPath: 'assets/google.png',
                            //   label: 'Google',
                            //   fallbackIcon: Icons.public,
                            // ),
                          ],
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

  Widget _buildInputContainer({required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDADADA)),
      ),
      child: child,
    );
  }

  Widget _buildSocialButton({
    required String assetPath,
    required String label,
    required IconData fallbackIcon,
  }) {
    return Container(
      width: 150,
      height: 55,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDADADA)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            assetPath,
            width: 24,
            height: 24,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                fallbackIcon,
                size: 24,
                color: const Color(0xFF333333),
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
        ],
      ),
    );
  }

  Widget _buildGoogleButton({
    required String label,
  }) {
    return Container(
      width: 150,
      height: 55,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color.fromARGB(255, 0, 0, 0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: Colors.white,
            child: Text(
              'G',
              style: TextStyle(
                color: const Color(0xFF4285F4),
                fontSize: 16,
                fontWeight: FontWeight.w700,
                fontFamily: 'Roboto',
              ),
            ),
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
        ],
      ),
    );
  }
}
