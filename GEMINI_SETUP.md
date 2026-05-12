# Setup Gemini AI untuk Chatbot

## 📋 Langkah-langkah Setup:

### 1. Dapatkan Gemini API Key (Gratis)
- Buka: https://makersuite.google.com/app/apikey
- Klik tombol **"Create API Key"**
- Pilih **"Create API key in new Google Cloud project"**
- Tunggu sebentar hingga API key terbuat
- Copy API key yang sudah dibuat

### 2. Tambahkan API Key ke File `.env`
- Buka file `.env` di root project
- Ganti `YOUR_GEMINI_API_KEY_HERE` dengan API key yang sudah Anda copy
- Contoh:
  ```
  GEMINI_API_KEY=AIzaSyAbCdEfGhIjKlMnOpQrStUvWxYz1234567890
  ```
- Simpan file

### 3. Package yang Digunakan
- `google_generative_ai: ^0.4.0` - Library untuk mengakses Gemini API
- `flutter_dotenv: ^5.1.0` - Library untuk membaca file `.env`

### 4. Fitur AI Chatbot
- ✅ Respons real-time dari Gemini AI
- ✅ Chat history dipelihara dalam satu session
- ✅ Sistem instruksi untuk konteks Green Point
- ✅ Error handling jika API key tidak ditemukan

### 5. Cara Menggunakan
- Jalankan aplikasi: `flutter run`
- Pergi ke Dashboard
- Klik tombol **"Chat AI"** di bottom navigation
- Mulai chat dengan AI!

## 🔒 Keamanan
- **JANGAN** commit file `.env` ke git
- File `.env` sudah ada di `.gitignore`
- API key Anda aman di lokal

## ❓ Troubleshooting

### Error: "GEMINI_API_KEY tidak ditemukan di file .env"
- Pastikan file `.env` sudah dibuat di root project
- Pastikan API key sudah diisi dengan benar
- Pastikan tidak ada spasi di awal/akhir API key

### Error: "Failed to resolve: google_generative_ai"
- Jalankan `flutter pub get` lagi
- Pastikan internet koneksi stabil

### Chat tidak merespons
- Cek apakah API key valid
- Cek kuota penggunaan Gemini API (free tier unlimited untuk text)
- Cek koneksi internet

## 💡 Tips
- Gemini AI gratis untuk text-only
- Respon lebih cepat dari ChatGPT
- Sistem instruksi sudah dikonfigurasi untuk Green Point
- Bisa customize prompt sesuai kebutuhan di `lib/services/gemini_service.dart`
