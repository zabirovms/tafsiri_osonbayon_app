/// API Configuration Example
/// 
/// Copy this file to api_config.dart and fill in your actual keys.
/// The api_config.dart file is gitignored and will not be committed.

class ApiConfig {
  // Supabase Configuration
  static const String supabaseUrl = 'YOUR_SUPABASE_URL_HERE';
  
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY_HERE';
  
  // AlQuran Cloud API (public, no key needed)
  static const String alquranCloudUrl = 'https://api.alquran.cloud/v1';
  
  /// Check if configuration is valid
  static bool get isValid {
    return supabaseUrl.isNotEmpty && 
           supabaseAnonKey.isNotEmpty && 
           supabaseAnonKey != 'YOUR_SUPABASE_ANON_KEY_HERE';
  }
}

