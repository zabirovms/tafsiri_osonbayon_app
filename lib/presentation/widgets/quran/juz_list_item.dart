import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../data/services/surah_svg_service.dart';
import '../../../data/models/surah_model.dart';
import '../../../presentation/providers/quran_provider.dart';

class JuzInfo {
  final int juz;
  final int surahNumber;
  final String surahName;
  final int ayahNumber;

  JuzInfo({
    required this.juz,
    required this.surahNumber,
    required this.surahName,
    required this.ayahNumber,
  });
}

class JuzListItem extends ConsumerWidget {
  final JuzInfo juzInfo;
  final VoidCallback? onTap;

  const JuzListItem({
    super.key,
    required this.juzInfo,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final surahsAsync = ref.watch(surahsProvider);
    final svgService = SurahSvgService();

    // Get surah model for additional info
    SurahModel? surah;
    if (surahsAsync.value != null) {
      try {
        surah = surahsAsync.value!.firstWhere(
          (s) => s.number == juzInfo.surahNumber,
        );
      } catch (e) {
        surah = null;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap ??
              () => context.push(
                  '/surah/${juzInfo.surahNumber}/verse/${juzInfo.ayahNumber}'),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Row(
              children: [
                // Juz number badge
                _buildJuzNumber(theme, colorScheme, svgService),

                const SizedBox(width: 16),

                // Juz details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ҷузъи ${juzInfo.juz}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              juzInfo.surahName,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface
                                    .withValues(alpha: 0.6),
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '•',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface
                                  .withValues(alpha: 0.4),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'оят ${juzInfo.ayahNumber}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Arabic name SVG pill
                if (surah != null)
                  _buildArabicName(theme, colorScheme, surah, svgService),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildJuzNumber(ThemeData theme, ColorScheme colorScheme, SurahSvgService svgService) {
    final circleColor = colorScheme.primary;

    return RepaintBoundary(
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: SizedBox(
          width: 32,
          height: 32,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SvgPicture.asset(
                svgService.getCircleSvgAssetPath(),
                width: 32,
                height: 32,
                fit: BoxFit.contain,
                colorFilter: ColorFilter.mode(
                  circleColor,
                  BlendMode.srcIn,
                ),
                semanticsLabel: 'Juz ${juzInfo.juz}',
              ),
              Text(
                '${juzInfo.juz}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArabicName(ThemeData theme, ColorScheme colorScheme, SurahModel surah, SurahSvgService svgService) {
    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: SizedBox(
          width: 80,
          height: 32,
          child: SvgPicture.asset(
            svgService.getSurahSvgAssetPath(juzInfo.surahNumber),
            fit: BoxFit.contain,
            alignment: Alignment.center,
            colorFilter: ColorFilter.mode(
              colorScheme.primary,
              BlendMode.srcIn,
            ),
            semanticsLabel: surah.nameArabic,
          ),
        ),
      ),
    );
  }
}
