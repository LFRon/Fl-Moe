import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';

import '../../../features/music/music_catalog_controller.dart';
import '../../scrolling/fl_moe_smooth_scroll.dart';
import '../../widgets/collection_grid.dart';
import '../../widgets/common_widgets.dart';
import 'widgets/loading_or_error.dart';

final class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

final class _DiscoverPageState extends State<DiscoverPage> {
  @override
  void initState() {
    super.initState();
    final catalog = Get.find<MusicCatalogController>();
    // Animated page switching keeps the outgoing page mounted. Starting here
    // synchronously would notify its GetBuilder while the new page is building.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(catalog.loadDiscoverCatalog());
    });
  }

  @override
  Widget build(BuildContext context) => GetBuilder<MusicCatalogController>(
    // Discover does not render the home hot-word/cover data. Keep its own
    // grids stable when that unrelated part of the shared catalog updates.
    filter: (catalog) => (
      collections: catalog.discoverCollections,
      rankings: catalog.rankings,
      loading: catalog.discoverLoading,
      loaded: catalog.discoverLoaded,
      error: catalog.discoverError,
    ),
    builder: (catalog) {
      final initialLoadPending =
          !catalog.discoverLoaded && catalog.discoverError == null;
      final showLoading = catalog.discoverLoading || initialLoadPending;
      return SilkyCustomScrollView(
        silkyConfig: flMoeSmoothScrollConfig,
        slivers: <Widget>[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate(<Widget>[
                PageHeading(
                  title: '发现音乐',
                  subtitle: '歌单与排行榜都来自内嵌的纯 Dart 酷狗 API',
                  trailing: FilledButton.tonalIcon(
                    onPressed: showLoading
                        ? null
                        : () => unawaited(catalog.refreshDiscoverCatalog()),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('换一批'),
                  ),
                ),
                const SizedBox(height: 28),
                _SectionTitle('热门歌单'),
                const SizedBox(height: 16),
              ]),
            ),
          ),
          if (catalog.discoverCollections.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              sliver: SliverCollectionGrid(
                collections: catalog.discoverCollections,
              ),
            )
          else
            _messageSliver(
              LoadingOrError(
                loading: showLoading,
                error: catalog.discoverError,
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(28, 34, 28, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate(<Widget>[
                _SectionTitle('酷狗排行榜'),
                const SizedBox(height: 16),
              ]),
            ),
          ),
          if (catalog.rankings.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              sliver: SliverCollectionGrid(collections: catalog.rankings),
            )
          else
            _messageSliver(
              LoadingOrError(
                loading: showLoading,
                error: catalog.discoverError,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      );
    },
  );
}

Widget _messageSliver(Widget child) => SliverPadding(
  padding: const EdgeInsets.symmetric(horizontal: 28),
  sliver: SliverToBoxAdapter(child: child),
);

final class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: Theme.of(
      context,
    ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
  );
}
