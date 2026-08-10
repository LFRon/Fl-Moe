import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../features/music/music_catalog_controller.dart';
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
    unawaited(Get.find<MusicCatalogController>().loadDiscoverCatalog());
  }

  @override
  Widget build(BuildContext context) => GetBuilder<MusicCatalogController>(
    builder: (catalog) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
        children: <Widget>[
          PageHeading(
            title: '发现音乐',
            subtitle: '歌单与排行榜都来自内嵌的纯 Dart 酷狗 API',
            trailing: FilledButton.tonalIcon(
              onPressed: catalog.discoverLoading
                  ? null
                  : () => unawaited(catalog.refreshDiscoverCatalog()),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('换一批'),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            '热门歌单',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          if (catalog.discoverCollections.isNotEmpty)
            CollectionGrid(collections: catalog.discoverCollections)
          else
            LoadingOrError(
              loading: catalog.discoverLoading,
              error: catalog.discoverError,
            ),
          const SizedBox(height: 34),
          Text(
            '酷狗排行榜',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          if (catalog.rankings.isNotEmpty)
            CollectionGrid(collections: catalog.rankings)
          else
            LoadingOrError(
              loading: catalog.discoverLoading,
              error: catalog.discoverError,
            ),
        ],
      );
    },
  );
}
