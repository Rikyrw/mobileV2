class AppConfig {
  const AppConfig._();

  static const greenPointApiBaseUrl = String.fromEnvironment(
    'GREENPOINT_API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api',
  );

  static const topupApiUrl = String.fromEnvironment('TOPUP_API_URL');

  static const googleClientId = String.fromEnvironment('GOOGLE_CLIENT_ID');

  static const firebaseApiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const firebaseAppId = String.fromEnvironment('FIREBASE_APP_ID');
  static const firebaseMessagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
  );
  static const firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
  );
  static const firebaseAuthDomain = String.fromEnvironment(
    'FIREBASE_AUTH_DOMAIN',
  );
  static const firebaseStorageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
  );
  static const firebaseMeasurementId = String.fromEnvironment(
    'FIREBASE_MEASUREMENT_ID',
  );

  static String clean(String value) => value.trim();
}
