import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../data/models/surah_model.dart';
import '../../../data/services/surah_svg_service.dart';

class SurahListItem extends ConsumerWidget {
  final SurahModel surah;
  final VoidCallback? onTap;

  const SurahListItem({
    super.key,
    required this.surah,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final svgService = SurahSvgService();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap ?? () => context.push('/surah/${surah.number}'),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Row(
              children: [
                // Surah number with soft theme background box
                _buildSurahNumber(theme, colorScheme, svgService),
                
                const SizedBox(width: 16),
                
                // Surah details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tajik name (Сураи {nameTajik})
                      Text(
                        'Сураи ${surah.nameTajik}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      const SizedBox(height: 4),
                      
                      // Revelation type and verses count on same line
                      Row(
                        children: [
                          // Revelation type
                          Text(
                            surah.revelationType,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withValues(alpha: 0.6),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          
                          const SizedBox(width: 4),
                          
                          // Separator dot
                          Text(
                            '•',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withValues(alpha: 0.4),
                            ),
                          ),
                          
                          const SizedBox(width: 4),
                      
                          // Verses count (localized)
                          Text(
                            '${surah.versesCount} оят',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Arabic name SVG inside a soft theme pill container
                _buildArabicName(theme, colorScheme, svgService),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSurahNumber(ThemeData theme, ColorScheme colorScheme, SurahSvgService svgService) {
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
              // Circle SVG background with theme color
              SvgPicture.asset(
                svgService.getCircleSvgAssetPath(),
                width: 32,
                height: 32,
                fit: BoxFit.contain,
                colorFilter: ColorFilter.mode(
                  circleColor,
                  BlendMode.srcIn,
                ),
                semanticsLabel: 'Surah ${surah.number}',
              ),
              // Surah number text overlay
              Text(
                '${surah.number}',
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

  Widget _buildArabicName(ThemeData theme, ColorScheme colorScheme, SurahSvgService svgService) {
    final svgColor = colorScheme.primary;
    
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
            svgService.getSurahSvgAssetPath(surah.number),
            fit: BoxFit.contain,
            alignment: Alignment.center,
            colorFilter: ColorFilter.mode(
              svgColor,
              BlendMode.srcIn,
            ),
            semanticsLabel: surah.nameArabic,
          ),
        ),
      ),
    );
  }
}
