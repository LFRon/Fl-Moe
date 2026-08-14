import 'dart:async';
import 'dart:io';

import 'package:cached_network_image_ce/cached_network_image.dart';
// The public conditional export currently exposes the stub constructor's
// narrower signature to static analysis. Fl-Moe only targets dart:io desktop.
// ignore: implementation_imports
import 'package:cached_network_image_ce/src/cache/default_cache_manager.dart'
    as cached_io;

import '../core/backend/music_backend.dart';
import '../core/storage/app_database.dart';
import '../core/storage/app_directories.dart';
import '../core/tray/desktop_tray_service.dart';
import '../core/window/desktop_window_service.dart';
import '../features/auth/authentication_controller.dart';
import '../features/auth/kugou_user_profile.dart';
import '../features/music/favorite_tracks_controller.dart';
import '../features/music/music_catalog_controller.dart';
import '../features/music/user_playlists_controller.dart';
import '../features/navigation/app_navigation_controller.dart';
import '../features/player/audio_engine.dart';
import '../features/player/lyrics_controller.dart';
import '../features/player/playback_controller.dart';
import '../features/settings/app_settings_controller.dart';

final class AppDependencies {
  const AppDependencies({
    required this.directories,
    required this.database,
    required this.imageCache,
    required this.backend,
    required this.settings,
    required this.authentication,
    required this.navigation,
    required this.catalog,
    required this.favorites,
    required this.userPlaylists,
    required this.collectionDetail,
    required this.search,
    required this.lyrics,
    required this.playback,
    required this.window,
    required this.tray,
  });

  static Future<AppDependencies> initialize() async {
    final directories = AppDirectories.resolve();
    final window = NativeApiDesktopWindowService();
    late final _InitializedCore core;
    // Both branches are local-only and can be completed concurrently before
    // rendering the real application UI.
    await Future.wait<void>(<Future<void>>[
      _initializeCore(directories).then<void>((value) {
        core = value;
      }),
      window.initialize(),
    ]);
    final audioEngine = MediaKitAudioEngine();
    return AppDependencies(
      directories: directories,
      database: core.database,
      imageCache: core.imageCache,
      backend: core.backend,
      settings: core.settings,
      authentication: AuthenticationController(
        core.backend,
        profileRepository: KugouUserProfileRepository(core.database.session),
      ),
      navigation: AppNavigationController(),
      catalog: MusicCatalogController(core.backend),
      favorites: FavoriteTracksController(core.backend),
      userPlaylists: UserPlaylistsController(core.backend),
      collectionDetail: MusicCollectionDetailController(core.backend),
      search: MusicSearchController(core.backend),
      lyrics: LyricsController(core.backend),
      playback: PlaybackController(
        core.backend,
        audioEngine,
        core.database.library,
        preferredQuality: () => core.settings.maximumPlaybackQuality,
      ),
      window: window,
      tray: NativeApiDesktopTrayService(),
    );
  }

  /// Starts native integrations and online work after the real shell has
  /// rendered its first frame, keeping both off the cold-start critical path.
  void startDeferredTasks() {
    unawaited(tray.initialize(window: window, playback: playback));
    unawaited(catalog.loadHomeCatalog());
    unawaited(authentication.refreshUserProfile());
    unawaited(_preRegisterDevice(backend));
  }

  final AppDirectories directories;
  final AppDatabase database;
  final BaseCacheManager imageCache;
  final MusicBackend backend;
  final AppSettingsController settings;
  final AuthenticationController authentication;
  final AppNavigationController navigation;
  final MusicCatalogController catalog;
  final FavoriteTracksController favorites;
  final UserPlaylistsController userPlaylists;
  final MusicCollectionDetailController collectionDetail;
  final MusicSearchController search;
  final LyricsController lyrics;
  final PlaybackController playback;
  final DesktopWindowService window;
  final DesktopTrayService tray;
}

final class _InitializedCore {
  const _InitializedCore({
    required this.database,
    required this.imageCache,
    required this.backend,
    required this.settings,
  });

  final AppDatabase database;
  final BaseCacheManager imageCache;
  final MusicBackend backend;
  final AppSettingsController settings;
}

Future<_InitializedCore> _initializeCore(AppDirectories directories) async {
  final database = await AppDatabase.open(directories);
  final imageCache = cached_io.DefaultCacheManager(
    stalePeriod: const Duration(days: 14),
    maxNrOfCacheObjects: 600,
    cacheDirectoryProvider: () async => Directory(directories.cache),
  );
  CachedNetworkImageProvider.defaultCacheManager = imageCache;
  final settings = AppSettingsController.load(database.settings);
  final sessionRepository = KugouSessionRepository(database.session);
  final session = sessionRepository.load(variant: settings.clientVariant);
  await sessionRepository.save(session);
  final backend = DeferredMusicBackend.start(
    initialSession: session.toJson(),
    clientVariant: settings.clientVariant,
    onSessionChanged: sessionRepository.saveJson,
  );
  return _InitializedCore(
    database: database,
    imageCache: imageCache,
    backend: backend,
    settings: settings,
  );
}

Future<void> _preRegisterDevice(MusicBackend backend) async {
  try {
    await backend.ensureDeviceRegistered();
  } on Object {
    // Registration is retried before playback. Offline UI remains usable.
  }
}
