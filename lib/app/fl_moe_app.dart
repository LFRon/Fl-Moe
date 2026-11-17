import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';

import '../core/backend/music_backend.dart';
import '../features/auth/authentication_controller.dart';
import '../features/music/favorite_tracks_controller.dart';
import '../features/music/music_catalog_controller.dart';
import '../features/music/user_playlists_controller.dart';
import '../features/navigation/app_navigation_controller.dart';
import '../features/player/lyrics_controller.dart';
import '../features/player/playback_controller.dart';
import '../features/settings/app_settings_controller.dart';
import '../ui/desktop_shell.dart';
import 'app_dependencies.dart';
import 'app_theme.dart';

final class FlMoeApp extends StatefulWidget {
  const FlMoeApp({required this.dependencies, super.key});

  final AppDependencies dependencies;

  @override
  State<FlMoeApp> createState() => _FlMoeAppState();
}

final class _FlMoeAppState extends State<FlMoeApp> {
  @override
  void initState() {
    super.initState();
    _registerDependencies(widget.dependencies);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.dependencies.startDeferredTasks();
    });
  }

  @override
  void dispose() {
    unawaited(widget.dependencies.tray.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GetBuilder<AppSettingsController>(
    // Only appearance changes need to rebuild the MaterialApp. Window chrome
    // and playback-source preferences are consumed by their own subtrees.
    filter: (settings) =>
        (themeMode: settings.themeMode, accentColor: settings.accentColor),
    builder: (settings) => MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fl-Moe',
      themeMode: settings.themeMode,
      theme: FlMoeTheme.light(settings.accentColor),
      darkTheme: FlMoeTheme.dark(settings.accentColor),
      home: DesktopShell(
        directories: widget.dependencies.directories,
        window: widget.dependencies.window,
        tray: widget.dependencies.tray,
      ),
    ),
  );
}

void _registerDependencies(AppDependencies dependencies) {
  Get.put<MusicBackend>(dependencies.backend, permanent: true);
  Get.put<AppSettingsController>(dependencies.settings, permanent: true);
  Get.put<AuthenticationController>(
    dependencies.authentication,
    permanent: true,
  );
  Get.put<AppNavigationController>(dependencies.navigation, permanent: true);
  Get.put<MusicCatalogController>(dependencies.catalog, permanent: true);
  Get.put<FavoriteTracksController>(dependencies.favorites, permanent: true);
  Get.put<UserPlaylistsController>(dependencies.userPlaylists, permanent: true);
  Get.put<MusicCollectionDetailController>(
    dependencies.collectionDetail,
    permanent: true,
  );
  Get.put<MusicSearchController>(dependencies.search, permanent: true);
  Get.put<LyricsController>(dependencies.lyrics, permanent: true);
  Get.put<PlaybackController>(dependencies.playback, permanent: true);
}

final class FlMoeInitializationFailureApp extends StatelessWidget {
  const FlMoeInitializationFailureApp({required this.error, super.key});

  final Object error;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Fl-Moe',
    theme: FlMoeTheme.light(_defaultAccent),
    darkTheme: FlMoeTheme.dark(_defaultAccent),
    home: Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Card(
            margin: const EdgeInsets.all(28),
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    Icons.error_outline_rounded,
                    size: 52,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Fl-Moe 本地初始化失败',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '无法打开本地配置、数据库或桌面窗口服务。请关闭其他 Fl-Moe 实例后重新启动。',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SelectableText(
                    '$error',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

const Color _defaultAccent = Color(0xFF4C9BE8);
