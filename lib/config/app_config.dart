class AppConfig {
  AppConfig._();

  static const String googleWebClientId =
      '481782536231-7hvevp8cg7cepkfo93esqlpcis1mhjkc.apps.googleusercontent.com';

  static const String googleAndroidClientId =
      '481782536231-g01taglruptu3jeo1pup2ahkn5htrnoc.apps.googleusercontent.com';

  static const String backendBaseUrl = String.fromEnvironment(
    'BACKEND_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );
}