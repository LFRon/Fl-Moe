import 'dart:io';

import 'package:fl_moe/core/backend/music_backend.dart';
import 'package:fl_moe/core/storage/app_database.dart';
import 'package:fl_moe/core/storage/app_directories.dart';
import 'package:fl_moe/features/player/audio_engine.dart';
import 'package:fl_moe/features/player/playback_controller.dart';
import 'package:fl_moe/kugou_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'playback mode survives closing and reopening the Hive database',
    () async {
      final root = await Directory.systemTemp.createTemp('fl_moe_mode_test_');
      final directories = AppDirectories.fromEnvironment(
        operatingSystem: 'linux',
        environment: <String, String>{
          'HOME': root.path,
          'XDG_CONFIG_HOME': '${root.path}${Platform.pathSeparator}config',
          'XDG_DATA_HOME': '${root.path}${Platform.pathSeparator}data',
          'XDG_CACHE_HOME': '${root.path}${Platform.pathSeparator}cache',
        },
        separator: Platform.pathSeparator,
      );
      AppDatabase? database;
      PlaybackController? controller;

      try {
        database = await AppDatabase.open(directories);
        controller = PlaybackController(
          const _NoopMusicBackend(),
          NoopAudioEngine(),
          database.library,
        );
        await controller.setPlaybackMode(PlaybackMode.singleLoop);
        controller.onClose();
        controller = null;
        await database.close();
        database = null;

        database = await AppDatabase.open(directories);
        controller = PlaybackController(
          const _NoopMusicBackend(),
          NoopAudioEngine(),
          database.library,
        );

        expect(controller.playbackMode, PlaybackMode.singleLoop);
      } finally {
        controller?.onClose();
        await database?.close();
        if (await root.exists()) await root.delete(recursive: true);
      }
    },
  );
}

final class _NoopMusicBackend implements MusicBackend {
  const _NoopMusicBackend();

  @override
  KugouClientVariant get clientVariant => KugouClientVariant.lite;

  @override
  BackendSessionState get sessionState => const BackendSessionState(
    isLoggedIn: false,
    userId: '0',
    hasRegisteredDevice: false,
  );

  @override
  Future<KugouResponse<KugouJsonObject>> callJson(
    String route, {
    KugouJsonObject parameters = const <String, Object?>{},
  }) => throw UnsupportedError('No network call is expected.');

  @override
  Future<void> clearAuthentication() async {}

  @override
  Future<void> close() async {}

  @override
  Future<bool> ensureDeviceRegistered() async => false;

  @override
  Future<void> flushSession() async {}

  @override
  Future<void> setClientVariant(KugouClientVariant variant) async {}
}
