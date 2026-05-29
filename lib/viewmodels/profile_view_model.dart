import 'package:flutter/foundation.dart';

import '../services/app_cache_service.dart';
import '../services/firebase_account_service.dart';

class ProfilDummyData {
  const ProfilDummyData({
    required this.greeting,
    required this.userName,
    required this.title,
    required this.subtitle,
    required this.fullName,
    required this.username,
    required this.saldo,
    required this.address,
    required this.email,
    required this.phone,
  });

  final String greeting;
  final String userName;
  final String title;
  final String subtitle;
  final String fullName;
  final String username;
  final String saldo;
  final String address;
  final String email;
  final String phone;
}

class ProfileViewModel extends ChangeNotifier {
  static const dummyData = ProfilDummyData(
    greeting: 'Halo,',
    userName: 'Haidar Rais',
    title: 'Profil Saya',
    subtitle: 'Tentang profil saya',
    fullName: 'Jarot Rohim',
    username: 'Jarot User',
    saldo: 'Rp. 0,-',
    address:
        'Jl. Mastrip, Krajan Timur, Sumbersari, Kec. Sumbersari, Kabupaten Jember, Java Timur 68121',
    email: 'dhimas@example.com',
    phone: '081234567890',
  );

  String? _fetchedUserName;
  bool _loadingProfile = false;
  String? _currentEmail;
  String? _fetchedFullName;
  String? _fetchedUsername;
  String? _fetchedEmail;
  String? _fetchedPhone;
  String? _fetchedAddress;
  String? _fetchedSaldo;

  bool get loadingProfile => _loadingProfile;
  String? get currentEmail => _currentEmail;
  String get userName => _fetchedUserName ?? dummyData.userName;
  String get fullName => _fetchedFullName ?? dummyData.fullName;
  String get username => _fetchedUsername ?? dummyData.username;
  String get email => _fetchedEmail ?? dummyData.email;
  String get phone => _fetchedPhone ?? dummyData.phone;
  String get address => _fetchedAddress ?? dummyData.address;
  String get saldo => _fetchedSaldo ?? dummyData.saldo;

  Map<String, dynamic> get editableUserData {
    return {
      'nama': fullName,
      'username': username,
      'email': email,
      'alamat': address,
      'phone': phone,
    };
  }

  Object get routeArguments => {'email': _currentEmail};

  Future<void> loadProfile({
    String? emailArgument,
    bool forceRefresh = false,
  }) async {
    if (_loadingProfile) return;
    _setLoadingProfile(true);

    try {
      final firebaseUser = FirebaseAccountService.currentUser;
      final email = emailArgument ?? firebaseUser?.email ?? _currentEmail;
      _currentEmail = email;
      _notify();

      if (email != null && email.isNotEmpty) {
        final record = await AppCacheService.fetchNasabahByEmail(
          email,
          forceRefresh: forceRefresh,
        );

        if (record != null) {
          _applyRecord(record);
          return;
        }

        final firebaseProfile =
            await FirebaseAccountService.currentUserProfile();
        if (firebaseProfile != null && firebaseProfile['email'] == email) {
          _applyRecord(firebaseProfile);
        }
      }
    } catch (e) {
      debugPrint('Load user name error: $e');
    } finally {
      _setLoadingProfile(false);
    }
  }

  Future<void> signOut() async {
    await FirebaseAccountService.signOut();
  }

  void _applyRecord(Map<String, dynamic> record) {
    _fetchedUserName =
        (record['nama_lengkap'] as String?) ?? (record['user_name'] as String?);
    _fetchedFullName = record['nama_lengkap'] as String?;
    _fetchedUsername = record['user_name'] as String?;
    _fetchedEmail = record['email'] as String?;
    _fetchedPhone = record['no_hp'] as String?;
    _fetchedAddress = record['alamat'] as String?;
    _fetchedSaldo = record['saldo'] != null ? 'Rp ${record['saldo']}' : 'Rp 0';
    _notify();
  }

  void _setLoadingProfile(bool value) {
    if (_loadingProfile == value) return;
    _loadingProfile = value;
    _notify();
  }

  void _notify() {
    if (hasListeners) notifyListeners();
  }
}
