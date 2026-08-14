import 'dart:io';

import 'package:flutter_to_debian/flutter_to_debian.dart';
import 'package:yaml/yaml.dart';

const String _configPath = 'debian/debian.yaml';

/// Strongly typed packaging values that flutter_to_debian 2.0.2 does not read.
final class DebianPackagingConfig {
  const DebianPackagingConfig({required this.depends});

  final List<String> depends;

  String get controlDepends => depends.join(', ');

  static Future<DebianPackagingConfig> load({String path = _configPath}) async {
    final File file = File(path);
    if (!await file.exists()) {
      throw FileSystemException('Debian packaging config was not found', path);
    }

    final Object? document = loadYaml(await file.readAsString());
    if (document is! YamlMap) {
      throw const FormatException('The Debian packaging config must be a map.');
    }

    final Object? control = document['control'];
    if (control is! YamlMap) {
      throw const FormatException('debian.yaml must contain a control map.');
    }

    return DebianPackagingConfig(depends: _parseDepends(control['Depends']));
  }

  static List<String> _parseDepends(Object? value) {
    final Iterable<Object?> entries;
    if (value is String) {
      entries = <Object?>[value];
    } else if (value is YamlList) {
      entries = value.nodes.map((YamlNode node) => node.value);
    } else {
      throw const FormatException(
        'control.Depends must be a string or a non-empty YAML list.',
      );
    }

    final List<String> dependencies = <String>[];
    for (final Object? entry in entries) {
      if (entry is! String || entry.trim().isEmpty) {
        throw const FormatException(
          'Every control.Depends entry must be a non-empty string.',
        );
      }
      dependencies.add(entry.trim());
    }

    if (dependencies.isEmpty) {
      throw const FormatException('control.Depends cannot be empty.');
    }
    if (dependencies.toSet().length != dependencies.length) {
      throw const FormatException('control.Depends contains duplicates.');
    }
    return List<String>.unmodifiable(dependencies);
  }
}

Future<void> main(List<String> arguments) async {
  final bool hasValidArguments =
      arguments.isEmpty ||
      (arguments.length == 1 &&
          (arguments.single == '--check' || arguments.single == '--build'));
  if (!hasValidArguments) {
    stderr.writeln('Usage: dart run tool/build_debian.dart [--check|--build]');
    exitCode = 64;
    return;
  }

  final DebianPackagingConfig config = await DebianPackagingConfig.load();
  stdout.writeln('Depends: ${config.controlDepends}');

  if (!arguments.contains('--build')) {
    stdout.writeln('Configuration check completed; no package was built.');
    return;
  }

  final FlutterToDebian packager = await FlutterToDebian.fromConfigs();
  packager.debianControl = packager.debianControl.copyWith(
    depends: config.controlDepends,
  );

  stdout.writeln('Building Debian package from the existing release bundle...');
  final String outputPath = await packager.build();
  stdout.writeln('Debian package created at $outputPath');
}
