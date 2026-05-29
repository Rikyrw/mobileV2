import 'package:flutter/material.dart';

import 'viewmodels/edit_profile_view_model.dart';
import 'widgets/greenpoint_header.dart';

class PerbaruiProfilScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const PerbaruiProfilScreen({super.key, this.userData});

  @override
  State<PerbaruiProfilScreen> createState() => _PerbaruiProfilScreenState();
}

class _PerbaruiProfilScreenState extends State<PerbaruiProfilScreen> {
  late final EditProfileViewModel _viewModel;
  late TextEditingController etNama;
  late TextEditingController etUsername;
  late TextEditingController etEmail;
  late TextEditingController etAlamat;
  late TextEditingController etNoHandphone;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _viewModel = EditProfileViewModel(userData: widget.userData);
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
    _viewModel.dispose();
    super.dispose();
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
    final result = await _viewModel.updateProfile(
      fullName: etNama.text,
      userName: etUsername.text,
      email: etEmail.text,
      address: etAlamat.text,
      phone: etNoHandphone.text,
    );
    if (!mounted) return;

    switch (result.type) {
      case EditProfileResultType.success:
        _showSuccess(result.message);
        Navigator.of(context).pop(true);
        return;
      case EditProfileResultType.validationError:
      case EditProfileResultType.failure:
        _showError(result.message);
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        final isLoading = _viewModel.loading;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(100),
            child: GreenPointHeader(
              title: 'Perbarui Profil',
              subtitle: 'Lengkapi data akun Green Point',
              avatarText: etNama.text.isNotEmpty
                  ? etNama.text
                  : etUsername.text,
              avatarSize: 58,
              contentAlignment: CrossAxisAlignment.center,
              textAlign: TextAlign.center,
              leading: GreenPointHeaderIconButton(
                icon: Icons.arrow_back_rounded,
                tooltip: 'Kembali',
                onPressed: () => Navigator.of(context).pop(),
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
        );
      },
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
