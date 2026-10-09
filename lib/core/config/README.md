# API Configuration

## Setup Instructions

This directory contains API configuration files. The actual configuration file (`api_config.dart`) is **gitignored** for security.

### Initial Setup

1. **Copy the example file:**
   ```bash
   cp lib/core/config/api_config.example.dart lib/core/config/api_config.dart
   ```

2. **Edit `api_config.dart`** and replace the placeholder values with your actual API keys:
   - `supabaseUrl`: Your Supabase project URL
   - `supabaseAnonKey`: Your Supabase anonymous key

### Using Environment Variables (Recommended for Production)

You can use compile-time environment variables:

```bash
flutter run --dart-define=SUPABASE_URL=your_url --dart-define=SUPABASE_ANON_KEY=your_key
```

Or set them in your IDE's run configuration.

### Security Notes

- ✅ `api_config.dart` is gitignored and will NOT be committed
- ✅ `api_config.example.dart` is safe to commit (contains placeholders only)
- ⚠️ Never commit actual API keys to version control
- ⚠️ For production builds, use environment variables or secure storage

### Current Configuration

The app currently uses a fallback key in `api_config.dart` for development. This should be replaced with environment variables or secure storage in production.

