import 'package:flutter/material.dart';

import 'services/app_cache_service.dart';
import 'services/greenpoint_api_service.dart';

class PerbaruiProfilScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const PerbaruiProfilScreen({super.key, this.userData});

  @override
  State<PerbaruiProfilScreen> createState() => _PerbaruiProfilScreenState();
}

class _PerbaruiProfilScreenState extends State<PerbaruiProfilScreen> {
  late TextEditingController etNama;
  late TextEditingController etUsername;
  late TextEditingController etEmail;
  late TextEditingController etAlamat;
  late TextEditingController etNoHandphone;

  bool isLoading = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Initialize controllers dengan data yang ada
    etNama = TextEditingController(text: widget.userData?['nama'] ?? '');
    etUsername = TextEditingController(
      text: widget.userData?['username'] ?? '',
    );
    etEmail = TextEditingController(text: widget.userData?['email'] ?? '');
    etAlamat = TextEditingController(text: widget.userData?['alamat'] ?? '');
    etNoHandphone = TextEditingController(
      text: widget.userData?['phone'] ?? '',
    );
  }

  @override
  void dispose() {
    etNama.dispose();
    etUsername.dispose();
    etEmail.dispose();
    etAlamat.dispose();
    etNoHandphone.dispose();
    super.dispose();
  }

  bool _validateInput() {
    if (etNama.text.trim().isEmpty) {
      _showError('Nama tidak boleh kosong');
      return false;
    }
    if (etUsername.text.trim().isEmpty) {
      _showError('Username tidak boleh kosong');
      return false;
    }
    if (etEmail.text.trim().isEmpty) {
      _showError('Email tidak boleh kosong');
      return false;
    }
    if (!_isValidEmail(etEmail.text.trim())) {
      _showError('Format email tidak valid');
      return false;
    }
    if (etAlamat.text.trim().isEmpty) {
      _showError('Alamat tidak boleh kosong');
      return false;
    }
    if (etNoHandphone.text.trim().isEmpty) {
      _showError('No Handphone tidak boleh kosong');
      return false;
    }
    return true;
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  Future<void> _perbaruiProfil() async {
    if (!_validateInput()) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final nama = etNama.text.trim();
      final username = etUsername.text.trim();
      final email = etEmail.text.trim();
      final alamat = etAlamat.text.trim();
      final noHp = etNoHandphone.text.trim();
      final oldEmail = widget.userData?['email'] ?? '';

      final response = await GreenPointApiService.updateProfile(
        oldEmail: oldEmail.toString(),
        fullName: nama,
        userName: username,
        email: email,
        address: alamat,
        phone: noHp,
      );

      if (response != null) {
        AppCacheService.invalidateNasabahByEmail(oldEmail.toString());
        AppCacheService.putNasabahProfile(response);
        _showSuccess('Profil berhasil diperbarui!');
        // Kembali ke screen profil dengan flag update
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } else {
        _showError('Gagal memperbarui profil');
      }
    } catch (e) {
      _showError('Error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: const Color(0xFF315A39),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Perbarui Profil',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  // Nama Lengkap
                  _buildTextField(
                    label: 'Nama Lengkap',
                    controller: etNama,
                    hint: 'Masukkan nama lengkap',
                  ),
                  const SizedBox(height: 16),
                  // Username
                  _buildTextField(
                    label: 'Username',
                    controller: etUsername,
                    hint: 'Masukkan username',
                  ),
                  const SizedBox(height: 16),
                  // Email
                  _buildTextField(
                    label: 'Email',
                    controller: etEmail,
                    hint: 'Masukkan email',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  // Alamat
                  _buildTextField(
                    label: 'Alamat',
                    controller: etAlamat,
                    hint: 'Masukkan alamat',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  // No Handphone
                  _buildTextField(
                    label: 'No Handphone',
                    controller: etNoHandphone,
                    hint: 'Masukkan nomor handphone',
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 30),
                  // Button Perbarui
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _perbaruiProfil,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF315A39),
                        disabledBackgroundColor: Colors.grey[400],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Perbarui Profil',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Button Batal
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF315A39)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Batal',
                        style: TextStyle(
                          color: Color(0xFF315A39),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF333333),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 14),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF315A39), width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
