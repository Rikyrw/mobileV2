class ChatbotKnowledgeBase {
  const ChatbotKnowledgeBase();

  static String normalizeText(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String? answerFor(String question) {
    final q = normalizeText(question);

    if (q.isEmpty) return null;

    if (_containsAny(q, const [
      'daftar',
      'registrasi',
      'buat akun',
      'bikin akun',
      'akun baru',
      'sign up',
    ])) {
      return 'Untuk daftar akun Green Point, dari halaman awal pilih tombol "Daftar". '
          'Isi form Nama Lengkap, Username, Email, Alamat, Nomor Telepon, Password minimal 8 karakter '
          'dengan huruf besar, huruf kecil, angka, karakter khusus, dan Confirm Password, lalu tekan "Daftar". '
          'Kamu juga bisa memilih "Daftar dengan Google". '
          'Jika berhasil, kamu akan langsung diarahkan ke dashboard.';
    }

    if (_containsAny(q, const [
      'cara masuk',
      'mau masuk',
      'masuk akun',
      'masuk aplikasi',
      'masuknya',
      'login',
      'log in',
      'sign in',
    ])) {
      return 'Untuk masuk, dari halaman awal pilih "Masuk". '
          'Isi Email atau Username dan Password, lalu tekan tombol "Masuk". '
          'Kamu juga bisa memakai tombol "Masuk dengan Google". Jika berhasil, kamu akan masuk ke dashboard.';
    }

    if (_containsAny(q, const [
      'setor sampah',
      'ajukan setor',
      'jenis sampah',
      'hitung total',
    ])) {
      return 'Untuk setor sampah, buka dashboard lalu pilih "Transaksi Setor Sampah". '
          'Tekan "+ Tambah Jenis Sampah", pilih jenis sampah, masukkan berat minimal 1 kg, '
          'tambahkan foto untuk setiap jenis sampah yang dipilih, lalu cek total otomatis. '
          'Jika data sudah benar, tekan "Ajukan Setor Sampah".';
    }

    if (_containsAny(q, const ['e money', 'emoney', 'gopay', 'dana'])) {
      return 'Untuk menggunakan E-Money, dari dashboard pilih menu "E-Money". '
          'Isi No Tujuan, pilih kategori nominal, pilih layanan seperti GoPay atau DANA, '
          'lalu tekan "Proses". Pastikan saldo mencukupi sebelum mengirim permintaan.';
    }

    if (_containsAny(q, const ['pln', 'token listrik', 'token pln'])) {
      return 'Untuk membeli token PLN, dari dashboard pilih menu "PLN". '
          'Masukkan No Meter/Token, pilih nominal token, lalu tekan "Beli Token".';
    }

    if (_containsAny(q, const ['pulsa', 'isi pulsa'])) {
      return 'Untuk isi pulsa, dari dashboard pilih menu "Pulsa". '
          'Masukkan nomor telepon, pilih operator, pilih nominal pulsa, lalu tekan "Beli Pulsa".';
    }

    if (_containsAny(q, const [
      'riwayat setor',
      'riwayat sampah',
      'history setor',
    ])) {
      return 'Untuk melihat riwayat setor sampah, buka menu "Riwayat" di navigasi bawah. '
          'Halaman ini menampilkan riwayat setor sampah dan bisa difilter berdasarkan periode tanggal.';
    }

    if (_containsAny(q, const [
      'transaksi ppob',
      'daftar transaksi',
      'status transaksi',
    ])) {
      return 'Untuk melihat transaksi PPOB, buka menu "Transaksi" di navigasi bawah. '
          'Di sana kamu bisa melihat daftar transaksi dan memfilter berdasarkan periode tanggal.';
    }

    if (_containsAny(q, const [
      'profil',
      'perbarui profil',
      'ubah profil',
      'edit profil',
    ])) {
      return 'Untuk melihat atau mengubah profil, buka menu "Profil" di navigasi bawah. '
          'Tekan "Perbarui Profil" untuk mengubah nama, username, email, alamat, atau nomor HP. '
          'Dari halaman profil kamu juga bisa logout dari akun lewat ikon logout.';
    }

    if (_containsAny(q, const [
      'cara pakai',
      'cara menggunakan',
      'gunakan aplikasi',
      'tutorial',
    ])) {
      return 'Alur utama Green Point adalah: daftar atau masuk terlebih dahulu, lalu dari dashboard kamu bisa '
          'memilih layanan seperti Setor Sampah, E-Money, PLN, Pulsa, melihat Transaksi, membuka Riwayat, '
          'atau mengelola Profil.';
    }

    if (_containsAny(q, const ['fitur', 'menu', 'layanan apa'])) {
      return 'Fitur utama Green Point saat ini meliputi Setor Sampah, E-Money, pembelian token PLN, '
          'isi Pulsa, daftar Transaksi PPOB, Riwayat Setor Sampah, Profil, dan Chat AI.';
    }

    if (_containsAny(q, const [
      'limit',
      'kuota',
      'quota',
      'habis',
      'ai sibuk',
    ])) {
      return 'Kalau AI sedang limit, artinya batas penggunaan sementara sudah tercapai. '
          'Tunggu beberapa saat sampai indikator di kanan atas normal kembali.';
    }

    if (_containsAny(q, const [
      'terima kasih',
      'makasih',
      'thanks',
      'thank you',
    ])) {
      return 'Sama-sama! Senang bisa membantu kamu.';
    }

    if (_containsAny(q, const [
      'error',
      'gagal',
      'tidak bisa',
      'bug',
      'masalah',
    ])) {
      return 'Maaf kalau ada kendala. Coba periksa kembali data yang diisi, tutup lalu buka ulang aplikasi, '
          'dan ulangi prosesnya. Jika masih bermasalah, hubungi admin atau pengembang Green Point.';
    }

    if (_containsAny(q, const [
      'green point',
      'greenpoint',
      'aplikasi ini',
      'tentang aplikasi',
    ])) {
      return 'Green Point adalah aplikasi yang membantu pengguna melakukan setor sampah dan mengakses layanan '
          'seperti E-Money, token PLN, Pulsa, Transaksi, Riwayat, Profil, serta bantuan Chat AI dalam satu aplikasi.';
    }

    if (_containsAny(q, const [
      'halo',
      'hallo',
      'hai',
      'hello',
      'hi',
      'pagi',
      'siang',
      'sore',
      'malam',
    ])) {
      return 'Halo! Saya Si Jajang. Ada yang bisa saya bantu hari ini?';
    }

    return null;
  }

  bool _containsAny(String q, List<String> keywords) {
    return keywords.any(q.contains);
  }
}
