import 'package:flutter/material.dart';

import '../../../widgets/loading_skeletons.dart';

final class SearchSuggestionView extends StatelessWidget {
  const SearchSuggestionView({
    required this.error,
    required this.words,
    required this.loading,
    required this.onSelected,
    super.key,
  });

  final String? error;
  final List<String> words;
  final bool loading;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) => ListView(
    children: <Widget>[
      const SizedBox(height: 20),
      Icon(
        error == null ? Icons.music_note_rounded : Icons.search_off_rounded,
        size: 72,
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.55),
      ),
      const SizedBox(height: 12),
      Text(
        error ?? '想听什么？',
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 8),
      Text(
        error == null ? '也可以从这些热门关键词开始' : '可以换个关键词或稍后重试',
        textAlign: TextAlign.center,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
      const SizedBox(height: 22),
      Center(
        child: loading
            ? FlMoeSkeletonScope(
                child: Wrap(
                  key: const ValueKey<String>('search-suggestions-skeleton'),
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: List<Widget>.generate(
                    8,
                    (index) => FlMoeSkeletonBox(
                      width: 72 + (index % 3) * 22,
                      height: 34,
                      borderRadius: const BorderRadius.all(Radius.circular(18)),
                    ),
                    growable: false,
                  ),
                ),
              )
            : Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children: words
                    .map(
                      (word) => ActionChip(
                        mouseCursor: WidgetStateMouseCursor.clickable,
                        label: Text(word),
                        onPressed: () => onSelected(word),
                      ),
                    )
                    .toList(growable: false),
              ),
      ),
    ],
  );
}
