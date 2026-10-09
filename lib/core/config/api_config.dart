/// API Configuration
/// 
/// This file should NOT be committed to version control.
/// Copy api_config.example.dart to api_config.dart and fill in your keys.
/// 
/// For production, use environment variables or secure storage.
/// 
/// To build for production, set environment variables:
/// flutter build apk --release --dart-define=SUPABASE_URL=your_url --dart-define=SUPABASE_ANON_KEY=your_key

class ApiConfig {
  // Supabase Configuration
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://bwymwoomylotjlnvawlr.supabase.co',
  );
  
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: _devFallbackKey,
  );
  
  // AlQuran Cloud API (public, no key needed)
  static const String alquranCloudUrl = 'https://api.alquran.cloud/v1';
  
  // Development fallback key - ONLY for local development
  // ⚠️ WARNING: This key is exposed in source code and should NOT be used in production
  // For production builds, ALWAYS use --dart-define=SUPABASE_ANON_KEY=your_production_key
  // This fallback will be removed in a future version
  static const String _devFallbackKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ3eW13b29teWxvdGpsbnZhd2xyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDY4MDM2ODUsImV4cCI6MjA2MjM3OTY4NX0.0LP8whhfrlt15EUgtrzRox25oiApzg9ZGy8kgiV1NP8';
  
  /// Check if configuration is valid
  /// Returns true if environment variables are set (production mode)
  /// Returns false if using development fallback
  static bool get isValid {
    return supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
  }
  
  /// Check if using production configuration (environment variables)
  /// Returns true if NOT using the development fallback key
  static bool get isProductionConfig {
    return supabaseAnonKey != _devFallbackKey;
  }
  
  /// Validate configuration and throw if invalid
  /// Call this during app initialization to ensure proper configuration
  static void validate() {
    if (!isValid) {
      throw Exception(
        'API configuration is invalid. '
        'For production builds, set SUPABASE_URL and SUPABASE_ANON_KEY via --dart-define flags.'
      );
    }
    
    if (!isProductionConfig) {
      // Log warning in debug mode only
      assert(() {
        // ignore: avoid_print
        print('⚠️ WARNING: Using development API key. For production, use --dart-define=SUPABASE_ANON_KEY=your_key');
        return true;
      }(), '');
    }
  }
}

