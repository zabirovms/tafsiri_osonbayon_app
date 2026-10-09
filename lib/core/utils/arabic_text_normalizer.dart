/// Utility class for normalizing Arabic text for better search matching
class ArabicTextNormalizer {
  /// Normalize Arabic text by removing diacritics and normalizing characters
  /// This helps match words even when diacritics differ
  static String normalizeArabic(String text) {
    if (text.isEmpty) return text;
    
    // Remove Arabic diacritics (harakat/tashkeel)
    // Unicode ranges for Arabic diacritics: U+064B to U+065F, U+0670, U+06D6 to U+06ED
    String normalized = text.replaceAll(RegExp(r'[\u064B-\u065F\u0670\u06D6-\u06ED]'), '');
    
    // Normalize hamza variations to basic hamza
    normalized = normalized
        .replaceAll('أ', 'ا')  // Alif with hamza above
        .replaceAll('إ', 'ا')  // Alif with hamza below
        .replaceAll('آ', 'ا')  // Alif maddah
        .replaceAll('ء', 'ا')  // Hamza (standalone)
        .replaceAll('ؤ', 'و')  // Waw with hamza
        .replaceAll('ئ', 'ي');  // Ya with hamza
    
    // Normalize alif variations
    normalized = normalized.replaceAll('ى', 'ي'); // Alif maksura to ya
    
    // Remove zero-width characters
    normalized = normalized.replaceAll(RegExp(r'[\u200B-\u200D\uFEFF]'), '');
    
    // Normalize whitespace
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    return normalized;
  }
  
  /// Normalize text for search (removes diacritics and special characters)
  static String normalizeForSearch(String text) {
    // First normalize Arabic-specific characters
    String normalized = normalizeArabic(text);
    
    // Then apply general normalization (lowercase, remove special chars)
    normalized = normalized
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s\u0600-\u06FF]'), '') // Keep Arabic and alphanumeric
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize whitespace
        .trim();
    
    return normalized;
  }
}

