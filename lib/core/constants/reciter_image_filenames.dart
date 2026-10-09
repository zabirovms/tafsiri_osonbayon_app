/// Exact image filenames mapping for reciters
/// Based on actual files in C:\Users\Anas\Downloads\reciters_photo
/// Maps reciter ID to exact filename (including extension)
class ReciterImageFilenames {
  /// Map of reciter ID to exact image filename
  static const Map<String, String> imageFilenames = {
    // Arabic reciters
    'ar.abdulazizazzahrani': 'ar.abdulazizazzahrani.webp',
    'ar.abdulbariaththubaity': 'ar.abdulbariaththubaity.webp',
    'ar.abdulbarimohammed': 'ar.abdulbarimohammed.jpg',
    'ar.abdulbasitmujawwad': 'ar.abdulbasitmujawwad.jpg',
    'ar.abdulbasitmurattal': 'ar.abdulbasitmurattal.jpg',
    'ar.abdulkareemalhazmi': 'ar.abdulkareemalhazmi.jpg',
    'ar.abdullahalmatrood': 'ar.abdullahalmatrood.jpg',
    'ar.abdullahawadaljuhani': 'ar.abdullahawadaljuhani.jpg',
    'ar.abdullahbasfar': 'ar.abdullahbasfar.jpg',
    'ar.abdullahkhayat': 'ar.abdullahkhayat.png',
    'ar.abdullahkhulaifi': 'ar.abdullahkhulaifi.jpg',
    'ar.abdulmohsenalharthy': 'ar.abdulmohsenalharthy.jpg',
    'ar.abdulmuhsinalqasim': 'ar.abdulmuhsinalqasim.webp',
    'ar.abdulmunimabdulmubdi': 'ar.abdulmunimabdulmubdi.jpg',
    'ar.abdulwadoodhaneef': 'ar.abdulwadoodhaneef.webp',
    'ar.abdurrasheedsufisoosi': 'ar.abdurrasheedsufisoosi.jpg',
    'ar.alafasy': 'ar.alafasy.jpeg',
    'ar.ezzatsabri': 'ar.ezzatsabri.webp',
    'ar.faresabbad': 'ar.faresabbad.webp',
    'ar.fouadalkhamiri': 'ar.fouadalkhamiri.webp',
    'ar.hamadsinan': 'ar.hamadsinan.jpg',
    'ar.haniarrifai': 'ar.haniarrifai.jpg',
    'ar.hassansaleh': 'ar.hassansaleh.jpg',
    'ar.hatemfarid': 'ar.hatemfarid.jpg',
    'ar.muhammadalluhaidan': 'ar.muhammadalluhaidan.jpg',
    'ar.muhammadsiddiqalminshawimujawwad': 'ar.muhammadsiddiqalminshawimujawwad.jpeg',
    'ar.yasseraldossari': 'ar.yasseraldossari.jpg',
    
    // English translations
    'en.misharyrashidalafasyenglishtranslationsaheehibrahimwalk': 'en.misharyrashidalafasyenglishtranslationsaheehibrahimwalk.jpg',
    'en.muhammadayyubenglishtranslationmuhsinkhanmikaalwaters': 'en.muhammadayyubenglishtranslationmuhsinkhanmikaalwaters.jpeg',
    'en.sudaisandshuraymenglishtranslationpickthallaslamathar': 'en.sudaisandshuraymenglishtranslationpickthallaslamathar.jpg',
  };

  /// Get exact filename for a reciter ID
  /// Returns null if not found in mapping
  static String? getFilename(String reciterId) {
    return imageFilenames[reciterId];
  }

  /// Check if reciter has an exact filename mapping
  static bool hasExactFilename(String reciterId) {
    return imageFilenames.containsKey(reciterId);
  }

  /// Get all reciter IDs that have exact filenames
  static List<String> getReciterIds() {
    return imageFilenames.keys.toList();
  }
}
























