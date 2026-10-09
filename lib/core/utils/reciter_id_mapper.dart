import 'package:flutter/foundation.dart' show debugPrint;

/// Utility class to map app reciter IDs to CDN reciter IDs
/// 
/// The app uses IDs with underscores (e.g., ar.abdul_basit_murattal)
/// but the CDN uses IDs without underscores (e.g., ar.abdulbasitmurattal)
class ReciterIdMapper {
  /// Maps app reciter ID to CDN reciter ID
  /// Returns the CDN ID if mapping exists, otherwise returns the original ID
  static String toCdnId(String appId) {
    // Map of app IDs to CDN IDs
    // Based on verified URLs from https://cdn.islamic.network/quran/info/by-ayah/info.txt
    final mapping = {
      // Arabic reciters - verse-by-verse supported
      'ar.alafasy': 'ar.alafasy',
      'ar.husary': 'ar.husary',
      'ar.minshawi': 'ar.minshawi',
      'ar.ahmed_ajamy': 'ar.ahmedajamy', // Fixed: was ar.ahmedalajmi
      'ar.hudhaify': 'ar.hudhaify',
      'ar.husarymujawwad': 'ar.husarymujawwad',
      'ar.maher_al_muaiqly': 'ar.mahermuaiqly',
      'ar.muhammadayyoub': 'ar.muhammadayyoub',
      'ar.muhammadjibreel': 'ar.muhammadjibreel',
      'ar.abu_bakr_ash_shaatree': 'ar.shaatree',
      'ar.abdul_basit_murattal': 'ar.abdulbasitmurattal',
      'ar.abdullah_basfar': 'ar.abdullahbasfar',
      'ar.abdurrahmaan_as_sudais': 'ar.abdurrahmaansudais',
      'ar.hanirifai': 'ar.hanirifai',
      'ar.ibrahimakhbar': 'ar.ibrahimakhbar',
      'ar.abdul_samad': 'ar.abdulsamad',
      'ar.aymanswoaid': 'ar.aymanswoaid',
      'ar.minshawimujawwad': 'ar.minshawimujawwad',
      'ar.saoodshuraym': 'ar.saoodshuraym',
      
      // Other reciters (for full surah playback)
      'ar.abdul_basit_mujawwad': 'ar.abdulbasitmujawwad',
      'ar.saad_al_ghamdi': 'ar.saadghamdi',
      'ar.abdul_muhsin_al_muhsin': 'ar.abdulmuhsinalqasim',
      'ar.abdul_wadood_haneef': 'ar.abdulwadoodhaneef',
      'ar.abdurrashid_sufi': 'ar.abdurrasheedsufisoosi',
      
      // Translation editions
      'fa.ayati': 'fa.ayati',
      'ru.kuliev': 'ru.kuliev-audio',
      'en.ahmedali': 'en.ahmedali',
      'en.ahmedraza': 'en.ahmedraza',
      'ur.maududi': 'ur.maududi',
      'tr.yuksel': 'tr.yuksel',
      'id.indonesian': 'id.indonesian',
      'ms.basmeih': 'ms.basmeih',
      'bn.bengali': 'bn.bengali',
      'hi.hindi': 'hi.hindi',
      
      // Tajik translations use separate API, so no mapping needed
      'tg.akmal_mansurov': 'tg.akmal_mansurov',
      'tg.abuabdurrahman': 'tg.abuabdurrahman',
    };
    
    // If no mapping found, try to normalize (remove underscores) as fallback
    if (mapping[appId] != null) {
      return mapping[appId]!;
    }
    
    // Fallback: if app ID has underscores, remove them to get CDN ID
    if (appId.contains('_')) {
      final normalized = appId.replaceAll('_', '');
      debugPrint('[ReciterIdMapper] No mapping for $appId, using normalized: $normalized');
      return normalized;
    }
    
    // Return as-is if no underscores (likely already a CDN ID)
    return appId;
  }
  
  /// Maps CDN reciter ID back to app reciter ID (reverse mapping)
  /// Returns the app ID if mapping exists, otherwise returns the original ID
  static String toAppId(String cdnId) {
    final reverseMapping = {
      'ar.abdulbasitmurattal': 'ar.abdul_basit_murattal',
      'ar.abdulbasitmujawwad': 'ar.abdul_basit_mujawwad',
      'ar.abdullahbasfar': 'ar.abdullah_basfar',
      'ar.abdurrahmaansudais': 'ar.abdurrahmaan_as_sudais',
      'ar.ahmedajamy': 'ar.ahmed_ajamy', // Fixed: was ar.ahmedalajmi
      'ar.mahermuaiqly': 'ar.maher_al_muaiqly',
      'ar.saadghamdi': 'ar.saad_al_ghamdi',
      'ar.shaatree': 'ar.abu_bakr_ash_shaatree',
      'ar.abdulmuhsinalqasim': 'ar.abdul_muhsin_al_muhsin',
      'ar.abdulwadoodhaneef': 'ar.abdul_wadood_haneef',
      'ar.abdurrasheedsufisoosi': 'ar.abdurrashid_sufi',
      'ar.abdulsamad': 'ar.abdul_samad',
      'ru.kuliev-audio': 'ru.kuliev',
      // Verse-by-verse reciters that don't need mapping (IDs match)
      'ar.hudhaify': 'ar.hudhaify',
      'ar.husarymujawwad': 'ar.husarymujawwad',
      'ar.muhammadayyoub': 'ar.muhammadayyoub',
      'ar.muhammadjibreel': 'ar.muhammadjibreel',
      'ar.hanirifai': 'ar.hanirifai',
      'ar.ibrahimakhbar': 'ar.ibrahimakhbar',
      'ar.aymanswoaid': 'ar.aymanswoaid',
      'ar.minshawimujawwad': 'ar.minshawimujawwad',
      'ar.saoodshuraym': 'ar.saoodshuraym',
    };
    
    return reverseMapping[cdnId] ?? cdnId;
  }
}

