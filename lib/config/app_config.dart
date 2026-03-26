class AppConfig {
  AppConfig._();

  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue:
        '481782536231-7hvevp8cg7cepkfo93esqlpcis1mhjkc.apps.googleusercontent.com',
  );

  static const String googleAndroidClientId = String.fromEnvironment(
    'GOOGLE_ANDROID_CLIENT_ID',
    defaultValue:
        '481782536231-us91oe2ej1qmgtqmv00qehspg1ajjj6i.apps.googleusercontent.com',
  );

  static const String backendBaseUrl = String.fromEnvironment(
    'BACKEND_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );

  static const bool allowCreateVacancyForAll = bool.fromEnvironment(
    'ALLOW_CREATE_VACANCY_FOR_ALL',
    defaultValue: true,
  );
}