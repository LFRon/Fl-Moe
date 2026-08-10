import 'package:hive_ce/hive.dart';

abstract interface class KeyValueStore {
  Object? read(String key);

  Future<void> write(String key, Object? value);

  Future<void> delete(String key);
}

final class HiveKeyValueStore implements KeyValueStore {
  const HiveKeyValueStore(this._box);

  final Box<Object?> _box;

  @override
  Object? read(String key) => _box.get(key);

  @override
  Future<void> write(String key, Object? value) => _box.put(key, value);

  @override
  Future<void> delete(String key) => _box.delete(key);
}

/// Useful for widget tests and previews where native storage is unavailable.
final class MemoryKeyValueStore implements KeyValueStore {
  MemoryKeyValueStore([Map<String, Object?>? values])
    : _values = Map<String, Object?>.from(values ?? const <String, Object?>{});

  final Map<String, Object?> _values;

  @override
  Object? read(String key) => _values[key];

  @override
  Future<void> write(String key, Object? value) async {
    _values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _values.remove(key);
  }
}
