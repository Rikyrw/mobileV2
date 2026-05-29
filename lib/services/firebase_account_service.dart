import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mob_2/config/app_config.dart';
import 'package:mob_2/services/app_session_service.dart';
import 'package:mob_2/services/app_cache_service.dart';
import 'package:mob_2/services/greenpoint_api_service.dart';

class EmailNotVerifiedException implements Exception {
  EmailNotVerifiedException(this.email);

  final String email;

  @override
  String toString() => 'Email belum diverifikasi.';
}

class FirebaseAccountService {
  FirebaseAccountService._();

  static FirebaseAuth get _auth => FirebaseAuth.instance;
  static FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  static User? get currentUser {
    try {
      if (!_isFirebaseReady) {
        return null;
      }

      return _auth.currentUser;
    } catch (e) {
      debugPrint('Firebase current user unavailable: $e');
      return null;
    }
  }

  static bool isEmailNotVerifiedError(Object error) {
    return error is EmailNotVerifiedException;
  }

  static String? emailFromEmailNotVerifiedError(Object error) {
    return error is EmailNotVerifiedException ? error.email : null;
  }

  static Future<Map<String, dynamic>> signInWithEmailOrUsername({
    required String identifier,
    required String password,
  }) async {
    await _clearCurrentSessionForAccountSwitch();

    try {
      final user = await GreenPointApiService.verifyManualLogin(
        identifier: identifier,
        password: password,
      );
      AppCacheService.invalidateAll();
      return user;
    } on GreenPointApiException catch (error) {
      if (error.statusCode == 403 &&
          error.message.toLowerCase().contains('email belum diverifikasi')) {
        final email = error.data?['email']?.toString();
        throw EmailNotVerifiedException(email ?? identifier.trim());
      }

      if (error.statusCode == 401) {
        return _signInWithFirebaseAndIssueLaravelToken(
          identifier: identifier,
          password: password,
        );
      }

      rethrow;
    }
  }

  static Future<Map<String, dynamic>> _signInWithFirebaseAndIssueLaravelToken({
    required String identifier,
    required String password,
  }) async {
    final credential = await signInWithFirebaseEmailOrUsername(
      identifier: identifier,
      password: password,
    );
    final user = credential.user;
    final email = user?.email?.trim().toLowerCase();

    if (email == null || email.isEmpty) {
      throw FirebaseAuthException(
        code: 'missing-email',
        message: 'Akun tidak memiliki email.',
      );
    }

    if (GreenPointApiService.accessToken == null ||
        GreenPointApiService.accessToken!.isEmpty) {
      throw GreenPointApiException(
        'Login Firebase berhasil, tetapi token API GreenPoint belum diterima. Coba login ulang.',
        statusCode: 401,
      );
    }

    try {
      final profile = await GreenPointApiService.fetchNasabahByEmail(email);
      if (profile != null) {
        return profile;
      }
    } catch (e) {
      debugPrint('Laravel profile refresh after Firebase login skipped: $e');
    }

    return {
      'email': email,
      'nama_lengkap': user?.displayName,
      'photo_url': user?.photoURL,
    };
  }

  static Future<UserCredential> signInWithFirebaseEmailOrUsername({
    required String identifier,
    required String password,
  }) async {
    _ensureFirebaseReady();
    await _clearCurrentSessionForAccountSwitch();

    final mirroredRecord = await _findNasabahByIdentifier(identifier);
    if (_emailNeedsVerification(mirroredRecord)) {
      throw EmailNotVerifiedException(
        _text(mirroredRecord?['email'])?.toLowerCase() ?? identifier.trim(),
      );
    }

    final email =
        _text(mirroredRecord?['email'])?.toLowerCase() ??
        await _resolveEmail(identifier);
    final storedPassword = _text(mirroredRecord?['password']);

    try {
      final credential = await _signInWithFirebasePassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user != null &&
          mirroredRecord != null &&
          _isFirebasePendingPassword(storedPassword)) {
        await _markNasabahPasswordManagedByFirebase(
          email: email,
          firebaseUid: user.uid,
        );
      }

      return credential;
    } on FirebaseAuthException catch (error) {
      if (!_shouldTryLegacyNasabahFallback(error)) {
        rethrow;
      }

      if (_isFirebaseBackedPassword(storedPassword)) {
        rethrow;
      }

      final migratedCredential = await _tryMigrateLegacyNasabahAccount(
        identifier: identifier,
        password: password,
      );

      if (migratedCredential != null) {
        return migratedCredential;
      }

      rethrow;
    }
  }

  static Future<UserCredential> createEmailPasswordAccount({
    required String fullName,
    required String userName,
    required String email,
    required String password,
    String? address,
    String? phone,
  }) async {
    _ensureFirebaseReady();
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedUserName = userName.trim();

    await _assertEmailAvailableInMirror(normalizedEmail);
    await _assertUsernameAvailable(normalizedUserName);

    final credential = await _auth.createUserWithEmailAndPassword(
      email: normalizedEmail,
      password: password,
    );

    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'missing-user',
        message: 'Firebase tidak mengembalikan data pengguna.',
      );
    }

    await user.updateDisplayName(fullName.trim());

    await _upsertUserProfile(
      user: user,
      provider: 'password',
      fullName: fullName,
      userName: normalizedUserName,
      address: address,
      phone: phone,
    );

    return credential;
  }

  static Future<String> sendPasswordResetForIdentifier(
    String identifier,
  ) async {
    final normalizedIdentifier = identifier.trim();
    String? email;

    try {
      email = await _resolveEmail(normalizedIdentifier);
    } catch (e) {
      debugPrint('Password reset email lookup skipped: $e');
    }

    return GreenPointApiService.sendPasswordReset(
      normalizedIdentifier,
      email: email,
    );
  }

  static Future<UserCredential?> signInWithGoogle() async {
    _ensureFirebaseReady();
    await _clearCurrentSessionForAccountSwitch(disconnectGoogle: !kIsWeb);

    if (kIsWeb) {
      final provider = GoogleAuthProvider()
        ..addScope('email')
        ..addScope('profile');
      final userCredential = await _auth.signInWithPopup(provider);
      final user = userCredential.user;

      if (user != null) {
        await _upsertUserProfile(
          user: user,
          provider: 'google',
          fullName: user.displayName,
          userName: user.email?.split('@').first,
          photoUrl: user.photoURL,
          googleId: _providerUid(user, GoogleAuthProvider.PROVIDER_ID),
        );
      }

      return userCredential;
    }

    final googleUser = await _signInWithGoogleAccount();

    if (googleUser == null) {
      return null;
    }

    final googleAuth = await googleUser.authentication;
    if (googleAuth.accessToken == null && googleAuth.idToken == null) {
      throw FirebaseAuthException(
        code: 'missing-google-token',
        message: 'Token Google tidak diterima. Coba masuk ulang.',
      );
    }

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final userCredential = await _auth.signInWithCredential(credential);

    final user = userCredential.user;
    if (user != null) {
      await _upsertUserProfile(
        user: user,
        provider: 'google',
        fullName: googleUser.displayName,
        userName: googleUser.email.split('@').first,
        photoUrl: googleUser.photoUrl,
        googleId: googleUser.id,
      );
    }

    return userCredential;
  }

  static Future<GoogleSignInAccount?> _signInWithGoogleAccount() async {
    try {
      return await _buildGoogleSignIn().signIn();
    } on PlatformException catch (error) {
      if (!_isGoogleDeveloperError(error)) {
        throw _googlePlatformError(error);
      }

      debugPrint(
        'Google Sign-In retried without serverClientId after ApiException: 10.',
      );

      try {
        await _buildGoogleSignIn(useServerClientId: false).signOut();
      } catch (_) {}

      try {
        return await _buildGoogleSignIn(useServerClientId: false).signIn();
      } on PlatformException catch (retryError) {
        throw _googlePlatformError(retryError);
      }
    }
  }

  static Future<Map<String, dynamic>?> currentUserProfile() async {
    if (!_isFirebaseReady) {
      return null;
    }

    final user = currentUser;
    if (user == null) {
      return null;
    }

    final snapshot = await _users.doc(user.uid).get();
    if (!snapshot.exists) {
      return _upsertUserProfile(
        user: user,
        provider: user.providerData.isNotEmpty
            ? user.providerData.first.providerId
            : 'firebase',
        fullName: user.displayName,
        userName: user.email?.split('@').first,
        photoUrl: user.photoURL,
      );
    }

    return snapshot.data();
  }

  static Future<void> signOut() async {
    await AppSessionService.clear();
    AppCacheService.invalidateAll();

    try {
      await GreenPointApiService.logout();
    } catch (e) {
      GreenPointApiService.clearAuthToken();
      debugPrint('Laravel token logout skipped: $e');
    }

    try {
      await _buildGoogleSignIn(requireWebClientId: false).signOut();
    } catch (e) {
      debugPrint('Google sign-out skipped: $e');
    }

    if (_isFirebaseReady) {
      await _auth.signOut();
    }
  }

  static Future<void> _clearCurrentSessionForAccountSwitch({
    bool disconnectGoogle = false,
  }) async {
    await AppSessionService.clear();
    GreenPointApiService.clearAuthToken();

    try {
      final googleSignIn = _buildGoogleSignIn(requireWebClientId: false);
      if (disconnectGoogle) {
        await googleSignIn.disconnect();
      } else {
        await googleSignIn.signOut();
      }
    } catch (e) {
      debugPrint('Google account switch sign-out skipped: $e');
      try {
        await _buildGoogleSignIn(requireWebClientId: false).signOut();
      } catch (_) {}
    }

    if (_isFirebaseReady) {
      await _auth.signOut();
    }

    AppCacheService.invalidateAll();
  }

  static String messageForError(Object error) {
    if (error is EmailNotVerifiedException) {
      return 'Email belum diverifikasi. Cek email Anda atau kirim ulang link verifikasi.';
    }

    if (error is GreenPointApiException) {
      return error.message;
    }

    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'Format email tidak valid.';
        case 'user-disabled':
          return 'Akun ini dinonaktifkan.';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Email/username atau password salah.';
        case 'email-already-in-use':
          return 'Email sudah terdaftar.';
        case 'weak-password':
          return 'Password terlalu lemah.';
        case 'username-already-in-use':
          return 'Username sudah terdaftar.';
        case 'popup-closed-by-user':
          return 'Login Google dibatalkan.';
        case 'missing-google-client-id':
          return 'GOOGLE_CLIENT_ID belum diset untuk login Google di web.';
        case 'missing-google-token':
          return error.message ?? 'Token Google tidak diterima.';
        case 'google-developer-error':
          return error.message ??
              'Konfigurasi login Google belum cocok. Cek package name dan SHA-1/SHA-256 di Firebase.';
        case 'missing-firebase-config':
          return error.message ?? _firebaseConfigMessage;
        case 'reset-email-sent':
          return 'Link reset password sudah dikirim ke email Anda.';
        default:
          return error.message ?? 'Terjadi kesalahan autentikasi.';
      }
    }

    if (error is FirebaseException) {
      if (error.code == 'no-app' || error.code == 'core/no-app') {
        return _firebaseConfigMessage;
      }

      return error.message ?? 'Terjadi kesalahan Firebase.';
    }

    return error.toString();
  }

  static String messageForGoogleError(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-credential':
          return 'Login Google gagal karena credential OAuth tidak cocok. Pastikan Google provider aktif di Firebase dan OAuth Web Client ID berasal dari project Firebase yang sama.';
        case 'account-exists-with-different-credential':
          return 'Email Google ini sudah terdaftar dengan metode login lain. Coba masuk pakai email/password dulu, lalu hubungkan Google.';
        case 'popup-closed-by-user':
        case 'web-context-cancelled':
          return 'Login Google dibatalkan.';
        case 'popup-blocked':
          return 'Popup Google diblokir browser. Izinkan popup untuk localhost lalu coba lagi.';
        case 'operation-not-allowed':
          return 'Provider Google belum aktif di Firebase Authentication.';
        case 'unauthorized-domain':
          return 'Domain ini belum diizinkan di Firebase Authentication. Tambahkan localhost di Authorized domains.';
        case 'missing-google-client-id':
          return 'GOOGLE_CLIENT_ID belum diset untuk login Google.';
        case 'missing-google-token':
          return error.message ?? 'Token Google tidak diterima.';
        case 'missing-firebase-config':
          return error.message ?? _firebaseConfigMessage;
        default:
          return error.message ?? 'Login Google gagal.';
      }
    }

    if (error is FirebaseException) {
      if (error.code == 'no-app' || error.code == 'core/no-app') {
        return _firebaseConfigMessage;
      }

      return error.message ?? 'Login Google gagal.';
    }

    if (error is PlatformException) {
      return _googlePlatformError(error).message ?? 'Login Google gagal.';
    }

    return error.toString();
  }

  static Future<String> _resolveEmail(String identifier) async {
    final value = identifier.trim().toLowerCase();
    if (value.contains('@')) {
      return value;
    }

    final mirroredEmail = await _findMirroredEmailByUsername(identifier);
    if (mirroredEmail != null) {
      return mirroredEmail;
    }

    try {
      final snapshot = await _users
          .where('user_name_lowercase', isEqualTo: value)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final email = _text(snapshot.docs.first.data()['email'])?.toLowerCase();
        if (email != null) {
          return email;
        }
      }
    } catch (e) {
      debugPrint('Firestore username lookup skipped: $e');
    }

    throw FirebaseAuthException(code: 'user-not-found');
  }

  static Future<void> _assertUsernameAvailable(String userName) async {
    final value = userName.trim().toLowerCase();
    if (value.isEmpty) {
      return;
    }

    final mirroredUser = await _findNasabahByIdentifier(
      userName,
      includeEmailMatch: false,
    );
    if (mirroredUser != null) {
      throw FirebaseAuthException(code: 'username-already-in-use');
    }

    final snapshot = await _users
        .where('user_name_lowercase', isEqualTo: value)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      throw FirebaseAuthException(code: 'username-already-in-use');
    }
  }

  static Future<void> _assertEmailAvailableInMirror(String email) async {
    final value = email.trim().toLowerCase();
    if (value.isEmpty) {
      return;
    }

    try {
      if (await GreenPointApiService.emailExists(value)) {
        throw FirebaseAuthException(code: 'email-already-in-use');
      }
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      debugPrint('Laravel email availability lookup skipped: $e');
    }
  }

  static Future<Map<String, dynamic>> _upsertUserProfile({
    required User user,
    required String provider,
    String? fullName,
    String? userName,
    String? address,
    String? phone,
    String? photoUrl,
    String? googleId,
    num? balance,
  }) async {
    final email = _text(user.email)?.toLowerCase();
    if (email == null) {
      throw FirebaseAuthException(
        code: 'missing-email',
        message: 'Akun Firebase tidak memiliki email.',
      );
    }

    final ref = _users.doc(user.uid);
    final snapshot = await ref.get();
    final existing = snapshot.data() ?? <String, dynamic>{};

    final existingUserName = _text(existing['user_name']);
    final providedUserName = _text(userName);
    final existingFullName = _text(existing['nama_lengkap']);
    final providedFullName = _text(fullName) ?? _text(user.displayName);

    final resolvedUserName = snapshot.exists
        ? existingUserName ?? providedUserName ?? email.split('@').first
        : providedUserName ?? existingUserName ?? email.split('@').first;
    final resolvedFullName = snapshot.exists
        ? existingFullName ?? providedFullName ?? resolvedUserName
        : providedFullName ?? existingFullName ?? resolvedUserName;
    final resolvedAddress = _text(address) ?? _text(existing['alamat']) ?? '';
    final resolvedPhone = _text(phone) ?? _text(existing['no_hp']);
    final resolvedPhoto =
        _text(photoUrl) ?? _text(user.photoURL) ?? _text(existing['photo_url']);
    final resolvedBalance = snapshot.exists
        ? (existing['saldo'] as num?) ?? balance ?? 0
        : balance ?? (existing['saldo'] as num?) ?? 0;

    final data = <String, dynamic>{
      'uid': user.uid,
      'email': email,
      'user_name': resolvedUserName,
      'user_name_lowercase': resolvedUserName.toLowerCase(),
      'nama_lengkap': resolvedFullName,
      'alamat': resolvedAddress,
      'status': 'aktif',
      'provider': provider,
      'updated_at': FieldValue.serverTimestamp(),
    };

    if (resolvedPhone != null) {
      data['no_hp'] = resolvedPhone;
    }

    if (resolvedPhoto != null) {
      data['photo_url'] = resolvedPhoto;
    }

    if (googleId != null) {
      data['google_id'] = googleId;
    }

    if (!snapshot.exists) {
      data['saldo'] = resolvedBalance;
      data['created_at'] = FieldValue.serverTimestamp();
    }

    await ref.set(data, SetOptions(merge: true));

    final profile = <String, dynamic>{
      ...existing,
      ...data,
      'uid': user.uid,
      'email': email,
      'user_name': resolvedUserName,
      'nama_lengkap': resolvedFullName,
      'alamat': resolvedAddress,
      'no_hp': resolvedPhone,
      'photo_url': resolvedPhoto,
      'google_id': googleId ?? existing['google_id'],
      'saldo': resolvedBalance,
    };

    await _syncNasabahMirror(user: user, profile: profile);
    return profile;
  }

  static Future<void> _syncNasabahMirror({
    required User user,
    required Map<String, dynamic> profile,
  }) async {
    final email = _text(profile['email']);
    if (email == null) {
      return;
    }

    try {
      final mirrored = await GreenPointApiService.mirrorNasabahProfile(
        firebaseUid: user.uid,
        email: email,
        userName: _text(profile['user_name']) ?? email.split('@').first,
        fullName: _text(profile['nama_lengkap']) ?? email.split('@').first,
        phone: _text(profile['no_hp']),
        address: _text(profile['alamat']) ?? '',
        photoUrl: _text(profile['photo_url']),
        googleId: _text(profile['google_id']),
        provider: _text(profile['provider']),
        balance: profile['saldo'] as num? ?? 0,
      );

      final currentBalance = mirrored?['saldo'] as num?;
      if (currentBalance != null) {
        await _users.doc(user.uid).set({
          'saldo': currentBalance,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Laravel nasabah mirror skipped: $e');
    }
  }

  static Future<UserCredential> _signInWithFirebasePassword({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user;
    if (user != null) {
      await _upsertUserProfile(
        user: user,
        provider: 'password',
        fullName: user.displayName,
      );
    }

    return credential;
  }

  static bool _shouldTryLegacyNasabahFallback(FirebaseAuthException error) {
    return error.code == 'user-not-found' ||
        error.code == 'wrong-password' ||
        error.code == 'invalid-credential';
  }

  static Future<UserCredential?> _tryMigrateLegacyNasabahAccount({
    required String identifier,
    required String password,
  }) async {
    final record = await _findNasabahByIdentifier(identifier);
    if (record == null) {
      return null;
    }

    if (_emailNeedsVerification(record)) {
      throw EmailNotVerifiedException(
        _text(record['email'])?.toLowerCase() ?? identifier.trim(),
      );
    }

    final storedPassword = _text(record['password']);

    if (_isFirebaseBackedPassword(storedPassword)) {
      return null;
    }

    final verifiedUser =
        await _verifyManualLoginWithBackend(
          identifier: identifier,
          password: password,
        ) ??
        await _verifyManualLoginLocally(record: record, password: password);

    if (verifiedUser == null) {
      return null;
    }

    final email =
        _text(verifiedUser['email'])?.toLowerCase() ??
        _text(record['email'])?.toLowerCase();

    if (email == null) {
      return null;
    }

    final fullName =
        _text(verifiedUser['nama_lengkap']) ?? _text(record['nama_lengkap']);
    final userName =
        _text(verifiedUser['user_name']) ?? _text(record['user_name']);
    final address = _text(verifiedUser['alamat']) ?? _text(record['alamat']);
    final phone = _text(verifiedUser['no_hp']) ?? _text(record['no_hp']);
    final photoUrl =
        _text(verifiedUser['photo_url']) ?? _text(record['photo_url']);
    final googleId =
        _text(verifiedUser['google_id']) ?? _text(record['google_id']);
    final balance = verifiedUser['saldo'] as num? ?? record['saldo'] as num?;

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'missing-user',
          message: 'Firebase tidak mengembalikan data pengguna.',
        );
      }

      if (fullName != null) {
        await user.updateDisplayName(fullName);
      }

      await _upsertUserProfile(
        user: user,
        provider: 'password',
        fullName: fullName,
        userName: userName,
        address: address,
        phone: phone,
        photoUrl: photoUrl,
        googleId: googleId,
        balance: balance,
      );
      await _markNasabahPasswordManagedByFirebase(
        email: email,
        firebaseUid: user.uid,
      );

      return credential;
    } on FirebaseAuthException catch (error) {
      if (error.code != 'email-already-in-use') {
        rethrow;
      }

      final credential = await _signInWithFirebasePassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user != null) {
        await _markNasabahPasswordManagedByFirebase(
          email: email,
          firebaseUid: user.uid,
        );
      }
      return credential;
    }
  }

  static Future<Map<String, dynamic>?> _verifyManualLoginWithBackend({
    required String identifier,
    required String password,
  }) async {
    try {
      return await GreenPointApiService.verifyManualLogin(
        identifier: identifier,
        password: password,
      );
    } on GreenPointApiException catch (error) {
      if (error.message.toLowerCase().contains('email belum diverifikasi')) {
        throw EmailNotVerifiedException(identifier.trim());
      }

      return null;
    }
  }

  static Future<Map<String, dynamic>?> _verifyManualLoginLocally({
    required Map<String, dynamic> record,
    required String password,
  }) async {
    final storedPassword = _text(record['password']);
    if (storedPassword == null || _isFirebaseBackedPassword(storedPassword)) {
      return null;
    }

    try {
      if (_isBcryptHash(storedPassword) &&
          BCrypt.checkpw(password, storedPassword)) {
        return record;
      }

      if (!_isBcryptHash(storedPassword) && storedPassword == password) {
        return record;
      }
    } catch (e) {
      debugPrint('Local legacy password verification skipped: $e');
    }

    return null;
  }

  static Future<String?> _findMirroredEmailByUsername(String userName) async {
    final record = await _findNasabahByIdentifier(
      userName,
      includeEmailMatch: false,
    );
    return _text(record?['email'])?.toLowerCase();
  }

  static Future<Map<String, dynamic>?> _findNasabahByIdentifier(
    String identifier, {
    bool includeEmailMatch = true,
  }) async {
    final value = identifier.trim();
    if (value.isEmpty) {
      return null;
    }

    try {
      return await GreenPointApiService.lookupNasabah(
        value,
        includeEmailMatch: includeEmailMatch,
      );
    } catch (e) {
      debugPrint('Laravel nasabah lookup skipped: $e');
    }

    return null;
  }

  static Future<void> _markNasabahPasswordManagedByFirebase({
    required String email,
    required String firebaseUid,
  }) async {
    try {
      await GreenPointApiService.markPasswordManagedByFirebase(
        email: email,
        firebaseUid: firebaseUid,
      );
    } catch (e) {
      debugPrint('Laravel password marker update skipped: $e');
    }
  }

  static bool _isFirebaseBackedPassword(String? value) {
    return value != null &&
        (value.startsWith('firebase-auth:') ||
            value == 'firebase-auth-pending');
  }

  static bool _isFirebasePendingPassword(String? value) {
    return value == 'firebase-auth-pending';
  }

  static bool _isBcryptHash(String value) {
    return value.startsWith(r'$2a$') ||
        value.startsWith(r'$2b$') ||
        value.startsWith(r'$2y$');
  }

  static bool _emailNeedsVerification(Map<String, dynamic>? record) {
    if (record == null || !record.containsKey('email_verified_at')) {
      return false;
    }

    final googleId = _text(record['google_id']);

    return googleId == null && _text(record['email_verified_at']) == null;
  }

  static GoogleSignIn _buildGoogleSignIn({
    bool requireWebClientId = true,
    bool useServerClientId = true,
  }) {
    const scopes = <String>['email', 'profile'];
    final clientId = AppConfig.clean(AppConfig.googleClientId);

    if (kIsWeb && clientId.isEmpty) {
      if (requireWebClientId) {
        throw FirebaseAuthException(code: 'missing-google-client-id');
      }
      return GoogleSignIn(scopes: scopes);
    }

    if (kIsWeb) {
      return GoogleSignIn(clientId: clientId, scopes: scopes);
    }

    if (useServerClientId && clientId.isNotEmpty) {
      return GoogleSignIn(scopes: scopes, serverClientId: clientId);
    }

    return GoogleSignIn(scopes: scopes);
  }

  static bool _isGoogleDeveloperError(PlatformException error) {
    final text = '${error.code} ${error.message} ${error.details}';
    return text.contains('ApiException: 10') ||
        text.contains('DEVELOPER_ERROR');
  }

  static FirebaseAuthException _googlePlatformError(PlatformException error) {
    if (_isGoogleDeveloperError(error)) {
      return FirebaseAuthException(
        code: 'google-developer-error',
        message:
            'Konfigurasi login Google belum cocok. Tambahkan SHA-1/SHA-256 aplikasi ini ke Firebase, aktifkan provider Google, lalu unduh ulang konfigurasi.',
      );
    }

    if (error.code == 'sign_in_canceled') {
      return FirebaseAuthException(code: 'popup-closed-by-user');
    }

    return FirebaseAuthException(
      code: error.code,
      message: error.message ?? 'Login Google gagal.',
    );
  }

  static String? _text(Object? value) {
    if (value == null) {
      return null;
    }

    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static String? _providerUid(User user, String providerId) {
    for (final info in user.providerData) {
      if (info.providerId == providerId) {
        return _text(info.uid);
      }
    }

    return null;
  }

  static bool get _isFirebaseReady {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static void _ensureFirebaseReady() {
    if (_isFirebaseReady) {
      return;
    }

    throw FirebaseAuthException(
      code: 'missing-firebase-config',
      message: _firebaseConfigMessage,
    );
  }

  static const String _firebaseConfigMessage =
      'Firebase belum dikonfigurasi. Isi FIREBASE_API_KEY, FIREBASE_APP_ID, '
      'FIREBASE_MESSAGING_SENDER_ID, dan FIREBASE_PROJECT_ID lewat '
      '--dart-define atau jalankan flutterfire configure.';
}
