abstract class EnvConfig {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://YOUR_SUPABASE_PROJECT.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'YOUR_SUPABASE_ANON_KEY',
  );
}
