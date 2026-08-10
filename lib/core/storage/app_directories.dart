import 'dart:io';

/// All Fl-Moe owned directories. None of these overlap MoeKoe Music's data.
final class AppDirectories {
  const AppDirectories._({
    required this.config,
    required this.data,
    required this.cache,
    required this._separator,
  });

  factory AppDirectories.resolve() => AppDirectories.fromEnvironment(
    operatingSystem: Platform.operatingSystem,
    environment: Platform.environment,
    separator: Platform.pathSeparator,
  );

  factory AppDirectories.fromEnvironment({
    required String operatingSystem,
    required Map<String, String> environment,
    required String separator,
  }) {
    final home = environment['HOME'] ?? environment['USERPROFILE'];
    if (home == null || home.isEmpty) {
      throw StateError('Cannot resolve the current user home directory.');
    }

    if (operatingSystem == 'windows') {
      final appData = _join(home, 'AppData', separator);
      final roaming =
          environment['APPDATA'] ?? _join(appData, 'Roaming', separator);
      final local =
          environment['LOCALAPPDATA'] ?? _join(appData, 'Local', separator);
      return AppDirectories._(
        config: _join(roaming, applicationDirectoryName, separator),
        data: _join(local, applicationDirectoryName, separator),
        cache: _join(
          _join(local, applicationDirectoryName, separator),
          'Cache',
          separator,
        ),
        separator: separator,
      );
    }

    final configRoot =
        environment['XDG_CONFIG_HOME'] ?? _join(home, '.config', separator);
    final dataRoot =
        environment['XDG_DATA_HOME'] ??
        _join(_join(home, '.local', separator), 'share', separator);
    final cacheRoot =
        environment['XDG_CACHE_HOME'] ?? _join(home, '.cache', separator);
    return AppDirectories._(
      config: _join(configRoot, applicationDirectoryName, separator),
      data: _join(dataRoot, applicationDirectoryName, separator),
      cache: _join(cacheRoot, applicationDirectoryName, separator),
      separator: separator,
    );
  }

  static const String applicationDirectoryName = 'Fl-Moe';

  final String config;
  final String data;
  final String cache;
  final String _separator;

  String get hive => _join(data, 'Hive', _separator);

  Future<void> create() async {
    await Future.wait(<Future<Directory>>[
      Directory(config).create(recursive: true),
      Directory(data).create(recursive: true),
      Directory(cache).create(recursive: true),
      Directory(hive).create(recursive: true),
    ]);
  }

  static String _join(String left, String right, String separator) {
    final normalizedLeft = left.endsWith(separator)
        ? left.substring(0, left.length - separator.length)
        : left;
    return '$normalizedLeft$separator$right';
  }
}
