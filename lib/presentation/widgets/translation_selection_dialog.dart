import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/services/settings_service.dart';

class TranslationSelectionDialog extends StatelessWidget {
  final String currentTranslation;
  final int? surahNumber; // Optional, for checking/downloading translations
  final Function(String)? onTranslationSelected;

  const TranslationSelectionDialog({
    super.key,
    required this.currentTranslation,
    this.surahNumber,
    this.onTranslationSelected,
  });


  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Интихоби забони тарҷума'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Tajik Translations
            RadioListTile<String>(
              title: Text(AppConstants.getTranslationName('tajik_ayati')),
              value: 'tajik_ayati',
              groupValue: currentTranslation,
              onChanged: (value) => _handleSelection(context, value!),
            ),
            RadioListTile<String>(
              title: Text(AppConstants.getTranslationName('tajik_alomuddin')),
              value: 'tajik_alomuddin',
              groupValue: currentTranslation,
              onChanged: (value) => _handleSelection(context, value!),
            ),
            RadioListTile<String>(
              title: Text(AppConstants.getTranslationName('tajik_pioneers')),
              value: 'tajik_pioneers',
              groupValue: currentTranslation,
              onChanged: (value) => _handleSelection(context, value!),
            ),
            RadioListTile<String>(
              title: Text(AppConstants.getTranslationName('tajik_khojamirov')),
              value: 'tajik_khojamirov',
              groupValue: currentTranslation,
              onChanged: (value) => _handleSelection(context, value!),
            ),
            const Divider(),
            // Other Languages
            RadioListTile<String>(
              title: Text(AppConstants.getTranslationName('farsi')),
              value: 'farsi',
              groupValue: currentTranslation,
              onChanged: (value) => _handleSelection(context, value!),
            ),
            RadioListTile<String>(
              title: Text(AppConstants.getTranslationName('russian_kuliev')),
              value: 'russian_kuliev',
              groupValue: currentTranslation,
              onChanged: (value) => _handleSelection(context, value!),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSelection(BuildContext context, String translationCode) async {
    // All translations are now served locally (normalized assets)
    // No need to check for downloads
    
    // Proceed with selection
    final s = SettingsService();
    await s.init();
    await s.setTranslationLanguage(translationCode);
    
    if (onTranslationSelected != null) {
      onTranslationSelected!(translationCode);
    }
    
    // Return the selected translation code
    Navigator.of(context).pop(translationCode);
  }

}

