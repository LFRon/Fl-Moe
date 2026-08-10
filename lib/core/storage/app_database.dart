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
    return AppDatabase._(
      settings: HiveKeyValueStore(boxes[0]),
      session: HiveKeyValueStore(boxes[1]),
      library: HiveKeyValueStore(boxes[2]),
      boxes: boxes,
    );
  }

  final KeyValueStore settings;
  final KeyValueStore session;
  final KeyValueStore library;
  final List<Box<Object?>> _boxes;

  Future<void> close() async {
    for (final box in _boxes) {
      await box.close();
    }
  }
}
