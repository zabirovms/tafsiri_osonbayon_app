import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/reciter_model.dart';
import '../../data/services/settings_service.dart';
import '../providers/reciter_provider.dart';

class ReciterSelectionDialog extends ConsumerWidget {
  final String currentReciterId;

  const ReciterSelectionDialog({
    super.key,
    required this.currentReciterId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reciters = ref.watch(recitersWithVerseByVerseProvider);
    
    if (reciters.isEmpty) {
      return AlertDialog(
        title: const Text('Интихоби қорӣ'),
        content: const Text('Ҳеҷ қорӣ бо дастгирии ояти ҷудогона ёфт нашуд'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ХУБ'),
          ),
        ],
      );
    }

    // Categorize reciters
    final categorized = _categorizeReciters(reciters);
    final murattal = categorized['murattal'] as List<ReciterModel>;
    final mujawwad = categorized['mujawwad'] as List<ReciterModel>;
    final translations = categorized['translations'] as List<ReciterModel>;
    final others = categorized['others'] as List<ReciterModel>;
    
    return AlertDialog(
      title: const Text('Интихоби қорӣ'),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Murattal Style
              if (murattal.isNotEmpty) ...[
                _buildCategoryHeader(context, 'Мураттал (Оҳиста)'),
                ...murattal.map((reciter) => _buildReciterTile(
                  context,
                  reciter,
                  currentReciterId,
                )),
                const SizedBox(height: 8),
              ],
              
              // Mujawwad Style
              if (mujawwad.isNotEmpty) ...[
                _buildCategoryHeader(context, 'Муҷаввад (Муътадил)'),
                ...mujawwad.map((reciter) => _buildReciterTile(
                  context,
                  reciter,
                  currentReciterId,
                )),
                const SizedBox(height: 8),
              ],
              
              // Translations (all in one category with flags)
              if (translations.isNotEmpty) ...[
                _buildCategoryHeader(context, 'Тарҷумаҳо'),
                ...translations.map((reciter) => _buildReciterTile(
                  context,
                  reciter,
                  currentReciterId,
                  isTranslation: true,
                )),
                const SizedBox(height: 8),
              ],
              
              // Other Reciters
              if (others.isNotEmpty) ...[
                _buildCategoryHeader(context, 'Дигар қориҳо'),
                ...others.map((reciter) => _buildReciterTile(
                  context,
                  reciter,
                  currentReciterId,
                )),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 6),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildReciterTile(
    BuildContext context,
    ReciterModel reciter,
    String currentReciterId, {
    bool isTranslation = false,
  }) {
    final isSelected = reciter.id == currentReciterId;
    
    // Get display name - prefer Tajik, fallback to English, never show Arabic
    String displayName = reciter.id;
    if (reciter.nameTajik.isNotEmpty && reciter.nameTajik != reciter.id) {
      displayName = reciter.nameTajik;
    } else if (reciter.name.isNotEmpty && reciter.name != reciter.id) {
      displayName = reciter.name;
    }
    
    // Get flag for translations
    String? flag;
    if (isTranslation) {
      flag = _getFlagForTranslation(reciter.id);
    }
    
    return RadioListTile<String>(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      title: Row(
        children: [
          if (flag != null) ...[
            Text(flag, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
          ],
          Expanded(child: Text(displayName)),
        ],
      ),
      value: reciter.id,
      groupValue: currentReciterId,
      onChanged: (value) => _handleSelection(context, value!),
      selected: isSelected,
    );
  }
  
  String? _getFlagForTranslation(String reciterId) {
    // Map reciter IDs to flags
    if (reciterId.startsWith('fa.')) {
      return '🇮🇷'; // Farsi
    } else if (reciterId.startsWith('ru.')) {
      return '🇷🇺'; // Russian
    } else if (reciterId.startsWith('en.')) {
      return '🇬🇧'; // English
    } else if (reciterId.startsWith('fr.')) {
      return '🇫🇷'; // French
    } else if (reciterId.startsWith('ur.')) {
      return '🇵🇰'; // Urdu
    } else if (reciterId.startsWith('zh.')) {
      return '🇨🇳'; // Chinese
    } else if (reciterId.startsWith('tr.')) {
      return '🇹🇷'; // Turkish
    } else if (reciterId.startsWith('id.')) {
      return '🇮🇩'; // Indonesian
    } else if (reciterId.startsWith('ms.')) {
      return '🇲🇾'; // Malay
    } else if (reciterId.startsWith('bn.')) {
      return '🇧🇩'; // Bengali
    } else if (reciterId.startsWith('hi.')) {
      return '🇮🇳'; // Hindi
    }
    return null;
  }

  Future<void> _handleSelection(BuildContext context, String reciterId) async {
    final s = SettingsService();
    await s.init();
    await s.setAudioEdition(reciterId);
    
    if (context.mounted) {
      Navigator.of(context).pop(reciterId);
    }
  }

  /// Categorize reciters into groups
  /// Returns a map with Lists for each category
  Map<String, dynamic> _categorizeReciters(List<ReciterModel> reciters) {
    // Murattal style (clear, slow recitation)
    final murattalIds = {
      'ar.abdulbasitmurattal',
      'ar.abdullahbasfar',
      'ar.abdulsamad',
      'ar.hudhaify',
      'ar.ibrahimakhbar',
    };
    
    // Mujawwad style (melodic recitation)
    final mujawwadIds = {
      'ar.husarymujawwad',
      'ar.minshawimujawwad',
    };
    
    final murattal = <ReciterModel>[];
    final mujawwad = <ReciterModel>[];
    final translations = <ReciterModel>[];
    final others = <ReciterModel>[];
    
    // Translation IDs
    // Use CDN IDs directly
    final translationIds = {
      'fr.leclerc',
      'ru.kuliev-audio', // CDN ID for Russian translation
      'zh.chinese',
      'en.walk',
      'fa.hedayatfarfooladvand',
      'ur.khan',
    };
    
    // Language priority for sorting translations: farsi, russian, english, then others
    int _getTranslationPriority(String reciterId) {
      if (reciterId.startsWith('fa.')) {
        return 1; // Farsi - first
      } else if (reciterId.startsWith('ru.')) {
        return 2; // Russian - second
      } else if (reciterId.startsWith('en.')) {
        return 3; // English - third
      } else {
        return 4; // Others - last
      }
    }
    
    for (final reciter in reciters) {
      // Check if it's a translation (only known translation IDs)
      if (translationIds.contains(reciter.id)) {
        translations.add(reciter);
      } else if (mujawwadIds.contains(reciter.id) || 
                 reciter.nameTajik.toLowerCase().contains('муҷаввад')) {
        mujawwad.add(reciter);
      } else if (murattalIds.contains(reciter.id) ||
                 reciter.nameTajik.toLowerCase().contains('мураттал')) {
        murattal.add(reciter);
      } else {
        others.add(reciter);
      }
    }
    
    // Sort each category alphabetically
    murattal.sort((a, b) => a.nameTajik.compareTo(b.nameTajik));
    mujawwad.sort((a, b) => a.nameTajik.compareTo(b.nameTajik));
    others.sort((a, b) => a.nameTajik.compareTo(b.nameTajik));
    
    // Sort translations: first by priority (farsi, russian, english, others), then alphabetically
    translations.sort((a, b) {
      final priorityA = _getTranslationPriority(a.id);
      final priorityB = _getTranslationPriority(b.id);
      if (priorityA != priorityB) {
        return priorityA.compareTo(priorityB);
      }
      return a.nameTajik.compareTo(b.nameTajik);
    });
    
    return {
      'murattal': murattal,
      'mujawwad': mujawwad,
      'translations': translations,
      'others': others,
    };
  }
}

