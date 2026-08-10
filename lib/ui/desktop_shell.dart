import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/storage/app_directories.dart';
import '../core/window/desktop_window_service.dart';
import '../features/navigation/app_navigation_controller.dart';
import 'app_sidebar.dart';
import 'pages/cloud_page/cloud_page.dart';
import 'pages/collection_detail_page/collection_detail_page.dart';
import 'pages/discover_page/discover_page.dart';
import 'pages/home_page/home_page.dart';
import 'pages/library_page/library_page.dart';
import 'pages/search_page/search_page.dart';
import 'pages/settings_page/settings_page.dart';
import 'player_bar.dart';
import 'window_title_bar.dart';

final class DesktopShell extends StatelessWidget {
  const DesktopShell({
    required this.directories,
    required this.window,
    super.key,
  });

  final AppDirectories directories;
  final DesktopWindowService window;

  @override
  Widget build(BuildContext context) => GetBuilder<AppNavigationController>(
    builder: (navigation) => Scaffold(
      body: Column(
        children: <Widget>[
          FlMoeTitleBar(window: window),
          Divider(height: 1, color: Theme.of(context).dividerColor),
          Expanded(
            child: Row(
              children: <Widget>[
                const AppSidebar(),
                Expanded(
                  child: ClipRect(
                    child: KeyedSubtree(
                      key: ValueKey<AppSection>(navigation.section),
                      child: _pageFor(navigation.section),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const PlayerBar(),
        ],
      ),
    ),
  );

  Widget _pageFor(AppSection section) => switch (section) {
    AppSection.home => const HomePage(),
    AppSection.discover => const DiscoverPage(),
    AppSection.collection => const CollectionDetailPage(),
    AppSection.search => const SearchPage(),
    AppSection.library => const LibraryPage(),
    AppSection.cloud => const CloudPage(),
    AppSection.settings => SettingsPage(directories: directories),
  };
}
