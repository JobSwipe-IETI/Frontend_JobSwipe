class AppConfig {
  AppConfig._();

  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue:
      '481782536231-7voacirhb9v58eko1id5rjdt2gjo1r4g.apps.googleusercontent.com',
  );

  static const String googleAndroidClientId =
      '481782536231-g01taglruptu3jeo1pup2ahkn5htrnoc.apps.googleusercontent.com';

  static const String backendBaseUrl = String.fromEnvironment(
    'BACKEND_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );

  static const bool allowCreateVacancyForAll = bool.fromEnvironment(
    'ALLOW_CREATE_VACANCY_FOR_ALL',
    defaultValue: true,
  );
}