import 'dart:convert';

import 'package:hive_ce/hive.dart';

import 'app_directories.dart';
import 'key_value_store.dart';

final class AppDatabase {
  AppDatabase._({
    required this.settings,
    required this.session,
    required this.library,
    required this._boxes,
  });

  static Future<AppDatabase> open(AppDirectories directories) async {
    await directories.create();
    Hive.init(directories.hive);
    final boxes = await Future.wait<Box<Object?>>(<Future<Box<Object?>>>[
      Hive.openBox<Object?>('settings', path: directories.config),
      Hive.openBox<Object?>('kugou_session', path: directories.config),
      Hive.openBox<Object?>('library'),
    ]);
    final settingsBox = boxes[0];
    if (settingsBox.containsKey(_removedCloseToTrayKey)) {
      await settingsBox.delete(_removedCloseToTrayKey);
    }
    await _migrateCurrentTrackAndRemoveQueue(boxes[2]);
    return AppDatabase._(
      settings: HiveKeyValueStore(settingsBox),
      session: HiveKeyValueStore(boxes[1]),
      library: HiveKeyValueStore(boxes[2]),
      boxes: boxes,
    );
  }

  final KeyValueStore settings;
  final KeyValueStore session;
  final KeyValueStore library;
  final List<Box<Object?>> _boxes;

  static const String _removedCloseToTrayKey = 'close_to_tray';
  static const String _removedPlaybackStateKey = 'player_playback_state';
  static const String _currentTrackKey = 'player_current_track';

  static Future<void> _migrateCurrentTrackAndRemoveQueue(
    Box<Object?> libraryBox,
  ) async {
    if (!libraryBox.containsKey(_removedPlaybackStateKey)) return;
    if (!libraryBox.containsKey(_currentTrackKey)) {
      final legacy = _decodeJsonObject(
        libraryBox.get(_removedPlaybackStateKey),
      );
      final currentTrack = _asStringObjectMap(legacy?['currentTrack']);
      if (currentTrack != null) {
        await libraryBox.put(
          _currentTrackKey,
          jsonEncode(<String, Object?>{
            'version': 1,
            'currentTrack': currentTrack,
          }),
        );
      }
    }
    // The legacy value contains the user-visible playback queue. It must not
    // survive migration even when its current-track payload is malformed.
    await libraryBox.delete(_removedPlaybackStateKey);
  }

  Future<void> close() async {
    for (final box in _boxes) {
      await box.close();
    }
  }
}

Map<String, Object?>? _decodeJsonObject(Object? value) {
  final Object? decoded;
  if (value is String) {
    try {
      decoded = jsonDecode(value);
    } on FormatException {
      return null;
    }
  } else {
    decoded = value;
  }
  return _asStringObjectMap(decoded);
}

Map<String, Object?>? _asStringObjectMap(Object? value) {
  if (value is Map<String, Object?>) return value;
  if (value is! Map<Object?, Object?>) return null;
  final result = <String, Object?>{};
  for (final entry in value.entries) {
    final key = entry.key;
    if (key is! String) return null;
    result[key] = entry.value;
  }
  return result;
}
