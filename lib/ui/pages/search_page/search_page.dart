import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';

import '../../../features/music/music_catalog_controller.dart';
import '../../../features/navigation/app_navigation_controller.dart';
import '../../scrolling/fl_moe_smooth_scroll.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/song_list.dart';
import 'widgets/search_results_skeleton.dart';
import 'widgets/search_suggestion_view.dart';

final class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

final class _SearchPageState extends State<SearchPage> {
  final TextEditingController _query = TextEditingController();

  void _syncPendingSearch(String pending) {
    if (pending.isNotEmpty && pending != _query.text) {
      _query.value = TextEditingValue(
        text: pending,
        selection: TextSelection.collapsed(offset: pending.length),
      );
    }
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _search(String value) async {
    final normalized = value.trim();
    if (normalized.isEmpty) return;
    Get.find<AppNavigationController>().openSearch(normalized);
    await Get.find<MusicSearchController>().search(normalized);
  }

  @override
  Widget build(BuildContext context) => GetBuilder<AppNavigationController>(
    filter: (navigation) =>
        (section: navigation.section, pendingSearch: navigation.pendingSearch),
    builder: (navigation) => GetBuilder<MusicSearchController>(
      filter: (search) => (
        query: search.query,
        loading: search.loading,
        error: search.error,
        results: search.results,
      ),
      builder: (search) => GetBuilder<MusicCatalogController>(
        filter: (catalog) =>
            (loading: catalog.homeLoading, words: catalog.hotWords),
        builder: (catalog) {
          _syncPendingSearch(navigation.pendingSearch);
          return Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const PageHeading(
                  title: '搜索',
                  subtitle: '直接调用内嵌 API，不经过 localhost 或 Node.js',
                ),
                const SizedBox(height: 20),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: TextField(
                    controller: _query,
                    autofocus: search.query.isEmpty,
                    onSubmitted: (value) => unawaited(_search(value)),
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: '输入歌曲、歌手、专辑或歌单名称',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: Padding(
                        padding: const EdgeInsets.all(5),
                        child: FilledButton(
                          onPressed: search.loading
                              ? null
                              : () => unawaited(_search(_query.text)),
                          child: const Text('搜索'),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: search.loading
                        ? const SearchResultsSkeleton()
                        : search.results.isNotEmpty
                        ? SilkyListView.builder(
                            silkyConfig: flMoeSmoothScrollConfig,
                            key: ValueKey<String>('results-${search.query}'),
                            itemCount: search.results.length + 2,
                            itemBuilder: (context, index) {
                              if (index == 0) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Row(
                                    children: <Widget>[
                                      Text(
                                        '“${search.query}” 的歌曲',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      const Spacer(),
                                      Text('${search.results.length} 首'),
                                    ],
                                  ),
                                );
                              }
                              if (index > search.results.length) {
                                return const SizedBox(height: 28);
                              }
                              final trackIndex = index - 1;
                              return SongListItem(
                                track: search.results[trackIndex],
                                sourceTracks: search.results,
                                index: trackIndex,
                                compact: false,
                              );
                            },
                          )
                        : SearchSuggestionView(
                            key: const ValueKey<String>('suggestions'),
                            error: search.error,
                            words: catalog.hotWords,
                            loading:
                                catalog.homeLoading && catalog.hotWords.isEmpty,
                            onSelected: (word) {
                              _query.text = word;
                              unawaited(_search(word));
                            },
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ),
  );
}
