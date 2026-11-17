import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';

import '../core/storage/app_directories.dart';
import '../core/tray/desktop_tray_service.dart';
import '../core/window/desktop_window_service.dart';
import '../features/navigation/app_navigation_controller.dart';
import 'app_page_transition.dart';
import 'app_sidebar.dart';
import 'pages/cloud_page/cloud_page.dart';
import 'pages/collection_detail_page/collection_detail_page.dart';
import 'pages/discover_page/discover_page.dart';
import 'pages/home_page/home_page.dart';
import 'pages/library_page/library_page.dart';
import 'pages/now_playing_page/now_playing_page.dart';
import 'pages/search_page/search_page.dart';
import 'pages/settings_page/settings_page.dart';
import 'player_bar.dart';
import 'window_resize_frame.dart';
import 'window_title_bar.dart';

final class DesktopShell extends StatelessWidget {
  const DesktopShell({
    required this.directories,
    required this.window,
    required this.tray,
    super.key,
  });

  final AppDirectories directories;
  final DesktopWindowService window;
  final DesktopTrayService tray;

  @override
  Widget build(BuildContext context) => WindowResizeFrame(
    window: window,
    child: Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Column(
            key: const ValueKey<String>('desktop-shell-content'),
            children: <Widget>[
              FlMoeTitleBar(window: window, tray: tray),
              Divider(height: 1, color: Theme.of(context).dividerColor),
              Expanded(
                child: Row(
                  children: <Widget>[
                    const AppSidebar(),
                    Expanded(
                      child: ClipRect(
                        child: GetBuilder<AppNavigationController>(
                          // Section changes rebuild the page area only.
                          // Showing/hiding the now-playing overlay is handled
                          // by a separate builder below, so the active page is
                          // not rebuilt while that transition runs.
                          filter: (navigation) => navigation.section,
                          builder: (navigation) => FlMoePageTransition(
                            section: navigation.section,
                            child: _pageFor(navigation.section),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const PlayerBar(),
            ],
          ),
          Positioned.fill(child: _NowPlayingOverlay(window: window)),
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

/// Owns the full-window now-playing transition without rebuilding the active
/// section page when the overlay opens or closes.
final class _NowPlayingOverlay extends StatelessWidget {
  const _NowPlayingOverlay({required this.window});

  final DesktopWindowService window;

  @override
  Widget build(BuildContext context) => GetBuilder<AppNavigationController>(
    filter: (navigation) => navigation.nowPlayingVisible,
    builder: (navigation) => AnimatedSwitcher(
      key: const ValueKey<String>('now-playing-full-window-overlay'),
      duration: const Duration(milliseconds: 320),
      reverseDuration: const Duration(milliseconds: 240),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.035),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: navigation.nowPlayingVisible
          // Cache the complete overlay while it slides and fades. Without this
          // boundary every intermediate transform re-rasterizes the blurred
          // background and the lyric canvas.
          ? RepaintBoundary(
              key: const ValueKey<String>('now-playing-visible'),
              child: NowPlayingPage(window: window),
            )
          : const SizedBox.shrink(key: ValueKey<String>('now-playing-hidden')),
    ),
  );
}
