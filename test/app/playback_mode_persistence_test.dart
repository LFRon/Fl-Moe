import 'dart:io';

import 'package:fl_moe/core/backend/music_backend.dart';
import 'package:fl_moe/core/storage/app_database.dart';
import 'package:fl_moe/core/storage/app_directories.dart';
import 'package:fl_moe/features/music/music_models.dart';
import 'package:fl_moe/features/player/audio_engine.dart';
import 'package:fl_moe/features/player/playback_controller.dart';
import 'package:fl_moe/kugou_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'playback mode and current track survive reopening Hive without network',
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
        final initialBackend = _PlayableMusicBackend();
        controller = PlaybackController(
          initialBackend,
          NoopAudioEngine(),
          database.library,
        );
        await controller.setPlaybackMode(PlaybackMode.singleLoop);
        const first = MusicTrack(
          id: '1',
          hash: 'HIVE-FIRST',
          title: 'Hive Song One',
          artist: 'Test Singer',
        );
        const second = MusicTrack(
          id: '2',
          hash: 'HIVE-SECOND',
          title: 'Hive Song Two',
          artist: 'Test Singer',
          duration: Duration(minutes: 4),
        );
        await controller.playTrack(
          second,
          sourceTracks: const <MusicTrack>[first, second],
        );
        expect(database.library.read('player_current_track'), isA<String>());
        expect(database.library.read('player_playback_state'), isNull);
        controller.onClose();
        controller = null;
        await database.close();
        database = null;

        database = await AppDatabase.open(directories);
        final restoredBackend = _PlayableMusicBackend();
        controller = PlaybackController(
          restoredBackend,
          NoopAudioEngine(),
          database.library,
        );

        expect(controller.playbackMode, PlaybackMode.singleLoop);
        expect(controller.currentTrack?.hash, second.hash);
        expect(controller.duration, second.duration);
        expect(controller.canGoPrevious, isFalse);
        expect(controller.canGoNext, isFalse);
        expect(restoredBackend.registrationCalls, 0);
        expect(restoredBackend.jsonCalls, 0);

        await controller.toggle();
        expect(restoredBackend.registrationCalls, 1);
        expect(restoredBackend.jsonCalls, 1);
      } finally {
        controller?.onClose();
        await database?.close();
        if (await root.exists()) await root.delete(recursive: true);
      }
    },
  );
}

final class _PlayableMusicBackend implements MusicBackend {
  int registrationCalls = 0;
  int jsonCalls = 0;

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
  }) async {
    jsonCalls += 1;
    return const KugouResponse<KugouJsonObject>(
      status: 1,
      httpStatus: 200,
      body: <String, Object?>{
        'url': <Object?>['https://audio.example.test/song.mp3'],
      },
    );
  }

  @override
  Future<void> clearAuthentication() async {}

  @override
  Future<void> close() async {}

  @override
  Future<bool> ensureDeviceRegistered() async {
    registrationCalls += 1;
    return true;
  }

  @override
  Future<void> flushSession() async {}

  @override
  Future<void> setClientVariant(KugouClientVariant variant) async {}
}
