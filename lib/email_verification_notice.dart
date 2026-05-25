import 'package:flutter/material.dart';
import 'package:mob_2/services/greenpoint_api_service.dart';
import 'package:mob_2/sig_in.dart';

class EmailVerificationNoticeScreen extends StatefulWidget {
  const EmailVerificationNoticeScreen({super.key, this.email});

  final String? email;

  @override
  State<EmailVerificationNoticeScreen> createState() =>
      _EmailVerificationNoticeScreenState();
}

class _EmailVerificationNoticeScreenState
    extends State<EmailVerificationNoticeScreen> {
  bool _resending = false;

  String? get _email {
    final value = widget.email?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  Future<void> _resend() async {
    final email = _email;

    if (email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email akun tidak ditemukan.')),
      );
      return;
    }

    setState(() {
      _resending = true;
    });

    try {
      await GreenPointApiService.resendVerificationEmail(email);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email verifikasi baru sudah dikirim.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _resending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = _email;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'GreenPoint',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF4CAF50),
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Roboto',
                    ),
                  ),
                  const SizedBox(height: 36),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFDADADA)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.mark_email_unread_outlined,
                          color: Color(0xFF315A39),
                          size: 44,
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Email belum diverifikasi',
                          style: TextStyle(
                            color: Color(0xFF333333),
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Roboto',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          email == null
                              ? 'Silakan cek email yang digunakan saat daftar, lalu klik link verifikasi dari GreenPoint.'
                              : 'Kami sudah mengirim link verifikasi ke $email. Klik link tersebut agar akun bisa masuk ke dashboard.',
                          style: const TextStyle(
                            color: Color(0xFF666666),
                            fontSize: 14,
                            height: 1.5,
                            fontFamily: 'Roboto',
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _resending ? null : _resend,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF315A39),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            child: _resending
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Kirim ulang email verifikasi'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: TextButton(
                            onPressed: () {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (context) => const SignInScreen(),
                                ),
                                (route) => false,
                              );
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF315A39),
                            ),
                            child: const Text('Kembali ke login'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
