class AppConfig {
  AppConfig._();

  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue:
      '481782536231-7voacirxxxhb9v58eko1id5rjdt2gjo1r4g.apps.googleusercontent.com',
  );

  static const String googleAndroidClientId = String.fromEnvironment(
    'GOOGLE_ANDROID_CLIENT_ID',
    defaultValue:
      '481782536231-7voacirhxxxxb9v58eko1id5rjdt2gjo1r4g.apps.googleusercontent.com',
  );

  static const String backendBaseUrl = String.fromEnvironment(
    'BACKEND_BASE_URL',
    defaultValue: 'http://10.0.2.2:8081',
  );

  static const String aiServiceBaseUrl = String.fromEnvironment(
    'AI_SERVICE_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static const String supabaseMessagesTable = String.fromEnvironment(
    'SUPABASE_MESSAGES_TABLE',
    defaultValue: 'chat_messages_realtime',
  );

  static const String supabaseNotificationsTable = String.fromEnvironment(
    'SUPABASE_NOTIFICATIONS_TABLE',
    defaultValue: 'notification_events_realtime',
  );

  static bool get isSupabaseChatConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static const bool allowCreateVacancyForAll = bool.fromEnvironment(
    'ALLOW_CREATE_VACANCY_FOR_ALL',
    defaultValue: true,
  );
}