import '../constants/reciter_image_filenames.dart';

/// Helper utility for reciter image URLs
class ReciterImageHelper {
  // CDN base URL for reciter photos (https://cdn.quran.tj/reciters-photo)
  static const String cloudBaseUrl = 'https://cdn.quran.tj/reciters-photo/';
  
  // Local asset path for Tajik reciter (only exception)
  static const String tajikReciterLocalPath = 'assets/images/reciters_photo/akmal_mansurov.jpg';
  static const String tajikReciterId = 'tg.akmal_mansurov';
  
  /// Get reciter photo path/URL
  /// Returns local asset path for Tajik reciter, cloud URL for mapped reciters, or null for unmapped
  static String? getReciterPhotoPath(String reciterId) {
    // Keep Tajik reciter as local asset
    if (reciterId == tajikReciterId) {
      return tajikReciterLocalPath;
    }
    
    // Check if we have an exact filename mapping
    final exactFilename = ReciterImageFilenames.getFilename(reciterId);
    if (exactFilename != null) {
      return '$cloudBaseUrl$exactFilename';
    }
    
    // No mapping found - return null (will show placeholder)
    return null;
  }
  
  /// Get URL for a reciter (single URL, no fallbacks)
  /// Returns null if reciter is not mapped
  static String? getReciterPhotoUrl(String reciterId) {
    return getReciterPhotoPath(reciterId);
  }
  
  /// Check if reciter has a mapped image
  static bool hasMappedImage(String reciterId) {
    if (reciterId == tajikReciterId) {
      return true; // Tajik reciter always has local asset
    }
    return ReciterImageFilenames.hasExactFilename(reciterId);
  }
  
  /// Check if reciter photo is a local asset
  static bool isLocalAsset(String? path) {
    if (path == null) return false;
    return path.startsWith('assets/');
  }
  
  /// Check if reciter photo is a cloud URL
  static bool isCloudUrl(String? path) {
    if (path == null) return false;
    return path.startsWith('http://') || path.startsWith('https://');
  }
}

