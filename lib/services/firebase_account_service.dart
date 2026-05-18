import 'package:bcrypt/bcrypt.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

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

  static Future<UserCredential> signInWithEmailOrUsername({
    required String identifier,
    required String password,
  }) async {
    _ensureFirebaseReady();
    final email = await _resolveEmail(identifier);

    try {
      return await _signInWithFirebasePassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (error) {
      if (!_shouldTryLegacyNasabahFallback(error)) {
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

  static Future<UserCredential?> signInWithGoogle() async {
    _ensureFirebaseReady();

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

    final googleSignIn = _buildGoogleSignIn();
    final googleUser = await googleSignIn.signIn();

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
    try {
      await _buildGoogleSignIn(requireWebClientId: false).signOut();
    } catch (e) {
      debugPrint('Google sign-out skipped: $e');
    }

    try {
      await Supabase.instance.client.auth.signOut();
    } catch (e) {
      debugPrint('Supabase sign-out skipped: $e');
    }

    if (_isFirebaseReady) {
      await _auth.signOut();
    }
  }

  static String messageForError(Object error) {
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
        case 'missing-firebase-config':
          return error.message ?? _firebaseConfigMessage;
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
      final existingRows = await Supabase.instance.client
          .from('nasabah')
          .select('id_nasabah')
          .eq('email', value)
          .limit(1);

      if (existingRows.isNotEmpty) {
        throw FirebaseAuthException(code: 'email-already-in-use');
      }
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      debugPrint('Supabase email availability lookup skipped: $e');
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
      final client = Supabase.instance.client;
      final existing = await client
          .from('nasabah')
          .select('id_nasabah')
          .eq('email', email)
          .limit(1);

      final payload = <String, dynamic>{
        'user_name': _text(profile['user_name']) ?? email.split('@').first,
        'nama_lengkap':
            _text(profile['nama_lengkap']) ?? email.split('@').first,
        'email': email,
        'no_hp': _text(profile['no_hp']),
        'status': 'aktif',
        'saldo': profile['saldo'] ?? 0,
        'alamat': _text(profile['alamat']) ?? '',
        'photo_url': _text(profile['photo_url']),
        'google_id': _text(profile['google_id']),
      };

      payload.removeWhere((key, value) => value == null);

      if (existing.isNotEmpty) {
        await client.from('nasabah').update(payload).eq('email', email);
        return;
      }

      await client.from('nasabah').insert({
        ...payload,
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'password': 'firebase-auth:${user.uid}',
      });
    } catch (e) {
      debugPrint('Supabase nasabah mirror skipped: $e');
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

    final storedPassword = _text(record['password']);
    final email = _text(record['email'])?.toLowerCase();

    if (storedPassword == null ||
        email == null ||
        storedPassword.startsWith('firebase-auth:') ||
        !_looksLikeBcryptHash(storedPassword) ||
        !BCrypt.checkpw(password, storedPassword)) {
      return null;
    }

    final fullName = _text(record['nama_lengkap']);
    final userName = _text(record['user_name']);
    final address = _text(record['alamat']);
    final phone = _text(record['no_hp']);
    final photoUrl = _text(record['photo_url']);
    final googleId = _text(record['google_id']);
    final balance = record['saldo'] as num?;

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
      final client = Supabase.instance.client;

      if (includeEmailMatch) {
        final emailCandidates = <String>{value, value.toLowerCase()};
        for (final candidate in emailCandidates) {
          final emailRows = await client
              .from('nasabah')
              .select(
                'id_nasabah,user_name,nama_lengkap,email,password,no_hp,alamat,photo_url,google_id,saldo',
              )
              .eq('email', candidate)
              .limit(1);

          if (emailRows.isNotEmpty) {
            return Map<String, dynamic>.from(emailRows.first);
          }
        }
      }

      final userNameRows = await client
          .from('nasabah')
          .select(
            'id_nasabah,user_name,nama_lengkap,email,password,no_hp,alamat,photo_url,google_id,saldo',
          )
          .eq('user_name', value)
          .limit(1);

      if (userNameRows.isNotEmpty) {
        return Map<String, dynamic>.from(userNameRows.first);
      }
    } catch (e) {
      debugPrint('Supabase nasabah lookup skipped: $e');
    }

    return null;
  }

  static Future<void> _markNasabahPasswordManagedByFirebase({
    required String email,
    required String firebaseUid,
  }) async {
    try {
      await Supabase.instance.client
          .from('nasabah')
          .update({'password': 'firebase-auth:$firebaseUid'})
          .eq('email', email);
    } catch (e) {
      debugPrint('Supabase password marker update skipped: $e');
    }
  }

  static bool _looksLikeBcryptHash(String value) {
    return value.startsWith(r'$2a$') ||
        value.startsWith(r'$2b$') ||
        value.startsWith(r'$2x$') ||
        value.startsWith(r'$2y$');
  }

  static GoogleSignIn _buildGoogleSignIn({bool requireWebClientId = true}) {
    const scopes = <String>['email', 'profile'];
    final clientId = dotenv.env['GOOGLE_CLIENT_ID']?.trim();

    if (kIsWeb && (clientId == null || clientId.isEmpty)) {
      if (requireWebClientId) {
        throw FirebaseAuthException(code: 'missing-google-client-id');
      }
      return GoogleSignIn(scopes: scopes);
    }

    if (kIsWeb) {
      return GoogleSignIn(clientId: clientId, scopes: scopes);
    }

    if (clientId != null && clientId.isNotEmpty) {
      return GoogleSignIn(scopes: scopes, serverClientId: clientId);
    }

    return GoogleSignIn(scopes: scopes);
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
      'FIREBASE_MESSAGING_SENDER_ID, dan FIREBASE_PROJECT_ID di file .env, '
      'lalu restart aplikasi.';
}
