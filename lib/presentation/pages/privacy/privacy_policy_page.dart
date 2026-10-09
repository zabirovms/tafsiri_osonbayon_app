import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Сиёсати махфият'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Санаи эътибор:',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '17 октябри 2025',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),

              _buildSection(
                theme: theme,
                colorScheme: colorScheme,
                title: '1. Муқаддима',
                content:
                    'Барномаи Қуръон бо Тафсири Осонбаён (“мо”) маълумоти шуморо ҳимоя мекунад ва ин сиёсат нишон медиҳад, ки чӣ гуна маълумоти шумо истифода ва ҳифз мешавад.',
              ),
              _buildSection(
                theme: theme,
                colorScheme: colorScheme,
                title: '2. Маълумоте, ки мо ҷамъоварӣ намекунем',
                content:
                    'Мо ҳеҷ маълумоти шахсии шумо, аз қабили ном, суроғаи почта, рақам ва ё макони ҷуғрофиро ҷамъ намекунем.',
              ),
              _buildSection(
                theme: theme,
                colorScheme: colorScheme,
                title: '3. Маълумоте, ки ба таври худкор ҷамъоварӣ карда мешавад',
                content:
                    'Барнома метавонад маълумоти ғайри шахсӣ, ба монанди: версияи барнома, намуди дастгоҳ, забони барнома, ва статистикаи истифода (шумораи кушодани сураҳо) ҷамъ кунад. Ин маълумот барои беҳтар кардани барнома истифода мешавад.',
              ),
              _buildSection(
                theme: theme,
                colorScheme: colorScheme,
                title: '4. Чӣ гуна мо онро истифода мекунем',
                content:
                    'Мо маълумоти ҷамъшударо танҳо барои беҳтар кардани барнома ва ислоҳи хатогиҳо истифода мекунем ва ҳеҷ гоҳ онро бо каси сеюм мубодила намекунем.',
              ),
              _buildSection(
                theme: theme,
                colorScheme: colorScheme,
                title: '5. Захираи маълумот',
                content:
                    'Маълумоти шумо, аз қабили нишонаҳо, шумораи такрор ва танзимот дар дастгоҳи шумо маҳфуз мемонад ва ҳеҷ гоҳ ба серверҳои беруна ирсол намешавад.',
              ),
              _buildSection(
                theme: theme,
                colorScheme: colorScheme,
                title: '6. Хизматрасониҳои тарафи сеюм',
                content:
                    'Барнома метавонад хидматрасониҳои эътимодноки тарафи сеюмро барои ҳисобҳои оморӣ ва ҳалли хатогиҳо истифода барад. Ин хизматрасониҳо маълумоти шахсии шуморо ҷамъ намекунанд.',
              ),
              _buildSection(
                theme: theme,
                colorScheme: colorScheme,
                title: '7. Ҳуқуқҳои шумо',
                content:
                    'Шумо метавонед маълумоти маҳаллӣ дар барнома ва кэши барномаро тоза кунед ва барномаро аз дастгоҳи худ нест кунед, ки ҳамаи маълумоти маҳаллӣ нест мешаванд.',
              ),

              Text(
                '8. Навсозии сиёсат',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              RichText(
                text: TextSpan(
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                  children: [
                    const TextSpan(
                      text: 'Мо метавонем ин сиёсатро давра ба давра навсозӣ кунем. Ҳама навсозиҳо дар вебсайти мо нашр карда мешаванд: ',
                    ),
                    TextSpan(
                      text: 'www.quran.tj/privacy',
                      style: TextStyle(
                        color: colorScheme.primary,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () async {
                          final url = Uri.parse('https://www.quran.tj/privacy');
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url, mode: LaunchMode.externalApplication);
                          }
                        },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              _buildSection(
                theme: theme,
                colorScheme: colorScheme,
                title: '9. Тамос бо мо',
                content:
                    'Агар савол ё нигароние дошта бошед, бо мо тавассути почта тамос гиред: info@quran.tj',
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required ThemeData theme,
    required ColorScheme colorScheme,
    required String title,
    required String content,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
