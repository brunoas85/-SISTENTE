/// Configuración por entorno. Se pasa con
/// `--dart-define-from-file=env/dev.json` (ver `env/example.json`).
class AppConfig {
  const AppConfig._();

  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;
}
