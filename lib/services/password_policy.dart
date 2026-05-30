class PasswordPolicy {
  const PasswordPolicy._();

  static const String requirementsMessage =
      'Kata sandi harus minimal 8 karakter, mengandung huruf besar (A-Z), '
      'huruf kecil (a-z), angka (0-9), dan karakter khusus (!@#\$%^&*).';

  static const String legacyPasswordWarning =
      'Kata sandi akun ini belum memenuhi standar keamanan terbaru. '
      'Kamu tetap bisa masuk, tetapi sebaiknya ganti password melalui fitur Lupa Password.';

  static String? validate(String password) {
    if (password.length < 8 ||
        !RegExp(r'[A-Z]').hasMatch(password) ||
        !RegExp(r'[a-z]').hasMatch(password) ||
        !RegExp(r'[0-9]').hasMatch(password) ||
        !RegExp(r'[!@#$%^&*]').hasMatch(password)) {
      return requirementsMessage;
    }

    return null;
  }

  static bool isStrong(String password) => validate(password) == null;
}
