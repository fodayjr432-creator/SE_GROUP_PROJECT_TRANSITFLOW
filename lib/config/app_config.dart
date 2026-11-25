/// Application Configuration & Supabase Connection Constants
class AppConfig {
  static const String appName = 'TransitFlow SL';
  static const String appTagline =
      'Commercial Motorcycle Union Management & Financial Compliance System';
  static const String appVersion = '2.0.0+1';
  static const String countryName = 'Sierra Leone';
  static const String defaultCity = 'Freetown';

  // SDG Alignments
  static const String sdg11Title = 'SDG 11: Sustainable Cities & Communities';
  static const String sdg11Target = 'Target 11.2: Safe, affordable, accessible & sustainable transport';
  static const String sdg8Title = 'SDG 8: Decent Work & Economic Growth';

  // Supabase Configuration (Overridable via --dart-define or runtime settings)
  static const String defaultSupabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://xyzcompany.supabase.co',
  );
  static const String defaultSupabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.dummy_publishable_key_for_offline_resilience',
  );

  // Runtime Supabase values (allow in-app live configuration from Settings screen)
  static String activeSupabaseUrl = defaultSupabaseUrl;
  static String activeSupabasePublishableKey = defaultSupabasePublishableKey;
  static bool isLiveSupabaseConnected = false;

  // Currency
  static const String currencyCode = 'SLE';
  static const String currencySymbol = 'Le';
}
