import 'dart:convert';
import 'dart:io';

import 'package:fl_moe/core/storage/app_database.dart';
import 'package:fl_moe/core/storage/app_directories.dart';
import 'package:fl_moe/features/music/music_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'opening settings removes the obsolete close-to-tray preference',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'fl_moe_settings_migration_test_',
      );
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

      try {
        database = await AppDatabase.open(directories);
        await database.settings.write('close_to_tray', false);
        await database.settings.write('theme', 'dark');
        await database.close();
        database = null;

        database = await AppDatabase.open(directories);

        expect(database.settings.read('close_to_tray'), isNull);
        expect(database.settings.read('theme'), 'dark');
      } finally {
        await database?.close();
        if (await root.exists()) await root.delete(recursive: true);
      }
    },
  );

  test(
    'opening library keeps the current song and removes the legacy queue',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'fl_moe_playback_migration_test_',
      );
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
      const current = MusicTrack(
        id: '2',
        hash: 'CURRENT',
        title: 'Current Song',
        artist: 'Test Singer',
      );
      const other = MusicTrack(
        id: '1',
        hash: 'OTHER',
        title: 'Other Song',
        artist: 'Test Singer',
      );

      try {
        database = await AppDatabase.open(directories);
        await database.library.write(
          'player_playback_state',
          jsonEncode(<String, Object?>{
            'version': 1,
            'queue': <Object?>[other.toJson(), current.toJson()],
            'currentTrack': current.toJson(),
            'currentIndex': 1,
          }),
        );
        await database.close();
        database = null;

        database = await AppDatabase.open(directories);

        expect(database.library.read('player_playback_state'), isNull);
        final migrated =
            jsonDecode(database.library.read('player_current_track')! as String)
                as Map<String, Object?>;
        expect(migrated.containsKey('queue'), isFalse);
        expect(
          (migrated['currentTrack']! as Map<String, Object?>)['hash'],
          current.hash,
        );
      } finally {
        await database?.close();
        if (await root.exists()) await root.delete(recursive: true);
      }
    },
  );
}
