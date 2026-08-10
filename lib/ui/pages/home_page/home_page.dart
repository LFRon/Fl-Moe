import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../features/auth/authentication_controller.dart';
import '../../../features/music/music_catalog_controller.dart';
import '../../../features/navigation/app_navigation_controller.dart';
import '../../login_dialog.dart';
import '../../widgets/collection_grid.dart';
import '../../widgets/common_widgets.dart';
import 'widgets/catalog_skeleton.dart';
import 'widgets/home_hero.dart';
import 'widgets/inline_message.dart';

final class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> _search(String word) async {
    Get.find<AppNavigationController>().openSearch(word);
    await Get.find<MusicSearchController>().search(word);
  }

  @override
  Widget build(BuildContext context) => GetBuilder<AuthenticationController>(
    builder: (authentication) => GetBuilder<MusicCatalogController>(
      builder: (catalog) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
          children: <Widget>[
            HomeHero(
              loggedIn: authentication.isLoggedIn,
              onAction: authentication.isLoggedIn
                  ? () => Get.find<AppNavigationController>().goTo(
                      AppSection.library,
                    )
                  : () => unawaited(showQrLoginDialog(context)),
            ),
            const SizedBox(height: 30),
            PageHeading(
              title: '大家都在搜',
              subtitle: '来自酷狗音乐的实时热门关键词',
              trailing: IconButton(
                tooltip: '刷新',
                onPressed: catalog.homeLoading
                    ? null
                    : () => unawaited(catalog.refreshHomeCatalog()),
                icon: const Icon(Icons.refresh_rounded),
              ),
            ),
            const SizedBox(height: 16),
            if (catalog.hotWords.isNotEmpty)
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: catalog.hotWords
                    .map(
                      (word) => ActionChip(
                        mouseCursor: WidgetStateMouseCursor.clickable,
                        avatar: const Icon(Icons.trending_up_rounded, size: 17),
                        label: Text(word),
                        onPressed: () => unawaited(_search(word)),
                      ),
                    )
                    .toList(growable: false),
              )
            else if (catalog.homeLoading)
              const HotWordsSkeleton()
            else
              InlineMessage(message: catalog.homeError ?? '暂时没有热门搜索，稍后再来看看'),
            const SizedBox(height: 32),
            const PageHeading(
              title: '发现好歌单',
              subtitle: '不复刻网页结构，保留熟悉的信息层级与轻盈感',
            ),
            const SizedBox(height: 18),
            if (catalog.homeCollections.isNotEmpty)
              CollectionGrid(
                collections: catalog.homeCollections.take(12).toList(),
              )
            else if (catalog.homeLoading)
              const CatalogSkeleton()
            else
              InlineMessage(message: catalog.homeError ?? '歌单加载失败'),
          ],
        );
      },
    ),
  );
}
