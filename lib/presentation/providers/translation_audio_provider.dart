import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'audio_editions_provider.dart' show TranslationAudioEdition, apiTranslationAudioEditionsProvider;

// Provider for translation audio editions - hardcoded list (ALL from CDN, excluding Tajik)
// Directly use apiTranslationAudioEditionsProvider
final translationAudioEditionsProvider = apiTranslationAudioEditionsProvider;

// Provider for Tajik translation audio - Акмал Мансуров
final tajikTranslationAudioProvider = FutureProvider<TranslationAudioEdition?>((ref) async {
  // Return Tajik edition from Акмал Мансуров API
  await Future.delayed(const Duration(milliseconds: 100));
  return const TranslationAudioEdition(
    id: 'tg.akmal_mansurov',
    name: 'Тоҷикӣ',
    flag: '🇹🇯',
    languageCode: 'tg',
  );
});

// Provider for a specific translation edition by ID
// Uses hardcoded list - all IDs are CDN IDs (no normalization needed)
final translationAudioEditionProvider = Provider.family<TranslationAudioEdition?, String>((ref, editionId) {
  // Check if it's Tajik edition first (handled separately)
  if (editionId == 'tg.akmal_mansurov' || editionId == 'tg.abuabdurrahman') {
    final tajikAsync = ref.watch(tajikTranslationAudioProvider);
    return tajikAsync.valueOrNull;
  }
  
  // Use hardcoded translations list (has all translation data)
  final editions = ref.watch(translationAudioEditionsProvider);
  try {
    // Direct match - all IDs are CDN IDs
    return editions.firstWhere((e) => e.id == editionId);
  } catch (e) {
    return null;
  }
});

