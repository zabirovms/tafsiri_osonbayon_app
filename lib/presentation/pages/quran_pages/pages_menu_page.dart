import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/quran_pages_provider.dart';
import '../../widgets/quran/page_list_item.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/error_widget.dart';

class PagesMenuPage extends ConsumerWidget {
  const PagesMenuPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pagesAsync = ref.watch(quranPagesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Саҳифаҳои Қуръон'),
        centerTitle: false,
      ),
      body: SafeArea(
        top: false,
        bottom: true,
        child: pagesAsync.when(
          data: (pages) {
            if (pages.isEmpty) {
              return const Center(
                child: Text('Саҳифаҳо дастрас нестанд'),
              );
            }

            return ListView.builder(
              itemCount: pages.length,
              itemBuilder: (context, index) {
                final pageInfo = pages[index];
                return PageListItem(
                  key: ValueKey(pageInfo.page),
                  pageInfo: pageInfo,
                  onTap: () => context.push(
                    '/mushaf?page=${pageInfo.page}',
                  ),
                );
              },
            );
          },
          loading: () => LoadingFullScreenWidget(
            backgroundColor: theme.scaffoldBackgroundColor,
            itemCount: 10,
          ),
          error: (error, stack) => CustomErrorWidget(
            title: 'Хатогӣ дар боргирии саҳифаҳо',
            message: 'Саҳифаҳои Қуръонро боргирӣ карда натавонистем.',
            onRetry: () => ref.invalidate(quranPagesProvider),
          ),
        ),
      ),
    );
  }
}

